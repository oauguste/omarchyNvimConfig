-- ~/.config/nvim/lua/plugins/astrolsp.lua
return {
  "AstroNvim/astrolsp",
  ---@type AstroLSPOpts
  opts = {
    config = {
      clangd = {
        capabilities = { offsetEncoding = "utf-8" },
      },

      lua_ls = {
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
          },
        },
      },

      tailwindcss = {
        -- optional: add settings here later if needed
      },

      astro = {
        -- optional: add settings here later if needed
      },
    },

    formatting = {
      -- keep Astro's format-on-save on, but you can tune it
      format_on_save = {
        enabled = true,
        ignore_filetypes = { "markdown" },
      },

      -- optional: if some LSP tries to format when you don't want it to
      -- disabled = { "tailwindcss" },
    },
  },
}
