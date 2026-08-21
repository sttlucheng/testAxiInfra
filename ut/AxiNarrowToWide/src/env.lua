local clock_reset = require "common.clock_reset"
local signals = require "dut.signals"
local monitor = require "dut.monitor"
require "dut.scoreboard"

local M = {}
local has_monitor_task = false

local function monitor_task()
    local cycles = dut.cycles:get()
    while true do
        monitor.sample(cycles)
        if cycles % 10000 == 0 then
            print("Running...", cycles)
        end
        signals.clock:posedge()
        cycles = cycles + 1
    end
end

function M.drive_default()
    dut.io_mst_aw_valid:set(0)
    dut.io_mst_aw_bits_id:set(0)
    dut.io_mst_aw_bits_addr:set(0)
    dut.io_mst_aw_bits_len:set(0)
    dut.io_mst_aw_bits_size:set(0)
    dut.io_mst_aw_bits_burst:set(0)
    dut.io_mst_aw_bits_lock:set(0)
    dut.io_mst_aw_bits_cache:set(0)
    dut.io_mst_aw_bits_prot:set(0)
    dut.io_mst_aw_bits_qos:set(0)
    dut.io_mst_aw_bits_region:set(0)

    dut.io_mst_ar_valid:set(0)
    dut.io_mst_ar_bits_id:set(0)
    dut.io_mst_ar_bits_addr:set(0)
    dut.io_mst_ar_bits_len:set(0)
    dut.io_mst_ar_bits_size:set(0)
    dut.io_mst_ar_bits_burst:set(0)
    dut.io_mst_ar_bits_lock:set(0)
    dut.io_mst_ar_bits_cache:set(0)
    dut.io_mst_ar_bits_prot:set(0)
    dut.io_mst_ar_bits_qos:set(0)
    dut.io_mst_ar_bits_region:set(0)

    dut.io_mst_w_valid:set(0)
    dut.io_mst_w_bits_data:set(0)
    dut.io_mst_w_bits_strb:set(0)
    dut.io_mst_w_bits_last:set(0)
    dut.io_mst_b_ready:set(0)
    dut.io_mst_r_ready:set(0)

    dut.io_slv_aw_ready:set(0)
    dut.io_slv_ar_ready:set(0)
    dut.io_slv_w_ready:set(0)
    dut.io_slv_b_valid:set(0)
    dut.io_slv_b_bits_id:set(0)
    dut.io_slv_b_bits_resp:set(0)
    dut.io_slv_r_valid:set(0)
    dut.io_slv_r_bits_id:set(0)
    dut.io_slv_r_bits_data:set(0)
    dut.io_slv_r_bits_resp:set(0)
    dut.io_slv_r_bits_last:set(0)
end

function M.dut_reset()
    M.drive_default()
    clock_reset.reset(10)
end

function M.wait_cycles(n)
    clock_reset.wait_cycles(n)
end

function M.launch_monitor_task()
    if not has_monitor_task then
        has_monitor_task = true
        scheduler:append_task(nil, "axi_narrow_to_wide_monitor", monitor_task, true)
    end
end

function M.test_success()
    print("=== TEST PASSED ===")
    io.flush()
end

return M
