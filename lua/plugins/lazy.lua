-- Install lazy
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({

  -- Color scheme
  { "catppuccin/nvim", name = "catppuccin" },

  -- Fuzzy Finder (files, lsp, etc)
  { "nvim-telescope/telescope.nvim", branch = "0.1.x", dependencies = { "nvim-lua/plenary.nvim" } },

  -- File tree
  {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("nvim-tree").setup({})
    end,
  },

  -- Save and load buffers (a session) automatically for each folder
  {
    "rmagatti/auto-session",
    config = function()
      require("auto-session").setup({
        log_level = "error",
        auto_session_suppress_dirs = { "~/", "~/Downloads" },
      })
    end,
  },

  -- Comment code
  {
    "terrortylor/nvim-comment",
    config = function()
      require("nvim_comment").setup({ create_mappings = false })
    end,
  },

  -- Visualize buffers as tabs
  { "akinsho/bufferline.nvim", version = "*", dependencies = "nvim-tree/nvim-web-devicons" },

  -- Mason (LSP/DAP/Linters manager)
  {
    "williamboman/mason.nvim",
    lazy = false,
    opts = {},
  },

  -- ToggleTerm
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      require("toggleterm").setup({
        size = 20,
        open_mapping = [[<c-\>]], -- press Ctrl+\ to toggle terminal
        shade_terminals = true,
      })
    end,
  },

  -- Autocompletion
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        sources = {
          { name = "nvim_lsp" },
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-u>"] = cmp.mapping.scroll_docs(-4),
          ["<C-d>"] = cmp.mapping.scroll_docs(4),
          -- Uncomment if you want Enter to confirm:
          -- ["<CR>"] = cmp.mapping.confirm({ select = true }),
        }),
        snippet = {
          expand = function(args)
            vim.snippet.expand(args.body)
          end,
        },
      })
    end,
  },

  -- LSP
  {
    "neovim/nvim-lspconfig",
    cmd = { "LspInfo", "LspInstall", "LspStart" },
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    init = function()
      -- Reserve a space in the gutter (avoids annoying layout shifts)
      vim.opt.signcolumn = "yes"
    end,
    config = function()
      local lsp_defaults = require("lspconfig").util.default_config

      -- Add cmp_nvim_lsp capabilities settings to lspconfig
      lsp_defaults.capabilities = vim.tbl_deep_extend(
        "force",
        lsp_defaults.capabilities,
        require("cmp_nvim_lsp").default_capabilities()
      )

      -- Keymaps that are only active when an LSP is attached
      vim.api.nvim_create_autocmd("LspAttach", {
        desc = "LSP actions",
        callback = function(event)
          local opts = { buffer = event.buf }
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
          vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
          vim.keymap.set("n", "go", vim.lsp.buf.type_definition, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          vim.keymap.set("n", "gs", vim.lsp.buf.signature_help, opts)
          vim.keymap.set("n", "<F2>", vim.lsp.buf.rename, opts)
          vim.keymap.set({ "n", "x" }, "<F3>", function() vim.lsp.buf.format({ async = true }) end, opts)
          vim.keymap.set("n", "<F4>", vim.lsp.buf.code_action, opts)
        end,
      })

      -- Mason-lspconfig + Pyright config
      require("mason-lspconfig").setup({
        ensure_installed = { "pyright" },
        handlers = {
          -- default handler
          function(server)
            require("lspconfig")[server].setup({})
          end,
          -- custom pyright
          ["pyright"] = function()
            require("lspconfig").pyright.setup({
              settings = {
                python = {
                  pythonPath = "/usr/bin/python3", -- system Python
                  analysis = {
                    typeCheckingMode = "basic", -- "off" | "basic" | "strict"
                    diagnosticMode = "openFilesOnly",
                    autoSearchPaths = true,
                    useLibraryCodeForTypes = true,
                  },
                },
              },
            })
          end,
        },
      })
    end,
  },

})