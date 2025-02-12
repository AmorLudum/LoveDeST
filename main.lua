lume = require "lib.lume"
ENGINE = require"engine"

local lurker = require("test.lib.lurker")
local bins = {}

function love.load()
    bins = lurker.listdir("test/bin")
end

function love.update(dt)
    lurker.update()
    if GAME then
        GAME.step(GAME.state)
    end
end

function love.draw()
    if GAME then
        GAME.draw(GAME.state)
    else
        local y = 10
        love.graphics.print("No Game", 10, y)
        y = y + 20
        for i, v in ipairs(bins) do
            love.graphics.print(string.format("[%s] %s", i, v), 10, y)
            y = y + 20
        end
    end
end

function love.keypressed(k)
    if GAME then
        GAME.command(GAME.state, {
            type = "keypressed",
            key = k
        })
    else
        if k == "space" then
            GAME = require("game")
            ENGINE.assets.setup(GAME.asset_data)
        else
            local game_idx = tonumber(k)
            if game_idx then
                local game_path = bins[game_idx]
                local result, err = pcall(function()
                    GAME = require(game_path)
                end)
                if not result then
                    print(err)
                end
            end
        end
    end
end

function love.keyreleased(k)
    if GAME then
        GAME.command(GAME.state, {
            type = "keyreleased",
            key = k
        })
    end
end