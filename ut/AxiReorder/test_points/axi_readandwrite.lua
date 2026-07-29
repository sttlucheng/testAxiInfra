local g = tspace.new_group("功能测试点")

g:with_tp "AXI 常规请求" "ReadandWrite" "randomIDReorder" {
    cond = "同时发送随机id的随机读和写请求",
    check = "",

    test_type = {
    stimulus = "CRV",
    check_type = "Chk",
    },

    priority = "P1",
    test_case = "008",
    info = "TODO_补充说明",

    opts = {
        color = "yellow",
    },
}