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
