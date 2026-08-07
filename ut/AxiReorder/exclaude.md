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
      当 _driver_io_deq_valid=0 时，io_deq_ready 必然为0，
      子条件组合1/0在逻辑结构上不可达。

# branch
无
