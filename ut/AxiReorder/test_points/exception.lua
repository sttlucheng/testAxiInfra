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

g:with_tp "Scoreboard" "Reset" "AddressChannel" "ReadyAfterReset" {
    cond = "reset 连续经过至少两个有效采样周期",
    check = "上游 ARREADY 与 AWREADY 均为 1，读写地址重排表可接收新事务",

    test_type = {
        stimulus = "None",
        check_type = "Chk",
    },

    priority = "P0",
    test_case = "001_reset",
    info = "检测逻辑：scoreboard.lua 的 reset_auto_check 地址通道状态检查",
}

g:with_tp "Scoreboard" "Reset" "WriteDataChannel" "BlockedWithoutAW" {
    cond = "reset 连续经过至少两个有效采样周期，且复位后尚未接收 AW",
    check = "上游 WREADY 为 0，不接收没有对应写地址的 W 数据",

    test_type = {
        stimulus = "None",
        check_type = "Chk",
    },

    priority = "P0",
    test_case = "001_reset",
    info = "检测逻辑：scoreboard.lua 的 reset_auto_check 写数据通道状态检查",
}

g:with_tp "Scoreboard" "Reset" "DownstreamRequest" "NoValid" {
    cond = "reset 连续经过至少两个有效采样周期",
    check = "下游 ARVALID、AWVALID、WVALID 均为 0，不发出读写请求",

    test_type = {
        stimulus = "None",
        check_type = "Chk",
    },

    priority = "P0",
    test_case = "001_reset",
    info = "检测逻辑：scoreboard.lua 的 reset_auto_check 下游请求静默检查",
}

g:with_tp "Scoreboard" "Reset" "UpstreamResponse" "NoValid" {
    cond = "reset 连续经过至少两个有效采样周期，且下游响应输入保持无效",
    check = "上游 RVALID、BVALID 均为 0，不产生读写响应",

    test_type = {
        stimulus = "None",
        check_type = "Chk",
    },

    priority = "P0",
    test_case = "001_reset",
    info = "检测逻辑：scoreboard.lua 的 reset_auto_check 上游响应静默检查",
}

g:with_tp "ScoreboardMonitor" "Reset" "OutstandingState" "Clear" {
    cond = "存在未完成读写事务时进入 reset，随后释放 reset 并发起新事务",
    check = "复位前保存的通道期望、读写事务和 Slave 表项占用记录全部取消，不与复位后事务交叉匹配",

    test_type = {
        stimulus = "None",
        check_type = "Assert",
    },

    priority = "P0",
    info = "检测逻辑：scoreboard.lua 的复位队列重建与 monitor.lua 的 outstanding 状态清空",
}

g:with_tp "Monitor" "InternalAR" "SendEligibility" "CanSend" {
    cond = "下游 ARVALID 为 1，AR 仲裁器选中一个读重排表项",
    check = "选中表项必须同时满足 valid=1、nid=0、have_sent=0",

    test_type = {
        stimulus = "None",
        check_type = "Assert",
    },

    priority = "P0",
    info = "检测逻辑：monitor.lua 的 check_internal 读表项 can_send 断言",
}

g:with_tp "Monitor" "InternalAR" "SelectedEntry" "IDMatch" {
    cond = "下游 ARVALID 为 1，AR 仲裁器已经给出 selected_entry",
    check = "下游 ARID 等于 selected_entry，发送事务来自仲裁器选中的读表项",

    test_type = {
        stimulus = "None",
        check_type = "Assert",
    },

    priority = "P0",
    info = "检测逻辑：monitor.lua 的 check_internal 下游 ARID 断言",
}

g:with_tp "Monitor" "InternalAW" "DependencyGate" "HeadNID" {
    cond = "写事务队首有效，监测队首表项 nid 与下游 AWVALID",
    check = "仅当队首表项 nid=0 时下游 AWVALID 为 1；nid 非 0 时下游 AWVALID 为 0",

    test_type = {
        stimulus = "None",
        check_type = "Assert",
    },

    priority = "P0",
    info = "检测逻辑：monitor.lua 的 check_internal 写队首依赖门控断言",
}

g:with_tp "Monitor" "InternalAW" "HeadEntry" "IDMatch" {
    cond = "写事务队首有效且下游 AWVALID 为 1",
    check = "下游 AWID 等于 head_entry，发送事务来自当前写队首表项",

    test_type = {
        stimulus = "None",
        check_type = "Assert",
    },

    priority = "P0",
    info = "检测逻辑：monitor.lua 的 check_internal 下游 AWID 断言",
}
