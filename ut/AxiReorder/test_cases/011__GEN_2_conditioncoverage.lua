local env = require "env"
local driver = require "dut.driver"

--[====[
================================================================================
011__GEN_2_conditioncoverage.lua
================================================================================

一、目标表达式

本用例定向覆盖 AxiReorder 中的以下条件表达式：

    _GEN_2 =
        (|arinfo_0_nid) &
        _rFireSlvHit_T_12 &
        (_GEN[slvRHitEtr] == arinfo_0_bits_id) &
        rvld_0 &
        io_slv_r_bits_last;

VCS/Verdi 将五个子条件依次编号为：

    C1 = |arinfo_0_nid
    C2 = io_mst_r_ready & io_slv_r_valid
    C3 = _GEN[io_slv_r_bits_id[1:0]] == arinfo_0_bits_id
    C4 = rvld_0
    C5 = io_slv_r_bits_last

二、不可达组合 C1=1、C2=1、C3=1、C4=0、C5=1

本用例只允许驱动 AxiReorder 的顶层 AXI 端口，绝不修改、force 或 deposit
DUT 内部寄存器。在这个限制下，Verdi 表中的下面一行无法通过合法事务产生：

    C1 C2 C3 C4 C5 = 1 1 1 0 1

原因来自 rvld_0 与 arinfo_0_nid 的状态关系：

1. arinfo_0_nid 只在新的 AR 请求分配到 entry 0 时装载。它记录分配瞬间已经
   存在的同 ID 未完成事务数。

2. 同一次 entry 0 分配会把 rvld_0 置为 1。因此，只要通过正常分配得到了
   arinfo_0_nid>0，同一表项的 rvld_0 就必然有效。

3. entry 0 的 nid 会随着前序同 ID 事务的末拍 R 响应逐次递减。只有所有前序
   事务完成、nid 降到 0 后，该 entry 保存的 AR 才允许发送到下游。

4. 合法下游不可能在该 AR 尚未发送时返回它的 R 响应。entry 0 只有在自己的
   末拍 R 真正握手后才会清除 rvld_0，而此时 nid 已经是 0。

由此得到合法状态不变量：

    arinfo_0_nid != 0  ==>  rvld_0 == 1

也就是说 C1=1 与 C4=0 互斥。若强行命中该行，只能直接篡改内部寄存器，或从
下游注入一个没有对应已发送 AR 的非法 R 响应；两种做法都会破坏测试的协议
语义。本用例不采用这些做法，而是覆盖其余所有可达行，并在代码中明确记录该
不可达项。覆盖率签核时应对 C4 独立翻转行设置 exclusion/waiver，而不应伪造
端口事务。

三、可达组合与端口事务构造

为了让 entry 0 自然得到 nid=1，本用例按以下顺序发送读请求：

    A(ID_A) -> entry 0，单拍
    B(ID_B) -> entry 1，两拍
    C(ID_C) -> entry 2，单拍

先完成 A，释放 entry 0；此时 B 仍未完成。再提交与 B 相同 ID 的请求 B2，
B2 会由最低空闲表项选择逻辑分配到 entry 0，并自然得到 nid=1。随后：

    * 完成 C，命中 1 1 0 1 1（C3 单独为 0）；
    * 返回 B 的第一拍，命中 1 1 1 1 0（C5 单独为 0）；
    * 返回 B 的末拍但令上游 RREADY=0，命中 1 0 1 1 1（C2 单独为 0）；
    * 解除背压并完成该末拍，命中 1 1 1 1 1（_GEN_2=1）。

完成 A 时还会命中 0 1 1 1 1（C1 单独为 0）。全部激励都来自顶层
io_mst_* / io_slv_* 端口，并遵守 AXI valid/ready 与同 ID 响应顺序。
================================================================================
]====]

local clock = dut.clock:chdl()
local core = dut.u_AxiReorder

-- 这些内部句柄只用于读取覆盖条件并做运行时自检。
-- 本文件中所有 :set() 调用的目标均为顶层 io_mst_* 或 io_slv_* 端口。
local gen_2 = core["_GEN_2"]:chdl()

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

local function bit(value)
    return value and 1 or 0
end

local function format_conditions(c)
    return string.format(
        "C1..C5=%d%d%d%d%d",
        c[1], c[2], c[3], c[4], c[5]
    )
end

-- testcase 始终在下降沿修改端口，使 payload 在下一个上升沿握手前稳定半拍。
local function wait_negedge()
    clock:negedge()
end

-- 在下降沿轮询一个端口条件。每轮至少经过一个有效上升沿，避免零时间死循环。
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

-- 只读取目标表达式的五个实际子条件。
local function sample_conditions()
    return {
        bit(core.arinfo_0_nid:get() ~= 0),
        bit(
            dut.io_mst_r_ready:get() == 1 and
            dut.io_slv_r_valid:get() == 1
        ),
        bit(
            dut.io_mst_r_bits_id:get() ==
            core.arinfo_0_bits_id:get()
        ),
        bit(core.rvld_0:get() == 1),
        bit(dut.io_slv_r_bits_last:get() == 1),
    }
end

local function check_condition_vector(expected, description)
    -- set_imm() 能立即更新被驱动的端口，但由这些端口经过连续赋值得到的
    -- _rFireSlvHit_T_12、io_mst_r_bits_id 和 _GEN_2 仍需要一个调度阶段才能
    -- 完成传播。等待 1 ps 远小于半个时钟周期，不会跨过下一个上升沿或形成
    -- 额外握手，只用于消除“源条件已更新、派生 wire 仍是旧值”的零时间竞态。
    await_time_ps(1)

    local actual = sample_conditions()

    for index = 1, 5 do
        assert(
            actual[index] == expected[index],
            error_message(string.format(
                "%s condition %d mismatch: expected %s, actual %s",
                description,
                index,
                format_conditions(expected),
                format_conditions(actual)
            ))
        )
    end

    local expected_gen_2 =
        expected[1] * expected[2] * expected[3] *
        expected[4] * expected[5]

    assert(
        gen_2:get() == expected_gen_2,
        error_message(string.format(
            "%s _GEN_2 mismatch: expected=%d actual=%s",
            description,
            expected_gen_2,
            tostring(gen_2:get())
        ))
    )

    print(string.format(
        "covered %-34s -> %s, _GEN_2=%d",
        description,
        format_conditions(actual),
        expected_gen_2
    ))
end

-- 固定使用合法、简单的 INCR read。各事务地址唯一，便于自动 scoreboard
-- 在上游 AR 与下游重映射后的 AR 之间进行精确匹配。
local function set_mst_ar(transaction, valid)
    dut.io_mst_ar_valid:set(valid and 1 or 0)
    dut.io_mst_ar_bits_id:set(transaction.id)
    dut.io_mst_ar_bits_addr:set(transaction.addr)
    dut.io_mst_ar_bits_len:set(transaction.len)
    dut.io_mst_ar_bits_size:set(transaction.size)
    dut.io_mst_ar_bits_burst:set(1)
    dut.io_mst_ar_bits_lock:set(0)
    dut.io_mst_ar_bits_cache:set(0)
    dut.io_mst_ar_bits_prot:set(0)
    dut.io_mst_ar_bits_qos:set(0)
    dut.io_mst_ar_bits_region:set(0)
end

local function clear_mst_ar()
    dut.io_mst_ar_valid:set(0)
end

-- 将一笔上游 AR 接收到重排表。函数进入和退出时均处于下降沿附近。
local function accept_mst_ar(transaction)
    set_mst_ar(transaction, true)

    wait_until_negedge(function()
        return dut.io_mst_ar_ready:get() == 1
    end, transaction.name .. " upstream ARREADY")

    -- valid/ready 已经稳定，在下一个上升沿形成上游 AR 握手。
    env.wait_cycles(1)
    wait_negedge()
    clear_mst_ar()
end

-- 等待某笔已分配 AR 向下游发送，并检查 DUT 产生的 2-bit 重映射 ID。
local function accept_slv_ar(transaction, expected_entry)
    wait_until_negedge(function()
        return dut.io_slv_ar_valid:get() == 1
    end, transaction.name .. " downstream ARVALID")

    assert(
        dut.io_slv_ar_bits_id:get() == expected_entry,
        error_message(string.format(
            "%s expected downstream entry %d, actual %s",
            transaction.name,
            expected_entry,
            tostring(dut.io_slv_ar_bits_id:get())
        ))
    )
    assert(
        dut.io_slv_ar_bits_addr:get() == transaction.addr,
        error_message(transaction.name .. " downstream AR address mismatch")
    )
    assert(
        dut.io_slv_ar_bits_len:get() == transaction.len,
        error_message(transaction.name .. " downstream AR length mismatch")
    )

    -- io_slv_ar_ready 在整个用例中保持为 1，所以下一个上升沿完成握手。
    env.wait_cycles(1)
    wait_negedge()
end

local function send_read_request(transaction, expected_entry)
    accept_mst_ar(transaction)
    accept_slv_ar(transaction, expected_entry)
end

local function clear_slv_r()
    dut.io_slv_r_valid:set_imm(0)
    dut.io_slv_r_bits_id:set_imm(0)
    dut.io_slv_r_bits_data:set_imm(0)
    dut.io_slv_r_bits_resp:set_imm(0)
    dut.io_slv_r_bits_last:set_imm(0)
end

-- 在下游 R 端口放置一拍响应。这里仅驱动端口，不访问内部状态。
local function set_slv_r(entry, data, resp, last)
    -- 紧随其后的覆盖自检会在同一个调度片读取这些端口，因此必须使用
    -- set_imm() 立即提交，避免普通 set() 的延迟写入让自检读到旧值。
    dut.io_slv_r_valid:set_imm(1)
    dut.io_slv_r_bits_id:set_imm(entry)
    dut.io_slv_r_bits_data:set_imm(data)
    dut.io_slv_r_bits_resp:set_imm(resp)
    dut.io_slv_r_bits_last:set_imm(last and 1 or 0)
end

-- 发送一拍能够立即握手的 R 响应，并在握手前检查目标条件组合。
local function send_r_beat(entry, data, resp, last, expected, description)
    dut.io_mst_r_ready:set_imm(1)
    set_slv_r(entry, data, resp, last)

    assert(
        dut.io_slv_r_ready:get() == 1,
        error_message(description .. " downstream RREADY was not asserted")
    )
    check_condition_vector(expected, description)

    env.wait_cycles(1)
    wait_negedge()
    clear_slv_r()
end

local function task_gen_2_condition_coverage()
    -- 不启动随机 AXI agent，由 testcase 直接驱动所有顶层端口，确保 entry
    -- 分配、R 通道背压和每一拍 RLAST 的时序完全确定。
    driver.drive {
        io_slv_ar_ready = 1,
        io_mst_r_ready = 1,
    }

    -- 三个不同的 ID 用于建立 entry 0/1/2；B2 与 B 使用同一个 ID，以自然
    -- 生成同 ID 依赖。size=5 表示每拍 32 byte，所有地址均按 32 byte 对齐。
    local transaction_a = {
        name = "A(entry0 blocker)",
        id = 0x101,
        addr = 0x1000,
        len = 0,
        size = 5,
    }
    local transaction_b = {
        name = "B(entry1 predecessor)",
        id = 0x202,
        addr = 0x2000,
        len = 1,
        size = 5,
    }
    local transaction_c = {
        name = "C(entry2 different ID)",
        id = 0x303,
        addr = 0x3000,
        len = 0,
        size = 5,
    }
    local transaction_b2 = {
        name = "B2(entry0 dependent)",
        id = transaction_b.id,
        addr = 0x4000,
        len = 0,
        size = 5,
    }

    wait_negedge()

    -- A/B/C 依次占用 entry 0/1/2，并全部完成下游 AR 握手。
    send_read_request(transaction_a, 0)
    send_read_request(transaction_b, 1)
    send_read_request(transaction_c, 2)

    -- A 的末拍响应命中 C1=0，其余条件均为 1。该响应合法释放 entry 0。
    send_r_beat(
        0, 0xA0, 0, true,
        {0, 1, 1, 1, 1},
        "C1=0, other reachable conditions=1"
    )

    -- entry 0 已空闲，但 entry 1 中相同 ID 的 B 仍未完成。B2 因此分配到
    -- entry 0，并自然得到 nid=1。nid 非零时 B2 不能向下游发送 AR。
    accept_mst_ar(transaction_b2)
    assert(
        dut.io_slv_ar_valid:get() == 0,
        error_message("B2 AR was sent before its same-ID predecessor completed")
    )
    assert(
        core.arinfo_0_nid:get() == 1 and core.rvld_0:get() == 1,
        error_message(
            "B2 did not naturally establish entry0 nid=1 and rvld_0=1"
        )
    )

    -- 返回不同 ID 的 C。slv RID=2 选择 entry 2，恢复出的 ID_C 不等于
    -- entry 0 中 B2 保存的 ID_B，因此只让 C3 为 0。
    send_r_beat(
        2, 0xC0, 2, true,
        {1, 1, 0, 1, 1},
        "C3=0, other reachable conditions=1"
    )

    -- B 是两拍 burst。第一拍使用 RLAST=0，其他条件保持为 1，命中 C5=0。
    send_r_beat(
        1, 0xB0, 1, false,
        {1, 1, 1, 1, 0},
        "C5=0, other reachable conditions=1"
    )

    -- 放置 B 的末拍，但先拉低上游 RREADY。AXI 要求 valid=1 且 ready=0
    -- 时保持 RID/RDATA/RRESP/RLAST 稳定；该合法背压周期命中 C2=0。
    dut.io_mst_r_ready:set_imm(0)
    set_slv_r(1, 0xB1, 1, true)
    check_condition_vector(
        {1, 0, 1, 1, 1},
        "C2=0, other reachable conditions=1"
    )

    -- 跨过一个上升沿但不握手，使 C2=0 组合保持完整一个周期。
    env.wait_cycles(1)
    wait_negedge()
    assert(
        dut.io_slv_r_valid:get() == 1 and
        dut.io_slv_r_bits_id:get() == 1 and
        dut.io_slv_r_bits_last:get() == 1,
        error_message("backpressured B final R beat did not remain stable")
    )

    -- 解除背压，同一个稳定末拍现在命中全 1，_GEN_2 必须变为 1。
    dut.io_mst_r_ready:set_imm(1)
    check_condition_vector(
        {1, 1, 1, 1, 1},
        "all reachable conditions=1"
    )
    env.wait_cycles(1)
    wait_negedge()
    clear_slv_r()

    -- B 的末拍完成后，B2 的 nid 降到 0，可以合法发送此前阻塞的 AR。
    accept_slv_ar(transaction_b2, 0)

    -- 完成 B2，清空最后一个读事务，保证自动 scoreboard 收尾无残留。
    send_r_beat(
        0, 0xB2, 0, true,
        {0, 1, 1, 1, 1},
        "B2 cleanup response"
    )

    dut.io_mst_r_ready:set_imm(0)
    clear_mst_ar()
    clear_slv_r()

    -- 给 monitor 一个周期处理最后一次握手，随后 tc_main 会调用
    -- scoreboard.finish_auto_check() 检查所有 AR/R 事务均已匹配完成。
    env.wait_cycles(1)

    print_message(
        "All reachable _GEN_2 condition vectors were driven through AXI ports; " ..
        "C1=1/C4=0 is documented as unreachable"
    )
end

return {
    tasks = {
        task_gen_2_condition_coverage,
    },
}
