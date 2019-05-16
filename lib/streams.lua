engine.name = AUDIO_ENGINE or "Streams"

-- dependencies

local StreamPool = include("lib/stream_pool")
local sp = {}

local modulators = include("lib/modulators")

local Arcify = include("arcify/lib/arcify")
local my_arc = arc.connect()
local arcify = Arcify.new(my_arc, false)

local Billboard = include("billboard/lib/billboard")
billboard = Billboard.new({mode = "banner"})

-- script vars
local clock = {}
local spawn_clock = {}
local spawn_counter = 1
local spawn_rate = 10
local diffusion_rate = 0
local gravity = 0
local primary_params = {}

local options = {}
options.max_grains = {64, 128, 256, 512, 1024}

local controlspecs = {}

local audio_state = 1 -- 1 == normal, 2 == ducked, 3 == muted

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

    clock = metro.init(update, 1 / 15, -1)
    clock:start()

    spawn_clock = metro.init(spawn, 0.1, -1)
    spawn_clock:start()

    if engine.name == "StreamsBuffer" then
        params:add_file("file", "file")
        params:set_action(
            "file",
            function(filename)
                if value ~= "-" then
                    engine.read(filename)
                end
            end
        )

        params:add {
            type = "control",
            id = "min_pos",
            name = "buffer min position",
            controlspec = controlspec.new(0, 1.0, "lin", 0.01, 0),
            action = function(value)
                engine.min_pos(value)
            end
        }
        params:add {
            type = "control",
            id = "max_pos",
            name = "buffer max position",
            controlspec = controlspec.new(0, 1.0, "lin", 0.01, 1),
            action = function(value)
                engine.max_pos(value)
            end
        }
        params:add_separator()
    end

    params:add {
        type = "option",
        id = "max_grains",
        name = "max num grains",
        options = options.max_grains,
        default = 3, -- 256 grains
        action = function(value)
            local num = options.max_grains[value]
            engine.max_grains(num)
        end
    }
    params:add_separator()

    controlspecs.wind = controlspec.new(0.05, 5, "lin", 0.01, 0.2)
    params:add {
        type = "control",
        id = "wind",
        name = "wind amount",
        controlspec = controlspecs.wind,
        action = function(value)
            modulators.cache_param("wind", value)
            local iv = 5 - value
            local scaled = util.linlin(0, 5, 1, 15, iv)
            spawn_rate = scaled
            arcify:redraw()
            billboard:display_param("wind", -1 * value)
        end
    }
    table.insert(primary_params, "wind")

    controlspecs.gravity = controlspec.new(-0.15, 0.15, "lin", 0.01, 0)
    params:add {
        type = "control",
        id = "gravity",
        name = "gravity amount",
        controlspec = controlspecs.gravity,
        action = function(value)
            modulators.cache_param("gravity", value)
            gravity = value
            billboard:display_param("gravity", util.round(gravity, 0.01))
        end
    }
    table.insert(primary_params, "gravity")

    controlspecs.diffusion = controlspec.new(0, 1, "lin", 0.01, diffusion_rate)
    params:add {
        type = "control",
        id = "diffusion",
        name = "diffusion rate",
        controlspec = controlspecs.diffusion,
        action = function(value)
            modulators.cache_param("diffusion", value)
            diffusion_rate = value
            billboard:display_param("diffusion rate", value)
        end
    }
    table.insert(primary_params, "diffusion")

    modulators.init(3, primary_params, true, true, true, false)

    arcify:register("wind", 0.05)
    arcify:register("diffusion", 0.01)
    arcify:register("gravity", 0.01)

    for i = 1, modulators.num do
        arcify:register("mod_" .. i .. "_speed", 0.1)
        arcify:register("mod_" .. i .. "_amount", 0.01)
    end

    arcify:add_params()

    params:default()

    local function mod_set_param(param_name, value, mod_amt)
        local mmin = modulators.minval
        local mmax = modulators.maxval
        local pmin = controlspecs[param_name].minval
        local pmax = controlspecs[param_name].maxval
        local mod = util.linlin(mmin, mmax, pmin, pmax, value)
        local cached = modulators.get_cached_value(param_name)

        local interpolated = lerp(cached, mod, mod_amt)
        modulators.ignore_param_change(param_name)
        params:set(param_name, interpolated)
    end

    local function mod_callback(val, i)
        local param_idx = params:get("mod_" .. i .. "_param")
        local current_modulator = modulators.params[param_idx]
        local mod_amount = params:get("mod_" .. i .. "_amount")

        if modulators.get_type(i) == "none" or mod_amount == 0 then
            return
        end

        if current_modulator == "gravity" then
            mod_set_param("gravity", val, mod_amount)
        end

        if current_modulator == "wind" then
            mod_set_param("wind", val, mod_amount)
        end

        if current_modulator == "diffusion" then
            mod_set_param("diffusion", val, mod_amount)
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
    arcify:handle_shift(n, z)
    if (n == 3 and z == 1) then
        if audio_state == 1 then
            audio_state = 2
        elseif audio_state == 2 then
            audio_state = 3
        else
            audio_state = 1
        end
    end

    if (audio_state == 3) then
        audio.level_dac(0)
    elseif (audio_state == 2) then
        audio.level_dac(0.1)
    else
        audio.level_dac(0.8)
    end
    redraw()
end

function redraw()
    screen.clear()

    sp:draw()
    billboard:draw()

    screen.update()
end
