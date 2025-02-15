return function(state)
    love.graphics.print(string.format("FRAME: %d", state.frame), 10, 10)
    love.graphics.print(string.format("PLAYER: %d, %d", state.player_state.x, state.player_state.y), 10, 30)
end