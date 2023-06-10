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
    -- line_sep_start = '┌-----------------------------------------',
    -- result_padding     = '¦  ',
    -- line_sep = '├──────────────────────────────────────',

    line_sep_start = '┌──────────────────────────────────────────────────────',
    result_padding = '│  ',
    line_sep       = '└──────────────────────────────────────────────────────',
    color_devicons     = true,
    open_cmd           = 'vnew',
    live_update        = false,
    highlight          = {
        headers = "Comment",
        ui = "String",
        filename = "Keyword",
        filedirectory = "Comment",
        search = "DiffChange",
        border = "Comment",
        replace = "DiffDelete"
    },
    mapping            = {
        ['toggle_line'] = {
            map = "d",
            cmd = "<cmd>lua require('spectre').toggle_line()<CR>",
            desc = "toggle item."
        },
        ['enter_file'] = {
            map = "<cr>",
            cmd = "<cmd>lua require('spectre.actions').select_entry()<CR>",
            desc = "open file."
        },
        ['send_to_qf'] = {
            map = "sqf",
            cmd = "<cmd>lua require('spectre.actions').send_to_qf()<CR>",
            desc = "send all items to quickfix."
        },
        ['replace_cmd'] = {
            map = "src",
            cmd = "<cmd>lua require('spectre.actions').replace_cmd()<CR>",
            desc = "replace command."
        },
        ['show_option_menu'] = {
            map = "so",
            cmd = "<cmd>lua require('spectre').show_options()<CR>",
            desc = "show options."
        },
        ['run_current_replace'] = {
          map = "c",
          cmd = "<cmd>lua require('spectre.actions').run_current_replace()<CR>",
          desc = "confirm item."
        },
        ['run_replace'] = {
            map = "R",
            cmd = "<cmd>lua require('spectre.actions').run_replace()<CR>",
            desc = "replace all."
        },
        ['change_view_mode'] = {
            map = "sv",
            cmd = "<cmd>lua require('spectre').change_view()<CR>",
            desc = "results view mode."
        },
        ['change_replace_sed'] = {
          map = "srs",
          cmd = "<cmd>lua require('spectre').change_engine_replace('sed')<CR>",
          desc = "use sed to replace."
        },
        ['change_replace_oxi'] = {
          map = "sro",
          cmd = "<cmd>lua require('spectre').change_engine_replace('oxi')<CR>",
          desc = "use oxi to replace."
        },
        ['toggle_live_update']={
          map = "sar",
          cmd = "<cmd>lua require('spectre').toggle_live_update()<CR>",
          desc = "auto refresh changes when nvim writes a file."
        },
        ['resume_last_search'] = {
          map = "sl",
          cmd = "<cmd>lua require('spectre').resume_last_search()<CR>",
          desc = "repeat last search."
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

if vim.loop.os_uname().sysname == 'Windows_NT' then
    if vim.fn.executable('sed') == 0 then
        print("You need to install gnu sed with 'scoop install sed' or 'choco install sed'")
    end
end
return config
