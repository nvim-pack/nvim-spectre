return require('plenary.log').new {
    level = (_G.__is_log == true and 'debug') or 'warn',
}

