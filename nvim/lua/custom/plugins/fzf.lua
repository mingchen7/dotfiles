return {
  'ibhagwan/fzf-lua',
  -- optional for icon support
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    -- [[ Configure fzf-lua ]]
    -- See `:help fzf-lua-customization`
    require('fzf-lua').setup {
      -- Note: fzf-lua uses 'fzf' as the default engine, so no need to
      -- specify it like with telescope-fzf-native.
      --
      -- fzf-lua uses a popup window by default. If you want a dropdown
      -- style similar to the telescope-ui-select theme, you can
      -- configure the window options globally:
      winopts = {
        -- height = 0.85,
        -- width = 0.8,
        -- row = 0.5,
        -- col = 0.5,
        -- border = { '┌', '─', '┐', '│', '┘', '─', '└', '│' },
      },

      -- Additional options for keybindings, etc. can go here
      -- For example, to change the default keybindings inside fzf
      keymap = {
        -- 'fzf' prompt mappings
        fzf = {
          ['ctrl-d'] = 'half-page-down',
          ['ctrl-u'] = 'half-page-up',
        },
        -- 'fzf-lua' preview window mappings
        preview = {
          ['ctrl-d'] = 'half-page-down',
          ['ctrl-u'] = 'half-page-up',
        },
      },
    }

    -- To replace vim.ui.select with fzf-lua
    -- This is the equivalent of the 'telescope-ui-select.nvim' extension
    vim.ui.select = function(...)
      require('fzf-lua').ui_select(...)
    end

    -- [[ Keymaps ]]
    -- See `:help fzf-lua-commands`
    local fzf = require 'fzf-lua'

    -- NOTE: All original keymaps are preserved.
    vim.keymap.set('n', '<leader>sh', fzf.help_tags, { desc = '[S]earch [H]elp' })
    vim.keymap.set('n', '<leader>sk', fzf.keymaps, { desc = '[S]earch [K]eymaps' })
    vim.keymap.set('n', '<leader>sf', fzf.files, { desc = '[S]earch [F]iles' })

    -- `telescope.builtin.builtin` shows a list of available pickers.
    -- The closest equivalent in fzf-lua is `commands`.
    vim.keymap.set('n', '<leader>ss', fzf.commands, { desc = '[S]earch [S]elect fzf-lua command' })
    vim.keymap.set('n', '<leader>sw', fzf.grep_cword, { desc = '[S]earch current [W]ord' })
    vim.keymap.set('n', '<leader>sW', fzf.grep_cWORD, { desc = '[S]earch current [W]ORD' })
    vim.keymap.set('n', '<leader>sg', fzf.live_grep, { desc = '[S]earch by [G]rep' })

    -- For diagnostics, fzf-lua splits them by scope. `diagnostics_workspace` is the
    -- equivalent of telescope's default `diagnostics` picker.
    vim.keymap.set('n', '<leader>sd', fzf.diagnostics_workspace, { desc = '[S]earch [D]iagnostics' })
    vim.keymap.set('n', '<leader>sr', fzf.resume, { desc = '[S]earch [R]esume' })
    vim.keymap.set('n', '<leader>s.', fzf.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
    vim.keymap.set('n', '<leader><leader>', fzf.buffers, { desc = '[ ] Find existing buffers' })

    -- This was `current_buffer_fuzzy_find` in Telescope. The equivalent is `blines`.
    vim.keymap.set('n', '<leader>/', function()
      fzf.blines {
        -- To mimic the dropdown theme, we can override winopts for this specific command.
        winopts = {
          height = 0.5,
          width = 0.6,
          preview = {
            hidden = 'hidden', -- Hide preview window for this picker, like original
          },
        },
      }
    end, { desc = '[/] Fuzzily search in current buffer' })

    -- This was live_grep in open files.
    vim.keymap.set('n', '<leader>s/', function()
      fzf.live_grep {
        grep_open_files = true,
        prompt = 'Live Grep in Open Files> ',
      }
    end, { desc = '[S]earch [/] in Open Files' })

    vim.keymap.set('n', '<leader>sG', function()
      require('fzf-lua').files {
        prompt = 'Grep in Directory> ',
        cmd = 'fd --type d --hidden --follow --strip-cwd-prefix --ignore-file=' .. vim.fn.expand '~' .. '/.fdignore',
        actions = {
          ['default'] = function(selected)
            -- `selected` is a table of the chosen entries. We only need the first one.
            local selected_dir = selected[1]
            if selected_dir == nil then
              return
            end
            require('fzf-lua').live_grep {
              search = '', -- Start with an empty search query
              cwd = selected_dir,
            }
          end,
        },
      }
    end, { desc = '[S]earch by [G]rep in selected directory' })

    -- Shortcut for searching your Neovim configuration files
    vim.keymap.set('n', '<leader>sn', function()
      fzf.files {
        prompt = 'Search Neovim Config files> ',
        -- Change the directory for this search
        cwd = vim.fn.stdpath 'config',
        -- Use the custom command from your original config for this specific picker
        cmd = 'rg --files --hidden -L --color never',
      }
    end, { desc = '[S]earch [N]eovim files' })
  end,
}
