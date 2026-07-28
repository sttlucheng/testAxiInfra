local env = require "env"
local driver = require "dut.driver"
local monitor = require "dut.monitor"

-- 本用例验证的配置关系如下：
--   * 重排表有 4 个 entry；
--   * AW FIFO 深度为 1；
--   * 保存“下一笔 W 属于哪个 entry”的 W FIFO 深度为 2。
--
-- 测试不读取 DUT 内部寄存器，而是用 AXI 端口握手推导占用量：
--   已分配的重排 entry 数 = 上游已握手 AW 数 - 上游已握手 B 数。
-- 整个填充阶段不返回 B，因此已握手 AW 数就是重排表当前占用数。
-- 这样既可证明 FIFO 深度较小时 buffer 未填满就发生阻塞，也不会依赖
-- 具体的 RTL 层级名称。
local REORDER_DEPTH = 4
local AW_FIFO_DEPTH = 1
local W_FIFO_DEPTH = 2

-- 所有等待都必须有上限，避免 DUT 或测试平台异常时仿真无限运行。
local TIMEOUT = 100

-- 本用例在负沿修改输入，在下一个正沿完成 AXI valid/ready 握手。
-- 这样 monitor 在正沿采样时，所有输入字段已经稳定半个时钟周期。
local clock = dut.clock:chdl()

-- AXI 通道在 valid 和 ready 同时为 1 时才算传输完成。
local function fired(channel)
    return channel.valid == 1 and channel.ready == 1
end

-- 统一封装负沿等待，避免各测试阶段混用正、负沿而产生竞态。
local function wait_negedge()
    clock:negedge()
end

-- 所有断言错误统一使用测试用例约定的明显分割线。
-- assert() 会把该字符串作为失败原因打印，调用点只需传入具体错误信息。
local function error_message(message)
    return "\n\n---ERROR---\n\n" .. message .. "\n\n--------\n\n"
end

-- 普通进度信息也使用分割线包围，避免多条仿真日志混在一起难以定位。
local function print_message(message)
    print(
        "\n\n-----------------------------------------------\n\n" ..
        message ..
        "\n\n-----------------------------------------------\n\n"
    )
end

-- 在负沿轮询异步可见的状态。
-- 每次轮询之间至少推进一个完整正沿，使 DUT、monitor 和 scoreboard
-- 都有机会处理本拍的握手；description 会出现在超时错误中。
local function wait_until_negedge(predicate, description)
    for _ = 1, TIMEOUT do
        if predicate() then
            return
        end

        env.wait_cycles(1)
        wait_negedge()
    end

    assert(false, error_message("timeout waiting for " .. description))
end

-- 驱动一笔单拍 INCR 写地址。
-- 本用例的目标是 FIFO 占用而不是 burst 功能，因此固定：
--   AxLEN   = 0：仅一拍 W；
--   AxSIZE  = 0：每拍 1 byte；
--   AxBURST = 1：INCR burst。
-- 其余 AW 属性设为 0，确保四笔事务的差别只来自 AXI ID 和地址。
-- valid 为 false 时仍保留 payload；AXI 规定 valid=0 时 payload 无意义，
-- 但保留数值有利于波形阅读，并不会形成任何传输。
local function set_aw(transaction, valid)
    dut.io_mst_aw_valid:set(valid and 1 or 0)
    dut.io_mst_aw_bits_id:set(transaction.id)
    dut.io_mst_aw_bits_addr:set(transaction.addr)
    dut.io_mst_aw_bits_len:set(0)
    dut.io_mst_aw_bits_size:set(0)
    dut.io_mst_aw_bits_burst:set(1)
    dut.io_mst_aw_bits_lock:set(0)
    dut.io_mst_aw_bits_cache:set(0)
    dut.io_mst_aw_bits_prot:set(0)
    dut.io_mst_aw_bits_qos:set(0)
    dut.io_mst_aw_bits_region:set(0)
end

-- 在负沿撤销 AWVALID，确保只在前一个正沿完成一笔地址握手。
local function clear_aw()
    dut.io_mst_aw_valid:set(0)
end

-- 驱动一拍写数据。index 同时编码到数据中，方便 monitor/scoreboard
-- 区分四笔事务；WSTRB=1 表示仅最低字节有效，WLAST=1 表示单拍 burst。
local function set_w(index, valid)
    dut.io_mst_w_valid:set(valid and 1 or 0)
    dut.io_mst_w_bits_data:set(0x100 + index)
    dut.io_mst_w_bits_strb:set(1)
    dut.io_mst_w_bits_last:set(1)
end

-- 与 clear_aw() 对应，在负沿撤销 WVALID。
local function clear_w()
    dut.io_mst_w_valid:set(0)
end

local function task_fifo_depth_vs_reorder_buffer()
    -- 本用例不调用 driver.initialize()，即不启动随机延迟的 AXI Master/
    -- Memory agent。改由 driver.drive() 和 dut 信号直接驱动，可精确控制：
    --   1. 下游 AWREADY 何时施加背压；
    --   2. 上游 WVALID 何时开始发送；
    --   3. 下游 B 响应何时返回。
    -- 因而每次 io_mst_aw_ready 拉低都可归因于当前测试的 FIFO 条件。
    driver.drive {
        -- 上游始终接收 B，避免 B 通道本身成为重排表释放的限制因素。
        io_mst_b_ready = 1,
        -- 第一阶段故意阻塞下游 AW，填满深度为 1 的 AW FIFO。
        io_slv_aw_ready = 0,
        -- 下游始终接收 W，后续只由 W FIFO 的 entry 映射占用造成阻塞。
        io_slv_w_ready = 1,
    }

    -- monitor 已被 env 启动，scoreboard 也会自动比较 AW/W/B 的透传。
    -- 这里额外记录握手数，只用于将端口现象转换成“FIFO/重排表占用”结论：
    --   mst_aw：DUT 接收的写请求数；
    --   slv_aw：DUT 向下游发出的写地址数；
    --   mst_w/slv_w：上游/下游写数据拍数；
    --   mst_b：已返回上游的响应数。
    -- slv_aw_ids 保存下游重映射后的 ID，收尾时用来构造合法 B 响应；
    -- mst_b_ids 保存还原后的上游 ID，用来检查 B 重排是否正确。
    local observed = {
        mst_aw = 0,
        slv_aw = 0,
        mst_w = 0,
        slv_w = 0,
        mst_b = 0,
        slv_aw_ids = {},
        mst_b_ids = {},
    }

    monitor.subscribe(function(sample)
        -- 复位周期的 valid/ready 不代表本测试产生的事务，不能计数。
        if sample.reset == 1 then
            return
        end

        -- 只在真实握手时递增，valid 单独拉高或 ready 单独拉高均不计数。
        if fired(sample.io.mst_aw) then
            observed.mst_aw = observed.mst_aw + 1
        end
        if fired(sample.io.slv_aw) then
            observed.slv_aw = observed.slv_aw + 1
            observed.slv_aw_ids[#observed.slv_aw_ids + 1] =
                sample.io.slv_aw.bits.id
        end
        if fired(sample.io.mst_w) then
            observed.mst_w = observed.mst_w + 1
        end
        if fired(sample.io.slv_w) then
            observed.slv_w = observed.slv_w + 1
        end
        if fired(sample.io.mst_b) then
            observed.mst_b = observed.mst_b + 1
            observed.mst_b_ids[#observed.mst_b_ids + 1] =
                sample.io.mst_b.bits.id
        end
    end)

    -- 生成四笔地址、ID 均不同的单拍写事务。地址也彼此不同，便于波形和
    -- scoreboard 将每一笔下游 AW 与对应上游 AW 匹配。事务数恰好等于
    -- 重排表深度，后续可验证 4 个 entry 最终都能被使用。
    local transactions = {}
    for index = 1, REORDER_DEPTH do
        transactions[index] = {
            id = 0x100 + index,
            addr = 0x1000 + (index - 1) * 0x100,
        }
    end

    -- 从负沿开始施加激励，使其在随后的正沿被 DUT 和 monitor 同时采样。
    wait_negedge()

    -- ====================================================================
    -- 第一阶段：验证深度为 1 的 AW FIFO 会使重排表停在 1/4。
    -- ====================================================================
    -- 下游 AWREADY=0 时先发送 AW1。该地址会被接收并占用一个重排 entry，
    -- 同时进入 AW FIFO；由于 FIFO 无法向下游出队，之后会保持满状态。
    set_aw(transactions[1], true)
    assert(
        dut.io_mst_aw_ready:get() == 1,
        error_message("AW1 was not initially accepted")
    )
    env.wait_cycles(1)
    wait_negedge()
    clear_aw()

    -- AW1 已在上游握手，但下游仍被阻塞，故 slv_aw 必须为 0。
    assert(
        observed.mst_aw == 1,
        error_message("AW1 handshake was not observed")
    )
    assert(
        observed.slv_aw == 0,
        error_message("AW escaped while downstream AW was blocked")
    )

    -- 持续保持 AW2 的 valid。虽然重排表此时仅占用 1/4、仍有 3 个空 entry，
    -- 但 AW FIFO 已满，io_mst_aw_ready 必须持续为 0，AW2 不得握手。
    -- 连续观察三个周期可防止仅检查一个组合周期而遗漏状态变化。
    set_aw(transactions[2], true)
    for _ = 1, 3 do
        assert(
            dut.io_mst_aw_ready:get() == 0,
            error_message(
                "AW FIFO accepted more than one request under AW backpressure"
            )
        )
        env.wait_cycles(1)
        wait_negedge()
    end

    assert(
        observed.mst_aw == AW_FIFO_DEPTH,
        error_message("unexpected upstream AW count in AW FIFO test")
    )
    assert(
        observed.slv_aw == 0,
        error_message("downstream AW fired while AWREADY was low")
    )
    assert(
        REORDER_DEPTH - observed.mst_aw == 3,
        error_message("unexpected reorder occupancy in AW FIFO test")
    )

    -- 至此已从外部端口证明：不是重排表满，而是 AW FIFO 深度只有 1
    -- 导致上游不能继续填充重排表。
    print_message(
        "Observed AW FIFO bottleneck: reorder occupancy=1/4, " ..
        "io_mst_aw_ready stayed low while io_slv_aw_ready=0"
    )

    -- 现在放开下游 AWREADY。AW1 在此拍向下游握手并释放 AW FIFO，AW2
    -- 可在同一拍进入 FIFO。整个过程中不返回 B，因此 AW2 能够被接收
    -- 直接证明上一阶段的阻塞来源是 AW FIFO，而不是重排表已满。
    dut.io_slv_aw_ready:set(1)
    env.wait_cycles(1)
    wait_negedge()
    clear_aw()

    assert(
        observed.mst_aw == 2,
        error_message(
            "AW2 was not accepted when the one-entry AW FIFO was drained"
        )
    )

    wait_until_negedge(function()
        return observed.slv_aw == 2
    end, "the first two downstream AW handshakes")

    assert(
        observed.mst_aw == 2,
        error_message("expected exactly two accepted AW requests")
    )

    -- ====================================================================
    -- 第二阶段：验证深度为 2 的 W FIFO 会使重排表停在 2/4。
    -- ====================================================================
    -- 前两笔 AW 都已向下游发送，但仍未发送任何 W。W FIFO 保存“下一拍
    -- W 应写入哪个重排 entry”的映射，两个 entry 因而全部占用。
    -- 此时 AW FIFO 已空、下游 AWREADY=1，AW3 仍必须无法握手；若不能
    -- 握手，唯一的限制就是 W FIFO 深度，而不是重排表（仍有两个空 entry）。
    set_aw(transactions[3], true)
    for _ = 1, 3 do
        assert(
            dut.io_mst_aw_ready:get() == 0,
            error_message(
                "W FIFO accepted more than two AW mappings without W data"
            )
        )
        env.wait_cycles(1)
        wait_negedge()
    end

    assert(
        observed.mst_aw == W_FIFO_DEPTH,
        error_message("unexpected upstream AW count in W FIFO test")
    )
    assert(
        observed.slv_aw == W_FIFO_DEPTH,
        error_message("unexpected downstream AW count in W FIFO test")
    )
    assert(
        observed.mst_w == 0,
        error_message("upstream W fired before W FIFO stall was checked")
    )
    assert(
        REORDER_DEPTH - observed.mst_aw == 2,
        error_message("unexpected reorder occupancy in W FIFO test")
    )

    -- 上游 AW 已停在 2、上游 W 仍为 0，严格对应 W FIFO 的两个映射槽位。
    print_message(
        "Observed W FIFO bottleneck: reorder occupancy=2/4, " ..
        "io_mst_aw_ready stayed low with downstream AW ready"
    )

    -- 发送 W1（AW3 的 valid 保持不变）。W1 的 WLAST=1 会使 W FIFO 弹出
    -- AW1 对应的映射，从而释放一个槽位；下一拍 AW3 应能握手。整个过程
    -- 仍无 B 响应，故可再次证明此前重排表确有空 entry，只是 W FIFO 满。
    set_w(1, true)
    assert(
        dut.io_mst_w_ready:get() == 1,
        error_message("W1 was not ready")
    )
    env.wait_cycles(1)
    wait_negedge()
    clear_w()

    assert(
        observed.mst_w == 1,
        error_message("W1 handshake was not observed")
    )
    assert(
        dut.io_mst_aw_ready:get() == 1,
        error_message(
            "AW3 did not become ready after one W FIFO entry was consumed"
        )
    )
    env.wait_cycles(1)
    wait_negedge()
    clear_aw()

    wait_until_negedge(function()
        return observed.slv_aw == 3
    end, "the third downstream AW handshake")
    assert(
        observed.mst_aw == 3,
        error_message("expected three accepted AW requests after sending W1")
    )

    -- 再重复一次“AW4 被 W FIFO 阻塞 -> 发送 W2 释放映射 -> 接收 AW4”。
    -- 这说明全部 4 个重排 entry 都可使用，但深度仅为 2 的 W FIFO 要求
    -- 上游持续发送 W 以回收映射槽位，无法一次性填满整个重排表。
    set_aw(transactions[4], true)
    assert(
        dut.io_mst_aw_ready:get() == 0,
        error_message("AW4 should initially be blocked by the refilled W FIFO")
    )
    env.wait_cycles(2)
    wait_negedge()
    assert(
        observed.mst_aw == 3,
        error_message("AW4 was accepted before a W FIFO entry was released")
    )

    set_w(2, true)
    assert(
        dut.io_mst_w_ready:get() == 1,
        error_message("W2 was not ready")
    )
    env.wait_cycles(1)
    wait_negedge()
    clear_w()

    assert(
        dut.io_mst_aw_ready:get() == 1,
        error_message(
            "AW4 did not become ready after the second W mapping was consumed"
        )
    )
    env.wait_cycles(1)
    wait_negedge()
    clear_aw()

    wait_until_negedge(function()
        return observed.slv_aw == REORDER_DEPTH
    end, "all downstream AW handshakes")

    assert(
        observed.mst_aw == REORDER_DEPTH,
        error_message("reorder table did not accept all four AW requests")
    )
    assert(
        observed.mst_b == 0,
        error_message("a B response appeared before downstream B was driven")
    )

    -- 未返回 B 的前提下 mst_aw=4 等价于重排表占用 4/4，表明 buffer 本身
    -- 的容量没有问题；前两个停顿点均来自深度更小的 FIFO。
    print_message(
        "Reached reorder occupancy=4/4 only after draining W FIFO entries"
    )

    -- ====================================================================
    -- 收尾阶段：完成剩余 W，并以逆序 B 验证 ID 还原和资源释放。
    -- ====================================================================
    -- 此时 W FIFO 尚保存 AW3/AW4 的映射。依次发送 W3、W4，等待每拍
    -- io_mst_w_ready 后才跨正沿握手，避免在数据通道引入额外背压。
    for index = 3, REORDER_DEPTH do
        set_w(index, true)
        wait_until_negedge(function()
            return dut.io_mst_w_ready:get() == 1
        end, "upstream W ready")
        env.wait_cycles(1)
        wait_negedge()
        clear_w()
    end

    wait_until_negedge(function()
        return observed.slv_w == REORDER_DEPTH
    end, "all downstream W handshakes")

    assert(
        observed.mst_w == REORDER_DEPTH,
        error_message("not all upstream W beats were accepted")
    )
    assert(
        #observed.slv_aw_ids == REORDER_DEPTH,
        error_message("not all downstream AW IDs were observed")
    )

    -- 所有 AW/W 均已到达下游后，再按相反顺序返回 B。B 的下游 ID 不是
    -- 原始上游 ID，因此从记录的 slv_aw_ids 中取值。DUT 应根据重排表
    -- 将它们还原成 transactions 中的上游 ID；自动 scoreboard 也会做
    -- AW/W/B 一致性检查。
    for index = REORDER_DEPTH, 1, -1 do
        dut.io_slv_b_valid:set(1)
        dut.io_slv_b_bits_id:set(observed.slv_aw_ids[index])
        dut.io_slv_b_bits_resp:set(index % 4)
        assert(
            dut.io_slv_b_ready:get() == 1,
            error_message("downstream B was not ready")
        )
        env.wait_cycles(1)
        wait_negedge()
    end
    dut.io_slv_b_valid:set(0)

    -- 逆序返回时，第一个上游 B 必须属于 transaction[4]，最后一个属于
    -- transaction[1]。该检查确保本用例在制造 FIFO 背压后仍完整验证
    -- B 通道的 ID 映射，而不仅仅停留在 ready 信号观察。
    assert(
        observed.mst_b == REORDER_DEPTH,
        error_message("not all B responses reached the upstream interface")
    )
    for response_index = 1, REORDER_DEPTH do
        local transaction_index = REORDER_DEPTH - response_index + 1
        assert(
            observed.mst_b_ids[response_index] ==
                transactions[transaction_index].id,
            error_message(
                "B response was not restored to the original upstream AXI ID"
            )
        )
    end

    clear_aw()
    clear_w()

    -- 留出两个周期让 monitor 和自动 scoreboard 完成最后一次采样；tc_main
    -- 随后会调用 finish_auto_check()，确认不存在未匹配的 AW/W/B 事务。
    env.wait_cycles(2)

    -- 能到达这里说明已复现并验证：在通道偏斜或下游 AW 背压下，深度小于
    -- 重排表的 AW/W FIFO 会让重排表尚未填满就停止接收新的 AW。
    print_message(
        "FIFO-depth mismatch reproduced: shallow AW/W FIFOs can leave " ..
        "reorder entries unused under channel skew/backpressure"
    )
end

return {
    tasks = {
        task_fifo_depth_vs_reorder_buffer,
    },
}
