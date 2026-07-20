local monitor = require "dut.monitor"
local M = {}

-- 用于保存通道信息，为后续比对
local function create_channels_expect_table()
    return {
        aw = {
            id = {},
            addr = {},
            len = {},
            size = {},
            burst = {},
            lock = {},
            cache = {},
            prot = {},
            qos = {},
            region = {},
        },

        ar = {
            id = {},
            addr = {},
            len = {},
            size = {},
            burst = {},
            lock = {},
            cache = {},
            prot = {},
            qos = {},
            region = {},
        },

        w = {
            data = {},
            strb = {},
            last = {},
        },

        r = {
            id = {},
            data = {},
            resp = {},
            last = {},
        },

        b = {
            id = {},
            resp = {},
        },
    }
end

local ChannelsExpectQueue = {}
ChannelsExpectQueue.__index = ChannelsExpectQueue

local function create_channels_expect_queue()
    return setmetatable({
        aw = {
            id = {
                first = 1,
                last = 0
            },
            addr = {
                first = 1,
                last = 0
            },
            len = {
                first = 1,
                last = 0
            },
            size = {
                first = 1,
                last = 0
            },
            burst = {
                first = 1,
                last = 0
            },
            lock = {
                first = 1,
                last = 0
            },
            cache = {
                first = 1,
                last = 0
            },
            prot = {
                first = 1,
                last = 0
            },
            qos = {
                first = 1,
                last = 0
            },
            region = {
                first = 1,
                last = 0
            },
        },

        ar = {
            id = {
                first = 1,
                last = 0
            },
            addr = {
                first = 1,
                last = 0
            },
            len = {
                first = 1,
                last = 0
            },
            size = {
                first = 1,
                last = 0
            },
            burst = {
                first = 1,
                last = 0
            },
            lock = {
                first = 1,
                last = 0
            },
            cache = {
                first = 1,
                last = 0
            },
            prot = {
                first = 1,
                last = 0
            },
            qos = {
                first = 1,
                last = 0
            },
            region = {
                first = 1,
                last = 0
            },
        },

        w = {
            data = {
                first = 1,
                last = 0
            },
            strb = {
                first = 1,
                last = 0
            },
            last = {
                first = 1,
                last = 0
            },
        },

        r = {
            id = {
                first = 1,
                last = 0
            },
            data = {
                first = 1,
                last = 0
            },
            resp = {
                first = 1,
                last = 0
            },
            last = {
                first = 1,
                last = 0
            },
        },

        b = {
            id = {
                first = 1,
                last = 0
            },
            resp = {
                first = 1,
                last = 0
            },
        },
    }, ChannelsExpectQueue)
end

-- 同id读事务记录队列
local function creat_read_matter_quene()
    return{
        upstream_id = {
            first = 1,
            last = 0
        },
        downstream_id = {
            first = 1,
            last = 0
        },
        addr = {
            first = 1,
            last = 0
        },
        len = {
            first = 1,
            last = 0
        },
        size = {
            first = 1,
            last = 0
        },
        burst = {
            first = 1,
            last = 0
        },
        lock = {
            first = 1,
            last = 0
        },
        cache = {
            first = 1,
            last = 0
        },
        prot = {
            first = 1,
            last = 0
        },
        qos = {
            first = 1,
            last = 0
        },
        region = {
            first = 1,
            last = 0
        },
    }
end

-- 同id写事务记录队列
local function creat_write_matter_quene()
    return{
        upstream_id = {
            first = 1,
            last = 0
        },
        downstream_id = {
            first = 1,
            last = 0
        },
        addr = {
            first = 1,
            last = 0
        },
        len = {
            first = 1,
            last = 0
        },
        size = {
            first = 1,
            last = 0
        },
        burst = {
            first = 1,
            last = 0
        },
        lock = {
            first = 1,
            last = 0
        },
        cache = {
            first = 1,
            last = 0
        },
        prot = {
            first = 1,
            last = 0
        },
        qos = {
            first = 1,
            last = 0
        },
        region = {
            first = 1,
            last = 0
        },
    }
end

local CHANNELS_EXPECT_TABLE = create_channels_expect_table()

local CHANNELS_EXPECT_QUEUE = create_channels_expect_queue()

-- master ID个数
local IDcount = 2^12 - 1

-- 读事务表
local READ_MATTER = {}
for i = 0, IDcount do
    READ_MATTER[i] = creat_read_matter_quene()
end

-- 写事务表
local WRITE_MATTER = {}
for i = 0, IDcount do
    WRITE_MATTER[i] = creat_write_matter_quene()
end

-- 通用入队函数
local function enqueue(queue, value)
    queue.last = queue.last + 1
    queue[queue.last] = value
end

-- 入队
function ChannelsExpectQueue:push(channel_name, sample)
    local channel = assert(
        self[channel_name],
        "unknown channel: " .. tostring(channel_name)
    )

    if channel_name == "aw" then
        enqueue(channel.id,     sample.io.mst_aw.bits.id)
        enqueue(channel.addr,   sample.io.mst_aw.bits.addr)
        enqueue(channel.len,    sample.io.mst_aw.bits.len)
        enqueue(channel.size,   sample.io.mst_aw.bits.size)
        enqueue(channel.burst,  sample.io.mst_aw.bits.burst)
        enqueue(channel.lock,   sample.io.mst_aw.bits.lock)
        enqueue(channel.cache,  sample.io.mst_aw.bits.cache)
        enqueue(channel.prot,   sample.io.mst_aw.bits.prot)
        enqueue(channel.qos,    sample.io.mst_aw.bits.qos)
        enqueue(channel.region, sample.io.mst_aw.bits.region)

    elseif channel_name == "ar" then
        enqueue(channel.id,     sample.io.mst_ar.bits.id)
        enqueue(channel.addr,   sample.io.mst_ar.bits.addr)
        enqueue(channel.len,    sample.io.mst_ar.bits.len)
        enqueue(channel.size,   sample.io.mst_ar.bits.size)
        enqueue(channel.burst,  sample.io.mst_ar.bits.burst)
        enqueue(channel.lock,   sample.io.mst_ar.bits.lock)
        enqueue(channel.cache,  sample.io.mst_ar.bits.cache)
        enqueue(channel.prot,   sample.io.mst_ar.bits.prot)
        enqueue(channel.qos,    sample.io.mst_ar.bits.qos)
        enqueue(channel.region, sample.io.mst_ar.bits.region)

    elseif channel_name == "w" then
        enqueue(channel.data, sample.io.mst_w.bits.data)
        enqueue(channel.strb, sample.io.mst_w.bits.strb)
        enqueue(channel.last, sample.io.mst_w.bits.last)

    elseif channel_name == "r" then
        enqueue(channel.id,   sample.io.slv_r.bits.id)
        enqueue(channel.data, sample.io.slv_r.bits.data)
        enqueue(channel.resp, sample.io.slv_r.bits.resp)
        enqueue(channel.last, sample.io.slv_r.bits.last)

    elseif channel_name == "b" then
        enqueue(channel.id,   sample.io.slv_b.bits.id)
        enqueue(channel.resp, sample.io.slv_b.bits.resp)

    else
        error("unsupported channel: " .. tostring(channel_name))
    end
end

-- 通用出队函数
local function dequeue(queue)
    if queue.first > queue.last then
        return nil
    end

    local value = queue[queue.first]
    queue[queue.first] = nil
    queue.first = queue.first + 1

    return value
end

-- 出队
function ChannelsExpectQueue:pop(channel_name)
    local channel = assert(
        self[channel_name],
        "unknown channel: " .. tostring(channel_name)
    )

    -- 每个通道选择一个代表队列检查是否为空
    local check_queue = channel.id or channel.data

    if check_queue.first > check_queue.last then
        return nil
    end

    if channel_name == "aw" then
        return {
            id     = dequeue(channel.id),
            addr   = dequeue(channel.addr),
            len    = dequeue(channel.len),
            size   = dequeue(channel.size),
            burst  = dequeue(channel.burst),
            lock   = dequeue(channel.lock),
            cache  = dequeue(channel.cache),
            prot   = dequeue(channel.prot),
            qos    = dequeue(channel.qos),
            region = dequeue(channel.region),
        }
    elseif channel_name == "ar" then
        return {
            id     = dequeue(channel.id),
            addr   = dequeue(channel.addr),
            len    = dequeue(channel.len),
            size   = dequeue(channel.size),
            burst  = dequeue(channel.burst),
            lock   = dequeue(channel.lock),
            cache  = dequeue(channel.cache),
            prot   = dequeue(channel.prot),
            qos    = dequeue(channel.qos),
            region = dequeue(channel.region),
        }
    elseif channel_name == "w" then
        return {
            data = dequeue(channel.data),
            strb = dequeue(channel.strb),
            last = dequeue(channel.last),
        }
    elseif channel_name == "r" then
        return {
            id   = dequeue(channel.id),
            data = dequeue(channel.data),
            resp = dequeue(channel.resp),
            last = dequeue(channel.last),
        }
    elseif channel_name == "b" then
        return {
            id   = dequeue(channel.id),
            resp = dequeue(channel.resp),
        }
    else
        error("unsupported channel: " .. tostring(channel_name))
    end
end



-- reset复位时，比对逻辑
local function reset_auto_check(sample)
            -- reset经过有效时钟沿后，所有AR/AW entry应为空闲，
            -- 所以DUT能够接收新的地址请求。
            assert(sample.io.mst_ar.ready == 1, 
            "\n\n------------ERROR---------------\n\nAR entry not empty after reset\n\n---------------------------------\n\n")
            assert(sample.io.mst_aw.ready == 1, 
            "\n\n------------ERROR---------------\n\nAW entry not empty after reset\n\n--------------------------------\n\n")

            -- reset后尚未接收AW，写事务队列为空，
            -- 因此不能接收没有对应地址的W数据。
            assert(sample.io.mst_w.ready == 0, "\n\n------------ERROR---------------\n\nW entry not empty after reset\n\n---------------------------------\n\n")

            -- 复位期间DUT不应向 downstream 发出请求。
            assert(sample.io.slv_ar.valid == 0, "\n\n------------ERROR---------------\n\nAR valid asserted during reset\n\n---------------------------------\n\n")
            assert(sample.io.slv_aw.valid == 0, "\n\n------------ERROR---------------\n\nAW valid asserted during reset\n\n---------------------------------\n\n")
            assert(sample.io.slv_w.valid == 0, "\n\n------------ERROR---------------\n\nW valid asserted during reset\n\n---------------------------------\n\n")

            -- 下游响应输入已经被env.drive_default()清零，
            -- 因此DUT不应向上游产生响应。
            assert(sample.io.mst_r.valid == 0, "\n\n------------ERROR---------------\n\nR valid asserted during reset\n\n---------------------------------\n\n")
            assert(sample.io.mst_b.valid == 0, "\n\n------------ERROR---------------\n\nB valid asserted during reset\n\n---------------------------------\n\n")
end

-- 通道是否握手成功
local function channel_fired(channel_name, sample)
    return sample.io[channel_name].valid == 1 and sample.io[channel_name].ready == 1
end

-- 记录通道握手成功的事务,用队列储存,先进先出
local function channel_fired_transaction_queue(channel_name, expected_channel, sample)
    if not channel_fired(channel_name, sample) then
        return
    end
    CHANNELS_EXPECT_QUEUE:push(expected_channel, sample)
end

-- 记录通道握手成功的事务,用非队列储存,避免先进先出，顺序比对
local function channel_fired_transaction(channel_name, expected_channel, fields, sample)
    if not channel_fired(channel_name, sample) then
        return
    end

    local bits = sample.io[channel_name].bits
    local expected = CHANNELS_EXPECT_TABLE[expected_channel]
    for _, field in ipairs(fields) do
        expected[field][#expected[field] + 1] = bits[field]
    end
end

-- 顺序比对
local function channel_fired_check_queue(channel_name, expected_channel, sample, feilds)
    if not channel_fired(channel_name, sample) then
        return
    end

    local expected = assert(
        CHANNELS_EXPECT_QUEUE:pop(expected_channel),
        string.format(
            "\n\n---ERROR---\n\nexpected queue %s mismatch %s\n\n-----------\n\n",
            expected_channel,
            channel_name
        )
    )

    for _, field in pairs(feilds) do
        local expected_value = expected[field]
        local actual_value = sample.io[channel_name].bits[field]

        assert(
            expected_value == actual_value,
            string.format(
                "\n\n---ERROR---\n\n%s automatic check %s mismatch: expected=%s actual=%s cycle=%s\n\n-----------\n\n",
                channel_name,
                field,
                tostring(expected_value),
                tostring(actual_value),
                tostring(sample.cycles)
            )
        )
    end
end



-- 比对table中是否有对应项，若有删除对应项
local function remove_matching(channel, expected, fields)
    local count = #channel[fields[1]]

    for index = 1, count do
        local matched = true

        for _, field in ipairs(fields) do
            if channel[field][index] ~= expected[field] then
                matched = false
                break
            end
        end

        if matched then
            -- 所有字段必须删除相同的下标
            for _, field in ipairs(fields) do
                table.remove(channel[field], index)
            end

            return true, index
        end
    end

    return false, nil
end

-- 非顺序比对
local function channel_fired_check(io_channel, expected_channel, fields, sample)
    if not channel_fired(io_channel, sample) then
        return
    end

    local actual = sample.io[io_channel].bits
    local expected = CHANNELS_EXPECT_TABLE[expected_channel]
    local matched = remove_matching(expected, actual, fields)

    assert(
        matched,
        string.format(
            "\n\n---ERROR---\n\n%s has no matching expected transaction, cycle=%s\n\n-----------\n\n",
            io_channel,
            tostring(sample.cycles)
        )
    )
end

-- 读事务入队
function READ_MATTER:push(sample)
    if channel_fired("mst_ar", sample) then
        enqueue(READ_MATTER[sample.io.mst_ar.bits.id].upstream_id,     sample.io.mst_ar.bits.id)
        enqueue(READ_MATTER[sample.io.mst_ar.bits.id].addr,   sample.io.mst_ar.bits.addr)
        enqueue(READ_MATTER[sample.io.mst_ar.bits.id].len,    sample.io.mst_ar.bits.len)
        enqueue(READ_MATTER[sample.io.mst_ar.bits.id].size,   sample.io.mst_ar.bits.size)
        enqueue(READ_MATTER[sample.io.mst_ar.bits.id].burst,  sample.io.mst_ar.bits.burst)
        enqueue(READ_MATTER[sample.io.mst_ar.bits.id].lock,   sample.io.mst_ar.bits.lock)
        enqueue(READ_MATTER[sample.io.mst_ar.bits.id].cache,  sample.io.mst_ar.bits.cache)
        enqueue(READ_MATTER[sample.io.mst_ar.bits.id].prot,   sample.io.mst_ar.bits.prot)
        enqueue(READ_MATTER[sample.io.mst_ar.bits.id].qos,    sample.io.mst_ar.bits.qos)
        enqueue(READ_MATTER[sample.io.mst_ar.bits.id].region, sample.io.mst_ar.bits.region)
    end

    if channel_fired("slv_ar", sample) then
        local j = 0
        for i = 0, #READ_MATTER do
            j = 0  -- 用于判断是否找到了对应读事务
            if  READ_MATTER[i].addr[READ_MATTER[i].addr.first] == sample.io.slv_ar.bits.addr and
                READ_MATTER[i].len[READ_MATTER[i].len.first] == sample.io.slv_ar.bits.len and
                READ_MATTER[i].size[READ_MATTER[i].size.first] == sample.io.slv_ar.bits.size and
                READ_MATTER[i].burst[READ_MATTER[i].burst.first] == sample.io.slv_ar.bits.burst and
                READ_MATTER[i].lock[READ_MATTER[i].lock.first] == sample.io.slv_ar.bits.lock and
                READ_MATTER[i].cache[READ_MATTER[i].cache.first] == sample.io.slv_ar.bits.cache and
                READ_MATTER[i].prot[READ_MATTER[i].prot.first] == sample.io.slv_ar.bits.prot and
                READ_MATTER[i].qos[READ_MATTER[i].qos.first] == sample.io.slv_ar.bits.qos and
                READ_MATTER[i].region[READ_MATTER[i].region.first] == sample.io.slv_ar.bits.region then
                
                    enqueue(READ_MATTER[i].downstream_id,     sample.io.slv_ar.bits.id)
                    j = 1
                    break
            end
        end
        assert(j == 1,"\n\n---ERROR--\n\nar channnel sameID out-of-order\n\n--------\n\n")
    end

end

-- 读事务出队
function READ_MATTER:pop(sample)
    if channel_fired("slv_r", sample) then
        assert(READ_MATTER[sample.io.mst_r.bits.id].downstream_id[READ_MATTER[sample.io.mst_r.bits.id].downstream_id.first] == sample.io.slv_r.bits.id,"\n\n---ERROR---\n\nr channel sameID out-of-order\n\n-----------\n\n")
        if sample.io.slv_r.bits.last == 1 then
            dequeue(READ_MATTER[sample.io.mst_r.bits.id].downstream_id)
            dequeue(READ_MATTER[sample.io.mst_r.bits.id].upstream_id)
            dequeue(READ_MATTER[sample.io.mst_r.bits.id].addr)
            dequeue(READ_MATTER[sample.io.mst_r.bits.id].len)
            dequeue(READ_MATTER[sample.io.mst_r.bits.id].size)
            dequeue(READ_MATTER[sample.io.mst_r.bits.id].burst)
            dequeue(READ_MATTER[sample.io.mst_r.bits.id].lock)
            dequeue(READ_MATTER[sample.io.mst_r.bits.id].cache)
            dequeue(READ_MATTER[sample.io.mst_r.bits.id].prot)
            dequeue(READ_MATTER[sample.io.mst_r.bits.id].qos)
            dequeue(READ_MATTER[sample.io.mst_r.bits.id].region)
        end
    end
end

-- 写事务入队
function WRITE_MATTER:push(sample)
    if channel_fired("mst_aw", sample) then
        enqueue(WRITE_MATTER[sample.io.mst_aw.bits.id].upstream_id,     sample.io.mst_aw.bits.id)
        enqueue(WRITE_MATTER[sample.io.mst_aw.bits.id].addr,   sample.io.mst_aw.bits.addr)
        enqueue(WRITE_MATTER[sample.io.mst_aw.bits.id].len,    sample.io.mst_aw.bits.len)
        enqueue(WRITE_MATTER[sample.io.mst_aw.bits.id].size,   sample.io.mst_aw.bits.size)
        enqueue(WRITE_MATTER[sample.io.mst_aw.bits.id].burst,  sample.io.mst_aw.bits.burst)
        enqueue(WRITE_MATTER[sample.io.mst_aw.bits.id].lock,   sample.io.mst_aw.bits.lock)
        enqueue(WRITE_MATTER[sample.io.mst_aw.bits.id].cache,  sample.io.mst_aw.bits.cache)
        enqueue(WRITE_MATTER[sample.io.mst_aw.bits.id].prot,   sample.io.mst_aw.bits.prot)
        enqueue(WRITE_MATTER[sample.io.mst_aw.bits.id].qos,    sample.io.mst_aw.bits.qos)
        enqueue(WRITE_MATTER[sample.io.mst_aw.bits.id].region, sample.io.mst_aw.bits.region)
    end
    if channel_fired("slv_aw", sample) then
        local j = 0
        for i = 0, #WRITE_MATTER do
            j = 0  -- 用于判断是否找到了对应写事务
            if  WRITE_MATTER[i].addr[WRITE_MATTER[i].addr.first] == sample.io.slv_aw.bits.addr and
                WRITE_MATTER[i].len[WRITE_MATTER[i].len.first] == sample.io.slv_aw.bits.len and
                WRITE_MATTER[i].size[WRITE_MATTER[i].size.first] == sample.io.slv_aw.bits.size and
                WRITE_MATTER[i].burst[WRITE_MATTER[i].burst.first] == sample.io.slv_aw.bits.burst and
                WRITE_MATTER[i].lock[WRITE_MATTER[i].lock.first] == sample.io.slv_aw.bits.lock and
                WRITE_MATTER[i].cache[WRITE_MATTER[i].cache.first] == sample.io.slv_aw.bits.cache and
                WRITE_MATTER[i].prot[WRITE_MATTER[i].prot.first] == sample.io.slv_aw.bits.prot and
                WRITE_MATTER[i].qos[WRITE_MATTER[i].qos.first] == sample.io.slv_aw.bits.qos and
                WRITE_MATTER[i].region[WRITE_MATTER[i].region.first] == sample.io.slv_aw.bits.region then
                    
                    enqueue(WRITE_MATTER[i].downstream_id, sample.io.slv_aw.bits.id)
                    j = 1
                    break
            end
        end
        assert(j == 1, "\n\n---ERROR--\n\naw channnel sameID out-of-order\n\n--------\n\n")
    end
end

-- 写事务出队
function WRITE_MATTER:pop(sample)
    if channel_fired("slv_b", sample) then
        assert(WRITE_MATTER[sample.io.mst_b.bits.id].downstream_id[WRITE_MATTER[sample.io.mst_b.bits.id].downstream_id.first] == sample.io.slv_b.bits.id,"\n\n---ERROR---\n\nr channel sameID out-of-order\n\n-----------\n\n")
        if WRITE_MATTER[sample.io.mst_b.bits.id].downstream_id[WRITE_MATTER[sample.io.mst_b.bits.id].downstream_id.first] == sample.io.slv_b.bits.id then
            dequeue(WRITE_MATTER[sample.io.mst_b.bits.id].downstream_id)
            dequeue(WRITE_MATTER[sample.io.mst_b.bits.id].upstream_id)
            dequeue(WRITE_MATTER[sample.io.mst_b.bits.id].addr)
            dequeue(WRITE_MATTER[sample.io.mst_b.bits.id].len)
            dequeue(WRITE_MATTER[sample.io.mst_b.bits.id].size)
            dequeue(WRITE_MATTER[sample.io.mst_b.bits.id].burst)
            dequeue(WRITE_MATTER[sample.io.mst_b.bits.id].lock)
            dequeue(WRITE_MATTER[sample.io.mst_b.bits.id].cache)
            dequeue(WRITE_MATTER[sample.io.mst_b.bits.id].prot)
            dequeue(WRITE_MATTER[sample.io.mst_b.bits.id].qos)
            dequeue(WRITE_MATTER[sample.io.mst_b.bits.id].region)
        end
    end
end

local reset_sample_count = 0

function M.observe(sample)
    -- 每拍收到 monitor 的端口采样
    if sample == nil then
        return
    end

    if sample.reset == 1 then
        reset_sample_count = reset_sample_count + 1

        -- 清空已记录的期望事务
        CHANNELS_EXPECT_TABLE = create_channels_expect_table()
        CHANNELS_EXPECT_QUEUE = create_channels_expect_queue()
        -- 清空读/写事务表
        for i = 0, IDcount do
            READ_MATTER[i] = creat_read_matter_quene()
            WRITE_MATTER[i] = creat_write_matter_quene()
        end

        -- 首个 reset 样本可能尚未经历有效复位沿，跳过状态断言。
        if reset_sample_count > 1 then
            reset_auto_check(sample)
        end
        return
    end

    -- 释放reset计数器
    reset_sample_count = 0

    channel_fired_transaction_queue("mst_aw","aw",sample)
    channel_fired_transaction_queue("mst_w","w",sample)
    channel_fired_transaction(
        "mst_ar",
        "ar",
        { "addr", "len", "size", "burst", "lock", "cache", "prot", "qos", "region" },
        sample
    )
    channel_fired_transaction(
        "slv_r", "r",
        { "data", "resp", "last" },
        sample
    )
    channel_fired_transaction(
        "slv_b", "b",
        { "resp" },
        sample
    )
    channel_fired_check_queue("slv_aw", "aw", sample, { "addr", "len", "size", "burst", "lock", "cache", "prot", "qos", "region" })
    channel_fired_check_queue("slv_w", "w", sample, { "data", "strb", "last"})
    channel_fired_check(
        "slv_ar",
        "ar",
        { "addr", "len", "size", "burst", "lock", "cache", "prot", "qos", "region" },
        sample
    )
    channel_fired_check(
        "mst_r",
        "r",
        { "data", "resp", "last" },
        sample
    )
    channel_fired_check(
        "mst_b",
        "b",
        { "resp" },
        sample
    )
    WRITE_MATTER:push(sample)
    READ_MATTER:push(sample)
    WRITE_MATTER:pop(sample)
    READ_MATTER:pop(sample)

end

-- 两个通用检查函数
local function assert_table_empty(name, channel)
    for field, values in pairs(channel) do
        assert(
            #values == 0,
            string.format("%s still has %d pending %s entries",
                name, #values, field)
        )
    end
end

local function assert_queue_empty(name, channel)
    for field, queue in pairs(channel) do
        local count = queue.last - queue.first + 1
        assert(
            count <= 0,
            string.format("%s still has %d pending %s entries",
                name, count, field)
        )
    end
end

function M.finish_auto_check()
    -- testcase 结束时检查是否还有未匹配事务
    assert_queue_empty("AW", CHANNELS_EXPECT_QUEUE.aw)
    assert_queue_empty("W", CHANNELS_EXPECT_QUEUE.w)

    assert_table_empty("AR", CHANNELS_EXPECT_TABLE.ar)
    assert_table_empty("R", CHANNELS_EXPECT_TABLE.r)
    assert_table_empty("B", CHANNELS_EXPECT_TABLE.b)

    for id = 0, IDcount do
        local read_queue = READ_MATTER[id].upstream_id
        assert(read_queue.first > read_queue.last,
            string.format("read transaction for upstream id %d did not finish", id))

        local write_queue = WRITE_MATTER[id].upstream_id
        assert(write_queue.first > write_queue.last,
            string.format("write transaction for upstream id %d did not finish", id))
    end
 
end

-- 必须在 M.observe 定义完成后注册
monitor.subscribe(M.observe)

return M
