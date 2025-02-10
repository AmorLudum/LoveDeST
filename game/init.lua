local game = {}

game.state = {
    x = 10,
    y = 10
}

function game.step()
end
function game.draw(state)
    love.graphics.setFont(RES.the_font)
    love.graphics.print(lume.serialize(state), 10, 10)
    love.graphics.print("Hi, I'm Mark Brown, and this is Game Maker's Toolkit", 10, 30)
end

function game.command(cmd)
    print(lume.serialize(cmd))
end

return game