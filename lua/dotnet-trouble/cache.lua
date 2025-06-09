local M = {}

M._cache = {}

function M.__getOrSetCache(cache_name)
    if not M._cache[cache_name] then
        M._cache[cache_name] = {}
    end

    return M._cache[cache_name]
end

function M.Get(cache_name, cache_key)
    return M.__getOrSetCache(cache_name)[cache_key]
end

function M.Set(cache_name, cache_key, value)
    local c = M.__getOrSetCache(cache_name)

    c[cache_key] = value

    return c[cache_key]
end

return M
