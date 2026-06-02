-- adds ShowRubyDeps command to show dependencies in the quickfix list.
-- add the `all` argument to show indirect dependencies as well
local function add_ruby_deps_command(client, bufnr)
  vim.api.nvim_buf_create_user_command(bufnr, "ShowRubyDeps", function(opts)
    local params = vim.lsp.util.make_text_document_params()
    local showAll = opts.args == "all"

    client.request("rubyLsp/workspace/dependencies", params, function(err, result)
      if err then
        -- err can be a string or a table depending on the client
        local msg = type(err) == "string" and err or vim.inspect(err)
        vim.notify("Error showing deps: " .. msg, vim.log.levels.ERROR)
        return
      end

      local qf_list = {}
      for _, item in ipairs(result or {}) do
        if showAll or item.dependency then
          table.insert(qf_list, {
            text = string.format("%s (%s) - %s", item.name, item.version, item.dependency),
            filename = item.path,
          })
        end
      end

      vim.fn.setqflist(qf_list)
      vim.cmd("copen")
    end, bufnr)
  end, {
    nargs = "?",
    complete = function()
      return { "all" }
    end,
  })
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "ruby" })
    end,
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- NOTE: lspconfig server name is ruby_lsp (Mason package: ruby-lsp)
        ruby_lsp = {
          mason = true,
          on_attach = function(client, buffer)
            add_ruby_deps_command(client, buffer)
          end,
        },

        solargraph = {
          mason = true,
          -- These fields are not standard lspconfig options; keep them only if your distro/plugin consumes them.
          autoformat = false,
          diagnostic = false,
        },
      },
    },
  },

  {
    "nvim-neotest/neotest",
    dependencies = {
      "olimorris/neotest-rspec",
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("neotest").setup({
        adapters = {
          require("neotest-rspec"),
        },
      })
    end,
  },

  {
    "folke/which-key.nvim",
    optional = true,
    opts = function(_, opts)
      -- which-key "new spec" (replaces opts.defaults group style)
      opts.spec = opts.spec or {}
      vim.list_extend(opts.spec, {
        { "<leader>r", group = "Ruby on Rails" },
        { "<leader>t", group = "Tests" },
      })
      return opts
    end,
  },

  {
    "weizheheng/ror.nvim",
    keys = {
      { "<leader>rc", ":lua require('ror.commands').list_commands()<CR>", desc = "Commands" },
      { "<leader>rf", ":lua require('ror.finders').select_finders()<CR>", desc = "Finders" },
      { "<leader>rr", ":lua require('ror.routes').list_routes()<CR>", desc = "List routes" },
      { "<leader>rs", ":lua require('ror.routes').sync_routes()<CR>", desc = "Sync routes" },
      { "<leader>rt", ":lua require('ror.schema').list_table_columns()<CR>", desc = "Show table columns" },
    },
  },
}
