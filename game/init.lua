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

function game.step(state)
    if state.d then
        state.x = state.x + 1
        state.y = state.y + 1
    end
end
function game.draw(state)
    love.graphics.setFont(ENGINE.assets.get("normal_font"))
    love.graphics.print(lume.serialize(state), 10, 10)
    love.graphics.print("Hi, I'm Mark Brown, and this is Game Maker's Toolkit", 10, 30)
    love.graphics.setFont(ENGINE.assets.get("big_font"))
    love.graphics.print(lume.serialize(state), 10, 100)
    love.graphics.print("Hi, I'm Mark Brown, and this is Game Maker's Toolkit", 10, 150)
    love.graphics.draw(ENGINE.assets.get("my_icon"), state.x, state.y)
end

function game.command(state, cmd)
    print(lume.serialize(cmd))
    if cmd.type == "keypressed" then
        if cmd.key == "d" then
            state.d = true
        end
    elseif cmd.type == "keyreleased" then
        if cmd.key == "d" then
            state.d = false
        end
    end
end

return game