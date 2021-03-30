local api = vim.api

local config = {
    filetype = "search_panel",
    namespace = api.nvim_create_namespace("SEARCH_PANEL"),
    namespace_status = api.nvim_create_namespace("SEARCH_PANEL_STATUS"),
    namespace_result = api.nvim_create_namespace("SEARCH_PANEL_RESULT"),
    line_sep = '--------------------------------------',
    highlight = {ui = "String", search = "DiffChange", replace = "DiffDelete"},
    mapping = {
        ['delete_line'] = {
            map = "dd",
            cmd = "<cmd>lua import('spectre').delete()<CR>",
            desc = "delete current item"
        },
        ['enter_file'] = {
            map = "<cr>",
            cmd = "<cmd>lua import('spectre.actions').select_entry()<CR>",
            desc = "goto current file"
        },
        ['send_to_qf'] = {
            map = "rq",
            cmd = "<cmd>lua import('spectre.actions').send_to_qf()<CR>",
            desc = "send all item to quickfix"
        },
        ['replace_cmd'] = {
            map = "rc",
            cmd = "<cmd>lua import('spectre.actions').replace_cmd()<CR>",
            desc = "input replace command vim"
        },
        ['run_replace'] = {
            map = "rs",
            cmd = "<cmd>lua import('spectre.actions').run_replace()<CR>",
            desc = "replace all"
        }
        -- ["undo_file"]     = {
        --   map = "ru",
        --   cmd = "<cmd>lua import('spectre.actions').undo_file()<CR>",
        --   desc="Goto file"
        -- },

        -- ["undo_all"]     = {
        --   map = "rU",
        --   cmd = "<cmd>lua import('spectre.actions').undo_all()<CR>",
        --   desc="Goto file"
        -- },
    },
    finder_cmd="rg",
    replace_cmd = "sed",
    lnum_UI = 8, -- total line for ui you can edit it
    line_result = 10, -- line begin result
    replace_vim_cmd = "cfdo",
    is_open_target_win = true
}

return config

