local g = tspace.new_group("功能测试点")

g:with_tp "AXI" "ReadWrite" "Concurrent" "ReadIsolation" {
    cond = "读事务与写事务同时在途",
    check = "每笔上游 R 响应仅与对应的读事务匹配",

    test_type = {
        stimulus = "CRV",
        check_type = "Chk",
    },

    priority = "P1",
    test_case = "008_parellel_RandW",
}

g:with_tp "AXI" "ReadWrite" "Concurrent" "WriteIsolation" {
    cond = "读事务与写事务同时在途",
    check = "每笔上游 B 响应仅与对应的写事务匹配",

    test_type = {
        stimulus = "CRV",
        check_type = "Chk",
    },

    priority = "P1",
    test_case = "008_parellel_RandW",
}
