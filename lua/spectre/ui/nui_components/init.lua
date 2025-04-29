local n = require("nui-components")
if not n then
    error("Failed to load nui-components")
end

local state = require("spectre.state")
local config = require("spectre.config")
local utils = require("spectre.utils")
local api = vim.api
local state_utils = require("spectre.state_utils")
local has_devicons, devicons = pcall(require, 'nvim-web-devicons')

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
        results = {},
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
            n.tree({
                id = "results-tree",
                flex = 1,
                border_label = "Results",
                data = signal.results,
                on_select = function(node, component)
                    if node.is_done ~= nil then
                        node.is_done = not node.is_done
                        component:render()
                    end
                end,
                prepare_node = function(node, line, component)
                    if node.is_done then
                        line:append("✔", "String")
                    else
                        line:append("◻", "Comment")
                    end

                    if node.icon then
                        line:append(" " .. node.icon .. " ", node.icon_highlight)
                    end

                    line:append(" " .. node.text)
                    return line
                end,
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
    return new_renderer, signal
end

function M.open()
    if renderer then
        M.close()
    end

    local new_renderer, signal = create_search_ui()
    renderer = new_renderer
    M.signal = signal
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
    local results_component = renderer:get_component_by_id("results-tree")
    if not results_component then return end

    local results = {}
    local last_filename = ""
    local current_group = nil

    -- Start search
    local finder_creator = state_utils.get_finder_creator()
    state.finder_instance = finder_creator:new(state_utils.get_search_engine_config(), {
        on_result = function(result)
            if last_filename ~= result.filename then
                local icon, icon_highlight = "", ""
                if has_devicons then
                    icon, icon_highlight = devicons.get_icon(result.filename, "", { default = true })
                end
                
                current_group = n.node({
                    text = result.filename,
                    icon = icon,
                    icon_highlight = icon_highlight,
                    children = {}
                })
                table.insert(results, current_group)
                last_filename = result.filename
            end

            if current_group then
                table.insert(results, n.node({
                    text = string.format("%d:%d: %s", result.lnum, result.col, result.text),
                    is_done = false
                }))
            end
        end,
        on_finish = function()
            state.finder_instance = nil
            if M.signal then
                M.signal.results = results
                renderer:redraw()
            end
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
        table.insert(options, string.format("%d: %s", i, option.desc or ""))
        i = i + 1
    end

    vim.ui.select(options, {
        prompt = "Select option to toggle:",
        format_item = function(item)
            return item
        end,
    }, function(choice)
        if not choice then return end
        local index = tonumber(choice:match("(%d+):"))
        if not index then return end
        
        local i = 1
        for key, _ in pairs(cfg.options) do
            if i == index then
                state.options[key] = not state.options[key]
                M.on_search_change()
                break
            end
            i = i + 1
        end
    end)
end

function M.toggle_live_update()
    state.user_config.live_update = not state.user_config.live_update
    M.on_search_change()
end

function M.toggle_preview()
    if not renderer then return end
    local results_component = renderer:get_component_by_id("results-tree")
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
        renderer = nil
    end
    if preview_win and api.nvim_win_is_valid(preview_win) then
        api.nvim_win_close(preview_win, true)
        preview_win = nil
        preview_buf = nil
    end
end

return M 