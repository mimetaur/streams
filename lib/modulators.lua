local modulators = {}
modulators.types = {"Sine", "Triangle", "Saw", "Square", "Noise", "Brownian", "Lorenz"}
modulators.polls = {}
modulators.values = {}
modulators.NUM_MODULATORS = 2

modulators.create_polls = function()
    for i = 1, modulators.NUM_MODULATORS do
        modulators.polls[i] = poll.set("mod_" .. i .. "_out")
        modulators.polls[i].callback = function(val)
            modulators.values[i] = val
        end
        modulators.polls[i].time = 0.25
        modulators.update_poll(i)
    end
end

modulators.get_poll = function(idx)
    return modulators.polls[idx]
end

modulators.start_poll = function(idx)
    modulators.polls[idx]:start()
end

modulators.stop_poll = function(idx)
    modulators.polls[idx]:stop()
end

modulators.set_callback = function(idx, new_callback)
    modulators.polls[idx].callback = new_callback
end

modulators.add_callback = function(idx, new_callback)
    local old_callback = modulators.polls[idx].callback
    modulators.polls[idx].callback = function(val)
        old_callback(val)
        new_callback(val)
    end
end

modulators.clear_callback = function(idx)
    modulators.polls[idx].callback = function(val)
        modulators.values[idx] = val
    end
end

modulators.set_time = function(idx, time)
    modulators.polls[idx].time = time
end

modulators.update_poll = function(idx)
    modulators.polls[idx]:update()
    return modulators.values[idx]
end

modulators.update_all = function()
    for _, poll in ipairs(modulators.polls) do
        poll:update()
    end
end

modulators.create_params = function(add_type, add_hz, add_amp, add_lag)
    params:add_separator()
    for i = 1, modulators.NUM_MODULATORS do
        if add_type then
            params:add {
                type = "option",
                id = "mod_" .. i .. "_type",
                name = "modulator " .. i .. " type",
                options = modulators.types,
                default = 1,
                action = function(value)
                    engine.mod_type(i, value)
                end
            }
        end
        if add_hz then
            params:add {
                type = "control",
                id = "mod_" .. i .. "_hz",
                name = "modulator " .. i .. " hz",
                controlspec = controlspec.new(0, 20, "lin", 0.01, 5, "hz"),
                action = function(value)
                    engine.mod_hz(i, value)
                end
            }
        end
        if add_amp then
            params:add {
                type = "control",
                id = "mod_" .. i .. "_amp",
                name = "modulator " .. i .. " amp",
                controlspec = controlspec.new(0, 1, "lin", 0.01, 1.0),
                action = function(value)
                    engine.mod_amp(i, value)
                end
            }
        end
        if add_lag then
            params:add {
                type = "control",
                id = "mod_" .. i .. "_lag",
                name = "modulator " .. i .. " lag",
                controlspec = controlspec.new(0, 1, "lin", 0.1, 0.01),
                action = function(value)
                    engine.mod_lag(i, value)
                end
            }
        end
    end
end

return modulators
