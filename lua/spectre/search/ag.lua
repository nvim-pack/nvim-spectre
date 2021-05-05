local ag = {}

ag.init = function(_, config)
    config = vim.tbl_extend('force',{
        cmd = "ag",
        args = {
            '--vimgrep',
            '-s'
        },
    }, config or {})
    return config
end

ag.get_path_args = function(_, path)
    if #path == 0 then
      return {}
    end
    return  { '-G', path }
end

return ag
