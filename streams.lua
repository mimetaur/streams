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
local spawn_counter = 1
local spawn_rate = 10

local function update()
    local w = params:get("wind")
    sp:apply_force(-w, 0)
    sp:update()
    redraw()
end

local function spawn()
    spawn_counter = spawn_counter + 1
    if spawn_counter > spawn_rate then
        local d = math.random(10, 100)
        sp:spawn_only_dur(d)
        spawn_counter = 0
    end
end

function init()
    sp = StreamPool.new()

    clock = metro.init(update, 1 / 15, -1)
    clock:start()

    spawn_clock = metro.init(spawn, 0.1, -1)
    spawn_clock:start()

    params:add {
        type = "control",
        id = "wind",
        name = "wind amount",
        controlspec = controlspec.new(0, 5, "lin", 0.05, 0.05),
        action = function(value)
            local iv = 5 - value
            local scaled = util.linlin(0, 5, 1, 15, iv)
            spawn_rate = scaled
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
