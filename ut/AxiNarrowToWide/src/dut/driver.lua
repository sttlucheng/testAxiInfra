local AXI4Master = require "AXI4MasterV2"
local AXI4Memory = require "AXI4Memory"

local M = {}
local DUT_HIER = "tb_top"

local function make_ax_bundle(prefix, name)
    return ([[
        | valid      => valid
        | ready      => ready
        | bits_id    => id
        | bits_addr  => addr
        | bits_len   => len
        | bits_size  => size
        | bits_burst => burst
        | bits_cache => cache
        | bits_qos   => qos
    ]]):abdl {
        hier = DUT_HIER,
        prefix = prefix,
        name = name,
    }
end

local function make_w_bundle(prefix, name)
    return ([[
        | valid     => valid
        | ready     => ready
        | bits_data => data
        | bits_strb => strb
        | bits_last => last
    ]]):abdl {
        hier = DUT_HIER,
        prefix = prefix,
        name = name,
    }
end

local function make_b_bundle(prefix, name)
    return ([[
        | valid     => valid
        | ready     => ready
        | bits_id   => id
        | bits_resp => resp
    ]]):abdl {
        hier = DUT_HIER,
        prefix = prefix,
        name = name,
    }
end

local function make_r_bundle(prefix, name)
    return ([[
        | valid     => valid
        | ready     => ready
        | bits_id   => id
        | bits_data => data
        | bits_resp => resp
        | bits_last => last
    ]]):abdl {
        hier = DUT_HIER,
        prefix = prefix,
        name = name,
    }
end

local mst_ar = make_ax_bundle("io_mst_ar_", "MST_AR")
local mst_r = make_r_bundle("io_mst_r_", "MST_R")
local mst_aw = make_ax_bundle("io_mst_aw_", "MST_AW")
local mst_w = make_w_bundle("io_mst_w_", "MST_W")
local mst_b = make_b_bundle("io_mst_b_", "MST_B")

local axi_master = AXI4Master(
    "axi_narrow_master",
    mst_ar,
    mst_r,
    mst_aw,
    mst_w,
    mst_b,
    {
        clock_chdl = dut.clock:chdl(),
        nr_task = 8,
        timeout_max = 200000,
        agent_options = {
            clock_chdl = dut.clock:chdl(),
            cycles_chdl = dut.cycles:chdl(),
            verbose = false,
            enable_randomize_fields = false,
            nr_ar_taskbuf = 8,
            nr_aw_taskbuf = 8,
            nr_w_taskbuf = 8,
            enable_ar_delay = false,
            enable_aw_delay = false,
            enable_w_delay = false,
            enable_r_delay = false,
            enable_b_delay = false,
            random_delay = false,
        },
    }
)

local slv_ar = make_ax_bundle("io_slv_ar_", "SLV_AR")
local slv_r = make_r_bundle("io_slv_r_", "SLV_R")
local slv_aw = make_ax_bundle("io_slv_aw_", "SLV_AW")
local slv_w = make_w_bundle("io_slv_w_", "SLV_W")
local slv_b = make_b_bundle("io_slv_b_", "SLV_B")

local axi_memory = AXI4Memory(
    "axi_wide_memory",
    slv_ar,
    slv_r,
    slv_aw,
    slv_w,
    slv_b,
    {
        clock_chdl = dut.clock:chdl(),
        cycles_chdl = dut.cycles:chdl(),
        data_width = 256,
        verbose = false,
        enable_randomize_fields = false,
        enable_ar_delay = false,
        enable_aw_delay = false,
        enable_w_delay = false,
        enable_r_delay = false,
        enable_b_delay = false,
        random_delay = false,
        shuffle_r = false,
        shuffle_b = false,
        nr_r_taskbuf = 8,
        nr_w_taskbuf = 8,
        nr_b_taskbuf = 8,
        strict_wdata = false,
    }
)

local initialized = false
local BURST_INCR = 1
local AXI_SIZE_16_BYTES = 4
local FULL_STRB_128 = "ffff"

local function check_data(data_hex)
    assert(type(data_hex) == "string", "write data must be a hexadecimal string")
    assert(#data_hex == 32, string.format(
        "128-bit write data must contain 32 hex characters, got %d",
        #data_hex
    ))
    assert(data_hex:match("^[0-9a-fA-F]+$"), "write data contains invalid hex characters")
end

local function check_addr(addr)
    assert(type(addr) == "number", "AXI address must be a number")
    assert(addr >= 0, "AXI address must not be negative")
    assert(addr % 16 == 0, "single-beat 128-bit access must be 16-byte aligned")
end

function M.initialize()
    if initialized then
        return
    end

    initialized = true
    axi_master:initialize()
    axi_memory:initialize()
end

function M.write_single(addr, data_hex)
    assert(initialized, "driver.initialize() must be called before write_single()")
    check_addr(addr)
    check_data(data_hex)

    return axi_master:block_write(
        addr,
        BURST_INCR,
        0,
        AXI_SIZE_16_BYTES,
        { data_hex },
        { FULL_STRB_128 }
    )
end

function M.read_single(addr)
    assert(initialized, "driver.initialize() must be called before read_single()")
    check_addr(addr)

    local read_data_hex = nil
    local ret = axi_master:block_read(
        addr,
        BURST_INCR,
        0,
        AXI_SIZE_16_BYTES,
        {
            finish_callback = function(task)
                read_data_hex = task.read_data_hex_str_vec[1]
            end,
        }
    )

    return ret, read_data_hex
end

function M.has_pending()
    if not initialized then
        return false
    end
    return axi_master:has_valid_task() or axi_memory:has_valid_task()
end

return M
