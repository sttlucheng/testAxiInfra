# AxiReorder 代码覆盖率排除说明

本文记录当前 `AxiReorder` 配置下拟排除的代码覆盖项及其不可达性分析。

> [!IMPORTANT]
> 本文结论仅适用于当前 AXI 属性配置和队列结构。若启用 `LOCK`、`REGION`、
> `PROT` 属性，或修改 `FastQueue`、AW/W 握手逻辑，必须重新评审相关排除项。

## Line

无排除项。

## Toggle

### 接口信号

| 通道 | 排除信号 |
| --- | --- |
| Master AR | `io_mst_ar_bits_lock`、`io_mst_ar_bits_region[3:0]`、`io_mst_ar_bits_prot[2:0]` |
| Master AW | `io_mst_aw_bits_lock`、`io_mst_aw_bits_region[3:0]`、`io_mst_aw_bits_prot[2:0]` |
| Slave AR | `io_slv_ar_bits_lock`、`io_slv_ar_bits_region[3:0]`、`io_slv_ar_bits_prot[2:0]` |
| Slave AW | `io_slv_aw_bits_lock`、`io_slv_aw_bits_region[3:0]`、`io_slv_aw_bits_prot[2:0]` |

**排除原因：** 当前配置不支持 AXI `LOCK`、`REGION`、`PROT` 属性，AR/AW
对应的侧带信号固定为常量，不属于本配置的 Toggle Coverage 目标。

### 内部信号

| 方向 | 排除信号 |
| --- | --- |
| AWINFO 入队 | `io_enq_bits_awinfo_lock`、`io_enq_bits_awinfo_region[3:0]`、`io_enq_bits_awinfo_prot[2:0]` |
| AWINFO 出队 | `io_deq_bits_awinfo_lock`、`io_deq_bits_awinfo_region[3:0]`、`io_deq_bits_awinfo_prot[2:0]` |

**排除原因：** `AxiReorder` 不解析或修改 AWINFO 中的 `LOCK`、`REGION`、
`PROT` 字段。当前接口配置将这些字段固定为常量，因此排除相应内部信号的
Toggle Coverage。

## Condition

下文中的 `C1`、`C2`、`C3` 按表达式操作数从左到右编号。

### `aw_mst_fire_hit_0`

```systemverilog
wire aw_mst_fire_hit_0 =
  wq_io_enq_valid & _awsel_T_1[0] & _awsel_res_bits_T_1[0];
```

| 组合 | `C1: wq_io_enq_valid` | `C2: _awsel_T_1[0]` | `C3: _awsel_res_bits_T_1[0]` |
| --- | ---: | ---: | ---: |
| EXCL-AW-01 | 1 | 0 | 1 |
| EXCL-AW-02 | 1 | 1 | 0 |

**排除原因：**

已知：

```systemverilog
_awsel_res_bits_T   = wvld;
_awsel_T_1          = ~_awsel_res_bits_T;
_awsel_res_bits_T_1 = _awsel_res_bits_T + 64'h1;
```

令 `x = wvld[0]`。对于加一运算的最低位：

```text
_awsel_T_1[0]          = ~x
_awsel_res_bits_T_1[0] = (x + 1)[0] = ~x
```

因此 `C2 == C3` 恒成立，`C2/C3` 为 `0/1` 或 `1/0` 的组合在逻辑上均不可达。

### `ar_mst_fire_hit_0`

```systemverilog
wire ar_mst_fire_hit_0 =
  _arMstFireHit_T_189 & _arsel_T_1[0] & _arsel_res_bits_T_1[0];
```

| 组合 | `C1: _arMstFireHit_T_189` | `C2: _arsel_T_1[0]` | `C3: _arsel_res_bits_T_1[0]` |
| --- | ---: | ---: | ---: |
| EXCL-AR-01 | 1 | 0 | 1 |
| EXCL-AR-02 | 1 | 1 | 0 |

**排除原因：**

已知：

```systemverilog
_arsel_res_bits_T   = rvld;
_arsel_T_1          = ~_arsel_res_bits_T;
_arsel_res_bits_T_1 = _arsel_res_bits_T + 64'h1;
```

令 `x = rvld[0]`。对于加一运算的最低位：

```text
_arsel_T_1[0]          = ~x
_arsel_res_bits_T_1[0] = (x + 1)[0] = ~x
```

因此 `C2 == C3` 恒成立，`C2/C3` 为 `0/1` 或 `1/0` 的组合在逻辑上均不可达。

### `FastQueue.ptrMoveVec`（`wq`）

```systemverilog
wire [1:0] ptrMoveVec = {
  ~(waterline[2]) & io_enq_valid,
  io_deq_ready & _driver_io_deq_valid
};
```

针对低位表达式 `io_deq_ready & _driver_io_deq_valid`：

| 组合 | `io_deq_ready` | `_driver_io_deq_valid` |
| --- | ---: | ---: |
| EXCL-WQ-PTR-01 | 1 | 0 |

**排除原因：** `AxiReorder` 中 `wq.io_deq.ready` 的逻辑为：

```text
wq.io_deq.ready
  = wbitsq.io.enq.valid & io_mst_w_bits_last

wbitsq.io.enq.valid
  = io_mst_w_valid & io_mst_w_ready

io_mst_w_ready
  = wbitsq.io.enq.ready & wq.io_deq.valid

wq.io_deq.valid
  = _driver_io_deq_valid
```

展开后：

```text
io_deq_ready
  = io_mst_w_valid
  & wbitsq.io_enq.ready
  & _driver_io_deq_valid
  & io_mst_w_bits_last
```

因此，`io_deq_ready == 1` 必然要求 `_driver_io_deq_valid == 1`；组合 `1/0`
在逻辑结构上不可达。

### `Queue1_AxiWEtrBundle_1.do_enq`（`wbitsq.holder`）

```systemverilog
wire do_enq =
  ~(~maybe_full & io_deq_ready) & ~maybe_full & io_enq_valid;
```

| 组合 | `C1: ~(~maybe_full & io_deq_ready)` | `C2: ~maybe_full` | `C3: io_enq_valid` |
| --- | ---: | ---: | ---: |
| EXCL-WBITSQ-ENQ-01 | 1 | 0 | 1 |

**排除原因：** `C2 == 0` 等价于 `maybe_full == 1`，表示 `wbitsq` 的 holder
已满。在合法 `FastQueue_1` 状态下，holder 已满意味着 driver 也被占用，队列处于
满状态：

```text
maybe_full == 1
  => waterline[2] == 1
  => wbitsq.io_enq.ready == ~waterline[2] == 0
```

`wbitsq` 的入队有效信号来自合法的上游 W 握手：

```text
io_mst_w_ready
  = wbitsq.io_enq.ready & wq.io_deq.valid

wbitsq.io_enq.valid
  = io_mst_w_ready & io_mst_w_valid
```

所以：

```text
maybe_full == 1
  => wbitsq.io_enq.ready == 0
  => io_mst_w_ready == 0
  => io_enq_valid == wbitsq.io_enq.valid == 0
```

这与目标组合要求的 `io_enq_valid == 1` 矛盾。即使下游在当前周期接收一笔 W，
队列也只能在时钟沿后更新状态并重新允许入队，当前周期仍无法形成 `1/0/1`。

### `Queue1_UInt6_1.do_enq`（`wq.holder`）

```systemverilog
wire do_enq =
  ~(~maybe_full & io_deq_ready) & ~maybe_full & io_enq_valid;
```

| 组合 | `C1: ~(~maybe_full & io_deq_ready)` | `C2: ~maybe_full` | `C3: io_enq_valid` |
| --- | ---: | ---: | ---: |
| EXCL-WQ-ENQ-01 | 1 | 0 | 1 |

**排除原因：** `C2 == 0` 等价于 `maybe_full == 1`，表示 `wq` 的 holder 已满。
在合法 `FastQueue` 状态下，holder 已满意味着 driver 也被占用，队列处于满状态：

```text
maybe_full == 1
  => waterline[2] == 1
  => wq.io_enq.ready == ~waterline[2] == 0
```

`wq` 的入队有效信号来自合法的上游 AW 握手：

```text
io_mst_aw_ready
  = awsel_valid & wq.io_enq.ready & awq.io_enq.ready

wq.io_enq.valid
  = io_mst_aw_ready & io_mst_aw_valid
```

所以：

```text
maybe_full == 1
  => wq.io_enq.ready == 0
  => io_mst_aw_ready == 0
  => io_enq_valid == wq.io_enq.valid == 0
```

这与目标组合要求的 `io_enq_valid == 1` 矛盾，因此 `1/0/1` 在合法接口行为下
不可达。

## Branch

无排除项。
