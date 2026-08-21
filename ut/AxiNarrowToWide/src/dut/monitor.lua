local signals = require "dut.signals"
local cfg = require "cfg"

local M = {}
local subscribers = {}

function M.subscribe(callback)
    assert(type(callback) == "function", "monitor subscriber must be a function")
    subscribers[#subscribers + 1] = callback
end

local function sample_ax(channel)
    return {
        ready = channel.ready:get(),
        valid = channel.valid:get(),
        bits = {
            id = channel.id:get(),
            addr = channel.addr:get(),
            len = channel.len:get(),
            size = channel.size:get(),
            burst = channel.burst:get(),
            lock = channel.lock:get(),
            cache = channel.cache:get(),
            prot = channel.prot:get(),
            qos = channel.qos:get(),
            region = channel.region:get(),
        },
    }
end

local function sample_w(channel)
    return {
        ready = channel.ready:get(),
        valid = channel.valid:get(),
        bits = {
            data = channel.data:get_hex_str(),
            strb = channel.strb:get_hex_str(),
            last = channel.last:get(),
        },
    }
end

local function sample_b(channel)
    return {
        ready = channel.ready:get(),
        valid = channel.valid:get(),
        bits = {
            id = channel.id:get(),
            resp = channel.resp:get(),
        },
    }
end

local function sample_r(channel)
    return {
        ready = channel.ready:get(),
        valid = channel.valid:get(),
        bits = {
            id = channel.id:get(),
            data = channel.data:get_hex_str(),
            resp = channel.resp:get(),
            last = channel.last:get(),
        },
    }
end

local bundles = {
    mst_aw = {
        ready = signals.io_mst_aw_ready,
        valid = signals.io_mst_aw_valid,
        id = signals.io_mst_aw_bits_id,
        addr = signals.io_mst_aw_bits_addr,
        len = signals.io_mst_aw_bits_len,
        size = signals.io_mst_aw_bits_size,
        burst = signals.io_mst_aw_bits_burst,
        lock = signals.io_mst_aw_bits_lock,
        cache = signals.io_mst_aw_bits_cache,
        prot = signals.io_mst_aw_bits_prot,
        qos = signals.io_mst_aw_bits_qos,
        region = signals.io_mst_aw_bits_region,
    },
    mst_ar = {
        ready = signals.io_mst_ar_ready,
        valid = signals.io_mst_ar_valid,
        id = signals.io_mst_ar_bits_id,
        addr = signals.io_mst_ar_bits_addr,
        len = signals.io_mst_ar_bits_len,
        size = signals.io_mst_ar_bits_size,
        burst = signals.io_mst_ar_bits_burst,
        lock = signals.io_mst_ar_bits_lock,
        cache = signals.io_mst_ar_bits_cache,
        prot = signals.io_mst_ar_bits_prot,
        qos = signals.io_mst_ar_bits_qos,
        region = signals.io_mst_ar_bits_region,
    },
    mst_w = {
        ready = signals.io_mst_w_ready,
        valid = signals.io_mst_w_valid,
        data = signals.io_mst_w_bits_data,
        strb = signals.io_mst_w_bits_strb,
        last = signals.io_mst_w_bits_last,
    },
    mst_b = {
        ready = signals.io_mst_b_ready,
        valid = signals.io_mst_b_valid,
        id = signals.io_mst_b_bits_id,
        resp = signals.io_mst_b_bits_resp,
    },
    mst_r = {
        ready = signals.io_mst_r_ready,
        valid = signals.io_mst_r_valid,
        id = signals.io_mst_r_bits_id,
        data = signals.io_mst_r_bits_data,
        resp = signals.io_mst_r_bits_resp,
        last = signals.io_mst_r_bits_last,
    },
    slv_aw = {
        ready = signals.io_slv_aw_ready,
        valid = signals.io_slv_aw_valid,
        id = signals.io_slv_aw_bits_id,
        addr = signals.io_slv_aw_bits_addr,
        len = signals.io_slv_aw_bits_len,
        size = signals.io_slv_aw_bits_size,
        burst = signals.io_slv_aw_bits_burst,
        lock = signals.io_slv_aw_bits_lock,
        cache = signals.io_slv_aw_bits_cache,
        prot = signals.io_slv_aw_bits_prot,
        qos = signals.io_slv_aw_bits_qos,
        region = signals.io_slv_aw_bits_region,
    },
    slv_ar = {
        ready = signals.io_slv_ar_ready,
        valid = signals.io_slv_ar_valid,
        id = signals.io_slv_ar_bits_id,
        addr = signals.io_slv_ar_bits_addr,
        len = signals.io_slv_ar_bits_len,
        size = signals.io_slv_ar_bits_size,
        burst = signals.io_slv_ar_bits_burst,
        lock = signals.io_slv_ar_bits_lock,
        cache = signals.io_slv_ar_bits_cache,
        prot = signals.io_slv_ar_bits_prot,
        qos = signals.io_slv_ar_bits_qos,
        region = signals.io_slv_ar_bits_region,
    },
    slv_w = {
        ready = signals.io_slv_w_ready,
        valid = signals.io_slv_w_valid,
        data = signals.io_slv_w_bits_data,
        strb = signals.io_slv_w_bits_strb,
        last = signals.io_slv_w_bits_last,
    },
    slv_b = {
        ready = signals.io_slv_b_ready,
        valid = signals.io_slv_b_valid,
        id = signals.io_slv_b_bits_id,
        resp = signals.io_slv_b_bits_resp,
    },
    slv_r = {
        ready = signals.io_slv_r_ready,
        valid = signals.io_slv_r_valid,
        id = signals.io_slv_r_bits_id,
        data = signals.io_slv_r_bits_data,
        resp = signals.io_slv_r_bits_resp,
        last = signals.io_slv_r_bits_last,
    },
}

function M.sample(cycles)
    if not cfg.enable_monitor then
        return nil
    end

    local sample = {
        cycles = cycles,
        reset = signals.reset:get(),
        io = {
            mst_aw = sample_ax(bundles.mst_aw),
            mst_ar = sample_ax(bundles.mst_ar),
            mst_w = sample_w(bundles.mst_w),
            mst_b = sample_b(bundles.mst_b),
            mst_r = sample_r(bundles.mst_r),
            slv_aw = sample_ax(bundles.slv_aw),
            slv_ar = sample_ax(bundles.slv_ar),
            slv_w = sample_w(bundles.slv_w),
            slv_b = sample_b(bundles.slv_b),
            slv_r = sample_r(bundles.slv_r),
        },
    }

    for _, callback in ipairs(subscribers) do
        callback(sample)
    end

    return sample
end

return M
