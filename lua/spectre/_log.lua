return require('plenary.log').new {
    plugin = 'nvim-spectre',
    level = (_G.__is_log == true and 'debug') or 'warn',
}

