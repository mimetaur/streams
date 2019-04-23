local modulators = {}
modulators.types = {"none", "sine", "noise", "brownian", "lorenz"}
modulators.types_rev = {none = 1, sine = 2, noise = 3, brownian = 4, lorenz = 5}
modulators.polls = {}
modulators.values = {}
modulators.params = {}
modulators.cached_params = {}
modulators.minval = -1
modulators.maxval = 1

modulators.num = 0

modulators.create_polls = function()
    for i = 1, modulators.num do
        modulators.polls[i] = poll.set("mod_" .. i .. "_out")
        modulators.polls[i].callback = function(val)
            modulators.values[i] = val
        end
        modulators.polls[i].time = 0.05
        modulators.update_poll(i)
    end
end

modulators.get_type = function(idx)
    local type_idx = params:get("mod_" .. idx .. "_type")
    return modulators.types[type_idx]
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

modulators.get_original = function(param_name)
    return modulators.stored_params[param_name]
end

modulators.cache_param = function(param_name, value)
    local cached_param = modulators.cached_params[param_name]
    if cached_param.ignore == true then
        cached_param.ignore = false
    else
        cached_param.value = value
    end
end

modulators.get_cached_value = function(param_name)
    return modulators.cached_params[param_name].value
end

modulators.ignore_param_change = function(param_name)
    modulators.cached_params[param_name].ignore = true
end

modulators.init = function(num_modulators, mod_params, add_params, add_type, add_speed, add_lag)
    modulators.num = num_modulators
    modulators.params = mod_params

    for _, param_name in ipairs(modulators.params) do
        modulators.cached_params[param_name] = {value = params:get(param_name), ignore = false}
    end

    modulators.create_params(add_params, add_type, add_speed, add_lag)
    modulators.create_polls()
end

modulators.create_params = function(add_params, add_type, add_speed, add_lag)
    for i = 1, modulators.num do
        params:add_separator()
        if add_type then
            params:add {
                type = "option",
                id = "mod_" .. i .. "_type",
                name = "mod " .. i .. " type",
                options = modulators.types,
                default = 1,
                action = function(value)
                    engine.mod_type(i, value)
                end
            }
        end
        if add_speed then
            params:add {
                type = "control",
                id = "mod_" .. i .. "_speed",
                name = "mod " .. i .. " speed",
                controlspec = controlspec.new(1, 100, "lin", 1, 50),
                action = function(value)
                    engine.mod_speed(i, value)
                end
            }
        end
        if add_lag then
            params:add {
                type = "control",
                id = "mod_" .. i .. "_lag",
                name = "mod " .. i .. " lag",
                controlspec = controlspec.new(0, 1, "lin", 0.1, 0.01),
                action = function(value)
                    engine.mod_lag(i, value)
                end
            }
        end
        if add_params then
            params:add {
                type = "option",
                id = "mod_" .. i .. "_param",
                name = "mod " .. i .. " param",
                options = modulators.params,
                default = i
            }
            params:add {
                type = "control",
                id = "mod_" .. i .. "_amount",
                name = "mod " .. i .. " Amount",
                controlspec = controlspec.new(0, 1, "lin", 0.01, 0),
                action = function(value)
                    local param_name = modulators.params[params:get("mod_" .. i .. "_param")]
                    billboard:display_param("mod " .. i .. " to " .. param_name, value)
                end
            }
        end
    end
end

return modulators
