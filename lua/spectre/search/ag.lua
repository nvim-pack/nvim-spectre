local ag = {}

ag.init = function(_, config)
    config = vim.tbl_extend('force', {
        cmd = "ag",
        args = {
            '--vimgrep',
            '-s'
        },
    }, config or {})
    return config
end

ag.get_path_args = function(_, paths)
    if #paths == 0 then
        return {}
    end

    local pattern = ""
    for _, path in ipairs(paths) do
        pattern = pattern .. path .. "|"
    end
    return { '-G', pattern:sub(1, #pattern - 1) }
end

return ag
