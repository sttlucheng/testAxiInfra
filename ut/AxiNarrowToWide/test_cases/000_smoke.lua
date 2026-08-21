local env = require "env"
local driver = require "dut.driver"

local function assert_success(operation, result)
    assert(result == "Success", string.format("%s failed: %s", operation, tostring(result)))
end

local function check_readback(addr, write_data, lane_name)
    local read_result, read_data = driver.read_single(addr)
    assert_success("read " .. lane_name, read_result)
    assert(read_data ~= nil, "read " .. lane_name .. " completed without data")
    assert(read_data:lower() == write_data:lower(), string.format(
        "%s readback mismatch: expected=%s actual=%s",
        lane_name,
        write_data,
        tostring(read_data)
    ))
end

local function task_smoke()
    driver.initialize()
    env.wait_cycles(1)

    -- These addresses select the low and high 128-bit lanes of one 256-bit word.
    local lane_0_data = "00112233445566778899aabbccddeeff"
    local lane_1_data = "fedcba98765432100123456789abcdef"

    assert_success("write lane 0", driver.write_single(0x1000, lane_0_data))
    assert_success("write lane 1", driver.write_single(0x1010, lane_1_data))

    -- Read both halves after both writes to catch accidental cross-lane overwrite.
    check_readback(0x1000, lane_0_data, "lane 0")
    check_readback(0x1010, lane_1_data, "lane 1")
end

return {
    tasks = {
        task_smoke,
    },
}
