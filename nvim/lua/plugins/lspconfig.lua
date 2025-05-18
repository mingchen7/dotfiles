return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      ruff = {
        settings = {
          init_options = {
            configuration = "~/stripe/zoolander/pyproject.toml",
            configurationPreference = "filesystemFirst",
          },
        },
      },
    },
  },
}
