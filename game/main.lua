local main = {}

function main.default_state()
    return {
        player_state = {
            x = 10,
            y = 10
        },
        score = 0,
        input = {}
    }
end

local function _handle_input(key, pressed, state)
    if not state.input[key] then
        state.input[key] = { pressed, pressed and true or false }
    else
        local just = state.input[key][1] ~= pressed
        state.input[key][1] = pressed
        state.input[key][2] = just
    end
end

local function _clear_input_just(state)
    for k, v in pairs(state.input) do
        v[2] = false
    end
end

local function _is_key_down(state, k)
    return state.input[k] and state.input[k][1]
end
local function _is_key_just_down(state, k)
    return state.input[k] and state.input[k][1] and state.input[k][2]
end
local function _is_key_just_up(state, k)
    return state.input[k] and not state.input[k][1] and state.input[k][2]
end

local function _process_get_coin(state, data)
    if state.coin then
        local bx, by = false, false
        bx = state.coin.x > state.player_state.x and state.coin.x < state.player_state.x + data.player_data.size
        by = state.coin.y > state.player_state.y and state.coin.y < state.player_state.y + data.player_data.size
        if bx and by then
            state.coin = nil
            state.score = state.score + 1
        end
    end
end
local function _try_generate_coin(state)
    if not state.coin then
        local x, y
        state.rng_state, x = ENGINE.rng.next(state.rng_state)
        state.rng_state, y = ENGINE.rng.next(state.rng_state)
        x = x / 100 * 480
        y = y / 100 * 270
        state.coin = {
            x = x,
            y = y
        }
    end
end
local function _step(state, data)
    local dx, dy = 0, 0
    if _is_key_down(state, "d") then
        dx = dx + 1
    end
    if _is_key_down(state, "a") then
        dx = dx - 1
    end
    if _is_key_down(state, "w") then
        dy = dy - 1
    end
    if _is_key_down(state, "s") then
        dy = dy + 1
    end
    local l = math.sqrt(dx * dx + dy * dy)
    if l > 0 then
        dx, dy = dx / l * data.player_data.speed, dy / l * data.player_data.speed
        state.player_state.x = state.player_state.x + dx
        state.player_state.y = state.player_state.y + dy
    end
    _process_get_coin(state, data)
    _try_generate_coin(state)
end

function main.process(cmd, state, data, events)
    if not cmd.type then
        _step(state, data)
        _clear_input_just(state)
    elseif cmd.type == "keypressed" then
        _handle_input(cmd.key, true, state)
    elseif cmd.type == "keyreleased" then
        _handle_input(cmd.key, false, state)
    elseif cmd.type == "set_preferences" then
        state.preferences = cmd.preferences
    elseif cmd.type == "set_rng_state" then
        state.rng_state = cmd.rng_state
    end
end

function main.draw(state, data)
    love.graphics.clear(0.2, 0.2, 0.4, 1.0)
    love.graphics.setFont(ENGINE.assets.get("normal_font"))
    local py = 10
    local p = function(str)
        p = love.graphics.print(str, 10, py)
        py = py + 12
    end
    p(string.format("SCORE: %d", state.score))
    p(string.format("FRAME: %d", state.frame))
    p(string.format("INPUT:", state.frame))
    p(string.format("PLAYER: %s, %s", state.player_state.x, state.player_state.y))
    p(string.format("COIN: %s, %s", state.coin.x, state.coin.y))
    local my_icon = ENGINE.assets.get("my_icon")
    local sx, sy = data.player_data.size / my_icon:getWidth(), data.player_data.size / my_icon:getHeight()
    love.graphics.draw(my_icon, state.player_state.x, state.player_state.y, 0, sx, sy)
    if state.coin then
        love.graphics.rectangle("fill", state.coin.x - 1, state.coin.y - 1, 2, 2)
    end
end

return main