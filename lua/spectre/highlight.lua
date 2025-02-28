local M = {}

M.set_hl = function()
    vim.api.nvim_set_hl(0, 'SpectreHeader', { link = 'Comment', default = true })
    vim.api.nvim_set_hl(0, 'SpectreBody', { link = 'String', default = true })
    vim.api.nvim_set_hl(0, 'SpectreFile', { link = 'Keyword', default = true })
    vim.api.nvim_set_hl(0, 'SpectreDir', { link = 'Comment', default = true })
    vim.api.nvim_set_hl(0, 'SpectreSearch', { link = 'DiffChange', default = true })
    vim.api.nvim_set_hl(0, 'SpectreBorder', { link = 'Comment', default = true })
    vim.api.nvim_set_hl(0, 'SpectreReplace', { link = 'DiffDelete', default = true })
end

vim.api.nvim_create_autocmd('ColorScheme', {
    pattern = '*',
    callback = M.set_hl,
})

return M
