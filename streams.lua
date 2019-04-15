-- Streams
-- Granular Sine Streams

engine.name = "SimpleSineGrainCloud"

-- dependencies
local StreamPool = include("lib/stream_pool")

-- script vars
local sp = {}
local clock = {}

local hold_clock = {}
local time_held = 0
local spawn_clock = {}

local function update()
    sp:update()
    redraw()
end

local function holding()
    if time_held < 100 then
        time_held = time_held + 1
    end
end

local function spawn()
    local d = math.random(10, 100)
    sp:spawn_only_dur(d)
end

function init()
    sp = StreamPool.new()

    clock = metro.init(update, 1 / 25, -1)
    clock:start()

    hold_clock = metro.init(holding, 1 / 20, -1)

    spawn_clock = metro.init(spawn, 1, -1)
    spawn_clock:start()
end

function redraw()
    screen.clear()

    sp:draw()

    screen.update()
end

function key(n, z)
    if n == 2 then
        if z == 1 then
            print("starting holding")
            hold_clock:start()
        else
            print("finishing holding: " .. time_held)
            hold_clock:stop()
            sp:spawn_only_dur(time_held)
            time_held = 0
        end
    end

    redraw()
end
