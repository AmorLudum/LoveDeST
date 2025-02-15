lume = require "lib.lume"
ENGINE = require"engine"

local game
local lurker = require("test.lib.lurker")
local bins = {}
local state_slot_idx = 0
local bottom_toast_state = {
    content = nil,
    start_time = -1
}

local game_canvas = nil
local recording_replay = nil
local running_replay = nil

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
    bins = lurker.listdir("test/bin")
end

function love.update(dt)
    lurker.update()
    _step_game()
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
        love.graphics.circle("fill", 30, seH - 50, 15)
    end
    love.graphics.setColor(r, g, b, a)
end

local function _toast(str)
    bottom_toast_state.content = str
    bottom_toast_state.start_time = love.timer.getTime()
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
           if not recording_replay then
                recording_replay = {}
                if game then
                    recording_replay.state = lume.clone(game.state)
                end
                recording_replay.cmds = {}
           end
        elseif k == "f" then
            if recording_replay then
                love.filesystem.write(string.format("replay_%d.txt", state_slot_idx), lume.serialize(recording_replay))
                recording_replay = nil
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
                game.state = lume.deserialize(love.filesystem.read(_slot_file_name()))
                _toast(string.format("state loaded: #%d", state_slot_idx))
            elseif k == "s" then
                os.execute("start "..love.filesystem.getSaveDirectory())
            elseif k == "w" then
                local loaded_replay_str = love.filesystem.read(string.format("replay_%d.txt", state_slot_idx))
                if loaded_replay_str then
                    running_replay = lume.deserialize(loaded_replay_str)
                    if running_replay.state then
                        game.state = running_replay.state
                    else
                        local new_game = dofile("game.lua")
                        game.state = new_game.state
                    end
                    _toast(string.format("replay loaded: #%d", state_slot_idx))
                end
            elseif k == "x" then
                game = nil
                ENGINE.assets.clear()
                if game_canvas then
                    game_canvas:release()
                    game_canvas = nil
                end
            end
        else
            if not running_replay then
                _process_command({
                    type = "keypressed",
                    key = k
                })
            end
        end
    else
        if k == "space" then
            game = dofile("game.lua")
            if recording_replay then
                recording_replay.state = lume.clone(game.state)
            end
            local gw, gh = game.config_data.game_width, game.config_data.game_height
            game_canvas = love.graphics.newCanvas(gw, gh)
            ENGINE.assets.setup(game.asset_data)
            love.filesystem.setIdentity(game.config_data.identity)
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
                preferences = lume.clone(saved_settings.preferences)
            })
        else
            local game_idx = tonumber(k)
            if game_idx then
                local game_path = bins[game_idx]
                local result, err = pcall(function()
                    game = dofile(game_path)
                end)
                if not result then
                    print(err)
                end
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