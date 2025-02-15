local path = ...
return {
    assets = require(path..".assets"),
    rng = require(path..".rng")
}