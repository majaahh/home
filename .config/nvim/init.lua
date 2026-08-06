--
-- SPDX-FileCopyrightText: Majaahh
-- SPDX-License-Identifier: Apache-2.0
--

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("lazy").setup({
	spec = {
		{ "catppuccin/nvim", as = "catppuccin" },
		{ "folke/noice.nvim" },
		{ "hrsh7th/cmp-buffer" },
		{ "hrsh7th/cmp-nvim-lsp" },
		{ "hrsh7th/cmp-path" },
		{ "hrsh7th/nvim-cmp" },
		{ "L3MON4D3/LuaSnip", build = "make install_jsregexp" },
		{ "MDNSSKNGHT/smali.vim" },
		{ "mrloop/telescope-git-branch.nvim" },
		{ "MunifTanjim/nui.nvim" },
		{ "neovim/nvim-lspconfig" },
		{ "nvim-lualine/lualine.nvim" },
		{ "nvim-telescope/telescope.nvim" },
		{ "nvim-tree/nvim-tree.lua" },
		{ "nvim-tree/nvim-web-devicons" },
		{ "nvim-treesitter/nvim-treesitter" },
		{ "onsails/lspkind.nvim" },
		{ "OXY2DEV/markview.nvim" },
		{ "rafamadriz/friendly-snippets" },
		{ "rcarriga/nvim-notify" },
		{ "saadparwaiz1/cmp_luasnip" },
		{ "sbdchd/neoformat" },
		{ "tpope/vim-commentary" },
		{ "WhoIsSethDaniel/mason-tool-installer.nvim", build = ":MasonToolsInstall" },
		{ "williamboman/mason-lspconfig.nvim" },
		{ "williamboman/mason.nvim" },
		{ "windwp/nvim-autopairs" },
		{ "ya2s/nvim-cursorline" },
		{ "yuttie/comfortable-motion.vim" },
	},
	checker = { enabled = false },
})

local map = vim.keymap.set
local opts = { noremap = true, silent = true }
local des = function(desc)
	return { noremap = true, silent = true, desc = desc }
end

-- Treesitter
require("nvim-treesitter").setup()
require("nvim-treesitter").install({
	"markdown",
	"lua",
	"vim",
	"vimdoc",
	"bash",
	"python",
	"html",
	"javascript",
	"typescript",
	"zig",
})

-- Markview
require("markview").setup({
	experimental = {
		check_rtp_message = false,
	},
})

-- CMP
local cmp = require("cmp")
local luasnip = require("luasnip")

cmp.setup({
	snippet = {
		expand = function(args)
			luasnip.lsp_expand(args.body)
		end,
	},
	mapping = cmp.mapping.preset.insert({
		["<C-j>"] = cmp.mapping.select_next_item(),
		["<C-k>"] = cmp.mapping.select_prev_item(),
		["<C-d>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),
		["<C-Space>"] = cmp.mapping.complete(),
		["<C-e>"] = cmp.mapping.abort(),
		["<CR>"] = cmp.mapping.confirm({ select = true }),
		["<Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_next_item()
			elseif luasnip.expand_or_jumpable() then
				luasnip.expand_or_jump()
			else
				fallback()
			end
		end, { "i", "s" }),
		["<S-Tab>"] = cmp.mapping(function(fallback)
			if luasnip.jumpable(-1) then
				luasnip.jump(-1)
			else
				fallback()
			end
		end, { "i", "s" }),
	}),
	sources = cmp.config.sources({
		{ name = "luasnip" },
		{ name = "nvim_lsp" },
		{ name = "buffer" },
		{ name = "path" },
	}),
	window = {
		completion = cmp.config.window.bordered(),
		documentation = cmp.config.window.bordered(),
	},
})

-- Stylua
vim.g.neoformat_lua_stylua = {
	exe = "stylua",
	args = { "--search-parent-directories", "--stdin-filepath", "%:p", "-" },
	stdin = 1,
}
vim.g.neoformat_enabled_lua = { "stylua" }

-- LuaSnip
require("luasnip.loaders.from_vscode").lazy_load()

-- Mason
require("mason").setup()
require("mason-lspconfig").setup({
	ensure_installed = { "ts_ls", "html", "bashls", "zls", "ruff" },
	automatic_installation = true,
})
require("mason-tool-installer").setup({
	ensure_installed = {
		{ "bash-language-server" },
		{ "stylua" },
		{ "cmakelang" },
		{ "cmakelint" },
	},

	auto_update = false,
	integrations = {
		["mason-null-ls"] = false,
		["mason-nvim-dap"] = false,
	},
})

-- LSP
vim.lsp.config("html", {})
vim.lsp.config("bashls", {})
vim.lsp.config("zls", {})
vim.lsp.config("ruff", {
	settings = {
		ruff = {
			lint = {
				select = { "E", "F" },
			},
		},
	},
})

vim.lsp.enable({ "html", "bashls", "zls", "ruff" })

-- Auto Pairs
require("nvim-autopairs").setup({})

-- Telescope
require("telescope").setup({
	defaults = {
		mappings = {
			i = {
				["<C-j>"] = require("telescope.actions").move_selection_next,
				["<C-k>"] = require("telescope.actions").move_selection_previous,
			},
		},
	},
})

-- Noice
require("noice").setup({
	lsp = {
		progress = {
			enabled = true,
			format = "lsp_progress",
			format_done = "lsp_progress_done",
			throttle = 1000 / 30,
			view = "notify",
		},
	},
	presets = {
		command_palette = true,
		long_message_to_split = true,
		inc_rename = false,
		lsp_doc_border = false,
	},
})

-- LuaLine
require("lualine").setup({
	extensions = { "nvim-tree" },
	options = {
		icons_enabled = true,
	},
	sections = {
		lualine_a = { "mode" },
		lualine_b = { "branch", "diff", "diagnostics" },
		lualine_c = { "filename" },
		lualine_x = { "filetype" },
		lualine_y = { "progress" },
		lualine_z = { "location" },
	},
	inactive_sections = {
		lualine_a = {},
		lualine_b = {},
		lualine_c = { "filename" },
		lualine_x = { "location" },
		lualine_y = {},
		lualine_z = {},
	},
	sections = {
		lualine_c = { "filename" },
		lualine_x = { "filetype" },
	},
})

-- Catppuccin
require("catppuccin").setup({
	transparent_background = true,
	color_overrides = {
		all = {
			base = "#000000",
			mantle = "#000000",
			crust = "#000000",
		},
	},
})

-- Nvim Tree
require("nvim-tree").setup({
	sort = {
		sorter = "case_sensitive",
	},
	view = {
		width = 25,
	},
	renderer = {
		group_empty = true,
	},
	filters = {
		dotfiles = true,
	},
})

-- Cursorline
require("nvim-cursorline").setup({
	cursorline = {
		enable = true,
		timeout = 1000,
		number = false,
	},
	cursorword = {
		enable = true,
		min_length = 3,
		hl = { underline = true },
	},
})

-- Notify
require("notify").setup({
	background_colour = "#000000",
})

-- Formatting
map("n", "<Space>f", ":Neoformat<CR>", des("Format code"))

-- Telescope
map("n", "<Space>gb", ":Telescope git_branches<CR>", des("Git Branches"))
map("n", "<Space>gt", ":Telescope git_status<CR>", des("Git Status"))
map("n", "<Space>th", ":Telescope find_files<CR>", des("Find Files"))

-- Nvim Tree
map("n", "<C-n>", ":NvimTreeToggle<CR>", opts)
map("n", "<Space>e", function()
	vim.cmd("wincmd p")
end, opts)

vim.cmd.colorscheme("catppuccin")
vim.g.did_load_filetypes = 1
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.signcolumn = "yes"
vim.opt.relativenumber = false
vim.opt.number = true
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.clipboard = "unnamedplus"
vim.opt.fillchars = { eob = " " }
vim.g.mapleader = " "
vim.cmd.set("timeout timeoutlen=3000 ttimeoutlen=100")
vim.g.vimtex_view_method = "zathura"
vim.opt.wrap = true
vim.opt.whichwrap:append("<>[]hl")
vim.opt.ignorecase = true
vim.opt.smartcase = false
