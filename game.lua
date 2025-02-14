local game = {}
local main = dofile("game/main.lua")

game.config_data = dofile("game/config_data.lua")
game.asset_data = dofile("game/assets_data.lua")
game.state = main.default_state()
game.data = dofile("game/game_data.lua")

function game:draw()
    main.draw(self.state, self.data)
end

function game:process(cmd, events)
    main.process(cmd, self.state, self.data, events)
end

return game