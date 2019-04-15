--- StreamPool class.

local StreamPool = {}
StreamPool.__index = StreamPool

local Stream = include("lib/stream")

local MAX_STREAMS = 4

function StreamPool.new(num_streams)
    local sp = {}
    sp.streams_ = {}
    sp.free_ = {}

    local num = num_streams or MAX_STREAMS

    for i = 1, num do
        local s = Stream.new(sp)
        table.insert(sp.free_, s)
    end

    setmetatable(sp, StreamPool)
    return sp
end

function StreamPool:spawn(x, y, w, h, density, smoothness, duration)
    math.randomseed(os.time())
    local s = table.remove(self.free_)
    if not s then
        print("at max streams. wait for one to die")
    else
        s:reset(x, y, w, h, density, smoothness, duration)
        table.insert(self.streams_, s)
    end
end

function StreamPool:spawn_only_dur(duration)
    math.randomseed(os.time())
    local s = table.remove(self.free_)
    local d = util.linlin(0, 100, 0, 1, duration)
    if not s then
        print("at max streams. wait for one to die")
    else
        s:reset()
        s:set_duration(d)
        table.insert(self.streams_, s)
    end
end

function StreamPool:update()
    local dead_idxs = {}
    for i, s in ipairs(self.streams_) do
        s:apply_force(-0.05, 0)
        s:update()
        if s:is_dead() then
            table.insert(self.free_, s)
            table.insert(dead_idxs, i)
        end
    end
    for _, idx in ipairs(dead_idxs) do
        table.remove(self.streams_, idx)
    end
end

function StreamPool:draw()
    for _, s in ipairs(self.streams_) do
        s:draw()
    end
end

function StreamPool:num()
    return #self.streams_, #self.free_
end

return StreamPool
