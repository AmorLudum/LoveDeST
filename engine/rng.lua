local rng = {}

local r = love.math.newRandomGenerator()
function rng.next(rng_state)
    r:setState(rng_state)
    local n = r:random(100)
    return r:getState(), n
end

return rng