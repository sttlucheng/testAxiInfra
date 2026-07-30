local cfg = require "cfg"

-- 009只通过公共monitor观察AXI端口握手。即使运行命令设置了ENABLE=0，
-- 本用例也必须开启monitor，否则无法确认64笔初始AR是否全部进入DUT，
-- 也无法记录目标事务是否真正发往下游以及各外部表项ID的等待周期。
cfg.enable_monitor = true

local env = require "env"
local driver = require "dut.driver"
local monitor = require "dut.monitor"

--[[
================================================================================
009.lua -- 仅依据AXI接口验证AR固定优先级长期阻塞
================================================================================

一、激励结构

  1. 通过公共AXI Master依次发送64笔相同ID的读事务：

       第 1~63 笔：单拍读；
       第 64 笔  ：99拍目标读，目标地址固定为0x40000。

  2. 当外部接口已经观察到64次上游AR握手、并且尚未出现任何初始事务
     RLAST时，即可从接口事实判断：64笔事务均已进入深度为64的AR重排表，
     且还没有表项释放。本用例不读取任何DUT内部valid、依赖计数或发送标志。

  3. 满表后立即进入LOOP补流阶段，不等待目标事务满足发送条件。每当已有事务
     完成、公共Master释放一个task，就提交一笔与初始ID不同的单拍读事务。
     同时未完成的竞争事务使用互不相同的ID。

二、为什么能够验证固定优先级阻塞

  下游ARID由DUT编码为AR重排表项号，因此它属于AXI外部接口信息。目标作为
  第64笔、且满表前没有表项释放，预期占据最后一个表项，目标真正输出时应在
  下游看到：

      slv_ar.id   = 63
      slv_ar.addr = 0x40000
      slv_ar.len  = 98

  009会从外部R握手确认前63笔同ID单拍事务已经全部完成。从该时刻开始，目标
  已不存在同ID前序响应约束。如果此后仍持续看到id小于63的下游AR，而目标
  地址始终没有下游AR握手，则目标的继续等待只能由低编号表项优先输出造成。

  LOOP足够大时，低编号事务持续替换已释放表项，目标长期收不到下游发送机会，
  上游AXI Master也就收不到目标的99拍R响应，最终在w_R状态达到timeout_max。

三、内部信号使用约束

  本文件：

      * 不访问dut.u_AxiReorder或任何其他DUT内部层级；
      * 不访问monitor样本中的internal字段；
      * 不读取表项valid、依赖计数、发送标志或分配命中信号；
      * 不创建私有AXI4Memory，不手工驱动AXI端口。

  全部判定只使用公共driver ticket以及mst_ar、slv_ar、slv_r等AXI接口握手。

四、周期统计

  对下游ARID 0~63分别打印：

      * 下游AR握手次数和RLAST次数；
      * 从上游AR握手到下游AR握手的累计/最大等待周期；
      * 该表项被呈现在下游AR但ARREADY为0的周期；
      * 从下游AR握手到RLAST的累计/最大响应周期；
      * 第一次/最后一次下游AR和最后一次RLAST周期。

  这些统计不依赖内部状态。目标的固定优先级证据单独统计为“所有同ID前序
  完成后、目标输出前，低编号表项在下游AR出现的周期和握手次数”。
================================================================================
]]

local REORDER_DEPTH = 64
local TARGET_ENTRY = REORDER_DEPTH - 1
local INITIAL_SINGLE_COUNT = TARGET_ENTRY

local AXI_BURST_INCR = 1
local AXI_SIZE_32_BYTES = 5
local SINGLE_LEN = 0
local TARGET_BEATS = 99
local TARGET_LEN = TARGET_BEATS - 1

local INITIAL_ID = 0x100
local INITIAL_ADDR_BASE = 0x1000
local INITIAL_ADDR_STRIDE = 0x1000
local TARGET_ADDR = INITIAL_ADDR_BASE +
    TARGET_ENTRY * INITIAL_ADDR_STRIDE

local COMPETITOR_ADDR_BASE = 0x100000
local COMPETITOR_ADDR_STRIDE = 0x20
local MAX_AXI_ADDR = 0xFFFFFFFFFFFF
local MAX_LOOP_COUNT =
    math.floor((MAX_AXI_ADDR - COMPETITOR_ADDR_BASE) /
        COMPETITOR_ADDR_STRIDE) + 1

-- 公共AXI Master的timeout_max为2,000,000周期。009自身的保护上限设置为
-- 2,200,000周期，使长期阻塞时优先看到Master的w_R超时；只有Master超时
-- 机制没有按预期工作时，009才用外部端口快照在额外200,000周期后终止。
local TEST_TIMEOUT = 2200000
local WAIT_TIMEOUT = 100000

local runtime = {
    active = false,
    stage = "009尚未开始",
    loop = 0,
    start_cycle = nil,
    full_cycle = nil,
    replacement_start_cycle = nil,
    first_competitor_submit_cycle = nil,
    predecessors_done_cycle = nil,
    loop_accept_done_cycle = nil,
    end_cycle = nil,

    upstream_ar_count = 0,
    downstream_ar_count = 0,
    total_submitted = 0,
    total_accepted = 0,
    total_completed = 0,

    initial_accepted = 0,
    initial_completed = 0,
    initial_predecessors_completed = 0,
    competitor_submitted = 0,
    competitor_accepted = 0,
    competitor_completed = 0,

    target_guard = false,
    target_pending_cycles_after_full = 0,
    priority_observation_cycles = 0,
    lower_entry_presented_cycles = 0,
    lower_entry_ar_fires_after_predecessors = 0,
    competitor_ar_fires_before_target = 0,
    competitor_ar_fires_after_predecessors = 0,
    observer_failure = nil,
}

-- 只能在下游AR握手时从外部ARID知道事务使用了哪个表项。因此这里统计的是
-- 外部可观测的发送/响应时序，不推测表项内部valid或依赖状态。
local entry_stats = {}
for entry = 0, REORDER_DEPTH - 1 do
    entry_stats[entry] = {
        ar_fires = 0,
        rlast_fires = 0,
        arready_wait = 0,
        ar_wait_total = 0,
        ar_wait_max = 0,
        response_wait_total = 0,
        response_wait_max = 0,
        first_ar_cycle = nil,
        last_ar_cycle = nil,
        last_rlast_cycle = nil,
    }
end

local transactions = {}
local transaction_by_addr = {}
local transaction_by_entry = {}
local competitor_ids_in_use = {}
local next_competitor_id = 0x200
local target_transaction = nil

local function hex(value)
    local number = tonumber(value)
    if number == nil then
        return tostring(value)
    end
    return string.format("0x%x", number)
end

local function fired(channel)
    return channel.valid == 1 and channel.ready == 1
end

local function current_cycle()
    return tonumber(dut.cycles:get()) or 0
end

local function record_observer_failure(reason)
    if runtime.observer_failure == nil then
        runtime.observer_failure = reason
    end
end

local function port_snapshot()
    return string.format(
        "  mst_ar: valid=%s ready=%s id=%s addr=%s len=%s\n" ..
        "  slv_ar: valid=%s ready=%s entry_id=%s addr=%s len=%s\n" ..
        "  slv_r : valid=%s ready=%s entry_id=%s last=%s\n" ..
        "  mst_r : valid=%s ready=%s restored_id=%s last=%s",
        tostring(dut.io_mst_ar_valid:get()),
        tostring(dut.io_mst_ar_ready:get()),
        hex(dut.io_mst_ar_bits_id:get()),
        hex(dut.io_mst_ar_bits_addr:get()),
        tostring(dut.io_mst_ar_bits_len:get()),
        tostring(dut.io_slv_ar_valid:get()),
        tostring(dut.io_slv_ar_ready:get()),
        tostring(dut.io_slv_ar_bits_id:get()),
        hex(dut.io_slv_ar_bits_addr:get()),
        tostring(dut.io_slv_ar_bits_len:get()),
        tostring(dut.io_slv_r_valid:get()),
        tostring(dut.io_slv_r_ready:get()),
        tostring(dut.io_slv_r_bits_id:get()),
        tostring(dut.io_slv_r_bits_last:get()),
        tostring(dut.io_mst_r_valid:get()),
        tostring(dut.io_mst_r_ready:get()),
        hex(dut.io_mst_r_bits_id:get()),
        tostring(dut.io_mst_r_bits_last:get())
    )
end

local function target_snapshot()
    if target_transaction == nil then
        return "目标事务尚未创建"
    end

    local current_wait = 0
    if target_transaction.mst_ar_cycle ~= nil then
        local end_cycle = target_transaction.slv_ar_cycle or current_cycle()
        current_wait = end_cycle - target_transaction.mst_ar_cycle
    end

    return string.format(
        "地址=%s 上游AR周期=%s 下游AR周期=%s 外部表项ID=%s " ..
        "AR等待=%d R拍数=%d/%d RLAST周期=%s ticket.done=%s",
        hex(target_transaction.addr),
        tostring(target_transaction.mst_ar_cycle),
        tostring(target_transaction.slv_ar_cycle),
        tostring(target_transaction.entry),
        current_wait,
        target_transaction.r_beats,
        TARGET_BEATS,
        tostring(target_transaction.rlast_cycle),
        tostring(target_transaction.ticket and
            target_transaction.ticket.done or false)
    )
end

local function entry_statistics_report()
    local lines = {
        "表项 | AR/RLAST | AR等待累计 | AR等待最大 | 等ARREADY | " ..
            "R等待累计 | R等待最大 | 首次AR | 最后AR | 最后RLAST",
        string.rep("-", 119),
    }

    for entry = 0, REORDER_DEPTH - 1 do
        local stat = entry_stats[entry]
        lines[#lines + 1] = string.format(
            "%5d | %4d/%-5d | %10d | %10d | %9d | %9d | " ..
            "%9d | %6s | %6s | %9s",
            entry,
            stat.ar_fires,
            stat.rlast_fires,
            stat.ar_wait_total,
            stat.ar_wait_max,
            stat.arready_wait,
            stat.response_wait_total,
            stat.response_wait_max,
            stat.first_ar_cycle == nil and "-" or
                tostring(stat.first_ar_cycle),
            stat.last_ar_cycle == nil and "-" or
                tostring(stat.last_ar_cycle),
            stat.last_rlast_cycle == nil and "-" or
                tostring(stat.last_rlast_cycle)
        )
    end

    return table.concat(lines, "\n")
end

local function active_entry_report()
    local lines = {}
    for entry = 0, REORDER_DEPTH - 1 do
        local transaction = transaction_by_entry[entry]
        if transaction ~= nil then
            lines[#lines + 1] = string.format(
                "  entry_id %02d: %s，地址=%s，下游AR周期=%s，" ..
                "R拍数=%d/%d",
                entry,
                transaction.name,
                hex(transaction.addr),
                tostring(transaction.slv_ar_cycle),
                transaction.r_beats,
                transaction.beats
            )
        end
    end

    if #lines == 0 then
        return "  外部接口当前没有已发AR但尚未RLAST的事务"
    end
    return table.concat(lines, "\n")
end

-- 错误格式沿用002~007的---ERROR---分隔符。由于本用例不读取内部信号，
-- 错误证据由AXI端口、目标事务、低编号下游AR活动和每个外部表项ID统计组成。
local function error_message(reason)
    local cycle = current_cycle()
    local elapsed = runtime.start_cycle == nil and 0 or
        cycle - runtime.start_cycle

    return string.format(
        "\n\n---ERROR---\n\n" ..
        "009 AR固定优先级阻塞测试失败\n" ..
        "失败原因                   : %s\n" ..
        "当前阶段                   : %s\n" ..
        "当前/已运行周期            : %d / %d\n" ..
        "LOOP                       : %s\n" ..
        "初始接收/完成              : %d/%d / %d/%d\n" ..
        "同ID单拍前序完成           : %d/%d\n" ..
        "竞争提交/接收/完成         : %d/%s / %d/%s / %d/%s\n" ..
        "总提交/接收/完成           : %d / %d / %d\n" ..
        "上游/下游AR握手总数        : %d / %d\n" ..
        "满表后目标未输出周期       : %d\n" ..
        "前序完成后的观察周期       : %d\n" ..
        "低编号AR呈现/握手          : %d / %d\n" ..
        "前序完成后竞争AR握手       : %d\n" ..
        "目标保护                   : %s\n" ..
        "目标状态                   : %s\n\n" ..
        "AXI端口快照：\n%s\n\n" ..
        "已发下游AR且尚未RLAST的外部事务：\n%s\n\n" ..
        "64个外部表项ID周期统计：\n%s\n\n" ..
        "判定说明：64笔同ID事务完成上游AR且没有初始RLAST后立即开始" ..
        "LOOP补流。前63笔同ID单拍响应全部完成以后，如果仍持续出现" ..
        "id<63的下游AR，而目标地址%s没有下游AR和R响应，则目标等待由" ..
        "固定低编号优先级造成。\n\n" ..
        "-----------\n\n",
        reason,
        runtime.stage,
        cycle,
        elapsed,
        tostring(runtime.loop),
        runtime.initial_accepted,
        REORDER_DEPTH,
        runtime.initial_completed,
        REORDER_DEPTH,
        runtime.initial_predecessors_completed,
        INITIAL_SINGLE_COUNT,
        runtime.competitor_submitted,
        tostring(runtime.loop),
        runtime.competitor_accepted,
        tostring(runtime.loop),
        runtime.competitor_completed,
        tostring(runtime.loop),
        runtime.total_submitted,
        runtime.total_accepted,
        runtime.total_completed,
        runtime.upstream_ar_count,
        runtime.downstream_ar_count,
        runtime.target_pending_cycles_after_full,
        runtime.priority_observation_cycles,
        runtime.lower_entry_presented_cycles,
        runtime.lower_entry_ar_fires_after_predecessors,
        runtime.competitor_ar_fires_after_predecessors,
        tostring(runtime.target_guard),
        target_snapshot(),
        port_snapshot(),
        active_entry_report(),
        entry_statistics_report(),
        hex(TARGET_ADDR)
    )
end

local function check(condition, reason)
    if not condition then
        assert(false, error_message(reason))
    end
end

local function print_message(message)
    print(
        "\n\n============================================================\n\n" ..
        message ..
        "\n\n============================================================\n\n"
    )
end

local function transaction_for_addr(addr)
    return transaction_by_addr[tonumber(addr)]
end

-- monitor回调只读取sample.io中的AXI外部端口，不访问sample.internal。
-- 回调不直接assert，而是记录observer_failure；主任务每周期检查后统一生成
-- 带完整外部诊断的中文错误信息。
monitor.subscribe(function(sample)
    if not runtime.active or sample == nil or sample.reset == 1 then
        return
    end

    local cycle = sample.cycles
    local slv_ar = sample.io.slv_ar
    local slv_r = sample.io.slv_r

    if target_transaction ~= nil and
        target_transaction.mst_ar_cycle ~= nil and
        target_transaction.slv_ar_cycle == nil and
        runtime.full_cycle ~= nil then
        runtime.target_pending_cycles_after_full =
            runtime.target_pending_cycles_after_full + 1
    end

    -- 所有同ID单拍前序均已完成后，目标已不再受前序响应顺序约束。此时若
    -- 下游持续呈现更低的表项ID，就是无需内部信号即可观察到的固定优先级证据。
    if runtime.predecessors_done_cycle ~= nil and
        target_transaction ~= nil and
        target_transaction.slv_ar_cycle == nil then
        runtime.priority_observation_cycles =
            runtime.priority_observation_cycles + 1

        if slv_ar.valid == 1 then
            local presented_entry = tonumber(slv_ar.bits.id)
            if presented_entry ~= nil and presented_entry < TARGET_ENTRY then
                runtime.lower_entry_presented_cycles =
                    runtime.lower_entry_presented_cycles + 1
            end
        end
    end

    -- 下游ARVALID已经呈现某个表项但ARREADY为0时，只依据外部握手统计该
    -- 表项的ARREADY等待周期。该数据不包含任何内部仲裁状态推测。
    if slv_ar.valid == 1 and slv_ar.ready == 0 then
        local entry = tonumber(slv_ar.bits.id)
        if entry ~= nil and entry >= 0 and entry < REORDER_DEPTH then
            entry_stats[entry].arready_wait =
                entry_stats[entry].arready_wait + 1
        end
    end

    -- RLAST先处理，以便极端情况下同一外部表项ID在相邻操作中及时解除映射。
    if fired(slv_r) then
        local entry = tonumber(slv_r.bits.id)
        local transaction = entry ~= nil and
            transaction_by_entry[entry] or nil

        if transaction == nil then
            record_observer_failure(string.format(
                "下游R握手的entry_id=%s找不到对应已发AR事务",
                tostring(entry)))
        else
            transaction.r_beats = transaction.r_beats + 1

            if slv_r.bits.last == 1 then
                if transaction.rlast_cycle ~= nil then
                    record_observer_failure(
                        transaction.name .. "发生重复RLAST握手")
                else
                    transaction.rlast_cycle = cycle
                    local stat = entry_stats[entry]
                    local response_wait =
                        cycle - transaction.slv_ar_cycle

                    stat.rlast_fires = stat.rlast_fires + 1
                    stat.response_wait_total =
                        stat.response_wait_total + response_wait
                    if response_wait > stat.response_wait_max then
                        stat.response_wait_max = response_wait
                    end
                    stat.last_rlast_cycle = cycle
                    transaction_by_entry[entry] = nil

                    runtime.total_completed =
                        runtime.total_completed + 1
                    if transaction.kind == "initial" then
                        runtime.initial_completed =
                            runtime.initial_completed + 1

                        if not transaction.is_target then
                            runtime.initial_predecessors_completed =
                                runtime.initial_predecessors_completed + 1

                            if runtime.initial_predecessors_completed ==
                                INITIAL_SINGLE_COUNT then
                                runtime.predecessors_done_cycle = cycle
                            end
                        end
                    else
                        runtime.competitor_completed =
                            runtime.competitor_completed + 1
                        competitor_ids_in_use[transaction.id] = nil
                    end
                end
            end
        end
    end

    -- 上游AR握手只用唯一地址找回测试事务。地址句柄可能是LuaJIT cdata，
    -- 因此查表前必须tonumber，避免数值相同但table键类型不同。
    if fired(sample.io.mst_ar) then
        local transaction = transaction_for_addr(
            sample.io.mst_ar.bits.addr)
        if transaction == nil then
            record_observer_failure(string.format(
                "观察到未登记的上游AR握手，地址=%s",
                hex(sample.io.mst_ar.bits.addr)))
        elseif transaction.mst_ar_cycle ~= nil then
            record_observer_failure(
                transaction.name .. "发生重复上游AR握手")
        else
            runtime.upstream_ar_count = runtime.upstream_ar_count + 1
            runtime.total_accepted = runtime.total_accepted + 1
            transaction.mst_ar_cycle = cycle
            transaction.mst_ar_ordinal = runtime.upstream_ar_count

            if transaction.kind == "initial" then
                runtime.initial_accepted = runtime.initial_accepted + 1
            else
                runtime.competitor_accepted =
                    runtime.competitor_accepted + 1
            end
        end
    end

    -- 下游AR地址可唯一定位事务，外部ARID则给出该事务使用的重排表项号。
    -- 目标在LOOP全部进入DUT前输出会破坏长期阻塞场景，因此当拍记录错误。
    if fired(slv_ar) then
        local transaction = transaction_for_addr(slv_ar.bits.addr)
        local entry = tonumber(slv_ar.bits.id)
        runtime.downstream_ar_count = runtime.downstream_ar_count + 1

        if transaction == nil then
            record_observer_failure(string.format(
                "观察到未登记的下游AR握手，entry_id=%s，地址=%s",
                tostring(entry), hex(slv_ar.bits.addr)))
        elseif entry == nil or entry < 0 or entry >= REORDER_DEPTH then
            record_observer_failure(string.format(
                "%s的下游ARID越界：%s",
                transaction.name, tostring(entry)))
        elseif transaction.slv_ar_cycle ~= nil then
            record_observer_failure(
                transaction.name .. "发生重复下游AR握手")
        elseif transaction_by_entry[entry] ~= nil then
            record_observer_failure(string.format(
                "%s使用entry_id=%d时，该ID仍关联事务%s",
                transaction.name,
                entry,
                transaction_by_entry[entry].name))
        else
            transaction.slv_ar_cycle = cycle
            transaction.slv_ar_ordinal = runtime.downstream_ar_count
            transaction.entry = entry
            transaction_by_entry[entry] = transaction

            local stat = entry_stats[entry]
            local ar_wait = cycle - transaction.mst_ar_cycle
            stat.ar_fires = stat.ar_fires + 1
            stat.ar_wait_total = stat.ar_wait_total + ar_wait
            if ar_wait > stat.ar_wait_max then
                stat.ar_wait_max = ar_wait
            end
            stat.first_ar_cycle = stat.first_ar_cycle or cycle
            stat.last_ar_cycle = cycle

            if entry < TARGET_ENTRY and
                target_transaction ~= nil and
                target_transaction.slv_ar_cycle == nil then
                if runtime.predecessors_done_cycle ~= nil then
                    runtime.lower_entry_ar_fires_after_predecessors =
                        runtime.lower_entry_ar_fires_after_predecessors + 1
                end
            end

            if transaction.kind == "competitor" and
                target_transaction ~= nil and
                target_transaction.slv_ar_cycle == nil then
                runtime.competitor_ar_fires_before_target =
                    runtime.competitor_ar_fires_before_target + 1

                if runtime.predecessors_done_cycle ~= nil then
                    runtime.competitor_ar_fires_after_predecessors =
                        runtime.competitor_ar_fires_after_predecessors + 1
                end
            end

            if transaction.is_target then
                if entry ~= TARGET_ENTRY then
                    record_observer_failure(string.format(
                        "目标事务下游ARID错误：期望entry_id=63，实际=%d",
                        entry))
                end
                if runtime.target_guard then
                    record_observer_failure(string.format(
                        "目标事务在LOOP全部进入DUT以前提前输出：" ..
                        "目标AR周期=%d，竞争接收=%d/%d",
                        cycle,
                        runtime.competitor_accepted,
                        runtime.loop))
                end
            end
        end
    end
end)

local function make_initial_transaction(index)
    local is_target = index == REORDER_DEPTH
    return {
        name = is_target and
            "初始事务64/目标事务(预期entry 63, 99拍)" or
            string.format("初始事务%02d(单拍)", index),
        kind = "initial",
        initial_index = index,
        is_target = is_target,
        id = INITIAL_ID,
        addr = INITIAL_ADDR_BASE +
            (index - 1) * INITIAL_ADDR_STRIDE,
        burst = AXI_BURST_INCR,
        len = is_target and TARGET_LEN or SINGLE_LEN,
        size = AXI_SIZE_32_BYTES,
        beats = is_target and TARGET_BEATS or 1,
        ticket = nil,
        entry = nil,
        mst_ar_cycle = nil,
        mst_ar_ordinal = nil,
        slv_ar_cycle = nil,
        slv_ar_ordinal = nil,
        rlast_cycle = nil,
        r_beats = 0,
    }
end

-- 从12位ID空间挑选当前没有竞争事务占用的ID。最大并发不超过64，远小于
-- 可用ID数量；排除初始ID并在RLAST后回收，可避免竞争事务彼此产生同ID依赖。
local function allocate_competitor_id()
    for _ = 1, 4096 do
        local candidate = next_competitor_id
        next_competitor_id = (next_competitor_id + 1) % 4096

        if candidate ~= INITIAL_ID and
            competitor_ids_in_use[candidate] == nil then
            return candidate
        end
    end

    check(false, "12位AXI ID空间中找不到空闲竞争ID")
end

local function make_competitor_transaction(index)
    return {
        name = string.format("LOOP竞争事务%06d(单拍)", index),
        kind = "competitor",
        competitor_index = index,
        is_target = false,
        id = allocate_competitor_id(),
        addr = COMPETITOR_ADDR_BASE +
            (index - 1) * COMPETITOR_ADDR_STRIDE,
        burst = AXI_BURST_INCR,
        len = SINGLE_LEN,
        size = AXI_SIZE_32_BYTES,
        beats = 1,
        ticket = nil,
        entry = nil,
        mst_ar_cycle = nil,
        mst_ar_ordinal = nil,
        slv_ar_cycle = nil,
        slv_ar_ordinal = nil,
        rlast_cycle = nil,
        r_beats = 0,
    }
end

local function register_successful_submission(transaction, ticket)
    transaction.ticket = ticket
    transactions[#transactions + 1] = transaction
    transaction_by_addr[transaction.addr] = transaction
    runtime.total_submitted = runtime.total_submitted + 1

    if transaction.kind == "competitor" then
        competitor_ids_in_use[transaction.id] = transaction
        runtime.competitor_submitted =
            runtime.competitor_submitted + 1
        if runtime.first_competitor_submit_cycle == nil then
            runtime.first_competitor_submit_cycle = current_cycle()
        end
    end
end

local function submit_transaction(transaction)
    check(transaction_by_addr[transaction.addr] == nil,
        string.format("事务地址重复：%s", hex(transaction.addr)))

    local ret, ticket = driver.noblock_read(
        transaction.addr,
        transaction.burst,
        transaction.len,
        transaction.size,
        transaction.id
    )

    if ret == "Success" then
        register_successful_submission(transaction, ticket)
    end
    return ret
end

local function check_async_failure()
    check(runtime.observer_failure == nil,
        runtime.observer_failure or "monitor观察器报告未知错误")

    if runtime.start_cycle ~= nil then
        check(current_cycle() - runtime.start_cycle < TEST_TIMEOUT,
            string.format(
                "009总运行时间达到保护上限%d周期；公共Master的" ..
                "2,000,000周期超时检查没有先触发",
                TEST_TIMEOUT))
    end
end

local function advance_one_cycle()
    env.wait_cycles(1)
    check_async_failure()
end

local function wait_until(predicate, description, timeout)
    local limit = timeout or WAIT_TIMEOUT
    for _ = 1, limit do
        check_async_failure()
        if predicate() then
            return
        end
        advance_one_cycle()
    end
    check(false, "等待" .. description .. "超时")
end

local function all_tickets_done()
    for _, transaction in ipairs(transactions) do
        if transaction.ticket == nil or not transaction.ticket.done then
            return false
        end
    end
    return true
end

local function all_external_entries_idle()
    for entry = 0, REORDER_DEPTH - 1 do
        if transaction_by_entry[entry] ~= nil then
            return false
        end
    end
    return true
end

local function verify_ticket(transaction)
    local ticket = transaction.ticket
    check(ticket ~= nil, transaction.name .. "没有返回ticket")
    check(ticket.done, transaction.name .. "的ticket尚未完成")
    check(ticket.result ~= nil, transaction.name .. "完成后没有result快照")
    check(ticket.result.addr == transaction.addr,
        string.format(
            "%s返回地址错误：期望=%s，实际=%s",
            transaction.name,
            hex(transaction.addr),
            hex(ticket.result.addr)))
    check(ticket.result.axid == transaction.id,
        string.format(
            "%s返回ID错误：期望=%s，实际=%s",
            transaction.name,
            hex(transaction.id),
            hex(ticket.result.axid)))
    check(ticket.result.len == transaction.len,
        string.format(
            "%s返回ARLEN错误：期望=%d，实际=%s",
            transaction.name,
            transaction.len,
            tostring(ticket.result.len)))
    check(ticket.data_vec ~= nil,
        transaction.name .. "完成后没有RDATA数组")
    check(#ticket.data_vec == transaction.beats,
        string.format(
            "%s返回拍数错误：期望=%d，ticket实际=%d",
            transaction.name,
            transaction.beats,
            #ticket.data_vec))
    check(transaction.r_beats == transaction.beats,
        string.format(
            "%s外部端口统计拍数错误：期望=%d，实际=%d",
            transaction.name,
            transaction.beats,
            transaction.r_beats))
end

local function sum_entry_field(field)
    local total = 0
    for entry = 0, REORDER_DEPTH - 1 do
        total = total + entry_stats[entry][field]
    end
    return total
end

local function task_test()
    local loop_text = os.getenv("LOOP")
    local loop = loop_text == nil and 1000 or tonumber(loop_text)

    runtime.loop = loop or loop_text
    check(
        type(loop) == "number" and
            loop == math.floor(loop) and
            loop >= 1 and
            loop <= MAX_LOOP_COUNT,
        string.format(
            "LOOP=%s非法；LOOP必须是1~%d的整数",
            tostring(loop_text), MAX_LOOP_COUNT)
    )
    runtime.loop = loop
    local expected_total = REORDER_DEPTH + loop

    -- 公共initialize同时启动公共AXI4MasterV2和公共AXI4Memory。009不创建
    -- 私有Slave，也不调用driver.drive()覆盖公共组件驱动的端口。
    driver.initialize()
    env.wait_cycles(1)

    runtime.active = true
    runtime.start_cycle = current_cycle()
    runtime.stage = "依次提交64笔同ID初始读事务"

    print_message(string.format(
        "009用例开始：仅使用公共AXI Master/Slave和AXI外部端口。\n\n" ..
        "AR重排表深度                 : %d\n" ..
        "初始事务                     : 64笔同ID=%s，前63笔单拍，" ..
        "最后1笔99拍\n" ..
        "目标事务                     : 地址=%s，预期下游entry_id=63\n" ..
        "满表判定                     : 64次上游AR握手且初始RLAST=0\n" ..
        "满表后动作                   : 不等待任何内部状态，立即开始补流\n" ..
        "竞争替换事务                 : LOOP=%d，均为不同ID单拍读\n" ..
        "内部信号                     : 完全不读取\n" ..
        "公共Slave随机配置            : AR延迟20~40周期，R延迟" ..
        "100~200周期，R响应允许乱序",
        REORDER_DEPTH,
        hex(INITIAL_ID),
        hex(TARGET_ADDR),
        loop
    ))

    -- 每笔初始事务等待真实上游AR握手后再提交下一笔，确保Master内部随机
    -- task调度不会改变提交顺序。只要64笔握手完成前没有任何初始RLAST，
    -- 深度64的表就必然没有释放位置，因而可由外部事实确认曾经满表。
    local initial_transactions = {}
    for index = 1, REORDER_DEPTH do
        local transaction = make_initial_transaction(index)
        initial_transactions[index] = transaction
        if transaction.is_target then
            target_transaction = transaction
        end

        local ret = submit_transaction(transaction)
        check(ret == "Success",
            string.format(
                "%s提交失败：%s。公共Master nr_task和nr_ar_taskbuf" ..
                "必须至少为64",
                transaction.name, tostring(ret)))

        wait_until(function()
            return transaction.mst_ar_cycle ~= nil
        end, transaction.name .. "完成上游AR握手")

        check(transaction.mst_ar_ordinal == index,
            string.format(
                "%s上游AR顺序错误：期望第%d笔，实际第%s笔",
                transaction.name,
                index,
                tostring(transaction.mst_ar_ordinal)))
        check(runtime.initial_completed == 0,
            string.format(
                "只接收%d/64笔初始事务时已有%d笔完成，无法从外部接口" ..
                "证明64项曾同时占用",
                runtime.initial_accepted,
                runtime.initial_completed))
    end

    check(runtime.initial_accepted == REORDER_DEPTH,
        string.format("初始AR接收数错误：期望64，实际%d",
            runtime.initial_accepted))
    check(runtime.initial_completed == 0,
        "第64笔上游AR握手完成时已有初始事务RLAST，满表条件不成立")
    check(target_transaction.mst_ar_ordinal == REORDER_DEPTH,
        "99拍目标事务不是第64笔上游AR")

    runtime.full_cycle = current_cycle()
    runtime.replacement_start_cycle = runtime.full_cycle
    runtime.target_guard = true
    runtime.stage = "满表后立即循环补入不同ID单拍事务"

    print_message(string.format(
        "已在周期%d从AXI外部接口确认满表条件成立：\n" ..
        "  * 上游AR握手=%d/64；\n" ..
        "  * 初始事务RLAST=0；\n" ..
        "  * 目标是第64笔上游AR，地址=%s。\n\n" ..
        "现在立即进入LOOP=%d补流，不等待目标依赖状态变化。" ..
        "由于64个Master task此刻均被占用，第一次竞争事务会在首笔" ..
        "初始响应完成、task释放后马上提交。",
        runtime.full_cycle,
        runtime.initial_accepted,
        hex(TARGET_ADDR),
        loop
    ))

    -- 满表后的主循环始终尽快维持64笔未完成事务。RLAST到达时DUT表项已经
    -- 释放，但Master task还可能经过WillFree状态，因此NoTaskIDAvailable是
    -- 可按周期重试的短暂状态；其他返回值均表示配置或事务参数错误。
    local pending_competitor = nil
    local progress_step = math.max(1, math.floor(loop / 10))

    while runtime.competitor_submitted < loop do
        check_async_failure()

        local outstanding =
            runtime.total_submitted - runtime.total_completed
        if outstanding < REORDER_DEPTH then
            if pending_competitor == nil then
                pending_competitor = make_competitor_transaction(
                    runtime.competitor_submitted + 1)
            end

            local ret = submit_transaction(pending_competitor)
            if ret == "Success" then
                local submitted = runtime.competitor_submitted
                pending_competitor = nil

                if submitted == loop or submitted % progress_step == 0 then
                    print(string.format(
                        "[009补流进度] 提交=%d/%d，入DUT=%d/%d，" ..
                        "完成=%d/%d；同ID前序完成=%d/63；" ..
                        "目标下游AR=%s；前序完成后竞争AR=%d",
                        submitted,
                        loop,
                        runtime.competitor_accepted,
                        loop,
                        runtime.competitor_completed,
                        loop,
                        runtime.initial_predecessors_completed,
                        tostring(target_transaction.slv_ar_cycle),
                        runtime.competitor_ar_fires_after_predecessors
                    ))
                end
            else
                check(ret == "NoTaskIDAvailable",
                    string.format(
                        "%s提交失败：%s",
                        pending_competitor.name, tostring(ret)))
            end
        end

        if runtime.competitor_submitted < loop then
            advance_one_cycle()
        end
    end

    -- API提交成功不代表AR已经进入DUT。目标保护保持到最后一笔LOOP事务完成
    -- 真实上游AR握手，保证停止补流前所有用户指定的竞争事务都已生效。
    runtime.stage = "等待全部LOOP事务完成上游AR握手"
    wait_until(function()
        return runtime.competitor_accepted == loop
    end, string.format("%d笔LOOP事务全部进入DUT", loop), TEST_TIMEOUT)

    check(target_transaction.slv_ar_cycle == nil,
        string.format(
            "目标在LOOP全部进入DUT以前已经输出，周期=%s；请增大LOOP",
            tostring(target_transaction.slv_ar_cycle)))
    check(runtime.predecessors_done_cycle ~= nil,
        string.format(
            "LOOP结束时同ID单拍前序只完成%d/63笔，尚不能排除同ID顺序" ..
            "约束；请增大LOOP",
            runtime.initial_predecessors_completed))
    check(runtime.competitor_ar_fires_after_predecessors > 0,
        "同ID前序全部完成后没有观察到竞争事务下游AR，未形成固定优先级证据")

    runtime.loop_accept_done_cycle = current_cycle()
    runtime.target_guard = false

    print_message(string.format(
        "LOOP补流阶段完成。\n" ..
        "竞争事务提交/入DUT/完成       : %d/%d/%d\n" ..
        "同ID单拍前序完成周期          : %d\n" ..
        "前序完成后观察周期            : %d\n" ..
        "前序完成后低编号AR呈现/握手   : %d/%d\n" ..
        "前序完成后竞争AR握手          : %d\n" ..
        "目标下游AR                    : 尚未发生\n" ..
        "目标从满表后已等待            : %d周期\n\n" ..
        "以上证据全部来自AXI外部接口：同ID前序已经全部完成，" ..
        "低编号竞争事务仍持续输出，而目标地址%s没有下游AR。" ..
        "现在停止补流并等待低编号事务排空。",
        runtime.competitor_submitted,
        runtime.competitor_accepted,
        runtime.competitor_completed,
        runtime.predecessors_done_cycle,
        runtime.priority_observation_cycles,
        runtime.lower_entry_presented_cycles,
        runtime.lower_entry_ar_fires_after_predecessors,
        runtime.competitor_ar_fires_after_predecessors,
        runtime.loop_accept_done_cycle - runtime.full_cycle,
        hex(TARGET_ADDR)
    ))

    runtime.stage = "停止补流并等待目标成为最后一笔下游AR"
    wait_until(function()
        return target_transaction.slv_ar_cycle ~= nil
    end, "目标事务完成下游AR握手", TEST_TIMEOUT)

    check(target_transaction.entry == TARGET_ENTRY,
        string.format(
            "目标下游ARID错误：期望63，实际=%s",
            tostring(target_transaction.entry)))
    check(target_transaction.slv_ar_cycle >=
        runtime.loop_accept_done_cycle,
        "目标下游AR周期早于LOOP全部入DUT周期")
    check(target_transaction.slv_ar_ordinal == expected_total,
        string.format(
            "目标不是最后一笔下游AR：目标序号=%s，期望=%d",
            tostring(target_transaction.slv_ar_ordinal),
            expected_total))

    runtime.stage = "等待目标99拍响应及全部公共Master ticket完成"
    wait_until(all_tickets_done, "全部读事务ticket完成", TEST_TIMEOUT)
    wait_until(all_external_entries_idle,
        "所有已发下游AR事务收到RLAST", WAIT_TIMEOUT)

    -- 多等两个周期，让公共Master的WillFree状态和monitor完成最后更新。
    env.wait_cycles(2)
    check_async_failure()
    runtime.end_cycle = current_cycle()

    check(runtime.total_submitted == expected_total,
        string.format(
            "总提交数错误：期望=%d，实际=%d",
            expected_total, runtime.total_submitted))
    check(runtime.total_accepted == expected_total,
        string.format(
            "总上游AR握手数错误：期望=%d，实际=%d",
            expected_total, runtime.total_accepted))
    check(runtime.downstream_ar_count == expected_total,
        string.format(
            "总下游AR握手数错误：期望=%d，实际=%d",
            expected_total, runtime.downstream_ar_count))
    check(runtime.total_completed == expected_total,
        string.format(
            "总RLAST数错误：期望=%d，实际=%d",
            expected_total, runtime.total_completed))
    check(runtime.initial_completed == REORDER_DEPTH,
        string.format("初始事务完成数错误：%d/64",
            runtime.initial_completed))
    check(runtime.competitor_completed == loop,
        string.format("竞争事务完成数错误：%d/%d",
            runtime.competitor_completed, loop))
    check(target_transaction.r_beats == TARGET_BEATS,
        string.format("目标R拍数错误：期望99，实际%d",
            target_transaction.r_beats))
    check(target_transaction.rlast_cycle ~= nil,
        "目标没有观察到RLAST握手")
    check(runtime.priority_observation_cycles > 0 and
        runtime.lower_entry_presented_cycles > 0 and
        runtime.lower_entry_ar_fires_after_predecessors > 0 and
        runtime.competitor_ar_fires_after_predecessors > 0,
        "没有形成同ID前序完成后的外部固定优先级阻塞证据")
    check(all_external_entries_idle(),
        "收尾时仍有已发下游AR但未收到RLAST的事务")

    for _, transaction in ipairs(transactions) do
        verify_ticket(transaction)
    end

    local run_cycles = runtime.end_cycle - runtime.start_cycle
    local target_total_ar_wait =
        target_transaction.slv_ar_cycle - target_transaction.mst_ar_cycle
    local target_wait_after_predecessors =
        target_transaction.slv_ar_cycle - runtime.predecessors_done_cycle
    local target_response_wait =
        target_transaction.rlast_cycle - target_transaction.slv_ar_cycle

    print_message(string.format(
        "009 AR固定优先级长期阻塞测试通过。\n\n" ..
        "信号使用情况：\n" ..
        "  * AXI Master/Slave来源          = dut.driver公共实例\n" ..
        "  * DUT内部层级/内部表项信号      = 未访问\n" ..
        "  * monitor内部字段               = 未访问\n" ..
        "  * 私有AXI4Memory/手工端口驱动   = 未使用\n\n" ..
        "事务与运行统计：\n" ..
        "  * 初始同ID事务                  = 64笔（63笔单拍+1笔99拍）\n" ..
        "  * 满表后立即补流                = 是\n" ..
        "  * LOOP竞争事务                  = %d笔单拍\n" ..
        "  * 总提交/上游AR/下游AR/RLAST    = %d/%d/%d/%d\n" ..
        "  * 开始/满表/首笔竞争提交周期    = %d/%d/%s\n" ..
        "  * 前序完成/LOOP入DUT/结束周期   = %d/%d/%d\n" ..
        "  * 用例总运行周期                = %d\n\n" ..
        "目标事务外部统计：\n" ..
        "  * 地址/下游表项ID               = %s/%d\n" ..
        "  * 下游AR序号                    = %d/%d（最后一笔）\n" ..
        "  * 上游AR到下游AR等待            = %d周期\n" ..
        "  * 同ID前序全部完成后继续等待    = %d周期\n" ..
        "  * 前序完成后低编号AR呈现周期    = %d周期\n" ..
        "  * 前序完成后低编号AR握手        = %d次\n" ..
        "  * 前序完成后竞争AR握手          = %d次\n" ..
        "  * 目标R返回                     = %d拍（含1次RLAST）\n" ..
        "  * 下游AR到目标RLAST             = %d周期\n\n" ..
        "64个外部表项ID累计：\n" ..
        "  * AR等待累计                    = %d周期\n" ..
        "  * ARREADY等待累计               = %d周期\n" ..
        "  * R响应等待累计                 = %d周期\n" ..
        "  * 最终未完成外部表项映射        = 0\n\n" ..
        "结论：64笔初始事务满表后立即开始补流。前63笔同ID事务" ..
        "全部完成以后，外部接口仍持续选择低编号表项，目标地址%s" ..
        "继续等待且最终是最后一笔下游AR。这是在不读取任何内部信号" ..
        "条件下得到的固定低编号优先级阻塞证据。",
        loop,
        runtime.total_submitted,
        runtime.total_accepted,
        runtime.downstream_ar_count,
        runtime.total_completed,
        runtime.start_cycle,
        runtime.full_cycle,
        tostring(runtime.first_competitor_submit_cycle),
        runtime.predecessors_done_cycle,
        runtime.loop_accept_done_cycle,
        runtime.end_cycle,
        run_cycles,
        hex(target_transaction.addr),
        target_transaction.entry,
        target_transaction.slv_ar_ordinal,
        expected_total,
        target_total_ar_wait,
        target_wait_after_predecessors,
        runtime.lower_entry_presented_cycles,
        runtime.lower_entry_ar_fires_after_predecessors,
        runtime.competitor_ar_fires_after_predecessors,
        target_transaction.r_beats,
        target_response_wait,
        sum_entry_field("ar_wait_total"),
        sum_entry_field("arready_wait"),
        sum_entry_field("response_wait_total"),
        hex(TARGET_ADDR)
    ))

    print_message(
        "009全部64个外部表项ID的发送/响应周期明细：\n\n" ..
        entry_statistics_report()
    )

    runtime.active = false
end

return {
    tasks = {
        task_test,
    },
}
