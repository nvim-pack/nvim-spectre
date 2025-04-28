local n = require("nui-components")
if not n then
    error("Failed to load nui-components")
end

local state = require("spectre.state")
local config = require("spectre.config")
local utils = require("spectre.utils")
local api = vim.api
local state_utils = require("spectre.state_utils")

local M = {}

local renderer = nil
local search_input = nil
local replace_input = nil
local path_input = nil
local results_buffer = nil
local preview_win = nil
local preview_buf = nil

local function create_search_ui()
    -- Create a new buffer for the results
    local bufnr = api.nvim_create_buf(false, true)
    api.nvim_buf_set_name(bufnr, "spectre")
    api.nvim_buf_set_option(bufnr, "filetype", "spectre_panel")
    api.nvim_buf_set_option(bufnr, "buftype", "nofile")
    api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
    api.nvim_buf_set_option(bufnr, "buflisted", false)

    local signal = n.create_signal({
        search_text = "",
        replace_text = "",
        path = "",
        is_file = false,
    })

    local body = function()
        return n.rows(
            n.columns(
                { flex = 0 },
                n.text_input({
                    id = "search-input",
                    border_label = "Search",
                    autofocus = true,
                    flex = 1,
                    max_lines = 1,
                    on_change = function(value)
                        signal.search_text = value
                        vim.schedule(function()
                            M.on_search_change()
                        end)
                    end,
                })
            ),
            n.columns(
                { flex = 0 },
                n.text_input({
                    id = "replace-input",
                    border_label = "Replace",
                    flex = 1,
                    max_lines = 1,
                    on_change = function(value)
                        signal.replace_text = value
                        vim.schedule(function()
                            M.on_search_change()
                        end)
                    end,
                })
            ),
            n.columns(
                { flex = 0 },
                n.text_input({
                    id = "path-input",
                    border_label = "Path",
                    flex = 1,
                    max_lines = 1,
                    on_change = function(value)
                        signal.path = value
                        vim.schedule(function()
                            M.on_search_change()
                        end)
                    end,
                })
            ),
            n.columns(
                { flex = 0 },
                n.button({
                    label = "Options",
                    on_press = function()
                        print("Options")
                        vim.schedule(function()
                            M.show_options()
                        end)
                    end,
                }),
                n.gap(3),
                n.button({
                    label = "Replace All",
                    on_press = function()
                        vim.schedule(function()
                            M.run_replace()
                        end)
                    end,
                }),
                n.gap(3),
                n.button({
                    label = "Live Update",
                    on_press = function()
                        vim.schedule(function()
                            M.toggle_live_update()
                        end)
                    end,
                }),
                n.gap(3),
                n.button({
                    label = "Preview",
                    on_press = function()
                        vim.schedule(function()
                            M.toggle_preview()
                        end)
                    end,
                })
            ),
            n.buffer({
                id = "results-buffer",
                flex = 1,
                border_label = "Results",
                autoscroll = true,
                buf = bufnr,
            })
        )
    end

    local new_renderer = n.create_renderer({
        width = 80,
        height = 20,
        buf = bufnr,
        parent = vim.api.nvim_get_current_win(),
        border = {
            style = "rounded",
            text = {
                top = "[Nvim Spectre]",
                top_align = "center",
            },
        },
    })

    if not new_renderer then
        error("Failed to create renderer")
    end

    new_renderer:render(body)
    return new_renderer
end

function M.open()
    if renderer then
        print ("close")
        M.close()
    end

    local new_renderer = create_search_ui()
    -- if not new_renderer or type(new_renderer.mount) ~= "function" then
    --     error("Failed to create search UI: renderer is invalid")
    -- end

    renderer = new_renderer
    -- renderer:render()
end

function M.on_search_change() 
    if not renderer then return end
    print("on_search_change")
    local query = {
        search_query = renderer:get_component_by_id("search-input"):get_current_value(),
        replace_query = renderer:get_component_by_id("replace-input"):get_current_value(),
        path = renderer:get_component_by_id("path-input"):get_current_value(),
    }
    state.query = query -- Store the query in state
    M.search(query)
end

function M.search(query)
    if not renderer then return end
    -- Clear results buffer
    local results_component = renderer:get_component_by_id("results-buffer")
    if not results_component then return end
    local bufnr = results_component.bufnr

    vim.schedule(function()
        api.nvim_buf_set_lines(bufnr, 0, -1, false, {})

        -- Start search
        local finder_creator = state_utils.get_finder_creator()
        state.finder_instance = finder_creator:new(state_utils.get_search_engine_config(), {
            on_result = function(result)
                local line = string.format("%s:%d:%d: %s", result.filename, result.lnum, result.col, result.text)
                api.nvim_buf_set_lines(bufnr, -1, -1, false, { line })
            end,
            on_finish = function()
                state.finder_instance = nil
                if preview_win and api.nvim_win_is_valid(preview_win) then
                    M.toggle_preview() -- Refresh preview if it's open
                end
            end,
        })

        state.finder_instance:search({
            cwd = state.cwd,
            search_text = query.search_query,
            path = query.path,
        })
    end)
end

function M.run_replace()
    if not renderer then return end
    local entries = M.get_all_entries()
    if #entries == 0 then
        vim.notify("No entries to replace")
        return
    end

    vim.schedule(function()
        local replacer_creator = state_utils.get_replace_creator()
        local replacer = replacer_creator:new(state_utils.get_replace_engine_config(), {
            on_done = function(result)
                if result.ref then
                    M.set_entry_finish(result.ref.display_lnum)
                end
            end,
            on_error = function(result)
                if result.ref then
                    vim.notify("Error replacing: " .. result.value, vim.log.levels.ERROR)
                end
            end,
        })

        for _, entry in ipairs(entries) do
            if not entry.is_replace_finish then
                replacer:replace({
                    lnum = entry.lnum,
                    col = entry.col,
                    cwd = state.cwd,
                    display_lnum = entry.display_lnum,
                    filename = entry.filename,
                    search_text = state.query.search_query,
                    replace_text = state.query.replace_query,
                })
            end
        end
    end)
end

function M.show_options()
    if not renderer then return end
    local cfg = state_utils.get_search_engine_config()
    local options = {}
    local i = 1

    for key, option in pairs(cfg.options) do
        table.insert(options, {
            text = string.format("%d: %s", i, option.desc or ""),
            value = key,
        })
        i = i + 1
    end

    vim.schedule(function()
        local menu = n.menu({
            position = "50%",
            size = {
                width = 30,
                height = #options + 2,
            },
            border = {
                style = "rounded",
                text = {
                    top = "[Options]",
                    top_align = "center",
                },
            },
        }, {
            lines = options,
            on_submit = function(item)
                state.options[item.value] = not state.options[item.value]
                M.on_search_change()
            end,
        })

        menu:mount()
    end)
end

function M.toggle_live_update()
    state.user_config.live_update = not state.user_config.live_update
    M.on_search_change()
end

function M.toggle_preview()
    if not renderer then return end
    local results_component = renderer:get_component_by_id("results-buffer")
    if not results_component then return end

    if preview_win and api.nvim_win_is_valid(preview_win) then
        api.nvim_win_close(preview_win, true)
        preview_win = nil
        preview_buf = nil
        return
    end

    local bufnr = results_component.bufnr
    local cursor_pos = api.nvim_win_get_cursor(0)
    local line = api.nvim_buf_get_lines(bufnr, cursor_pos[1] - 1, cursor_pos[1], false)[1]

    if not line then return end

    local filename, lnum, col = line:match("([^:]+):(%d+):(%d+):")
    if not filename or not lnum or not col then return end

    local full_path = vim.fn.fnamemodify(filename, ":p")
    if not vim.fn.filereadable(full_path) then return end

    preview_buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_lines(preview_buf, 0, -1, false, vim.fn.readfile(full_path))
    api.nvim_buf_set_option(preview_buf, "filetype", vim.fn.fnamemodify(filename, ":e"))

    preview_win = api.nvim_open_win(preview_buf, false, {
        relative = "win",
        row = 0,
        col = api.nvim_win_get_width(0),
        width = 40,
        height = 20,
        border = "rounded",
    })

    api.nvim_win_set_cursor(preview_win, { tonumber(lnum), tonumber(col) - 1 })
    api.nvim_win_set_option(preview_win, "wrap", true)
    api.nvim_win_set_option(preview_win, "number", true)
    api.nvim_win_set_option(preview_win, "relativenumber", true)
end

function M.close()
    if renderer then
        -- renderer:unmount()
        renderer = nil
    end
    if preview_win and api.nvim_win_is_valid(preview_win) then
        api.nvim_win_close(preview_win, true)
        preview_win = nil
        preview_buf = nil
    end
end

return M 