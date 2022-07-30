local api = vim.api

local config = {
    filetype         = "spectre_panel",
    namespace        = api.nvim_create_namespace("SEARCH_PANEL"),
    namespace_ui     = api.nvim_create_namespace("SEARCH_PANEL_UI"),
    namespace_header = api.nvim_create_namespace("SEARCH_PANEL_HEADER"),
    namespace_status = api.nvim_create_namespace("SEARCH_PANEL_STATUS"),
    namespace_result = api.nvim_create_namespace("SEARCH_PANEL_RESULT"),

    lnum_UI = 8, -- total line for ui you can edit it
    line_result = 10, -- line begin result

    -- result_padding = '│  ',
    -- color_devicons = true,
    -- line_sep = '├──────────────────────────────────────',
    -- line_sep_start = '┌-----------------------------------------',
    result_padding     = '¦  ',
    color_devicons     = true,
    line_sep_start     = '------------------------------------------',
    line_sep           = '------------------------------------------',
    open_cmd           = 'vnew',
    live_update        = false,
    highlight          = {
        ui = "String",
        filename = "Keyword",
        filedirectory = "Comment",
        search = "DiffChange",
        border = "Comment",
        replace = "DiffDelete"
    },
    mapping            = {
        ['toggle_line'] = {
            map = "dd",
            cmd = "<cmd>lua require('spectre').toggle_line()<CR>",
            desc = "delete current item"
        },
        ['enter_file'] = {
            map = "<cr>",
            cmd = "<cmd>lua require('spectre.actions').select_entry()<CR>",
            desc = "goto current file"
        },
        ['send_to_qf'] = {
            map = "<leader>q",
            cmd = "<cmd>lua require('spectre.actions').send_to_qf()<CR>",
            desc = "send all item to quickfix"
        },
        ['replace_cmd'] = {
            map = "<leader>c",
            cmd = "<cmd>lua require('spectre.actions').replace_cmd()<CR>",
            desc = "input replace vim command"
        },
        ['show_option_menu'] = {
            map = "<leader>o",
            cmd = "<cmd>lua require('spectre').show_options()<CR>",
            desc = "show option"
        },
        ['run_current_replace'] = {
            map = "<leader>rc",
            cmd = "<cmd>lua require('spectre.actions').run_current_replace()<CR>",
            desc = "replace current item"
        },
        ['run_replace'] = {
            map = "<leader>R",
            cmd = "<cmd>lua require('spectre.actions').run_replace()<CR>",
            desc = "replace all"
        },
        -- only show replace text in result UI
        ['change_view_mode'] = {
            map = "<leader>v",
            cmd = "<cmd>lua require('spectre').change_view()<CR>",
            desc = "change result view mode"
        },
        ['change_replace_sed'] = {
            map = "trs",
            cmd = "<cmd>lua require('spectre').change_engine_replace('sed')<CR>",
            desc = "use sed to replace"
        },
        ['change_replace_oxi'] = {
            map = "tro",
            cmd = "<cmd>lua require('spectre').change_engine_replace('oxi')<CR>",
            desc = "use oxi to replace"
        },
        ['toggle_live_update'] = {
            map = "tu",
            cmd = "<cmd>lua require('spectre').toggle_live_update()<CR>",
            desc = "update change when vim write file."
        },
        -- only work if the find_engine following have that option
        ['toggle_ignore_case'] = {
            map = "ti",
            cmd = "<cmd>lua require('spectre').change_options('ignore-case')<CR>",
            desc = "toggle ignore case"
        },
        ['toggle_ignore_hidden'] = {
            map = "th",
            cmd = "<cmd>lua require('spectre').change_options('hidden')<CR>",
            desc = "toggle search hidden"
        },
    },
    find_engine        = {
        ['rg'] = {
            cmd = "rg",
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
                    value = "--ignore-case",
                    icon = "[I]",
                    desc = "ignore case"
                },
                ['hidden'] = {
                    value = "--hidden",
                    desc = "hidden file",
                    icon = "[H]"

                },
                -- you can put any option you want here it can toggle with
                -- show_option function
            }
        },
        ['ag'] = {
            cmd = "ag",
            -- default args
            args = {
                '--vimgrep',
                '-s'
            },
            options = {
                ['ignore-case'] = {
                    value = "-i",
                    icon = "[I]",
                    desc = "ignore case"
                },
                ['hidden'] = {
                    value = "--hidden",
                    desc = "hidden file",
                    icon = "[H]"
                },
            },
        },
    },
    replace_engine     = {
        ['sed'] = {
            cmd = "sed",
            args = {
                '-i',
                '-E',
            },
            options = {
                ['ignore-case'] = {
                    value = "--ignore-case",
                    icon = "[I]",
                    desc = "ignore case"
                },
            }
        },
        ['oxi'] = {
            cmd = 'oxi',
            args = {},
            options = {
                ['ignore-case'] = {
                    value = "i",
                    icon = "[I]",
                    desc = "ignore case"
                },
            }
        }
    },
    default            = {
        find = {
            cmd = "rg",
            options = { "ignore-case" }
        },
        replace = {
            cmd = "sed"
        }
    },
    replace_vim_cmd    = "cdo",
    is_open_target_win = true,
    is_insert_mode     = false,
}

if vim.loop.os_uname().sysname == 'Darwin' then
    config.replace_engine.sed.cmd = "gsed"
    if vim.fn.executable('gsed') == 0 then
        print("You need to install gnu sed 'brew install gnu-sed'")
    end
end
return config
