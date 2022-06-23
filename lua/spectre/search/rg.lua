local rg = {}

rg.init = function(_, config)
    config = vim.tbl_extend('force', {
        cmd = "rg",
        args = {
            '--color=never',
            '--no-heading',
            '--with-filename',
            '--line-number',
            '--column',
        },
    }, config or {})
    return config
end

rg.get_path_args = function(_, paths)
    if #paths == 0 then
        return {}
    end

    local args = {}
    for _, path in ipairs(paths) do
        table.insert(args, "-g")
        table.insert(args, path)
    end
    return args
end


return rg
