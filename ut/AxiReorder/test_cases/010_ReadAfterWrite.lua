-- 010：随机写后读测试。
--
-- 本用例沿用 008_parellel_RandW.lua 的随机事务约束，但把每一轮事务改成
-- 明确的“先写、后读”顺序：
--
--   1. 随机生成一组合法的 burst、len、size、addr、ID、qos 和 cache；
--   2. 使用这组参数向 addr 写入随机数据；
--   3. 等待写事务收到完整 B 响应，确保数据已经提交到下游 Memory；
--   4. 使用同一个 addr、burst、len 和 size 发起读事务，ID/qos/cache 仍然
--      独立随机，验证事务字段和原始 ID 的恢复；
--   5. 等待读事务完成，并将每拍读回的 256 bit 数据与参考内存比较。
--
-- 写事务和读事务不共用同一个 ticket。driver.noblock_write() 返回的 ticket
-- 只有在 B 通道握手后才会把 done 置为 true；因此等待 write_ticket.done 是
-- 本用例“写完成后才能读”的关键，而不是仅仅等待 write() 提交成功。

local env = require "env"
local driver = require "dut.driver"
local axi_stimulus = require "common.axi_stimulus"

-- AXI4Memory 的数据宽度为 256 bit，即每个内存项包含 32 个字节。
local DATA_BYTES = 32
local DATA_HEX_CHARS = DATA_BYTES * 2
--local MAX_INCR_LEN = 99
local MAX_BURST_BYTES = 4096
local TASK_TIMEOUT = 2000000

-- MemoryCfg 按 WSTRB 的二进制字符串从左到右选择 data 的字节。
-- 例如 mask=00000001 表示只更新 data 最右侧的一个字节；这里的表用于
-- 把单拍写数据合并到测试用例自己的参考内存中。
local HEX_TO_BITS = {
    ["0"] = "0000",
    ["1"] = "0001",
    ["2"] = "0010",
    ["3"] = "0011",
    ["4"] = "0100",
    ["5"] = "0101",
    ["6"] = "0110",
    ["7"] = "0111",
    ["8"] = "1000",
    ["9"] = "1001",
    ["a"] = "1010",
    ["b"] = "1011",
    ["c"] = "1100",
    ["d"] = "1101",
    ["e"] = "1110",
    ["f"] = "1111",
}

-- 返回 256 bit 全零数据，表示尚未写过的内存字节。
local function zero_data()
    return string.rep("00", DATA_BYTES)
end

-- 将一拍带 WSTRB 的写数据合并到一个 32-byte 内存项。
--
-- data 和 strb 都是按 AXI 信号宽度转成的十六进制字符串。WSTRB 的每一位
-- 只影响同位置的 data 字节；未使能的字节保持旧值，旧值不存在时保持 0。
local function merge_write_data(old_data, data, strb)
    assert(#old_data == DATA_HEX_CHARS)
    assert(#data == DATA_HEX_CHARS)
    assert(#strb == DATA_BYTES / 4)

    local bytes = {}
    for byte = 1, DATA_BYTES do
        bytes[byte] = old_data:sub(byte * 2 - 1, byte * 2)
    end

    local lower_strb = strb:lower()
    for nibble = 1, #lower_strb do
        local bits = HEX_TO_BITS[lower_strb:sub(nibble, nibble)]
        assert(bits ~= nil, "WSTRB contains a non-hexadecimal character")

        for bit = 1, 4 do
            local byte = (nibble - 1) * 4 + bit
            if bits:sub(bit, bit) == "1" then
                bytes[byte] = data:sub(byte * 2 - 1, byte * 2)
            end
        end
    end

    return table.concat(bytes)
end

-- 等待一个非阻塞事务完成。
--
-- submit 成功只表示 AXI Master 接受了事务并分配了 task slot，不代表 AW/W/AR
-- 已握手或最终 B/R 已返回。这里统一轮询 ticket.done，并在超时或缺少结果
-- 时给出带有事务序号的错误信息，便于定位是哪一轮随机事务失败。
local function wait_ticket(kind, index, ticket)
    local timeout = TASK_TIMEOUT

    while not ticket.done do
        assert(
            timeout > 0,
            string.format(
                "\n\n---ERROR---\n\nwaiting for %s %d response timed out\n\n-----------\n\n",
                kind,
                index
            )
        )

        timeout = timeout - 1
        env.wait_cycles(1)
    end

    assert(
        ticket.error == nil,
        string.format(
            "\n\n---ERROR---\n\n%s %d completed with error: %s\n\n-----------\n\n",
            kind,
            index,
            tostring(ticket.error)
        )
    )
    assert(
        ticket.result ~= nil,
        string.format(
            "\n\n---ERROR---\n\n%s %d completed without result\n\n-----------\n\n",
            kind,
            index
        )
    )

    return ticket.result
end

-- AXI4MasterV2 只有有限数量的 task slot。提交返回 NoTaskIDAvailable 时，
-- 等待后台任务完成并释放 slot 后重试；其他返回值都是真正的提交错误。
local function submit_with_retry(kind, index, submit)
    local timeout = TASK_TIMEOUT

    while true do
        local ret, ticket = submit()
        if ret == "Success" then
            return ticket
        end

        assert(
            ret == "NoTaskIDAvailable",
            string.format(
                "\n\n---ERROR---\n\n%s %d submit failed: %s\n\n-----------\n\n",
                kind,
                index,
                tostring(ret)
            )
        )
        assert(
            timeout > 0,
            string.format(
                "\n\n---ERROR---\n\n%s %d timed out waiting for a free task slot\n\n-----------\n\n",
                kind,
                index
            )
        )

        timeout = timeout - 1
        env.wait_cycles(1)
    end
end

-- 检查 driver 完成回调保存的事务字段，确保读事务确实复用了写事务的地址、
-- burst、len 和 size，而不是只“碰巧”访问了某个地址。
local function assert_result(kind, index, result, expected)
    for _, field in ipairs({ "addr", "burst", "len", "size", "axid" }) do
        assert(
            result[field] == expected[field],
            string.format(
                "\n\n---ERROR---\n\n%s %d %s mismatch: expected %s, got %s\n\n-----------\n\n",
                kind,
                index,
                field,
                tostring(expected[field]),
                tostring(result[field])
            )
        )
    end
end

local function task_test()
    -- 启动公共 AXI Master 和 AXI4Memory。测试用例只通过 driver 产生事务，
    -- monitor/scoreboard 由公共 tc_main.lua 统一启动和收尾检查。
    driver.initialize()
    env.wait_cycles(1)

    local loop = tonumber(os.getenv("LOOP")) or 5000
    assert(
        loop > 0 and loop == math.floor(loop),
        "\n\n---ERROR---\n\nLOOP must be a positive integer\n\n-----------\n\n"
    )

    -- reference_memory 的 key 是 32-byte 对齐地址，value 是该内存项的完整
    -- 256 bit 内容。它不仅能检查 full-width 写，也能处理 size<5 时的窄写。
    local reference_memory = {}
    local transaction_count = 0

    for index = 1, loop do
        local burst
        local len
        local size

        -- 所有 burst 都不得
        -- 跨越 4KB 边界。FIXED burst 的 footprint 只有一拍大小。
        repeat
            burst, len = axi_stimulus.random_burst_len ()
            size = math.random(0, 5)
        until burst == 0 or (len + 1) * (2 ^ size) <= MAX_BURST_BYTES

        -- random_legal_addr() 会按 size 对齐地址，并再次保证 burst 不跨 4KB。
        local addr = axi_stimulus.random_legal_addr(len, size, burst)
        local write_axid = math.random(0, 4095)
        local write_qos = math.random(0, 15)
        local write_cache = math.random(0, 15)

        -- 每拍都产生完整 256 bit 数据；WSTRB 根据真实 beat 地址生成，
        -- 因此窄传输也会只更新合法的字节 lane。
        local write_data_vec = {}
        local write_strb_vec = {}
        for beat = 1, len + 1 do
            local beat_addr = axi_stimulus.get_beat_addr(
                addr,
                burst,
                len,
                size,
                beat - 1
            )
            write_data_vec[beat] = axi_stimulus.random_hex_data(DATA_BYTES)
            write_strb_vec[beat] = axi_stimulus.make_strb(
                beat_addr,
                size,
                DATA_BYTES
            )
        end

        -- 第一步：提交写事务，并等待最终 B 响应。
        -- 只有等待 done 后才允许提交对应读事务，保证写先于读真正完成。
        local write_ticket = submit_with_retry("write", index, function()
            return driver.noblock_write(
                addr,
                burst,
                len,
                size,
                write_data_vec,
                write_strb_vec,
                write_axid,
                write_qos,
                write_cache
            )
        end)
        local write_result = wait_ticket("write", index, write_ticket)
        assert_result("write", index, write_result, {
            addr = addr,
            burst = burst,
            len = len,
            size = size,
            axid = write_axid,
        })

        -- 写已经完成，按 AXI4Memory 的 byte-enable 规则更新参考内存。
        -- 这一步放在 B 完成之后，避免把尚未真正写入的事务计入期望值。
        for beat = 1, len + 1 do
            local beat_addr = axi_stimulus.get_beat_addr(
                addr,
                burst,
                len,
                size,
                beat - 1
            )
            local block_addr = beat_addr - beat_addr % DATA_BYTES
            local old_data = reference_memory[block_addr] or zero_data()
            reference_memory[block_addr] = merge_write_data(
                old_data,
                write_data_vec[beat],
                write_strb_vec[beat]
            )
        end

        -- 读 ID、qos 和 cache 与写事务独立随机；地址和 burst 描述保持一致，
        -- 这样读回的 beat 集合正好覆盖刚刚写入的对应地址范围。
        local read_axid = math.random(0, 4095)
        local read_qos = math.random(0, 15)
        local read_cache = math.random(0, 15)

        -- 第二步：只有写 ticket.done 后才提交读事务。
        local read_ticket = submit_with_retry("read", index, function()
            return driver.noblock_read(
                addr,
                burst,
                len,
                size,
                read_axid,
                read_qos,
                read_cache
            )
        end)
        local read_result = wait_ticket("read", index, read_ticket)
        assert_result("read", index, read_result, {
            addr = addr,
            burst = burst,
            len = len,
            size = size,
            axid = read_axid,
        })

        -- 读完成回调会复制所有 RDATA；逐拍和参考内存比较，验证不是只发送
        -- 了读请求，而是确实从刚才写入的地址读出了正确内容。
        assert(
            read_ticket.data_vec ~= nil and #read_ticket.data_vec == len + 1,
            string.format(
                "\n\n---ERROR---\n\nread %d returned an invalid data beat count\n\n-----------\n\n",
                index
            )
        )
        for beat = 1, len + 1 do
            local beat_addr = axi_stimulus.get_beat_addr(
                addr,
                burst,
                len,
                size,
                beat - 1
            )
            local block_addr = beat_addr - beat_addr % DATA_BYTES
            local expected_data = reference_memory[block_addr] or zero_data()
            local actual_data = read_ticket.data_vec[beat]

            assert(
                type(actual_data) == "string" and
                    actual_data:lower() == expected_data:lower(),
                string.format(
                    "\n\n---ERROR---\n\nread %d beat %d data mismatch at addr 0x%x:\nexpected: %s\nactual:   %s\n\n-----------\n\n",
                    index,
                    beat,
                    beat_addr,
                    expected_data,
                    tostring(actual_data)
                )
            )
        end

        transaction_count = transaction_count + 1
        if transaction_count % 1000 == 0 then
            print(string.format(
                "010 progress: completed %d write-then-read pairs",
                transaction_count
            ))
        end
    end

    assert(
        transaction_count == loop,
        "\n\n---ERROR---\n\nnot all write-then-read transactions completed\n\n-----------\n\n"
    )
    print(string.format(
        "010 write-then-read test passed: %d pairs completed",
        transaction_count
    ))
end

return {
    tasks = {
        task_test,
    },
}
