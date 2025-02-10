lume = require "lib.lume"
RES = require"engine.res"

local lurker = require("test.lib.lurker")
local bins = {}

function love.load()
    bins = lurker.listdir("test/bin")
end

function love.update(dt)
    lurker.update()
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
        GAME.command({
            type = "keypressed",
            key = k
        })
    else
        if k == "space" then
            GAME = require("game")
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