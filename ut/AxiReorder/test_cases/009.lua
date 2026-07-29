local cfg = require "cfg"

-- 009 依靠公共 monitor 在每个周期采集 AXI 握手和 64 个 AR 表项的内部状态。
-- 即使运行命令设置了 ENABLE=0，本用例也必须打开 monitor，否则无法精确统计
-- 每个表项的阻塞周期，也无法在目标事务提前输出的当拍立即留下证据。
cfg.enable_monitor = true

local env = require "env"
local driver = require "dut.driver"
local monitor = require "dut.monitor"

--[[
================================================================================
009.lua -- 使用公共 AXI Master/Slave 验证 AR 固定优先级长期阻塞
================================================================================

一、测试目标

  AR 重排表深度为 64，输出仲裁优先级为：

      entry 0 > entry 1 > ... > entry 62 > entry 63

  本用例先通过公共 AXI Master 连续发送 64 笔相同 ID 的读事务：

      entry 0~62：各 1 拍读；
      entry 63   ：99 拍目标读事务。

  64 笔读必须同时驻留过重排表，才能证明测试确实占满了表。相同 ID 使后续
  事务依赖前序 RLAST；随着前 63 笔单拍读依次完成，目标 entry 63 的 nid 从
  63 逐步降为 0。

二、替换流和 LOOP

  初始表占满以后，先让前 62 笔单拍读自然完成。当最后一个同 ID 前序
  entry 62 已完成下游 AR 握手、正在等待 R 返回时，利用公共 Slave 至少
  100 周期的响应延迟窗口，通过公共 Master 预提交 62 笔单拍竞争读，填入
  entry 0~61。竞争事务的 ID 与初始 ID 不同，而且所有同时未完成的竞争事务
  ID 互不相同。目标从 nid=1 降为 0 时，低编号表项中已经存在可发送竞争项。

  上述 62 笔预填事务只用于建立初始竞争状态，不计入 LOOP。LOOP 表示目标
  已经 nid=0 后继续补入的单拍竞争事务总数，默认值为 1000。LOOP 越大，
  entry 63 在可发送状态下受到固定优先级阻塞的时间越长。最后一笔 LOOP
  事务真正完成上游 AR 握手、进入重排表以前，目标不允许下游 AR 握手。

三、Slave 使用约束

  本用例只调用 driver.initialize()，因此 Master 和 Slave 都来自公共 driver：

      * 不创建 009 私有 AXI4Memory；
      * 不直接驱动 io_mst_* 或 io_slv_*；
      * ARREADY 和 RVALID 完全由公共 AXI4Memory 的随机延迟逻辑产生。

四、周期统计定义

  对 entry 0~63 分别统计：

      * 同 ID 阻塞：valid=1、haveSendAR=0、nid>0；
      * 固定优先级阻塞：本项已 nid=0，但仲裁器选择了更低编号表项；
      * ARREADY 阻塞：本项已被仲裁器选择，但下游 ARREADY=0；
      * AR 阻塞总数：上述状态中尚未完成下游 AR 握手的采样周期总数；
      * 驻留周期：表项 valid=1 的累计采样周期；
      * 初始事务 AR 等待/驻留：最初占据该表项的事务的单独统计值。

  成功时打印全部 64 项；失败时除上述统计外，还打印当前 AXI 端口、目标状态、
  循环进度和完整 AR 表快照，便于直接从日志定位提前输出、丢事务或超时原因。
================================================================================
]]

local REORDER_DEPTH = 64
local TARGET_ENTRY = REORDER_DEPTH - 1
local INITIAL_PREDECESSORS = TARGET_ENTRY
local PRELOAD_COMPETITORS = INITIAL_PREDECESSORS - 1

local AXI_BURST_INCR = 1
local AXI_SIZE_32_BYTES = 5
local SINGLE_LEN = 0
local TARGET_BEATS = 99
local TARGET_LEN = TARGET_BEATS - 1

local INITIAL_ID = 0x100
local INITIAL_ADDR_BASE = 0x1000
local INITIAL_ADDR_STRIDE = 0x1000
local COMPETITOR_ADDR_BASE = 0x100000
local COMPETITOR_ADDR_STRIDE = 0x20
local MAX_AXI_ADDR = 0xFFFFFFFFFFFF
local MAX_COMPETITOR_COUNT =
    math.floor((MAX_AXI_ADDR - COMPETITOR_ADDR_BASE) /
        COMPETITOR_ADDR_STRIDE) + 1

-- 目标事务从测试开始便占用公共 Master task。当前公共 AXI Master 的
-- timeout_max 是 2,000,000 周期；这里将009自身的保护上限设置为
-- 2,200,000 周期，确保目标AR长期卡在重排表中、始终收不到R响应时，优先
-- 触发公共Master自身的超时检查。额外保留200,000周期余量，仅在Master超时
-- 机制没有按预期生效时，才由009的详细错误快照终止仿真。
local TEST_TIMEOUT = 2200000
local WAIT_TIMEOUT = 100000

local core = dut.u_AxiReorder
local ar_entries = {}
for entry = 0, REORDER_DEPTH - 1 do
    ar_entries[entry] = {
        valid = core["rvld_" .. entry]:chdl(),
        id = core["arinfo_" .. entry .. "_bits_id"]:chdl(),
        addr = core["arinfo_" .. entry .. "_bits_addr"]:chdl(),
        nid = core["arinfo_" .. entry .. "_nid"]:chdl(),
        have_sent = core["arinfo_" .. entry .. "_haveSendAR"]:chdl(),
        alloc_hit = core["ar_mst_fire_hit_" .. entry]:chdl(),
    }
end

local selected_entry = core.selSendAR:chdl()

local runtime = {
    active = false,
    stage = "009 尚未开始",
    loop = 0,
    start_cycle = nil,
    full_cycle = nil,
    preload_start_cycle = nil,
    preload_accept_done_cycle = nil,
    loop_accept_done_cycle = nil,
    end_cycle = nil,
    total_submitted = 0,
    total_accepted = 0,
    total_completed = 0,
    initial_accepted = 0,
    initial_completed = 0,
    competitor_submitted = 0,
    competitor_accepted = 0,
    competitor_completed = 0,
    preload_submitted = 0,
    preload_accepted = 0,
    preload_completed = 0,
    loop_submitted = 0,
    loop_accepted = 0,
    loop_completed = 0,
    downstream_ar_count = 0,
    max_occupancy = 0,
    guard_target = false,
    observer_failure = nil,
}

local entry_stats = {}
for entry = 0, REORDER_DEPTH - 1 do
    entry_stats[entry] = {
        allocations = 0,
        completions = 0,
        ar_blocked = 0,
        same_id_blocked = 0,
        priority_blocked = 0,
        arready_blocked = 0,
        arbitration_gap = 0,
        resident_cycles = 0,
        completed_resident_cycles = 0,
        initial_ar_wait = nil,
        initial_resident = nil,
        current = nil,
    }
end

local transactions = {}
local transaction_by_addr = {}
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

local function ar_table_snapshot()
    local lines = {}
    for entry = 0, REORDER_DEPTH - 1 do
        local signals = ar_entries[entry]
        local stat = entry_stats[entry]
        local current_name = "无"
        if stat.current ~= nil then
            current_name = stat.current.name
        end

        lines[#lines + 1] = string.format(
            "  entry %02d: valid=%s id=%s addr=%s nid=%s " ..
            "haveSendAR=%s allocHit=%s 当前事务=%s",
            entry,
            tostring(signals.valid:get()),
            hex(signals.id:get()),
            hex(signals.addr:get()),
            tostring(signals.nid:get()),
            tostring(signals.have_sent:get()),
            tostring(signals.alloc_hit:get()),
            current_name
        )
    end
    return table.concat(lines, "\n")
end

local function entry_statistics_report()
    local lines = {
        "表项 | 分配/完成 | AR阻塞总数 | 同ID阻塞 | 固定优先级 | 等ARREADY | " ..
            "仲裁空档 | 驻留累计 | 初始AR等待 | 初始驻留",
        string.rep("-", 112),
    }

    for entry = 0, REORDER_DEPTH - 1 do
        local stat = entry_stats[entry]
        lines[#lines + 1] = string.format(
            "%5d | %4d/%-4d | %10d | %8d | %10d | %9d | %8d | " ..
            "%8d | %10s | %8s",
            entry,
            stat.allocations,
            stat.completions,
            stat.ar_blocked,
            stat.same_id_blocked,
            stat.priority_blocked,
            stat.arready_blocked,
            stat.arbitration_gap,
            stat.resident_cycles,
            stat.initial_ar_wait == nil and "-" or
                tostring(stat.initial_ar_wait),
            stat.initial_resident == nil and "-" or
                tostring(stat.initial_resident)
        )
    end

    return table.concat(lines, "\n")
end

local function port_snapshot()
    return string.format(
        "  mst_ar: valid=%s ready=%s id=%s addr=%s len=%s\n" ..
        "  slv_ar: valid=%s ready=%s entry=%s selected=%s addr=%s len=%s\n" ..
        "  slv_r : valid=%s ready=%s entry=%s last=%s\n" ..
        "  mst_r : valid=%s ready=%s restored_id=%s last=%s",
        tostring(dut.io_mst_ar_valid:get()),
        tostring(dut.io_mst_ar_ready:get()),
        hex(dut.io_mst_ar_bits_id:get()),
        hex(dut.io_mst_ar_bits_addr:get()),
        tostring(dut.io_mst_ar_bits_len:get()),
        tostring(dut.io_slv_ar_valid:get()),
        tostring(dut.io_slv_ar_ready:get()),
        tostring(dut.io_slv_ar_bits_id:get()),
        tostring(selected_entry:get()),
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

    return string.format(
        "entry=%s mstAR=%s slvAR=%s R拍数=%d/%d RLAST=%s " ..
        "nid0首次周期=%s ticket.done=%s",
        tostring(target_transaction.entry),
        tostring(target_transaction.mst_ar_cycle),
        tostring(target_transaction.slv_ar_cycle),
        target_transaction.r_beats,
        TARGET_BEATS,
        tostring(target_transaction.rlast_cycle),
        tostring(target_transaction.sendable_cycle),
        tostring(target_transaction.ticket and
            target_transaction.ticket.done or false)
    )
end

-- 错误格式沿用 002~007 的 ---ERROR--- 分隔符，并补充009所需的全部诊断。
local function error_message(reason)
    local cycle = current_cycle()
    local elapsed = runtime.start_cycle == nil and 0 or
        cycle - runtime.start_cycle

    return string.format(
        "\n\n---ERROR---\n\n" ..
        "009 AR 固定优先级阻塞测试失败\n" ..
        "失败原因             : %s\n" ..
        "当前阶段             : %s\n" ..
        "当前/已运行周期      : %d / %d\n" ..
        "LOOP                 : %s\n" ..
        "初始接收/完成        : %d/%d / %d/%d\n" ..
        "预填提交/接收/完成   : %d/%d / %d/%d / %d/%d\n" ..
        "LOOP提交/接收/完成   : %d/%s / %d/%s / %d/%s\n" ..
        "竞争提交/接收/完成   : %d / %d / %d\n" ..
        "总提交/接收/完成     : %d / %d / %d\n" ..
        "最大AR表占用         : %d/%d\n" ..
        "目标保护             : %s\n" ..
        "目标状态             : %s\n\n" ..
        "AXI端口快照：\n%s\n\n" ..
        "64项阻塞周期统计：\n%s\n\n" ..
        "AR重排表当前快照：\n%s\n\n" ..
        "判定要求：64笔同ID事务必须同时占满entry 0~63；entry 62完成" ..
        "下游AR以后预填62笔不同ID单拍读；目标nid=0后继续补入LOOP笔事务。" ..
        "LOOP事务全部进入重排表以前，" ..
        "entry 63必须保持valid=1且haveSendAR=0。停止补流后才允许目标完成" ..
        "下游AR握手并返回完整99拍数据。\n\n" ..
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
        runtime.preload_submitted,
        PRELOAD_COMPETITORS,
        runtime.preload_accepted,
        PRELOAD_COMPETITORS,
        runtime.preload_completed,
        PRELOAD_COMPETITORS,
        runtime.loop_submitted,
        tostring(runtime.loop),
        runtime.loop_accepted,
        tostring(runtime.loop),
        runtime.loop_completed,
        tostring(runtime.loop),
        runtime.competitor_submitted,
        runtime.competitor_accepted,
        runtime.competitor_completed,
        runtime.total_submitted,
        runtime.total_accepted,
        runtime.total_completed,
        runtime.max_occupancy,
        REORDER_DEPTH,
        tostring(runtime.guard_target),
        target_snapshot(),
        port_snapshot(),
        entry_statistics_report(),
        ar_table_snapshot()
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

local function find_allocated_entry(sample)
    local hit = nil
    for entry = 0, REORDER_DEPTH - 1 do
        if sample.internal.ar.entries[entry].alloc_hit == 1 then
            if hit ~= nil then
                return nil, "一次上游AR握手命中了多个表项"
            end
            hit = entry
        end
    end

    if hit == nil then
        return nil, "上游AR握手没有命中任何表项"
    end
    return hit, nil
end

-- monitor回调只记录事实，不直接assert。主测试任务每推进一个周期都会检查
-- observer_failure，这样失败信息可统一附带最新的64项统计与端口快照。
monitor.subscribe(function(sample)
    if not runtime.active or sample == nil or sample.reset == 1 then
        return
    end

    local cycle = sample.cycles
    local ar_sample = sample.internal.ar
    local slv_ar_fire = fired(sample.io.slv_ar)
    local slv_ar_entry = slv_ar_fire and sample.io.slv_ar.bits.id or nil

    local occupancy = 0
    for entry = 0, REORDER_DEPTH - 1 do
        local state = ar_sample.entries[entry]
        local stat = entry_stats[entry]

        if state.valid == 1 then
            occupancy = occupancy + 1
            stat.resident_cycles = stat.resident_cycles + 1

            -- 下游AR握手当拍不再计为阻塞周期。其他 haveSendAR=0 的周期按
            -- nid、仲裁选择和ARREADY状态拆分，三类之和构成主要阻塞来源。
            local is_this_ar_fire = slv_ar_fire and slv_ar_entry == entry
            if state.have_sent == 0 and not is_this_ar_fire then
                stat.ar_blocked = stat.ar_blocked + 1

                if state.nid > 0 then
                    stat.same_id_blocked = stat.same_id_blocked + 1
                elseif sample.io.slv_ar.valid == 1 and
                    sample.io.slv_ar.bits.id ~= entry then
                    stat.priority_blocked = stat.priority_blocked + 1
                elseif sample.io.slv_ar.valid == 1 and
                    sample.io.slv_ar.bits.id == entry and
                    sample.io.slv_ar.ready == 0 then
                    stat.arready_blocked = stat.arready_blocked + 1
                else
                    stat.arbitration_gap = stat.arbitration_gap + 1
                end
            end

            if entry == TARGET_ENTRY and state.nid == 0 and
                state.have_sent == 0 and target_transaction ~= nil and
                target_transaction.sendable_cycle == nil then
                target_transaction.sendable_cycle = cycle
            end
        end
    end
    if occupancy > runtime.max_occupancy then
        runtime.max_occupancy = occupancy
    end

    -- 上游AR握手表示事务已真正进入DUT。用唯一地址找回测试事务，再通过
    -- alloc_hit确定它落入哪个entry，不能把Master API返回Success误当成入表。
    if fired(sample.io.mst_ar) then
        -- 48位地址句柄在LuaJIT中可能以cdata返回。cdata与普通Lua number即使
        -- 数值相等也不是同一个table键，因此查找唯一地址前必须显式tonumber。
        local addr = tonumber(sample.io.mst_ar.bits.addr)
        local transaction = transaction_by_addr[addr]
        if transaction == nil then
            record_observer_failure(string.format(
                "观察到未登记的上游AR握手，地址=%s", hex(addr)))
        elseif transaction.mst_ar_cycle ~= nil then
            record_observer_failure(string.format(
                "%s发生重复上游AR握手", transaction.name))
        else
            local entry, alloc_error = find_allocated_entry(sample)
            if alloc_error ~= nil then
                record_observer_failure(transaction.name .. "：" .. alloc_error)
            else
                local stat = entry_stats[entry]
                if stat.current ~= nil then
                    record_observer_failure(string.format(
                        "%s分配到entry %d时统计器仍记录旧事务%s",
                        transaction.name, entry, stat.current.name))
                end

                transaction.entry = entry
                transaction.mst_ar_cycle = cycle
                stat.current = transaction
                stat.allocations = stat.allocations + 1
                runtime.total_accepted = runtime.total_accepted + 1

                if transaction.kind == "initial" then
                    runtime.initial_accepted = runtime.initial_accepted + 1
                else
                    runtime.competitor_accepted =
                        runtime.competitor_accepted + 1
                    if transaction.phase == "preload" then
                        runtime.preload_accepted =
                            runtime.preload_accepted + 1
                    else
                        runtime.loop_accepted = runtime.loop_accepted + 1
                    end
                end
            end
        end
    end

    -- 下游AR握手使用重排表项号作为ID。记录每笔事务真正输出的周期，并在
    -- LOOP补流阶段保护entry 63，防止只在事后发现目标早已离开重排表。
    if slv_ar_fire then
        local entry = slv_ar_entry
        local stat = entry_stats[entry]
        local transaction = stat and stat.current or nil
        runtime.downstream_ar_count = runtime.downstream_ar_count + 1

        if transaction == nil then
            record_observer_failure(string.format(
                "entry %s下游AR握手时找不到对应测试事务", tostring(entry)))
        elseif transaction.slv_ar_cycle ~= nil then
            record_observer_failure(string.format(
                "%s发生重复下游AR握手", transaction.name))
        else
            transaction.slv_ar_cycle = cycle
            transaction.slv_ar_ordinal = runtime.downstream_ar_count

            if transaction.kind == "initial" then
                stat.initial_ar_wait = cycle - transaction.mst_ar_cycle
            end

            if entry == TARGET_ENTRY and runtime.guard_target then
                record_observer_failure(string.format(
                    "目标entry 63在竞争事务接收完成前提前输出：" ..
                    "预填接收=%d/%d，LOOP接收=%d/%d，目标AR周期=%d",
                    runtime.preload_accepted,
                    PRELOAD_COMPETITORS,
                    runtime.loop_accepted,
                    runtime.loop,
                    cycle))
            end
        end
    end

    -- RLAST握手才真正释放AR表项。这里同时回收竞争ID，使随后补入的事务始终
    -- 能选择一个当前未使用的ID，从而避免竞争事务自身产生同ID依赖。
    if fired(sample.io.slv_r) then
        local entry = sample.io.slv_r.bits.id
        local stat = entry_stats[entry]
        local transaction = stat and stat.current or nil

        if transaction == nil then
            record_observer_failure(string.format(
                "entry %s返回R数据时找不到对应测试事务", tostring(entry)))
        else
            transaction.r_beats = transaction.r_beats + 1

            if sample.io.slv_r.bits.last == 1 then
                if transaction.rlast_cycle ~= nil then
                    record_observer_failure(string.format(
                        "%s发生重复RLAST握手", transaction.name))
                else
                    transaction.rlast_cycle = cycle
                    stat.completions = stat.completions + 1
                    stat.completed_resident_cycles =
                        stat.completed_resident_cycles +
                        (cycle - transaction.mst_ar_cycle)
                    if transaction.kind == "initial" then
                        stat.initial_resident =
                            cycle - transaction.mst_ar_cycle
                        runtime.initial_completed =
                            runtime.initial_completed + 1
                    else
                        runtime.competitor_completed =
                            runtime.competitor_completed + 1
                        if transaction.phase == "preload" then
                            runtime.preload_completed =
                                runtime.preload_completed + 1
                        else
                            runtime.loop_completed =
                                runtime.loop_completed + 1
                        end
                        competitor_ids_in_use[transaction.id] = nil
                    end
                    runtime.total_completed = runtime.total_completed + 1
                    stat.current = nil
                end
            end
        end
    end
end)

local function make_initial_transaction(index)
    local is_target = index == REORDER_DEPTH
    return {
        name = is_target and
            "初始事务64/目标事务(entry 63, 99拍)" or
            string.format("初始事务%02d(entry %02d, 单拍)", index, index - 1),
        kind = "initial",
        initial_index = index,
        id = INITIAL_ID,
        addr = INITIAL_ADDR_BASE + (index - 1) * INITIAL_ADDR_STRIDE,
        burst = AXI_BURST_INCR,
        len = is_target and TARGET_LEN or SINGLE_LEN,
        size = AXI_SIZE_32_BYTES,
        beats = is_target and TARGET_BEATS or 1,
        entry = nil,
        ticket = nil,
        mst_ar_cycle = nil,
        slv_ar_cycle = nil,
        slv_ar_ordinal = nil,
        sendable_cycle = nil,
        rlast_cycle = nil,
        r_beats = 0,
    }
end

-- 从12位ID空间中挑选当前没有竞争事务占用的ID。最大并发只有63笔竞争事务，
-- 而可用ID有4095个，因此正常情况下必然能找到。相比简单按4或64个ID循环，
-- 该方法仍满足“每连续4笔ID不同”，并排除了旧事务未完成时复用ID的偶然性。
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

local function make_competitor_transaction(index, phase)
    -- 预填和LOOP分别从1开始编号，日志更容易与两段进度对应；地址则使用
    -- 全局竞争事务序号，保证两段事务的地址绝不重复。
    local global_index = phase == "preload" and index or
        PRELOAD_COMPETITORS + index
    return {
        name = string.format(
            "%s竞争事务%06d(单拍)",
            phase == "preload" and "预填" or "LOOP",
            index),
        kind = "competitor",
        phase = phase,
        competitor_index = index,
        id = allocate_competitor_id(),
        addr = COMPETITOR_ADDR_BASE +
            (global_index - 1) * COMPETITOR_ADDR_STRIDE,
        burst = AXI_BURST_INCR,
        len = SINGLE_LEN,
        size = AXI_SIZE_32_BYTES,
        beats = 1,
        entry = nil,
        ticket = nil,
        mst_ar_cycle = nil,
        slv_ar_cycle = nil,
        slv_ar_ordinal = nil,
        sendable_cycle = nil,
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
        runtime.competitor_submitted = runtime.competitor_submitted + 1
        if transaction.phase == "preload" then
            runtime.preload_submitted = runtime.preload_submitted + 1
        else
            runtime.loop_submitted = runtime.loop_submitted + 1
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
                "009总运行时间达到保护上限%d周期；请减小LOOP，或同步提高" ..
                "公共Master timeout_max与本用例TEST_TIMEOUT",
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

local function all_entries_valid()
    for entry = 0, REORDER_DEPTH - 1 do
        if ar_entries[entry].valid:get() ~= 1 then
            return false
        end
    end
    return true
end

local function all_entries_empty()
    for entry = 0, REORDER_DEPTH - 1 do
        if ar_entries[entry].valid:get() ~= 0 then
            return false
        end
    end
    return true
end

local function all_tickets_done()
    for _, transaction in ipairs(transactions) do
        if transaction.ticket == nil or not transaction.ticket.done then
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
            "%s端口统计拍数错误：期望=%d，实际=%d",
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
            loop <= MAX_COMPETITOR_COUNT - PRELOAD_COMPETITORS,
        string.format(
            "LOOP=%s非法；LOOP表示补入的不同ID单拍事务数，必须是1~%d的整数",
            tostring(loop_text),
            MAX_COMPETITOR_COUNT - PRELOAD_COMPETITORS)
    )
    runtime.loop = loop
    local expected_total = REORDER_DEPTH + PRELOAD_COMPETITORS + loop

    -- 公共initialize同时启动公共AXI4MasterV2和公共AXI4Memory。009不实例化
    -- 任何私有Slave，也不调用driver.drive()覆盖组件正在驱动的端口。
    driver.initialize()
    env.wait_cycles(1)

    runtime.active = true
    runtime.start_cycle = current_cycle()
    runtime.stage = "按顺序提交64笔同ID初始读事务"

    print_message(string.format(
        "009 用例开始：完全使用公共 AXI Master 和公共 AXI4Memory。\n\n" ..
        "AR重排表深度                 : %d\n" ..
        "初始事务                     : 64笔同ID=%s，前63笔单拍，" ..
        "最后1笔99拍\n" ..
        "预填竞争事务                 : 62笔，不计入LOOP，均为单拍读\n" ..
        "可调竞争事务                 : LOOP=%d，均为单拍读\n" ..
        "竞争ID约束                   : 不等于%s，且所有同时未完成" ..
        "竞争事务ID互异\n" ..
        "公共Slave随机配置            : AR延迟20~40周期，R延迟" ..
        "100~200周期，R响应允许乱序\n" ..
        "目标要求                     : entry 63在LOOP笔竞争事务" ..
        "全部入表以前不得输出",
        REORDER_DEPTH,
        hex(INITIAL_ID),
        loop,
        hex(INITIAL_ID)
    ))

    -- 每笔初始事务都等到上游AR真正握手后再提交下一笔。公共Master内部会随机
    -- 遍历task槽；这种逐笔确认避免多笔同ID任务同时处于s_AR时发送顺序被打乱，
    -- 并确保99拍目标确实是第64笔、落在entry 63。
    local initial_transactions = {}
    for index = 1, REORDER_DEPTH do
        local transaction = make_initial_transaction(index)
        initial_transactions[index] = transaction
        if index == REORDER_DEPTH then
            target_transaction = transaction
        end

        local ret = submit_transaction(transaction)
        check(ret == "Success",
            string.format(
                "%s提交失败：%s。公共Master nr_task必须至少为64，且" ..
                "nr_ar_taskbuf也必须能持续接收AR任务",
                transaction.name, tostring(ret)))

        wait_until(function()
            return transaction.mst_ar_cycle ~= nil
        end, transaction.name .. "完成上游AR握手")

        check(transaction.entry == index - 1,
            string.format(
                "%s没有按顺序进入entry %d，实际entry=%s",
                transaction.name, index - 1, tostring(transaction.entry)))

        -- 在64笔全部进入以前不允许任何初始事务完成，否则无法形成64/64满表。
        check(runtime.initial_completed == 0,
            string.format(
                "只接收了%d/64笔初始事务时已有%d笔完成，公共Slave响应早于" ..
                "填表速度，未形成64项同时有效状态",
                runtime.initial_accepted, runtime.initial_completed))

        if index == REORDER_DEPTH then
            runtime.guard_target = true
        end
    end

    wait_until(all_entries_valid, "64个AR表项同时有效")
    runtime.full_cycle = current_cycle()
    check(runtime.initial_accepted == REORDER_DEPTH,
        string.format("初始AR接收数错误：期望64，实际%d",
            runtime.initial_accepted))
    check(runtime.max_occupancy == REORDER_DEPTH,
        string.format("monitor观察到的最大AR表占用只有%d/64",
            runtime.max_occupancy))

    for entry = 0, REORDER_DEPTH - 1 do
        local transaction = initial_transactions[entry + 1]
        check(ar_entries[entry].valid:get() == 1,
            string.format("满表检查时entry %d无效", entry))
        check(ar_entries[entry].id:get() == INITIAL_ID,
            string.format(
                "满表检查时entry %d ID错误：期望=%s，实际=%s",
                entry, hex(INITIAL_ID), hex(ar_entries[entry].id:get())))
        check(ar_entries[entry].addr:get() == transaction.addr,
            string.format(
                "满表检查时entry %d地址错误：期望=%s，实际=%s",
                entry, hex(transaction.addr), hex(ar_entries[entry].addr:get())))
        check(ar_entries[entry].nid:get() == entry,
            string.format(
                "满表检查时entry %d nid错误：期望=%d，实际=%s",
                entry, entry, tostring(ar_entries[entry].nid:get())))
    end

    print_message(string.format(
        "64笔同ID事务已在周期%d占满AR重排表。\n" ..
        "entry 0~62为单拍读，entry 63为99拍目标；目标当前" ..
        "valid=1、nid=63、haveSendAR=0。\n" ..
        "现在先等待前62笔初始事务完成，并等待最后一个前序" ..
        "entry 62完成下游AR握手。此时目标nid=1，随后利用entry 62" ..
        "等待公共Slave返回R的窗口预填62笔不同ID单拍读。\n" ..
        "预填事务只负责建立固定优先级竞争环境，不计入LOOP；" ..
        "目标nid降到0后再通过LOOP=%d控制继续补流的长度。",
        runtime.full_cycle, loop
    ))

    -- 先不补入任何竞争事务，让同ID链自然向后推进。目标nid=1表示只有
    -- entry 62这个前序事务尚未RLAST；同时要求entry 62已经完成下游AR，确保
    -- 此后至少还有公共Slave的R响应延迟窗口可用于把62笔预填事务送入DUT。
    runtime.stage = "等待目标只剩entry 62一个同ID前序事务"
    wait_until(function()
        return ar_entries[TARGET_ENTRY].valid:get() == 1 and
            ar_entries[TARGET_ENTRY].nid:get() == 1 and
            ar_entries[INITIAL_PREDECESSORS - 1].valid:get() == 1 and
            ar_entries[INITIAL_PREDECESSORS - 1].have_sent:get() == 1
    end, "目标nid=1且entry 62已经完成下游AR握手", TEST_TIMEOUT)

    check(runtime.initial_completed == INITIAL_PREDECESSORS - 1,
        string.format(
            "开始预填时初始事务完成数错误：期望62，实际%d",
            runtime.initial_completed))
    check(target_transaction.sendable_cycle == nil,
        "开始预填以前目标已经出现nid=0")

    runtime.preload_start_cycle = current_cycle()
    print_message(string.format(
        "预填窗口已经建立（周期%d）。\n" ..
        "entry 0~61已释放；entry 62已完成下游AR并等待公共Slave的R；" ..
        "目标entry 63仍为valid=1、nid=1、haveSendAR=0。\n" ..
        "现在向公共Master提交62笔不同ID单拍读，使其优先回填" ..
        "entry 0~61。公共Slave的ARREADY和RVALID仍完全由公共组件的" ..
        "随机延迟控制。",
        runtime.preload_start_cycle
    ))

    -- 目标和entry 62占用两个Master task，剩余62个task恰好用于预填。
    -- RLAST到达时，DUT表项已经释放，但Master task还可能经过WillFree状态才
    -- 归还槽位，因此NoTaskIDAvailable允许按周期重试；其他返回值均为错误。
    runtime.stage = "提交62笔预填竞争事务"
    local pending_preload = nil
    while runtime.preload_submitted < PRELOAD_COMPETITORS do
        check_async_failure()

        if pending_preload == nil then
            pending_preload = make_competitor_transaction(
                runtime.preload_submitted + 1, "preload")
        end

        local ret = submit_transaction(pending_preload)
        if ret == "Success" then
            pending_preload = nil
        else
            check(ret == "NoTaskIDAvailable",
                string.format(
                    "%s提交失败：%s",
                    pending_preload.name, tostring(ret)))
        end

        if runtime.preload_submitted < PRELOAD_COMPETITORS then
            advance_one_cycle()
        end
    end

    -- API提交成功只表示占用了Master task，不等于AR已经进入重排表。必须等
    -- 62笔预填事务全部真实握手，并确认它们都分配在entry 0~61。若公共组件
    -- 的时延关系不足以建立竞争环境，guard_target会在目标提前输出的当拍报错。
    runtime.stage = "等待62笔预填事务全部进入entry 0~61"
    wait_until(function()
        return runtime.preload_accepted == PRELOAD_COMPETITORS
    end, "62笔预填竞争事务全部进入AR重排表", TEST_TIMEOUT)
    runtime.preload_accept_done_cycle = current_cycle()

    for _, transaction in ipairs(transactions) do
        if transaction.phase == "preload" then
            check(transaction.entry ~= nil and
                transaction.entry >= 0 and
                transaction.entry < INITIAL_PREDECESSORS - 1,
                string.format(
                    "%s没有进入entry 0~61，实际entry=%s",
                    transaction.name, tostring(transaction.entry)))
        end
    end

    check(target_transaction.slv_ar_cycle == nil,
        "62笔预填事务全部入表前目标已经输出")
    check(ar_entries[TARGET_ENTRY].valid:get() == 1 and
        ar_entries[TARGET_ENTRY].have_sent:get() == 0,
        "预填完成时目标entry 63未保持valid=1、haveSendAR=0")

    -- 直到目标nid真正变成0才开始计算用户指定的LOOP。这样LOOP只控制目标
    -- 已具备发送资格以后继续制造的竞争次数，不包含前面的同ID依赖等待。
    runtime.stage = "等待entry 62返回RLAST并使目标nid降为0"
    wait_until(function()
        return target_transaction.sendable_cycle ~= nil and
            ar_entries[TARGET_ENTRY].valid:get() == 1 and
            ar_entries[TARGET_ENTRY].nid:get() == 0 and
            ar_entries[TARGET_ENTRY].have_sent:get() == 0
    end, "目标entry 63进入nid=0可发送状态", TEST_TIMEOUT)

    print_message(string.format(
        "目标entry 63已在周期%d进入nid=0可发送状态。\n" ..
        "预填事务提交/入表/完成       : %d/%d/%d（固定62笔）\n" ..
        "目标当前状态                 : valid=1、nid=0、haveSendAR=0\n" ..
        "现在开始LOOP=%d笔可调补流：每释放一个Master task就继续提交" ..
        "一笔不同ID单拍读，持续占用低编号表项。",
        target_transaction.sendable_cycle,
        runtime.preload_submitted,
        runtime.preload_accepted,
        runtime.preload_completed,
        loop
    ))

    -- 维持接近64笔Master未完成任务。当竞争事务RLAST释放task后立即补入下一
    -- 笔LOOP事务。不同ID事务会进入目标以下的空闲表项，固定优先级使它们在
    -- entry 63之前完成下游AR握手。LOOP越大，目标被阻塞的时间越长。
    runtime.stage = "目标nid=0后循环补入LOOP竞争事务"
    local pending_loop = nil
    local progress_step = math.max(1, math.floor(loop / 10))

    while runtime.loop_submitted < loop do
        check_async_failure()

        local outstanding = runtime.total_submitted - runtime.total_completed
        if outstanding < REORDER_DEPTH then
            if pending_loop == nil then
                pending_loop = make_competitor_transaction(
                    runtime.loop_submitted + 1, "loop")
            end

            local ret = submit_transaction(pending_loop)
            if ret == "Success" then
                local submitted = runtime.loop_submitted
                pending_loop = nil

                if submitted == loop or submitted % progress_step == 0 then
                    print(string.format(
                        "[009 LOOP进度] 提交=%d/%d，入表=%d/%d，完成=%d/%d；" ..
                        "预填完成=%d/%d；目标nid=%s haveSendAR=%s",
                        submitted,
                        loop,
                        runtime.loop_accepted,
                        loop,
                        runtime.loop_completed,
                        loop,
                        runtime.preload_completed,
                        PRELOAD_COMPETITORS,
                        tostring(ar_entries[TARGET_ENTRY].nid:get()),
                        tostring(ar_entries[TARGET_ENTRY].have_sent:get())
                    ))
                end
            else
                check(ret == "NoTaskIDAvailable",
                    string.format(
                        "%s提交失败：%s",
                        pending_loop.name, tostring(ret)))
            end
        end

        if runtime.loop_submitted < loop then
            advance_one_cycle()
        end
    end

    -- 最后一笔LOOP事务仅API提交成功仍不够；目标保护保持到它完成上游AR握手，
    -- 确保所有用户要求的替换事务都真正进入重排表后才停止补流。
    runtime.stage = "等待全部LOOP事务完成上游AR握手"
    wait_until(function()
        return runtime.loop_accepted == loop
    end, string.format("%d笔LOOP事务全部进入AR重排表", loop), TEST_TIMEOUT)

    check(target_transaction.slv_ar_cycle == nil,
        string.format(
            "目标在全部LOOP事务入表前已经输出，周期=%s",
            tostring(target_transaction.slv_ar_cycle)))
    check(ar_entries[TARGET_ENTRY].valid:get() == 1,
        "LOOP结束时目标entry 63已经无效")
    check(ar_entries[TARGET_ENTRY].have_sent:get() == 0,
        "LOOP结束时目标entry 63的haveSendAR已经置1")

    runtime.loop_accept_done_cycle = current_cycle()
    runtime.guard_target = false

    print_message(string.format(
        "LOOP补流阶段完成。\n" ..
        "预填事务提交/入表/完成         : %d/%d/%d（固定62笔）\n" ..
        "LOOP事务提交/入表/完成         : %d/%d/%d（用户可调）\n" ..
        "目标entry 63状态              : valid=1、nid=%s、" ..
        "haveSendAR=0\n" ..
        "目标从入表到当前已驻留         : %d周期\n" ..
        "其中nid=0后的固定优先级阻塞    : %d周期\n\n" ..
        "现在停止补流，允许公共Slave继续排空；目标只能在低编号" ..
        "表项均完成下游AR输出后获得机会。",
        runtime.preload_submitted,
        runtime.preload_accepted,
        runtime.preload_completed,
        runtime.loop_submitted,
        runtime.loop_accepted,
        runtime.loop_completed,
        tostring(ar_entries[TARGET_ENTRY].nid:get()),
        runtime.loop_accept_done_cycle - target_transaction.mst_ar_cycle,
        entry_stats[TARGET_ENTRY].priority_blocked
    ))

    runtime.stage = "停止补流并等待目标最后输出"
    wait_until(function()
        return target_transaction.slv_ar_cycle ~= nil
    end, "目标entry 63完成下游AR握手", TEST_TIMEOUT)

    check(target_transaction.slv_ar_cycle >=
        runtime.loop_accept_done_cycle,
        "目标下游AR周期早于LOOP全部入表周期")
    check(target_transaction.slv_ar_ordinal ==
        expected_total,
        string.format(
            "目标不是最后一笔下游AR：目标序号=%s，期望=%d",
            tostring(target_transaction.slv_ar_ordinal),
            expected_total))

    runtime.stage = "等待目标99拍响应及全部公共Master ticket完成"
    wait_until(all_tickets_done, "全部读事务ticket完成", TEST_TIMEOUT)
    wait_until(all_entries_empty, "64个AR表项全部释放", WAIT_TIMEOUT)

    -- 多等两个周期，让monitor和公共Master的WillFree状态完成最后更新，再执行
    -- ticket、端口拍数和统计总数检查。
    env.wait_cycles(2)
    check_async_failure()
    runtime.end_cycle = current_cycle()

    check(runtime.total_submitted == expected_total,
        string.format(
            "总提交数错误：期望=%d，实际=%d",
            expected_total, runtime.total_submitted))
    check(runtime.total_accepted == runtime.total_submitted,
        string.format(
            "总接收数与提交数不一致：提交=%d，接收=%d",
            runtime.total_submitted, runtime.total_accepted))
    check(runtime.total_completed == runtime.total_submitted,
        string.format(
            "总完成数与提交数不一致：提交=%d，完成=%d",
            runtime.total_submitted, runtime.total_completed))
    check(runtime.initial_completed == REORDER_DEPTH,
        string.format("初始事务完成数错误：%d/64",
            runtime.initial_completed))
    check(runtime.preload_submitted == PRELOAD_COMPETITORS and
        runtime.preload_accepted == PRELOAD_COMPETITORS and
        runtime.preload_completed == PRELOAD_COMPETITORS,
        string.format(
            "预填事务提交/接收/完成错误：%d/%d/%d，期望均为%d",
            runtime.preload_submitted,
            runtime.preload_accepted,
            runtime.preload_completed,
            PRELOAD_COMPETITORS))
    check(runtime.loop_submitted == loop and
        runtime.loop_accepted == loop and
        runtime.loop_completed == loop,
        string.format(
            "LOOP事务提交/接收/完成错误：%d/%d/%d，期望均为%d",
            runtime.loop_submitted,
            runtime.loop_accepted,
            runtime.loop_completed,
            loop))
    check(runtime.competitor_completed == PRELOAD_COMPETITORS + loop,
        string.format("竞争事务总完成数错误：%d/%d",
            runtime.competitor_completed, PRELOAD_COMPETITORS + loop))
    check(target_transaction.r_beats == TARGET_BEATS,
        string.format("目标R拍数错误：期望99，实际%d",
            target_transaction.r_beats))
    check(target_transaction.rlast_cycle ~= nil,
        "目标没有观察到RLAST握手")
    check(entry_stats[TARGET_ENTRY].priority_blocked > 0,
        "没有观察到目标nid=0后的固定优先级阻塞周期")
    check(all_entries_empty(), "收尾时仍有AR表项有效")

    for _, transaction in ipairs(transactions) do
        verify_ticket(transaction)
    end

    local run_cycles = runtime.end_cycle - runtime.start_cycle
    local target_total_wait =
        target_transaction.slv_ar_cycle - target_transaction.mst_ar_cycle
    local target_sendable_wait =
        target_transaction.slv_ar_cycle - target_transaction.sendable_cycle

    print_message(string.format(
        "009 AR固定优先级长期阻塞测试通过。\n\n" ..
        "公共组件使用情况：\n" ..
        "  * AXI Master/Slave来源          = dut.driver公共实例\n" ..
        "  * 009私有AXI4Memory             = 未创建\n" ..
        "  * 手工AXI端口驱动               = 未使用\n\n" ..
        "事务与运行统计：\n" ..
        "  * 初始同ID事务                  = 64笔（63笔单拍+1笔99拍）\n" ..
        "  * 预填竞争事务                  = %d笔单拍（不计入LOOP）\n" ..
        "  * LOOP竞争替换事务              = %d笔单拍（目标nid=0后）\n" ..
        "  * 总提交/接收/完成              = %d/%d/%d\n" ..
        "  * 最大AR重排表占用              = %d/64\n" ..
        "  * 开始/满表周期                 = %d / %d\n" ..
        "  * 预填开始/入表完成周期         = %d / %d\n" ..
        "  * 目标nid=0/LOOP入表完成周期    = %d / %d\n" ..
        "  * 结束周期                      = %d\n" ..
        "  * 用例总运行周期                = %d\n\n" ..
        "目标entry 63统计：\n" ..
        "  * 目标下游AR序号                = %d/%d（最后一笔）\n" ..
        "  * 从入表到下游AR                = %d周期\n" ..
        "  * 从nid=0到下游AR               = %d周期\n" ..
        "  * 同ID依赖阻塞                  = %d周期\n" ..
        "  * nid=0固定优先级阻塞           = %d周期\n" ..
        "  * 等待公共Slave ARREADY         = %d周期\n" ..
        "  * R返回拍数                     = %d（含1次RLAST）\n" ..
        "  * 从入表到RLAST释放             = %d周期\n\n" ..
        "64项累计汇总：\n" ..
        "  * AR阻塞总数                    = %d周期\n" ..
        "  * 同ID阻塞总数                  = %d周期\n" ..
        "  * 固定优先级阻塞总数            = %d周期\n" ..
        "  * 等ARREADY总数                 = %d周期\n" ..
        "  * 表项驻留总数                  = %d周期\n" ..
        "  * 最终空表                      = 64/64项全部无效\n\n" ..
        "结论：公共Master的64个task足以让64笔同ID读事务占满AR重排表。" ..
        "前62笔初始事务完成后，62笔预填事务进入entry 0~61；目标nid=0" ..
        "以后又完成LOOP笔可调补流。固定优先级使entry 63一直保留到全部" ..
        "预填和LOOP事务进入并完成下游AR以后，才成为最后一笔下游AR。" ..
        "随后99拍R响应完整返回，全部事务和表项均已清空。",
        PRELOAD_COMPETITORS,
        loop,
        runtime.total_submitted,
        runtime.total_accepted,
        runtime.total_completed,
        runtime.max_occupancy,
        runtime.start_cycle,
        runtime.full_cycle,
        runtime.preload_start_cycle,
        runtime.preload_accept_done_cycle,
        target_transaction.sendable_cycle,
        runtime.loop_accept_done_cycle,
        runtime.end_cycle,
        run_cycles,
        target_transaction.slv_ar_ordinal,
        expected_total,
        target_total_wait,
        target_sendable_wait,
        entry_stats[TARGET_ENTRY].same_id_blocked,
        entry_stats[TARGET_ENTRY].priority_blocked,
        entry_stats[TARGET_ENTRY].arready_blocked,
        target_transaction.r_beats,
        target_transaction.rlast_cycle - target_transaction.mst_ar_cycle,
        sum_entry_field("ar_blocked"),
        sum_entry_field("same_id_blocked"),
        sum_entry_field("priority_blocked"),
        sum_entry_field("arready_blocked"),
        sum_entry_field("resident_cycles")
    ))

    print_message(
        "009 全部64个AR表项的阻塞/驻留周期明细：\n\n" ..
        entry_statistics_report()
    )

    runtime.active = false
end

return {
    tasks = {
        task_test,
    },
}
