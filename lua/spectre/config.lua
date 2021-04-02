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

    line_sep = '--------------------------------------',
    result_padding = '    ',
    highlight = {
        ui = "String",
        search = "DiffChange",
        replace = "DiffDelete"
    },
    mapping = {
        ['delete_line'] = {
            map = "dd",
            cmd = "<cmd>lua require('spectre').delete()<CR>",
            desc = "delete current item"
        },
        ['enter_file'] = {
            map = "<cr>",
            cmd = "<cmd>lua require('spectre.actions').select_entry()<CR>",
            desc = "goto current file"
        },
        ['send_to_qf'] = {
            map = "rq",
            cmd = "<cmd>lua require('spectre.actions').send_to_qf()<CR>",
            desc = "send all item to quickfix"
        },
        ['replace_cmd'] = {
            map = "rc",
            cmd = "<cmd>lua require('spectre.actions').replace_cmd()<CR>",
            desc = "input replace vim command vim"
        },
        ['show_option_menu'] = {
            map = "to",
            cmd = "<cmd>lua require('spectre').show_options()<CR>",
            desc = "show option"
        },
        ['run_replace'] = {
            map = "rS",
            cmd = "<cmd>lua require('spectre.actions').run_replace()<CR>",
            desc = "replace all"
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
    find_engine = {
        ['rg'] = {
            cmd = "rg",
            -- default args
            args = {
                '--color=never',
                '--no-heading',
                '--with-filename',
                '--line-number',
                '--column',
            } ,
            options = {
                ['ignore-case'] = {
                        value= "--ignore-case",
                        icon="[I]",
                        desc="ignore case"
                },
                ['hidden'] = {
                    value="--hidden",
                    desc="hidden file",
                    icon="[H]"

                },
                -- you can put any option you want here it can toggle with
                -- show_option function
            }
        },
    },
    replace_engine={
       ['sed']={
            cmd = "sed",
            args = {
                '-i',
                '-E',
            }
        },
    },
    default = {
        find = {
            cmd = "rg",
            options = {"ignore-case"}
        },
        replace={
            cmd = "sed"
        }
    },
    replace_vim_cmd = "cfdo",
    is_open_target_win = true,
    is_insert_mode = false,
}

return config

