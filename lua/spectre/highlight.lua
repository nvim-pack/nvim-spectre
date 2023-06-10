local M = {}
local create_highlight_group = function (name, link)
    local ok, hl = pcall(vim.api.nvim_get_hl_by_name, link, true)
    if not ok then
        return
    end
    if hl.foreground ~= nil then
        -- vim.cmd.highlight({name, 'guifg='.. string.format("#%06x", hl.foreground)})
        vim.cmd("highlight " .. name .. " guifg=" .. string.format("#%06x", hl.foreground) )
    end

    if hl.background ~= nil then
        -- vim.cmd.highlight({name, 'guibg='.. string.format("#%06x", hl.background)})
        vim.cmd("highlight " .. name .. " guibg=" .. string.format("#%06x", hl.background) )
    end
end

create_highlight_group('SpectreHeader', "Comment")
create_highlight_group('SpectreBody', "String")
create_highlight_group('SpectreFile', "Keyword")
create_highlight_group('SpectreDir', "Comment")
create_highlight_group('SpectreSearch', "DiffChange")
create_highlight_group('SpectreBorder', "Comment")
create_highlight_group('SpectreReplace', "DiffDelete")

return M;
