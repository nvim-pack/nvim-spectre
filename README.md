# nvim-spectre
A search panel for neovim.

**Spectre** __Find the enemy and replace them with dark power.__

![demo](./images/demo.gif)

**WIP**
## Feature
* Use regex in search
* I don't need a typeahead function It always search when i type and it is very useless on
search with regex.
* I don't want a floating window with multiple buffer 1 buffer is enough I can move
and copy easy.

<h1>Spectre</h1>

## Installation

``` lua
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'windwp/nvim-spectre'
```
## Usage
Try the command `:Spectre`

``` vim 
vnoremap <leader>R :lua require('spectre').open_visual()<CR>
nnoremap <leader>R :lua require('spectre').open()<CR>
nnoremap <leader>R viw:lua require('spectre').open_visual()<CR>
nnoremap <leader>rp viw:lua require('spectre').open_file_search()<cr> 
```
You can use dd to delete result ite

**WARNING** 
- Commit your file before you replace text. it doesn't suport undo
-Don't use your crazy vim skill to edit result text or UI

## FAQ
* what is Spectre?
> I want create a `Search Panel` but this name is not cool so I get the hero name from
> dota2 game. Spectre has a skill to find enemy on global map so i use it:)
