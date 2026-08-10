local g = tspace.new_group("功能测试点")

g:with_tp "AXI" "Write" "SameID" "AWIssueOrder" {
    cond = "至少两笔相同 AWID 的合法写事务同时在途，前序事务尚未返回 B 响应",
    check = "后一笔事务不得先于前一笔完成下游 AW 握手",

    test_type = {
        stimulus = "CRV",
        check_type = "Chk",
    },

    priority = "P1",
    test_case = "002_same_id_write",
}

g:with_tp "AXI" "Write" "SameID" "BResponseOrder" {
    cond = "至少两笔相同 AWID 的合法写事务同时在途",
    check = "上游 B 响应顺序与该 AWID 的 AW 接收顺序一致",

    test_type = {
        stimulus = "CRV",
        check_type = "Chk",
    },

    priority = "P1",
    test_case = "002_same_id_write",
}

g:with_tp "AXI" "Write" "DifferentID" "OutOfOrderCompletion" {
    cond = "至少两笔不同 AWID 的合法写事务同时在途，后接收事务先在下游返回 B 响应",
    check = "后接收事务的 B 响应先于先接收事务到达上游",

    test_type = {
        stimulus = "CRV",
        check_type = "Chk",
    },

    priority = "P1",
    test_case = "003_different_id_write",
}

g:with_tp "AXI" "Write" "Response" "BIDRestore" {
    cond = "下游使用写重排表项 ID 返回一笔 B 响应",
    check = "上游 BID 等于该事务的原始 AWID",

    test_type = {
        stimulus = "CRV",
        check_type = "Chk",
    },

    priority = "P1",
    test_case = "002_same_id_write, 003_different_id_write",
}

g:with_tp "AXI" "Write" "MixedID" "PerIDOrder" {
    cond = "重复 AWID 与其他 AWID 的写事务同时在途",
    check = "每个 AWID 内部的 B 响应顺序与该 AWID 的 AW 接收顺序一致",

    test_type = {
        stimulus = "CRV",
        check_type = "Chk",
    },

    priority = "P1",
    info = "013_mixed_id_read_write",
}

g:with_tp "Scoreboard" "Write" "AWChannel" "PayloadAndOrderMatch" {
    cond = "上游 AW 完成握手，随后写事务在下游 AW 通道完成握手",
    check =
        "下游 AWADDR、AWLEN、AWSIZE、AWBURST、AWLOCK、AWCACHE、AWPROT、" ..
        "AWQOS、AWREGION 与上游 AW 接收顺序及字段值一致",

    test_type = {
        stimulus = "None",
        check_type = "Chk",
    },

    priority = "P1",
    info = "检测逻辑：scoreboard.lua 的 AW 先进先出队列匹配；下游 AWID 为重排表项 ID，另行检查",
}

g:with_tp "Scoreboard" "Write" "WChannel" "PayloadAndOrderMatch" {
    cond = "上游 W 完成握手，随后写数据在下游 W 通道完成握手",
    check = "下游 WDATA、WSTRB、WLAST 与上游 W 接收顺序及字段值一致",

    test_type = {
        stimulus = "None",
        check_type = "Chk",
    },

    priority = "P1",
    info = "检测逻辑：scoreboard.lua 的 W 先进先出队列匹配",
}

g:with_tp "Scoreboard" "Write" "BChannel" "ResponseMatch" {
    cond = "下游 B 通道完成握手，随后对应响应在上游 B 通道完成握手",
    check = "上游 BRESP 与已接收的下游 B 响应匹配",

    test_type = {
        stimulus = "None",
        check_type = "Chk",
    },

    priority = "P1",
    info = "检测逻辑：scoreboard.lua 的 B 非顺序响应匹配；BID 恢复由既有 BIDRestore 测试点覆盖",
}

g:with_tp "Scoreboard" "Write" "Completion" "NoPendingTransaction" {
    cond = "测试用例结束并调用自动检查收尾逻辑",
    check = "所有已接收的 AW/W 均已匹配下游事务，且对应写事务均已通过 B 响应完成",

    test_type = {
        stimulus = "None",
        check_type = "Chk",
    },

    priority = "P0",
    info = "检测逻辑：scoreboard.lua 的 finish_auto_check 写事务及 AW/W/B 期望项清空检查",
}
