local monitor = require "dut.monitor"
local driver = require "dut.driver"

local M = {}
local AX_FIELDS = { "id", "addr", "len", "size", "burst", "lock", "cache", "prot", "qos", "region" }

local function new_queue()
    return { first = 1, last = 0 }
end

local function queue_count(queue)
    return queue.last - queue.first + 1
end

local function push(queue, value)
    queue.last = queue.last + 1
    queue[queue.last] = value
end

local function peek(queue, name)
    assert(queue_count(queue) > 0, name .. " queue is empty")
    return queue[queue.first]
end

local function pop(queue, name)
    local value = peek(queue, name)
    queue[queue.first] = nil
    queue.first = queue.first + 1
    return value
end

local function clear_queue(queue)
    for index = queue.first, queue.last do
        queue[index] = nil
    end
    queue.first = 1
    queue.last = 0
end

local function fired(channel)
    return channel.valid == 1 and channel.ready == 1
end

local function assert_equal(name, actual, expected, cycles)
    assert(actual == expected, string.format(
        "%s mismatch at cycle %s: expected=%s actual=%s",
        name,
        tostring(cycles),
        tostring(expected),
        tostring(actual)
    ))
end

local function normalize_hex(value, digits, name)
    local text = tostring(value):lower():gsub("^0x", "")
    assert(text:match("^[0-9a-f]+$"), name .. " contains non-hexadecimal data: " .. text)
    assert(#text <= digits, string.format("%s is wider than %d hex digits: %s", name, digits, text))
    return string.rep("0", digits - #text) .. text
end

local function next_addr(addr, burst, len, size)
    local bytes = 2 ^ size
    if burst == 0 then
        return addr
    end
    if burst == 1 then
        return addr + bytes
    end

    local wrap_bytes = (len + 1) * bytes
    local wrap_base = math.floor(addr / wrap_bytes) * wrap_bytes
    return wrap_base + ((addr - wrap_base + bytes) % wrap_bytes)
end

local function lane_for_addr(addr)
    return math.floor((addr % 32) / 16)
end

local function expected_wdata(narrow_data)
    narrow_data = normalize_hex(narrow_data, 32, "upstream WDATA")
    return narrow_data .. narrow_data
end

local function expected_wstrb(narrow_strb, lane)
    narrow_strb = normalize_hex(narrow_strb, 4, "upstream WSTRB")
    if lane == 0 then
        return "0000" .. narrow_strb
    end
    return narrow_strb .. "0000"
end

local function expected_rdata(wide_data, lane)
    wide_data = normalize_hex(wide_data, 64, "downstream RDATA")
    if lane == 0 then
        return wide_data:sub(33, 64)
    end
    return wide_data:sub(1, 32)
end

local write_data_queue = new_queue()
local write_context_queue = new_queue()
local wide_read_queue = new_queue()
local read_contexts = {}
local sample_count = 0

local function clear_read_contexts()
    for id in pairs(read_contexts) do
        read_contexts[id] = nil
    end
end

local function reset_state()
    clear_queue(write_data_queue)
    clear_queue(write_context_queue)
    clear_queue(wide_read_queue)
    clear_read_contexts()
end

local function compare_ax(mst, slv, name, cycles)
    assert_equal(name .. " handshake", fired(mst), fired(slv), cycles)
    if fired(mst) then
        for _, field in ipairs(AX_FIELDS) do
            assert_equal(name .. "." .. field, slv.bits[field], mst.bits[field], cycles)
        end
    end
end

local function check_direct_b(sample)
    local mst = sample.io.mst_b
    local slv = sample.io.slv_b
    assert_equal("B.valid", mst.valid, slv.valid, sample.cycles)
    assert_equal("B.ready", slv.ready, mst.ready, sample.cycles)
    if slv.valid == 1 then
        assert_equal("B.id", mst.bits.id, slv.bits.id, sample.cycles)
        assert_equal("B.resp", mst.bits.resp, slv.bits.resp, sample.cycles)
    end
end

local function handle_mst_r(sample)
    local mst_r = sample.io.mst_r
    if not fired(mst_r) then
        return
    end

    local wide = pop(wide_read_queue, "downstream R")
    assert_equal("R.id", mst_r.bits.id, wide.id, sample.cycles)
    assert_equal("R.resp", mst_r.bits.resp, wide.resp, sample.cycles)
    assert_equal("R.last", mst_r.bits.last, wide.last, sample.cycles)

    local contexts = read_contexts[mst_r.bits.id]
    assert(contexts ~= nil, string.format(
        "R response for id %s has no AR context at cycle %s",
        tostring(mst_r.bits.id),
        tostring(sample.cycles)
    ))
    local context = peek(contexts, "AR context")
    local expected = expected_rdata(wide.data, lane_for_addr(context.addr))
    assert_equal(
        "R.data",
        normalize_hex(mst_r.bits.data, 32, "upstream RDATA"),
        expected,
        sample.cycles
    )

    if mst_r.bits.last == 1 then
        assert_equal("R beat index", context.beat, context.len, sample.cycles)
        pop(contexts, "AR context")
        if queue_count(contexts) == 0 then
            read_contexts[mst_r.bits.id] = nil
        end
    else
        assert(context.beat < context.len, "R transaction returned too many non-last beats")
        context.beat = context.beat + 1
        context.addr = next_addr(context.addr, context.burst, context.len, context.size)
    end
end

local function handle_slv_w(sample)
    local slv_w = sample.io.slv_w
    if not fired(slv_w) then
        return
    end

    local upstream = pop(write_data_queue, "upstream W")
    local context = peek(write_context_queue, "AW context")
    local lane = lane_for_addr(context.addr)

    assert_equal(
        "W.data",
        normalize_hex(slv_w.bits.data, 64, "downstream WDATA"),
        expected_wdata(upstream.data),
        sample.cycles
    )
    assert_equal(
        "W.strb",
        normalize_hex(slv_w.bits.strb, 8, "downstream WSTRB"),
        expected_wstrb(upstream.strb, lane),
        sample.cycles
    )
    assert_equal("W.last", slv_w.bits.last, upstream.last, sample.cycles)

    if slv_w.bits.last == 1 then
        assert_equal("W beat index", context.beat, context.len, sample.cycles)
        pop(write_context_queue, "AW context")
    else
        assert(context.beat < context.len, "W transaction returned too many non-last beats")
        context.beat = context.beat + 1
        context.addr = next_addr(context.addr, context.burst, context.len, context.size)
    end
end

local function handle_addresses(sample)
    local mst_aw = sample.io.mst_aw
    if fired(mst_aw) then
        push(write_context_queue, {
            addr = mst_aw.bits.addr,
            len = mst_aw.bits.len,
            size = mst_aw.bits.size,
            burst = mst_aw.bits.burst,
            beat = 0,
        })
    end

    local mst_ar = sample.io.mst_ar
    if fired(mst_ar) then
        local id = mst_ar.bits.id
        local contexts = read_contexts[id]
        if contexts == nil then
            contexts = new_queue()
            read_contexts[id] = contexts
        end
        push(contexts, {
            addr = mst_ar.bits.addr,
            len = mst_ar.bits.len,
            size = mst_ar.bits.size,
            burst = mst_ar.bits.burst,
            beat = 0,
        })
    end
end

function M.observe(sample)
    if sample == nil then
        return
    end
    sample_count = sample_count + 1

    if sample.reset == 1 then
        reset_state()
        return
    end

    compare_ax(sample.io.mst_aw, sample.io.slv_aw, "AW", sample.cycles)
    compare_ax(sample.io.mst_ar, sample.io.slv_ar, "AR", sample.cycles)
    check_direct_b(sample)

    -- Registered queues can dequeue an old beat while accepting a new beat.
    -- Consume outputs before recording same-cycle inputs to preserve that order.
    handle_mst_r(sample)
    handle_slv_w(sample)

    if fired(sample.io.slv_r) then
        push(wide_read_queue, {
            id = sample.io.slv_r.bits.id,
            data = sample.io.slv_r.bits.data,
            resp = sample.io.slv_r.bits.resp,
            last = sample.io.slv_r.bits.last,
        })
    end

    handle_addresses(sample)

    if fired(sample.io.mst_w) then
        push(write_data_queue, {
            data = sample.io.mst_w.bits.data,
            strb = sample.io.mst_w.bits.strb,
            last = sample.io.mst_w.bits.last,
        })
    end
end

function M.finish_auto_check()
    assert(sample_count > 0, "monitor did not publish any samples")
    assert_equal("pending upstream W beats", queue_count(write_data_queue), 0, "finish")
    assert_equal("pending AW contexts", queue_count(write_context_queue), 0, "finish")
    assert_equal("pending downstream R beats", queue_count(wide_read_queue), 0, "finish")
    for id, contexts in pairs(read_contexts) do
        assert_equal("pending AR contexts for id " .. tostring(id), queue_count(contexts), 0, "finish")
    end
    assert(not driver.has_pending(), "AXI driver or memory still has pending transactions")
end

monitor.subscribe(M.observe)

return M
