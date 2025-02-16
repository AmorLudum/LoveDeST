local assets = {}

assets.group = {}
assets.map = {}

local group_reverse_table = {}

local function _reload(key, path_and_arg)
    local path = type(path_and_arg) == "table" and path_and_arg[1] or path_and_arg
    if assets.map[key] then
        print(string.format("Reload asset: %s - %s", key,  path))
        assets.map[key]:release()
    end
    local ret, r, err
    if type(path) == "function" then
        r, err = pcall(function()
            ret = path()
        end)
    else
        local splited = lume.split(path, ".")
        local ext = splited[#splited]
        local full_path = "assets/"..path
        r, err = pcall(function()
            if ext == "png" then
                ret = love.graphics.newImage(full_path)
            elseif ext == "ttf" then
                ret = love.graphics.newFont(full_path, path_and_arg[2])
            end
        end)
    end
    if r then
        assets.map[key] = ret
    else
        print(string.format("Failed to load\n\t%s\n\t%s", path, err))
    end
end

local function _calculate_group_code(g)
    local num = 0
    for k, v in pairs(g) do
        local unit = group_reverse_table[k] - 1
        num = num + math.pow(2, unit)
    end
    return num
end
function assets.setup(data)
    assets.data = data
    for k, v in pairs(data.static_group) do
        _reload(k, v)
    end
    group_reverse_table = {}
    for i, v in pairs(data.dynamic_groups) do
        group_reverse_table[v.name] = i
    end
end
function assets.get(path)
    return assets.map[path]
end

function assets.clear()
    for k, v in pairs(assets.map) do
        v:release()
    end
    assets.group = {}
    assets.map = {}
end

function assets.load_dynamic_group(group_name)
    if not assets.group[group_name] and assets.data and group_reverse_table[group_name] then
        local group = assets.data.dynamic_groups[group_reverse_table[group_name]].contents
        assets.group[group_name] = true
        for k, v in pairs(group) do
            _reload(k, v)
        end
    end
    return _calculate_group_code(assets.group)
end

function assets.unload_dynamic_group(group_name)
    if assets.group[group_name] and assets.data and group_reverse_table[group_name] then
        local group = assets.data.dynamic_groups[group_reverse_table[group_name]].contents
        assets.group[group_name] = nil
        for k, v in pairs(group) do
            assets.map[k]:release()
            assets.map[k] = nil
        end
    end
    return _calculate_group_code(assets.group)
end

function assets.get_dynamic_group_code()
    return _calculate_group_code(assets.group)
end

function assets.restore_dynamic_group_by_code(code)
    local c = code
    for i = 1, #assets.data.dynamic_groups do
        local r = c % 2
        c = math.floor(c / 2)
        if r == 0 then
            assets.unload_dynamic_group(assets.data.dynamic_groups[i].name)
        else
            assets.load_dynamic_group(assets.data.dynamic_groups[i].name)
        end
    end
end

return assets