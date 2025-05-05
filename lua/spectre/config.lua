local api = vim.api

---@class SpectreConfig
local config = {
    filetype = 'spectre_panel',
    namespace = api.nvim_create_namespace('SEARCH_PANEL'),
    namespace_ui = api.nvim_create_namespace('SEARCH_PANEL_UI'),
    namespace_header = api.nvim_create_namespace('SEARCH_PANEL_HEADER'),
    namespace_status = api.nvim_create_namespace('SEARCH_PANEL_STATUS'),
    namespace_result = api.nvim_create_namespace('SEARCH_PANEL_RESULT'),

    lnum_UI = 8, -- total line for ui you can edit it
    line_result = 10, -- line begin result

    line_sep_start = '┌──────────────────────────────────────────────────────',
    result_padding = '│  ',
    line_sep = '└──────────────────────────────────────────────────────',
    color_devicons = true,
    open_cmd = 'vnew',
    live_update = false,
    lnum_for_results = false, -- show line number for search/replace results
    highlight = {
        headers = 'SpectreHeader',
        ui = 'SpectreBody',
        filename = 'SpectreFile',
        filedirectory = 'SpectreDir',
        search = 'SpectreSearch',
        border = 'SpectreBorder',
        replace = 'SpectreReplace',
    },
    mapping = {
        ['tab'] = {
            map = '<Tab>',
            cmd = "<cmd>lua require('spectre').tab()<cr>",
            desc = 'next query',
        },
        ['shift-tab'] = {
            map = '<S-Tab>',
            cmd = "<cmd>lua require('spectre').tab_shift()<cr>",
            desc = 'previous query',
        },
        ['toggle_line'] = {
            map = 'dd',
            cmd = "<cmd>lua require('spectre').toggle_line()<CR>",
            desc = 'toggle item',
        },
        ['enter_file'] = {
            map = '<cr>',
            cmd = "<cmd>lua require('spectre.actions').select_entry()<CR>",
            desc = 'open file',
        },
        ['send_to_qf'] = {
            map = '<leader>q',
            cmd = "<cmd>lua require('spectre.actions').send_to_qf()<CR>",
            desc = 'send all items to quickfix',
        },
        ['replace_cmd'] = {
            map = '<leader>c',
            cmd = "<cmd>lua require('spectre.actions').replace_cmd()<CR>",
            desc = 'input replace command',
        },
        ['show_option_menu'] = {
            map = '<leader>o',
            cmd = "<cmd>lua require('spectre').show_options()<CR>",
            desc = 'show options',
        },
        ['run_current_replace'] = {
            map = '<leader>rc',
            cmd = "<cmd>lua require('spectre.actions').run_current_replace()<CR>",
            desc = 'replace current item',
        },
        ['run_replace'] = {
            map = '<leader>R',
            cmd = "<cmd>lua require('spectre.actions').run_replace()<CR>",
            desc = 'replace all items',
        },
        -- only show replace text in result UI
        ['change_view_mode'] = {
            map = '<leader>v',
            cmd = "<cmd>lua require('spectre').change_view()<CR>",
            desc = 'change result view mode',
        },
        ['change_replace_sed'] = {
            map = 'trs',
            cmd = "<cmd>lua require('spectre').change_engine_replace('sed')<CR>",
            desc = 'use sed to replace',
        },
        ['change_replace_oxi'] = {
            map = 'tro',
            cmd = "<cmd>lua require('spectre').change_engine_replace('oxi')<CR>",
            desc = 'use oxi to replace',
        },
        ['toggle_live_update'] = {
            map = 'tu',
            cmd = "<cmd>lua require('spectre').toggle_live_update()<CR>",
            desc = 'update when vim writes to file',
        },
        -- only work if the find_engine following have that option
        ['toggle_ignore_case'] = {
            map = 'ti',
            cmd = "<cmd>lua require('spectre').change_options('ignore-case')<CR>",
            desc = 'toggle ignore case',
        },
        ['toggle_ignore_hidden'] = {
            map = 'th',
            cmd = "<cmd>lua require('spectre').change_options('hidden')<CR>",
            desc = 'toggle search hidden',
        },
        ['resume_last_search'] = {
            map = '<leader>l',
            cmd = "<cmd>lua require('spectre').resume_last_search()<CR>",
            desc = 'repeat last search',
        },
        ['select_template'] = {
            map = '<leader>rp',
            cmd = "<cmd>lua require('spectre.actions').select_template()<CR>",
            desc = 'pick template',
        },
        ['delete_line'] = {
            map = '<leader>rd',
            cmd = "<cmd>lua require('spectre.actions').run_delete_line()<CR>",
            desc = 'delete line',
        },
    },
    find_engine = {
        ['rg'] = {
            cmd = 'rg',
            -- default args
            args = {
                '--color=never',
                '--no-heading',
                '--with-filename',
                '--line-number',
                '--column',
            },
            options = {
                ['ignore-case'] = {
                    value = '--ignore-case',
                    icon = '[I]',
                    desc = 'ignore case',
                },
                ['hidden'] = {
                    value = '--hidden',
                    desc = 'hidden file',
                    icon = '[H]',
                },
                -- you can put any option you want here it can toggle with
                -- show_option function
            },
        },
        ['ag'] = {
            cmd = 'ag',
            -- default args
            args = {
                '--vimgrep',
                '-s',
            },
            options = {
                ['ignore-case'] = {
                    value = '-i',
                    icon = '[I]',
                    desc = 'ignore case',
                },
                ['hidden'] = {
                    value = '--hidden',
                    desc = 'hidden file',
                    icon = '[H]',
                },
            },
        },
    },
    replace_engine = {
        ['sed'] = {
            cmd = 'sed',
            args = nil,
            options = {
                ['ignore-case'] = {
                    value = '--ignore-case',
                    icon = '[I]',
                    desc = 'ignore case',
                },
            },
            warn = true,
        },
        ['oxi'] = {
            cmd = 'oxi',
            args = {},
            options = {
                ['ignore-case'] = {
                    value = 'i',
                    icon = '[I]',
                    desc = 'ignore case',
                },
            },
        },
        ['sd'] = {
            cmd = 'sd',
            options = {},
            warn = true,
        },
    },
    default = {
        find = {
            cmd = 'rg',
            options = { 'ignore-case' },
        },
        replace = {
            cmd = 'sed',
        },
    },
    replace_vim_cmd = 'cdo',
    use_trouble_qf = false,
    is_open_target_win = true,
    is_insert_mode = false,
    is_block_ui_break = false,
    open_template = {},
    ui = 'buffer',
}

return config
