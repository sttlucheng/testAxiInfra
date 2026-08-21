local env = require "env"
local scoreboard = require "dut.scoreboard"
local tc_name = assert(os.getenv "TC_NAME", "failed to get TC_NAME")

fork {
    main_task = function()
        if os.getenv "DUMP" then
            sim.dump_wave((os.getenv("TC") or "sim") .. ".vcd")
        end

        local seed_text = os.getenv("SEED") or "1"
        local seed = assert(tonumber(seed_text), "SEED must be a number: " .. seed_text)
        assert(seed == math.floor(seed), "SEED must be an integer: " .. seed_text)
        math.randomseed(seed)
        print(string.format("Testcase: %s, random seed: %d", tc_name, seed))

        local tc = require(tc_name)

        env.dut_reset()
        env.launch_monitor_task()
        for _, task in ipairs(tc.tasks) do
            task()
        end

        env.wait_cycles(1)
        scoreboard.finish_auto_check()
        env.test_success()
        sim.finish()
    end,
}
