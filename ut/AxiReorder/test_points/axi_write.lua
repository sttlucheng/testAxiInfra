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
    info = "需约束重复 ID 与不同 ID 同时在途后再反标用例",
}
