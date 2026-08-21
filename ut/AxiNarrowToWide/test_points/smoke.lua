local g = tspace.new_group("功能测试点")

g:with_tp "AXI" "Write" "AWChannel" "PayloadPassThrough" {
    cond = "128 位上游发起一笔合法单拍写事务，AW 通道完成握手",
    check = "256 位下游 AW 通道同时握手，且 AWID、AWADDR、AWLEN、AWSIZE、AWBURST、AWLOCK、AWCACHE、AWPROT、AWQOS、AWREGION 均保持不变",

    test_type = { stimulus = "DT", check_type = "Chk" },
    priority = "P0",
    test_case = "000_smoke",
}

g:with_tp "AXI" "Write" "WChannel" "DataReplication" {
    cond = "上游发送一拍 128 位写数据",
    check = "下游 256 位 WDATA 的高、低 128 位均为该上游写数据",

    test_type = { stimulus = "DT", check_type = "Chk" },
    priority = "P0",
    test_case = "000_smoke",
}

g:with_tp "AXI" "Write" "WChannel" "LowLaneStrobe" {
    cond = "上游向 32 字节对齐地址的低 128 位写入一拍全字节有效数据",
    check = "下游 32 位 WSTRB 仅低 16 位有效，高 16 位为零",

    test_type = { stimulus = "DT", check_type = "Chk" },
    priority = "P0",
    test_case = "000_smoke",
}

g:with_tp "AXI" "Write" "WChannel" "HighLaneStrobe" {
    cond = "上游向同一 256 位存储字的高 128 位写入一拍全字节有效数据",
    check = "下游 32 位 WSTRB 仅高 16 位有效，低 16 位为零",

    test_type = { stimulus = "DT", check_type = "Chk" },
    priority = "P0",
    test_case = "000_smoke",
}

g:with_tp "AXI" "Write" "BChannel" "ResponsePassThrough" {
    cond = "下游完成一笔写事务并返回 B 响应",
    check = "上游 BID、BRESP 与下游响应一致，且 VALID/READY 背压关系正确传递",

    test_type = { stimulus = "DT", check_type = "Chk" },
    priority = "P0",
    test_case = "000_smoke",
}

g:with_tp "AXI" "Read" "ARChannel" "PayloadPassThrough" {
    cond = "128 位上游发起一笔合法单拍读事务，AR 通道完成握手",
    check = "256 位下游 AR 通道同时握手，且 ARID、ARADDR、ARLEN、ARSIZE、ARBURST、ARLOCK、ARCACHE、ARPROT、ARQOS、ARREGION 均保持不变",

    test_type = { stimulus = "DT", check_type = "Chk" },
    priority = "P0",
    test_case = "000_smoke",
}

g:with_tp "AXI" "Read" "RChannel" "LowLaneExtraction" {
    cond = "下游针对 32 字节对齐地址返回一拍 256 位读数据",
    check = "上游 RDATA 等于下游 RDATA 的低 128 位，RID、RRESP、RLAST 保持不变",

    test_type = { stimulus = "DT", check_type = "Chk" },
    priority = "P0",
    test_case = "000_smoke",
}

g:with_tp "AXI" "Read" "RChannel" "HighLaneExtraction" {
    cond = "下游针对同一 256 位存储字的高 128 位地址返回一拍 256 位读数据",
    check = "上游 RDATA 等于下游 RDATA 的高 128 位，RID、RRESP、RLAST 保持不变",

    test_type = { stimulus = "DT", check_type = "Chk" },
    priority = "P0",
    test_case = "000_smoke",
}

g:with_tp "AXI" "ReadWrite" "LaneIsolation" "PreserveOtherLane" {
    cond = "先后写入同一 256 位存储字的低、高 128 位，并在两次写入完成后分别读回",
    check = "低、高 128 位均返回各自最后写入的数据，第二次窄写不覆盖另一 lane",

    test_type = { stimulus = "DT", check_type = "SC" },
    priority = "P0",
    test_case = "000_smoke",
}

g:with_tp "Scoreboard" "Completion" "EndOfTest" "NoPendingTransaction" {
    cond = "冒烟用例的两笔写事务和两笔读事务均返回完成，并进入自动检查收尾逻辑",
    check = "上游 W、AW context、下游 R、AR context 队列均为空，AXI master 与 memory 均无在途事务",

    test_type = { stimulus = "DT", check_type = "Chk" },
    priority = "P0",
    test_case = "000_smoke",
}
