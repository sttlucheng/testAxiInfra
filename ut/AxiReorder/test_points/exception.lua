local g = tspace.new_group("微架构测试点")

g:with_tp "AXI" "Read" "ARTable" "Capacity64" {
    cond = "在读响应释放表项前连续接收 64 笔相同 ARID 的读事务",
    check = "AR 重排表的 64 个表项同时有效",

    test_type = {
        stimulus = "DT",
        check_type = "Chk",
    },

    priority = "P1",
    test_case = "009",
}

g:with_tp "AXI" "Read" "ARTable" "SameIDDependency" {
    cond = "64 笔相同 ARID 的读事务依次分配到 entry0 至 entry63",
    check = "每个表项的 nid 等于其尚未完成的同 ID 前序事务数量",

    test_type = {
        stimulus = "DT",
        check_type = "Chk",
    },

    priority = "P1",
    test_case = "009",
}

g:with_tp "AXI" "Read" "ARArbitration" "FixedPriority" {
    cond = "entry63 已满足发送条件，低编号表项持续接收可发送的不同 ID 事务",
    check = "全部竞争事务入表前 entry63 不得完成下游 AR 握手",

    test_type = {
        stimulus = "DT",
        check_type = "Chk",
    },

    priority = "P1",
    test_case = "009",
}

g:with_tp "AXI" "Read" "ARArbitration" "DrainRecovery" {
    cond = "停止补充低编号竞争事务并等待已有竞争事务排空",
    check = "entry63 最终完成下游 AR 握手",

    test_type = {
        stimulus = "DT",
        check_type = "Chk",
    },

    priority = "P1",
    test_case = "009",
}

g:with_tp "AxiReorder" "SlaveEntryID" "ReadNoEarlyReuse" {
    cond =
        "Slave侧已完成一笔AR握手并取得重排表项ID；" ..
        "延迟该表项对应的RVALID/RREADY/RLAST完成握手，" ..
        "期间继续接收其他读事务",
    check =
        "在该表项的RLAST握手完成前，不得再次发生相同重排表项ID的Slave AR握手；" ..
        "RLAST握手完成后，该表项ID允许被新读事务重新使用",
    test_type = {stimulus = "None",check_type = "Assert",}
    priority = "P0",
    info = "这里的ID是AxiReorder读重排表项ID，不是上游ARID",
}

g:with_tp "AxiReorder" "SlaveEntryID" "WriteNoEarlyReuse" {
    cond =
        "Slave侧已完成一笔AW握手并取得重排表项ID；" ..
        "允许对应W事务完成，但延迟该表项对应的BVALID/BREADY握手，" ..
        "期间继续接收其他写事务",
    check =
        "在该表项的B握手完成前，不得再次发生相同重排表项ID的Slave AW握手；" ..
        "B握手完成后，该表项ID允许被新写事务重新使用",
    test_type = {stimulus = "None",check_type = "Assert",}
    priority = "P0",
    info = "这里的ID是AxiReorder写重排表项ID，不是上游AWID；读写表分别检查",
}
