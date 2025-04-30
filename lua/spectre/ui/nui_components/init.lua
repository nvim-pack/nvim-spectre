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
                    end
                end,
                on_focus = function()
                    signal.preview_visible = true
                end,
                on_blur = function()
                    signal.preview_visible = false
                end,
                on_change = function(focused_node)
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
                                    -- Safely get matches with error handling
                                    local matches = {}
                                    local success, result = pcall(function()
                                        return utils.match_text_line(state.query.search_query, line, 0)
                                    end)
                                    
                                    if success and type(result) == "table" then
                                        matches = result
                                    end
                                    
                                    for _, match in ipairs(matches) do
                                        -- Safely add highlight
                                        pcall(function()
                                            api.nvim_buf_add_highlight(
                                                preview_bufnr,
                                                preview_namespace,
                                                state.user_config.highlight.search,
                                                i - 1,
                                                match[1],
                                                match[2]
                                            )
                                        end)
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
                            line:append('  ' .. icon .. ' ', hl)
                        else
                            local icon = "◻"
                            local hl = "Comment"
                            if has_devicons then
                                icon = ''
                            end
                            line:append('  ' .. icon .. ' ', hl)
                        end
                    end

                    if node.icon then
                        line:append(" " .. node.icon .. " ", node.icon_highlight)
                    end

                    -- Add search highlighting if there's a search query
                    if state.query and state.query.search_query and #state.query.search_query > 0 and node.text then
                        -- Safely get matches with error handling
                        local matches = {}
                        local success, result = pcall(function()
                            return utils.match_text_line(state.query.search_query, node.text, 0)
                        end)
                        
                        if success and type(result) == "table" then
                            matches = result
                        end
                        
                        local last_pos = 0
                        local max_width = vim.api.nvim_win_get_width(0) -
                        15                                                   -- Leave some space for icons and padding
                        local truncated_text = utils.truncate(node.text, max_width)

                        -- Find if this node has been replaced
                        local is_replaced = false
                        if state.total_item and node.display_lnum ~= nil then
                            for _, item in ipairs(state.total_item) do
                                if item and item.display_lnum and item.display_lnum == node.display_lnum and item.is_replace then
                                    is_replaced = true
                                    break
                                end
                            end
                        end

                        for _, match in ipairs(matches) do
                            -- Add text before the match
                            if match[1] > last_pos then
                                line:append(truncated_text:sub(last_pos + 1, match[1]))
                            end
                            
                            -- Add highlighted match
                            line:append(truncated_text:sub(match[1] + 1, match[2]), state.user_config.highlight.search)
                            
                            -- Add replacement preview if exists and not replaced yet
                            if state.query.replace_query and #state.query.replace_query > 0 and not is_replaced then
                                -- Get the regex engine with safety check
                                local regex = nil
                                local success, result = pcall(state_utils.get_regex)
                                if success then
                                    regex = result
                                else
                                    -- Fallback to vim regex
                                    regex = require('spectre.regex.vim')
                                end
                                
                                -- Calculate replace_match with error handling
                                local replace_match = {}
                                success, result = pcall(function()
                                    return utils.get_hl_line_text({
                                        search_query = state.query.search_query,
                                        replace_query = state.query.replace_query,
                                        search_text = truncated_text:sub(match[1] + 1, match[2]),
                                        show_search = true,
                                        show_replace = true
                                    }, regex).replace
                                end)
                                
                                if success then
                                    replace_match = result
                                end
                                
                                if type(replace_match) == "table" and #replace_match > 0 then
                                    -- Calculate replace_text with error handling
                                    local replace_text = ""
                                    success, result = pcall(function()
                                        return " → (" .. utils.get_hl_line_text({
                                            search_query = state.query.search_query,
                                            replace_query = state.query.replace_query,
                                            search_text = truncated_text:sub(match[1] + 1, match[2]),
                                        }, regex).text .. ")"
                                    end)
                                    
                                    if success then
                                        replace_text = result
                                        line:append(replace_text, state.user_config.highlight.replace)
                                    end
                                end
                            end
                            
                            last_pos = match[2]
                        end
                        -- Add remaining text after last match
                        if last_pos < #truncated_text then
                            line:append(truncated_text:sub(last_pos + 1))
                        end
                    else
                        local max_width = vim.api.nvim_win_get_width(0) -
                        15                                                   -- Leave some space for icons and padding
                        line:append(utils.truncate(node.text, max_width))
                    end
                    return line
                end,
            }),
            n.buffer({
                id = "preview-buffer",
                flex = 1,
                border_label = "Preview",
                hidden = signal.preview_visible:negate(),
                is_focusable = false,
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
                            require('spectre.actions').run_replace()
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
    if state.renderer then
        M.close()
    end

    local new_renderer, signal = create_search_ui()
    state.renderer = new_renderer
    M.signal = signal
end

function M.on_search_change()
    if not state.renderer then return end
    local query = {
        search_query = state.renderer:get_component_by_id("search-input"):get_current_value(),
        replace_query = state.renderer:get_component_by_id("replace-input"):get_current_value(),
        path = state.renderer:get_component_by_id("path-input"):get_current_value(),
    }
    state.query = query -- Store the query in state
    M.search(query)
end

function M.search(query)
    if not state.renderer then return end
    local results_component = state.renderer:get_component_by_id("results-tree")
    if not results_component then return end

    local results = {}
    local last_filename = ""
    local current_group = nil
    state.total_item = {} -- Reset total_item

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
                local entry = n.node({
                    filename = result.filename,
                    col = result.col,
                    lnum = result.lnum,
                    text = string.format("%d:%d: %s", result.lnum, result.col, result.text),
                    is_done = false,
                    display_lnum = #state.total_item
                })
                table.insert(results, entry)
                -- Store the entry in state.total_item with all required fields
                table.insert(state.total_item, {
                    filename = result.filename,
                    col = result.col,
                    lnum = result.lnum,
                    text = result.text,
                    display_lnum = #state.total_item,
                    is_replace_finish = false
                })
            end
        end,
        on_finish = function()
            state.finder_instance = nil
            if M.signal then
                M.signal.results = results
                state.renderer:redraw()
            end
        end,
    })

    state.finder_instance:search({
        cwd = state.cwd,
        search_text = query.search_query,
        path = query.path,
    })
end

function M.show_options()
    if not state.renderer then return end
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

function M.close()
    if state.renderer then
        state.renderer = nil
    end
end

return M
