local env = require "env"
local driver = require "dut.driver"
local signals = require "dut.signals"

--[[
实现方法
========

本用例覆盖两处定向 condition 组合。

一、覆盖 AxiReorder.sv:1736 缺失的 condition 组合：
--
--   rvld_63 & ~(|arinfo_63_nid) & ~arinfo_63_haveSendAR
--      0               1                    1
--
-- rvld 在 reset 时清零，但 arinfo 的 nid 和 haveSendAR 没有 reset 初值。
-- 因此仅在用例开始时等待复位，nid/haveSendAR 仍可能为 X，不能稳定
-- 产生覆盖工具要求的 (0,1,1)。测试分三个阶段构造确定状态：
--
-- 1. 保持下游 ARREADY=0，依次发送 64 笔不同 ID 的单拍读请求，使它们
--    分别占用 entry0..63。不同 ID 保证 entry63.nid=0；下游不接收 AR
--    保证 entry63.haveSendAR=0。此时 entry63 三项为 (1,1,1)。
--
-- 2. 再次断言 reset。DUT 将 rvld_63 清为 0，而已经通过合法 AR 握手写入的
--    nid=0 和 haveSendAR=0 保持不变。复位期间公共 scoreboard 也会清除
--    这 64 笔被 reset 取消的请求，不会留下悬空事务。
--
-- 3. 释放 reset 后保持一个完整的非复位周期，并直接检查 entry63 的
--    valid/nid/haveSendAR 为 0/0/0。对应取反后，第 1736 行便稳定取得
--    缺失的 (0,1,1) condition 组合。
--
-- 二、覆盖 AxiReorder.sv:1931 缺失的 condition 组合：
--
--   wq_io_enq_valid & _awsel_T_1[63] & _awsel_res_bits_T_1[63]
--          1                  0                     1
--
-- 生成 RTL 中选择器各项的来源是：
--   _awsel_T_1            = ~wvld
--   _awsel_res_bits_T_1   = wvld + 1
--
-- 测试分四个阶段构造该组合：
--
-- 1. 依次发送 64 笔不同 ID 的单拍写事务，使其分别占用 entry0..63。每笔
--    事务都完成上游 AW/W 和下游 AW/W 握手，但暂不返回 B。这样既不会堵塞
--    awq、wq、wbitsq，又能让全部 wvld 保持为 1。
--
-- 2. 合法返回 entry0 对应事务的 B。该事务的下游 AW/W 已在此前完成，因此
--    B 响应满足 AXI 时序。B 握手后只有 entry0 被释放，得到：
--
--        wvld = 64'hffff_ffff_ffff_fffe
--
-- 3. 保持 entry1..63 占用并发送一笔新 AW。最低空闲项选择器把它分配到
--    entry0；在 AW 握手所在周期：
--
--      * AWVALID=1 且 AWREADY=1，所以 wq_io_enq_valid=1；
--      * wvld[63]=1，所以 (~wvld)[63]=_awsel_T_1[63]=0；
--      * wvld 的 bit0 为 0，加 1 只把 bit0 置 1，不会改变 bit63，所以
--        (wvld+1)[63]=_awsel_res_bits_T_1[63]=1。
--
--    因此第 1931 行在该周期准确取得缺失的 (1,0,1) condition 组合。用例还
--    检查 entry0.alloc_hit=1、entry63.alloc_hit=0 和完整的 wvld 布局，防止
--    因时序或队列状态不同而误以为已经命中目标场景。
--
-- 4. 完成新事务的下游 AW/W 后返回其 B，再依次返回 entry1..63 的 B，确保
--    DUT 和公共 scoreboard 最终都没有悬空事务。
--
-- 整个过程仅通过合法 AXI valid/ready 握手和 AXI reset 推进，不
-- force/deposit DUT 内部信号，因此 condition 覆盖来自真实可达状态。
--]]

local clock = dut.clock:chdl()
local TIMEOUT = 200
local LAST_ENTRY = 63

local function error_message(message)
    return "\n\n---ERROR---\n\n" .. message .. "\n\n-----------\n\n"
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

local function settle_combination()
    await_rd()
end

local function finish_handshake_edge()
    await_rw()
end

local function wait_until_observed(predicate, description)
    for _ = 1, TIMEOUT do
        if predicate() then
            return
        end
        wait_negedge()
    end

    assert(false, error_message("timeout waiting for " .. description))
end

local function make_transaction(entry)
    return {
        name = string.format("condition coverage initial entry%d", entry),
        id = 0x200 + entry,
        addr = 0x40000 + entry * 0x20,
        data = 0x5000 + entry,
    }
end

local replacement = {
    name = "condition coverage replacement entry0",
    id = 0x3FF,
    addr = 0x50000,
    data = 0x6000,
}

local initial_transactions = {}
for entry = 0, LAST_ENTRY do
    initial_transactions[entry] = make_transaction(entry)
end

local read_transactions = {}
for entry = 0, LAST_ENTRY do
    read_transactions[entry] = {
        name = string.format("condition coverage read entry%d", entry),
        id = 0x100 + entry,
        addr = 0x20000 + entry * 0x20,
    }
end

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

local function set_slv_b(entry, valid)
    dut.io_slv_b_valid:set_imm(valid and 1 or 0)
    dut.io_slv_b_bits_id:set_imm(entry)
    dut.io_slv_b_bits_resp:set_imm(0)
end

local function clear_slv_b()
    dut.io_slv_b_valid:set_imm(0)
    dut.io_slv_b_bits_id:set_imm(0)
    dut.io_slv_b_bits_resp:set_imm(0)
end

local function assert_entry_valid(entry, expected, description)
    assert_equal(
        signals.dbg_aw.entries[entry].valid:get(),
        expected,
        description or string.format("entry%d valid", entry)
    )
end

local function assert_ar_entry(entry, expected_valid, description)
    local actual = signals.dbg_ar.entries[entry]

    assert_equal(actual.valid:get(), expected_valid, description .. " valid")
    assert_equal(actual.nid:get(), 0, description .. " nid")
    assert_equal(actual.have_sent:get(), 0, description .. " haveSendAR")
end

local function accept_mst_ar(transaction, expected_entry)
    local expected_signals = signals.dbg_ar.entries[expected_entry]

    set_mst_ar(transaction, true)
    settle_combination()
    wait_until_observed(function()
        return dut.io_mst_ar_ready:get() == 1
    end, transaction.name .. " upstream ARREADY")

    assert_equal(
        expected_signals.alloc_hit:get(),
        1,
        transaction.name .. " selected read entry"
    )

    env.wait_cycles(1)
    finish_handshake_edge()
    clear_mst_ar()
    wait_negedge()

    assert_ar_entry(expected_entry, 1, transaction.name)
    assert_equal(
        expected_signals.id:get(),
        transaction.id,
        transaction.name .. " saved original ARID"
    )
end

local function cover_ar_should_send_63_invalid_condition()
    -- 下游不接收 AR，确保填表期间所有 haveSendAR 保持为 0。
    driver.drive {
        io_slv_ar_ready = 0,
        io_mst_r_ready = 0,
    }
    wait_negedge()

    for entry = 0, LAST_ENTRY do
        accept_mst_ar(read_transactions[entry], entry)
    end

    assert_equal(dut.io_mst_ar_ready:get(), 0, "ARREADY while all entries are occupied")
    for entry = 0, LAST_ENTRY do
        assert_ar_entry(entry, 1, string.format("full read-table entry%d", entry))
    end

    -- reset 只清除 rvld；entry63 先前写入的 nid=0/haveSendAR=0 保持。
    -- scoreboard 在 reset 采样时同步清空，因此填表事务被合法取消。
    clear_mst_ar()
    env.dut_reset()
    finish_handshake_edge()
    wait_negedge()

    assert_equal(signals.reset:get(), 0, "reset released for line 1736 condition")
    assert_ar_entry(63, 0, "AxiReorder.sv:1736 condition entry63")

    -- 保持目标值跨过一个完整非复位时钟沿，让 condition 覆盖器采样。
    env.wait_cycles(1)
    finish_handshake_edge()
    wait_negedge()
    assert_ar_entry(63, 0, "AxiReorder.sv:1736 sampled condition entry63")

    print(
        "Covered AxiReorder.sv:1736 condition row " ..
        "rvld_63/~(|arinfo_63_nid)/~arinfo_63_haveSendAR = 0/1/1"
    )
end

local function accept_mst_aw(transaction, expected_entry, is_target)
    local expected_signals = signals.dbg_aw.entries[expected_entry]

    set_mst_aw(transaction, true)
    settle_combination()
    wait_until_observed(function()
        return dut.io_mst_aw_ready:get() == 1
    end, transaction.name .. " upstream AWREADY")

    assert_equal(
        expected_signals.alloc_hit:get(),
        1,
        transaction.name .. " selected write entry"
    )

    if is_target then
        -- wq_io_enq_valid is io_mst_aw_valid && io_mst_aw_ready.
        assert_equal(dut.io_mst_aw_valid:get(), 1, "condition term 1 AWVALID")
        assert_equal(dut.io_mst_aw_ready:get(), 1, "condition term 1 AWREADY")

        -- entry63 occupied => (~wvld)[63] == 0.
        assert_entry_valid(63, 1, "condition term 2 requires wvld_63=1")
        assert_equal(
            signals.dbg_aw.entries[63].alloc_hit:get(),
            0,
            "AxiReorder.sv:1931 aw_mst_fire_hit_63"
        )

        -- entry0 is the only free entry.  Adding one to ...fffe only sets bit0,
        -- so bit63 stays 1 in wvld + 1.
        assert_entry_valid(0, 0, "condition term 3 requires entry0 free")
        for entry = 1, LAST_ENTRY do
            assert_entry_valid(
                entry,
                1,
                string.format("condition layout entry%d occupied", entry)
            )
        end
    end

    env.wait_cycles(1)
    finish_handshake_edge()
    clear_mst_aw()
    wait_negedge()

    assert_entry_valid(expected_entry, 1, transaction.name .. " valid after AW")
    assert_equal(
        expected_signals.id:get(),
        transaction.id,
        transaction.name .. " saved original AWID"
    )
    assert_equal(expected_signals.nid:get(), 0, transaction.name .. " saved nid")
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

local function accept_slv_aw(transaction, expected_entry)
    wait_until_observed(function()
        return dut.io_slv_aw_valid:get() == 1
    end, transaction.name .. " downstream AWVALID")

    assert_equal(
        dut.io_slv_aw_bits_id:get(),
        expected_entry,
        transaction.name .. " remapped AWID"
    )
    assert_equal(
        dut.io_slv_aw_bits_addr:get(),
        transaction.addr,
        transaction.name .. " downstream AWADDR"
    )

    dut.io_slv_aw_ready:set_imm(1)
    settle_combination()
    env.wait_cycles(1)
    finish_handshake_edge()
    dut.io_slv_aw_ready:set_imm(0)
    wait_negedge()

    assert_equal(
        signals.dbg_aw.entries[expected_entry].have_sent:get(),
        1,
        transaction.name .. " haveSendAW"
    )
end

local function accept_slv_w(transaction)
    wait_until_observed(function()
        return dut.io_slv_w_valid:get() == 1
    end, transaction.name .. " downstream WVALID")

    local actual_data = dut.io_slv_w_bits_data:get_hex_str():lower():gsub("^0+", "")
    assert_equal(actual_data, string.format("%x", transaction.data), transaction.name .. " WDATA")
    assert_equal(dut.io_slv_w_bits_strb:get(), 0xFFFFFFFF, transaction.name .. " WSTRB")
    assert_equal(dut.io_slv_w_bits_last:get(), 1, transaction.name .. " WLAST")

    dut.io_slv_w_ready:set_imm(1)
    settle_combination()
    env.wait_cycles(1)
    finish_handshake_edge()
    dut.io_slv_w_ready:set_imm(0)
    wait_negedge()
end

local function allocate_and_hold_write(transaction, expected_entry, is_target)
    accept_mst_aw(transaction, expected_entry, is_target)
    accept_mst_w(transaction)
    accept_slv_aw(transaction, expected_entry)
    accept_slv_w(transaction)

    assert_entry_valid(
        expected_entry,
        1,
        transaction.name .. " remains occupied before B"
    )
end

local function send_b_response(transaction, entry)
    set_slv_b(entry, true)
    settle_combination()
    wait_until_observed(function()
        return dut.io_slv_b_ready:get() == 1 and dut.io_mst_b_valid:get() == 1
    end, transaction.name .. " B handshake")

    assert_equal(dut.io_mst_b_bits_id:get(), transaction.id, transaction.name .. " restored BID")
    assert_equal(dut.io_mst_b_bits_resp:get(), 0, transaction.name .. " BRESP")

    env.wait_cycles(1)
    finish_handshake_edge()
    clear_slv_b()
    wait_negedge()

    assert_entry_valid(entry, 0, transaction.name .. " released after B")
end

local function assert_all_entries(expected, description)
    for entry = 0, LAST_ENTRY do
        assert_entry_valid(
            entry,
            expected,
            string.format("%s entry%d", description, entry)
        )
    end
end

local function task_condition_coverage()
    cover_ar_should_send_63_invalid_condition()

    -- Use direct, deterministic channel driving.  Each retained entry has
    -- already completed downstream AW and W before its B is delayed.
    driver.drive {
        io_slv_ar_ready = 0,
        io_mst_r_ready = 0,
        io_slv_aw_ready = 0,
        io_slv_w_ready = 0,
        io_mst_b_ready = 1,
    }
    wait_negedge()

    for entry = 0, LAST_ENTRY do
        allocate_and_hold_write(initial_transactions[entry], entry, false)
    end
    assert_all_entries(1, "full-table layout")
    assert_equal(dut.io_mst_aw_ready:get(), 0, "AWREADY while all entries are occupied")

    -- Leave entry63 occupied but create a lower free entry.
    send_b_response(initial_transactions[0], 0)
    assert_entry_valid(0, 0, "entry0 free before target AW")
    for entry = 1, LAST_ENTRY do
        assert_entry_valid(entry, 1, string.format("entry%d retained before target AW", entry))
    end

    -- This AW handshake records the missing (1,0,1) condition combination at
    -- AxiReorder.sv:1931 while allocating the transaction to entry0.
    allocate_and_hold_write(replacement, 0, true)

    send_b_response(replacement, 0)
    for entry = 1, LAST_ENTRY do
        send_b_response(initial_transactions[entry], entry)
    end
    assert_all_entries(0, "final cleanup")

    dut.io_mst_b_ready:set_imm(0)
    dut.io_slv_aw_ready:set_imm(0)
    dut.io_slv_w_ready:set_imm(0)
    clear_mst_aw()
    clear_mst_w()
    clear_slv_b()
    env.wait_cycles(1)

    print(
        "Covered AxiReorder.sv:1931 condition row " ..
        "wq_io_enq_valid/_awsel_T_1[63]/_awsel_res_bits_T_1[63] = 1/0/1"
    )
end

return {
    tasks = {
        task_condition_coverage,
    },
}
