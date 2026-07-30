-- main.lua 中至少 require 一次；require 后会挂到全局 _G.tspace
local tspace = require "test_zhujiang_docs.TestPointSpace"

-- 必须调用一次初始化（整个工程只能 initialize 一次）
tspace.initialize("AxiReorder UT test points")

-- 加载其他的测试点文件（这些文件可直接用全局 tspace，不必再 require）
require "axi_read"
require "axi_write"
require "axi_readandwrite"
require "exception"

-- 生成 markdown 文件
tspace.to_markdown({
    filename = "./build/AxiReorder_ut_test_points.md",
    show_source = true,
})

-- 生成交互 HTML（单文件，内联 CSS/JS：宽表 + TOC + 搜索）
tspace.to_html({
    filename = "./build/AxiReorder_ut_test_points.html",
    title = "AxiReorder test points",
})
