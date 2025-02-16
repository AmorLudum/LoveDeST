lume = require "lib.lume"
ENGINE = require"engine"

local game
local game_canvas = nil
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

local function _step_game()
    if game then
        game:process({})
    end
end

local function _process_command(cmd)
    if game then
        game:process(cmd)
    end
end

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest", 1)
    game = dofile("game.lua")
    local gw, gh = game.config_data.game_width, game.config_data.game_height
    game_canvas = love.graphics.newCanvas(gw, gh)
    ENGINE.assets.setup(game.assets_data)
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
        preferences = _table_deepcopy(saved_settings.preferences)
    })
    local rng = love.math.newRandomGenerator(os.time())
    _process_command({
        type = "set_rng_state",
        rng_state = rng:getState()
    })
end

function love.update(dt)
    _step_game()
end

function love.draw()
    local current_font = love.graphics.getFont()
    love.graphics.setCanvas(game_canvas)
    game:draw()
    love.graphics.setCanvas()
    local seX, seY, seW, seH = love.window.getSafeArea()
    love.graphics.push()
    love.graphics.scale(seW / game.config_data.game_width, seH / game.config_data.game_height)
    love.graphics.draw(game_canvas, 0, 0)
    love.graphics.pop()
    love.graphics.setFont(current_font)
end
function love.keypressed(k)
    _process_command({
        type = "keypressed",
        key = k
    })
end

function love.keyreleased(k)
    _process_command({
        type = "keyreleased",
        key = k
    })
end