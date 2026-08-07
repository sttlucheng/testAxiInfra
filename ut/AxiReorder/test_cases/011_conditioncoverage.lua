local env = require "env"
local driver = require "dut.driver"
local signals = require "dut.signals"

--[[
实现方法
========

本用例覆盖十三类定向 condition 组合。

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
-- 4. 该方法同时可以同时解决覆盖 0-62 缺失的 condition 组合：
--      rvld_62 & ~(|arinfo_62_nid) & ~arinfo_62_haveSendAR
--        0               1                    1
--        .               .                    .
--        .               .                    .
--        .               .                    .
--        .               .                    .
--        .               .                    .
--      rvld_0 & ~(|arinfo_0_nid) & ~arinfo_0_haveSendAR
--        0               1                    1
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
-- 三、覆盖 AxiReorder.sv:41700 缺失的 condition 组合：
--
--   io_mst_aw_valid & awsel_valid & _wq_io_enq_ready
--          1                0                1
--
-- 该组合直接复用第 1931 行场景中“64 个写 entry 全部占用”的时刻：
--
-- 1. wvld[63:0] 全为 1，没有可分配的写 entry，因此 awsel_valid=0。
--
-- 2. 填表时每笔事务都已完成上游 W 握手，wq 中对应的 entry 已经出队；
--    所以写表虽然已满，_wq_io_enq_ready 仍然为 1。
--
-- 3. 在释放任何 entry 之前额外拉高一拍 io_mst_aw_valid。由于
--    awsel_valid=0，该 AW 不会握手或写入 awq/wq，但第 41700 行的三个
--    condition 项会稳定取得 (1,0,1)。用例直接检查内部 awsel_valid
--    和 _wq_io_enq_ready，并在撤销 AWVALID 后确认 64 个 entry 仍全部占用。
--
-- 四、覆盖 AxiReorder.sv:1476 缺失的 condition 组合：
--
--   arsel_valid & io_mst_ar_valid
--        0               1
--
-- 该组合复用第 1736 行场景中“64 个读 entry 全部占用”的时刻：
--
-- 1. rvld[63:0] 全为 1，没有可分配的读 entry，因此 arsel_valid=0，
--    io_mst_ar_ready 也为 0。
--
-- 2. 在执行中途 reset 前额外拉高一拍 io_mst_ar_valid。由于 ARREADY=0，
--    该请求不会握手或改变任何 entry，但第 1476 行会稳定取得缺失的
--    (0,1)。撤销 ARVALID 后再次检查整张读表，然后继续 reset 流程覆盖
--    第 1736 行。
--
-- 五、统一覆盖 AxiReorder.sv:41111..41552 的 AW nid 递减条件。
--
-- 这 64 个条件由 Chisel 对 awinfo[0]..awinfo[63] 展开生成，行号每次递增 7：
--
--   (|awinfo_i_nid) & b_fire & (restored_bid == awinfo_i_id) & wvld_i
--
-- 覆盖报告统一缺少两组：
--
--       nid_nonzero  b_fire  id_match  valid
--           1           1        0        1
--           1           1        1        0
--
-- 用例对每个 target entry 执行同一个参数化流程：
--
-- 1. 用不同 ID 占用 entry0..max(target,2)，完成它们的上下游 AW/W，
--    但保留 B。至少三个表项可以为 target 提供一个同 ID helper 和一个
--    不同 ID mismatch B。
--
-- 2. 返回 target 原事务的 B 以释放该表项，然后在同一个 entry 重新分配
--    一笔与 helper 同 ID 的 AW。此时 helper 仍未返回 B，所以 target 被
--    DUT 自然计算为 nid=1、valid=1，无需改写任何内部寄存器。
--
-- 3. 返回 mismatch entry 的 B。该 B 的恢复 ID 与 target 不同，因此在
--    B 握手时 target 条件取得 (1,1,0,1)，且 target.nid 保持为 1。
--
-- 4. 保持 helper BVALID 和上游 BREADY，同时断言异步 reset。reset 先将
--    target.wvld 清零，但 awinfo 中的 id/nid 保持；在下一个时钟沿，
--    该分支被求值为 (1,1,1,0)。由于 valid=0，nid 不会误递减；monitor
--    和 scoreboard 在 reset 期间忽略 B 并清除未完成事务。
--
-- 循环遍历 0..63，因此不仅覆盖第 41111 行，也同时覆盖第 41118 行
-- 以及后续所有同构分支。
--
-- 六、统一覆盖 AxiReorder.sv:39968..41102 的 AR nid 递减条件。
--
-- 这 64 个条件由 arinfo[0]..arinfo[63] 展开生成，行号每次递增 18：
--
--   (|arinfo_i_nid) & r_fire & (restored_rid == arinfo_i_id) & rvld_i & RLAST
--
-- 覆盖报告统一缺少：
--
--       nid_nonzero  r_fire  id_match  valid  RLAST
--           1           1        0        1      1
--           1           1        1        0      1
--
-- 测试流程与 AW nid 分支相同：每个 target 用同 ID helper 构造 nid=1，
-- 用不同 ID 的 R 握手覆盖 id_match=0；再保持匹配 helper R 并断言异步
-- reset，在下一个时钟沿用 rvld=0 覆盖 id_match=1/valid=0。循环 target=0..63
-- 后，39968 行和 39986 行以及后续所有同构 AR 分支都会被覆盖。
--
-- 七、覆盖 AxiReorder.sv:41756 缺失的 condition 组合：
--
--   _GEN_132 & io_slv_w_ready
--       0              1
--
-- _GEN_132 是 wbitsq 队首写数据对应 entry 的 haveSendAW。测试复用最终填充
-- 写表的第一笔事务，并按以下顺序构造该组合：
--
-- 1. 先完成上游 AW 和 W 握手，但保持下游 AWREADY=0。AW 已为事务分配 entry，
--    W 也已进入 wbitsq；由于下游 AW 尚未握手，该 entry 的 haveSendAW=0，
--    因此 _GEN_132=0。
--
-- 2. 单独把下游 WREADY 拉高并保持一个完整周期。此时第 41756 行稳定取得
--    (0,1)；同时 io_slv_w_valid 被同一个 haveSendAW 条件门控为 0，所以不会
--    产生下游 W 握手，wbitsq 队首也不会被错误弹出。
--
-- 3. 撤销 WREADY 后恢复原流程，依次完成该事务的下游 AW、W 和最终 B。
--    AXI 的 AW/W 通道彼此独立，接收端允许提前声明 WREADY；并且该周期没有
--    WVALID/WREADY 握手，因此这是合法且不会产生额外事务的覆盖场景。
--
-- 八、覆盖 AxiReorder.sv:1900 缺失的 condition 组合：
--
--   _awinfo_63_nid_done_T_126 & (io_slv_b_bits_id[5:0] == 6'h2f)
--              0                              1
--
-- 复用 64 个写 entry 都已完成下游 AW/W、但尚未返回 B 的状态。将
-- io_mst_b_ready 置 0、io_slv_b_valid 置 1，并驱动下游 entry47 的 B ID（6'h2f）：
-- 第一项 _awinfo_63_nid_done_T_126 = io_mst_b_ready & io_slv_b_valid 为 0，
-- 第二项 ID 比较为 1。保持 BVALID 和 ID 一个完整周期后拉高 BREADY，完成
-- entry47 的真实 B 握手，再撤销 BVALID。最后发一笔新事务重新占用 entry47，
-- 恢复满表布局，避免影响后续第 1931 行的既有覆盖场景。
--
-- 九、覆盖 AxiReorder.sv:1906 缺失的 condition 组合：
--
--   _awinfo_63_nid_done_T_126 & (io_slv_b_bits_id[5:0] == 6'h32)
--              0                              1
--
-- 复用第 1900 行的合法 B 响应流程，但目标改为 entry50：先以 BREADY=0 保持
-- BVALID=1、BID=6'h32 一个完整周期，得到 (0,1)；再保持 BID 不变并拉高
-- BREADY 完成 B 握手。最后用新事务重新占用 entry50，恢复 64 项满表状态。
--
-- 十、覆盖 AxiReorder.sv:1926 缺失的 condition 组合：
--
--   _awinfo_63_nid_done_T_126 & (io_slv_b_bits_id[5:0] == 6'h3c)
--              0                              1
--
-- 继续复用相同的合法 B 响应流程，目标改为 entry60：BREADY=0 时保持
-- BVALID=1、BID=6'h3c 一个完整周期，覆盖 (0,1)；随后保持 payload 不变并
-- 拉高 BREADY 完成握手，最后用新事务重新占用 entry60，恢复满表状态。
--
-- 十一、覆盖 RRArbiter64_UInt0.sv:136 缺失的子条件组合：
--
--   io_in_63_valid & (ctrl_validMask_grantMask_lastGrant != 6'h3f)
--          1                              0
--
-- 1. reset 后 lastGrant=0。保持下游 ARREADY=0，以 64 个不同 ID 的上游 AR
--    填满 entry0..63，使所有 entry 的 nid=0、haveSendAR=0。
--
-- 2. 依次允许 entry1..63 完成下游 AR 握手。entry63 握手后 lastGrant=63，
--    但它的 haveSendAR=1，所以此时 io_in_63_valid=0。
--
-- 3. 合法返回 entry63 的单拍 R，将 entry63 释放；保持下游 ARREADY=0，再发送
--    一笔不同 ID 的新 AR。由于 entry0..62 仍占用，新请求只能分配到 entry63。
--    新 entry63 的 valid/nid/haveSendAR=1/0/0，所以 io_in_63_valid=1；同时没有
--    新的下游 AR 握手，lastGrant 仍为63，稳定得到缺失的 (1,0)。
--
-- 4. 覆盖采样后继续完成 entry0 和新 entry63 的下游 AR，再返回全部剩余 R，
--    使所有读事务正常结束，不依赖 force/deposit 或 reset 取消事务。
--
-- 整个过程仅通过合法 AXI valid/ready 握手和 AXI reset 推进，不
-- force/deposit DUT 内部信号，因此 condition 覆盖来自真实可达状态。
--
-- 十二、覆盖 RRArbiter64_UInt0.sv:137 缺失的子条件组合：
--
--   io_in_62_valid & (ctrl_validMask_grantMask_lastGrant[5:1] != 5'h1f)
--          1                                      0
--
-- 1. 上一个场景的事务全部正常返回 R 后，对空闲 DUT 执行 reset，使 lastGrant=0；
--    再填满 64 个不同 ID 的读 entry，并依次允许 entry1..62 完成下游 AR。
--    entry62 的 AR 握手将 lastGrant 更新为 62，此时 entry62 已不再请求。
-- 2. 返回 entry62 的单拍 R 释放表项，再发送一笔不同 ID 的新 AR，使其重新
--    分配到 entry62；下游 ARREADY 保持为 0，因此 entry62 保持
--    valid=1、nid=0、haveSendAR=0，io_in_62_valid=1，而 lastGrant[5:1]
--    仍为 5'h1f，稳定得到缺失的 (1,0)。
-- 3. 覆盖采样后，依次完成原 entry63、entry0 和新 entry62 的下游 AR，随后
--    返回全部剩余 R。reset 只用于场景开始前初始化空闲仲裁器，不取消任何
--    未完成事务。
--
-- 十三、覆盖 FastQueue_1.sv:72 缺失的子条件组合：
--
--   io_deq_ready & _driver_io_deq_valid
--         1                  0
--
-- FastQueue_1 是 AxiReorder 内保存写数据的 wbitsq。该组合复用最终填表时的
-- 第一笔合法写事务：
--
-- 1. 正常完成该事务的上游 AW/W 和下游 AW/W 握手。下游 W 握手后，wbitsq
--    的 driver 已经出队并变空，因此 _driver_io_deq_valid=0；但尚未返回 B，
--    对应写 entry 仍有效且 haveSendAW=1。
--
-- 2. FastQueue 的出队 payload 寄存器在空队列时保留刚出队的 entry 编号，
--    因而 AxiReorder 的 _GEN_132 仍读取到该 entry 的 haveSendAW=1。此时单独
--    拉高下游 io_slv_w_ready，使 FastQueue 的
--
--      io_deq_ready = _GEN_132 & io_slv_w_ready = 1
--
--    同时 driver 仍为空，稳定得到缺失的 (1,0)。因为 io_slv_w_valid=0，
--    该周期不会产生额外 W 握手。
--
-- 3. 保持目标组合跨过完整时钟沿后撤销 WREADY。该事务继续由原流程保留，
--    最终通过正常 B 响应结束；整个过程不使用 force/deposit 或 reset 清理。
--
--]]

local clock = dut.clock:chdl()
local core = dut.u_AxiReorder
local arsel_valid = core.arsel_valid:chdl()
local awsel_valid = core.awsel_valid:chdl()
local wq_enq_ready = core["_wq_io_enq_ready"]:chdl()
local wbitsq_deq_valid = core["_wbitsq_io_deq_valid"]:chdl()
local wbitsq_deq_entry = core["_wbitsq_io_deq_bits_entry"]:chdl()
local wbitsq_deq_entry_have_sent_aw = core["_GEN_132"]:chdl()
local wbitsq_fastqueue = core.wbitsq
local wbitsq_io_deq_ready = wbitsq_fastqueue.io_deq_ready:chdl()
local wbitsq_driver_deq_valid = wbitsq_fastqueue["_driver_io_deq_valid"]:chdl()
local awinfo_63_nid_done = core["_awinfo_63_nid_done_T_126"]:chdl()
local aw_b_id_2f_condition = core["_GEN_113"]:chdl()
local aw_b_id_32_condition = core["_GEN_116"]:chdl()
local aw_b_id_3c_condition = core["_GEN_126"]:chdl()
local ar_rr_arbiter = core.selSendAR_arb
local ar_rr_input_62_valid = ar_rr_arbiter.io_in_62_valid:chdl()
local ar_rr_input_63_valid = ar_rr_arbiter.io_in_63_valid:chdl()
local ar_rr_last_grant = ar_rr_arbiter.ctrl_validMask_grantMask_lastGrant:chdl()
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

local line1900_replacement = {
    name = "condition coverage line1900 replacement entry47",
    id = 0x4F0,
    addr = 0x58000,
    data = 0x6200,
}

local line1906_replacement = {
    name = "condition coverage line1906 replacement entry50",
    id = 0x4F1,
    addr = 0x58020,
    data = 0x6201,
}

local line1926_replacement = {
    name = "condition coverage line1926 replacement entry60",
    id = 0x4F2,
    addr = 0x58040,
    data = 0x6202,
}

local b_condition_replacements = {
    [47] = line1900_replacement,
    [50] = line1906_replacement,
    [60] = line1926_replacement,
}

local blocked_when_full = {
    name = "condition coverage AW blocked by full write table",
    id = 0x400,
    addr = 0x60000,
    data = 0,
}

local blocked_read_when_full = {
    name = "condition coverage AR blocked by full read table",
    id = 0x180,
    addr = 0x30000,
}

local rr_line136_replacement = {
    name = "RRArbiter line136 replacement entry63",
    id = 0x181,
    addr = 0x31000,
}

local rr_line137_replacement = {
    name = "RRArbiter line137 replacement entry62",
    id = 0x182,
    addr = 0x31020,
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

local function set_slv_r(entry, valid)
    dut.io_slv_r_valid:set_imm(valid and 1 or 0)
    dut.io_slv_r_bits_id:set_imm(entry)
    dut.io_slv_r_bits_data:set_imm(0)
    dut.io_slv_r_bits_resp:set_imm(0)
    dut.io_slv_r_bits_last:set_imm(valid and 1 or 0)
end

local function clear_slv_r()
    dut.io_slv_r_valid:set_imm(0)
    dut.io_slv_r_bits_id:set_imm(0)
    dut.io_slv_r_bits_data:set_imm(0)
    dut.io_slv_r_bits_resp:set_imm(0)
    dut.io_slv_r_bits_last:set_imm(0)
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

local function accept_mst_ar(transaction, expected_entry, expected_nid)
    local expected_signals = signals.dbg_ar.entries[expected_entry]
    expected_nid = expected_nid or 0

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

    assert_equal(
        expected_signals.valid:get(),
        1,
        transaction.name .. " valid"
    )
    assert_equal(
        expected_signals.nid:get(),
        expected_nid,
        transaction.name .. " saved nid"
    )
    assert_equal(
        expected_signals.have_sent:get(),
        0,
        transaction.name .. " haveSendAR"
    )
    assert_equal(
        expected_signals.id:get(),
        transaction.id,
        transaction.name .. " saved original ARID"
    )
end

local function accept_slv_ar(transaction, expected_entry)
    wait_until_observed(function()
        return dut.io_slv_ar_valid:get() == 1
    end, transaction.name .. " downstream ARVALID")

    assert_equal(
        dut.io_slv_ar_bits_id:get(),
        expected_entry,
        transaction.name .. " remapped ARID"
    )
    assert_equal(
        dut.io_slv_ar_bits_addr:get(),
        transaction.addr,
        transaction.name .. " downstream ARADDR"
    )

    dut.io_slv_ar_ready:set_imm(1)
    settle_combination()
    env.wait_cycles(1)
    finish_handshake_edge()
    dut.io_slv_ar_ready:set_imm(0)
    wait_negedge()

    assert_equal(
        signals.dbg_ar.entries[expected_entry].have_sent:get(),
        1,
        transaction.name .. " haveSendAR"
    )
end

local function allocate_and_hold_read(transaction, expected_entry, expected_nid)
    accept_mst_ar(transaction, expected_entry, expected_nid)
    accept_slv_ar(transaction, expected_entry)

    assert_equal(
        signals.dbg_ar.entries[expected_entry].valid:get(),
        1,
        transaction.name .. " remains occupied before R"
    )
end

local function cover_ar_mst_fire_full_table_condition()
    assert_equal(arsel_valid:get(), 0, "condition term 1 arsel_valid with full table")
    assert_equal(dut.io_mst_ar_ready:get(), 0, "ARREADY while read table is full")

    set_mst_ar(blocked_read_when_full, true)
    settle_combination()

    assert_equal(arsel_valid:get(), 0, "AxiReorder.sv:1476 arsel_valid")
    assert_equal(dut.io_mst_ar_valid:get(), 1, "AxiReorder.sv:1476 io_mst_ar_valid")
    assert_equal(dut.io_mst_ar_ready:get(), 0, "target AR remains blocked")

    -- 跨过一个时钟沿保持 0/1；ARREADY=0 保证不会产生握手。
    env.wait_cycles(1)
    finish_handshake_edge()
    clear_mst_ar()
    wait_negedge()

    for entry = 0, LAST_ENTRY do
        assert_ar_entry(
            entry,
            1,
            string.format("line 1476 did not allocate read entry%d", entry)
        )
    end

    print(
        "Covered AxiReorder.sv:1476 condition row " ..
        "arsel_valid/io_mst_ar_valid = 0/1"
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

    -- 读表已满，在 reset 清表前覆盖第 1476 行的 0/1 组合。
    cover_ar_mst_fire_full_table_condition()

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

local function accept_mst_aw(transaction, expected_entry, is_target, expected_nid)
    local expected_signals = signals.dbg_aw.entries[expected_entry]
    expected_nid = expected_nid or 0

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
    assert_equal(
        expected_signals.nid:get(),
        expected_nid,
        transaction.name .. " saved nid"
    )
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

local function cover_wbitsq_ready_before_downstream_aw(transaction, expected_entry)
    -- 上游 W 已进入 wbitsq，而下游 AW 被阻塞，所以队首 entry 尚未发送 AW。
    assert_equal(wbitsq_deq_valid:get(), 1, transaction.name .. " queued W valid")
    assert_equal(wbitsq_deq_entry:get(), expected_entry, transaction.name .. " queued W entry")
    assert_equal(
        signals.dbg_aw.entries[expected_entry].have_sent:get(),
        0,
        transaction.name .. " haveSendAW before downstream AW"
    )
    assert_equal(
        wbitsq_deq_entry_have_sent_aw:get(),
        0,
        "AxiReorder.sv:41756 condition term 1 _GEN_132"
    )
    assert_equal(dut.io_slv_aw_ready:get(), 0, "downstream AW remains blocked")

    dut.io_slv_w_ready:set_imm(1)
    settle_combination()

    assert_equal(
        wbitsq_deq_entry_have_sent_aw:get(),
        0,
        "AxiReorder.sv:41756 sampled _GEN_132"
    )
    assert_equal(dut.io_slv_w_ready:get(), 1, "AxiReorder.sv:41756 sampled WREADY")
    assert_equal(dut.io_slv_w_valid:get(), 0, "WVALID gated until downstream AW")

    -- 保持 (0,1) 跨过一个时钟沿；deq_ready=0，队首 W 必须保持不变。
    env.wait_cycles(1)
    finish_handshake_edge()
    assert_equal(wbitsq_deq_valid:get(), 1, transaction.name .. " queued W retained")
    assert_equal(wbitsq_deq_entry:get(), expected_entry, transaction.name .. " retained W entry")
    assert_equal(dut.io_slv_w_valid:get(), 0, "no downstream W handshake before AW")

    dut.io_slv_w_ready:set_imm(0)
    wait_negedge()

    print(
        "Covered AxiReorder.sv:41756 condition row " ..
        "_GEN_132/io_slv_w_ready = 0/1"
    )
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

local function cover_fastqueue1_empty_driver_ready_condition(transaction, expected_entry)
    -- W 已经正常出队，但 B 尚未返回，写 entry 及其 haveSendAW 仍保持为 1。
    -- FastQueue 的空 driver 保留刚出队的 payload，因此 _GEN_132 仍指向该 entry。
    assert_equal(wbitsq_deq_valid:get(), 0, transaction.name .. " wbitsq empty after W")
    assert_equal(wbitsq_driver_deq_valid:get(), 0, "FastQueue_1.sv:72 driver valid")
    assert_equal(wbitsq_deq_entry:get(), expected_entry, transaction.name .. " retained W entry")
    assert_equal(
        signals.dbg_aw.entries[expected_entry].valid:get(),
        1,
        transaction.name .. " entry retained before B"
    )
    assert_equal(
        signals.dbg_aw.entries[expected_entry].have_sent:get(),
        1,
        transaction.name .. " haveSendAW after downstream AW"
    )
    assert_equal(wbitsq_deq_entry_have_sent_aw:get(), 1, "FastQueue line72 retained _GEN_132")

    -- 空队列继续声明 READY 是合法的；VALID=0 保证这一拍不会产生 W 握手。
    dut.io_slv_w_ready:set_imm(1)
    settle_combination()

    assert_equal(wbitsq_io_deq_ready:get(), 1, "FastQueue_1.sv:72 io_deq_ready")
    assert_equal(wbitsq_driver_deq_valid:get(), 0, "FastQueue_1.sv:72 _driver_io_deq_valid")
    assert_equal(dut.io_slv_w_valid:get(), 0, "no downstream WVALID with empty wbitsq")

    -- 保持 io_deq_ready/_driver_io_deq_valid=1/0 跨过完整时钟沿供覆盖器采样。
    env.wait_cycles(1)
    finish_handshake_edge()
    assert_equal(wbitsq_io_deq_ready:get(), 1, "FastQueue line72 sampled io_deq_ready")
    assert_equal(wbitsq_driver_deq_valid:get(), 0, "FastQueue line72 sampled driver valid")
    assert_equal(wbitsq_deq_valid:get(), 0, transaction.name .. " wbitsq remains empty")

    dut.io_slv_w_ready:set_imm(0)
    wait_negedge()

    print(
        "Covered FastQueue_1.sv:72 subcondition row " ..
        "io_deq_ready/_driver_io_deq_valid = 1/0"
    )
end

local function allocate_and_hold_write(transaction, expected_entry, is_target, cover_wready_conditions)
    accept_mst_aw(transaction, expected_entry, is_target)
    accept_mst_w(transaction)
    if cover_wready_conditions then
        cover_wbitsq_ready_before_downstream_aw(transaction, expected_entry)
    end
    accept_slv_aw(transaction, expected_entry)
    accept_slv_w(transaction)
    if cover_wready_conditions then
        cover_fastqueue1_empty_driver_ready_condition(transaction, expected_entry)
    end

    assert_entry_valid(
        expected_entry,
        1,
        transaction.name .. " remains occupied before B"
    )
end

local function send_b_response(transaction, entry, before_handshake)
    set_slv_b(entry, true)
    settle_combination()
    wait_until_observed(function()
        return dut.io_slv_b_ready:get() == 1 and dut.io_mst_b_valid:get() == 1
    end, transaction.name .. " B handshake")

    if before_handshake ~= nil then
        before_handshake()
    end

    assert_equal(dut.io_mst_b_bits_id:get(), transaction.id, transaction.name .. " restored BID")
    assert_equal(dut.io_mst_b_bits_resp:get(), 0, transaction.name .. " BRESP")

    env.wait_cycles(1)
    finish_handshake_edge()
    clear_slv_b()
    wait_negedge()

    assert_entry_valid(entry, 0, transaction.name .. " released after B")
end

local function send_r_response(transaction, entry, before_handshake)
    set_slv_r(entry, true)
    settle_combination()
    wait_until_observed(function()
        return dut.io_slv_r_ready:get() == 1 and dut.io_mst_r_valid:get() == 1
    end, transaction.name .. " R handshake")

    if before_handshake ~= nil then
        before_handshake()
    end

    assert_equal(dut.io_mst_r_bits_id:get(), transaction.id, transaction.name .. " restored RID")
    assert_equal(dut.io_mst_r_bits_last:get(), 1, transaction.name .. " RLAST")
    assert_equal(dut.io_mst_r_bits_resp:get(), 0, transaction.name .. " RRESP")

    env.wait_cycles(1)
    finish_handshake_edge()
    clear_slv_r()
    wait_negedge()

    assert_equal(
        signals.dbg_ar.entries[entry].valid:get(),
        0,
        transaction.name .. " released after R"
    )
end

local function cover_rr_arbiter_line136_subcondition()
    driver.drive {
        io_slv_ar_ready = 0,
        io_mst_r_ready = 1,
        io_slv_aw_ready = 0,
        io_slv_w_ready = 0,
        io_mst_b_ready = 0,
    }
    clear_mst_ar()
    clear_slv_r()
    wait_negedge()

    assert_equal(ar_rr_last_grant:get(), 0, "RRArbiter line136 reset lastGrant")

    -- 下游 AR 被阻塞，64 笔不同 ID 的请求按最低空闲项填满 entry0..63。
    for entry = 0, LAST_ENTRY do
        accept_mst_ar(read_transactions[entry], entry)
    end

    assert_equal(ar_rr_input_63_valid:get(), 1, "RRArbiter line136 initial io_in_63_valid")
    assert_equal(ar_rr_last_grant:get(), 0, "RRArbiter line136 lastGrant before arbitration")

    -- lastGrant=0 且全部 entry 可发送时，轮询顺序为 entry1..63。
    -- 每次只开放一拍 ARREADY，避免 entry63 后继续回绕握手 entry0。
    for entry = 1, LAST_ENTRY do
        assert_equal(
            signals.dbg_ar.selected_entry:get(),
            entry,
            string.format("RRArbiter line136 selected entry%d", entry)
        )
        accept_slv_ar(read_transactions[entry], entry)
        assert_equal(
            ar_rr_last_grant:get(),
            entry,
            string.format("RRArbiter line136 lastGrant after entry%d", entry)
        )
    end

    assert_equal(ar_rr_last_grant:get(), 63, "RRArbiter line136 lastGrant reached entry63")
    assert_equal(ar_rr_input_63_valid:get(), 0, "entry63 no longer requests after downstream AR")

    -- entry63 已合法发出下游 AR，现在返回末拍 R 释放它；R 不改变 lastGrant。
    send_r_response(read_transactions[63], 63)
    assert_equal(ar_rr_last_grant:get(), 63, "RRArbiter line136 lastGrant retained after R")

    -- entry0..62 仍占用，因此新 AR 只能重新分配到 entry63。
    -- ARREADY 保持为 0，使新 entry63 不会在同一场景内再次发往下游。
    accept_mst_ar(rr_line136_replacement, 63)
    settle_combination()

    assert_equal(signals.dbg_ar.entries[63].valid:get(), 1, "line136 replacement valid")
    assert_equal(signals.dbg_ar.entries[63].nid:get(), 0, "line136 replacement nid")
    assert_equal(signals.dbg_ar.entries[63].have_sent:get(), 0, "line136 replacement haveSendAR")
    assert_equal(ar_rr_input_63_valid:get(), 1, "RRArbiter64_UInt0.sv:136 operand 1")
    assert_equal(ar_rr_last_grant:get(), 63, "RRArbiter64_UInt0.sv:136 operand 2 is false")
    assert_equal(signals.dbg_ar.selected_entry:get(), 0, "line136 wrap-around chooses entry0")

    -- 保持 io_in_63_valid/lastGrant = 1/63 跨过一个完整时钟沿，覆盖子条件 10。
    env.wait_cycles(1)
    finish_handshake_edge()
    wait_negedge()
    assert_equal(ar_rr_input_63_valid:get(), 1, "RRArbiter line136 sampled operand 1")
    assert_equal(ar_rr_last_grant:get(), 63, "RRArbiter line136 sampled lastGrant")

    print(
        "Covered RRArbiter64_UInt0.sv:136 subcondition row " ..
        "io_in_63_valid/(lastGrant != 63) = 1/0"
    )

    -- 完成尚未发送的 entry0 和新 entry63 的下游 AR，然后返回全部剩余 R。
    accept_slv_ar(read_transactions[0], 0)
    accept_slv_ar(rr_line136_replacement, 63)

    for entry = 0, 62 do
        send_r_response(read_transactions[entry], entry)
    end
    send_r_response(rr_line136_replacement, 63)

    for entry = 0, LAST_ENTRY do
        assert_equal(
            signals.dbg_ar.entries[entry].valid:get(),
            0,
            string.format("RRArbiter line136 cleanup entry%d", entry)
        )
    end

    dut.io_mst_r_ready:set_imm(0)
    dut.io_slv_ar_ready:set_imm(0)
    clear_mst_ar()
    clear_slv_r()
    wait_negedge()
end

local function cover_rr_arbiter_line137_subcondition()
    -- line136 场景已经正常结束，先复位空闲 DUT，使轮询指针确定为 0。
    -- 复位前所有读事务均已返回 R，不依赖 reset 取消任何事务。
    env.dut_reset()
    finish_handshake_edge()
    wait_negedge()

    driver.drive {
        io_slv_ar_ready = 0,
        io_mst_r_ready = 1,
        io_slv_aw_ready = 0,
        io_slv_w_ready = 0,
        io_mst_b_ready = 0,
    }
    clear_mst_ar()
    clear_slv_r()
    wait_negedge()

    assert_equal(ar_rr_last_grant:get(), 0, "RRArbiter line137 reset lastGrant")

    -- 下游 AR 被阻塞，先用 64 笔不同 ID 的 AR 填满 entry0..63。
    for entry = 0, LAST_ENTRY do
        accept_mst_ar(read_transactions[entry], entry)
    end

    -- 从 lastGrant=0 开始依次发送 entry1..62，最后一个握手把指针置为 62。
    -- entry63 保持占用但未发送，后续用于验证回绕选择不会改变目标组合。
    for entry = 1, 62 do
        assert_equal(
            signals.dbg_ar.selected_entry:get(),
            entry,
            string.format("RRArbiter line137 selected entry%d", entry)
        )
        accept_slv_ar(read_transactions[entry], entry)
        assert_equal(
            ar_rr_last_grant:get(),
            entry,
            string.format("RRArbiter line137 lastGrant after entry%d", entry)
        )
    end

    assert_equal(ar_rr_last_grant:get(), 62, "RRArbiter line137 lastGrant reached entry62")
    assert_equal(ar_rr_input_63_valid:get(), 1, "entry63 remains pending for line137")

    -- entry62 的原事务合法返回单拍 R，释放该 entry；R 不改变 lastGrant=62。
    send_r_response(read_transactions[62], 62)
    assert_equal(ar_rr_last_grant:get(), 62, "RRArbiter line137 lastGrant retained after R")

    -- 新 AR 重新占用 entry62。保持下游 ARREADY=0，使 entry62 的
    -- valid/nid/haveSendAR=1/0/0，从而 io_in_62_valid=1。
    accept_mst_ar(rr_line137_replacement, 62)
    settle_combination()

    assert_equal(signals.dbg_ar.entries[62].valid:get(), 1, "line137 replacement valid")
    assert_equal(signals.dbg_ar.entries[62].nid:get(), 0, "line137 replacement nid")
    assert_equal(signals.dbg_ar.entries[62].have_sent:get(), 0, "line137 replacement haveSendAR")
    assert_equal(ar_rr_input_62_valid:get(), 1, "RRArbiter64_UInt0.sv:137 operand 1")
    assert_equal(ar_rr_last_grant:get(), 62, "RRArbiter64_UInt0.sv:137 operand 2 is false")
    assert_equal(signals.dbg_ar.selected_entry:get(), 63, "line137 false branch selects entry63")

    -- lastGrant=62 的高 5 位为 5'h1f，所以 (lastGrant[5:1] != 5'h1f)=0。
    -- 保持该状态跨过完整时钟沿，确保覆盖器采到缺失的 1/0 组合。
    env.wait_cycles(1)
    finish_handshake_edge()
    wait_negedge()
    assert_equal(ar_rr_input_62_valid:get(), 1, "RRArbiter line137 sampled operand 1")
    assert_equal(ar_rr_last_grant:get(), 62, "RRArbiter line137 sampled lastGrant")

    print(
        "Covered RRArbiter64_UInt0.sv:137 subcondition row " ..
        "io_in_62_valid/(lastGrant[5:1] != 5'h1f) = 1/0"
    )

    -- 依次完成 entry63、entry0 和新 entry62 的下游 AR；随后返回所有剩余 R。
    accept_slv_ar(read_transactions[63], 63)
    accept_slv_ar(read_transactions[0], 0)
    accept_slv_ar(rr_line137_replacement, 62)

    for entry = 0, 61 do
        send_r_response(read_transactions[entry], entry)
    end
    send_r_response(read_transactions[63], 63)
    send_r_response(rr_line137_replacement, 62)

    for entry = 0, LAST_ENTRY do
        assert_equal(
            signals.dbg_ar.entries[entry].valid:get(),
            0,
            string.format("RRArbiter line137 cleanup entry%d", entry)
        )
    end

    dut.io_mst_r_ready:set_imm(0)
    dut.io_slv_ar_ready:set_imm(0)
    clear_mst_ar()
    clear_slv_r()
    wait_negedge()
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

local function select_nid_coverage_helpers(target_entry)
    if target_entry == 0 then
        return 1, 2
    elseif target_entry == 1 then
        return 2, 0
    end

    return 0, 1
end

local function make_ar_nid_target_transaction(target_entry, helper_entry)
    return {
        name = string.format("AR nid condition target entry%d", target_entry),
        id = read_transactions[helper_entry].id,
        addr = 0x30000 + target_entry * 0x20,
    }
end

local function assert_ar_nid_target(target_entry, transaction, expected_valid)
    local target = signals.dbg_ar.entries[target_entry]

    assert_equal(target.id:get(), transaction.id, transaction.name .. " stored ARID")
    assert_equal(target.nid:get(), 1, transaction.name .. " nid")
    assert_equal(target.valid:get(), expected_valid, transaction.name .. " valid")
    assert_equal(target.have_sent:get(), 0, transaction.name .. " haveSendAR")
end

local function cover_ar_nid_invalid_matching_row(
    target_entry,
    helper_entry,
    target_transaction,
    rtl_line
)
    -- helper R 与 target 使用同一个上游 ID。先断言异步 reset，将 rvld 清零
    -- 但保留 arinfo.id/nid，让下一个时钟沿观察到 valid=0。
    assert_ar_nid_target(target_entry, target_transaction, 1)
    set_slv_r(helper_entry, true)
    dut.reset:set_imm(1)
    settle_combination()

    assert_equal(signals.reset:get(), 1, "reset asserted for AR nid invalid row")
    assert_equal(dut.io_mst_r_ready:get(), 1, "AR nid condition r_fire RREADY")
    assert_equal(dut.io_slv_r_valid:get(), 1, "AR nid condition r_fire RVALID")
    assert_equal(dut.io_slv_r_bits_last:get(), 1, "AR nid condition RLAST")
    assert_equal(
        dut.io_mst_r_bits_id:get(),
        target_transaction.id,
        string.format("AxiReorder.sv:%d matching restored RID", rtl_line)
    )
    assert_ar_nid_target(target_entry, target_transaction, 0)

    -- 跨过一个时钟沿，使该 always 块求值 1/1/1/0/1。
    wait_negedge()
    assert_ar_nid_target(target_entry, target_transaction, 0)
    assert_equal(dut.io_mst_r_ready:get(), 1, "sampled AR nid condition RREADY")
    assert_equal(dut.io_slv_r_valid:get(), 1, "sampled AR nid condition RVALID")
    assert_equal(dut.io_slv_r_bits_last:get(), 1, "sampled AR nid condition RLAST")
    assert_equal(
        dut.io_mst_r_bits_id:get(),
        target_transaction.id,
        string.format("AxiReorder.sv:%d sampled matching RID", rtl_line)
    )

    clear_slv_r()
    env.dut_reset()
    finish_handshake_edge()
    wait_negedge()

    assert_ar_nid_target(target_entry, target_transaction, 0)
end

local function cover_all_ar_nid_decrement_conditions()
    for target_entry = 0, LAST_ENTRY do
        driver.drive {
            io_mst_r_ready = 1,
            io_slv_ar_ready = 0,
            io_slv_aw_ready = 0,
            io_slv_w_ready = 0,
            io_mst_b_ready = 0,
        }
        wait_negedge()

        local helper_entry, mismatch_entry = select_nid_coverage_helpers(target_entry)
        local last_setup_entry = math.max(target_entry, 2)

        -- 先用不同 ID 构造可合法返回 R 的 helper、mismatch 和 target。
        for entry = 0, last_setup_entry do
            allocate_and_hold_read(read_transactions[entry], entry, 0)
        end

        send_r_response(read_transactions[target_entry], target_entry)

        -- 重新分配 target，并复用 helper 的 ID；helper 仍有效，因此 nid=1。
        local target_transaction = make_ar_nid_target_transaction(target_entry, helper_entry)
        accept_mst_ar(target_transaction, target_entry, 1)
        assert_ar_nid_target(target_entry, target_transaction, 1)

        local rtl_line = 39968 + target_entry * 18

        -- mismatch R 的恢复 ID 不同，覆盖 1/1/0/1/1。
        send_r_response(
            read_transactions[mismatch_entry],
            mismatch_entry,
            function()
                assert_equal(
                    signals.dbg_ar.entries[target_entry].nid:get(),
                    1,
                    string.format("AxiReorder.sv:%d nid_nonzero", rtl_line)
                )
                assert_equal(dut.io_mst_r_ready:get(), 1, "AR nid mismatch RREADY")
                assert_equal(dut.io_slv_r_valid:get(), 1, "AR nid mismatch RVALID")
                assert_equal(dut.io_slv_r_bits_last:get(), 1, "AR nid mismatch RLAST")
                assert_equal(
                    dut.io_mst_r_bits_id:get() == target_transaction.id,
                    false,
                    string.format("AxiReorder.sv:%d restored RID mismatch", rtl_line)
                )
                assert_equal(
                    signals.dbg_ar.entries[target_entry].valid:get(),
                    1,
                    string.format("AxiReorder.sv:%d target valid", rtl_line)
                )
            end
        )
        assert_ar_nid_target(target_entry, target_transaction, 1)

        -- helper R 提供匹配 ID，异步 reset 提供 valid=0，覆盖 1/1/1/0/1。
        cover_ar_nid_invalid_matching_row(
            target_entry,
            helper_entry,
            target_transaction,
            rtl_line
        )

        if (target_entry + 1) % 8 == 0 then
            print(string.format(
                "AR nid condition progress: covered entries 0..%d",
                target_entry
            ))
        end
    end

    print(
        "Covered AxiReorder.sv:39968..41102 AR nid condition rows " ..
        "nid_nonzero/r_fire/id_match/valid/RLAST = 1/1/0/1/1 and 1/1/1/0/1"
    )
end

local function make_nid_target_transaction(target_entry, helper_entry)
    return {
        name = string.format("AW nid condition target entry%d", target_entry),
        id = initial_transactions[helper_entry].id,
        addr = 0x70000 + target_entry * 0x20,
        data = 0x7000 + target_entry,
    }
end

local function assert_aw_nid_target(target_entry, transaction, expected_valid)
    local target = signals.dbg_aw.entries[target_entry]

    assert_equal(target.id:get(), transaction.id, transaction.name .. " stored AWID")
    assert_equal(target.nid:get(), 1, transaction.name .. " nid")
    assert_equal(target.valid:get(), expected_valid, transaction.name .. " valid")
end

local function cover_aw_nid_invalid_matching_row(
    target_entry,
    helper_entry,
    target_transaction,
    rtl_line
)
    -- helper B 与 target 使用同一个上游 ID。在下一个时钟沿之前
    -- 先断言异步 reset，将 wvld 清零但保留 awinfo.id/nid。
    assert_aw_nid_target(target_entry, target_transaction, 1)
    set_slv_b(helper_entry, true)
    dut.reset:set_imm(1)
    settle_combination()

    assert_equal(signals.reset:get(), 1, "reset asserted for AW nid invalid row")
    assert_equal(dut.io_mst_b_ready:get(), 1, "AW nid condition b_fire BREADY")
    assert_equal(dut.io_slv_b_valid:get(), 1, "AW nid condition b_fire BVALID")
    assert_equal(
        dut.io_mst_b_bits_id:get(),
        target_transaction.id,
        string.format("AxiReorder.sv:%d matching restored BID", rtl_line)
    )
    assert_aw_nid_target(target_entry, target_transaction, 0)

    -- 跨过一个时钟沿，使该 always 块真正求值 1/1/1/0。
    -- reset=1 时 monitor 不会把保持的 BVALID 当成正常 B 事务。
    wait_negedge()
    assert_aw_nid_target(target_entry, target_transaction, 0)
    assert_equal(dut.io_mst_b_ready:get(), 1, "sampled AW nid condition BREADY")
    assert_equal(dut.io_slv_b_valid:get(), 1, "sampled AW nid condition BVALID")
    assert_equal(
        dut.io_mst_b_bits_id:get(),
        target_transaction.id,
        string.format("AxiReorder.sv:%d sampled matching BID", rtl_line)
    )

    clear_slv_b()
    env.dut_reset()
    finish_handshake_edge()
    wait_negedge()

    assert_aw_nid_target(target_entry, target_transaction, 0)
end

local function cover_all_aw_nid_decrement_conditions()
    for target_entry = 0, LAST_ENTRY do
        driver.drive {
            io_slv_ar_ready = 0,
            io_mst_r_ready = 0,
            io_slv_aw_ready = 0,
            io_slv_w_ready = 0,
            io_mst_b_ready = 1,
        }
        wait_negedge()

        local helper_entry, mismatch_entry = select_nid_coverage_helpers(target_entry)
        local last_setup_entry = math.max(target_entry, 2)

        -- 先用不同 ID 构造可合法返回 B 的 helper、mismatch 和 target。
        for entry = 0, last_setup_entry do
            allocate_and_hold_write(initial_transactions[entry], entry, false)
        end

        send_b_response(initial_transactions[target_entry], target_entry)

        -- 重新分配 target，并复用 helper 的 ID；helper 仍有效，因此 nid=1。
        local target_transaction = make_nid_target_transaction(target_entry, helper_entry)
        accept_mst_aw(target_transaction, target_entry, false, 1)
        accept_mst_w(target_transaction)
        assert_aw_nid_target(target_entry, target_transaction, 1)

        local rtl_line = 41111 + target_entry * 7

        -- mismatch B 的恢复 ID 不同，覆盖 1/1/0/1。
        send_b_response(
            initial_transactions[mismatch_entry],
            mismatch_entry,
            function()
                assert_equal(
                    signals.dbg_aw.entries[target_entry].nid:get(),
                    1,
                    string.format("AxiReorder.sv:%d nid_nonzero", rtl_line)
                )
                assert_equal(dut.io_mst_b_ready:get(), 1, "AW nid mismatch BREADY")
                assert_equal(dut.io_slv_b_valid:get(), 1, "AW nid mismatch BVALID")
                assert_equal(
                    dut.io_mst_b_bits_id:get() == target_transaction.id,
                    false,
                    string.format("AxiReorder.sv:%d restored BID mismatch", rtl_line)
                )
                assert_equal(
                    signals.dbg_aw.entries[target_entry].valid:get(),
                    1,
                    string.format("AxiReorder.sv:%d target valid", rtl_line)
                )
            end
        )
        assert_aw_nid_target(target_entry, target_transaction, 1)

        -- helper B 提供匹配 ID，异步 reset 提供 valid=0，覆盖 1/1/1/0。
        cover_aw_nid_invalid_matching_row(
            target_entry,
            helper_entry,
            target_transaction,
            rtl_line
        )

        if (target_entry + 1) % 8 == 0 then
            print(string.format(
                "AW nid condition progress: covered entries 0..%d",
                target_entry
            ))
        end
    end

    print(
        "Covered AxiReorder.sv:41111..41552 AW nid condition rows " ..
        "nid_nonzero/b_fire/id_match/valid = 1/1/0/1 and 1/1/1/0"
    )
end

local function cover_awq_enq_valid_full_table_condition()
    -- 每个已占用 entry 的 W 都在 allocate_and_hold_write() 中完成，
    -- 因此 wq 此时为空且仍可接收；只有写重排表本身已满。
    assert_equal(awsel_valid:get(), 0, "condition term 2 awsel_valid with full table")
    assert_equal(wq_enq_ready:get(), 1, "condition term 3 wq_io_enq_ready")

    set_mst_aw(blocked_when_full, true)
    settle_combination()

    assert_equal(dut.io_mst_aw_valid:get(), 1, "condition term 1 io_mst_aw_valid")
    assert_equal(awsel_valid:get(), 0, "AxiReorder.sv:41700 awsel_valid")
    assert_equal(wq_enq_ready:get(), 1, "AxiReorder.sv:41700 wq_io_enq_ready")
    assert_equal(dut.io_mst_aw_ready:get(), 0, "AWREADY while target AW is blocked")

    -- 跨过一个时钟沿保持 1/0/1；AWREADY=0 保证不会产生握手。
    env.wait_cycles(1)
    finish_handshake_edge()
    clear_mst_aw()
    wait_negedge()

    assert_all_entries(1, "line 41700 did not allocate an entry")

    print(
        "Covered AxiReorder.sv:41700 condition row " ..
        "io_mst_aw_valid/awsel_valid/wq_io_enq_ready = 1/0/1"
    )
end

local function cover_aw_b_id_condition(rtl_line, entry, condition_wire, replacement_transaction)
    local line_name = string.format("AxiReorder.sv:%d", rtl_line)

    -- 目标 entry 的下游 AW/W 已完成，故 entry 编号是合法的下游 B ID；
    -- wbitsq 为空也证明前面的 W 已经完成，不会留下额外 W 响应。
    assert_all_entries(1, line_name .. " B condition precondition")
    assert_equal(
        signals.dbg_aw.entries[entry].have_sent:get(),
        1,
        line_name .. " target haveSendAW"
    )
    assert_equal(wbitsq_deq_valid:get(), 0, line_name .. " wbitsq drained")

    -- BVALID=1、BREADY=0 使第 1 项为 0，同时不发生 B 握手或释放目标 entry。
    dut.io_mst_b_ready:set_imm(0)
    set_slv_b(entry, true)
    settle_combination()

    assert_equal(awinfo_63_nid_done:get(), 0, line_name .. " condition term 1")
    assert_equal(dut.io_slv_b_bits_id:get(), entry, line_name .. " B ID term 2")
    assert_equal(condition_wire:get(), 0, line_name .. " condition result")
    assert_equal(dut.io_slv_b_valid:get(), 1, line_name .. " BVALID")
    assert_equal(dut.io_mst_b_valid:get(), 1, line_name .. " upstream BVALID")
    assert_equal(dut.io_mst_b_ready:get(), 0, line_name .. " BREADY")

    -- READY=0 时保持 BVALID、BID 和 BRESP 不变，覆盖 0/1 但不发生握手。
    env.wait_cycles(1)
    finish_handshake_edge()
    assert_equal(awinfo_63_nid_done:get(), 0, line_name .. " sampled term 1")
    assert_equal(condition_wire:get(), 0, line_name .. " sampled condition")
    assert_entry_valid(entry, 1, line_name .. " target retained before B handshake")

    -- 保持 VALID 和 payload，拉高 READY 完成这笔真实 B 响应，然后才撤销 VALID。
    dut.io_mst_b_ready:set_imm(1)
    settle_combination()
    assert_equal(dut.io_slv_b_ready:get(), 1, line_name .. " downstream BREADY")
    assert_equal(dut.io_mst_b_bits_id:get(), initial_transactions[entry].id, line_name .. " restored BID")

    env.wait_cycles(1)
    finish_handshake_edge()
    clear_slv_b()
    wait_negedge()
    assert_entry_valid(entry, 0, line_name .. " target released after B")

    -- 重新占用目标 entry，使后续测试仍从 64 项全满的既有状态继续。
    allocate_and_hold_write(replacement_transaction, entry, false)
    assert_all_entries(1, line_name .. " full table restored")

    print(string.format(
        "Covered AxiReorder.sv:%d condition row " ..
        "_awinfo_63_nid_done_T_126/id_match = 0/1",
        rtl_line
    ))
end

local function task_condition_coverage()
    cover_all_ar_nid_decrement_conditions()
    cover_ar_should_send_63_invalid_condition()
    cover_rr_arbiter_line136_subcondition()
    cover_rr_arbiter_line137_subcondition()
    cover_all_aw_nid_decrement_conditions()

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
        -- entry0 同时覆盖下游 AW 前的 AxiReorder:41756 和 W 出队后的 FastQueue_1:72。
        allocate_and_hold_write(initial_transactions[entry], entry, false, entry == 0)
    end
    assert_all_entries(1, "full-table layout")
    assert_equal(dut.io_mst_aw_ready:get(), 0, "AWREADY while all entries are occupied")

    -- 写表已满但 wq 已排空，在释放 entry0 前覆盖第 41700 行。
    cover_awq_enq_valid_full_table_condition()

    -- 在返回 entry0 的 B 之前，分别用 entry47/50/60 覆盖三个 B-ID 条件。
    cover_aw_b_id_condition(1900, 0x2F, aw_b_id_2f_condition, line1900_replacement)
    cover_aw_b_id_condition(1906, 0x32, aw_b_id_32_condition, line1906_replacement)
    cover_aw_b_id_condition(1926, 0x3C, aw_b_id_3c_condition, line1926_replacement)

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
        local transaction = b_condition_replacements[entry] or initial_transactions[entry]
        send_b_response(transaction, entry)
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
