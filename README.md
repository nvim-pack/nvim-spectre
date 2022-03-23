# nvim-spectre

A search panel for neovim.

**Spectre** **find the enemy and replace them with dark power.**

![demo](https://github.com/windwp/nvim-spectre/wiki/assets/demospectre.gif)

## Why Spectre?

- Use regex in search
- It can filter the search by path glob (filetype)
- It only searches when you leave **Insert Mode**. You don't need a typeahead function.
  It always searches when you type and it is very useless to search with regex
- Use 1 buffer and you can edit or move
- A tool to replace text on the project

## Installation

```lua
Plug 'nvim-lua/plenary.nvim'
Plug 'windwp/nvim-spectre'

```

You need to install rg and sed.

- [BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep) (finder)
- [devicons](https://github.com/kyazdani42/nvim-web-devicons) (icons)
- [sed](https://www.gnu.org/software/sed/) (replace tool)

### MacOs

You need to run `brew install gnu-sed`.

## Usage

```vim
nnoremap <leader>S <cmd>lua require('spectre').open()<CR>

"search current word
nnoremap <leader>sw <cmd>lua require('spectre').open_visual({select_word=true})<CR>
vnoremap <leader>s <cmd>lua require('spectre').open_visual()<CR>
"  search in current file
nnoremap <leader>sp viw:lua require('spectre').open_file_search()<cr>
" run command :Spectre
```

**WARNING**

- Commit your file before you replace text. It does not support undo
- Don't use your crazy vim skill to edit result text or UI.
- You can use `dd` to toggle result item

## Regex Issue

- Default regex use vim regex **magic mode** `\v` and **no-ignore-case** .
- It might have a different regex convention between search command `rg` and replace command `sed` so careful if you want to replace text.
- It has a different highlight result because I use vim regex to
  highlight text so careful but you can try to replace it.

## Replace

You can replace with a group by `\0-9` like vim and sed
if you run command replace and don't see the change. you need to reload
file with `:e` because `sed` is replaced outside vim.

## Customize

```lua
require('spectre').setup()

```

Change any setting if you don't like it. **Don't copy all**.
It can be changed when plugin update so better uses a default setting.

```lua
require('spectre').setup({
  color_devicons = true,
  line_sep_start = '------------------------------------------',
  line_sep       = '------------------------------------------',
  open_cmd = 'vnew',
  live_update = false,
  highlight = {
      ui = "String",
      filename = "Keyword",
      filedirectory = "Comment",
      search = "DiffChange",
      border = "Comment",
      replace = "DiffDelete"
  },
  mapping = {
      ['toggle_line'] = {
          map = "dd",
          cmd = "<cmd>lua require('spectre').toggle_line()<CR>",
          desc = "delete current item"
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
      ['run_replace'] = {
          map = "<leader>R",
          cmd = "<cmd>lua require('spectre.actions').run_replace()<CR>",
          desc = "replace all"
      },
      -- only show replace text in result UI
      ['change_view_mode'] = {
          map = "<leader>v",
          cmd = "<cmd>lua require('spectre').change_view()<CR>",
          desc = "change result view mode"
      },
      ['toggle_live_update']={
          map = "tu",
          cmd = "<cmd>lua require('spectre').toggle_live_update()<CR>",
          desc = "update change when vim write file."
      },
      -- only work if the find_engine following have that option
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
      ['toggle_string_search'] = {
        map = "ts",
        cmd = "<cmd>lua require('spectre').change_options('string')<CR>",
        desc = "toggle string search mode",
      },
  },
  find_engine = {
      ['rg'] = {
          cmd = "rg",
          -- default args
          args = {
              '--color=never',
              '--no-heading',
              '--with-filename',
              '--line-number',
              '--column',
          },
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
              ['string'] = {
                  value = "--fixed-strings",
                  desc = "fixed string mode",
                  icon = "[S]"
              },
              -- you can put any option you want here it can toggle with
              -- show_option function
          }
      },
      ['ag'] = {
          cmd = "ag",
          -- default args
          args = {
              '--vimgrep',
              '-s'
          },
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
          args = {
              '-i',
              '-E',
          },
          options = {
              ['ignore-case'] = {
                      value= "--ignore-case",
                      icon="[I]",
                      desc="ignore case"
              },
              ['string'] = {
                      value = "--string-mode",
                      desc = "fixed string mode",
                      icon = "[S]"
              },
          }
      },
  },
  default = {
      find = {
          cmd = "rg",
          options = {"ignore-case"}
      },
      replace={
          cmd = "sed"
      }
  },
  replace_vim_cmd = "cdo",
  is_open_target_win = true,
  is_insert_mode = false,
})

```

### Custom function

```lua
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
  path="lua/**/*.lua"
})

```

## FAQ

- Add custom statusline [windline](https://github.com/windwp/windline.nvim)

```lua
require('windline').add_status(
    require('spectre.state_utils').status_line()
)
```

- What is Spectre?

> I want to create a `Search Panel` but this name is not cool.
> I get the name of a hero on a game.
> Spectre has the skill to find the enemy on the global map so I use it:)
