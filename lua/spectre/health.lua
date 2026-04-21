--- Health checks for nvim-spectre.
--- Run with :checkhealth spectre
local M = {}

--- Check if an external command is available.
---@param cmd string
---@param optional boolean?
---@param install_hint string?
local function check_executable(cmd, optional, install_hint)
    if vim.fn.executable(cmd) == 1 then
        vim.health.ok(('%s: found'):format(cmd))
    elseif optional then
        vim.health.warn(('%s: not found (optional)'):format(cmd), install_hint and { install_hint } or nil)
    else
        vim.health.error(('%s: not found'):format(cmd), install_hint and { install_hint } or nil)
    end
end

M.check = function()
    vim.health.start('spectre')

    -- Neovim version check
    if vim.fn.has('nvim-0.8') == 1 then
        vim.health.ok(('Neovim version: %s'):format(tostring(vim.version())))
    else
        vim.health.error('Neovim >= 0.8 is required')
    end

    -- Required dependency: plenary.nvim
    local has_plenary = pcall(require, 'plenary')
    if has_plenary then
        vim.health.ok('plenary.nvim: found')
    else
        vim.health.error('plenary.nvim: not found', { 'Install nvim-lua/plenary.nvim' })
    end

    -- Search engines
    vim.health.start('spectre: search engines')
    check_executable('rg', false, "Install BurntSushi/ripgrep: 'cargo install ripgrep' or use your package manager")
    check_executable('ag', true, 'Install ggreer/the_silver_searcher (optional alternative to rg)')

    -- Replace engines
    vim.health.start('spectre: replace engines')
    local uname = vim.loop.os_uname().sysname
    if uname == 'Darwin' then
        if vim.fn.executable('gsed') == 1 then
            vim.health.ok('gsed: found (recommended on macOS)')
        elseif vim.fn.executable('sed') == 1 then
            vim.health.warn('sed: found, but gsed is recommended on macOS', { 'Install with: brew install gnu-sed' })
        else
            vim.health.error('sed/gsed: not found', { 'Install with: brew install gnu-sed' })
        end
    else
        check_executable('sed', false)
    end
    check_executable('sd', true, "Install chmln/sd: 'cargo install sd' (optional alternative to sed)")

    -- Optional: native Rust module (spectre_oxi)
    vim.health.start('spectre: optional components')
    local has_oxi = pcall(require, 'spectre_oxi')
    if has_oxi then
        vim.health.ok('spectre_oxi (native Rust module): found')
    else
        vim.health.info('spectre_oxi (native Rust module): not found (optional, build with ./build.sh)')
    end

    -- Optional: icon providers
    local has_devicons = pcall(require, 'nvim-web-devicons')
    local has_mini_icons = pcall(require, 'mini.icons')
    if has_devicons then
        vim.health.ok('nvim-web-devicons: found')
    elseif has_mini_icons then
        vim.health.ok('mini.icons: found')
    else
        vim.health.info('No icon provider found (optional: install nvim-web-devicons or mini.icons)')
    end
end

return M
