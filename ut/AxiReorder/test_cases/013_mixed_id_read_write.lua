-- 013：读写 Mixed-ID 保序测试。
--
-- 本用例覆盖以下两个测试点：
--
--   1. AXI/Read/MixedID/PerIDOrder
--      重复 ARID 与其他 ARID 同时在途时，每个 ARID 内部的 R 响应顺序
--      必须与该 ARID 的 AR 接收顺序一致；
--   2. AXI/Write/MixedID/PerIDOrder
--      重复 AWID 与其他 AWID 同时在途时，每个 AWID 内部的 B 响应顺序
--      必须与该 AWID 的 AW 接收顺序一致。
--
-- 与 002_same_id_write、003_different_id_write、004_same_id_read、
-- 005_different_id_read、006_random_id_read、007_random_id_write 和
-- 008_parellel_RandW 一样，本用例通过公共 driver 产生非阻塞事务，由公共
-- AXI4Memory 返回响应，并由自动 scoreboard 检查通道内容、ID 恢复和同 ID
-- 顺序。不同之处是这里不依赖随机 ID 碰撞，而是固定使用 A/B/A 模式：
--
--   repeated ID A -> other ID B -> repeated ID A
--
-- monitor 会根据上游 AR/AW、R/B 的真实握手维护每个 ID 的在途计数。只有
-- 实际观察到“至少两笔 A 和至少一笔非 A 事务同时在途”，覆盖标志才会置位；
-- 因此即使以后验证环境的延迟参数发生变化，本用例也不会把仅仅提交过 A/B/A
-- 误判成已经覆盖 Mixed-ID 场景。

local env = require "env"
local driver = require "dut.driver"
local monitor = require "dut.monitor"
local axi_stimulus = require "common.axi_stimulus"

local TASK_TIMEOUT = 2000000
local DATA_BYTES = 32
local MAX_BURST_BYTES = 4096

-- 每笔事务使用独立的 4KB 地址窗口。这样随机 burst 不会跨入相邻事务的
-- 地址范围，scoreboard 也能通过唯一地址准确区分同 ID 的前序和后序事务。
local ADDRESS_STRIDE = 0x1000
local READ_ADDRESS_BASE = 0x10000000
local WRITE_ADDRESS_BASE = 0x20000000

-- 读和写分别选择两个合法的 12-bit AXI ID。A 是需要重复出现的 ID，B 是
-- 与 A 同时在途的其他 ID。两组 ID 分开取值，便于查看日志和波形。
local READ_REPEATED_ID = 0x101
local READ_OTHER_ID = 0x202
local WRITE_REPEATED_ID = 0x303
local WRITE_OTHER_ID = 0x404

local READ_ID_PATTERN = {
    READ_REPEATED_ID,
    READ_OTHER_ID,
    READ_REPEATED_ID,
}

local WRITE_ID_PATTERN = {
    WRITE_REPEATED_ID,
    WRITE_OTHER_ID,
    WRITE_REPEATED_ID,
}

local function fired(channel)
    return channel.valid == 1 and channel.ready == 1
end

-- 创建某一类事务的 Mixed-ID 覆盖状态。
--
-- by_id[id] 记录该 ID 已由上游接收、但尚未向上游完成响应的事务数量；
-- total 记录所有 ID 的在途事务总数。seen 只有在 repeated_id 至少有两笔
-- 在途，且其他 ID 至少有一笔在途时才会置为 true。
local function new_mixed_state(repeated_id)
    return {
        repeated_id = repeated_id,
        by_id = {},
        total = 0,
        seen = false,
        max_repeated = 0,
        max_other = 0,
    }
end

local read_state = new_mixed_state(READ_REPEATED_ID)
local write_state = new_mixed_state(WRITE_REPEATED_ID)

local function accept_transaction(state, id)
    state.by_id[id] = (state.by_id[id] or 0) + 1
    state.total = state.total + 1
end

local function complete_transaction(state, id, channel_name, cycle)
    local count = state.by_id[id] or 0

    -- 如果响应 ID 没有对应的上游在途事务，说明 ID 恢复、monitor 计数或
    -- DUT 响应存在错误。这里就地报错，比等待最终超时更容易定位问题。
    assert(
        count > 0,
        string.format(
            "\n\n---ERROR---\n\n%s completed unknown id %d at cycle %s\n\n-----------\n\n",
            channel_name,
            id,
            tostring(cycle)
        )
    )

    if count == 1 then
        state.by_id[id] = nil
    else
        state.by_id[id] = count - 1
    end
    state.total = state.total - 1
end

local function sample_mixed_coverage(state)
    local repeated = state.by_id[state.repeated_id] or 0
    local other = state.total - repeated

    if repeated > state.max_repeated then
        state.max_repeated = repeated
    end
    if other > state.max_other then
        state.max_other = other
    end

    if repeated >= 2 and other >= 1 then
        state.seen = true
    end
end

-- monitor 采样的是 DUT 上游接口。先处理本拍完成的响应，再处理本拍新接收
-- 的地址事务，然后检查拍后在途状态。按这个顺序可以避免把“第一笔 A 恰好
-- 完成、第二笔 A 同拍才被接收”的边界情况错误计算成两笔 A 同时在途。
monitor.subscribe(function(sample)
    if sample.reset == 1 then
        return
    end

    if fired(sample.io.mst_r) and sample.io.mst_r.bits.last == 1 then
        complete_transaction(
            read_state,
            sample.io.mst_r.bits.id,
            "R",
            sample.cycles
        )
    end
    if fired(sample.io.mst_b) then
        complete_transaction(
            write_state,
            sample.io.mst_b.bits.id,
            "B",
            sample.cycles
        )
    end

    if fired(sample.io.mst_ar) then
        accept_transaction(read_state, sample.io.mst_ar.bits.id)
    end
    if fired(sample.io.mst_aw) then
        accept_transaction(write_state, sample.io.mst_aw.bits.id)
    end

    sample_mixed_coverage(read_state)
    sample_mixed_coverage(write_state)
end)

-- AXI4MasterV2 只有有限数量的共享 task slot。提交暂时返回
-- NoTaskIDAvailable 时等待已有事务完成并释放 slot，然后重试当前事务；其他
-- 返回值均视为真正的提交错误。这个处理方式与 002-008 保持一致。
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

-- 随机生成合法 burst 形状。random_burst_len() 负责产生合法的 burst/len
-- 组合；额外限制 INCR/WRAP 的总 footprint 不超过 4KB。
local function random_burst_shape()
    local burst
    local len
    local size

    repeat
        burst, len = axi_stimulus.random_burst_len()
        size = math.random(0, 5)
    until burst == 0 or (len + 1) * (2 ^ size) <= MAX_BURST_BYTES

    return burst, len, size
end

-- 等待本用例提交的全部事务完成。ticket.done 只有在最终 B 或 RLAST 完成后
-- 才会置位，因此退出循环意味着事务不只是进入 driver，而是已经收到完整
-- 上游响应。公共 tc_main.lua 随后还会调用 scoreboard.finish_auto_check()。
local function wait_all(records)
    local timeout = TASK_TIMEOUT

    while true do
        local all_done = true

        for _, record in ipairs(records) do
            if not record.ticket.done then
                all_done = false
                break
            end
        end

        if all_done then
            break
        end

        assert(
            timeout > 0,
            "\n\n---ERROR---\n\nwaiting for Mixed-ID responses timed out\n\n-----------\n\n"
        )
        timeout = timeout - 1
        env.wait_cycles(1)
    end

    -- 完成回调会把原始事务字段复制到 ticket.result。逐笔检查 axid 和地址，
    -- 既验证 ID 恢复，也确保等待到的是当前记录所对应的事务。
    for _, record in ipairs(records) do
        assert(
            record.ticket.error == nil,
            string.format(
                "\n\n---ERROR---\n\n%s %d completed with error: %s\n\n-----------\n\n",
                record.kind,
                record.index,
                tostring(record.ticket.error)
            )
        )
        assert(
            record.ticket.result ~= nil,
            string.format(
                "\n\n---ERROR---\n\n%s %d completed without result\n\n-----------\n\n",
                record.kind,
                record.index
            )
        )
        assert(
            record.ticket.result.axid == record.axid and
                record.ticket.result.addr == record.addr,
            string.format(
                "\n\n---ERROR---\n\n%s %d result mismatch: expected addr=0x%x id=%d, got addr=0x%x id=%d\n\n-----------\n\n",
                record.kind,
                record.index,
                record.addr,
                record.axid,
                record.ticket.result.addr,
                record.ticket.result.axid
            )
        )
    end
end

local function task_test()
    -- 启动公共 AXI Master 和 AXI4Memory。monitor/scoreboard 的后台采样任务
    -- 已由 tc_main.lua 启动，本用例只负责初始化 agent 并提交事务。
    driver.initialize()
    env.wait_cycles(1)

    local loop = tonumber(os.getenv("LOOP")) or 5000
    assert(
        loop >= #READ_ID_PATTERN and loop == math.floor(loop),
        string.format(
            "\n\n---ERROR---\n\nLOOP must be an integer greater than or equal to %d\n\n-----------\n\n",
            #READ_ID_PATTERN
        )
    )

    -- 地址按 4KB 递增。限制最大循环数，避免写地址超过 32-bit AXI 地址空间。
    local max_loop = math.floor(
        (0xffffffff - WRITE_ADDRESS_BASE) / ADDRESS_STRIDE
    ) + 1
    assert(
        loop <= max_loop,
        string.format(
            "\n\n---ERROR---\n\nLOOP is too large for unique 32-bit addresses: %d\n\n-----------\n\n",
            loop
        )
    )

    local records = {}

    for index = 1, loop do
        local pattern_index = (index - 1) % #READ_ID_PATTERN + 1
        local write_axid = WRITE_ID_PATTERN[pattern_index]
        local read_axid = READ_ID_PATTERN[pattern_index]

        local write_burst, write_len, write_size = random_burst_shape()
        local read_burst, read_len, read_size = random_burst_shape()
        local write_addr = WRITE_ADDRESS_BASE + (index - 1) * ADDRESS_STRIDE
        local read_addr = READ_ADDRESS_BASE + (index - 1) * ADDRESS_STRIDE

        -- 写数据与 002、003、007、008 一样按每拍实际地址生成 WSTRB，既支持
        -- 256-bit 满宽传输，也支持 size<5 的窄传输。
        local write_data_vec = {}
        local write_strb_vec = {}
        for beat = 1, write_len + 1 do
            local beat_addr = axi_stimulus.get_beat_addr(
                write_addr,
                write_burst,
                write_len,
                write_size,
                beat - 1
            )
            write_data_vec[beat] = axi_stimulus.random_hex_data(DATA_BYTES)
            write_strb_vec[beat] = axi_stimulus.make_strb(
                beat_addr,
                write_size,
                DATA_BYTES
            )
        end

        -- 先后提交写和读，但不等待任一 ticket 完成。连续的 A/B/A 模式会在
        -- Memory 的随机地址及响应延迟下形成多笔并发在途事务。
        local write_ticket = submit_with_retry("write", index, function()
            return driver.noblock_write(
                write_addr,
                write_burst,
                write_len,
                write_size,
                write_data_vec,
                write_strb_vec,
                write_axid,
                math.random(0, 15),
                math.random(0, 15)
            )
        end)
        driver.inject_resp {
            ch = "b",
            addr = write_addr,
            burst = write_burst,
            len = write_len,
            size = write_size,
            resp = index % 3,
        }
        records[#records + 1] = {
            kind = "write",
            index = index,
            axid = write_axid,
            addr = write_addr,
            ticket = write_ticket,
        }

        local read_ticket = submit_with_retry("read", index, function()
            return driver.noblock_read(
                read_addr,
                read_burst,
                read_len,
                read_size,
                read_axid,
                math.random(0, 15),
                math.random(0, 15)
            )
        end)
        driver.inject_resp {
            ch = "r",
            addr = read_addr,
            burst = read_burst,
            len = read_len,
            size = read_size,
            resp = index % 3,
        }
        records[#records + 1] = {
            kind = "read",
            index = index,
            axid = read_axid,
            addr = read_addr,
            ticket = read_ticket,
        }

        if index % 1000 == 0 then
            print(string.format(
                "013 progress: submitted %d Mixed-ID read/write pairs",
                index
            ))
        end
    end

    wait_all(records)

    -- 给 monitor 一个额外采样周期，确保最后一拍 RLAST/B 的在途计数已经
    -- 退休，再检查覆盖状态和最终计数。
    env.wait_cycles(1)

    assert(
        read_state.seen,
        string.format(
            "\n\n---ERROR---\n\nread Mixed-ID overlap was not observed: max repeated=%d, max other=%d\n\n-----------\n\n",
            read_state.max_repeated,
            read_state.max_other
        )
    )
    assert(
        write_state.seen,
        string.format(
            "\n\n---ERROR---\n\nwrite Mixed-ID overlap was not observed: max repeated=%d, max other=%d\n\n-----------\n\n",
            write_state.max_repeated,
            write_state.max_other
        )
    )
    assert(
        read_state.total == 0 and write_state.total == 0,
        string.format(
            "\n\n---ERROR---\n\nMixed-ID inflight counters did not drain: read=%d, write=%d\n\n-----------\n\n",
            read_state.total,
            write_state.total
        )
    )

    print(string.format(
        "013 Mixed-ID test passed: %d read/write pairs, read max A/other=%d/%d, write max A/other=%d/%d",
        loop,
        read_state.max_repeated,
        read_state.max_other,
        write_state.max_repeated,
        write_state.max_other
    ))
end

return {
    tasks = {
        task_test,
    },
}
