local game = {}

game.asset_data = {
    static_group = {
        normal_font = {"m6x11plus.ttf", 20},
        big_font = {"m6x11plus.ttf", 40},
        my_icon = "icon.png",
    },
    dynamic_groups = {

    }
}

game.state = {
    x = 10,
    y = 10,
    d = false
}

function game:draw()
    love.graphics.clear(0.2, 0.2, 0.4, 1.0)
    love.graphics.setFont(ENGINE.assets.get("normal_font"))
    love.graphics.print(lume.serialize(self.state), 10, 10)
    love.graphics.print("Hi, I'm Mark Brown, and this is Game Maker's Toolkit", 10, 30)
    love.graphics.setFont(ENGINE.assets.get("big_font"))
    love.graphics.print(lume.serialize(self.state), 10, 100)
    love.graphics.print("Hi, I'm Mark Brown, and this is Game Maker's Toolkit...", 10, 150)
    love.graphics.draw(ENGINE.assets.get("my_icon"), self.state.x, self.state.y)
end

function game:command(cmd, events)
    if not cmd.type then
        if self.state.d then
            self.state.x = self.state.x + 1
            self.state.y = self.state.y + 1
        end
    elseif cmd.type == "keypressed" then
        if cmd.key == "d" then
            self.state.d = true
        end
    elseif cmd.type == "keyreleased" then
        if cmd.key == "d" then
            self.state.d = false
        end
    end
end

return game