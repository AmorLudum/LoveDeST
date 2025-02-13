local assets = {}

assets.group = {}
assets.map = {}

local function _reload(key, path_and_arg)
    local path = type(path_and_arg) == "table" and path_and_arg[1] or path_and_arg
    if assets.map[path] then
        print(string.format("Reload asset: %s - %s", key,  path))
        assets.map[path]:release()
    end
    local splited = lume.split(path, ".")
    local ext = splited[#splited]
    local full_path = "assets/"..path
    local ret = nil
    local r, err = pcall(function()
        if ext == "png" then
            ret = love.graphics.newImage(full_path)
        elseif ext == "ttf" then
            ret = love.graphics.newFont(full_path, path_and_arg[2])
        end
    end)
    if r then
        assets.map[key] = ret
    else
        print(string.format("Failed to load\n\t%s\n\t%s", path, err))
    end
end
function assets.setup(data)
    assets.data = data
    for k, v in pairs(data.static_group) do
        _reload(k, v)
    end
end
function assets.get(path)
    return assets.map[path]
end

function assets.clear(...)
    for k, v in pairs(assets.map) do
        v:release()
    end
end

return assets