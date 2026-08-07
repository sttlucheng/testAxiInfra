# line
无

# toggle

## 接口信号
io_mst_ar_bits_lock，io_slv_aw_bits_region[3:0]，io_slv_aw_bits_prot[2:0]，

io_slv_aw_bits_lock，io_slv_ar_bits_region[3:0]，io_slv_ar_bits_prot[2:0]，

io_slv_ar_bits_lock，io_mst_aw_bits_region[3:0]，io_mst_aw_bits_prot[2:0]，

io_mst_aw_bits_lock，io_mst_ar_bits_region[3:0]，io_mst_ar_bits_prot[2:0]，

当前配置不支持AXI LOCK/REGION/PROT属性，相应AR/AW侧带信号固定为常量，不属于本配置的覆盖目标。

## 内部信号
io_deq_bits_awinfo_lock，io_enq_bits_awinfo_region[3:0]，io_enq_bits_awinfo_prot[2:0]，

io_enq_bits_awinfo_lock，io_deq_bits_awinfo_region[3:0]，io_deq_bits_awinfo_prot[2:0]，

AXI AWINFO中的LOCK/REGION/PROT字段未被设计使用，按接口配置固定为常量，因此排除Toggle Coverage。

# condition

  #### wire aw_mst_fire_hit_0 = wq_io_enq_valid & _awsel_T_1[0] & _awsel_res_bits_T_1[0]; 

    Exclude组合：
      1 / 0 / 1
      1 / 1 / 0

    Exclude原因：
      由于_awsel_T_1 = ~_awsel_res_bits_T且_awsel_res_bits_T = wvld，_awsel_res_bits_T_1 = wvld + 64'h1，所以_awsel_T_1[0] = ~wvld[0]、_awsel_res_bits_T_1[0]= wvld[0] + 1 = ~wvld[0],因此该condition中_awsel_T_1[0]和_awsel_res_bits_T_1[0]必须相同，需要exclaude _awsel_T_1[0]=1，_awsel_res_bits_T_1[0]=0和_awsel_T_1[0]=0，_awsel_res_bits_T_1[0]=1的condition。

  #### wire ar_mst_fire_hit_0 = _arMstFireHit_T_189 & _arsel_T_1[0] &_arsel_res_bits_T_1[0];

    Exclude组合：
      1 / 0 / 1
      1 / 1 / 0

    Exclude原因：
      由于_arsel_T_1 = ~_arsel_res_bits_T且_arsel_res_bits_T = rvld，_arsel_res_bits_T_1 = rvld + 64'h1，所以_arsel_T_1[0] = ~rvld[0]、_arsel_res_bits_T_1[0]= rvld[0] + 1 = ~rvld[0],因此该condition中_arsel_T_1[0]和_arsel_res_bits_T_1[0]必须相同，需要exclaude _arsel_T_1[0]=1，_arsel_res_bits_T_1[0]=0和exclaude _arsel_T_1[0]=0，_arsel_res_bits_T_1[0]=1的condition。

  #### wire [1:0] ptrMoveVec = {~(waterline[2]) & io_enq_valid, io_deq_ready & _driver_io_deq_valid};

    Exclaude的组合：io_deq_ready / _driver_io_deq_valid = 1 / 0

    Exclude原因：
      在 AxiReorder 中，wq.io_deq_ready 的逻辑为：

        wq.io_deq_ready
          = wbitsq.io_enq.valid & io_mst_w_bits_last

        wbitsq.io_enq.valid
          = io_mst_w_valid & io_mst_w_ready

        io_mst_w_ready
          = wbitsq.io_enq.ready & wq.io_deq.valid

        wq.io_deq.valid
          = _driver_io_deq_valid

      展开后：

        io_deq_ready
          = io_mst_w_valid
            & wbitsq.io_enq.ready
            & _driver_io_deq_valid
            & io_mst_w_bits_last

      因此 io_deq_ready=1 必然要求 _driver_io_deq_valid=1。
      当 _driver_io_deq_valid=0 时，io_deq_ready 必然为0，子条件组合1/0在逻辑结构上不可达。

  #### wire do_enq = ~(~maybe_full & io_deq_ready) & ~maybe_full & io_enq_valid;
    
    Exclude组合：
      1 / 0 / 1

    Exclude原因：
      第二个操作数为0要求：

        ~maybe_full = 0
        maybe_full = 1

      maybe_full=1表示FastQueue_1的holder已满。在所有合法队列状态下，
      holder已满意味着driver也已占用FastQueue_1处于满状态：

        waterline[2] = 1

      因此FastQueue_1不再允许新的写数据入队：

        io_enq_ready = ~waterline[2] = 0

      在AxiReorder中，wbitsq的入队有效信号由合法的上游W握手产生：

        io_mst_w_ready_0 =
            _wbitsq_io_enq_ready
          & _wq_io_deq_valid

        wbitsq_io_enq_valid =
            io_mst_w_ready_0
          & io_mst_w_valid

      当holder已满时：

        _wbitsq_io_enq_ready = 0
        io_mst_w_ready_0 = 0
        wbitsq_io_enq_valid = 0

      Queue1_AxiWEtrBundle_1的io_enq_valid直接连接到wbitsq_io_enq_valid，因此：

        maybe_full = 1
          =>
        io_enq_valid = 0

      这与组合1/0/1要求的io_enq_valid=1矛盾。

      即使下游在当前周期接收一笔W，FastQueue_1也只能在时钟沿后更新队列状态并重新允许入队。
      此时holder已经开始清空，~maybe_full将变为1，仍然无法形成1/0/1。

# branch
无
