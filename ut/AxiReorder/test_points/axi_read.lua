local g = tspace.new_group("功能测试点")

g:with_tp "AXI 常规请求" "Read" "sameIDReorder" {
    cond = "发送相同id的随机读请求",
    check = "",

    test_type = {
    stimulus = "CRV",
    check_type = "Chk",
    },

    priority = "P1",
    test_case = "004",
    info = "TODO_补充说明",

    opts = {
        color = "yellow",
    },
}

g:with_tp "AXI 常规请求" "Read" "differentIDReorder" {
    cond = "发送不同id的随机读请求",
    check = "",

    test_type = {
    stimulus = "CRV",
    check_type = "Chk",
    },

    priority = "P1",
    test_case = "005",
    info = "TODO_补充说明",

    opts = {
        color = "yellow",
    },
}

g:with_tp "AXI 常规请求" "Read" "randomIDReorder" {
    cond = "发送随机id的随机读请求",
    check = "",

    test_type = {
    stimulus = "CRV",
    check_type = "Chk",
    },

    priority = "P1",
    test_case = "006",
    info = "TODO_补充说明",

    opts = {
        color = "yellow",
    },
}


-- ...