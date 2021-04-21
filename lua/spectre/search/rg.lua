
local rg = {}

rg.init = function(_, config)
    config = vim.tbl_extend('force',{
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

rg.get_path_args = function(_, path)
    if #path == 0 then
      return {}
    end
    return  { '-g', path }
end


return rg
