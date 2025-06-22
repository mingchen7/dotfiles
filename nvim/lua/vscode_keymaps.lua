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

-- Standard Neovim scroll commands
vim.keymap.set('n', '<C-j>', '<C-d>', { desc = 'Scroll half page down' })
vim.keymap.set('n', '<C-k>', '<C-u>', { desc = 'Scroll half page up' })
