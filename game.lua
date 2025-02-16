local game = {}
local main = dofile("game/main.lua")

game.config_data = dofile("game/config_data.lua")
game.assets_data = dofile("game/assets_data.lua")
game.state = main.default_state()
game.state.frame = 0
game.data = dofile("game/game_data.lua")

function game:draw()
    main.draw(self.state, self.data, self.assets_data)
end

function game:process(cmd, events)
    main.process(cmd, self.state, self.data, self.assets_data, events)
    if not cmd.type then
        self.state.frame = self.state.frame + 1
    end
end

return game