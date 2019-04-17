-- Streams
-- Granular Sine Streams

engine.name = "SimpleSineGrainCloud"

-- dependencies
local StreamPool = include("lib/stream_pool")
local sp = {}

local Arcify = include("arcify/lib/arcify")
local my_arc = arc.connect()
local arcify = Arcify.new(my_arc, false)

-- script vars
local clock = {}
local spawn_clock = {}

local function update()
    local w = params:get("wind")
    sp:apply_force(-w, 0)
    sp:update()
    redraw()
end

local function spawn()
    local d = math.random(10, 100)
    sp:spawn_only_dur(d)
end

function init()
    sp = StreamPool.new()

    clock = metro.init(update, 1 / 15, -1)
    clock:start()

    spawn_clock = metro.init(spawn, 1, -1)
    spawn_clock:start()

    params:add {
        type = "control",
        id = "wind",
        name = "wind amount",
        controlspec = controlspec.new(0, 5, "lin", 0.05, 0.05),
        action = function()
            arcify:redraw()
        end
    }

    arcify:register("wind", 0.01)
    arcify:add_params()

    -- TODO enable this one params are semi-stable
    -- params:default()
end

function redraw()
    screen.clear()

    sp:draw()

    screen.update()
end
