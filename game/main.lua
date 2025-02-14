local main = {}

function main.default_state()
    return {
        x = 10,
        y = 10,
        d = false
    }
end

function main.process(cmd, state, data, events)
    if not cmd.type then
        if state.d then
            state.x = state.x + data.s
            state.y = state.y + data.s
        end
    elseif cmd.type == "keypressed" then
        if cmd.key == "d" then
            state.d = true
        end
    elseif cmd.type == "keyreleased" then
        if cmd.key == "d" then
            state.d = false
        end
    elseif cmd.type == "set_preferences" then
        state.preferences = cmd.preferences
    end
end

function main.draw(state, data)
    love.graphics.clear(0.2, 0.2, 0.4, 1.0)
    love.graphics.setFont(ENGINE.assets.get("normal_font"))
    love.graphics.print(lume.serialize(state), 10, 10)
    love.graphics.print("Hi, I'm Mark Brown, and this is Game Maker's Toolkit", 10, 30)
    love.graphics.setFont(ENGINE.assets.get("big_font"))
    love.graphics.print(lume.serialize(state), 10, 100)
    love.graphics.print("Hi, I'm Mark Brown, and this is Game Maker's Toolkit...", 10, 150)
    love.graphics.draw(ENGINE.assets.get("my_icon"), state.x, state.y)
end

return main