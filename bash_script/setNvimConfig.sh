mkdir -p "$HOME/.config/nvim"
cat > "$HOME/.config/nvim/init.lua" <<-'EOF'
-- ============================================
-- 基础设置
-- ============================================

-- 设置 <Space> 为 Leader 键
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- 显示行号（绝对 + 相对）
vim.opt.number = true
vim.opt.relativenumber = true

-- 高亮当前光标所在行
vim.opt.cursorline = true
vim.opt.showtabline = 2

-- 启用 24 位真彩色
vim.opt.termguicolors = true

-- 是否显示当前模式
vim.opt.showmode = true

-- 左侧符号列
vim.opt.signcolumn = "yes"

-- 命令栏高度
vim.opt.cmdheight = 1

-- 滚动时保留的最小行数
vim.opt.scrolloff = 10

-- 自动换行
vim.opt.wrap = true

-- Tab / 缩进设置
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.autoindent = true

-- 搜索行为
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true

-- 启用鼠标
vim.opt.mouse = "a"

-- 使用系统剪贴板
vim.opt.clipboard = "unnamedplus"

-- 更快刷新
vim.opt.updatetime = 300
vim.opt.timeoutlen = 700

-- 不生成备份和交换文件
vim.opt.backup = false
vim.opt.swapfile = false

-- 编码
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"

-- 关闭烦人的铃声
vim.opt.errorbells = false
vim.opt.visualbell = false

-- 精简启动信息
vim.opt.shortmess:append("sI")

-- 性能优化
vim.opt.lazyredraw = true

-- 显示不可见字符
vim.opt.list = true
vim.opt.listchars = {
	tab = "→ ",
	space = "·",
	lead = "·",
	multispace = "···",
	trail = "•",
	eol = "↵",
	nbsp = "␣",
	extends = "›",
	precedes = "‹",
}

-- Treesitter 折叠
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldenable = true
vim.opt.foldlevel = 99
vim.opt.foldcolumn = "1"

-- Undo 文件目录
local undodir = vim.fn.stdpath("data") .. "/undo"
if vim.fn.isdirectory(undodir) == 0 then
	vim.fn.mkdir(undodir, "p")
end
vim.opt.undodir = undodir
vim.opt.undofile = true

-- ============================================
-- 自动命令
-- ============================================

vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*",
	command = "%s/\\s\\+$//e",
})

vim.api.nvim_create_autocmd("TermClose", {
	pattern = "*",
	command = "bdelete! %",
})

-- ============================================
-- Lazy 插件管理
-- ============================================

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local proxyUrl = "https://gh-proxy.org/"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = proxyUrl .. "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"--branch=stable",
		lazyrepo,
		lazypath,
	})
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

-- ============================================
-- 插件配置（无内部快捷键）
-- ============================================

require("lazy").setup({
	git = {
		url_format = proxyUrl .. "https://github.com/%s.git",
	},
	spec = {
		-- ---------- Tokyonight ----------
		{
			"folke/tokyonight.nvim",
			lazy = false,
			priority = 1000,
			config = function()
				vim.cmd.colorscheme("tokyonight-night")
			end,
		},

		-- 颜色预览
		{
			"catgoose/nvim-colorizer.lua",
			event = "BufReadPre",
			opts = {
				filetypes = { "*" },
				user_default_options = {
					mode = "background",
					hex = true,
					AARRGGBB = true,
					names = true,
					rgb_fn = false,
					hsl_fn = false,
				},
			},
		},

		-- LSP
		{
			"neovim/nvim-lspconfig",
			config = function()
				vim.lsp.config("lua_ls", {
					cmd = { "lua-language-server" },
					settings = {
						Lua = {
							runtime = { version = "LuaJIT" },
							diagnostics = { globals = { "vim" } },
							workspace = {
								library = vim.api.nvim_get_runtime_file("", true),
								checkThirdParty = false,
							},
							telemetry = { enable = false },
						},
					},
				})
				vim.lsp.enable("lua_ls")
			end,
		},

		-- 自动补全
		{
			"hrsh7th/nvim-cmp",
			dependencies = {
				"hrsh7th/cmp-nvim-lsp",
				"hrsh7th/cmp-buffer",
				"hrsh7th/cmp-path",
			},
			config = function()
				local cmp = require("cmp")
				cmp.setup({
					sources = {
						{ name = "nvim_lsp" },
						{ name = "buffer" },
						{ name = "path" },
					},
					mapping = cmp.mapping.preset.insert({
						["<Tab>"] = cmp.mapping.select_next_item(),
						["<S-Tab>"] = cmp.mapping.select_prev_item(),
						["<CR>"] = cmp.mapping.confirm({ select = true }),
					}),
				})
			end,
		},

		-- 翻译
		{
			"voldikss/vim-translator",
			cmd = { "TranslateW", "Translate", "TranslateR" },
			config = function()
				vim.g.translator_target_lang = "zh"
				vim.g.translator_source_lang = "auto"
				vim.g.translator_default_engines = { "bing" }
				vim.g.translator_window_type = "popup"
			end,
		},

		-- 格式化
		{
			"stevearc/conform.nvim",
			event = { "BufReadPre", "BufNewFile" },
			config = function()
				require("conform").setup({
					formatters_by_ft = {
						lua = { "stylua" },
						sh = { "shfmt" },
					},
					format_on_save = false,
				})
			end,
		},

		-- 缩进线
		{
			"lukas-reineke/indent-blankline.nvim",
			main = "ibl",
			config = function()
				local highlight = {
					"RainbowRed",
					"RainbowYellow",
					"RainbowBlue",
					"RainbowOrange",
					"RainbowGreen",
					"RainbowViolet",
					"RainbowCyan",
				}

				local hooks = require("ibl.hooks")
				hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
					vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
					vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
					vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
					vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
					vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
					vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
					vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })
				end)

				require("ibl").setup({
					indent = { char = "┃", highlight = highlight },
					scope = { enabled = true, show_start = true, show_end = false },
					exclude = { filetypes = { "help", "lazy", "mason", "toggleterm" } },
				})
			end,
		},

		-- 文件树
		{
			"nvim-tree/nvim-tree.lua",
			version = "*",
			lazy = false,
			dependencies = { "nvim-tree/nvim-web-devicons" },
			config = function()
				require("nvim-tree").setup({
					view = {
						width = 30,
						side = "left",
						number = true,
						relativenumber = true,
					},
					filters = { dotfiles = false },
				})
			end,
		},

		-- Treesitter
		{
			"nvim-treesitter/nvim-treesitter",
			lazy = false,
			build = ":TSUpdate",
			config = function()
				require("nvim-treesitter").install({ "lua", "bash" })
			end,
		},

		-- Treesitter Textobjects
		{
			"nvim-treesitter/nvim-treesitter-textobjects",
			branch = "main",
		},

	},

	install = { colorscheme = { "tokyonight-night" } },
	checker = { enabled = true },
})

-- ============================================
-- 全局快捷键映射（所有快捷键统一在此处）
-- ============================================

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- ---------- 基础操作 ----------
map("n", "<Leader>w", ":w<CR>", opts)
map("n", "<Leader>q", ":q!<CR>", opts)
map("n", "<Esc>", ":nohlsearch<CR>", opts)
map("n", "H", "^", opts)
map("n", "L", "$", opts)
map("v", "J", ":m '>+1<CR>gv=gv", opts)
map("v", "K", ":m '<-2<CR>gv=gv", opts)

-- ---------- 文件树 ----------
local nvim_tree_api = require("nvim-tree.api")
map("n", "<Leader>e", nvim_tree_api.tree.toggle, opts)
map("n", "<Leader>t", nvim_tree_api.tree.focus, opts)
map("n", "<Leader>o", nvim_tree_api.tree.find_file, opts)

-- ---------- 格式化 ----------
map({ "n", "v" }, "<leader>f", function()
	require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "Format buffer" })

-- ---------- 翻译 ----------
map({ "n", "v" }, "<leader>tt", ":TranslateW<CR>", { desc = "翻译光标词/选中(弹窗)" })

-- ---------- 代码导航 ----------
map("n", "gd", vim.lsp.buf.definition, opts)
map("n", "gD", vim.lsp.buf.declaration, opts)
map("n", "gi", vim.lsp.buf.implementation, opts)
map("n", "gt", vim.lsp.buf.type_definition, opts)
map("n", "gr", vim.lsp.buf.references, opts)

-- ---------- 信息提示 ----------
map("n", "K", vim.lsp.buf.hover, opts)
map("n", "<C-k>", vim.lsp.buf.signature_help, opts)

-- ---------- 符号列表 ----------
map("n", "<leader>ds", vim.lsp.buf.document_symbol, opts)
map("n", "<leader>ws", vim.lsp.buf.workspace_symbol, opts)

-- ---------- 编辑与重构 ----------
map("n", "<leader>rn", vim.lsp.buf.rename, opts)
map("n", "<leader>ca", vim.lsp.buf.code_action, opts)
map("n", "<leader>F", function()
	vim.lsp.buf.format({ async = true })
end, opts)

-- ---------- 诊断跳转 ----------
map("n", "[d", vim.diagnostic.goto_prev, opts)
map("n", "]d", vim.diagnostic.goto_next, opts)
map("n", "<leader>de", vim.diagnostic.open_float, opts)
map("n", "<leader>dq", vim.diagnostic.setloclist, opts)

-- ---------- Treesitter Textobjects ----------
local select = require("nvim-treesitter-textobjects.select")
local move = require("nvim-treesitter-textobjects.move")

local ts_objects = {
	f = { name = "function" },
	c = { name = "class" },
	p = { name = "parameter" },
	d = { name = "conditional" },
	l = { name = "loop" },
	a = { name = "call" },
	m = { name = "comment" },
}

-- Select
for key, obj in pairs(ts_objects) do
	local inner = "@" .. obj.name .. ".inner"
	local outer = "@" .. obj.name .. ".outer"

	map({ "x", "o" }, "s" .. key, function()
		select.select_textobject(inner, "textobjects")
	end)

	map({ "x", "o" }, "s" .. key:upper(), function()
		select.select_textobject(outer, "textobjects")
	end)
end

-- Select local scope
map({ "x", "o" }, "ss", function()
	select.select_textobject("@local.scope", "locals")
end)

-- Move (next / prev)
for key, obj in pairs(ts_objects) do
	local inner = "@" .. obj.name .. ".inner"
	local outer = "@" .. obj.name .. ".outer"

	map({ "n", "x", "o" }, "m" .. key, function()
		move.goto_next_start(outer, "textobjects")
	end)

	map({ "n", "x", "o" }, "m" .. key:upper(), function()
		move.goto_next_start(inner, "textobjects")
	end)

	map({ "n", "x", "o" }, "M" .. key, function()
		move.goto_previous_start(outer, "textobjects")
	end)

	map({ "n", "x", "o" }, "M" .. key:upper(), function()
		move.goto_previous_start(inner, "textobjects")
	end)
end

-- Scope move
map({ "n", "x", "o" }, "ms", function()
	move.goto_next_start("@local.scope", "locals")
end)

map({ "n", "x", "o" }, "Ms", function()
	move.goto_previous_start("@local.scope", "locals")
end)

-- Fold move
map({ "n", "x", "o" }, "mz", function()
	move.goto_next_start("@fold", "folds")
end)

map({ "n", "x", "o" }, "Mz", function()
	move.goto_previous_start("@fold", "folds")
end)
EOF
