local M = {}
-- [[
-- This code was taken from neo-tree
-- link: https://github.com/nvim-neo-tree/neo-tree.nvim 
-- ]]
local function dec_to_hex(n, chars)
  chars = chars or 6
  local hex = string.format("%0" .. chars .. "x", n)
  while #hex < chars do
    hex = "0" .. hex
  end
  return hex
end
local create_highlight_group = function(hl_group_name, link_to_if_exists, background, foreground, gui)
  local success, hl_group = pcall(vim.api.nvim_get_hl_by_name, hl_group_name, true)
  if not success or not hl_group.foreground or not hl_group.background then
    for _, link_to in ipairs(link_to_if_exists) do
      success, hl_group = pcall(vim.api.nvim_get_hl_by_name, link_to, true)
      if success then
        local new_group_has_settings = background or foreground or gui
        local link_to_has_settings = hl_group.foreground or hl_group.background
        if link_to_has_settings or not new_group_has_settings then
          vim.cmd("highlight default link " .. hl_group_name .. " " .. link_to)
          return hl_group
        end
      end
    end

    if type(background) == "number" then
      background = dec_to_hex(background)
    end
    if type(foreground) == "number" then
      foreground = dec_to_hex(foreground)
    end

    local cmd = "highlight default " .. hl_group_name
    if background then
      cmd = cmd .. " guibg=#" .. background
    end
    if foreground then
      cmd = cmd .. " guifg=#" .. foreground
    else
      cmd = cmd .. " guifg=NONE"
    end
    if gui then
      cmd = cmd .. " gui=" .. gui
    end
    vim.cmd(cmd)

    return {
      background = background and tonumber(background, 16) or nil,
      foreground = foreground and tonumber(foreground, 16) or nil,
    }
  end
  return hl_group
end

-- local normal = vim.api.nvim_get_hl_by_name("Normal", true)
create_highlight_group('SpectreHeader', {"DiffDelete"})
create_highlight_group('SpectreBody', {"String"})
create_highlight_group('SpectreFile', {"Keyword"})
create_highlight_group('SpectreDir', {"Comment"})
create_highlight_group('SpectreSearch', {"DiffChange"})
create_highlight_group('SpectreBorder', {"Comment"})
create_highlight_group('SpectreReplace', {"DiffDelete"})

return M;
