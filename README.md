# nvim-spectre
A search panel for neovim.

**Spectre** __find the enemy and replace them with dark power.__

![demo](https://github.com/windwp/nvim-spectre/wiki/assets/demospectre.gif)

## Why Spectre?
* Use regex in search
* It can filter search by path glob (filetype)
* It only search when you leave **Insert Mode**. You don't need a typeahead function .
It always search when you type and it is very useless on search with regex
* Use 1 buffer and you can edit or move
* A tool to replace text on project

## Installation

``` lua
Plug 'nvim-lua/plenary.nvim'
Plug 'windwp/nvim-spectre'

```
You need install rg and sed

- [BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep) (finder)
- [devicons](https://github.com/kyazdani42/nvim-web-devicons) (icons)
- [sed](https://www.gnu.org/software/sed/) (replace tool)

### MacOs
  you need run `brew install gnu-sed`

## Usage

``` vim
nnoremap <leader>S <cmd>lua require('spectre').open()<CR>

"search current word
nnoremap <leader>sw <cmd>lua require('spectre').open_visual({select_word=true})<CR>
vnoremap <leader>s <esc>:lua require('spectre').open_visual()<CR>
"  search in current file
nnoremap <leader>sp viw:lua require('spectre').open_file_search()<cr>
" run command :Spectre
```

**WARNING**
* Commit your file before you replace text. It does not support undo
* Don't use your crazy vim skill to edit result text or UI.
* You can use `dd` to toggle result item
* You need to use `<esc>` not `<c-c>` to leave insert mode.


## Regex Issue
* default regex use vim regex **magic mode** `\v` and **no-ignore-case** .
* It has different regex of search command `rg` and replace command
`sed` so careful if you want to replace text.
* It has a different of highlight result because I use vim regex to
highlight text so careful but you can try to replace.

## Replace

you can replace with group by `\0-9` like vim and sed
if you run command replace and don't see the change. you need to reload
file with `:e` because `sed` is replace outside vim.

## Customize
``` lua
require('spectre').setup()

```

Change any setting if you don't like it. **Don't copy all** .
It can be change when plugin update so better use a default setting.

``` lua
require('spectre').setup({

  color_devicons = true,
  open_cmd = 'vnew',
  live_update = false, -- auto excute search again when you write any file in vim
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
        desc = "toggle current item"
    },
    ['enter_file'] = {
        map = "<cr>",
        cmd = "<cmd>lua require('spectre.actions').select_entry()<CR>",
        desc = "goto current file"
    },
    ['send_to_qf'] = {
        map = "<leader>q",
        cmd = "<cmd>lua require('spectre.actions').send_to_qf()<CR>",
        desc = "send all item to quickfix"
    },
    ['replace_cmd'] = {
        map = "<leader>c",
        cmd = "<cmd>lua require('spectre.actions').replace_cmd()<CR>",
        desc = "input replace vim command"
    },
    ['show_option_menu'] = {
        map = "<leader>o",
        cmd = "<cmd>lua require('spectre').show_options()<CR>",
        desc = "show option"
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
      map = "th",
      cmd = "<cmd>lua require('spectre').change_engine_replace('sed')<CR>",
      desc = "use sed to replace"
    },
    ['change_replace_oxi'] = {
      map = "th",
      cmd = "<cmd>lua require('spectre').change_engine_replace('oxi')<CR>",
      desc = "use oxi to replace"
    },
    ['toggle_live_update']={
      map = "tu",
      cmd = "<cmd>lua require('spectre').toggle_live_update()<CR>",
      desc = "update change when vim write file."
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
  is_insert_mode = false  -- start open panel on is_insert_mode
})

```
### Custom function

``` lua
-- if you want to get item from spectre panel.
-- you can use some following function to get data from spectre.
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
  is_close = false, --  close an exists instance of spectre and open new
})

```
## Replace Method

There are 2 replace method sed and oxi.

| Sed                        | oxi                                 |
|----------------------------|-------------------------------------|
| group number by '\0'       | group number by '$0'                |
| use vim to highlight on UI | use rust to highlight on UI         |
| use sed to replace         | use rust to replace                 |
| run sed command            | call rust code directly by nvim-oxi |

Install oxi: 
- you need install cargo and run command:
[build.sh](./build.sh)
- set default replace command to "oxi" on setup()


## FAQ

* add custom statusline [windline](https://github.com/windwp/windline.nvim)

``` lua
    require('windline').add_status(
        require('spectre.state_utils').status_line()
    )
```

* what is Spectre?

> I want create a `Search Panel` but this name is not cool.
> I get the name of a hero on a game.
> Spectre has a skill to find enemy on global map so I use it:)
