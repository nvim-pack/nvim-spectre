#!/usr/bin/env -S nvim -l

-- determine path of this script when run with nvim -l or sourced by lazy.nvim
function script_path()
   local str = debug.getinfo(2, "S").source:sub(2)
   return str:match("(.*[/\\])")
end

vim.uv.chdir( script_path() .. '/spectre_oxi')

os.execute'cargo build --release'

local sysname = vim.uv.os_uname().sysname

if sysname == 'Darwin' then
    os.execute'cp target/release/libspectre_oxi.dylib ../lua/spectre_oxi.so'
elseif sysname == 'Linux' then
    os.execute'cp target/release/libspectre_oxi.so ../lua/spectre_oxi.so'
elseif sysname == 'Windows_NT' then
    os.execute'cp target/release/libspectre_oxi.dll ../lua/spectre_oxi.dll'
else
    error'unsupported os'
end

os.execute'rm -r -f target'
vim.print 'Build Done'
