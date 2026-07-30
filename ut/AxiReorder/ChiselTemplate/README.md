# Chisel Template

开箱即用的 Chisel → SystemVerilog 模板工程，无需手动配置环境。

## 环境信息

### 环境要求

- [Mill](https://mill-build.org/) 1.0.6+（项目已内置 `.mill-version`，自动锁定版本）
- [xmake](https://xmake.io/) 2.8+（可选，提供更简洁的构建命令）
- JDK 11+

### 依赖版本

| 组件 | 版本 |
|------|------|
| Scala | 2.13.18 |
| Chisel | 7.9.0 |
| Mill | 1.0.6 |

## Quick Start

```bash
mill -i chiselTemplate.runMain template.GenerateVerilog \
    --target systemverilog --split-verilog -td build/rtl
```

使用以上命令即可将 Chisel 项目生成为 SystemVerilog 到 build/rtl 目录中。

命令参数介绍：

```
mill -i chiselTemplate.runMain template.GenerateVerilog --target systemverilog --split-verilog -td build/rtl
 [1] [2]        [3]                      [4]            └───────────────────────[5]────────────────────────┘
```

| 序号 | 参数 | 归属 | 含义 |
|------|------|------|------|
| [1] | `mill` | shell | 调用 Mill 构建工具 |
| [2] | `-i` | Mill | interactive 模式：复用后台 JVM server，后续调用启动速度更快 |
| [3] | `chiselTemplate.runMain` | Mill task | 在 `chiselTemplate` 模块中运行指定 main class，而非默认入口 |
| [4] | `template.GenerateVerilog` | Mill task 参数 | 要运行的完全限定类名 |
| [5] | `--target ... -td build/rtl` | App args | 原样透传给 Scala `App` 的 `args` 数组，再传入 `ChiselStage` |

```scala
object GenerateVerilog extends App {
  private val firrtlOpts =
    if (args.nonEmpty) args   // 来自命令行
    else Array("--target", "systemverilog", "--split-verilog", "-td", "build/rtl")

  (new ChiselStage).execute(firrtlOpts, Seq(ChiselGeneratorAnnotation(() => new Top())))
}
```

### 代码格式化

```bash
mill chiselTemplate.reformat
```

## 使用现代构建工具 XMake

```bash
xmake run rtl      # 编译 Chisel → SystemVerilog，输出到 build/rtl/
xmake run clean    # 清理 build/ 目录
```

## 项目结构

```
├── build.sc                    # Mill 构建配置
├── xmake.lua                   # xmake 快捷命令（rtl / clean）
├── .mill-version               # Mill 版本锁定（1.0.6）
├── .scalafmt.conf              # 代码格式化配置
└── src/main/scala/
    ├── Top.scala               # 示例顶层模块
    └── GenerateVerilog.scala   # Chisel 编译入口
```
