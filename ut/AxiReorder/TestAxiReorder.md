# AxiReorder 模块验证报告（简版）

> 验证对象：`AxiReorder`
> 验证层级：模块级 UT
> 报告依据：当前 RTL、Lua 验证环境、测试点及测试用例的静态检查，并保留原报告中的覆盖率记录
> 报告状态：待确认；本文未重新执行回归，不能替代最终签核记录

## 1. 验证概述

`AxiReorder` 位于上游 AXI Master 与下游 AXI Slave 之间。模块为读写请求分配内部重排表项 ID，下游响应返回后再恢复原始 `RID/BID`。验证重点是同 ID 保序、不同 ID 乱序完成、ID 恢复、读写并发、背压、表项管理和复位行为。

当前验证资产包含 12 个用例文件和 16 个 P1 测试点。14 个测试点已填写反标用例，另外 2 个 Mixed-ID 测试点尚未反标；其中 `Read/ARArbitration/FixedPriority` 的定义与当前轮询仲裁 RTL/TC009 不一致，需要更新测试点后再确认覆盖。

原报告记录的代码覆盖率为 Line 100%、Condition 94.79%、Branch 100%、端口 Toggle 98.64%。当前工作区未保留相应 VDB/URG 报告，所有用例也仅记录为 `RUN` 而不是 `PASS`，因此本报告的结论为：**验证环境和主要场景已建立，但回归通过状态、覆盖率证据及遗留测试点仍需补齐后才能签核。**

## 2. DUT 基本参数

参数来自 `AxiParams()` 默认值、`AxiReorderTop` 生成配置及 `AxiReorder.scala`。

| 参数 | 值 | 说明 |
| --- | ---: | --- |
| `addrBits` | 48 | AXI 地址宽度 |
| `idBits` | 12 | 上游原始 AXI ID 宽度 |
| `dataBits` | 256 | 每拍 32 Byte，`WSTRB` 为 32 bit |
| `lenBits` | 8 | `AxLEN` 宽度 |
| `sizeBits` | 3 | `AxSIZE` 宽度 |
| `lastBits` | 1 | 支持 `RLAST/WLAST` |
| `buffer` | 64 | 读、写重排表各 64 项 |
| 下游重映射 ID | 6 bit | 由 64 个表项编号决定 |
| `AW` 队列 | 1 项 | `Queue(..., entries=1, pipe=true)` |
| `W` entry 队列 | 2 项 | 保存写数据对应的表项号 |
| `W` 数据队列 | 2 项 | 保存写数据及其表项号 |
| 复位 | 异步、高有效 | 复位时清空重排表有效位 |

主要接口为上游 `io_mst_*` 和下游 `io_slv_*`，均包含 AXI `AW/W/B/AR/R` 五个通道。下游请求 ID 是表项号，上游响应 ID 应恢复为原始请求 ID。

## 3. 验证框架

验证数据流如下：

```text
test_cases -> driver/AXI4Master -> io_mst -> AxiReorder -> io_slv -> AXI4Memory
                                      \-> monitor -> scoreboard -> 自动检查
```

| 文件或目录 | 作用 |
| --- | --- |
| `tc_main.lua` | 读取 `TC_NAME/SEED`，加载用例，执行复位、monitor 启动、用例任务和 scoreboard 收尾检查 |
| `src/cfg.lua` | 控制 monitor、详细日志和 heartbeat 开关 |
| `src/env.lua` | 驱动默认空闲值、执行 10 周期复位、启动周期采样任务 |
| `src/common/clock_reset.lua` | 提供时钟等待和复位操作 |
| `src/common/axi_stimulus.lua` | 生成合法 burst、地址、数据和 strobe |
| `src/dut/driver.lua` | 连接上游 AXI Master 和下游 AXI Memory，提供阻塞/非阻塞读写及响应注入接口 |
| `src/dut/signals.lua` | 汇总 DUT 端口及定向覆盖用例使用的只读内部信号句柄 |
| `src/dut/monitor.lua` | 逐周期采样端口，只在 `valid && ready` 时形成有效握手记录并通知订阅者 |
| `src/dut/scoreboard.lua` | 比对 payload、ID 映射和同 ID 顺序；结束时检查所有期望队列为空 |
| `src/components/AXI/test_zhujiang_utils/` | 提供 `AXI4MasterV2`、`AXI4Memory` 及 AXI 通道模型 |
| `test_cases/*.lua` | 定向和约束随机测试用例 |
| `test_points/*.lua` | 功能/微架构测试点及用例反标关系 |

公共随机种子由 `SEED` 指定，未设置时为 `1`。Driver 最多管理 64 个并发事务，单事务超时为 2,000,000 周期；AXI Master 和 Memory 均可插入随机延迟，Memory 可乱序返回 `R/B` 并注入四类 AXI 响应码。

## 4. 验证流程

1. 初始化 Verilua 环境并生成 `AxiReorder` RTL。
2. 选择 `TC`、`SEED` 和 `LOOP`，编译并运行普通仿真。
3. `tc_main.lua` 设置随机种子、复位 DUT、启动 monitor，再依次执行用例任务。
4. monitor 将接口握手送入 scoreboard；用例结束后 `finish_auto_check()` 检查未匹配事务。
5. 使用 coverage 目标运行选定用例并合并 VDB，检查 Line、Condition、Branch 和端口 Toggle。
6. 对覆盖缺口运行定向用例，或完成不可达分析和 waiver 评审；最后保存日志、波形和覆盖率报告。

参考命令：

```bash
source /nfs/home/yanglucheng/tools/verilua/v3.4.0/verilua.sh
xmake r -P . rtl

# 普通仿真和波形
TC=004 SEED=1 LOOP=5000 MODE=1 xmake run -P . TestAxiReorder
TC=004 SEED=1 LOOP=5000 DUMP=1 MODE=1 xmake run -P . TestAxiReorder

# 覆盖率仿真
TC=004 SEED=1 LOOP=5000 MODE=1 xmake run -P . TestAxiReorderVcsCov

# 调试
verdi -ssf build/vcs/TestAxiReorder/004.vcd.fsdb
verdi -cov -covdir build/vcs/TestAxiReorderVcsCov/sim_build/simv.vdb
```

## 5. 测试用例说明

除特别说明外，随机用例默认 `SEED=1`。

| TC | 用例 | 类型/默认 LOOP | 验证目标 |
| --- | --- | --- | --- |
| 000 | `000_smoke.lua` | DT / 1 次 | 单笔写入后同地址读回，检查基本读写数据通路 |
| 001 | `001_reset.lua` | DT / 1 次 | 检查复位期间输出静默及复位释放后的读写恢复 |
| 002 | `002_same_id_write.lua` | CRV / 5000 | 多笔相同 AWID 写事务保序、BID 恢复及随机 burst/响应 |
| 003 | `003_different_id_write.lua` | CRV / 5000 | 不同 AWID 写事务乱序完成、通道关联及 BID 恢复 |
| 004 | `004_same_id_read.lua` | CRV / 5000 | 多笔相同 ARID 读事务保序及 RID 恢复 |
| 005 | `005_different_id_read.lua` | CRV / 5000 | 不同 ARID 读事务乱序完成及 RID 恢复 |
| 006 | `006_random_id_read.lua` | CRV / 5000 | 随机 ID、地址、burst、size 和响应的读压力测试 |
| 007 | `007_random_id_write.lua` | CRV / 5000 | 随机 ID、地址、burst、size、strobe 和响应的写压力测试 |
| 008 | `008_parellel_RandW.lua` | CRV / 5000 | 随机读写并发，检查时间重叠和读写通道隔离 |
| 009 | `009.lua` | DT/Stress / 1000 | 64 项 AR 表满载、同 ID 依赖及轮询仲裁下的无长期饥饿和排空恢复 |
| 010 | `010_ReadAfterWrite.lua` | CRV / 5000 | 随机写完成后从同一地址读回，检查数据、strobe 和 ID 恢复 |
| 012 | `012_linecoverage.lua` | Coverage DT | 定向覆盖 AW entry8..63 分配语句及 entry1..63 的 `nid` 递减语句 |



## 6. 测试点说明

| 测试点 | 场景与检查标准 | 反标用例 |
| --- | --- | --- |
| `Read/SameID/ARIssueOrder` | 相同 ARID 同时在途时，后一笔不得先完成下游 AR 握手 | 004 |
| `Read/SameID/RResponseOrder` | 后一事务首拍 R 不得早于前一事务 RLAST | 004 |
| `Read/DifferentID/OutOfOrderCompletion` | 不同 ARID 后接收事务允许先完成 | 005 |
| `Read/Response/RIDRestore` | 下游表项 ID 返回后，上游 RID 恢复为原始 ARID | 004、005 |
| `Read/MixedID/PerIDOrder` | 重复 ID 与其他 ID 并发时，每个 ID 内部保持顺序 | **未反标** |
| `Write/SameID/AWIssueOrder` | 相同 AWID 同时在途时，后一笔不得先完成下游 AW 握手 | 002 |
| `Write/SameID/BResponseOrder` | 每个 AWID 的 B 顺序与 AW 接收顺序一致 | 002 |
| `Write/DifferentID/OutOfOrderCompletion` | 不同 AWID 后接收事务允许先返回 B | 003 |
| `Write/Response/BIDRestore` | 下游表项 ID 返回后，上游 BID 恢复为原始 AWID | 002、003 |
| `Write/MixedID/PerIDOrder` | 重复 ID 与其他 ID 并发时，每个 ID 内部保持顺序 | **未反标** |
| `ReadWrite/Concurrent/ReadIsolation` | 读写并发时，每笔 R 只匹配对应读事务 | 008 |
| `ReadWrite/Concurrent/WriteIsolation` | 读写并发时，每笔 B 只匹配对应写事务 | 008 |
| `Read/ARTable/Capacity64` | 响应释放前连续接收 64 笔读事务，64 个 AR 表项同时有效 | 009 |
| `Read/ARTable/SameIDDependency` | 64 笔同 ID 请求的 `nid` 等于未完成前序事务数 | 009 |
| `Read/ARArbitration/FixedPriority` | 测试点描述为固定优先级阻塞，但当前 RTL/TC009 为轮询无饥饿验证 | 009；**语义待更新** |
| `Read/ARArbitration/DrainRecovery` | 竞争停止并排空后，目标事务最终完成下游 AR 握手 | 009 |

| P1 测试点统计 | 数量 |
| --- | ---: |
| 总数 | 16 |
| 已填写反标用例 | 14 |
| 未反标 | 2 |
| 反标率 | 87.5% |
| 反标后仍需语义评审 | 1 |

反标率不等于功能覆盖率。只有对应回归通过且检查证据可追溯时，测试点才能计为已覆盖。

## 7. 覆盖率与遗留项

### 7.1 代码覆盖率

| 指标 | 原报告记录 | 目标 | 当前结论 |
| --- | ---: | ---: | --- |
| Line | 100% | 100% | 数值达标，待 VDB/URG 复核 |
| Condition | 94.79% | 100% | 未达标，缺口 5.21% |
| Branch | 100% | 100% | 数值达标，待 VDB/URG 复核 |
| Toggle（ports only） | 98.64% | 100% | 未达标，缺口 1.36% |

`xprop.log` 记录 1373/1373 个可插桩赋值成功插桩，XProp instrumentation success rate 为 100%；该数字仅说明插桩完整，不代表 XProp 场景全部通过。

### 7.2 遗留项

1. 补充 `Read/MixedID/PerIDOrder` 和 `Write/MixedID/PerIDOrder` 的约束随机场景或现有日志反标。
2. 将 `FixedPriority` 测试点更新为当前 RTL 的轮询仲裁目标，并重新评审 TC009 的检查标准。
3. 补充每个 TC/Seed/LOOP 的 PASS/FAIL 日志及 scoreboard 收尾结果；`RUN` 不能作为通过结论。
4. 恢复或归档 coverage VDB、URG 报告和 exclusion 文件，复核 94.79%/98.64% 的来源。
5. 对未覆盖 condition/toggle 完成可达性分析；waiver 需设计和验证共同批准。
6. 重新确认原报告引用的 TC011 证据，避免使用已不存在或过期的覆盖率分析。

## 8. 验证范围与结论

本报告覆盖 AXI 五通道握手和 payload、同 ID 保序、不同 ID 乱序、ID 映射恢复、随机背压、读写并发、表项容量/依赖、轮询仲裁、复位及自动 scoreboard 检查。不包含 CDC、时序、功耗、DFT、系统级性能和 Formal 证明。

基于当前代码检查，AxiReorder 的模块级验证框架和主要用例已具备，Line/Branch 覆盖率记录达到 100%，但 Condition、Toggle、两项 Mixed-ID 测试点、仲裁测试点一致性及回归证据尚未闭环。**最终结论保持“待确认”，完成第 7.2 节遗留项后再进行验证签核。**
