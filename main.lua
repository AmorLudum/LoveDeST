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

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest", 1)
    bins = lurker.listdir("test/bin")
end

function love.update(dt)
    lurker.update()
    if game then
        game:process({})
    end
end

local function _print_bottom_toast()
    if bottom_toast_state.content then
        local advance_time = love.timer.getTime() - bottom_toast_state.start_time 
        if advance_time < 4 then
            local r, g, b, a = love.graphics.getColor()
            local seX, seY, seW, seH = love.window.getSafeArea()
            local current_alpha = lume.clamp((4 - advance_time) * 3, 0, 1)
            love.graphics.setColor(r * 0.1, g * 0.1, b * 0.1, current_alpha * 0.5)
            love.graphics.rectangle("fill", 0, seH - 32, 400, 20)
            love.graphics.setColor(r, g, b, current_alpha)
            love.graphics.print(bottom_toast_state.content, 10, seH - 30)
            love.graphics.setColor(r, g, b, a)
        end
    end
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
    _print_bottom_toast()
end

local function _slot_file_name()
    return string.format("state_slot_%d.txt", state_slot_idx)
end

function love.keypressed(k)
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
            elseif k == "x" then
                game = nil
                ENGINE.assets.clear()
                if game_canvas then
                    game_canvas:release()
                    game_canvas = nil
                end
            end
        else
            game:process({
                type = "keypressed",
                key = k
            })
        end
    else
        if k == "space" then
            game = dofile("game.lua")
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
            game:process({
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
    if game then
        game:process({
            type = "keyreleased",
            key = k
        })
    end
end