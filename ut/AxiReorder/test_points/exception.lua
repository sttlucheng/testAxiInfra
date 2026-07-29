local g = tspace.new_group("性能测试点")

g:with_tp "AXI 常规请求" "Read" "AR重排表固定优先级" {
    cond = "先发送63个同id的单拍读请求和1个同id的99拍读请求，然后一直发送不同id的单拍读请求。",
    check = "",

    test_type = {
    stimulus = "CRV",
    check_type = "Chk+Assert",
    },

    priority = "P1",
    test_case = "009",
    info = "TODO_补充说明",

    opts = {
        color = "yellow",
    },
}