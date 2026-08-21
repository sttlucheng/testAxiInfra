local M = {}

local clock = dut.clock:chdl()
local reset = dut.reset:chdl()

function M.wait_cycles(n)
    clock:posedge(n or 1)
end

function M.reset(cycles)
    reset:set_imm(1)
    clock:posedge(cycles or 10)
    reset:set_imm(0)
end

M.clock = clock
M.reset_chdl = reset

return M
