local M = {}

local n = require("nui-components")
if not n then
    error("Failed to load nui-components")
end
local state = require("spectre.state")
local api = vim.api
local state_utils = require("spectre.state_utils")
local has_devicons, devicons = pcall(require, 'nvim-web-devicons')
local utils = require("spectre.utils")

local renderer = nil
local preview_win = nil
local preview_buf = nil
local preview_namespace = api.nvim_create_namespace('SPECTRE_PREVIEW')

local function create_search_ui()
    -- Create a new buffer for the results
    local bufnr = api.nvim_create_buf(false, true)
    api.nvim_buf_set_option(bufnr, "filetype", "spectre_panel")
    api.nvim_buf_set_option(bufnr, "buftype", "nofile")
    api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
    api.nvim_buf_set_option(bufnr, "buflisted", false)

    -- Create a separate buffer for preview
    local preview_bufnr = api.nvim_create_buf(false, true)
    api.nvim_buf_set_option(preview_bufnr, "filetype", "markdown")
    api.nvim_buf_set_option(preview_bufnr, "buftype", "nofile")
    api.nvim_buf_set_option(preview_bufnr, "bufhidden", "wipe")
    api.nvim_buf_set_option(preview_bufnr, "buflisted", false)
    api.nvim_buf_set_option(preview_bufnr, "wrap", true)
    api.nvim_buf_set_option(preview_bufnr, "number", true)
    api.nvim_buf_set_option(preview_bufnr, "relativenumber", true)

    local signal = n.create_signal({
        search_text = "",
        replace_text = "",
        path = "",
        is_file = false,
        results = {},
        has_search = false,
        preview_visible = false,
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
                        signal.has_search = #value > 0
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
            
                n.tree({
                    id = "results-tree",
                    flex = 1,
                    border_label = "Results",
                    data = signal.results,
                    hidden = signal.has_search:negate(),
                    on_select = function(node, component)
                        if node.is_done ~= nil then
                            node.is_done = not node.is_done
                            component:render()
                        end
                    end,
                    on_focus = function(component)
                        signal.preview_visible = true
                    end,
                    on_blur = function(node, component)
                        signal.preview_visible = false
                        component:render()
                    end,
                    on_change = function(focused_node, component)
                        if focused_node.filename then
                            local full_path = vim.fn.fnamemodify(focused_node.filename, ":p")
                            if vim.fn.filereadable(full_path) then
                                local lines = vim.fn.readfile(full_path)
                                api.nvim_buf_set_lines(preview_bufnr, 0, -1, false, lines)
                                
                                -- Clear previous highlights
                                api.nvim_buf_clear_namespace(preview_bufnr, preview_namespace, 0, -1)
                                
                                -- Add search highlighting if there's a search query
                                if state.query and state.query.search_query and #state.query.search_query > 0 then
                                    for i, line in ipairs(lines) do
                                        local matches = utils.match_text_line(state.query.search_query, line, 0)
                                        for _, match in ipairs(matches) do
                                            api.nvim_buf_add_highlight(
                                                preview_bufnr,
                                                preview_namespace,
                                                state.user_config.highlight.search,
                                                i - 1,
                                                match[1],
                                                match[2]
                                            )
                                        end
                                    end
                                end
                                
                                -- Highlight the current line in the preview buffer
                                if focused_node.lnum then
                                    local line_num = tonumber(focused_node.lnum)
                                    if line_num then
                                        -- Set cursor to the line number in the preview buffer
                                        api.nvim_buf_call(preview_bufnr, function()
                                            vim.cmd("normal! " .. line_num .. "G")
                                        end)
                                    end
                                end
                            end
                        else
                            api.nvim_buf_set_lines(preview_bufnr, 0, -1, false, {})
                        end
                    end,
                    prepare_node = function(node, line, component)
                        if node.is_done ~= nil then
                            if node.is_done then
                                local icon = "✔"
                                local hl = "String"
                                if has_devicons then
                                    icon = '󰱒' 
                                end
                                line:append('  ' .. icon .. ' ', hl)
                            else
                                local icon = "◻"
                                local hl = "Comment"
                                if has_devicons then
                                    icon = '' 
                                end
                                line:append('  ' .. icon .. ' ', hl)
                            end
                        end

                        if node.icon then
                            line:append(" " .. node.icon .. " ", node.icon_highlight)
                        end

                        -- Add search highlighting if there's a search query
                        if state.query and state.query.search_query and #state.query.search_query > 0 and node.text then
                            local matches = utils.match_text_line(state.query.search_query, node.text, 0)
                            local last_pos = 0
                            for _, match in ipairs(matches) do
                                -- Add text before the match
                                if match[1] > last_pos then
                                    line:append(" " .. node.text:sub(last_pos + 1, match[1]))
                                end
                                -- Add highlighted match
                                line:append(node.text:sub(match[1] + 1, match[2]), state.user_config.highlight.search)
                                last_pos = match[2]
                            end
                            -- Add remaining text after last match
                            if last_pos < #node.text then
                                line:append(" " .. node.text:sub(last_pos + 1))
                            end
                        else
                            line:append(" " .. node.text)
                        end
                        return line
                    end,
                }),
                n.buffer({
                    id = "preview-buffer",
                    flex = 1,
                    border_label = "Preview",
                    hidden = signal.preview_visible:negate(),
                    buf = preview_bufnr,
                    autoscroll = true,
                }),

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
                })
            )
        )
    end

    local new_renderer = n.create_renderer({
        width = 80,
        height = 40,
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
                    filename = result.filename,
                    col = result.col,
                    lnum = result.lnum,
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
        table.insert(options, n.option(string.format("%d: %s", i, option.desc or ""), { id = key }))
        i = i + 1
    end

    local signal = n.create_signal({
        selected = {},
    })

    local select_component = n.select({
        border_label = "Options",
        data = options,
        selected = signal.selected,
        multiselect = true,
        on_select = function(nodes)
            signal.selected = nodes
            for _, node in ipairs(nodes) do
                state.options[node.id] = not state.options[node.id]
            end
            M.on_search_change()
        end,
    })

    select_component:mount()
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