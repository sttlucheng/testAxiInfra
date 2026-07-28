local env = require "env"
local driver = require "dut.driver"
local monitor = require "dut.monitor"
local axi_stimulus = require "common.axi_stimulus"

local function task_test()
    driver.initialize()
    env.wait_cycles(1)

    local task_timeout = 2000000

    local function submit_with_retry(kind, index, submit)
        local timeout = task_timeout

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

    -- 用 monitor 证明读写确实存在时间重叠。
    local write_inflight = 0
    local read_inflight = 0
    local overlap_seen = false

    local function fired(channel)
        return channel.valid == 1 and channel.ready == 1
    end

    monitor.subscribe(function(sample)
        if sample.reset == 1 then
            return
        end

        if fired(sample.io.mst_aw) then
            write_inflight = write_inflight + 1
        end
        if fired(sample.io.mst_ar) then
            read_inflight = read_inflight + 1
        end

        if write_inflight > 0 and read_inflight > 0 then
            overlap_seen = true
        end

        if fired(sample.io.mst_b) then
            write_inflight = write_inflight - 1
        end
        if fired(sample.io.mst_r)
            and sample.io.mst_r.bits.last == 1 then
            read_inflight = read_inflight - 1
        end
    end)

    local write_tickets = {}
    local read_tickets = {}
    local loop = tonumber(os.getenv("LOOP")) or 5000
    assert(
        loop > 0 and loop == math.floor(loop),
        "\n\n---ERROR---\n\nLOOP must be a positive integer\n\n-----------\n\n"
    )
    for i = 1, loop do
        local write_burst
        local write_len
        local write_size
        -- 确保生成的burst footprint不超过4KB
        repeat
            -- AXI slave组件要求len要小于100，不是协议的要求，大于99会报错，跑不了仿真
            write_burst, write_len = axi_stimulus.random_burst_len({ max_incr_len = 99 })
            write_size = math.random(0, 5)
        until write_burst == 0 or (write_len + 1) * (2 ^ write_size) <= 4096
        local write_addr = axi_stimulus.random_legal_addr(write_len, write_size, write_burst)
        local write_axid = math.random(0,4095)
        -- local write_axid = math.random(0, 4095)
        local write_data_vec = {}
        local write_strb_vec = {}
        for beat = 1, write_len + 1 do
--            write_data_vec[beat] = string.format("%064x", beat)
            local beat_addr = axi_stimulus.get_beat_addr(
                write_addr,
                write_burst,
                write_len,
                write_size,
                beat - 1
            )
            write_data_vec[beat] = axi_stimulus.random_hex_data(32)
            write_strb_vec[beat] = axi_stimulus.make_strb(beat_addr, write_size, 32)
        end

        local read_axid = math.random(0,4095)
        local read_burst
        local read_size
        local read_len
        -- 确保生成的burst footprint不超过4KB
        repeat
            -- AXI slave组件要求len要小于100，不是协议的要求，大于99会报错，跑不了仿真
            read_burst, read_len = axi_stimulus.random_burst_len({ max_incr_len = 99 })
            read_size = math.random(0, 5)
        until read_burst == 0 or (read_len + 1) * (2 ^ read_size) <= 4096
        local read_addr = axi_stimulus.random_legal_addr(read_len, read_size, read_burst)

        -- 使用不同地址，避免并发读写同一地址产生未定义的先后关系。
        local write_ticket = submit_with_retry("write", i, function()
            return driver.noblock_write(
                write_addr,
                write_burst,
                write_len,
                write_size,
                write_data_vec,
                write_strb_vec,
                write_axid
            )
        end)

        -- 这里不能等待 write_ticket，立即提交读事务。
        local read_ticket = submit_with_retry("read", i, function()
            return driver.noblock_read(
                read_addr,
                read_burst,
                read_len,
                read_size,
                read_axid
            )
        end)

        -- 只有提交成功才记录
        write_tickets[#write_tickets + 1] = write_ticket
        read_tickets[#read_tickets + 1] = read_ticket
    end

    assert(
        #write_tickets == loop and #read_tickets == loop,
        "\n\n---ERROR---\n\nnot all concurrent transactions were submitted\n\n-----------\n\n"
    )

    -- 滑动提交结束后最多只剩nr_task笔事务未完成。
    local timeout = task_timeout

    while true do
        local all_done = true

        for _, ticket in ipairs(write_tickets) do
            if not ticket.done then
                all_done = false
                break
            end
        end

        if all_done then
            for _, ticket in ipairs(read_tickets) do
                if not ticket.done then
                    all_done = false
                    break
                end
            end
        end

        if all_done then
            break
        end

        assert(
            timeout > 0,
            "\n\n---ERROR---\n\nwaiting for concurrent read/write responses timed out\n\n-----------\n\n"
        )
        timeout = timeout - 1
        env.wait_cycles(1)
    end

    assert(
        overlap_seen,
        "\n\n---ERROR---\n\nread and write never overlapped\n\n-----------\n\n"
    )


    -- 能执行到这里，说明所有写事务都已经收到完成响应。
    --
    -- 注意：tickets数组的顺序是“事务提交顺序”，不一定是“实际完成顺序”。
    -- 下面的index只表示这是提交的第几笔事务。
    print("\n\n-----------------------------------------------\n\n")
    for index, ticket in ipairs(write_tickets) do
        -- 正常完成的ticket应当具有result快照。
        assert(
            ticket.result ~= nil,
            string.format(
                "\n\n---ERROR---\n\nwrite %d completed without result\n\n-----------\n\n",
                index
            )
        )

        -- result是在finish_callback中从内部task复制出来的稳定快照。
        -- 这里打印地址和上游AXI ID，便于与日志或波形对应。
        
        print(string.format(
            "write %d completed: addr=0x%x axid=%d",
            index,
            ticket.result.addr,
            ticket.result.axid
        ))
        
    end
    print("\n\n-----------------------------------------------\n\n")

    print("\n\n-----------------------------------------------\n\n")
    for index, ticket in ipairs(read_tickets) do
        -- 正常完成的ticket应当具有result快照。
        assert(
            ticket.result ~= nil,
            string.format(
                "\n\n---ERROR---\n\nread %d completed without result\n\n-----------\n\n",
                index
            )
        )

        -- result是在finish_callback中从内部task复制出来的稳定快照。
        -- 这里打印地址和上游AXI ID，便于与日志或波形对应。
        
        print(string.format(
            "read %d completed: addr=0x%x axid=%d",
            index,
            ticket.result.addr,
            ticket.result.axid
        ))
        

    end
    print("\n\n-----------------------------------------------\n\n")
end

return {
    tasks = {
        task_test,
    },
}
