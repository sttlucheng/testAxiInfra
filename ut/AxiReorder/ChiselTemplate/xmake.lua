---@diagnostic disable: undefined-global

target("rtl", function()
    set_kind("phony")
    on_run(function()
        local build_dir = path.join("build", "rtl")
        os.tryrm(build_dir)
        os.execv("mill", {
            "-i", "chiselTemplate.runMain",
            "template.GenerateVerilog",
            "--target", "systemverilog",
            "--split-verilog",
            "-td", build_dir
        })
    end)
end)

target("clean", function()
    set_kind("phony")
    on_run(function()
        os.rmdir("build")
    end)
end)
