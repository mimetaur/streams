--- Stream class.

local Stream = {}
Stream.__index = Stream

local WIDTH_UNIT = 4
local HEIGHT_UNIT = 4
local DEFAULT_HEIGHT = 8
local DEFAULT_WIDTH = 16
local DEFAULT_DENSITY = 100
local DEFAULT_SMOOTHNESS = 0.1
local DEFAULT_DURATION = 5

local function emit(self)
    if self.is_dead_ then
        return
    end

    -- sound parameters
    local inv_y = 64 - self.y_
    local cf = util.linexp(0, 64, 120, 1400, inv_y)

    engine.grain_dur(self.smoothness_)
    engine.density(self.density_)

    local dur = util.linlin(WIDTH_UNIT, WIDTH_UNIT * 8, 1, 4, self.w_)
    local w = params:get("wind")
    local iw = 5 - w
    local mod = util.linlin(0, 5, 0.15, 1.3, iw)
    local d = dur * mod
    engine.dur(d)

    local inv_num = 1 / self:num_streams()
    local amp_val = inv_num * 0.8
    engine.amp(amp_val)

    local fr = util.linlin(HEIGHT_UNIT, HEIGHT_UNIT * 4, 5, 100, self.h_)
    engine.hz_range(fr)
    engine.hz(cf)

    -- gate on
    -- engine.note_on(self.idx_)
end

local function silence(self)
    -- engine.note_off(self.idx_)
end

function Stream.new(pool, idx)
    local s = {}
    s.x_ = 0
    s.y_ = 0
    s.h_ = DEFAULT_HEIGHT
    s.w_ = DEFAULT_WIDTH
    s.vel_x_ = 0
    s.vel_y_ = 0
    s.accel_x_ = 0
    s.accel_y_ = 0
    s.density_ = 0
    s.smoothness_ = 0
    s.duration_ = 0
    s.is_dead_ = false
    s.pool_ = pool
    s.idx_ = idx or 0

    -- local function emit_callback()
    --     emit(s)
    -- end
    -- s.on_emit_ = metro.init(emit_callback, 0.1, 1)

    setmetatable(s, Stream)
    return s
end

function Stream:apply_force(force_x, force_y)
    self.accel_x_ = self.accel_x_ + force_x
    self.accel_y_ = self.accel_y_ + force_y
end

function Stream:apply_diffusion(diffusion_amount)
    local density_diffusion = util.linlin(0, 1, 1, 25, diffusion_amount)
    local d = self.density_ - density_diffusion
    if d < 0 then
        self:die()
    else
        self.density_ = d
    end

    local size_diffusion = diffusion_amount * 0.05
    local h = util.round(self.h_ + (self.h_ * size_diffusion), 1.0)
    local w = util.round(self.w_ + (self.w_ * size_diffusion), 1.0)

    if h > 32 or w > 64 then
        self:die()
    else
        self.h_ = h
        self.w_ = w
    end
end

function Stream:update()
    if self.is_dead_ then
        return
    end

    self.vel_x_ = self.vel_x_ + self.accel_x_
    self.vel_y_ = self.vel_y_ + self.accel_y_
    self.accel_x_ = 0
    self.accel_y_ = 0
    self.x_ = self.x_ + self.vel_x_
    self.y_ = self.y_ + self.vel_y_

    if self.x_ < -10 or self.y_ > 70 or self.y_ < -10 then
        self:die()
    end
end

function Stream:reset(x, y, w, h, density, smoothness)
    self.x_ = x or 130
    self.y_ = y or util.round(math.random(8) * HEIGHT_UNIT, 1.0)
    self.h_ = h or util.round(math.random(4) * HEIGHT_UNIT, 1.0)
    self.vel_x_ = 0
    self.vel_y_ = 0
    self.accel_x_ = 0
    self.accel_y_ = 0

    local rdens = math.ceil(math.random(1000))
    self.density_ = density or rdens

    local rsmooth = util.linlin(0, 1, 0.001, 0.25, math.random())
    self.smoothness_ = smoothness or rsmooth

    -- same as set_duration function but without the 1 to 100 mapping
    -- TODO deduplicate
    self.w_ = w or math.ceil(math.random(8) * WIDTH_UNIT)
    self.duration_ = util.linlin(WIDTH_UNIT, WIDTH_UNIT * 8, 1, 4, self.w_)

    self.is_dead_ = false

    -- self.on_emit_:start(scaled)
end

function Stream:set_duration(dur)
    self.w_ = math.ceil((dur * 8) * WIDTH_UNIT)
    self.duration_ = util.linlin(WIDTH_UNIT, WIDTH_UNIT * 8, 1, 4, self.w_)
end

function Stream:draw()
    if self.is_dead_ then
        return
    end

    local x = math.ceil(self.x_)
    local y = math.ceil(self.y_)
    local w = math.ceil(self.w_)
    local h = math.ceil(self.h_)

    local ff = self:fill_factor()
    local b_map_ff = util.linlin(0.001, 12.5, 1, 15, ff)
    local b = math.ceil(b_map_ff)

    screen.level(b)
    screen.rect(x, y, w, h)
    screen.fill()
end

function Stream:die()
    emit(self)
    self.is_dead_ = true
    -- self.on_emit_:stop()
end

function Stream:is_dead()
    return self.is_dead_
end

function Stream:density()
    return self.density_
end

function Stream:smoothness()
    return self.smoothness_
end

function Stream:fill_factor()
    return self.density_ * self.smoothness_
end

function Stream:num_streams()
    local s, f = self.pool_:num()
    return s
end

return Stream
