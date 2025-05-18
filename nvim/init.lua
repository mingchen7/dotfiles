-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
vim.o.termguicolors = true
vim.o.autoread = true

-- Function to get relative file path and copy to clipboard
local function copy_relative_path()
  -- Try to get the git root directory
  local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
  -- If not in a git repo, use the current working directory
  local root_dir = git_root or vim.fn.getcwd()
  -- Get the full path of the current file
  local full_path = vim.fn.expand("%:p")
  -- Remove the root directory from the full path to get the relative path
  local relative_path = full_path:sub(#root_dir + 2) -- +2 to account for the trailing slash
  -- Get the root directory name
  local root_name = vim.fn.fnamemodify(root_dir, ":t")
  -- Combine the root name with the relative path
  local path_with_root = root_name .. "/" .. relative_path
  -- Copy to clipboard
  vim.fn.setreg("+", path_with_root)
  -- Notify user
  vim.notify("Copied: " .. path_with_root, vim.log.levels.INFO)
end

local function copy_sourcegraph_path()
  local base_url = "https://stripe.sourcegraphcloud.com/stripe-internal/"
  local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
  -- If not in a git repo, use the current working directory
  local root_dir = git_root or vim.fn.getcwd()
  local root_name = vim.fn.fnamemodify(root_dir, ":t")
  local relative_path = vim.fn.fnamemodify(vim.fn.expand("%"), ":.")
  local line_number = vim.api.nvim_win_get_cursor(0)[1]
  local sourcegraph_url = string.format("%s%s/-/blob/%s?L%d", base_url, root_name, relative_path, line_number)
  vim.fn.setreg("+", sourcegraph_url)
  vim.notify("Copied Sourcegraph URL: " .. sourcegraph_url, vim.log.levels.INFO)
end

-- Set up the key binding
vim.keymap.set(
  "n",
  "<leader>cp",
  copy_relative_path,
  { noremap = true, silent = true, desc = "Copy relative file path" }
)

vim.keymap.set(
  "n",
  "<leader>scp",
  copy_sourcegraph_path,
  { noremap = true, silent = true, desc = "Copy relative file path" }
)
