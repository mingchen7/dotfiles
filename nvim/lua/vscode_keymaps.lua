-- VSCode extension
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
-- Copy to system clipboard
vim.keymap.set({ 'n', 'v' }, '<leader>y', '"+y', { desc = 'Copy to system clipboard' })

-- VSCode navigation
vim.keymap.set({ 'n', 'x' }, '<C-h>', function()
  require('vscode').action 'workbench.action.navigateLeft'
end, { silent = true, desc = 'Navigate left in VSCode (tabs)' })

vim.keymap.set({ 'n', 'x' }, '<C-l>', function()
  require('vscode').action 'workbench.action.navigateRight'
end, { silent = true, desc = 'Navigate right in VSCode (tabs)' })

-- VSCode actions
vim.keymap.set('n', '<leader>bb', function()
  require('vscode').action 'workbench.action.showAllEditorsByMostRecentlyUsed'
end, { desc = 'Show all editors by MRU' })

vim.keymap.set('n', '<leader>f', function()
  require('vscode').action 'workbench.action.quickOpen'
end, { desc = 'Quick Open (files)' })

vim.keymap.set({ 'n', 'x' }, '<leader>lg', function()
  -- VSCodeNotifyVisual takes a selection if applicable,
  -- so we can use .action() directly if we want to mimic it.
  -- For findInFiles, it's often more about the current word or selection.
  -- The '0' in your original suggests it might be acting on the current word or buffer.
  -- require('vscode').action('workbench.action.findInFiles') will open the search with the current word.
  require('vscode').action 'workbench.action.findInFiles'
end, { desc = 'Find in Files (VSCode)' })

vim.keymap.set({ 'n', 'x' }, 'gs', function()
  require('vscode').action 'workbench.action.gotoSymbol'
end, { desc = 'Go to Symbol (VSCode)' })

vim.keymap.set({ 'n', 'x' }, 'gh', function()
  require('vscode').action 'editor.action.referenceSearch.trigger'
end, { desc = 'Go to References (VSCode)' })

vim.keymap.set('n', 'K', function()
  require('vscode').action 'editor.action.showHover'
end, { desc = 'Show Definition (VSCode)' })

-- Function to get relative file path and copy to clipboard
local function copy_relative_path()
  -- Try to get the git root directory
  local git_root = vim.fn.systemlist('git rev-parse --show-toplevel')[1]
  -- If not in a git repo, use the current working directory
  local root_dir = git_root or vim.fn.getcwd()
  -- Get the full path of the current file
  local full_path = vim.fn.expand '%:p'
  -- Remove the root directory from the full path to get the relative path
  local relative_path = full_path:sub(#root_dir + 2) -- +2 to account for the trailing slash
  -- Get the root directory name
  local root_name = vim.fn.fnamemodify(root_dir, ':t')
  -- Combine the root name with the relative path
  local path_with_root = root_name .. '/' .. relative_path
  -- Copy to clipboard
  vim.fn.setreg('+', path_with_root)
  -- Notify user
  vim.notify('Copied: ' .. path_with_root, vim.log.levels.INFO)
end

local function copy_sourcegraph_path()
  local base_url = 'https://stripe.sourcegraphcloud.com/stripe-internal/'
  local git_root = vim.fn.systemlist('git rev-parse --show-toplevel')[1]
  -- If not in a git repo, use the current working directory
  local root_dir = git_root or vim.fn.getcwd()
  local root_name = vim.fn.fnamemodify(root_dir, ':t')
  local relative_path = vim.fn.fnamemodify(vim.fn.expand '%', ':.')
  local line_number = vim.api.nvim_win_get_cursor(0)[1]
  local sourcegraph_url = string.format('%s%s/-/blob/%s?L%d', base_url, root_name, relative_path, line_number)
  vim.fn.setreg('+', sourcegraph_url)
  vim.notify('Copied Sourcegraph URL: ' .. sourcegraph_url, vim.log.levels.INFO)
end

-- Set up the key binding
vim.keymap.set('n', '<leader>cp', copy_relative_path, { noremap = true, silent = true, desc = 'Copy relative file path' })
vim.keymap.set('n', '<leader>scp', copy_sourcegraph_path, { noremap = true, silent = true, desc = 'Copy relative file path' })
