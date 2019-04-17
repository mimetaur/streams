-- Streams
-- Granular Sine Streams

engine.name = "SimpleSineGrainCloud"

-- dependencies
local StreamPool = include("lib/stream_pool")
local sp = {}

local Arcify = include("arcify/lib/arcify")
local arcify = Arcify.new()

-- script vars
local clock = {}
local spawn_clock = {}

local function update()
    sp:update()
    redraw()
end

local function spawn()
    local d = math.random(10, 100)
    sp:spawn_only_dur(d)
end

function init()
    sp = StreamPool.new()

    clock = metro.init(update, 1 / 25, -1)
    clock:start()

    spawn_clock = metro.init(spawn, 1, -1)
    spawn_clock:start()

    -- arcify:register("release_mult", 1.0)
    -- arcify:register("max_dist", 1.0)
    -- arcify:register("num_walkers", 0.1)
    -- arcify:register("speed", 1.0)
    -- arcify:add_params()

    -- params:default()
end

function redraw()
    screen.clear()

    sp:draw()

    screen.update()
end
