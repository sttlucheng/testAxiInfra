local tspace = require "test_zhujiang_docs.TestPointSpace"

tspace.initialize("AxiNarrowToWide UT test points")

require "smoke"

tspace.to_markdown({
    filename = "./build/AxiNarrowToWide_ut_test_points.md",
    show_source = true,
})

tspace.to_html({
    filename = "./build/AxiNarrowToWide_ut_test_points.html",
    title = "AxiNarrowToWide test points",
})
