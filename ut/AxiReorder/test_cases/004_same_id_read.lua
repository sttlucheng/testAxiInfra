local env = require "env"
local driver = require "dut.driver"

-- 生成指定字节数的随机十六进制字符串。
--
-- 例如：
--   random_hex_data(4)  -> "3fa012bc"
--   random_hex_data(32) -> 64个十六进制字符，即256 bit
local function random_hex_data(byte_count)
    local parts = {}

    for byte = 1, byte_count do
        -- 每次只生成0～255，确保math.random参数在安全范围内。
        -- 
        local random_byte = math.random(0, 255)

        -- %02x表示转换成两个十六进制字符。
        -- 不足两位时在左侧补0：
        --   0   -> "00"
        --   5   -> "05"
        --   255 -> "ff"
        parts[byte] = string.format("%02x", random_byte)
    end

    return table.concat(parts)
end

-- 生成随机合法的burst和len组合
local function random_burst_len()
    local burst = math.random(0, 2)

    if burst == 0 then
        return burst, math.random(0, 15)
    elseif burst == 1 then
        -- AXI SLVE组件只允许len到100，读出时会有问题，所以定到99.
        return burst, math.random(0, 99)
    else
        local wrap_lens = { 1, 3, 7, 15 }
        return burst, wrap_lens[math.random(1, #wrap_lens)]
    end
end

-- 生成随机合法的AXI地址，确保burst footprint不跨页。
local function random_legal_addr(len, size, burst)
    local bytes_per_beat = 2 ^ size

    local footprint
    if burst == 0 then
        footprint = bytes_per_beat
    else
        footprint = (len + 1) * bytes_per_beat
    end

    assert(
        footprint <= 4096,
        "burst footprint exceeds one 4KB page"
    )

    -- 分两段产生36位页号，避免给math.random传入过大的上限。
    local page_number =
        math.random(0, 0x3ffff) * 0x40000 +
        math.random(0, 0x3ffff)

    local page_base = page_number * 4096
    local max_slot = math.floor((4096 - footprint) / bytes_per_beat)
    local offset = math.random(0, max_slot) * bytes_per_beat

    return page_base + offset
end

-- 窄传输
local function make_strb(beat_addr, size)
    local transfer_bytes = 2 ^ size
    local byte_offset = beat_addr % 32

    assert(
        byte_offset + transfer_bytes <= 32,
        "transfer crosses the 256-bit data-bus boundary"
    )

    if transfer_bytes == 32 then
        return "ffffffff"
    end

    local mask = (2 ^ transfer_bytes - 1) * (2 ^ byte_offset)
    return string.format("%08x", mask)
end
local function get_beat_addr(start_addr, burst, len, size, beat_index)
    local bytes_per_beat = 2 ^ size

    if burst == 0 then
        return start_addr
    elseif burst == 1 then
        return start_addr + beat_index * bytes_per_beat
    else
        local wrap_size = (len + 1) * bytes_per_beat
        local wrap_base = math.floor(start_addr / wrap_size) * wrap_size

        return wrap_base +
            ((start_addr - wrap_base + beat_index * bytes_per_beat)
                % wrap_size)
    end
end



local function task_test()
    -- 使用随机数种子，保证每次仿真可重复。
    local seed = tonumber(os.getenv("SEED")) or 1
    math.randomseed(seed)

    print(string.format("Random seed: %d", seed))

    driver.initialize()
    env.wait_cycles(1)

    -- 先写入数据，才能读出。先进行写操作
    -- 用于记录写入的位置，方便后续读出
    local write_table = {id = {},addr = {},burst = {},len = {},size = {}}
    local total_beats = 0
    local tickets = {}
    -- 循环次数
    local loop = 4
    for i = 1, loop do
        local write_burst
        local write_len
        local write_size
        -- 确保生成的burst footprint不超过4KB
        repeat
            write_burst, write_len = random_burst_len()
            write_size = math.random(0, 5)
        until write_burst == 0 or (write_len + 1) * (2 ^ write_size) <= 4096

        -- 统计总共的beat数，为后续超时做处理
        total_beats = total_beats + write_len + 1

        local test_addr = random_legal_addr(write_len, write_size, write_burst)
        local write_axid = 1
        -- local write_axid = math.random(0, 4095)
        local write_data_vec = {}
        local write_strb_vec = {}

        for beat = 1, write_len + 1 do
--            write_data_vec[beat] = string.format("%064x", beat)
            local beat_addr = get_beat_addr(
                test_addr,
                write_burst,
                write_len,
                write_size,
                beat - 1
            )
            write_data_vec[beat] = random_hex_data(32)
            write_strb_vec[beat] = make_strb(beat_addr, write_size)
        end

        -- 记录写入的情况
        write_table.addr[i] = test_addr
        write_table.burst[i] = write_burst
        write_table.len[i] = write_len
        write_table.size[i] = write_size
        write_table.id[i] = write_axid


        local write_ret, write_ticket = driver.noblock_write(
            test_addr,
            write_burst,
            write_len,
            write_size,
            write_data_vec,
            write_strb_vec,
            write_axid
        )

        assert(
            write_ret == "Success",
            string.format(
                "write %d submit failed: %s",
                i,
                tostring(write_ret)
            )
        )

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

    -- 根据所有写事务的总拍数计算超时，并额外保留1000周期余量。
    --
    -- 如果超时仍有写事务没有收到B响应，说明可能出现：
    --   1. AW或W通道握手被卡住；
    --   2. 下游Memory没有返回B响应；
    --   3. AxiReorder丢失了写事务；
    --   4. testbench或driver的事务状态出现错误。
    local timeout = total_beats + 1000

    -- tickets 应当至少包含一笔已成功提交的写事务。
    assert(
        #tickets > 0,
        "no write transaction was submitted"
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
            "waiting for write responses timed out"
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
    for index, ticket in ipairs(tickets) do
        -- 正常完成的ticket应当具有result快照。
        assert(
            ticket.result ~= nil,
            string.format(
                "write %d completed without result",
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





    -- 自动scoreboard会在AR输入握手时记录原始上游id，在下游R响应到来时
    -- 通过下游id恢复该id，并比较RDATA/RESP/RLAST。testcase只发送读请求
    -- 并等待ticket完成，无需调用scoreboard.expect()。
    --  调用 driver 产生激励
    -- 使用循环模拟多笔事务
    local read_total_beats = 0
    local read_tickets = {}
    for i = 1, loop do

        local write_table_id = math.random(1,#write_table.id)

        local read_burst = write_table.burst[write_table_id]
        local read_len = write_table.len[write_table_id]
        local read_size = write_table.size[write_table_id]

        -- 统计总共的beat数，为后续超时做处理
        read_total_beats = read_total_beats + read_len + 1

        local test_addr = write_table.addr[write_table_id] 
        local read_axid = write_table.id[write_table_id]
        

        local read_ret, read_ticket = driver.noblock_read(
            test_addr,
            read_burst,
            read_len,
            read_size,
            read_axid
        )

        assert(
            read_ret == "Success",
            string.format(
                "read %d submit failed: %s",
                i,
                tostring(read_ret)
            )
        )

        -- 在生成的对应的R响应，便于后续检查。
        driver.inject_resp {
            ch   = "r",
            addr = test_addr,
            burst = read_burst,
            len = read_len,
            size = read_size,  
            resp = i % 3, 
        }



        -- 只有提交成功才记录
        read_tickets[#read_tickets + 1] = read_ticket

    end

    -- 根据所有读事务的总拍数计算超时，并额外保留1000周期余量。
    --
    -- 如果超时仍有读事务没有收到R响应，说明可能出现：
    --   1. AR通道握手被卡住；
    --   2. 下游Memory没有返回R响应；
    --   3. AxiReorder丢失了读事务；
    --   4. testbench或driver的事务状态出现错误。
    local read_timeout = read_total_beats + 1000

    -- read_tickets 应当至少包含一笔已成功提交的读事务。
    assert(
        #read_tickets > 0,
        "no read transaction was submitted"
    )

    -- 持续轮询所有非阻塞读事务的完成状态。
    --
    -- noblock_read() 在提交事务后立即返回，因此不能直接认为读操作已经完成。
    -- 当AXI Master收到对应的R响应后，driver中的finish_callback才会执行：
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

        -- ipairs按照事务提交时保存到read_tickets数组中的顺序遍历。
        for _, ticket in ipairs(read_tickets) do
            -- done=false表示该读事务还没有完成。
            --
            -- 对非阻塞读而言，“完成”通常表示：
            --   AR地址已经发送；
            --   AXI Master已经收到最终R响应；
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
        -- read_timeout耗尽后主动触发assert，使仿真以明确错误结束，
        -- 而不是一直卡在等待B响应的循环中。
        assert(
            read_timeout > 0,
            "waiting for read responses timed out"
        )

        -- 消耗一个等待周期额度。
        read_timeout = read_timeout - 1

        -- 等待一个DUT时钟周期。
        --
        -- 等待期间，AXI Master、AxiReorder和AXI Memory的后台任务
        -- 会继续执行AW/W/B通道握手，并可能把某些ticket.done置为true。
        env.wait_cycles(1)
    end

    -- 能执行到这里，说明所有读事务都已经收到完成响应。
    --
    -- 注意：read_tickets数组的顺序是“事务提交顺序”，不一定是“实际完成顺序”。
    -- 下面的index只表示这是提交的第几笔事务。
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
            "\n\n--------\n\nread %d completed: addr=0x%x axid=%d\n\n-----------\n\n",
            index,
            ticket.result.addr,
            ticket.result.axid
        ))
    end
end



return {
    tasks = {
        task_test
    }
}
