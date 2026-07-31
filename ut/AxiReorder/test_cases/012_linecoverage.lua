local env = require "env"
local driver = require "dut.driver"
local signals = require "dut.signals"

--[====[
================================================================================
012_linecoverage.lua
================================================================================

一、覆盖目标

RTL 更新后，原 012 用例针对的旧行号和内部组合信号已经失效。本用例现在覆盖
AxiReorder.sv 中 AW 重排表 entry8..63 的分配分支。每个 entry 有两条目标语句：

    if (aw_mst_fire_hit_N) begin
        awinfo_N_id  <= io_mst_aw_bits_id;
        awinfo_N_nid <= 同 ID 的在途写事务数量;
    end

entry=N 的两条语句行号分别为：

    ID 保存行  = 41108 + 7 * N
    nid 保存行 = 41109 + 7 * N

因此 entry8 对应 41164/41165，entry9 对应 41171/41172，entry10 对应
41178/41179，按 7 行递增，最后 entry63 对应 41549/41550。本次需要新增覆盖的
范围是 entry8..63，共 56 个 entry、112 行代码。

本用例还覆盖 AW 重排表 entry1..63 的 nid 减 1 语句：

    else if (目标 entry 的 nid 非零且同 ID 前序 B 完成)
        awinfo_N_nid <= awinfo_N_nid - 7'h1;

entry=N 的目标行号为 41112 + 7 * N。因此 entry1 对应 41119，entry2 对应
41126，entry3 对应 41133，按 7 行递增，最后 entry63 对应 41553，共 63 行。
41112 是 entry0 的同类语句，不在本次指定的 41119 起始范围内。

二、参数化方法

AW_ALLOCATION_CASES 将 entry0..63 全部放入同一参数表，避免为 64 个 entry
复制相同代码。entry0..7 虽然不是本次缺失行，但它们是把最低空闲项推进到
entry8 的必要铺表事务，也一并通过相同 runner 执行和检查。

每个参数项使用不同的 12-bit AXI ID，并执行一笔单拍、32-byte、INCR 写：

    1. 上游 AW 握手，DUT 按最低空闲项分配 entry；
    2. 上游 W 握手；
    3. 下游 AW 握手，并检查重映射后的 6-bit ID 等于目标 entry；
    4. 下游 W 握手，并检查 DATA、STRB、LAST；
    5. 暂不返回 B，使该 entry 保持占用，下一笔自然进入下一个 entry。

64 笔事务的 ID 互不相同，所以每次分配时同 ID 的前序未完成事务数都是 0，
即 awinfo_N_nid 的合法期望值为 0。前一笔已经完成下游 AW/W 后才开始下一笔，
写地址队列和写数据队列不会被深度限制堵住，而已分配 entry 会因尚未收到 B
继续有效。这样可以在不修改、force 或 deposit 任何内部信号的情况下依次命中
aw_mst_fire_hit_0..63。

AW_NID_DECREMENT_CASES 参数化生成 entry1..63 的减 1 场景。每轮使用一个新的
原始 AXI ID，并按以下顺序构造严格的同 ID 写事务依赖：

    P : 分配到 entry0，完成下游 AW/W 后等待 B；
    T : 与 P 使用相同 ID，分配到目标 entry，分配后 nid=1；
    B : 合法返回 P 的 B，目标 entry 的 nid 从 1 减到 0；
    T : nid 清零后才允许向下游发送 AW/W，随后保留等待最终 B。

前一轮的目标 entry 会保持有效，因此第 N 轮开始时 entry1..N-1 已占用；P 占用
entry0 后，T 自然分配到最低空闲的 entryN。P 的 B 释放 entry0，T 则留作下一轮
的低编号占位。这样只需一个连续场景即可依次覆盖 63 条减 1 语句。

三、AXI 合法性

本用例严格遵守 AXI 五通道逻辑：

    * AWVALID 或 WVALID 遇到 READY=0 时保持 VALID 和 payload 稳定；
    * AW 与 W 是独立通道，但每笔事务的 AW/W 都各自只握手一次；
    * 下游 B 只在对应下游 AW 和末拍 W 均已于更早时钟沿握手后产生；
    * 每笔事务只返回一次 B，不发送无对应请求或重复的响应；
    * 不同 ID 的 B 可以乱序，本用例仍按 entry0..63 顺序返回，行为合法且易审计；
    * 最终返回全部 64 笔 B，恢复原始 BID，并清空 DUT 与公共 scoreboard。

nid 减 1 阶段中，同 ID 的 T 在 P 完成前不会发送下游 AW；P 的 B 只在 P 的
下游 AW 和末拍 W 均已完成后返回。P 的 B 完成后才发送 T 的下游 AW/W，最后
再返回 T 的 B，因而同 ID 写请求和写响应顺序均符合 AXI 要求。

内部 signals.dbg_aw 句柄只用于只读检查分配命中、保存的 ID/nid、有效位和
haveSendAW，不参与激励，不改变 DUT 状态。
================================================================================
]====]

local clock = dut.clock:chdl()
local TIMEOUT = 200
local FIRST_TARGET_ENTRY = 8
local FIRST_DECREMENT_ENTRY = 1
local LAST_ENTRY = 63

local function error_message(message)
    return "\n\n---ERROR---\n\n" .. message .. "\n\n-----------\n\n"
end

local function print_message(message)
    print(
        "\n\n-----------------------------------------------\n\n" ..
        message ..
        "\n\n-----------------------------------------------\n\n"
    )
end

local function assert_equal(actual, expected, description)
    assert(
        actual == expected,
        error_message(string.format(
            "%s: expected=%s, actual=%s",
            description,
            tostring(expected),
            tostring(actual)
        ))
    )
end

local function wait_negedge()
    clock:negedge()
end

-- set_imm() 后等待组合逻辑稳定，但不推进时钟。这样检查 READY、VALID 和
-- alloc_hit 时观察的是将要发生握手的同一个周期，不会意外重复一次事务。
local function settle_combination()
    await_rd()
end

-- 上升沿之后进入 read/write 同步阶段，再撤销刚刚握手的 VALID/READY。
-- 监视器和 RTL 已经在该上升沿采样，因此不会漏记合法握手。
local function finish_handshake_edge()
    await_rw()
end

local function wait_until_observed(predicate, description)
    for _ = 1, TIMEOUT do
        if predicate() then
            return
        end

        -- 调用者必须在等待期间持续保持 VALID 和 payload；这里只等待到下一个
        -- 下降沿重新观察 READY，不主动改写任何 AXI 信号。
        wait_negedge()
    end

    assert(false, error_message("timeout waiting for " .. description))
end

-- 所有参数项都是单拍、32-byte、INCR 写事务。地址按 32 byte 对齐且唯一，
-- DATA 也唯一，便于公共 scoreboard 和本用例同时核对上下游 payload。
local function make_transaction(entry)
    return {
        name = string.format("AW allocation entry%d", entry),
        id = 0x100 + entry,
        addr = 0x10000 + entry * 0x20,
        data = 0x2000 + entry,
    }
end

local function aw_id_line(entry)
    return 41108 + 7 * entry
end

local function aw_nid_line(entry)
    return aw_id_line(entry) + 1
end

local function aw_nid_decrement_line(entry)
    return 41112 + 7 * entry
end

-- entry0..63 共用同一参数结构。is_target=false 的前 8 项是必要铺表项；
-- entry8..63 才对应用户指出的当前未覆盖行。
local AW_ALLOCATION_CASES = {}
for entry = 0, LAST_ENTRY do
    table.insert(AW_ALLOCATION_CASES, {
        entry = entry,
        id_line = aw_id_line(entry),
        nid_line = aw_nid_line(entry),
        expected_nid = 0,
        is_target = entry >= FIRST_TARGET_ENTRY,
        transaction = make_transaction(entry),
    })
end

-- 每个减 1 参数项包含同 ID 的前序事务 P 和目标事务 T。P 始终复用 entry0，
-- T 使用 entry1..63；每轮 ID、地址和数据均唯一，避免 scoreboard 误配事务。
local AW_NID_DECREMENT_CASES = {}
for entry = FIRST_DECREMENT_ENTRY, LAST_ENTRY do
    local transaction_id = 0x500 + entry
    local address_base = 0x20000 + entry * 0x40

    table.insert(AW_NID_DECREMENT_CASES, {
        entry = entry,
        decrement_line = aw_nid_decrement_line(entry),
        predecessor = {
            entry = 0,
            id_line = aw_id_line(0),
            nid_line = aw_nid_line(0),
            expected_nid = 0,
            is_target = false,
            transaction = {
                name = string.format("entry%d nid decrement predecessor P", entry),
                id = transaction_id,
                addr = address_base,
                data = 0x3000 + entry * 2,
            },
        },
        target = {
            entry = entry,
            id_line = aw_id_line(entry),
            nid_line = aw_nid_line(entry),
            expected_nid = 1,
            is_target = false,
            transaction = {
                name = string.format("entry%d nid decrement target T", entry),
                id = transaction_id,
                addr = address_base + 0x20,
                data = 0x3001 + entry * 2,
            },
        },
    })
end

local function set_mst_aw(transaction, valid)
    dut.io_mst_aw_valid:set_imm(valid and 1 or 0)
    dut.io_mst_aw_bits_id:set_imm(transaction.id)
    dut.io_mst_aw_bits_addr:set_imm(transaction.addr)
    dut.io_mst_aw_bits_len:set_imm(0)
    dut.io_mst_aw_bits_size:set_imm(5)
    dut.io_mst_aw_bits_burst:set_imm(1)
    dut.io_mst_aw_bits_lock:set_imm(0)
    dut.io_mst_aw_bits_cache:set_imm(0)
    dut.io_mst_aw_bits_prot:set_imm(0)
    dut.io_mst_aw_bits_qos:set_imm(0)
    dut.io_mst_aw_bits_region:set_imm(0)
end

local function clear_mst_aw()
    dut.io_mst_aw_valid:set_imm(0)
end

local function set_mst_w(transaction, valid)
    dut.io_mst_w_valid:set_imm(valid and 1 or 0)
    dut.io_mst_w_bits_data:set_imm(transaction.data)
    dut.io_mst_w_bits_strb:set_imm(0xFFFFFFFF)
    dut.io_mst_w_bits_last:set_imm(valid and 1 or 0)
end

local function clear_mst_w()
    dut.io_mst_w_valid:set_imm(0)
    dut.io_mst_w_bits_data:set_imm(0)
    dut.io_mst_w_bits_strb:set_imm(0)
    dut.io_mst_w_bits_last:set_imm(0)
end

local function set_slv_b(entry, resp, valid)
    dut.io_slv_b_valid:set_imm(valid and 1 or 0)
    dut.io_slv_b_bits_id:set_imm(entry)
    dut.io_slv_b_bits_resp:set_imm(resp)
end

local function clear_slv_b()
    dut.io_slv_b_valid:set_imm(0)
    dut.io_slv_b_bits_id:set_imm(0)
    dut.io_slv_b_bits_resp:set_imm(0)
end

-- 完成上游 AW 握手。沿前读取 alloc_hit，直接确认最低空闲项选择结果；沿后
-- 再检查目标 entry 中保存的原始 ID 和 nid，从而证明两条目标赋值语句均执行。
local function accept_mst_aw(coverage_case)
    local transaction = coverage_case.transaction
    local entry_signals = signals.dbg_aw.entries[coverage_case.entry]
    local expected_nid = coverage_case.expected_nid or 0

    set_mst_aw(transaction, true)
    settle_combination()
    wait_until_observed(function()
        return dut.io_mst_aw_ready:get() == 1
    end, transaction.name .. " upstream AWREADY")

    assert_equal(
        entry_signals.alloc_hit:get(),
        1,
        string.format(
            "AxiReorder.sv:%d entry%d allocation hit before AW edge",
            coverage_case.id_line,
            coverage_case.entry
        )
    )

    env.wait_cycles(1)
    finish_handshake_edge()
    clear_mst_aw()
    wait_negedge()

    assert_equal(
        entry_signals.valid:get(),
        1,
        string.format("entry%d valid after upstream AW", coverage_case.entry)
    )
    assert_equal(
        entry_signals.id:get(),
        transaction.id,
        string.format(
            "AxiReorder.sv:%d entry%d saved upstream AWID",
            coverage_case.id_line,
            coverage_case.entry
        )
    )
    assert_equal(
        entry_signals.nid:get(),
        expected_nid,
        string.format(
            "AxiReorder.sv:%d entry%d saved nid",
            coverage_case.nid_line,
            coverage_case.entry
        )
    )
end

-- W 通道不携带 ID，必须按上游 AW 接收顺序提供单拍数据。本用例一次只推进
-- 一笔事务，且在 READY 拉高前保持 DATA/STRB/LAST 不变。
local function accept_mst_w(transaction)
    set_mst_w(transaction, true)
    settle_combination()
    wait_until_observed(function()
        return dut.io_mst_w_ready:get() == 1
    end, transaction.name .. " upstream WREADY")

    env.wait_cycles(1)
    finish_handshake_edge()
    clear_mst_w()
    wait_negedge()
end

-- 接收 DUT 发往下游的 AW。重映射 ID 必须等于参数项 entry，其余 payload
-- 必须保持上游请求值；READY 只跨越实际握手的一个上升沿。
local function accept_slv_aw(coverage_case)
    local transaction = coverage_case.transaction

    wait_until_observed(function()
        return dut.io_slv_aw_valid:get() == 1
    end, transaction.name .. " downstream AWVALID")

    assert_equal(
        dut.io_slv_aw_bits_id:get(),
        coverage_case.entry,
        transaction.name .. " downstream remapped AWID"
    )
    assert_equal(
        dut.io_slv_aw_bits_addr:get(),
        transaction.addr,
        transaction.name .. " downstream AWADDR"
    )
    assert_equal(dut.io_slv_aw_bits_len:get(), 0, transaction.name .. " downstream AWLEN")
    assert_equal(dut.io_slv_aw_bits_size:get(), 5, transaction.name .. " downstream AWSIZE")
    assert_equal(dut.io_slv_aw_bits_burst:get(), 1, transaction.name .. " downstream AWBURST")

    dut.io_slv_aw_ready:set_imm(1)
    settle_combination()
    env.wait_cycles(1)
    finish_handshake_edge()
    dut.io_slv_aw_ready:set_imm(0)
    wait_negedge()

    assert_equal(
        signals.dbg_aw.entries[coverage_case.entry].have_sent:get(),
        1,
        transaction.name .. " haveSendAW after downstream AW"
    )
end

-- 接收对应的单拍下游 W。由于 Lua number 无法完整表示任意 256-bit 数，本用例
-- 使用可精确表示的小整数 DATA，并通过十六进制字符串读取 256-bit 输出比较。
local function accept_slv_w(transaction)
    wait_until_observed(function()
        return dut.io_slv_w_valid:get() == 1
    end, transaction.name .. " downstream WVALID")

    local actual_data = dut.io_slv_w_bits_data:get_hex_str():lower():gsub("^0+", "")
    local expected_data = string.format("%x", transaction.data)
    assert_equal(actual_data, expected_data, transaction.name .. " downstream WDATA")
    assert_equal(
        dut.io_slv_w_bits_strb:get(),
        0xFFFFFFFF,
        transaction.name .. " downstream WSTRB"
    )
    assert_equal(dut.io_slv_w_bits_last:get(), 1, transaction.name .. " downstream WLAST")

    dut.io_slv_w_ready:set_imm(1)
    settle_combination()
    env.wait_cycles(1)
    finish_handshake_edge()
    dut.io_slv_w_ready:set_imm(0)
    wait_negedge()
end

-- 参数化 runner：完成一笔写的四次通道握手，但有意把 B 留到统一清场阶段。
-- 此时该 entry 已经具备接收 B 的全部协议前提，也能稳定占住低编号表项。
local function allocate_and_hold_write(coverage_case)
    accept_mst_aw(coverage_case)
    accept_mst_w(coverage_case.transaction)
    accept_slv_aw(coverage_case)
    accept_slv_w(coverage_case.transaction)

    assert_equal(
        signals.dbg_aw.entries[coverage_case.entry].valid:get(),
        1,
        coverage_case.transaction.name .. " remains valid before B"
    )

    if coverage_case.is_target then
        print_message(string.format(
            "Covered AxiReorder.sv:%d/%d by allocating AW entry%d",
            coverage_case.id_line,
            coverage_case.nid_line,
            coverage_case.entry
        ))
    end
end

-- 只有当下游 AW 和末拍 W 都已在更早的时钟沿完成，调用者才会进入这里。
-- BVALID 在 BREADY 之前保持，握手时检查 DUT 恢复的原始 12-bit BID。
local function send_b_response(coverage_case)
    local transaction = coverage_case.transaction

    set_slv_b(coverage_case.entry, 0, true)
    settle_combination()
    wait_until_observed(function()
        return dut.io_slv_b_ready:get() == 1 and dut.io_mst_b_valid:get() == 1
    end, transaction.name .. " B ready/valid")

    assert_equal(
        dut.io_mst_b_bits_id:get(),
        transaction.id,
        transaction.name .. " restored upstream BID"
    )
    assert_equal(
        dut.io_mst_b_bits_resp:get(),
        0,
        transaction.name .. " upstream BRESP"
    )

    env.wait_cycles(1)
    finish_handshake_edge()
    clear_slv_b()
    wait_negedge()

    assert_equal(
        signals.dbg_aw.entries[coverage_case.entry].valid:get(),
        0,
        transaction.name .. " released after its only B response"
    )
end

local function assert_all_entries_occupied()
    for entry = 0, LAST_ENTRY do
        local entry_signals = signals.dbg_aw.entries[entry]
        assert_equal(entry_signals.valid:get(), 1, string.format("entry%d full-table valid", entry))
        assert_equal(entry_signals.nid:get(), 0, string.format("entry%d full-table nid", entry))
        assert_equal(
            entry_signals.have_sent:get(),
            1,
            string.format("entry%d full-table haveSendAW", entry)
        )
    end

    -- 64 个表项全部有效时不能再接收第 65 笔 AW。这里只观察 READY，不驱动
    -- 额外 AWVALID，避免制造 scoreboard 中无法完成的事务。
    assert_equal(dut.io_mst_aw_ready:get(), 0, "AWREADY when all 64 entries are occupied")
end

local function assert_all_entries_free()
    for entry = 0, LAST_ENTRY do
        assert_equal(
            signals.dbg_aw.entries[entry].valid:get(),
            0,
            string.format("entry%d valid after final cleanup", entry)
        )
    end
end

-- 第 N 轮开始前，entry0 必须空闲，entry1..N-1 是前面已经完成下游 AW/W、
-- 尚未返回 B 的目标事务，其余高编号项必须空闲。该检查证明随后 P/T 的最低
-- 空闲项选择分别是 entry0 和 entryN，而不是依赖测试对内部状态的假设。
local function assert_decrement_layout(target_entry)
    for entry = 0, LAST_ENTRY do
        local entry_signals = signals.dbg_aw.entries[entry]
        local expected_valid = entry >= FIRST_DECREMENT_ENTRY and entry < target_entry

        assert_equal(
            entry_signals.valid:get(),
            expected_valid and 1 or 0,
            string.format(
                "before decrement entry%d scenario: entry%d valid",
                target_entry,
                entry
            )
        )

        if expected_valid then
            assert_equal(
                entry_signals.nid:get(),
                0,
                string.format("persistent entry%d nid before entry%d", entry, target_entry)
            )
            assert_equal(
                entry_signals.have_sent:get(),
                1,
                string.format("persistent entry%d haveSendAW before entry%d", entry, target_entry)
            )
        end
    end
end

-- 覆盖一个目标 entry 的 nid 减 1 语句。下面给出第 N 轮完整的通道级事务时序；
-- io_mst_* 是 DUT 的上游 AXI 端口，io_slv_* 是 DUT 的下游 AXI 端口：
--
-- 轮前布局：
--   entry0 空闲；前面各轮保留的目标事务占用 entry1..N-1，并且这些事务都已
--   完成下游 AW/W、只等待各自的最终 B；entryN..63 空闲。
--
-- 步骤 1，发送同 ID 前序事务 P：
--   a. io_mst_aw 发送 P，最低空闲项选择使 P 分配到 entry0，P.nid=0；
--   b. io_mst_w 发送 P 的单拍 W，WSTRB 全有效且 WLAST=1；
--   c. 依次握手 io_slv_aw(entry0) 和 io_slv_w(P)，证明 P 已完整到达下游；
--   d. 暂不发送 P 的 B，使 entry0 保持有效，作为目标事务 T 的同 ID 前序项。
--
-- 步骤 2，发送目标事务 T：
--   a. io_mst_aw 发送与 P 相同原始 ID、不同地址的 T；此时 entry0..N-1 均
--      有效，所以最低空闲项选择必然把 T 分配到 entryN；
--   b. 分配逻辑统计到 entry0 中尚未完成的同 ID 事务 P，因此 T.nid=1；
--   c. io_mst_w 发送 T 的单拍 W。W 通道没有 ID，DUT 按 AW 接收顺序将该 W
--      与 T 配对并缓存；
--   d. 因 awq 队首 T.nid=1，T 的 io_slv_aw_valid 必须保持为 0，不能越过 P
--      提前发送下游 AW。
--
-- 步骤 3，用 P 的合法 B 命中目标代码行：
--   a. 只有在步骤 1c 的 P 下游 AW/W 都已于更早上升沿握手后，测试才驱动
--      io_slv_b_valid=1、io_slv_b_bits_id=entry0；
--   b. DUT 用 entry0 恢复出 P 的原始 BID。由于 P 与 T 的原始 ID 相同，在该
--      B 握手沿，目标 else-if 的 nid非零、B fire、ID相等、T有效四个条件同时
--      成立，执行 AxiReorder.sv 对应行，使 T.nid 从 1 减为 0；
--   c. P 的 B 只发送一次，沿后 entry0 释放，同时检查上游 BID 恢复正确。
--
-- 步骤 4，完成并保留 T：
--   a. T.nid=0 后才依次握手 io_slv_aw(entryN) 和 io_slv_w(T)；
--   b. 暂不返回 T 的 B，让 entryN 成为下一轮 entryN+1 场景的合法占位项；
--   c. 全部 entry1..63 覆盖结束后，再逐项返回这些 T 的唯一 B，清空 DUT 和
--      scoreboard。每个 T 的 B 都晚于自己的下游 AW/W，也晚于同 ID 的 P B。
--
-- VALID 遇到 READY=0 时由 helper 持续保持，所有 AW、W、B 各握手一次；因此
-- 该场景既能稳定触发 nid 减 1，又满足 AXI 通道独立性和同 ID 写响应顺序。
local function cover_parameterized_aw_nid_decrement(coverage_case)
    local target_entry = coverage_case.entry
    local target_signals = signals.dbg_aw.entries[target_entry]

    assert_decrement_layout(target_entry)

    -- P 使用本轮 ID 分配到 entry0，并先完成下游 AW/W。至此返回 P 的 B 已具备
    -- 完整协议前提，但暂时保留 P，以便 T 分配时统计到一个同 ID 前序事务。
    allocate_and_hold_write(coverage_case.predecessor)

    -- entry0 和 entry1..N-1 均已占用，所以 T 必然分配到 entryN。T 与 P 同 ID，
    -- 分配沿后 nid 必须为 1。先接收上游 W，模拟一笔完整提交到 DUT 的写请求。
    accept_mst_aw(coverage_case.target)
    accept_mst_w(coverage_case.target.transaction)

    assert_equal(
        target_signals.nid:get(),
        1,
        string.format("AxiReorder.sv:%d entry%d nid before predecessor B", coverage_case.decrement_line, target_entry)
    )
    assert_equal(
        target_signals.have_sent:get(),
        0,
        string.format("entry%d must wait for same-ID predecessor B", target_entry)
    )
    assert_equal(
        dut.io_slv_aw_valid:get(),
        0,
        string.format("entry%d downstream AW must be blocked while nid=1", target_entry)
    )

    -- P 的 AW/W 已在更早上升沿完成，因此此处 B 合法。B 携带 entry0 的重映射
    -- ID，DUT 恢复出本轮原始 ID；同一上升沿执行目标 entry 的 nid 减 1 语句。
    send_b_response(coverage_case.predecessor)

    assert_equal(
        target_signals.valid:get(),
        1,
        string.format("AxiReorder.sv:%d entry%d remains valid after predecessor B", coverage_case.decrement_line, target_entry)
    )
    assert_equal(
        target_signals.nid:get(),
        0,
        string.format("AxiReorder.sv:%d entry%d nid after predecessor B", coverage_case.decrement_line, target_entry)
    )

    -- nid 清零后，T 才有资格向下游发送。完成其下游 AW/W 后暂不返回 T 的 B，
    -- 让 entryN 成为后续更高 entry 场景的合法占位事务。
    accept_slv_aw(coverage_case.target)
    accept_slv_w(coverage_case.target.transaction)

    assert_equal(
        target_signals.valid:get(),
        1,
        string.format("entry%d target remains pending before final B", target_entry)
    )
    assert_equal(
        target_signals.have_sent:get(),
        1,
        string.format("entry%d target completed downstream AW", target_entry)
    )

    print_message(string.format(
        "Covered AxiReorder.sv:%d by decrementing AW entry%d nid from 1 to 0",
        coverage_case.decrement_line,
        target_entry
    ))
end

local function task_line_coverage()
    -- 不启动随机 AXI agent，由本用例精确控制五个写通道。下游 READY 默认拉低，
    -- 仅在 helper 已确认 payload 后放行一个上升沿；上游始终准备接收 B。
    driver.drive {
        io_slv_ar_ready = 0,
        io_mst_r_ready = 0,
        io_slv_aw_ready = 0,
        io_slv_w_ready = 0,
        io_mst_b_ready = 1,
    }

    wait_negedge()

    -- 连续占用 entry0..63。entry0..7 是铺表项，entry8 开始逐项执行本次目标行。
    for _, coverage_case in ipairs(AW_ALLOCATION_CASES) do
        allocate_and_hold_write(coverage_case)
    end

    assert_all_entries_occupied()

    -- 每笔 B 都对应此前已经完整下游发送的 AW/W，且只发送一次。不同 ID 之间
    -- 没有响应顺序约束；按 entry 顺序清场便于检查每个有效位恰好清除一次。
    for _, coverage_case in ipairs(AW_ALLOCATION_CASES) do
        send_b_response(coverage_case)
    end

    assert_all_entries_free()

    -- 第二阶段覆盖 entry1..63 的 nid 减 1 语句。每轮目标事务在完成下游
    -- AW/W 后继续占表，最终形成 entry1..63 全部有效、entry0 空闲的布局。
    for _, coverage_case in ipairs(AW_NID_DECREMENT_CASES) do
        cover_parameterized_aw_nid_decrement(coverage_case)
    end

    -- 所有目标 T 都已完成下游 AW/W，且其同 ID 前序 P 已经先返回 B。现在逐项
    -- 返回 T 的唯一 B，保持同 ID 响应顺序并清空第二阶段的 scoreboard 状态。
    for _, coverage_case in ipairs(AW_NID_DECREMENT_CASES) do
        send_b_response(coverage_case.target)
    end

    assert_all_entries_free()

    dut.io_mst_b_ready:set_imm(0)
    dut.io_slv_aw_ready:set_imm(0)
    dut.io_slv_w_ready:set_imm(0)
    clear_mst_aw()
    clear_mst_w()
    clear_slv_b()
    env.wait_cycles(1)

    print_message(string.format(
        "012 line coverage completed: parameterized %d allocation entries, covered %d allocation entries (%d RTL lines), and covered %d nid-decrement lines",
        #AW_ALLOCATION_CASES,
        LAST_ENTRY - FIRST_TARGET_ENTRY + 1,
        2 * (LAST_ENTRY - FIRST_TARGET_ENTRY + 1),
        #AW_NID_DECREMENT_CASES
    ))
end

return {
    tasks = {
        task_line_coverage,
    },
}
