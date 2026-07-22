-- src/common/axi_stimulus.lua
-- 用于存放一些testcase生成随机激励时，产生随机输入信号的函数
local M = {}

-- 生成指定字节数的随机十六进制字符串。
--
-- 例如：
--   random_hex_data(4)  -> "3fa012bc"
--   random_hex_data(32) -> 64个十六进制字符，即256 bit
function M.random_hex_data(byte_count)
    local parts = {}

    for byte = 1, byte_count do
        -- 每次只生成0～255，确保math.random参数在安全范围内。
        local random_byte = math.random(0, 255)

        -- %02x表示转换成两个十六进制字符。
        -- 不足两位时在左侧补0：
        --   0   -> "00"
        --   5   -> "05"
        --   255 -> "ff"
        parts[byte] = string.format("%02x", random_byte)
    end

    return table.concat(parts)
end

-- 生成随机合法的burst和len组合
function M.random_burst_len(options)
    options = options or {}
    local max_incr_len = options.max_incr_len or 255

    assert(
        type(max_incr_len) == "number" and
            max_incr_len == math.floor(max_incr_len) and
            max_incr_len >= 0 and max_incr_len <= 255,
        "max_incr_len must be an integer in range 0..255"
    )

    local burst = math.random(0, 2)

    if burst == 0 then
        return burst, math.random(0, 15)
    elseif burst == 1 then
        return burst, math.random(0, max_incr_len)
    else
        local wrap_lens = { 1, 3, 7, 15 }
        return burst, wrap_lens[math.random(1, #wrap_lens)]
    end
end

-- 生成随机合法的AXI地址，确保burst footprint不跨页。
function M.random_legal_addr(len, size, burst)
    local bytes_per_beat = 2 ^ size

    local footprint
    if burst == 0 then
        footprint = bytes_per_beat
    else
        footprint = (len + 1) * bytes_per_beat
    end

    assert(
        footprint <= 4096,
        "\n\n---ERROR---\n\nburst footprint exceeds one 4KB page\n\n-----------\n\n"
    )

    -- 分两段产生36位页号，避免给math.random传入过大的上限。
    local page_number =
        math.random(0, 0x3ffff) * 0x40000 +
        math.random(0, 0x3ffff)

    local page_base = page_number * 4096
    local max_slot = math.floor((4096 - footprint) / bytes_per_beat)
    local offset = math.random(0, max_slot) * bytes_per_beat

    return page_base + offset
end

-- 窄传输
function M.make_strb(beat_addr, size, bus_bytes)
    local transfer_bytes = 2 ^ size
    local byte_offset = beat_addr % 32

    assert(
        byte_offset + transfer_bytes <= 32,
        "\n\n---ERROR---\n\ntransfer crosses the 256-bit data-bus boundary\n\n-----------\n\n"
    )

    if transfer_bytes == 32 then
        return "ffffffff"
    end

    local mask = (2 ^ transfer_bytes - 1) * (2 ^ byte_offset)
    return string.format("%08x", mask)
end

function M.get_beat_addr(start_addr, burst, len, size, beat_index)
    local bytes_per_beat = 2 ^ size

    if burst == 0 then
        return start_addr
    elseif burst == 1 then
        return start_addr + beat_index * bytes_per_beat
    else
        local wrap_size = (len + 1) * bytes_per_beat
        local wrap_base = math.floor(start_addr / wrap_size) * wrap_size

        return wrap_base +
            ((start_addr - wrap_base + beat_index * bytes_per_beat)
                % wrap_size)
    end
end

return M
