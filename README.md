# nvim-spectre

A search panel for neovim.

**Spectre** **find the enemy and replace them with dark power.**

![demo](https://github.com/windwp/nvim-spectre/wiki/assets/demospectre.gif)

## Why Use Spectre?

- Use regex in search
- It can filter search by path glob (filetype)
- It only searches when you leave **Insert Mode**, `incsearch` can be annoying when writing regex
- Use one buffer and you can edit or move
- A tool to replace text on project

## Installation

```lua
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-pack/nvim-spectre'
```

You may also need to install the following:

- [BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep) (finder)
- [devicons](https://github.com/kyazdani42/nvim-web-devicons) (icons)
- [sed](https://www.gnu.org/software/sed/) (replace tool)

### MacOs

You may need run `brew install gnu-sed`.

## Usage

```lua
vim.keymap.set('n', '<leader>S', '<cmd>lua require("spectre").toggle()<CR>', {
    desc = "Toggle Spectre"
})
vim.keymap.set('n', '<leader>sw', '<cmd>lua require("spectre").open_visual({select_word=true})<CR>', {
    desc = "Search current word"
})
vim.keymap.set('v', '<leader>sw', '<esc><cmd>lua require("spectre").open_visual()<CR>', {
    desc = "Search current word"
})
vim.keymap.set('n', '<leader>sp', '<cmd>lua require("spectre").open_file_search({select_word=true})<CR>', {
    desc = "Search on current file"
})
```

Use command: `:Spectre`

## Warnings

- Always commit your files before you replace text. `nvim-spectre`
  does not support undo directly.
- Don't use your crazy vim skills to edit result text or UI or you may
  encounter strange behaviour.
- You can use `dd` to toggle result items.
- You need to use `<Esc>` not `<C-c>` to leave insert mode.

## Regex Issues

- The default regex uses vim's **magic mode** `\v` and **no-ignore-case**.
- It has different regex sytax compared to the `rg` command and
  replace command `sed` so be careful when replacing text.
- It has a different highlighting result because I use vim regex to
  highlight text so be careful but you can try to replace.

## Replace

You can replace groups with `\0-9` similar to vim and sed, if you run
a replace command and don't see the change you may need to reload file
with `:e` because `sed` is replace outside vim.

## Customization

```lua
require('spectre').setup()
```

Change any settings if you don't like them. **Don't just copy all** as
settings may change as the plugin is updated so it may be better use
the default settings.

```lua
require('spectre').setup({

  color_devicons = true,
  open_cmd = 'vnew',
  live_update = false, -- auto execute search again when you write to any file in vim
  line_sep_start = '┌-----------------------------------------',
  result_padding = '¦  ',
  line_sep       = '└-----------------------------------------',
  highlight = {
      ui = "String",
      search = "DiffChange",
      replace = "DiffDelete"
  },
  mapping={
    ['toggle_line'] = {
        map = "dd",
        cmd = "<cmd>lua require('spectre').toggle_line()<CR>",
        desc = "toggle item"
    },
    ['enter_file'] = {
        map = "<cr>",
        cmd = "<cmd>lua require('spectre.actions').select_entry()<CR>",
        desc = "open file"
    },
    ['send_to_qf'] = {
        map = "<leader>q",
        cmd = "<cmd>lua require('spectre.actions').send_to_qf()<CR>",
        desc = "send all items to quickfix"
    },
    ['replace_cmd'] = {
        map = "<leader>c",
        cmd = "<cmd>lua require('spectre.actions').replace_cmd()<CR>",
        desc = "input replace command"
    },
    ['show_option_menu'] = {
        map = "<leader>o",
        cmd = "<cmd>lua require('spectre').show_options()<CR>",
        desc = "show options"
    },
    ['run_current_replace'] = {
      map = "<leader>rc",
      cmd = "<cmd>lua require('spectre.actions').run_current_replace()<CR>",
      desc = "replace current line"
    },
    ['run_replace'] = {
        map = "<leader>R",
        cmd = "<cmd>lua require('spectre.actions').run_replace()<CR>",
        desc = "replace all"
    },
    ['change_view_mode'] = {
        map = "<leader>v",
        cmd = "<cmd>lua require('spectre').change_view()<CR>",
        desc = "change result view mode"
    },
    ['change_replace_sed'] = {
      map = "trs",
      cmd = "<cmd>lua require('spectre').change_engine_replace('sed')<CR>",
      desc = "use sed to replace"
    },
    ['change_replace_oxi'] = {
      map = "tro",
      cmd = "<cmd>lua require('spectre').change_engine_replace('oxi')<CR>",
      desc = "use oxi to replace"
    },
    ['toggle_live_update']={
      map = "tu",
      cmd = "<cmd>lua require('spectre').toggle_live_update()<CR>",
      desc = "update when vim writes to file"
    },
    ['toggle_ignore_case'] = {
      map = "ti",
      cmd = "<cmd>lua require('spectre').change_options('ignore-case')<CR>",
      desc = "toggle ignore case"
    },
    ['toggle_ignore_hidden'] = {
      map = "th",
      cmd = "<cmd>lua require('spectre').change_options('hidden')<CR>",
      desc = "toggle search hidden"
    },
    ['resume_last_search'] = {
      map = "<leader>l",
      cmd = "<cmd>lua require('spectre').resume_last_search()<CR>",
      desc = "repeat last search"
    },
    ['jump_to_search'] = {
        map = "<F1>",
        cmd = "<cmd>lua require('spectre').search({type:'search'})<CR>",
        desc = "jump to search line and exec callback"
    },
    ['jump_to_replace'] = {
        map = "<F2>",
        cmd = "<cmd>lua require('spectre').search({type:'replace'})<CR>",
        desc = "jump to replace line and exec callback"
    },
    ['jump_to_path'] = {
        map = "<F3>",
        cmd = "<cmd>lua require('spectre').search({type:'path'})<CR>",
        desc = "jump to path line and exec callback"
    },
    -- you can put your mapping here it only use normal mode
  },
  find_engine = {
    -- rg is map with finder_cmd
    ['rg'] = {
      cmd = "rg",
      -- default args
      args = {
        '--color=never',
        '--no-heading',
        '--with-filename',
        '--line-number',
        '--column',
      } ,
      options = {
        ['ignore-case'] = {
          value= "--ignore-case",
          icon="[I]",
          desc="ignore case"
        },
        ['hidden'] = {
          value="--hidden",
          desc="hidden file",
          icon="[H]"
        },
        -- you can put any rg search option you want here it can toggle with
        -- show_option function
      }
    },
    ['ag'] = {
      cmd = "ag",
      args = {
        '--vimgrep',
        '-s'
      } ,
      options = {
        ['ignore-case'] = {
          value= "-i",
          icon="[I]",
          desc="ignore case"
        },
        ['hidden'] = {
          value="--hidden",
          desc="hidden file",
          icon="[H]"
        },
      },
    },
  },
  replace_engine={
      ['sed']={
          cmd = "sed",
          args = nil,
          options = {
            ['ignore-case'] = {
              value= "--ignore-case",
              icon="[I]",
              desc="ignore case"
            },
          }
      },
      -- call rust code by nvim-oxi to replace
      ['oxi'] = {
        cmd = 'oxi',
        args = {},
        options = {
          ['ignore-case'] = {
            value = "i",
            icon = "[I]",
            desc = "ignore case"
          },
        }
      }
  },
  default = {
      find = {
          --pick one of item in find_engine
          cmd = "rg",
          options = {"ignore-case"}
      },
      replace={
          --pick one of item in replace_engine
          cmd = "sed"
      }
  },
  replace_vim_cmd = "cdo",
  is_open_target_win = true, --open file on opener window
  is_insert_mode = false  -- start open panel on is_insert_mode,
  jump_callback = {
      search = function()
          vim.api.nvim_feedkeys('cc', 'n', true)
          end,
      replace = function()
          vim.api.nvim_feedkeys('cc', 'n', true)
          end,
      path = function()
          vim.api.nvim_feedkeys('cc', 'n', true)
          end
  }
})

```

### Custom Functions

```lua
-- if you want to get items from spectre panel you can use some of the
-- following functions to get data from spectre.
require('spectre.actions').get_current_entry()
require('spectre.actions').get_all_entries()
require('spectre.actions').get_state()

-- write your custom open function
require('spectre').open({
  is_insert_mode = true,
  cwd = "~/.config/nvim",
  search_text="test",
  replace_text="test",
  path="lua/**/*.lua",
  is_close = false, -- close an exists instance of spectre and open new
})
-- you can use all variables above on command line
-- for example: Spectre % is_insert_mode=true cwd=~/.config/nvim
-- in this example `%` will expand to current file.

```

## Replace Method

There are two replace methods `sed` and `oxi`.

| Sed                        | oxi                                 |
| -------------------------- | ----------------------------------- |
| group number by '\0'       | group number by '${0}'              |
| use vim to highlight on UI | use rust to highlight on UI         |
| use sed to replace         | use rust to replace                 |
| run sed command            | call rust code directly by nvim-oxi |

Install `oxi`:

- you will need to install `cargo` and run the command:
  [build.sh](./build.sh)
  [nvim-oxi](https://github.com/noib3/nvim-oxi)

- set default replace command to `"oxi"` on `setup()`

```lua
require('spectre').setup({
    default = {
        replace = {
            cmd = "oxi"
       }
    }
  )
```

## Sponsors

Thanks to everyone who sponsors my projects and makes continued development and maintenance possible!

<!-- patreon --><a href="https://github.com/t4t5"><img src="https://github.com/t4t5.png" width="60px" alt="" /></a><!-- patreon-->

## FAQ

- How can I add a custom status line? [windline](https://github.com/windwp/windline.nvim)

```lua
    require('windline').add_status(
        require('spectre.state_utils').status_line()
    )
```

- What if I have remapped keys in my neovim config?

> [Spectre hardcodes some mappings in order to work correctly](https://github.com/nvim-pack/nvim-spectre/blob/1abe23ec9b7bc3082164f4cb842d521ef70e080e/lua/spectre/init.lua#L175). You can remap them as described above. You are allowed to create as many mappings as you want. For name and description choose any value. 'map' and 'cmd' are the only important fields.

- Is spectre compatible with the plugin mini.animate?

> Yes, but only if you set `opts = { open = { enable = false } }` on `mini.animate`, otherwise it will cause serious issues preventing spectre from opening/closing.

- Why is it called Spectre?

> I wanted to call it `Search Panel` but this name is not cool.

> I got the name of a hero on a game.

> Spectre has a skill to find enemy on global map so I use it:)
