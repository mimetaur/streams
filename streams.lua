-- Streams
-- Granular Sine Streams

engine.name = "Streams"

-- dependencies
modulators = include("lib/modulators")

local StreamPool = include("lib/stream_pool")
local sp = {}

local Arcify = include("arcify/lib/arcify")
local my_arc = arc.connect()
local arcify = Arcify.new(my_arc, false)

local Billboard = include("billboard/lib/billboard")
billboard = Billboard.new()

-- script vars
local clock = {}
local spawn_clock = {}
local spawn_counter = 1
local spawn_rate = 10
local diffusion_rate = 0
local gravity = 0

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function update()
    local w = params:get("wind")
    sp:apply_force(-w, 0)

    sp:apply_force(0, gravity)

    sp:apply_diffusion(diffusion_rate)
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

    clock = metro.init(update, 1 / 20, -1)
    clock:start()

    spawn_clock = metro.init(spawn, 0.1, -1)
    spawn_clock:start()

    params:add {
        type = "control",
        id = "wind",
        name = "wind amount",
        controlspec = controlspec.new(0.05, 5, "lin", 0.01, 0.2),
        action = function(value)
            local iv = 5 - value
            local scaled = util.linlin(0, 5, 1, 15, iv)
            spawn_rate = scaled
            arcify:redraw()
            billboard:display_param("wind", -1 * value)
        end
    }
    params:add {
        type = "control",
        id = "diffusion",
        name = "diffusion rate",
        controlspec = controlspec.new(0, 1, "lin", 0.01, diffusion_rate),
        action = function(value)
            diffusion_rate = value
            billboard:display_param("diffusion rate", value)
        end
    }

    params:add {
        type = "control",
        id = "gravity",
        name = "gravity amount",
        controlspec = controlspec.new(-0.15, 0.15, "lin", 0.01, 0),
        action = function(value)
            gravity = value
            billboard:display_param("gravity", util.round(gravity, 0.01))
        end
    }

    modulators.init(3, {"wind", "gravity", "diffusion"}, true, true, true, false)

    arcify:register("wind", 0.05)
    arcify:register("diffusion", 0.01)
    arcify:register("gravity", 0.01)

    for i = 1, modulators.num do
        arcify:register("mod_" .. i .. "_hz", 0.1)
        arcify:register("mod_" .. i .. "_amount", 0.01)
    end

    arcify:add_params()

    params:default()

    local function mod_callback(val, i)
        local param_idx = params:get("mod_" .. i .. "_param")
        local current_modulator = modulators.params[param_idx]
        local mod_amount = params:get("mod_" .. i .. "_amount")

        if current_modulator == "gravity" then
            local old_gravity = params:get("gravity")
            local new_gravity = util.linlin(-1, 1, -0.15, 0.15, val)
            local l_gravity = lerp(old_gravity, new_gravity, mod_amount)

            params:set("gravity", l_gravity)
        end

        if current_modulator == "wind" then
            local old_wind = params:get("wind")
            local new_wind = util.linlin(-1, 1, 0.05, 5, val)
            local l_wind = lerp(old_wind, new_wind, mod_amount)

            params:set("wind", l_wind)
        end

        if current_modulator == "diffusion" then
            local old_diff = params:get("diffusion")
            local new_diff = util.linlin(-1, 1, 0, 1, val)
            local l_diff = lerp(old_diff, new_diff, mod_amount)

            params:set("diffusion", l_diff)
        end
    end

    local function mod_1_callback(val)
        mod_callback(val, 1)
    end
    modulators.set_callback(1, mod_1_callback)
    modulators.start_poll(1)

    local function mod_2_callback(val)
        mod_callback(val, 2)
    end
    modulators.set_callback(2, mod_2_callback)
    modulators.start_poll(2)

    local function mod_3_callback(val)
        mod_callback(val, 3)
    end
    modulators.set_callback(3, mod_3_callback)
    modulators.start_poll(3)
end

function key(n, z)
    if n == 2 and z == 1 then
        print(modulators.update_poll(1))
    end

    redraw()
end

function redraw()
    screen.clear()

    sp:draw()
    billboard:draw()

    screen.update()
end
