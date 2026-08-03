# line
无

# toggle

## 接口信号
io_mst_ar_bits_lock，io_slv_aw_bits_region[3:0]，io_slv_aw_bits_prot[2:0]，io_slv_aw_bits_lock，io_slv_ar_bits_region[3:0]，io_slv_ar_bits_prot[2:0]，io_slv_ar_bits_lock，io_mst_aw_bits_region[3:0]，io_mst_aw_bits_prot[2:0]，io_mst_aw_bits_lock，io_mst_ar_bits_region[3:0]，io_mst_ar_bits_prot[2:0]，
当前配置不支持AXI LOCK/REGION/PROT属性，相应AR/AW侧带信号固定为常量，不属于本配置的覆盖目标。

## 内部信号
io_deq_bits_awinfo_lock，io_enq_bits_awinfo_region[3:0]，io_enq_bits_awinfo_prot[2:0]，
io_enq_bits_awinfo_lock，io_deq_bits_awinfo_region[3:0]，io_deq_bits_awinfo_prot[2:0]，
AXI AWINFO中的LOCK/REGION/PROT字段未被设计使用，按接口配置固定为常量，因此排除Toggle Coverage。

# condition

  wire aw_mst_fire_hit_0 = wq_io_enq_valid & _awsel_T_1[0] & _awsel_res_bits_T_1[0];

# branch
无