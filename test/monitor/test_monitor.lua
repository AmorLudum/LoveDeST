return function(state)
    local y = 10
    local p = function(str, ...)
        love.graphics.print(string.format(str, ...), 10, y)
        y = y + 20
    end
    p("FRAME: %d", state.frame)
    p("PLAYER: %d, %d", state.player_state.x, state.player_state.y)
    p("ASSETS: %d", ENGINE.assets.get_dynamic_group_code())
    p(" - GROUP:")
    for k, v in pairs(ENGINE.assets.group) do
        p("    - %s: %s", k, v)
    end
    p(" - MAP:")
    for k, v in pairs(ENGINE.assets.map) do
        p("    - %s: %s", k, v)
    end
end