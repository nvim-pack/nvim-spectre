local M = {}

M.set_hl = function()
    vim.api.nvim_set_hl(0, 'SpectreHeader', { link = "Comment" })
    vim.api.nvim_set_hl(0, 'SpectreBody', { link = "String" })
    vim.api.nvim_set_hl(0, 'SpectreFile', { link = "Keyword" })
    vim.api.nvim_set_hl(0, 'SpectreDir', { link = "Comment" })
    vim.api.nvim_set_hl(0, 'SpectreSearch', { link = "DiffChange" })
    vim.api.nvim_set_hl(0, 'SpectreBorder', { link = "Comment" })
    vim.api.nvim_set_hl(0, 'SpectreReplace', { link = "DiffDelete" })
end

vim.api.nvim_create_autocmd('ColorScheme', {
    pattern = '*',
    callback = M.set_hl
})

return M;
