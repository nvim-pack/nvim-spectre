# nvim-ts-autotag

Use treesitter to **autoclose** and **autorename** html tag

It work with html,tsx,vue,svelte.

## Usage

``` text
Before        Input         After
------------------------------------
<div           >         <div></div>
<div></div>    ciwspan   <span></span>
------------------------------------
```


## Setup
Neovim 0.5 with and nvim-treesitter to work

User treesitter setup
```lua
require'nvim-treesitter.configs'.setup {
  autotag = {
    enable = true,
  }
}

```
or you can use a set up function

``` lua
require('nvim-ts-autotag').setup()

```

## Default values

``` lua
local filetypes = {
  'html', 'javascript', 'javascriptreact', 'typescriptreact', 'svelte', 'vue'
}
local skip_tags = {
  'area', 'base', 'br', 'col', 'command', 'embed', 'hr', 'img', 'slot',
  'input', 'keygen', 'link', 'meta', 'param', 'source', 'track', 'wbr','menuitem'
}

```

### Override default values

``` lua

require'nvim-treesitter.configs'.setup {
  autotag = {
    enable = true,
    filetypes = { "html" , "xml" },
  }
}
-- OR
require('nvim-ts-autotag').setup({
  filetypes = { "html" , "xml" },
})

```
