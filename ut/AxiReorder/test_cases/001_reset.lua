local env = require "env"
local driver = require "dut.driver"
local scoreboard = require "dut.scoreboard"

local function task_reset()
    -- tc_main 已经启动 monitor，所以这次显式复位能够被观察到。
    env.dut_reset()

    -- 等待 monitor 采到 reset 释放后的稳定状态。
    env.wait_cycles(2)

    -- 启动 AXI 组件，验证 DUT 复位后仍能正常工作。
    driver.initialize()
    env.wait_cycles(1)

    local addr = 0x1000
    local expected = string.rep("5a", 32)

    local write_ret = driver.write_single(addr, expected)
    assert(write_ret == "Success",
        "post-reset write failed: " .. tostring(write_ret))

    local read_ret, actual = driver.read_single(addr)
    assert(read_ret == "Success",
        "post-reset read failed: " .. tostring(read_ret))
    assert(actual:lower() == expected,
        "post-reset read data mismatch")

    print("Post-reset AXI access passed")
end

return {
    tasks = {
        task_reset
    }
}