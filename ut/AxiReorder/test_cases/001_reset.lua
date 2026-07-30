local env = require "env"
local driver = require "dut.driver"
local scoreboard = require "dut.scoreboard"

local function task_reset()
    -- tc_main 已经启动 monitor，所以这次显式复位能够被观察到。
    env.dut_reset()

    -- 等待 monitor 采到 reset 释放后的稳定状态。
    env.wait_cycles(2)

    -- env.dut_reset()释放后reset为0；这里再次拉高，显式产生0到1跳变。
    dut.reset:set_imm(1)
    env.wait_cycles(2)

    -- 释放reset，以便继续执行复位后的AXI读写检查。
    dut.reset:set_imm(0)
    env.wait_cycles(2)

    -- 启动 AXI 组件，验证 DUT 复位后仍能正常工作。
    driver.initialize()
    env.wait_cycles(1)

    local addr = 0x1000
    local expected = string.rep("5a", 32)

    local write_ret = driver.write_single(addr, expected)
    assert(
        write_ret == "Success",
        "\n\n---ERROR---\n\npost-reset write failed: " ..
            tostring(write_ret) ..
            "\n\n-----------\n\n"
    )

    local read_ret, actual = driver.read_single(addr)
    assert(
        read_ret == "Success",
        "\n\n---ERROR---\n\npost-reset read failed: " ..
            tostring(read_ret) ..
            "\n\n-----------\n\n"
    )
    assert(
        actual:lower() == expected,
        "\n\n---ERROR---\n\npost-reset read data mismatch\n\n-----------\n\n"
    )

    print("Post-reset AXI access passed")
end

return {
    tasks = {
        task_reset
    }
}
