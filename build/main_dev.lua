lume = require "lib.lume"
ENGINE = require"engine"

local game
local origin_game_state
local bins = {}
local state_slot_idx = 0
local bottom_toast_state = {
    content = nil,
    start_time = -1
}

local game_canvas = nil
local recording_replay = nil
local running_replay = nil
local running_replay_control = nil
local running_replay_speed_scales = {
    1, 2, 5, 10, 20, 50, 100, 500
}
local memorized_game_state_steps = 60

-- monitor
local monitor_draw_func = nil
local function _table_deepcopy(t)
    local r = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            r[k] = _table_deepcopy(v)
        else
            r[k] = v
        end
    end
    return r
end
local function _toast(str)
    bottom_toast_state.content = str
    bottom_toast_state.start_time = love.timer.getTime()
end
local function _try_switch_replay_speed_scale(v)
    if running_replay_control then
        running_replay_control.speed_idx = lume.clamp(running_replay_control.speed_idx + v, 1, #running_replay_speed_scales)
        _toast(string.format("switch replay speed scale: x%d", running_replay_speed_scales[running_replay_control.speed_idx]))
    end
end
local function _restore_game_state(new_state)
    if game then
        game.state = new_state
        ENGINE.assets.restore_dynamic_group_by_code(game.state.dac or 0)
    end
end

local function _step_game()
    if game then
        if running_replay then
            local cmd_list = running_replay.cmds[game.state.frame]
            if cmd_list then
                for i, v in ipairs(cmd_list) do
                    game:process(v)
                end
            end
        end
        game:process({})
    end
end
local function _ensure_memorized_state(num)
    if running_replay_control then
        if not running_replay_control.memorized_state then
            running_replay_control.memorized_state = {}
        end
        if not running_replay_control.memorized_state[num] then
            if num <= 0 then
                local s = running_replay.state
                if not s then
                    s = origin_game_state
                end
                running_replay_control.memorized_state[num] = _table_deepcopy(s)
            else
                _ensure_memorized_state(num - 1)
                _restore_game_state(_table_deepcopy(running_replay_control.memorized_state[num - 1]))
                for i = 1, memorized_game_state_steps do
                    _step_game()
                end
                running_replay_control.memorized_state[num] = _table_deepcopy(game.state)
            end
        end
    end
end

local function _try_navigate_to_arbitrary_frame(f)
    if running_replay_control then
        local start_frame = 0
        if running_replay.state then
            start_frame = running_replay.state.frame
        end
        f = math.max(f, start_frame)
        local memorized_num = math.floor((f - start_frame) / memorized_game_state_steps)
        local rest_step_count = f - start_frame - memorized_num * memorized_game_state_steps
        _ensure_memorized_state(memorized_num)
        _restore_game_state(_table_deepcopy(running_replay_control.memorized_state[memorized_num]))
        for i = 1, rest_step_count do
            _step_game()
        end
    end
end

local function _try_single_step(v)
    if running_replay_control then
        running_replay_control.method = 1
        if v >= 0 then
            for i = 1, running_replay_speed_scales[running_replay_control.speed_idx] * v do
                _step_game()
            end
        else
            _try_navigate_to_arbitrary_frame(game.state.frame + running_replay_speed_scales[running_replay_control.speed_idx] * v)
        end
    end
end

local function _process_command(cmd)
    if game then
        game:process(cmd)
        if recording_replay then
            local fm = game.state.frame
            if not recording_replay.cmds[fm] then
                recording_replay.cmds[fm] = {}
            end
            lume.push(recording_replay.cmds[fm], cmd)
        end
    end
end

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest", 1)
    game = dofile("game.lua")
    origin_game_state = _table_deepcopy(game.state)
    local gw, gh = game.config_data.game_width, game.config_data.game_height
    game_canvas = love.graphics.newCanvas(gw, gh)
    ENGINE.assets.setup(game.assets_data)
    love.filesystem.setIdentity(game.config_data.identity.."[DEV]")
    love.window.setTitle(game.config_data.identity)
    local saved_settings_str = love.filesystem.read("settings.txt")
    local saved_settings = nil
    if saved_settings_str then
        saved_settings = lume.deserialize(love.filesystem.read("settings.txt"))
    end
    if not saved_settings then
        saved_settings = game.config_data.default_settings
        love.filesystem.write("settings.txt", lume.serialize(saved_settings))
    end
    local ws = saved_settings.window_scale
    local ow, oh, of = love.window.getMode()
    of.fullscreen = saved_settings.fullscreen
    if saved_settings.fullscreen then
        love.window.setMode(0, 0, of)
    else
        love.window.setMode(gw * ws, gh * ws, of)
    end
    _process_command({
        type = "set_preferences",
        preferences = _table_deepcopy(saved_settings.preferences)
    })
    local rng = love.math.newRandomGenerator(os.time())
    _process_command({
        type = "set_rng_state",
        rng_state = rng:getState()
    })
end

function love.update(dt)
    local step_count = 0
    if not running_replay_control then
        step_count = 1
    else
        if running_replay_control.method == 0 then
            step_count = running_replay_speed_scales[running_replay_control.speed_idx]
        elseif running_replay_control.method == 1 then
            step_count = 0
        end
    end
    for i = 1, step_count do
        _step_game()
    end
end

local function _print_bottom_contents()
    local seX, seY, seW, seH = love.window.getSafeArea()
    local r, g, b, a = love.graphics.getColor()
    if bottom_toast_state.content then
        local advance_time = love.timer.getTime() - bottom_toast_state.start_time 
        if advance_time < 4 then
            local current_alpha = lume.clamp((4 - advance_time) * 3, 0, 1)
            love.graphics.setColor(r * 0.1, g * 0.1, b * 0.1, current_alpha * 0.5)
            love.graphics.rectangle("fill", 0, seH - 32, 400, 20)
            love.graphics.setColor(r, g, b, current_alpha)
            love.graphics.print(bottom_toast_state.content, 10, seH - 30)
        end
    end
    if recording_replay then
        love.graphics.setColor(0.8, 0.1, 0.1, 1.0)
        if math.floor(love.timer.getTime()) % 2 == 0 then
            love.graphics.circle("fill", 30, seH - 50, 15)
        end
    end
    if running_replay and running_replay_control then
        love.graphics.setColor(r * 0.1, g * 0.1, b * 0.1, 0.5)
        love.graphics.rectangle("fill", 0, seH - 18, seW, 18)
        love.graphics.setColor(r, g, b, 1)
        love.graphics.print(string.format("start_frame: %d, method: %s, current_frame: %d, time_scale: x%d",
            running_replay.state and running_replay.state.frame or 0,
            running_replay_control.method,
            game.state.frame,
            running_replay_speed_scales[running_replay_control.speed_idx]),
            10, seH - 16)
    end
    if game and monitor_draw_func then
        love.graphics.push()
        love.graphics.translate(seW - 300, 0)
        love.graphics.setColor(r * 0.1, g * 0.1, b * 0.1, 0.5)
        love.graphics.rectangle("fill", 0, 0, 300, seH)
        love.graphics.setColor(r, g, b, 1)
        monitor_draw_func(game.state)
        love.graphics.pop()
    end
    love.graphics.setColor(r, g, b, a)
end

function love.draw()
    local current_font = love.graphics.getFont()
    if game then
        love.graphics.setCanvas(game_canvas)
        game:draw()
        love.graphics.setCanvas()
        local seX, seY, seW, seH = love.window.getSafeArea()
        love.graphics.push()
        love.graphics.scale(seW / game.config_data.game_width, seH / game.config_data.game_height)
        love.graphics.draw(game_canvas, 0, 0)
        love.graphics.pop()
    else
        local y = 10
        love.graphics.print("No Game", 10, y)
        y = y + 20
        for i, v in ipairs(bins) do
            love.graphics.print(string.format("[%s] %s", i, v), 10, y)
            y = y + 20
        end
    end
    love.graphics.setFont(current_font)
    _print_bottom_contents()
end

local function _slot_file_name()
    return string.format("state_slot_%d.txt", state_slot_idx)
end

function love.keypressed(k)
    if love.keyboard.isDown("lctrl") then
        if k == "r" then
           if not running_replay and not recording_replay then
                recording_replay = {}
                if game then
                    recording_replay.state = _table_deepcopy(game.state)
                end
                recording_replay.cmds = {}
                recording_replay.commit = require("version")
           end
        elseif k == "f" then
            if recording_replay then
                local file_name = string.format("replay_%d.txt", state_slot_idx)
                love.filesystem.write(file_name, lume.serialize(recording_replay))
                recording_replay = nil
                _toast(string.format("replay saved: #%d", state_slot_idx))
            end
        end
    end
    if game then
        if love.keyboard.isDown("lctrl") then
            local num = tonumber(k)
            if num then
                state_slot_idx = num
                _toast(string.format("switch to slot: #%s", k))
            elseif k == "q" then
                love.filesystem.write(_slot_file_name(), lume.serialize(game.state))
                _toast(string.format("state saved: #%d", state_slot_idx))
            elseif k == "e" then
                _restore_game_state(lume.deserialize(love.filesystem.read(_slot_file_name())))
                _toast(string.format("state loaded: #%d", state_slot_idx))
            elseif k == "d" then
                os.execute("start "..love.filesystem.getSaveDirectory())
            elseif k == "w" then
                if not recording_replay then
                    if not running_replay then
                        local loaded_replay_str = love.filesystem.read(string.format("replay_%d.txt", state_slot_idx))
                        if loaded_replay_str then
                            running_replay = lume.deserialize(loaded_replay_str)
                            _toast(string.format("replay loaded: #%d", state_slot_idx))
                        end
                    end
                    if running_replay then
                        if running_replay.state then
                            _restore_game_state(_table_deepcopy(running_replay.state))
                        else
                            _restore_game_state(_table_deepcopy(origin_game_state))
                        end
                        if not running_replay_control then
                            running_replay_control = {
                                method = 0,
                                speed_idx = 1
                            }
                        end
                    end
                else
                    _toast("!! recording")
                end
            elseif k == "s" then
                running_replay = nil
                running_replay_control = nil
                _toast("replay finished")
            elseif k == "up" then
                _try_switch_replay_speed_scale(1)
            elseif k == "down" then
                _try_switch_replay_speed_scale(-1)
            elseif k == "left" then
                _try_single_step(-1)
            elseif k == "right" then
                _try_single_step(1)
            end
        else
            if not running_replay then
                _process_command({
                    type = "keypressed",
                    key = k
                })
            end
        end
    end
end

function love.keyreleased(k)
    if game and not running_replay then
        _process_command({
            type = "keyreleased",
            key = k
        })
    end
end