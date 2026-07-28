local env = require "env"
local driver = require "dut.driver"

--[====[
================================================================================
012_linecoverage.lua
================================================================================

一、覆盖目标

本用例用于命中 AxiReorder 读路径中 entry 0 到 entry 3 的减 2 RTL：

    else if (_layer_probe_5)
        arinfo_1_nid <= arinfo_1_nid - 2'h2;

    else if (_layer_probe_1)
        arinfo_0_nid <= arinfo_0_nid - 2'h2;

    else if (_layer_probe_9)
        arinfo_2_nid <= arinfo_2_nid - 2'h2;

    else if (_layer_probe_13)
        arinfo_3_nid <= arinfo_3_nid - 2'h2;

其中：

    _layer_probe_5 = _GEN_4 & _GEN_5

    _GEN_4 =
        (|arinfo_1_nid) &
        rFire &
        (response_original_id == arinfo_1_bits_id) &
        rvld_1 &
        RLAST

    _GEN_5 = rWkVldReg & rWkEtrReg[1]

要执行减 2 分支，不能只返回一笔同 ID 响应；必须同时出现两份需要从 entry 1
nid 中扣除的“前序事务完成”信息：

1. 当前周期有一笔同 ID 前序事务完成，对应 _GEN_4=1；
2. 上一周期还发生过“新 AR 分配与同 ID 末拍 R 响应同时握手”，这份修正信息
   被 rWkVldReg/rWkEtrReg 延迟一拍保存，并且新请求必须分配到 entry 1，
   对应当前周期 _GEN_5=1。

二、端口激励构造

测试先构造以下表项状态：

    entry 0 : B1，ID_B，第一个同 ID 前序事务，已经向下游发送 AR
    entry 1 : A，ID_A，与目标 ID 不同，是临时占位事务
    entry 2 : B2，ID_B，第二个同 ID 前序事务，nid=1，尚未发送 AR

之后完成 A，释放 entry 1，同时保持 entry 0 中的 B1 有效。此时在同一个
上升沿完成两件事：

    * 上游提交 B3(ID_B)，最低空闲表项选择逻辑将它分配到 entry 1；
    * 下游返回 entry 0 中 B1 的末拍 R 响应。

该上升沿之前 B1、B2 都仍有效，所以 B3 装载 rawRNid=2。同时，因为 B3 的
ARID 与 B1 响应恢复出的原始 ID 相同，RTL 将 rWkVldReg 置 1，并在
rWkEtrReg[1] 中记录“这份延迟修正属于新分配的 entry 1”。B1 完成还会使 B2
的 nid 从 1 降到 0，因此 B2 的 AR 在下一周期变为可发送。

紧接着的下一周期，让 B2 的下游 AR 与它的单拍 R 响应在同一个上升沿握手。
AXI 允许从设备组合观察 ARVALID/AR payload，并以零周期延迟给出 RVALID；在
该上升沿之前，B2 已经是有效且 nid=0 的可发送事务，因此响应是有对应请求的。
此时：

    _GEN_4 = 1：当前完成 B2，它与 entry 1 中 B3 的原始 ID 相同；
    _GEN_5 = 1：上一周期保存的 B1/B3 同周期修正命中 entry 1；

于是 _layer_probe_5=1，第一处目标行把 arinfo_1_nid 从 2 一次减到 0。

三、entry 0 减 2 场景

entry 0 的组合条件与 entry 1 完全对称：

    _layer_probe_1 = _GEN_2 & _GEN_3
    _GEN_3 = rWkVldReg & rWkEtrReg[0]

但 entry 0 是最低优先分配的空闲表项，不能直接照搬前一个表项布局。本用例在
entry 1 场景全部收尾后重新构造：

    entry 0 : D，不同 ID 的临时占位事务
    entry 1 : C1，ID_C，第一个同 ID 前序事务，已经向下游发送 AR
    entry 2 : C2，ID_C，第二个同 ID 前序事务，nid=1，尚未发送 AR

先完成 D 释放 entry 0；随后在同一个上升沿把 C3(ID_C) 分配到 entry 0，并
返回 entry 1 中 C1 的末拍响应。C3 在分配前能看到 C1/C2 两个同 ID 有效项，
所以 entry 0 装载 nid=2；同周期分配和响应还会使 rWkVldReg=1，并把
rWkEtrReg[0] 置 1。C1 完成后 C2 的 nid 变成 0，下一周期让 C2 的下游 AR
和单拍 R 同周期握手，此时当前 C2 响应产生 _GEN_2=1，上一周期保存的修正
产生 _GEN_3=1，最终使 _layer_probe_1=1，目标行将 arinfo_0_nid 从 2 减到 0。

四、entry 2 减 2 场景

entry 2 的目标条件为：

    _layer_probe_9 = _GEN_6 & _GEN_7
    _GEN_7 = rWkVldReg & rWkEtrReg[2]

测试先让 E1、E2 两笔同 ID 事务分别占用 entry 0 和 entry 1。E1 的 nid=0，
已经向下游发送 AR；E2 的 nid=1，仍在等待 E1 完成。随后在同一个上升沿：

    * 上游提交第三笔同 ID 事务 E3，E3 自然分配到 entry 2；
    * 下游返回 entry 0 中 E1 的单拍末拍响应。

E3 分配前能同时看到 E1/E2，因此 entry 2 装载 nid=2；分配和同 ID 响应同周期
发生，使 rWkVldReg=1、rWkEtrReg[2]=1。E1 完成后 E2 的 nid 变为 0，下一
周期让 E2 的下游 AR 和单拍 R 同周期握手：E2 当前响应产生 _GEN_6=1，上一
周期保存的 entry 2 修正产生 _GEN_7=1，最终执行第 452 行，将 arinfo_2_nid
从 2 一次减到 0。

五、entry 3 减 2 场景

entry 3 的目标条件为：

    _layer_probe_13 = _GEN_8 & _GEN_9
    _GEN_9 = rWkVldReg & rWkEtrReg[3]

为了让目标事务分配到最高编号的 entry 3，分配时 entry 0、entry 1 和 entry 2
必须同时有效；但目标 nid 又必须精确等于 2，所以这三个已有事务中只能有两笔
与目标 ID 相同。测试构造如下：

    entry 0 : F1，ID_F，第一个同 ID 前序事务，已经发送 AR
    entry 1 : F2，ID_F，第二个同 ID 前序事务，nid=1，等待 F1
    entry 2 : G，ID_G，不同 ID 的占位事务，已经发送 AR

随后在同一个上升沿将 F3(ID_F) 分配到 entry 3，并返回 F1 的末拍响应。F3
只统计 F1/F2，因而装载 nid=2；同时 rWkVldReg=1、rWkEtrReg[3]=1。
下一周期让已经解除依赖的 F2 在下游 AR/R 同周期握手，当前响应产生 _GEN_8，
上一周期保存的修正产生 _GEN_9，最终执行第 471 行，将 arinfo_3_nid 从 2
一次减到 0。

六、AxiReorder.sv 第 487 行不可达说明

第 487 行是写路径 entry 0 的减 2 分支：

    _GEN_23 =
        (|awinfo_0_nid) &
        bFire &
        (response_original_id == awinfo_0_id) &
        wvld_0

    _GEN_24 = wWkVldReg & wWkEtrReg[0]

    if (_GEN_23 & _GEN_24)
        awinfo_0_nid <= awinfo_0_nid - 2'h2;  // 第 487 行

其中 _GEN_24 在当前周期为 1，要求上一周期同时发生一笔下游 B 握手和一笔
同 ID 上游 AW 握手，并且新 AW 恰好分配到 entry 0。_GEN_23 又要求当前周期
再完成一笔与 entry 0 目标事务同 ID 的 B。换言之，若要合法地从 nid=2 减到
0，必须有两笔同 ID 前序写响应在相邻两个周期完成，同时在第一笔 B 完成的周期
把目标 AW 分配到 entry 0。

但是当前 RTL 的写地址发送路径使用 entries=1 的 awq，并且队首只有在对应表项
nid=0 时才能出队：

    awq.io.deq.ready :=
        awinfo(awq.io.deq.bits.entry).nid === 0.U && io.slv.aw.ready

    io.mst.aw.ready :=
        awsel.valid && wq.io.enq.ready && awq.io.enq.ready

若已经存在两笔同 ID 前序写事务，第二笔的 nid=1，它会占住唯一的 awq 表项且
不能向下游发送 AW。因为 awq 已满，目标 AW 的 ready 必然为 0；即使本周期 B
正在完成第一笔事务，nid 也只会在时钟沿后更新，不能组合地释放 awq。因此“不
同表项 B 握手 + 目标 AW 分配到 entry 0”无法在该周期同时发生，_GEN_24 无法
为 nid=2 的目标事务建立。

若只保留一笔同 ID 前序事务，确实可以在它返回 B 时把目标 AW 分配到 entry 0，
但此时目标 rawWNid 只能等于 1。下一周期要同时拉高 _GEN_23，只剩下三种选择：

1. 对已经完成的旧 entry 再发送一次 B：旧 entry 的 wvld 已清零，会触发 RTL
   中“B fire but vec(i) is not valid”的断言；
2. 提前给目标 entry 0 返回 B：目标 nid 仍为 1，尚未发送下游 AW/W，会触发
   “awinfo(i).nid === 0”断言；
3. 返回另一笔同 ID 事务的 B：该事务并不存在；若另行提交，它又会因 nid>0
   堵住单深度 awq，回到前述矛盾。

强行采用前两种方式不仅违反 AXI 规定的 AW/W 完成后才能返回 B 的时序，也会
使 DUT assertion 和公共 scoreboard 报错，不能作为一个有效的回归测试点。
因此，第 487 行是由统一生成的每表项减法模板保留下来的结构性不可达分支；在
“只驱动顶层端口、不修改内部状态、事务必须合法且测试必须通过”的约束下，不
存在能够覆盖该行的 testcase。本文件不会伪造重复或提前 B 响应。该行应在覆盖
率工具中按不可达代码进行 waiver/exclude，而不是通过非法端口序列强行命中。

七、AxiReorder.sv 第 505 行不可达说明

第 505 行是同一段写路径模板在 entry 1 上的展开：

    _GEN_25 =
        (|awinfo_1_nid) &
        bFire &
        (response_original_id == awinfo_1_id) &
        wvld_1

    _GEN_26 = wWkVldReg & wWkEtrReg[1]

    if (_GEN_25 & _GEN_26)
        awinfo_1_nid <= awinfo_1_nid - 2'h2;  // 第 505 行

要令 _GEN_26=1，上一周期必须发生“同 ID B 握手 + 新 AW 握手”，并且新 AW
必须分配到 entry 1。要在下一周期同时令 _GEN_25=1，还必须存在另一笔已经完成
下游 AW/W、可以合法返回 B 的同 ID 前序写事务。

表项编号从 0 改成 1 并不能解除第 487 行分析中的结构冲突。只要目标事务之前
存在两笔同 ID 写事务，较后的那笔就会带着 nid>0 占住唯一的 awq 表项；它既
不能出队，也使 awq.io.enq.ready 和 io.mst.aw.ready 为 0。因此，在第一笔 B
返回的周期，目标 AW 无法握手，更不可能分配到 entry 1，wWkEtrReg[1] 无法
记录该目标事务。

若只安排一笔同 ID 前序事务，目标 entry 1 的 rawWNid 最多为 1。下一周期没有
第二笔合法同 ID B 可以产生 _GEN_25：重复旧 B 会命中无效 wvld 断言，提前给
目标返回 B 会命中 nid 非零断言，并且两者都会违反 AXI AW/W/B 顺序及公共
scoreboard 的事务对应关系。

因此第 505 行与第 487 行一样，是统一生成的写表项减法模板中的结构性不可达
分支。在只使用合法顶层端口事务且测试必须正常通过的约束下，不存在可加入本
文件的有效激励序列；该行也应在覆盖工具中作为不可达代码 waiver/exclude。

八、AxiReorder.sv 第 523 行不可达说明

第 523 行对应写路径 entry 2 的减 2 分支：

    _GEN_27 =
        (|awinfo_2_nid) &
        bFire &
        (response_original_id == awinfo_2_id) &
        wvld_2

    _GEN_28 = wWkVldReg & wWkEtrReg[2]

    if (_GEN_27 & _GEN_28)
        awinfo_2_nid <= awinfo_2_nid - 2'h2;  // 第 523 行

_GEN_28 要求上一周期的新 AW 在同 ID B 握手周期分配到 entry 2；_GEN_27
要求紧接着的当前周期还有另一笔同 ID B 合法返回。要让 entry 2 的目标事务
从 nid=2 减到 0，目标分配前必须存在两笔同 ID 前序写事务。

然而第二笔前序事务的 nid 必然大于 0，它会停在唯一的 awq 队首，使
awq.io.deq.ready=0。单深度 awq 被占满后 awq.io.enq.ready=0，进而使目标
AW 的 io.mst.aw.ready=0。因此第一笔 B 返回时，目标 AW 不能握手，也不能
分配到 entry 2，wWkEtrReg[2] 无法记录目标表项，_GEN_28 不可能按要求建立。

若减少为一笔前序事务以腾空 awq，目标 rawWNid 只能得到 1。下一周期既没有
第二笔已经完成 AW/W 的同 ID 事务可以返回 B，也不能重复旧 B 或提前返回目标
B：前者会触发 wvld 无效断言，后者会触发 nid 非零断言；两者同时违反 AXI
写响应顺序和公共 scoreboard 的事务对应检查。

因此第 523 行同样是统一写表项模板产生的结构性不可达代码。在不修改内部信号、
只使用合法端口事务并要求测试正常结束的前提下，无法编写能够命中该行的有效
testcase；该行应作为不可达项在覆盖工具中进行 waiver/exclude。

九、AxiReorder.sv 第 541 行不可达说明

第 541 行对应写路径 entry 3 的减 2 分支：

    _GEN_29 =
        (|awinfo_3_nid) &
        bFire &
        (response_original_id == awinfo_3_id) &
        wvld_3

    _GEN_30 = wWkVldReg & wWkEtrReg[3]

    if (_GEN_29 & _GEN_30)
        awinfo_3_nid <= awinfo_3_nid - 2'h2;  // 第 541 行

要令 _GEN_30=1，上一周期必须在同 ID B 握手时把新 AW 分配到 entry 3；当前
周期还要有第二笔同 ID B 返回以产生 _GEN_29。目标事务分配到 entry 3 又要求
entry 0、entry 1、entry 2 均有效，其中至少两笔必须与目标同 ID 才能使目标
nid 达到 2。

但是 AxiReorder 对同 ID 写地址按 nid 串行发送。第一笔之后的同 ID 前序事务
nid>0，会占住唯一的 awq 表项且不能出队。此时 awq.io.enq.ready=0，新的目标
AW 无论空闲表项选择结果是否指向 entry 3，都无法获得 io.mst.aw.ready，因而
不能与第一笔 B 在同一周期握手，wWkEtrReg[3] 也不可能记录该目标表项。

使用不同 ID 事务填充低编号表项只能帮助选择 entry 3，不能提供 _GEN_29 所需
的第二笔同 ID B；只保留一笔同 ID 前序又会使目标 rawWNid 最多为 1。重复旧
B 或提前返回目标 B 仍会分别触发 wvld 无效、nid 非零断言，并违反 AXI 写响应
顺序及 scoreboard 检查。

因此第 541 行是 entry 3 上同样的结构性不可达模板分支。在仅驱动顶层端口、
不修改内部状态、保持 AXI 事务合法且 testcase 必须通过的约束下，没有能够
覆盖该行的有效激励；该行应在覆盖工具中进行 waiver/exclude。

十、AxiReorder.sv 第 552 行覆盖场景

第 552 行是 wWkEtrReg 的条件更新语句：

    wWkVldReg <= wWkVld;
    if (wWkVld)
        wWkEtrReg <= selected_free_write_entry;  // 第 552 行

其中 wWkVld 要求下游 B 和上游新 AW 在同一个周期握手，并且两者恢复出的原始
AXI ID 相同。该条件合法可达，不需要构造前述不可达的连续两拍同 ID B：

1. 先完整发送单拍写事务 H1 的上游 AW/W 和下游 AW/W，使 H1 合法等待 B；
2. 保持写地址队列为空，在 H1 返回 B 的同一周期提交相同 ID 的 H2 AW；
3. H1 尚未在该时钟沿清除，所以最低空闲写表项是 entry 1，H2 分配到 entry 1；
4. 同 ID B/AW 同周期握手使 wWkVld=1，第 552 行把 entry 1 的 one-hot 值
   4'b0010 写入 wWkEtrReg；
5. 随后继续完成 H2 的 W、下游 AW/W 和 B，保证全部写事务合法收尾。

时钟沿后同时检查 wWkVldReg=1 和 wWkEtrReg=2，可以直接证明第 552 行已经
执行，并且写入的是实际 AW 空闲表项选择结果，而不是寄存器旧值。

十一、测试约束

本用例只通过顶层 io_mst_* / io_slv_* 端口产生激励，不修改、force 或 deposit
DUT 内部信号。内部句柄仅用于读取关键状态并进行自检。所有实际产生的 AR/R
和 AW/W/B 事务均会完整收尾，使公共 monitor 和自动 scoreboard 在 testcase
结束时没有残留项；对于上述四个不可达写分支，只保留分析说明，不产生非法
AW/W/B 激励。
================================================================================
]====]

local clock = dut.clock:chdl()
local core = dut.u_AxiReorder

-- 以下内部信号全部只读，用来证明目标分支确实在预期上升沿成立。
local gen_4 = core["_GEN_4"]:chdl()
local gen_5 = core["_GEN_5"]:chdl()
local layer_probe_5 = core["_layer_probe_5"]:chdl()
local gen_2 = core["_GEN_2"]:chdl()
local gen_3 = core["_GEN_3"]:chdl()
local layer_probe_1 = core["_layer_probe_1"]:chdl()
local gen_6 = core["_GEN_6"]:chdl()
local gen_7 = core["_GEN_7"]:chdl()
local layer_probe_9 = core["_layer_probe_9"]:chdl()
local gen_8 = core["_GEN_8"]:chdl()
local gen_9 = core["_GEN_9"]:chdl()
local layer_probe_13 = core["_layer_probe_13"]:chdl()

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

-- set_imm() 更新端口后，通过只读同步阶段等待连续组合逻辑传播完成。
-- 这里不能使用 await_time_ps(1)：Verilator NORMAL_MODE 可能把时间回调安排到
-- 下一个时步，导致 VALID 意外跨过额外的上升沿并形成重复握手。
local function settle_combination()
    await_rd()
end

-- 上升沿触发后，等待到同一仿真时刻的 read/write 同步阶段。此时 RTL 已经
-- 采样本拍握手，monitor 的上升沿任务也有机会读取旧 VALID；随后可以安全
-- 撤销端口，而不会把 VALID 保持到下一个上升沿。
local function finish_handshake_edge()
    await_rw()
end

local function wait_until_observed(predicate, description)
    for _ = 1, TIMEOUT do
        if predicate() then
            return
        end

        -- 被等待的 valid 在 ready=0 时必须按照 AXI 协议保持，因此即使当前
        -- 调度点恰好位于下降沿，也不会因为等待下一个下降沿而漏掉单拍脉冲。
        wait_negedge()
    end

    assert(false, error_message("timeout waiting for " .. description))
end

-- 固定生成单拍、32-byte、INCR 读请求。地址均按 32 byte 对齐且互不相同，
-- 便于 scoreboard 根据 payload 将上游 AR 与下游重映射 AR 精确配对。
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
    -- 本用例全部是单拍读，因此每个有效 R 响应同时也是末拍。
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
    wait_until_observed(function()
        return dut.io_mst_ar_ready:get() == 1
    end, transaction.name .. " upstream ARREADY")

    -- 等待下一个上升沿完成握手。posedge 返回后进入同一仿真时刻的
    -- read/write 同步阶段，再撤销 VALID；该过程不推进仿真时间。撤销后
    -- 返回下一个下降沿，使后续 helper 始终从可写相位开始驱动端口。
    env.wait_cycles(1)
    finish_handshake_edge()
    clear_mst_ar()
    wait_negedge()
end

-- 完成指定事务的下游 AR 握手，并验证 RTL 产生的重映射 entry ID。下游
-- ARREADY 默认保持为 0，所以 DUT 必须持续保持 ARVALID 和 payload，测试
-- 不会因 Lua 调度顺序错过仅存在一个周期的 ARVALID。
local function accept_slv_ar(transaction, expected_entry)
    wait_until_observed(function()
        return dut.io_slv_ar_valid:get() == 1
    end, transaction.name .. " downstream ARVALID")

    assert(
        dut.io_slv_ar_bits_id:get() == expected_entry,
        error_message(string.format(
            "%s expected entry=%d, actual entry=%s",
            transaction.name,
            expected_entry,
            tostring(dut.io_slv_ar_bits_id:get())
        ))
    )
    assert(
        dut.io_slv_ar_bits_addr:get() == transaction.addr,
        error_message(transaction.name .. " downstream AR address mismatch")
    )

    -- payload 检查通过后才允许请求握手；READY 保持到下一个上升沿，并在
    -- monitor 完成采样后立即撤销，从而每笔 AR 只握手一次。
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

-- 返回一笔普通单拍 R 响应。expected_upstream_id 用来同时检查 ID 恢复。
local function send_r_response(entry, data, resp, expected_upstream_id, description)
    dut.io_mst_r_ready:set_imm(1)
    set_slv_r(entry, data, resp, true)
    settle_combination()

    assert(
        dut.io_slv_r_ready:get() == 1,
        error_message(description .. " downstream RREADY is low")
    )
    assert(
        dut.io_mst_r_valid:get() == 1,
        error_message(description .. " upstream RVALID is low")
    )
    assert(
        dut.io_mst_r_bits_id:get() == expected_upstream_id,
        error_message(description .. " restored upstream RID mismatch")
    )

    env.wait_cycles(1)
    finish_handshake_edge()
    clear_slv_r()
    wait_negedge()
end

-- 以下 helper 用于第 552 行的单拍写事务。与读事务 helper 一样，所有输入
-- 只在下降沿后的可写阶段更新，并在握手上升沿的 read/write 阶段后撤销，
-- 防止 VALID 或 READY 意外跨越额外的时钟沿。
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

-- 接收一笔上游 AW，使写事务分配到 DUT 的写重排表。W 通道必须在 AW
-- 之后单独握手，因为 RTL 使用 wq 将每组 W 数据与已分配表项关联。
local function accept_mst_aw(transaction)
    set_mst_aw(transaction, true)
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
    wait_until_observed(function()
        return dut.io_mst_w_ready:get() == 1
    end, transaction.name .. " upstream WREADY")

    env.wait_cycles(1)
    finish_handshake_edge()
    clear_mst_w()
    wait_negedge()
end

-- 下游 AW 由 awq 严格按上游接收顺序发送。只有队首表项 nid=0 时 AWVALID
-- 才会拉高；这里同时检查重映射 entry ID 和地址，证明响应使用正确映射。
local function accept_slv_aw(transaction, expected_entry)
    wait_until_observed(function()
        return dut.io_slv_aw_valid:get() == 1
    end, transaction.name .. " downstream AWVALID")

    assert(
        dut.io_slv_aw_bits_id:get() == expected_entry,
        error_message(string.format(
            "%s expected write entry=%d, actual entry=%s",
            transaction.name,
            expected_entry,
            tostring(dut.io_slv_aw_bits_id:get())
        ))
    )
    assert(
        dut.io_slv_aw_bits_addr:get() == transaction.addr,
        error_message(transaction.name .. " downstream AW address mismatch")
    )

    dut.io_slv_aw_ready:set_imm(1)
    settle_combination()
    env.wait_cycles(1)
    finish_handshake_edge()
    dut.io_slv_aw_ready:set_imm(0)
    wait_negedge()
end

-- wbitsq 只有在对应 AW 已经向下游握手后才允许 W 出队，因此这个 helper
-- 自然验证 AW 先于 W。数据采用小整数，比较时去掉 256-bit 十六进制前导零。
local function accept_slv_w(transaction)
    wait_until_observed(function()
        return dut.io_slv_w_valid:get() == 1
    end, transaction.name .. " downstream WVALID")

    local actual_data = dut.io_slv_w_bits_data:get_hex_str():lower():gsub("^0+", "")
    local expected_data = string.format("%x", transaction.data)
    assert(
        actual_data == expected_data,
        error_message(transaction.name .. " downstream W data mismatch")
    )
    assert(
        dut.io_slv_w_bits_last:get() == 1,
        error_message(transaction.name .. " downstream WLAST is low")
    )

    dut.io_slv_w_ready:set_imm(1)
    settle_combination()
    env.wait_cycles(1)
    finish_handshake_edge()
    dut.io_slv_w_ready:set_imm(0)
    wait_negedge()
end

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
    assert(
        dut.io_mst_b_bits_id:get() == expected_upstream_id,
        error_message(description .. " restored upstream BID mismatch")
    )

    env.wait_cycles(1)
    finish_handshake_edge()
    clear_slv_b()
    wait_negedge()
end

local function task_line_coverage()
    -- 不启动随机 AXI agent，由 testcase 精确控制读写端口。下游地址和写数据
    -- READY 默认拉低，只在对应 helper 中显式拉高一拍；上游始终接收 R/B。
    driver.drive {
        io_slv_ar_ready = 0,
        io_mst_r_ready = 1,
        io_slv_aw_ready = 0,
        io_slv_w_ready = 0,
        io_mst_b_ready = 1,
    }

    local ID_A = 0x111
    local ID_B = 0x222
    local ID_C = 0x333
    local ID_D = 0x444
    local ID_E = 0x555
    local ID_F = 0x666
    local ID_G = 0x777
    local ID_H = 0x888

    local transaction_b1 = {
        name = "B1(entry0 first predecessor)",
        id = ID_B,
        addr = 0x1000,
    }
    local transaction_a = {
        name = "A(entry1 temporary occupant)",
        id = ID_A,
        addr = 0x2000,
    }
    local transaction_b2 = {
        name = "B2(entry2 second predecessor)",
        id = ID_B,
        addr = 0x3000,
    }
    local transaction_b3 = {
        name = "B3(entry1 target transaction)",
        id = ID_B,
        addr = 0x4000,
    }
    local transaction_d = {
        name = "D(entry0 temporary occupant)",
        id = ID_D,
        addr = 0x5000,
    }
    local transaction_c1 = {
        name = "C1(entry1 first predecessor)",
        id = ID_C,
        addr = 0x6000,
    }
    local transaction_c2 = {
        name = "C2(entry2 second predecessor)",
        id = ID_C,
        addr = 0x7000,
    }
    local transaction_c3 = {
        name = "C3(entry0 target transaction)",
        id = ID_C,
        addr = 0x8000,
    }
    local transaction_e1 = {
        name = "E1(entry0 first predecessor)",
        id = ID_E,
        addr = 0x9000,
    }
    local transaction_e2 = {
        name = "E2(entry1 second predecessor)",
        id = ID_E,
        addr = 0xA000,
    }
    local transaction_e3 = {
        name = "E3(entry2 target transaction)",
        id = ID_E,
        addr = 0xB000,
    }
    local transaction_f1 = {
        name = "F1(entry0 first predecessor)",
        id = ID_F,
        addr = 0xC000,
    }
    local transaction_f2 = {
        name = "F2(entry1 second predecessor)",
        id = ID_F,
        addr = 0xD000,
    }
    local transaction_g = {
        name = "G(entry2 different-ID occupant)",
        id = ID_G,
        addr = 0xE000,
    }
    local transaction_f3 = {
        name = "F3(entry3 target transaction)",
        id = ID_F,
        addr = 0xF000,
    }
    local transaction_h1 = {
        name = "H1(write predecessor in entry0)",
        id = ID_H,
        addr = 0x10000,
        data = 0x1234,
    }
    local transaction_h2 = {
        name = "H2(simultaneously allocated write in entry1)",
        id = ID_H,
        addr = 0x11000,
        data = 0x5678,
    }

    wait_negedge()

    -- B1 先占用 entry 0，A 再占用 entry 1；两者 nid 均为 0，因此正常
    -- 发送 AR。这个顺序很关键：稍后释放 A 时，最低空闲项必须是 entry 1。
    send_read_request(transaction_b1, 0)
    send_read_request(transaction_a, 1)

    -- B2 分配到 entry 2。由于 entry 0 中存在未完成的同 ID B1，B2 的
    -- nid=1，必须等待 B1 完成，所以此处只接收上游 AR，不接收下游 AR。
    accept_mst_ar(transaction_b2)
    assert(
        core.rvld_2:get() == 1 and core.arinfo_2_nid:get() == 1,
        error_message("B2 did not naturally establish entry2 nid=1")
    )
    assert(
        dut.io_slv_ar_valid:get() == 0,
        error_message("B2 AR was sent before B1 completed")
    )

    -- 完成不同 ID 的 A，合法释放 entry 1。entry 0 中的同 ID 前序 B1 必须
    -- 继续保持有效，这样 B3 分配时才能同时看到 B1、B2 两个前序事务。
    send_r_response(1, 0xA0, 0, ID_A, "complete A")
    assert(
        core.rvld_0:get() == 1 and core.rvld_1:get() == 0,
        error_message("A did not release entry1 while B1 remained in entry0")
    )

    -- ====================================================================
    -- 关键周期 1：B3 分配到 entry 1，同时 entry 0 中 B1 返回末拍响应。
    -- ====================================================================
    set_mst_ar(transaction_b3, true)
    dut.io_mst_r_ready:set_imm(1)
    set_slv_r(0, 0xB1, 1, true)
    settle_combination()

    assert(
        dut.io_mst_ar_ready:get() == 1,
        error_message("B3 was not ready for simultaneous allocation")
    )
    assert(
        dut.io_slv_r_ready:get() == 1,
        error_message("B1 response was not ready in simultaneous cycle")
    )
    assert(
        dut.io_mst_r_bits_id:get() == ID_B,
        error_message("B1 response did not restore ID_B")
    )

    -- 下一个上升沿同时产生 mst AR fire 和 slv R fire，建立延迟修正状态。
    env.wait_cycles(1)
    finish_handshake_edge()
    clear_mst_ar()
    clear_slv_r()
    wait_negedge()

    -- B3 分配时看到了 B1、B2 两个未完成同 ID 项，因此 rawRNid 必须为 2；
    -- 同周期完成 B1 后，rWkEtrReg 必须以 bit 1 记录目标 entry 1。
    assert(
        core.rvld_1:get() == 1 and core.arinfo_1_nid:get() == 2,
        error_message("B3 did not enter entry1 with nid=2")
    )
    assert(
        core.rWkVldReg:get() == 1 and core.rWkEtrReg:get() == 2,
        error_message("simultaneous B3 allocation/B1 response did not set rWk entry1")
    )

    -- B1 已完成，B2 的 nid 已降到 0，此时 B2 应在下游 AR 端口有效并选择
    -- entry 2。当前 ARREADY 仍为 0，所以 B2 的 AR 会稳定停在端口上；随后
    -- 同时拉高 ARREADY 和 RVALID，构造合法的零周期响应。
    assert(
        dut.io_slv_ar_valid:get() == 1 and
        dut.io_slv_ar_bits_id:get() == 2 and
        dut.io_slv_ar_bits_addr:get() == transaction_b2.addr,
        error_message("B2 was not selected for downstream AR after B1 completion")
    )

    -- ====================================================================
    -- 关键周期 2：B2 的 AR 与 R 同周期握手，命中目标减 2 分支。
    -- ====================================================================
    set_slv_ar_ready(1)
    set_slv_r(2, 0xB2, 2, true)
    settle_combination()

    -- 当前 B2 响应贡献 _GEN_4；上一周期保存的 entry1 修正贡献 _GEN_5。
    -- 三个断言均成立时，下一个上升沿必然执行目标 RTL 行。
    assert(gen_4:get() == 1, error_message("_GEN_4 is not asserted"))
    assert(gen_5:get() == 1, error_message("_GEN_5 is not asserted"))
    assert(
        layer_probe_5:get() == 1,
        error_message("_layer_probe_5 is not asserted before target edge")
    )
    assert(
        dut.io_slv_ar_ready:get() == 1 and dut.io_slv_r_ready:get() == 1,
        error_message("B2 zero-latency AR/R channels are not both ready")
    )

    env.wait_cycles(1)
    finish_handshake_edge()
    clear_slv_r()
    set_slv_ar_ready(0)
    wait_negedge()

    -- 目标行应把 entry 1 中 B3 的 nid 从 2 一次减到 0，而不是只减到 1。
    assert(
        core.arinfo_1_nid:get() == 0,
        error_message(string.format(
            "target nid-2 update failed: entry1 nid=%s",
            tostring(core.arinfo_1_nid:get())
        ))
    )
    print_message(
        "Covered AxiReorder.sv:433; arinfo_1_nid changed 2 -> 0"
    )

    -- B3 已无同 ID 前序依赖，现在合法发送 entry 1 的下游 AR。
    accept_slv_ar(transaction_b3, 1)

    -- 完成 B3，清空最后一个事务，确保公共 scoreboard 收尾检查通过。
    send_r_response(1, 0xB3, 3, ID_B, "complete B3")

    -- ====================================================================
    -- entry 0 场景：重新构造表项布局
    -- ====================================================================

    -- D 先占用 entry 0，C1 再占用 entry 1，并分别正常发送下游 AR。
    -- C2 随后占用 entry 2；因为 C1 是未完成的同 ID 前序事务，C2 自然
    -- 得到 nid=1，只进入重排表而暂时不能向下游发送。
    send_read_request(transaction_d, 0)
    send_read_request(transaction_c1, 1)
    accept_mst_ar(transaction_c2)
    assert(
        core.rvld_2:get() == 1 and core.arinfo_2_nid:get() == 1,
        error_message("C2 did not naturally establish entry2 nid=1")
    )
    assert(
        dut.io_slv_ar_valid:get() == 0,
        error_message("C2 AR was sent before C1 completed")
    )

    -- D 与 ID_C 不同，完成 D 只释放 entry 0，不会改变 C1/C2 的同 ID
    -- 依赖关系。释放后 entry 0 是最低空闲项，下一笔 C3 必然分配到这里。
    send_r_response(0, 0xD0, 0, ID_D, "complete D")
    assert(
        core.rvld_0:get() == 0 and core.rvld_1:get() == 1,
        error_message("D did not release entry0 while C1 remained in entry1")
    )

    -- ====================================================================
    -- entry 0 关键周期 1：C3 分配到 entry 0，同时 C1 返回末拍响应。
    -- ====================================================================
    set_mst_ar(transaction_c3, true)
    dut.io_mst_r_ready:set_imm(1)
    set_slv_r(1, 0xC1, 1, true)
    settle_combination()

    assert(
        dut.io_mst_ar_ready:get() == 1,
        error_message("C3 was not ready for simultaneous allocation")
    )
    assert(
        dut.io_slv_r_ready:get() == 1,
        error_message("C1 response was not ready in simultaneous cycle")
    )
    assert(
        dut.io_mst_r_valid:get() == 1 and dut.io_mst_r_bits_id:get() == ID_C,
        error_message("C1 response did not restore ID_C")
    )

    -- 该上升沿同时产生 mst AR fire 和 slv R fire：C3 读取旧状态中的
    -- C1/C2，装载 rawRNid=2；同时 RTL 为新分配的 entry 0 保存延迟修正。
    env.wait_cycles(1)
    finish_handshake_edge()
    clear_mst_ar()
    clear_slv_r()
    wait_negedge()

    assert(
        core.rvld_0:get() == 1 and core.arinfo_0_nid:get() == 2,
        error_message("C3 did not enter entry0 with nid=2")
    )
    assert(
        core.rWkVldReg:get() == 1 and core.rWkEtrReg:get() == 1,
        error_message("simultaneous C3 allocation/C1 response did not set rWk entry0")
    )

    -- C1 完成已经把 C2 的 nid 从 1 降为 0，因此 C2 此时必须以 entry 2
    -- 出现在下游 AR 端口。READY 仍为 0，ARVALID 和 payload 会稳定保持。
    assert(
        dut.io_slv_ar_valid:get() == 1 and
        dut.io_slv_ar_bits_id:get() == 2 and
        dut.io_slv_ar_bits_addr:get() == transaction_c2.addr,
        error_message("C2 was not selected for downstream AR after C1 completion")
    )

    -- ====================================================================
    -- entry 0 关键周期 2：C2 的 AR 与 R 同周期握手，命中目标减 2 分支。
    -- ====================================================================
    set_slv_ar_ready(1)
    set_slv_r(2, 0xC2, 2, true)
    settle_combination()

    -- _GEN_2 来自当前 C2 的末拍响应；_GEN_3 来自上一周期记录在
    -- rWkEtrReg[0] 中的修正。三个条件在时钟沿前均为 1，证明目标行可达。
    assert(gen_2:get() == 1, error_message("_GEN_2 is not asserted"))
    assert(gen_3:get() == 1, error_message("_GEN_3 is not asserted"))
    assert(
        layer_probe_1:get() == 1,
        error_message("_layer_probe_1 is not asserted before target edge")
    )
    assert(
        dut.io_slv_ar_ready:get() == 1 and dut.io_slv_r_ready:get() == 1,
        error_message("C2 zero-latency AR/R channels are not both ready")
    )

    env.wait_cycles(1)
    finish_handshake_edge()
    clear_slv_r()
    set_slv_ar_ready(0)
    wait_negedge()

    -- 若 RTL 执行的是普通减 1 分支，此处 nid 会等于 1；检查等于 0 可以
    -- 直接区分并证明 arinfo_0_nid <= arinfo_0_nid - 2'h2 已经执行。
    assert(
        core.arinfo_0_nid:get() == 0,
        error_message(string.format(
            "entry0 target nid-2 update failed: nid=%s",
            tostring(core.arinfo_0_nid:get())
        ))
    )
    print_message(
        "Covered AxiReorder.sv:414; arinfo_0_nid changed 2 -> 0"
    )

    -- C3 的依赖已经全部解除，最后发送并完成 C3，清空 entry 0。
    accept_slv_ar(transaction_c3, 0)
    send_r_response(0, 0xC3, 3, ID_C, "complete C3")

    -- ====================================================================
    -- entry 2 场景：两笔同 ID 前序事务占用 entry 0/1
    -- ====================================================================

    -- E1 作为第一笔同 ID 事务占用 entry 0，nid=0，可以正常发送下游 AR。
    -- E2 随后占用 entry 1；它能看到未完成的 E1，因此 nid=1，只接收上游
    -- AR，不允许提前向下游发送。此时 entry 2 保持空闲，留给目标事务 E3。
    send_read_request(transaction_e1, 0)
    accept_mst_ar(transaction_e2)
    assert(
        core.rvld_1:get() == 1 and core.arinfo_1_nid:get() == 1,
        error_message("E2 did not naturally establish entry1 nid=1")
    )
    assert(
        core.rvld_2:get() == 0 and dut.io_slv_ar_valid:get() == 0,
        error_message("entry2 was not free or E2 AR was sent before E1 completed")
    )

    -- ====================================================================
    -- entry 2 关键周期 1：E3 分配到 entry 2，同时 E1 返回末拍响应。
    -- ====================================================================
    set_mst_ar(transaction_e3, true)
    dut.io_mst_r_ready:set_imm(1)
    set_slv_r(0, 0xE1, 1, true)
    settle_combination()

    assert(
        dut.io_mst_ar_ready:get() == 1,
        error_message("E3 was not ready for simultaneous allocation")
    )
    assert(
        dut.io_slv_r_ready:get() == 1,
        error_message("E1 response was not ready in simultaneous cycle")
    )
    assert(
        dut.io_mst_r_valid:get() == 1 and dut.io_mst_r_bits_id:get() == ID_E,
        error_message("E1 response did not restore ID_E")
    )

    -- 该沿之前 E1/E2 都有效且 ID 与 E3 相同，因此 E3 的 rawRNid=2；
    -- 同周期的 E1 响应则把“少算一次完成”的修正记录到 entry 2 对应位。
    env.wait_cycles(1)
    finish_handshake_edge()
    clear_mst_ar()
    clear_slv_r()
    wait_negedge()

    assert(
        core.rvld_2:get() == 1 and core.arinfo_2_nid:get() == 2,
        error_message("E3 did not enter entry2 with nid=2")
    )
    assert(
        core.rWkVldReg:get() == 1 and core.rWkEtrReg:get() == 4,
        error_message("simultaneous E3 allocation/E1 response did not set rWk entry2")
    )

    -- E1 完成后，E2 的 nid 已从 1 降到 0，应当稳定出现在下游 AR 端口。
    assert(
        dut.io_slv_ar_valid:get() == 1 and
        dut.io_slv_ar_bits_id:get() == 1 and
        dut.io_slv_ar_bits_addr:get() == transaction_e2.addr,
        error_message("E2 was not selected for downstream AR after E1 completion")
    )

    -- ====================================================================
    -- entry 2 关键周期 2：E2 的 AR 与 R 同周期握手，命中 RTL 第 452 行。
    -- ====================================================================
    set_slv_ar_ready(1)
    set_slv_r(1, 0xE2, 2, true)
    settle_combination()

    -- _GEN_6 表示当前完成的是 entry 2 目标事务的同 ID 前序响应；_GEN_7
    -- 表示上一周期的延迟修正属于 entry 2。两者同时为 1 才会走减 2 分支。
    assert(gen_6:get() == 1, error_message("_GEN_6 is not asserted"))
    assert(gen_7:get() == 1, error_message("_GEN_7 is not asserted"))
    assert(
        layer_probe_9:get() == 1,
        error_message("_layer_probe_9 is not asserted before target edge")
    )
    assert(
        dut.io_slv_ar_ready:get() == 1 and dut.io_slv_r_ready:get() == 1,
        error_message("E2 zero-latency AR/R channels are not both ready")
    )

    env.wait_cycles(1)
    finish_handshake_edge()
    clear_slv_r()
    set_slv_ar_ready(0)
    wait_negedge()

    -- 第 452 行执行后 nid 必须从 2 直接变为 0；若只走普通减 1 分支，
    -- 此处将得到 1，因此该检查能明确区分实际执行的是哪一条 RTL。
    assert(
        core.arinfo_2_nid:get() == 0,
        error_message(string.format(
            "entry2 target nid-2 update failed: nid=%s",
            tostring(core.arinfo_2_nid:get())
        ))
    )
    print_message(
        "Covered AxiReorder.sv:452; arinfo_2_nid changed 2 -> 0"
    )

    -- E3 依赖解除后正常发送 entry 2 的下游 AR，并返回响应清空最后表项。
    accept_slv_ar(transaction_e3, 2)
    send_r_response(2, 0xE3, 3, ID_E, "complete E3")

    -- ====================================================================
    -- entry 3 场景：entry 0/1 放同 ID 前序，entry 2 放不同 ID 占位
    -- ====================================================================

    -- F1 占用 entry 0 并正常发送 AR。F2 随后占用 entry 1，因为存在未完成
    -- 的同 ID F1，所以 F2 的 nid=1，只进入重排表而不发送下游 AR。
    send_read_request(transaction_f1, 0)
    accept_mst_ar(transaction_f2)
    assert(
        core.rvld_1:get() == 1 and core.arinfo_1_nid:get() == 1,
        error_message("F2 did not naturally establish entry1 nid=1")
    )
    assert(
        dut.io_slv_ar_valid:get() == 0,
        error_message("F2 AR was sent before F1 completed")
    )

    -- G 使用不同的 ID，占用 entry 2 但不增加 F3 的 rawRNid。G 的 nid=0，
    -- 先把它的下游 AR 正常发送，避免它在后续关键周期与 F2 争用 AR 通道。
    send_read_request(transaction_g, 2)
    assert(
        core.rvld_0:get() == 1 and
        core.rvld_1:get() == 1 and
        core.rvld_2:get() == 1 and
        core.rvld_3:get() == 0,
        error_message("entry0/1/2 occupancy for entry3 scenario is incorrect")
    )

    -- ====================================================================
    -- entry 3 关键周期 1：F3 分配到 entry 3，同时 F1 返回末拍响应。
    -- ====================================================================
    set_mst_ar(transaction_f3, true)
    dut.io_mst_r_ready:set_imm(1)
    set_slv_r(0, 0xF1, 1, true)
    settle_combination()

    assert(
        dut.io_mst_ar_ready:get() == 1,
        error_message("F3 was not ready for simultaneous allocation")
    )
    assert(
        dut.io_slv_r_ready:get() == 1,
        error_message("F1 response was not ready in simultaneous cycle")
    )
    assert(
        dut.io_mst_r_valid:get() == 1 and dut.io_mst_r_bits_id:get() == ID_F,
        error_message("F1 response did not restore ID_F")
    )

    -- 分配沿之前四个表项中只有 F1/F2 与 F3 同 ID，所以 F3 精确装载
    -- rawRNid=2；同沿 F1 响应则把延迟修正记录到新分配的 entry 3。
    env.wait_cycles(1)
    finish_handshake_edge()
    clear_mst_ar()
    clear_slv_r()
    wait_negedge()

    assert(
        core.rvld_3:get() == 1 and core.arinfo_3_nid:get() == 2,
        error_message("F3 did not enter entry3 with nid=2")
    )
    assert(
        core.rWkVldReg:get() == 1 and core.rWkEtrReg:get() == 8,
        error_message("simultaneous F3 allocation/F1 response did not set rWk entry3")
    )

    -- F1 完成后 F2 的 nid 已经变为 0；G 的 AR 之前已经发送，因此当前
    -- 下游 AR 选择必须是 entry 1 中的 F2。
    assert(
        dut.io_slv_ar_valid:get() == 1 and
        dut.io_slv_ar_bits_id:get() == 1 and
        dut.io_slv_ar_bits_addr:get() == transaction_f2.addr,
        error_message("F2 was not selected for downstream AR after F1 completion")
    )

    -- ====================================================================
    -- entry 3 关键周期 2：F2 的 AR 与 R 同周期握手，命中 RTL 第 471 行。
    -- ====================================================================
    set_slv_ar_ready(1)
    set_slv_r(1, 0xF2, 2, true)
    settle_combination()

    -- _GEN_8 来自当前 F2 的同 ID 末拍响应；_GEN_9 来自上一周期保存在
    -- rWkEtrReg[3] 的修正。两者同时为 1 时，entry 3 必须执行减 2 分支。
    assert(gen_8:get() == 1, error_message("_GEN_8 is not asserted"))
    assert(gen_9:get() == 1, error_message("_GEN_9 is not asserted"))
    assert(
        layer_probe_13:get() == 1,
        error_message("_layer_probe_13 is not asserted before target edge")
    )
    assert(
        dut.io_slv_ar_ready:get() == 1 and dut.io_slv_r_ready:get() == 1,
        error_message("F2 zero-latency AR/R channels are not both ready")
    )

    env.wait_cycles(1)
    finish_handshake_edge()
    clear_slv_r()
    set_slv_ar_ready(0)
    wait_negedge()

    -- 第 471 行执行后 entry 3 的 nid 应从 2 直接降到 0；如果只执行普通
    -- 减 1 分支，该值会是 1，因此此断言可以明确证明目标行已经执行。
    assert(
        core.arinfo_3_nid:get() == 0,
        error_message(string.format(
            "entry3 target nid-2 update failed: nid=%s",
            tostring(core.arinfo_3_nid:get())
        ))
    )
    print_message(
        "Covered AxiReorder.sv:471; arinfo_3_nid changed 2 -> 0"
    )

    -- F3 已解除全部同 ID 依赖，先发送它的下游 AR。最后分别完成不同 ID
    -- 占位事务 G 和目标事务 F3，确保 testcase 结束时没有残留读事务。
    accept_slv_ar(transaction_f3, 3)
    send_r_response(2, 0xA2, 0, ID_G, "complete G")
    send_r_response(3, 0xF3, 3, ID_F, "complete F3")

    -- ====================================================================
    -- 写路径第 552 行：同 ID 的 B 与新 AW 在同一周期握手
    -- ====================================================================

    -- H1 完整通过上游 AW/W 和下游 AW/W，此时 entry 0 保持有效、nid=0，
    -- 下游已经具备返回合法 B 响应的全部条件，且 awq/wq/wbitsq 均已排空。
    send_write_request(transaction_h1, 0)
    assert(
        core.wvld_0:get() == 1 and
        core.awinfo_0_nid:get() == 0 and
        core.awinfo_0_haveSendAW:get() == 1,
        error_message("H1 did not become a completed downstream write in entry0")
    )

    -- H1 仍占用 entry 0，所以同周期提交的 H2 会选择最低空闲 entry 1。
    -- H1 的 B 与 H2 的 AW ID 相同，组合条件 wWkVld 必须成立；第 552 行
    -- 因而在该上升沿把 entry 1 的 one-hot 选择值 2 写入 wWkEtrReg。
    set_mst_aw(transaction_h2, true)
    dut.io_mst_b_ready:set_imm(1)
    set_slv_b(0, 1, true)
    settle_combination()

    assert(
        dut.io_mst_aw_ready:get() == 1,
        error_message("H2 AW was not ready in simultaneous AW/B cycle")
    )
    assert(
        dut.io_slv_b_ready:get() == 1 and dut.io_mst_b_valid:get() == 1,
        error_message("H1 B was not ready/valid in simultaneous AW/B cycle")
    )
    assert(
        dut.io_mst_b_bits_id:get() == ID_H,
        error_message("H1 B did not restore ID_H")
    )

    env.wait_cycles(1)
    finish_handshake_edge()
    clear_mst_aw()
    clear_slv_b()
    wait_negedge()

    -- wWkVldReg 是 wWkVld 的一拍寄存结果；它等于 1 且 wWkEtrReg 等于
    -- entry 1 的 one-hot 值 2，直接证明第 552 行在刚才的时钟沿执行。
    assert(
        core.wWkVldReg:get() == 1 and core.wWkEtrReg:get() == 2,
        error_message(string.format(
            "line 552 update failed: wWkVldReg=%s wWkEtrReg=%s",
            tostring(core.wWkVldReg:get()),
            tostring(core.wWkEtrReg:get())
        ))
    )
    assert(
        core.wvld_0:get() == 0 and
        core.wvld_1:get() == 1 and
        core.awinfo_1_nid:get() == 1,
        error_message("simultaneous H1 completion/H2 allocation state is incorrect")
    )
    print_message("Covered AxiReorder.sv:552; wWkEtrReg changed to 0x2")

    -- 下一上升沿由 wWkVldReg/wWkEtrReg[1] 对 H2 执行一次延迟修正，
    -- 将分配时多统计的 H1 从 nid 中扣除，使 H2 的 nid 从 1 变为 0。
    env.wait_cycles(1)
    finish_handshake_edge()
    wait_negedge()
    assert(
        core.awinfo_1_nid:get() == 0,
        error_message("H2 delayed write nid correction did not change 1 -> 0")
    )

    -- H2 的 AW 已在关键周期进入 awq，下面补齐它的 W、下游 AW/W 和 B。
    -- 所有握手均按 AXI 顺序完成，公共 scoreboard 最终不会留下写事务。
    accept_mst_w(transaction_h2)
    accept_slv_aw(transaction_h2, 1)
    accept_slv_w(transaction_h2)
    send_b_response(1, 2, ID_H, "complete H2")

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

    print_message("012 line coverage testcase completed successfully")
end

return {
    tasks = {
        task_line_coverage,
    },
}
