local env = require "env"
local driver = require "dut.driver"

--[====[
================================================================================
012_linecoverage.lua
================================================================================

一、覆盖目标

本文件覆盖 AxiReorder 读表 entry 0..63 的 nid 减 2 分支：

    else if (target_layer_probe)
        arinfo_N_nid <= arinfo_N_nid - 6'h2;

entry=N 对应的门控信号为：

    current GEN = _GEN_(2*N+2)
    delayed GEN = _GEN_(2*N+3)
    layer probe = _layer_probe_(4*N+1)

目标 RTL 行从 entry 0 的 4247 行连续映射到 entry 63 的 5497 行。entry 0..10
每项间隔 19 行；entry 11..63 每项间隔 20 行。

二、参数化激励

全部 64 个目标由 cover_parameterized_read_nid_minus_two(entry, line) 实现，
并通过 LINE_COVERAGE_CASES 参数化生成。公共 AXI helper 负责握手、payload
检查、超时和错误打印，目标函数只保留表项布局和两拍关键时序。

每个目标都构造三笔相同原始 ID 的读事务：

    P1 : 第一笔前序事务，已经发送下游 AR
    P2 : 第二笔前序事务，nid=1，等待 P1
    P3 : 目标事务，分配时看到 P1/P2，装载 nid=2

关键周期 1 同时分配 P3 并返回 P1 的末拍 R，建立指向目标 entry 的延迟修正；
关键周期 2 让 P2 的下游 AR/R 同周期握手，使 current GEN 和 delayed GEN
同时为 1，拉高目标 layer probe。沿后检查 arinfo_N_nid 从 2 直接变为 0。

三、表项布局

entry 0/1 需要处理最低空闲项选择，准备阶段分别使用以下布局：

    target entry 0 : temporary=0, P1=1, P2=2，释放 temporary 后分配 P3
    target entry 1 : P1=0, temporary=1, P2=2，释放 temporary 后分配 P3

这两个目标完成后立即返回 P3 的 R，各自恢复为空表。

从 entry 2 开始使用连续布局：已覆盖的目标 entry 2..N-1 保持有效，但都已发送
下游 AR；P1/P2 每轮复用 entry 0/1，因此 P3 自然分配到 entry N。每个 N 使用
独立原始 ID，先前目标只负责占表，不会增加当前 rawRNid。entry 63 覆盖完成后
统一返回 entry 2..63 的 pending R，清空整张读表和 scoreboard。

所有激励只写 AxiReorder 顶层 io_mst_* / io_slv_* 端口。DUT 内部句柄仅用于
确认目标分支条件和寄存器更新结果，不 force、deposit 或修改内部状态。

四、AW entry 0..63 的 nid 减 2 分支

生成 RTL 在 5513..6701 行为写表 entry 0..63 展开了相同的减 2 模板：

    current GEN = _GEN_(2*N+143)
    delayed GEN = _GEN_(2*N+144)

    if (current GEN & delayed GEN)
        awinfo_N_nid <= awinfo_N_nid - 6'h2;

AW_NID_MINUS_TWO_CASES 参数化登记全部 64 个 entry、RTL 行号和 GEN 编号。
这些目标在当前 buffer=64、awq entries=1 的结构下全部不可达，不是只针对某个
entry 的偶然现象。要执行减 2，目标 AW 分配前必须已有两笔同 ID 前序写 P1/P2，
使目标的 rawWNid=2；同时还必须在 P1 返回 B 的周期完成目标 AW 握手，以建立
wWkVldReg/wWkEtrReg。可是 P2 的 nid=1，会占据唯一的 awq 表项，而 awq 队首
只有在对应 awinfo.nid=0 时才能出队。因此：

1. P1 返回 B 的周期，P2 的 nid 在时钟沿之后才从 1 变成 0；
2. 该周期沿前 awq 仍满且不能出队，awq.io.enq.ready=0；
3. io.mst.aw.ready 包含 awq.io.enq.ready，所以目标 P3 AW 无法握手；
4. 没有 P3 AW fire，就不能产生 wWkVld，也不能把目标 entry 写入 wWkEtrReg；
5. 下一周期即使合法返回另一笔同 ID B，delayed GEN 仍必然为 0。

cover_parameterized_write_nid_minus_two_unreachable() 不只做静态登记，而是对
每个 entry 都构造合法端口见证：先用不同 ID 事务占住所有更低表项，使当前目标
entry 确为最低空闲项；再构造 P1/P2 两笔同 ID 写，令 P1 已完成下游 AW/W、P2
以 nid=1 堵在 awq。P1 B 与 P3 AW 同拍驱动时，测试逐项检查：

    * AW 空闲项选择结果确实指向当前目标 entry；
    * P1 B 合法握手并恢复原始 ID；
    * P2 仍是 awq 队首且 nid=1、不能出队；
    * P3 AWREADY=0，目标表项没有分配，wWkVldReg 也不会建立。

随后保持 P3 AWVALID，等 P2 在下一拍合法出队时完成 P3 握手。此时 P1 已经释放，
所以 P3 的 nid 只能等于 1；返回 P2 的 B 后只能执行减 1，不能执行目标减 2。
最后补齐所有 AW/W/B 并清空 scoreboard。

若重复发送已经完成事务的 B，会触发“B fire but vec is not valid”断言；若在
AW/W 尚未下游完成时提前返回 B，则违反 AXI 协议和 scoreboard 对应关系，并会
触发 RTL 断言。本用例不会用非法响应伪造行覆盖。5513..6701 的 64 条 AW 减 2
代码应在覆盖工具中按结构性不可达代码 waiver/exclude；本用例提供逐 entry 的
动态证据和详细中文原因。

五、6712 行 wWkEtrReg 更新

6712 行与上述减 2 分支不同，它只要求一笔合法 B 与一笔同原始 ID 的新 AW 在
同一周期成功握手：

    wWkVld = B fire && AW fire && new AWID == restored BID

    if (wWkVld)
        wWkEtrReg <= selected_free_write_entry;  // 第 6712 行

WWK_ENTRY_UPDATE_CASES 使用独立参数表驱动该场景。H1 先完整完成下游 AW/W，
使 entry0 合法等待 B，同时保证 awq/wq/wbitsq 已排空；随后 H1 的 B 与同 ID
H2 的 AW 同拍握手。此时 H2 选择最低空闲 entry1，时钟沿后检查
wWkVldReg=1、wWkEtrReg=0x2，直接证明 6712 行已经执行。下一拍延迟修正会把
H2 的 nid 从 1 减到 0，之后再补齐 H2 的 W、下游 AW/W 和 B。

所有响应都只在对应 AW/W 已被下游接收后产生；每笔 B 只发送一次，整个场景
符合 AXI 五通道独立握手、同 ID 写响应顺序和公共 scoreboard 的事务对应关系。
================================================================================
]====]

local clock = dut.clock:chdl()
local core = dut.u_AxiReorder

-- 目标信号名称可由 entry 编号直接推导。内部句柄仅用于覆盖点自检，并按需
-- 缓存，避免为相同结构的 64 个表项手工声明 GEN、layer probe 和状态信号。
local core_signal_cache = {}

local function core_signal(name)
    local signal = core_signal_cache[name]
    if signal == nil then
        signal = core[name]:chdl()
        core_signal_cache[name] = signal
    end
    return signal
end

local TIMEOUT = 100

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

local function wait_negedge()
    clock:negedge()
end

-- set_imm() 更新端口后，等待连续组合逻辑传播完成。await_rd() 不推进仿真
-- 时间，避免 VALID 意外跨过额外的上升沿形成重复握手。
local function settle_combination()
    await_rd()
end

-- 上升沿触发后进入同一仿真时刻的 read/write 同步阶段。此时 RTL 和 monitor
-- 已经采样本拍握手，可以安全撤销 VALID/READY。
local function finish_handshake_edge()
    await_rw()
end

local function wait_until_observed(predicate, description)
    for _ = 1, TIMEOUT do
        if predicate() then
            return
        end

        -- AXI VALID 在 READY=0 时保持，因此等待下一个下降沿不会漏掉握手请求。
        wait_negedge()
    end

    assert(false, error_message("timeout waiting for " .. description))
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

-- 本用例使用单拍、32-byte、INCR 读请求。地址按 32 byte 对齐且互不相同，
-- 便于公共 scoreboard 根据 payload 配对上游和下游 AR。
local function set_mst_ar(transaction, valid)
    dut.io_mst_ar_valid:set_imm(valid and 1 or 0)
    dut.io_mst_ar_bits_id:set_imm(transaction.id)
    dut.io_mst_ar_bits_addr:set_imm(transaction.addr)
    dut.io_mst_ar_bits_len:set_imm(0)
    dut.io_mst_ar_bits_size:set_imm(5)
    dut.io_mst_ar_bits_burst:set_imm(1)
    dut.io_mst_ar_bits_lock:set_imm(0)
    dut.io_mst_ar_bits_cache:set_imm(0)
    dut.io_mst_ar_bits_prot:set_imm(0)
    dut.io_mst_ar_bits_qos:set_imm(0)
    dut.io_mst_ar_bits_region:set_imm(0)
end

local function clear_mst_ar()
    dut.io_mst_ar_valid:set_imm(0)
end

local function set_slv_ar_ready(value)
    dut.io_slv_ar_ready:set_imm(value)
end

local function set_slv_r(entry, data, resp, valid)
    dut.io_slv_r_valid:set_imm(valid and 1 or 0)
    dut.io_slv_r_bits_id:set_imm(entry)
    dut.io_slv_r_bits_data:set_imm(data)
    dut.io_slv_r_bits_resp:set_imm(resp)
    dut.io_slv_r_bits_last:set_imm(valid and 1 or 0)
end

local function clear_slv_r()
    dut.io_slv_r_valid:set_imm(0)
    dut.io_slv_r_bits_id:set_imm(0)
    dut.io_slv_r_bits_data:set_imm(0)
    dut.io_slv_r_bits_resp:set_imm(0)
    dut.io_slv_r_bits_last:set_imm(0)
end

-- 只完成上游 AR 握手，使请求进入重排表；不等待它向下游发送。
local function accept_mst_ar(transaction)
    set_mst_ar(transaction, true)
    settle_combination()
    wait_until_observed(function()
        return dut.io_mst_ar_ready:get() == 1
    end, transaction.name .. " upstream ARREADY")

    env.wait_cycles(1)
    finish_handshake_edge()
    clear_mst_ar()
    wait_negedge()
end

-- 完成指定事务的下游 AR，并检查 DUT 产生的 6-bit 重映射 entry ID 和地址。
local function accept_slv_ar(transaction, expected_entry)
    wait_until_observed(function()
        return dut.io_slv_ar_valid:get() == 1
    end, transaction.name .. " downstream ARVALID")

    assert_equal(
        dut.io_slv_ar_bits_id:get(),
        expected_entry,
        transaction.name .. " downstream AR entry"
    )
    assert_equal(
        dut.io_slv_ar_bits_addr:get(),
        transaction.addr,
        transaction.name .. " downstream AR address"
    )

    set_slv_ar_ready(1)
    settle_combination()
    env.wait_cycles(1)
    finish_handshake_edge()
    set_slv_ar_ready(0)
    wait_negedge()
end

local function send_read_request(transaction, expected_entry)
    accept_mst_ar(transaction)
    accept_slv_ar(transaction, expected_entry)
end

-- 返回一笔普通单拍 R，并同时检查响应有效和原始 AXI ID 恢复。
local function send_r_response(entry, data, resp, expected_upstream_id, description)
    dut.io_mst_r_ready:set_imm(1)
    set_slv_r(entry, data, resp, true)
    settle_combination()

    assert(
        dut.io_slv_r_ready:get() == 1 and dut.io_mst_r_valid:get() == 1,
        error_message(description .. " R channel is not ready/valid")
    )
    assert_equal(
        dut.io_mst_r_bits_id:get(),
        expected_upstream_id,
        description .. " restored upstream RID"
    )

    env.wait_cycles(1)
    finish_handshake_edge()
    clear_slv_r()
    wait_negedge()
end

-- ============================================================================
-- 写通道公共 helper
-- ============================================================================
-- AW 不可达性见证使用单拍、32-byte、INCR 写事务。与读 helper 相同，所有
-- VALID/READY 都只跨越一个实际握手上升沿，避免重复事务。
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

local function accept_mst_aw(transaction)
    set_mst_aw(transaction, true)
    settle_combination()
    wait_until_observed(function()
        return dut.io_mst_aw_ready:get() == 1
    end, transaction.name .. " upstream AWREADY")

    env.wait_cycles(1)
    finish_handshake_edge()
    clear_mst_aw()
    wait_negedge()
end

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

-- awq 严格保持上游 AW 顺序，只有队首 entry 的 nid=0 时才产生下游 AWVALID。
-- helper 同时检查重映射后的 6-bit entry ID 和原始地址。
local function accept_slv_aw(transaction, expected_entry)
    wait_until_observed(function()
        return dut.io_slv_aw_valid:get() == 1
    end, transaction.name .. " downstream AWVALID")

    assert_equal(
        dut.io_slv_aw_bits_id:get(),
        expected_entry,
        transaction.name .. " downstream AW entry"
    )
    assert_equal(
        dut.io_slv_aw_bits_addr:get(),
        transaction.addr,
        transaction.name .. " downstream AW address"
    )

    dut.io_slv_aw_ready:set_imm(1)
    settle_combination()
    env.wait_cycles(1)
    finish_handshake_edge()
    dut.io_slv_aw_ready:set_imm(0)
    wait_negedge()
end

-- wbitsq 会等对应 AW 已发送下游后才允许 W 出队。这里检查单拍 W 的 data 和
-- last；strb 固定为全部字节有效，scoreboard 会同时完成 payload 比对。
local function accept_slv_w(transaction)
    wait_until_observed(function()
        return dut.io_slv_w_valid:get() == 1
    end, transaction.name .. " downstream WVALID")

    local actual_data = dut.io_slv_w_bits_data:get_hex_str():lower():gsub("^0+", "")
    local expected_data = string.format("%x", transaction.data)
    assert_equal(actual_data, expected_data, transaction.name .. " downstream W data")
    assert_equal(
        dut.io_slv_w_bits_last:get(),
        1,
        transaction.name .. " downstream WLAST"
    )

    dut.io_slv_w_ready:set_imm(1)
    settle_combination()
    env.wait_cycles(1)
    finish_handshake_edge()
    dut.io_slv_w_ready:set_imm(0)
    wait_negedge()
end

-- 完整发送一笔单拍写事务，但暂不返回 B。调用结束后，该 entry 的 AW/W 已经
-- 被下游接收，wvld 仍保持为 1，可以作为后续目标 entry 的合法占位事务。
local function send_write_request(transaction, expected_entry)
    accept_mst_aw(transaction)
    accept_mst_w(transaction)
    accept_slv_aw(transaction, expected_entry)
    accept_slv_w(transaction)
end

local function send_b_response(entry, resp, expected_upstream_id, description)
    dut.io_mst_b_ready:set_imm(1)
    set_slv_b(entry, resp, true)
    settle_combination()

    assert(
        dut.io_slv_b_ready:get() == 1 and dut.io_mst_b_valid:get() == 1,
        error_message(description .. " B channel is not ready/valid")
    )
    assert_equal(
        dut.io_mst_b_bits_id:get(),
        expected_upstream_id,
        description .. " restored upstream BID"
    )

    env.wait_cycles(1)
    finish_handshake_edge()
    clear_slv_b()
    wait_negedge()
end

-- 64 个目标 entry 共用一个连续参数化场景。entry 0/1 因最低空闲项选择
-- 需要临时占位事务；entry 2..63 则保留已经发送下游 AR、尚未返回 R 的目标
-- 事务来递增占表。三种准备布局之后的关键两拍和检查完全相同。
local parameterized_read_state = {
    next_entry = 0,
    pending = {},
}

local function read_nid_minus_two_line(entry)
    if entry <= 10 then
        return 4247 + 19 * entry
    end
    return 4237 + 20 * entry
end

local function make_read_transaction(name, id, serial)
    return {
        name = name,
        id = id,
        addr = 0x20000 + serial * 0x20,
    }
end

local function assert_read_occupancy(first_entry, last_entry, description)
    for entry = 0, 63 do
        local expected = 0
        if
            first_entry ~= nil and
            entry >= first_entry and
            entry <= last_entry
        then
            expected = 1
        end

        assert_equal(
            core_signal("rvld_" .. entry):get(),
            expected,
            string.format("%s entry%d rvld", description, entry)
        )
    end
end

-- 返回 P1/P2 实际占用的 entry。entry 0/1 先借助不同 ID 的临时事务腾出目标
-- 表项；entry>=2 时，P1/P2 直接使用每轮都空闲的 entry 0/1。
local function prepare_parameterized_predecessors(
    entry,
    line,
    predecessor_1,
    predecessor_2
)
    local predecessor_1_entry
    local predecessor_2_entry
    local temporary
    local temporary_entry

    if entry == 0 then
        temporary = make_read_transaction(
            "entry0 temporary occupant",
            0x800,
            entry * 4 + 3
        )
        temporary_entry = 0
        send_read_request(temporary, temporary_entry)
        send_read_request(predecessor_1, 1)
        accept_mst_ar(predecessor_2)
        predecessor_1_entry = 1
        predecessor_2_entry = 2
    elseif entry == 1 then
        temporary = make_read_transaction(
            "entry1 temporary occupant",
            0x801,
            entry * 4 + 3
        )
        temporary_entry = 1
        send_read_request(predecessor_1, 0)
        send_read_request(temporary, temporary_entry)
        accept_mst_ar(predecessor_2)
        predecessor_1_entry = 0
        predecessor_2_entry = 2
    else
        send_read_request(predecessor_1, 0)
        accept_mst_ar(predecessor_2)
        predecessor_1_entry = 0
        predecessor_2_entry = 1
    end

    assert(
        core_signal("rvld_" .. predecessor_2_entry):get() == 1 and
        core_signal("arinfo_" .. predecessor_2_entry .. "_nid"):get() == 1,
        error_message(string.format(
            "AxiReorder.sv:%d P2 did not establish entry%d nid=1",
            line,
            predecessor_2_entry
        ))
    )
    assert_equal(
        dut.io_slv_ar_valid:get(),
        0,
        string.format("AxiReorder.sv:%d P2 ARVALID before P1 completion", line)
    )

    if temporary ~= nil then
        send_r_response(
            temporary_entry,
            0x100 + entry,
            0,
            temporary.id,
            string.format("release entry%d temporary occupant", entry)
        )
    end

    return predecessor_1_entry, predecessor_2_entry
end

local function finish_parameterized_read_entries()
    -- entry 2..63 的目标均已完成下游 AR；逐笔返回 R，保证公共 monitor 和
    -- scoreboard 完整收尾。它们使用不同原始 ID，响应顺序不影响合法性。
    for entry = 2, 63 do
        local transaction = parameterized_read_state.pending[entry]
        assert(
            transaction ~= nil,
            error_message(string.format("missing pending transaction for entry%d", entry))
        )
        send_r_response(
            entry,
            0x500 + entry,
            entry % 4,
            transaction.id,
            string.format("complete persistent target entry%d", entry)
        )
    end

    assert_read_occupancy(
        nil,
        nil,
        "after parameterized scenario cleanup"
    )
end

local function cover_parameterized_read_nid_minus_two(entry, line)
    assert_equal(
        entry,
        parameterized_read_state.next_entry,
        "parameterized line coverage entry order"
    )
    assert_equal(
        line,
        read_nid_minus_two_line(entry),
        string.format("AxiReorder entry%d target line", entry)
    )

    local occupied_first = nil
    local occupied_last = nil
    if entry >= 3 then
        occupied_first = 2
        occupied_last = entry - 1
    end
    assert_read_occupancy(
        occupied_first,
        occupied_last,
        string.format("before AxiReorder.sv:%d setup", line)
    )

    local target_id = 0x100 + entry
    local predecessor_1 = make_read_transaction(
        string.format("entry%d P1(first predecessor)", entry),
        target_id,
        entry * 4
    )
    local predecessor_2 = make_read_transaction(
        string.format("entry%d P2(second predecessor)", entry),
        target_id,
        entry * 4 + 1
    )
    local target = make_read_transaction(
        string.format("entry%d P3(target transaction)", entry),
        target_id,
        entry * 4 + 2
    )

    print_message(string.format(
        "Start AxiReorder.sv:%d line coverage: arinfo_%d_nid changes 2 -> 0",
        line,
        entry
    ))

    local predecessor_1_entry, predecessor_2_entry =
        prepare_parameterized_predecessors(
            entry,
            line,
            predecessor_1,
            predecessor_2
        )

    -- 关键周期 1：P3 分配到目标 entry，同时返回 P1 的末拍 R。P3 在沿前统计
    -- 到同 ID 的 P1/P2，装载 nid=2；分配和响应并发还会保存目标 entry 的
    -- 延迟修正。
    set_mst_ar(target, true)
    dut.io_mst_r_ready:set_imm(1)
    set_slv_r(predecessor_1_entry, 0x200 + entry, 1, true)
    settle_combination()

    assert_equal(
        dut.io_mst_ar_ready:get(),
        1,
        string.format("AxiReorder.sv:%d target ARREADY", line)
    )
    assert_equal(
        dut.io_slv_r_ready:get(),
        1,
        string.format("AxiReorder.sv:%d P1 RREADY", line)
    )
    assert_equal(
        dut.io_mst_r_bits_id:get(),
        target_id,
        string.format("AxiReorder.sv:%d P1 restored upstream RID", line)
    )

    env.wait_cycles(1)
    finish_handshake_edge()
    clear_mst_ar()
    clear_slv_r()
    wait_negedge()

    assert(
        core_signal("rvld_" .. entry):get() == 1 and
        core_signal("arinfo_" .. entry .. "_nid"):get() == 2,
        error_message(string.format(
            "AxiReorder.sv:%d target did not enter entry%d with nid=2",
            line,
            entry
        ))
    )
    assert_equal(
        core.rWkVldReg:get(),
        1,
        string.format("AxiReorder.sv:%d delayed correction valid", line)
    )
    assert_equal(
        core_signal("_GEN_" .. (2 * entry + 3)):get(),
        1,
        string.format("AxiReorder.sv:%d delayed correction entry bit", line)
    )
    assert(
        dut.io_slv_ar_valid:get() == 1 and
        dut.io_slv_ar_bits_id:get() == predecessor_2_entry and
        dut.io_slv_ar_bits_addr:get() == predecessor_2.addr,
        error_message(string.format(
            "AxiReorder.sv:%d P2 was not selected after P1 completion",
            line
        ))
    )

    -- 关键周期 2：刚解除依赖的 P2 在下游 AR/R 同周期握手。当前响应 GEN 和
    -- 上一周期保存的修正 GEN 共同拉高目标 layer probe。
    set_slv_ar_ready(1)
    set_slv_r(predecessor_2_entry, 0x300 + entry, 2, true)
    settle_combination()

    assert_equal(
        core_signal("_GEN_" .. (2 * entry + 2)):get(),
        1,
        string.format("AxiReorder.sv:%d current response GEN", line)
    )
    assert_equal(
        core_signal("_GEN_" .. (2 * entry + 3)):get(),
        1,
        string.format("AxiReorder.sv:%d delayed correction GEN", line)
    )
    assert_equal(
        core_signal("_layer_probe_" .. (4 * entry + 1)):get(),
        1,
        string.format("AxiReorder.sv:%d target layer probe", line)
    )
    assert_equal(
        dut.io_mst_ar_valid:get(),
        0,
        string.format("upstream ARVALID on AxiReorder.sv:%d target edge", line)
    )
    assert(
        dut.io_slv_ar_ready:get() == 1 and dut.io_slv_r_ready:get() == 1,
        error_message(string.format(
            "AxiReorder.sv:%d P2 zero-latency AR/R channels are not both ready",
            line
        ))
    )

    env.wait_cycles(1)
    finish_handshake_edge()
    clear_slv_r()
    set_slv_ar_ready(0)
    wait_negedge()

    assert_equal(
        core_signal("arinfo_" .. entry .. "_nid"):get(),
        0,
        string.format("AxiReorder.sv:%d arinfo_%d_nid after target edge", line, entry)
    )
    print_message(string.format(
        "Covered AxiReorder.sv:%d; arinfo_%d_nid changed 2 -> 0",
        line,
        entry
    ))

    accept_slv_ar(target, entry)

    if entry < 2 then
        -- entry 0/1 的特殊布局各自独立收尾，使下一场景重新从空表开始。
        send_r_response(
            entry,
            0x400 + entry,
            3,
            target.id,
            string.format("complete target entry%d", entry)
        )
        assert_read_occupancy(
            nil,
            nil,
            string.format("after AxiReorder.sv:%d target", line)
        )
    else
        -- entry 2..63 的目标保留到最后统一返回，用作下一目标的低编号占位。
        parameterized_read_state.pending[entry] = target
        assert_read_occupancy(
            2,
            entry,
            string.format("after AxiReorder.sv:%d target", line)
        )
    end

    parameterized_read_state.next_entry = entry + 1
    if entry == 63 then
        finish_parameterized_read_entries()
    end
end

-- ============================================================================
-- AW entry 0..63 不可达分支的参数化见证
-- ============================================================================

local parameterized_write_state = {
    next_entry = 0,
    pending = {},
}

-- AW 生成代码在 entry 0..9 和 entry 10..63 的格式略有不同，因此行号不能
-- 简单使用一个固定步长。这里把用户要求的 5513..6701 行映射集中管理，避免
-- 64 个 testcase 各自硬编码行号后发生漂移。
local function write_nid_minus_two_line(entry)
    if entry <= 9 then
        return 5513 + 18 * entry
    end
    return 5504 + 19 * entry
end

local function make_write_transaction(name, id, serial)
    return {
        name = name,
        id = id,
        addr = 0x60000 + serial * 0x20,
        data = 0xA00000 + serial,
    }
end

-- 检查参数化场景中已经保留的不同 ID 占位写。每一个占位事务都已完成
-- 下游 AW/W，只有 B 尚未返回，因此不会阻塞 awq，却会占住指定表项。
local function assert_write_occupancy(first_entry, last_entry, description)
    for entry = 0, 63 do
        local expected = 0
        if
            first_entry ~= nil and
            entry >= first_entry and
            entry <= last_entry
        then
            expected = 1
        end

        assert_equal(
            core_signal("wvld_" .. entry):get(),
            expected,
            string.format("%s entry%d wvld", description, entry)
        )
        if expected == 1 then
            assert_equal(
                core_signal("awinfo_" .. entry .. "_nid"):get(),
                0,
                string.format("%s entry%d nid", description, entry)
            )
            assert_equal(
                core_signal("awinfo_" .. entry .. "_haveSendAW"):get(),
                1,
                string.format("%s entry%d haveSendAW", description, entry)
            )
        end
    end
end

-- awsel 使用最低编号空闲项。检查所有低编号表项都有效、目标表项无效，可以
-- 直接证明当前最低空闲项就是 entry。不能直接比较 _awsel_res_bits_T_1：它只是
-- PickOne 中“有效向量加一”的传播中间量，真正 one-hot 还要与 ~wvld 按位与。
local function assert_aw_selected_entry(entry, line, description)
    for lower_entry = 0, entry - 1 do
        assert_equal(
            core_signal("wvld_" .. lower_entry):get(),
            1,
            string.format(
                "AxiReorder.sv:%d %s lower entry%d must be occupied",
                line,
                description,
                lower_entry
            )
        )
    end
    assert_equal(
        core_signal("wvld_" .. entry):get(),
        0,
        string.format(
            "AxiReorder.sv:%d %s target entry%d must be free",
            line,
            description,
            entry
        )
    )
end

-- entry 0/1 需要临时占位才能把 P1/P2 放到更高位置；entry>=2 则使用已保留
-- 的低编号不同 ID 占位。P2 只接收上游 AW/W，故 nid=1 的 P2 会留在唯一 awq
-- 中，形成后续不可达性的合法前置状态。
local function prepare_parameterized_aw_predecessors(
    entry,
    line,
    predecessor_1,
    predecessor_2
)
    local predecessor_1_entry
    local predecessor_2_entry
    local temporary
    local temporary_entry

    if entry == 0 then
        temporary = make_write_transaction(
            "entry0 temporary AW occupant",
            0x700,
            entry * 8 + 3
        )
        temporary_entry = 0
        send_write_request(temporary, temporary_entry)
        send_write_request(predecessor_1, 1)
        accept_mst_aw(predecessor_2)
        accept_mst_w(predecessor_2)
        predecessor_1_entry = 1
        predecessor_2_entry = 2
    elseif entry == 1 then
        temporary = make_write_transaction(
            "entry1 temporary AW occupant",
            0x701,
            entry * 8 + 3
        )
        temporary_entry = 1
        send_write_request(predecessor_1, 0)
        send_write_request(temporary, temporary_entry)
        accept_mst_aw(predecessor_2)
        accept_mst_w(predecessor_2)
        predecessor_1_entry = 0
        predecessor_2_entry = 2
    else
        send_write_request(predecessor_1, 0)
        accept_mst_aw(predecessor_2)
        accept_mst_w(predecessor_2)
        predecessor_1_entry = 0
        predecessor_2_entry = 1
    end

    assert_equal(
        core_signal("wvld_" .. predecessor_1_entry):get(),
        1,
        string.format("AxiReorder.sv:%d P1 wvld", line)
    )
    assert_equal(
        core_signal("awinfo_" .. predecessor_1_entry .. "_nid"):get(),
        0,
        string.format("AxiReorder.sv:%d P1 nid", line)
    )
    assert_equal(
        core_signal("awinfo_" .. predecessor_1_entry .. "_haveSendAW"):get(),
        1,
        string.format("AxiReorder.sv:%d P1 haveSendAW", line)
    )
    assert_equal(
        core_signal("wvld_" .. predecessor_2_entry):get(),
        1,
        string.format("AxiReorder.sv:%d P2 wvld", line)
    )
    assert_equal(
        core_signal("awinfo_" .. predecessor_2_entry .. "_nid"):get(),
        1,
        string.format("AxiReorder.sv:%d P2 nid=1", line)
    )
    assert_equal(
        core_signal("awinfo_" .. predecessor_2_entry .. "_haveSendAW"):get(),
        0,
        string.format("AxiReorder.sv:%d P2 is still waiting for AW", line)
    )
    assert_equal(
        dut.io_slv_aw_valid:get(),
        0,
        string.format("AxiReorder.sv:%d P2 AWVALID before P1 B", line)
    )

    if temporary ~= nil then
        -- 临时事务已经完整下游发送，此处返回它的 B，释放目标 entry。这个
        -- B 与 P1 的原始 ID 不同，不会产生目标分支需要的延迟修正。
        send_b_response(
            temporary_entry,
            0,
            temporary.id,
            string.format("release entry%d temporary AW occupant", entry)
        )
    end

    assert_aw_selected_entry(entry, line, "after predecessor preparation")
    return predecessor_1_entry, predecessor_2_entry
end

-- P2 的 nid 在 P1 B 的上升沿之后才更新为 0。此 helper 在保持 P3 AWVALID 的
-- 同时接收 P2 的下游 AW，并检查 Queue(pipe=true) 的“出队同时入队”行为：
-- 该沿会接收 P3，但它只能看到一个仍有效的同 ID P2，因此 rawWNid=1。
local function replace_awq_head_with_target(
    predecessor_2,
    predecessor_2_entry,
    target,
    line
)
    wait_until_observed(function()
        return dut.io_slv_aw_valid:get() == 1
    end, predecessor_2.name .. " downstream AWVALID after P1 B")

    assert_equal(
        dut.io_slv_aw_bits_id:get(),
        predecessor_2_entry,
        string.format("AxiReorder.sv:%d P2 downstream AW entry", line)
    )
    assert_equal(
        dut.io_slv_aw_bits_addr:get(),
        predecessor_2.addr,
        string.format("AxiReorder.sv:%d P2 downstream AW address", line)
    )

    dut.io_slv_aw_ready:set_imm(1)
    settle_combination()
    assert_equal(
        dut.io_mst_aw_ready:get(),
        1,
        string.format("AxiReorder.sv:%d target AWREADY after P2 becomes nid=0", line)
    )
    assert_equal(
        dut.io_mst_aw_bits_id:get(),
        target.id,
        string.format("AxiReorder.sv:%d target AW payload held while stalled", line)
    )
    assert_equal(
        core_signal("aw_mst_fire_hit_0"):get(),
        1,
        string.format("AxiReorder.sv:%d P3 actual allocation selects entry0", line)
    )

    env.wait_cycles(1)
    finish_handshake_edge()
    dut.io_slv_aw_ready:set_imm(0)
    clear_mst_aw()
    wait_negedge()
end

local function install_persistent_aw_filler(entry, line)
    -- P3 在不可达见证中实际会落入 entry0（P1 B 已释放最低项），所以不能
    -- 直接把它当作 entry=N 的占位。先临时占住 0/1，再分配并发送一个不同
    -- ID 的 filler 到 entry=N，最后释放临时项，保持下一轮的连续布局。
    local temporary_0 = make_write_transaction(
        string.format("entry%d filler temporary0", entry),
        0x800 + entry * 2,
        entry * 8 + 4
    )
    local temporary_1 = make_write_transaction(
        string.format("entry%d filler temporary1", entry),
        0x800 + entry * 2 + 1,
        entry * 8 + 5
    )
    local filler = make_write_transaction(
        string.format("entry%d persistent AW filler", entry),
        0xA00 + entry,
        entry * 8 + 6
    )

    send_write_request(temporary_0, 0)
    send_write_request(temporary_1, 1)
    send_write_request(filler, entry)
    send_b_response(0, 0, temporary_0.id, temporary_0.name)
    send_b_response(1, 0, temporary_1.id, temporary_1.name)

    assert_equal(
        core_signal("wvld_" .. entry):get(),
        1,
        string.format("AxiReorder.sv:%d persistent filler entry%d wvld", line, entry)
    )
    assert_equal(
        core_signal("awinfo_" .. entry .. "_nid"):get(),
        0,
        string.format("AxiReorder.sv:%d persistent filler entry%d nid", line, entry)
    )
    return filler
end

local function finish_parameterized_aw_entries()
    -- 所有 entry 2..63 的 filler 都已经完成 AW/W，只需按 entry 返回合法 B。
    -- 每个 filler 使用不同原始 ID，因此不依赖不同 ID 响应的顺序。
    for entry = 2, 63 do
        local transaction = parameterized_write_state.pending[entry]
        assert(
            transaction ~= nil,
            error_message(string.format("missing pending AW filler entry%d", entry))
        )
        send_b_response(
            entry,
            0,
            transaction.id,
            string.format("complete persistent AW filler entry%d", entry)
        )
    end

    assert_write_occupancy(nil, nil, "after AW unreachable witness cleanup")
end

local function cover_parameterized_write_nid_minus_two_unreachable(
    entry,
    line,
    current_gen,
    delayed_gen
)
    assert_equal(
        entry,
        parameterized_write_state.next_entry,
        "parameterized AW line coverage entry order"
    )
    assert_equal(
        line,
        write_nid_minus_two_line(entry),
        string.format("AxiReorder AW entry%d target line", entry)
    )
    assert_equal(
        current_gen,
        143 + 2 * entry,
        string.format("AxiReorder AW entry%d current GEN", entry)
    )
    assert_equal(
        delayed_gen,
        144 + 2 * entry,
        string.format("AxiReorder AW entry%d delayed GEN", entry)
    )

    if entry >= 2 then
        assert_write_occupancy(
            2,
            entry - 1,
            string.format("before AW AxiReorder.sv:%d setup", line)
        )
    else
        assert_write_occupancy(
            nil,
            nil,
            string.format("before AW AxiReorder.sv:%d setup", line)
        )
    end

    local target_id = 0x400 + entry
    local predecessor_1 = make_write_transaction(
        string.format("entry%d P1(first AW predecessor)", entry),
        target_id,
        entry * 8
    )
    local predecessor_2 = make_write_transaction(
        string.format("entry%d P2(second AW predecessor)", entry),
        target_id,
        entry * 8 + 1
    )
    local target = make_write_transaction(
        string.format("entry%d P3(target AW transaction)", entry),
        target_id,
        entry * 8 + 2
    )

    print_message(string.format(
        "Start AxiReorder.sv:%d AW entry%d unreachable witness (current GEN=%d, delayed GEN=%d)",
        line,
        entry,
        current_gen,
        delayed_gen
    ))

    local predecessor_1_entry, predecessor_2_entry =
        prepare_parameterized_aw_predecessors(
            entry,
            line,
            predecessor_1,
            predecessor_2
        )

    -- P1/P2 同 ID 且 P1 已下游完成，P2 nid=1 堵在 awq。此刻所有更低表项已
    -- 有效、目标 entry 为空，因此按最低空闲项规则，选择结果必然是当前 entry。
    assert_aw_selected_entry(entry, line, "before blocked P3 AW")
    assert_equal(
        core_signal("wvld_" .. entry):get(),
        0,
        string.format("AxiReorder.sv:%d target entry is still free", line)
    )

    -- 不可达的关键周期：P1 的合法 B 与 P3 AWVALID 同时驱动。因为 awq 队首
    -- P2 的 nid=1，awq_io_deq_ready=0，单深度 Queue 的 enq_ready 也为 0；
    -- 所以 P1 B 可以握手，P3 AWVALID 必须保持，io_mst_aw_ready 必须为 0。
    set_mst_aw(target, true)
    dut.io_mst_b_ready:set_imm(1)
    set_slv_b(predecessor_1_entry, 0, true)
    settle_combination()

    assert_aw_selected_entry(entry, line, "blocked P3 AW cycle")
    assert_equal(
        dut.io_mst_aw_ready:get(),
        0,
        string.format("AxiReorder.sv:%d P3 AWREADY blocked by awq depth=1", line)
    )
    assert_equal(
        dut.io_slv_b_ready:get(),
        1,
        string.format("AxiReorder.sv:%d P1 BREADY", line)
    )
    assert_equal(
        dut.io_mst_b_valid:get(),
        1,
        string.format("AxiReorder.sv:%d P1 BVALID", line)
    )
    assert_equal(
        dut.io_mst_b_bits_id:get(),
        target_id,
        string.format("AxiReorder.sv:%d P1 restored BID", line)
    )
    assert_equal(
        core.awq_io_deq_ready:get(),
        0,
        string.format("AxiReorder.sv:%d awq cannot dequeue P2 before B edge", line)
    )
    assert_equal(
        core["_awq_io_deq_bits_entry"]:get(),
        predecessor_2_entry,
        string.format("AxiReorder.sv:%d awq head is P2", line)
    )

    env.wait_cycles(1)
    finish_handshake_edge()
    clear_slv_b()
    wait_negedge()

    -- 时钟沿后 P1 已释放、P2 的 nid 才更新为 0；上一拍没有 AW fire，所以
    -- wWkVldReg 不会建立，目标表项仍未分配，目标减 2 分支没有执行条件。
    assert_equal(
        core_signal("wvld_" .. predecessor_1_entry):get(),
        0,
        string.format("AxiReorder.sv:%d P1 cleared after B", line)
    )
    assert_equal(
        core_signal("awinfo_" .. predecessor_2_entry .. "_nid"):get(),
        0,
        string.format("AxiReorder.sv:%d P2 nid becomes zero only after B edge", line)
    )
    assert_equal(
        core.wWkVldReg:get(),
        0,
        string.format("AxiReorder.sv:%d delayed AW correction was not recorded", line)
    )
    assert_equal(
        core_signal("wvld_" .. entry):get(),
        0,
        string.format("AxiReorder.sv:%d no P3 allocation occurred", line)
    )

    -- P3 VALID 按 AXI 规则保持不变。下一拍 P2 才能出队，并允许 Queue 在同一
    -- 沿接收 P3；此时 P1 已经不存在，P3 只能装载 nid=1，随后只能减 1。
    replace_awq_head_with_target(predecessor_2, predecessor_2_entry, target, line)
    assert_equal(
        core_signal("wvld_0"):get(),
        1,
        string.format("AxiReorder.sv:%d P3 uses newly freed lowest entry0", line)
    )
    assert_equal(
        core_signal("awinfo_0_nid"):get(),
        1,
        string.format("AxiReorder.sv:%d P3 rawWNid is only one", line)
    )
    assert_equal(
        core.wWkVldReg:get(),
        0,
        string.format("AxiReorder.sv:%d P3 did not create delayed correction", line)
    )

    accept_mst_w(target)
    accept_slv_w(predecessor_2)
    send_b_response(
        predecessor_2_entry,
        0,
        target_id,
        string.format("complete P2 before target AW entry%d", entry)
    )
    assert_equal(
        core_signal("awinfo_0_nid"):get(),
        0,
        string.format("AxiReorder.sv:%d P3 decremented by one after P2 B", line)
    )
    accept_slv_aw(target, 0)
    accept_slv_w(target)
    send_b_response(0, 0, target_id, string.format("complete P3 entry%d", entry))

    if entry >= 2 then
        -- 建立下一轮所需的连续占位布局；entry0/1 两项已经在本轮完全清空。
        local filler = install_persistent_aw_filler(entry, line)
        parameterized_write_state.pending[entry] = filler
        assert_write_occupancy(
            2,
            entry,
            string.format("after AW AxiReorder.sv:%d witness", line)
        )
    else
        assert_write_occupancy(
            nil,
            nil,
            string.format("after AW AxiReorder.sv:%d witness", line)
        )
    end

    parameterized_write_state.next_entry = entry + 1
    if entry == 63 then
        finish_parameterized_aw_entries()
    end
end

local function make_parameterized_aw_case(entry)
    local line = write_nid_minus_two_line(entry)
    return {
        line = line,
        current_gen = 143 + 2 * entry,
        delayed_gen = 144 + 2 * entry,
        run = function()
            cover_parameterized_write_nid_minus_two_unreachable(
                entry,
                line,
                143 + 2 * entry,
                144 + 2 * entry
            )
        end,
    }
end

local AW_NID_MINUS_TWO_CASES = {}
for entry = 0, 63 do
    table.insert(AW_NID_MINUS_TWO_CASES, make_parameterized_aw_case(entry))
end

-- ============================================================================
-- 6712 行 wWkEtrReg 条件更新的独立参数化覆盖
-- ============================================================================

local WWK_ENTRY_UPDATE_CASES = {
    {
        line = 6712,
        predecessor_entry = 0,
        target_entry = 1,
        expected_entry_one_hot = 0x2,
        id = 0xC00,
        serial = 0x500,
    },
}

local function cover_parameterized_wwk_entry_update(coverage_case)
    assert_equal(
        coverage_case.line,
        6712,
        "wWkEtrReg target RTL line"
    )
    assert_equal(
        coverage_case.predecessor_entry,
        0,
        "wWkEtrReg predecessor entry"
    )
    assert_equal(
        coverage_case.target_entry,
        1,
        "wWkEtrReg target entry"
    )
    assert_write_occupancy(
        nil,
        nil,
        string.format("before AxiReorder.sv:%d independent scenario", coverage_case.line)
    )

    local predecessor = make_write_transaction(
        "line6712 H1(completed write waiting for B)",
        coverage_case.id,
        coverage_case.serial
    )
    local target = make_write_transaction(
        "line6712 H2(new AW concurrent with H1 B)",
        coverage_case.id,
        coverage_case.serial + 1
    )

    print_message(string.format(
        "Start AxiReorder.sv:%d coverage: same-ID H1 B and H2 AW fire together",
        coverage_case.line
    ))

    -- H1 严格按 AW -> W、下游 AW -> 下游 W 的完整顺序发送。此时 Memory
    -- 已经具备返回 B 的条件，entry0 仍有效，而三个写请求队列均已排空。
    send_write_request(predecessor, coverage_case.predecessor_entry)
    assert_equal(
        core_signal("wvld_" .. coverage_case.predecessor_entry):get(),
        1,
        string.format("AxiReorder.sv:%d H1 wvld", coverage_case.line)
    )
    assert_equal(
        core_signal(
            "awinfo_" .. coverage_case.predecessor_entry .. "_nid"
        ):get(),
        0,
        string.format("AxiReorder.sv:%d H1 nid", coverage_case.line)
    )
    assert_equal(
        core_signal(
            "awinfo_" .. coverage_case.predecessor_entry .. "_haveSendAW"
        ):get(),
        1,
        string.format("AxiReorder.sv:%d H1 haveSendAW", coverage_case.line)
    )
    assert_equal(
        core_signal("_awq_io_deq_valid"):get(),
        0,
        string.format("AxiReorder.sv:%d awq is empty before concurrent edge", coverage_case.line)
    )

    -- 关键周期：H1 B 使用 entry0 的下游重映射 ID；DUT 将其恢复为原始 ID。
    -- 同拍 H2 提交相同 AWID，且 awq/wq 均有空间，因此 AW 和 B 都合法 fire。
    -- 沿前 H1 尚未清除，所以最低空闲项为 entry1，aw_mst_fire_hit_1 必须为 1。
    set_mst_aw(target, true)
    dut.io_mst_b_ready:set_imm(1)
    set_slv_b(coverage_case.predecessor_entry, 0, true)
    settle_combination()

    assert_equal(
        dut.io_mst_aw_ready:get(),
        1,
        string.format("AxiReorder.sv:%d H2 AWREADY", coverage_case.line)
    )
    assert_equal(
        dut.io_slv_b_ready:get(),
        1,
        string.format("AxiReorder.sv:%d H1 BREADY", coverage_case.line)
    )
    assert_equal(
        dut.io_mst_b_valid:get(),
        1,
        string.format("AxiReorder.sv:%d H1 BVALID", coverage_case.line)
    )
    assert_equal(
        dut.io_mst_b_bits_id:get(),
        coverage_case.id,
        string.format("AxiReorder.sv:%d H1 restored BID", coverage_case.line)
    )
    assert_equal(
        core_signal("aw_mst_fire_hit_" .. coverage_case.target_entry):get(),
        1,
        string.format("AxiReorder.sv:%d H2 allocation hit entry1", coverage_case.line)
    )

    env.wait_cycles(1)
    finish_handshake_edge()
    clear_mst_aw()
    clear_slv_b()
    wait_negedge()

    -- wWkVldReg 是关键周期 wWkVld 的寄存结果；wWkEtrReg 等于 entry1 的
    -- one-hot 值 0x2，直接证明 6712 行在刚才的上升沿执行并写入新值。
    assert_equal(
        core.wWkVldReg:get(),
        1,
        string.format("AxiReorder.sv:%d wWkVldReg", coverage_case.line)
    )
    assert_equal(
        core.wWkEtrReg:get(),
        coverage_case.expected_entry_one_hot,
        string.format("AxiReorder.sv:%d wWkEtrReg", coverage_case.line)
    )
    assert_equal(
        core_signal("wvld_" .. coverage_case.predecessor_entry):get(),
        0,
        string.format("AxiReorder.sv:%d H1 cleared after B", coverage_case.line)
    )
    assert_equal(
        core_signal("wvld_" .. coverage_case.target_entry):get(),
        1,
        string.format("AxiReorder.sv:%d H2 allocated", coverage_case.line)
    )
    assert_equal(
        core_signal("awinfo_" .. coverage_case.target_entry .. "_nid"):get(),
        1,
        string.format("AxiReorder.sv:%d H2 initial nid", coverage_case.line)
    )

    -- 下一拍没有新的 B/AW；上一拍记录的 wWkEtrReg[1] 对 H2 做一次延迟
    -- 修正，将分配时多统计但已经同拍完成的 H1 从 nid 中扣除，1 -> 0。
    env.wait_cycles(1)
    finish_handshake_edge()
    wait_negedge()
    assert_equal(
        core_signal("awinfo_" .. coverage_case.target_entry .. "_nid"):get(),
        0,
        string.format("AxiReorder.sv:%d H2 delayed nid correction", coverage_case.line)
    )

    -- H2 的 AW 已在关键周期进入 awq。AXI W 通道独立，允许在之后提交 W；
    -- 这里再依次完成上游 W、下游 AW/W，最后才返回唯一一次合法 B。
    accept_mst_w(target)
    accept_slv_aw(target, coverage_case.target_entry)
    accept_slv_w(target)
    send_b_response(
        coverage_case.target_entry,
        0,
        coverage_case.id,
        "complete line6712 H2"
    )

    assert_write_occupancy(
        nil,
        nil,
        string.format("after AxiReorder.sv:%d independent scenario", coverage_case.line)
    )
    print_message(string.format(
        "Covered AxiReorder.sv:%d; wWkEtrReg updated to 0x%x",
        coverage_case.line,
        coverage_case.expected_entry_one_hot
    ))
end

local function make_parameterized_read_case(entry)
    local line = read_nid_minus_two_line(entry)
    return {
        line = line,
        run = function()
            cover_parameterized_read_nid_minus_two(entry, line)
        end,
    }
end

local LINE_COVERAGE_CASES = {}
for entry = 0, 63 do
    table.insert(LINE_COVERAGE_CASES, make_parameterized_read_case(entry))
end

local function task_line_coverage()
    -- 不启动随机 AXI agent，由 testcase 精确控制端口。下游 AR/AW/W READY
    -- 默认拉低，仅在对应 helper 中允许握手；上游始终接收 R/B。
    driver.drive {
        io_slv_ar_ready = 0,
        io_mst_r_ready = 1,
        io_slv_aw_ready = 0,
        io_slv_w_ready = 0,
        io_mst_b_ready = 1,
    }

    wait_negedge()

    for _, coverage_case in ipairs(LINE_COVERAGE_CASES) do
        coverage_case.run()
    end

    for _, coverage_case in ipairs(AW_NID_MINUS_TWO_CASES) do
        coverage_case.run()
    end

    for _, coverage_case in ipairs(WWK_ENTRY_UPDATE_CASES) do
        cover_parameterized_wwk_entry_update(coverage_case)
    end

    dut.io_mst_r_ready:set_imm(0)
    dut.io_mst_b_ready:set_imm(0)
    set_slv_ar_ready(0)
    dut.io_slv_aw_ready:set_imm(0)
    dut.io_slv_w_ready:set_imm(0)
    clear_mst_ar()
    clear_slv_r()
    clear_mst_aw()
    clear_mst_w()
    clear_slv_b()
    env.wait_cycles(1)

    print_message(string.format(
        "012 line coverage testcase completed successfully; covered %d read line(s), verified %d unreachable AW line(s), covered %d wWkEtrReg line scenario(s)",
        #LINE_COVERAGE_CASES,
        #AW_NID_MINUS_TWO_CASES,
        #WWK_ENTRY_UPDATE_CASES
    ))
end

return {
    tasks = {
        task_line_coverage,
    },
}
