local g = tspace.new_group("功能测试点")

g:with_tp "AXI" "Read" "SameID" "ARIssueOrder" {
    cond = "至少两笔相同 ARID 的合法读事务同时在途，前序事务尚未返回 RLAST",
    check = "后一笔事务不得先于前一笔完成下游 AR 握手",

    test_type = {
        stimulus = "CRV",
        check_type = "Chk",
    },

    priority = "P1",
    test_case = "004_same_id_read",
}

g:with_tp "AXI" "Read" "SameID" "RResponseOrder" {
    cond = "至少两笔相同 ARID 的合法读事务同时在途",
    check = "后一事务的首拍 R 不得在前一事务 RLAST 之前向上游握手",

    test_type = {
        stimulus = "CRV",
        check_type = "Chk",
    },

    priority = "P1",
    test_case = "004_same_id_read",
}

g:with_tp "AXI" "Read" "DifferentID" "OutOfOrderCompletion" {
    cond = "至少两笔不同 ARID 的合法读事务同时在途，后接收事务先在下游完成",
    check = "后接收事务的 R 响应先于先接收事务到达上游",

    test_type = {
        stimulus = "CRV",
        check_type = "Chk",
    },

    priority = "P1",
    test_case = "005_different_id_read",
}

g:with_tp "AXI" "Read" "Response" "RIDRestore" {
    cond = "下游使用读重排表项 ID 返回一笔 R 响应",
    check = "上游 RID 等于该事务的原始 ARID",

    test_type = {
        stimulus = "CRV",
        check_type = "Chk",
    },

    priority = "P1",
    test_case = "004_same_id_read, 005_different_id_read",
}

g:with_tp "AXI" "Read" "MixedID" "PerIDOrder" {
    cond = "重复 ARID 与其他 ARID 的读事务同时在途",
    check = "每个 ARID 内部的 R 事务顺序与该 ARID 的 AR 接收顺序一致",

    test_type = {
        stimulus = "CRV",
        check_type = "Chk",
    },

    priority = "P1",
    info = "013_mixed_id_read_write",
}

g:with_tp "Scoreboard" "Read" "ARChannel" "PayloadMatch" {
    cond = "上游 AR 完成握手，随后对应读事务在下游 AR 通道完成握手",
    check =
        "下游 ARADDR、ARLEN、ARSIZE、ARBURST、ARLOCK、ARCACHE、ARPROT、" ..
        "ARQOS、ARREGION 与已接收的上游读事务逐字段匹配",

    test_type = {
        stimulus = "None",
        check_type = "Chk",
    },

    priority = "P1",
    info = "检测逻辑：scoreboard.lua 的 AR 非顺序事务匹配；下游 ARID 为重排表项 ID，另行检查",
}

g:with_tp "Scoreboard" "Read" "RChannel" "PayloadMatch" {
    cond = "下游 R 通道完成握手，随后对应响应在上游 R 通道完成握手",
    check = "上游 RDATA、RRESP、RLAST 与已接收的下游 R 响应逐字段匹配",

    test_type = {
        stimulus = "None",
        check_type = "Chk",
    },

    priority = "P1",
    info = "检测逻辑：scoreboard.lua 的 R 非顺序响应匹配；RID 恢复由既有 RIDRestore 测试点覆盖",
}

g:with_tp "Scoreboard" "Read" "Completion" "NoPendingTransaction" {
    cond = "测试用例结束并调用自动检查收尾逻辑",
    check = "所有已接收的 AR 请求均已匹配下游 AR，且对应读事务均已通过 RLAST 完成",

    test_type = {
        stimulus = "None",
        check_type = "Chk",
    },

    priority = "P0",
    info = "检测逻辑：scoreboard.lua 的 finish_auto_check 读事务及 AR/R 期望项清空检查",
}
