local env = require "env"
local driver = require "dut.driver"
local axi_stimulus = require "common.axi_stimulus"

--[[
local function make_low_strb(size)
    assert(
        size >= 0 and size <= 5,
        "\n\n---ERROR---\n\nAXI size must be in range 0..5\n\n-----------\n\n"
    )

    local bytes = 2 ^ size

    -- size=5时需要32个1，单独处理，避免32-bit移位边界问题。
    if bytes == 32 then
        return "ffffffff"
    end

    -- 低bytes个WSTRB bit置1。
    local mask = 2 ^ bytes - 1

    -- 固定输出8个十六进制字符，对应完整32-bit WSTRB。
    return string.format("%08x", mask)
end
]]

local function task_test()
    driver.initialize()
    env.wait_cycles(1)

    local task_timeout = 20000

    local function submit_write(index, submit)
        local timeout = task_timeout

        while true do
            local ret, ticket = submit()

            if ret == "Success" then
                return ticket
            end

            assert(
                ret == "NoTaskIDAvailable",
                string.format(
                    "\n\n---ERROR---\n\nwrite %d submit failed: %s\n\n-----------\n\n",
                    index,
                    tostring(ret)
                )
            )
            assert(
                timeout > 0,
                string.format(
                    "\n\n---ERROR---\n\nwrite %d timed out waiting for a free task slot\n\n-----------\n\n",
                    index
                )
            )

            timeout = timeout - 1
            env.wait_cycles(1)
        end
    end

    -- 自动scoreboard已由env加载：它从monitor取得mst/slv端口握手，自动
    -- 比对AW、W和B。本用例只描述激励、等待和业务结果，无需创建expected表
    -- 或调用scoreboard.expect()。
--  调用 driver 产生激励
    -- 使用循环模拟多笔事务
    local tickets = {}
    -- 循环次数
    local loop = tonumber(os.getenv("LOOP")) or 4
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
            write_burst, write_len = axi_stimulus.random_burst_len()
            write_size = math.random(0, 5)
        until write_burst == 0 or (write_len + 1) * (2 ^ write_size) <= 4096

        local test_addr = axi_stimulus.random_legal_addr(write_len, write_size, write_burst)
        local write_axid = 1
        -- local write_axid = math.random(0, 4095)
        local write_data_vec = {}
        local write_strb_vec = {}

        for beat = 1, write_len + 1 do
--            write_data_vec[beat] = string.format("%064x", beat)
            local beat_addr = axi_stimulus.get_beat_addr(
                test_addr,
                write_burst,
                write_len,
                write_size,
                beat - 1
            )
            write_data_vec[beat] = axi_stimulus.random_hex_data(32)
            write_strb_vec[beat] = axi_stimulus.make_strb(beat_addr, write_size, 32)
        end

        local write_ticket = submit_write(i, function()
            return driver.noblock_write(
                test_addr,
                write_burst,
                write_len,
                write_size,
                write_data_vec,
                write_strb_vec,
                write_axid
            )
        end)

        -- 在生成的对应的B响应，便于后续检查。
        driver.inject_resp {
            ch   = "b",
            addr = test_addr,
            burst = write_burst,
            len = write_len,
            size = write_size,  
            resp = i % 3, 
        }



        -- 只有提交成功才记录
        tickets[#tickets + 1] = write_ticket

    end

    -- 滑动提交结束后最多只剩nr_task笔事务未完成。这里与AXI Master
    -- 的单任务超时保持一致；若耗尽仍未收到B响应，说明可能出现：
    --   1. AW或W通道握手被卡住；
    --   2. 下游Memory没有返回B响应；
    --   3. AxiReorder丢失了写事务；
    --   4. testbench或driver的事务状态出现错误。
    local timeout = task_timeout

    -- tickets 应当至少包含一笔已成功提交的写事务。
    assert(
        #tickets > 0,
        "\n\n---ERROR---\n\nno write transaction was submitted\n\n-----------\n\n"
    )

    -- 持续轮询所有非阻塞写事务的完成状态。
    --
    -- noblock_write() 在提交事务后立即返回，因此不能直接认为写操作已经完成。
    -- 当AXI Master收到对应的B响应后，driver中的finish_callback才会执行：
    --
    --     ticket.done = true
    --
    -- 所以这里需要等待所有ticket的done都变成true。
    while true do
        -- 每轮检查开始时，先假定所有事务都已经完成。
        --
        -- 只要后面发现任意一个ticket.done不是true，
        -- 就把all_done改成false。
        local all_done = true

        -- ipairs按照事务提交时保存到tickets数组中的顺序遍历。
        for _, ticket in ipairs(tickets) do
            -- done=false表示该写事务还没有完成。
            --
            -- 对非阻塞写而言，“完成”通常表示：
            --   AW地址已经发送；
            --   所有W数据拍已经发送；
            --   AXI Master已经收到最终B响应；
            --   finish_callback已经执行。
            if not ticket.done then
                all_done = false

                -- 已经确定至少有一笔没有完成，不需要继续检查剩余ticket。
                -- 退出for循环，等待一个周期后再重新检查全部事务。
                break
            end
        end

        -- 如果没有找到未完成事务，说明所有ticket.done都已经为true。
        if all_done then
            break
        end

        -- 防止DUT或验证环境出现问题时，while循环无限运行。
        --
        -- timeout耗尽后主动触发assert，使仿真以明确错误结束，
        -- 而不是一直卡在等待B响应的循环中。
        assert(
            timeout > 0,
            "\n\n---ERROR---\n\nwaiting for write responses timed out\n\n-----------\n\n"
        )

        -- 消耗一个等待周期额度。
        timeout = timeout - 1

        -- 等待一个DUT时钟周期。
        --
        -- 等待期间，AXI Master、AxiReorder和AXI Memory的后台任务
        -- 会继续执行AW/W/B通道握手，并可能把某些ticket.done置为true。
        env.wait_cycles(1)
    end

    -- 能执行到这里，说明所有写事务都已经收到完成响应。
    --
    -- 注意：tickets数组的顺序是“事务提交顺序”，不一定是“实际完成顺序”。
    -- 下面的index只表示这是提交的第几笔事务。
    print("\n\n-----------------------------------------------\n\n")
    for index, ticket in ipairs(tickets) do
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
end



return {
    tasks = {
        task_test
    }
}
