mkdir -p "$HOME/.config/nvim"
cat >"$HOME/.config/nvim/init.lua" <<-'EOF'
-- ============================================
-- 基础设置
-- ============================================

-- 设置空格键为全局 Leader 键（用于自定义快捷键前缀）
vim.g.mapleader = " "
-- 设置空格键为局部 Leader 键（buffer / window 级别快捷键前缀）
vim.g.maplocalleader = " "

-- 显示绝对行号（当前行显示真实行号）
vim.opt.number = true
-- 显示相对行号（其他行相对于当前行的距离，便于跳转）
vim.opt.relativenumber = true

-- 高亮当前光标所在行（更容易定位）
vim.opt.cursorline = true
-- 始终显示标签页栏（即使只有一个 tab）
vim.opt.showtabline = 2

-- 启用 24 位真彩色（对主题、LSP、Treesitter 高亮很重要）
vim.opt.termguicolors = true

-- 在底部显示当前 Vim 模式（如 -- INSERT --）
vim.opt.showmode = true

-- 左侧固定显示符号列（用于 Git 标记、诊断、断点等）
vim.opt.signcolumn = "yes"

-- 命令行高度（1 行通常够用）
vim.opt.cmdheight = 1

-- 滚动时光标上下保留的最小行数（避免贴边）
-- vim.opt.scrolloff = 10

-- 自动换行（超出窗口宽度时折行显示）
vim.opt.wrap = true

-- Tab 宽度为 4 个空格
vim.opt.tabstop = 4
-- 自动缩进 / >> << 使用的宽度为 4
vim.opt.shiftwidth = 4
-- 编辑时按 Tab 键插入的空格数
vim.opt.softtabstop = 4
-- 将 Tab 转换为空格（推荐）
vim.opt.expandtab = true
-- 智能缩进（根据语法结构自动调整）
vim.opt.smartindent = true
-- 新行继承上一行缩进
vim.opt.autoindent = true

-- 搜索时忽略大小写
vim.opt.ignorecase = true
-- 若搜索词包含大写字母，则强制区分大小写（非常实用）
vim.opt.smartcase = true
-- 高亮所有匹配结果
vim.opt.hlsearch = true
-- 输入时实时增量搜索
vim.opt.incsearch = true

-- 在所有模式下启用鼠标支持（n/v/i/c 等）
vim.opt.mouse = "a"

-- 使用系统剪贴板（"+y / "+p 等价于系统复制粘贴）
vim.opt.clipboard = "unnamedplus"

-- 更快的 CursorHold 事件刷新（影响 LSP 诊断、自动保存等）
vim.opt.updatetime = 300
-- 按键超时时间（ms），影响快捷键序列识别
vim.opt.timeoutlen = 700

-- 不生成备份文件（*.bak）
vim.opt.backup = false
-- 不使用 swap 文件（防止意外退出冲突）
vim.opt.swapfile = false

-- Neovim 内部编码
vim.opt.encoding = "utf-8"
-- 文件保存时的编码
vim.opt.fileencoding = "utf-8"

-- 关闭错误提示音
vim.opt.errorbells = false
-- 关闭视觉提示铃音
vim.opt.visualbell = false

-- 精简启动信息（注释掉，可按需开启）
vim.opt.shortmess:append("sI")

-- 性能优化：在执行宏时不重绘屏幕
vim.opt.lazyredraw = true

-- 显示不可见字符（Tab、空格、换行等）
vim.opt.list = true
-- 定义不同不可见字符的显示样式
vim.opt.listchars = {
    tab = "→ ", -- Tab 显示为 → + 空格
    space = "·", -- 空格显示为 ·
    lead = "·", -- 行首空格
    multispace = "···", -- 多个连续空格
    trail = "•", -- 行尾多余空格
    eol = "↵", -- 行尾符
    nbsp = "␣", -- 非断行空格
    extends = "›", -- 右侧被截断
    precedes = "‹", -- 左侧被截断
}

-- 使用 Treesitter 作为折叠方法
vim.opt.foldmethod = "expr"
-- 调用 Treesitter 的折叠表达式
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
-- 默认启用折叠
vim.opt.foldenable = true
-- 默认折叠层级（99 表示全部展开）
vim.opt.foldlevel = 99
-- 左侧显示折叠列（宽度 1）
vim.opt.foldcolumn = "1"

-- 构造 undo 文件目录路径（位于 Neovim data 目录中）
local undodir = vim.fn.stdpath("data") .. "/undo"
-- 如果目录不存在则创建
if vim.fn.isdirectory(undodir) == 0 then
    vim.fn.mkdir(undodir, "p")
end
-- 设置 undo 目录
vim.opt.undodir = undodir
-- ⚠️ 注意：这里仍然关闭了 undofile，如需持久化撤销可改为 true
vim.opt.undofile = false

-- ============================================
-- 自动命令（Autocommands）
-- ============================================

-- 在每次保存文件前自动删除行尾多余空格
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*",             -- 对所有文件生效
    command = "%s/\\s\\+$//e", -- 全局替换行尾空白，e 防止无匹配时报错
})

-- 终端关闭后自动删除对应的 buffer
vim.api.nvim_create_autocmd("TermClose", {
    pattern = "*",          -- 对所有终端生效
    command = "bdelete! %", -- 强制删除当前 terminal buffer
})

-- 保存时自动创建缺失目录
vim.api.nvim_create_autocmd("BufWritePre", {
    callback = function(event)
        vim.fn.mkdir(vim.fs.dirname(event.match), "p")
    end,
})

-- ============================================
-- 全局快捷键（不依赖任何插件）
-- ============================================

local map = vim.keymap.set
local opts = { noremap = true, silent = false }

-- 基础操作
map("n", "<Leader>w", ":w<CR>", opts)
map("n", "<Leader>q", ":q!<CR>", opts)
map("n", "H", "^", opts)
map("n", "L", "$", opts)

-- 视觉模式移动行
map("v", "J", ":m '>+1<CR>gv=gv", opts)
map("v", "K", ":m '<-2<CR>gv=gv", opts)

-- 窗口操作
map("n", "<Leader>wo", "<C-w>o", opts)
map("n", "<Leader>wh", "<C-w>s", opts)
map("n", "<Leader>wv", "<C-w>v", opts)
map("n", "<Leader>wn", ":new<CR>", opts)
map("n", "<Leader>wN", ":vnew<CR>", opts)
map("n", "<Leader>wx", "<C-w>x", opts)
map("n", "<Leader>wc", "<C-w>c", opts)

-- 自定义广播命令
map("n", "<leader>R", function()
    vim.fn.system({
        "am",
        "broadcast",
        "-a",
        "中二",
        "-e",
        "path",
        vim.api.nvim_buf_get_name(0),
    })
end)

-- ============================================
-- Lazy 插件管理
-- ============================================

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local proxyUrl = "https://gh-proxy.org/"

local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"

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
            { out,                            "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end

vim.opt.rtp:prepend(lazypath)

-- ============================================
-- 插件配置（快捷键已全部放回对应插件内）
-- ============================================

require("lazy").setup({
    git = {
        url_format = proxyUrl .. "https://github.com/%s.git",
    },

    spec = {
        -- =======================
        -- Catppuccin
        -- =======================
        {
            "catppuccin/nvim",
            name = "catppuccin",
            priority = 1000,
            opts = {
                flavour = "latte",
            },
            config = function(_, opts)
                require("catppuccin").setup(opts)
                vim.cmd.colorscheme("catppuccin")
            end,
        },

        {
            "mason-org/mason.nvim",
            opts = {
                providers = { "mason.providers.client" },
                github = {
                    download_url_template = proxyUrl .. "https://github.com/%s/releases/download/%s/%s",
                },
                pip = { install_args = { "--index-url", "https://pypi.tuna.tsinghua.edu.cn/simple" } },
                npm = { install_args = { "--registry", "https://registry.npmmirror.com" } },
                ui = {
                    border = "rounded",
                    icons = {
                        package_installed = "✓",
                        package_pending = "➜",
                        package_uninstalled = "✗",
                    },
                },
            },
        },

        {
            "mason-org/mason-lspconfig.nvim",
            opts = { ensure_installed = { "yamlls","jdtls" } },
            dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
        },

        -- lua/plugins/mason.lua 或接在你现有 mason spec 旁边
        {
            "WhoIsSethDaniel/mason-tool-installer.nvim",
            dependencies = { "mason-org/mason.nvim" },
            opts = {
                run_on_start = true,
                start_delay = 3000, -- 启动 3 秒后装，不卡界面
                ensure_installed = {
                    "ktlint",       -- kotlin
                    "shfmt",        -- bash
                    "xmlformatter",
                },
            },
        },

        -- =======================
        -- 格式化（全 keys ✅，通知不动 ✅）
        -- =======================
        {
            "stevearc/conform.nvim",
            keys = {
                {
                    "<leader>f",
                    function()
                        require("conform").format({ async = true, lsp_fallback = true }, function(err, did_edit)
                            if err then
                                vim.notify("格式化失败: " .. err, vim.log.levels.ERROR)
                            elseif did_edit then
                                vim.notify("格式化完成!", vim.log.levels.INFO)
                            else
                                vim.notify("已格式化!", vim.log.levels.DEBUG)
                            end
                        end)
                    end,
                    desc = "Format buffer",
                },
            },
            config = function()
                require("conform").setup({
                    formatters_by_ft = {
                        -- Termux 下 Mason 不支持 stylua，注释掉即可
                        -- lua = { "CodeFormat" },
                        lua = { "codeformat" },
                        -- lua = { "CodeFormat", "lua_ls", "stylua" },
                        xml = { "xmlformat" },
                        -- java = { "jdtls" },

                        kt = { "ktlint" },
                        kts = { "ktlint" },
                        sh = { "shfmt" },
                        bash = { "shfmt" },
                    },
                    formatters = {
                        -- Termux 明确用系统 stylua
                        codeformat = {
                            command = "CodeFormat",
                            args = { "format", "-i", "-d" }, -- 关键三件套
                            stdin = true,
                        },
                    },
                    format_on_save = false,
                })
            end,
        },

        -- =======================
        -- 颜色预览
        -- =======================
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

        -- =======================
        -- LSP
        -- =======================
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

                vim.lsp.config("yamlls", {
                    cmd = { "node", mason_bin .. "/yaml-language-server", "--stdio" },
                })

                vim.lsp.enable("yamlls")
                vim.lsp.config("jdtls", {
                    cmd = {
                        mason_bin .. "/jdtls",
                        "-data", vim.fn.stdpath("cache") .. "/jdtls-ws/" .. vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t"),
                        -- "--java-executable", "/usr/lib/jvm/java-21-openjdk/bin/java", -- 可选，不写就用 PATH/JAVA_HOME 的
                    },
                })

                vim.lsp.enable("jdtls")
            end,

            keys = {
                { "gd",         vim.lsp.buf.definition,       desc = "Definition" },
                { "gD",         vim.lsp.buf.declaration,      desc = "Declaration" },
                { "gi",         vim.lsp.buf.implementation,   desc = "Implementation" },
                { "gt",         vim.lsp.buf.type_definition,  desc = "Type definition" },
                { "gr",         vim.lsp.buf.references,       desc = "References" },

                { "K",          vim.lsp.buf.hover,            desc = "Hover info" },
                { "<C-k>",      vim.lsp.buf.signature_help,   desc = "Signature help" },

                { "<leader>ds", vim.lsp.buf.document_symbol,  desc = "Document symbols" },
                { "<leader>ws", vim.lsp.buf.workspace_symbol, desc = "Workspace symbols" },

                { "<leader>rn", vim.lsp.buf.rename,           desc = "Rename" },
                { "<leader>ca", vim.lsp.buf.code_action,      desc = "Code action" },
                {
                    "<leader>F",
                    function()
                        vim.lsp.buf.format({ async = true })
                    end,
                    desc = "LSP format",
                },

                {
                    "[d",
                    function()
                        vim.diagnostic.jump({ count = -1, float = true })
                    end,
                    desc = "Prev diagnostic",
                },
                {
                    "]d",
                    function()
                        vim.diagnostic.jump({ count = 1, float = true })
                    end,
                    desc = "Next diagnostic",
                },
                { "<leader>de", vim.diagnostic.open_float, desc = "Diagnostic details" },
                { "<leader>dq", vim.diagnostic.setloclist, desc = "Diagnostics list" },
            },
        },

        -- =======================
        -- nvim-cmp
        -- =======================
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

        -- =======================
        -- 翻译（全 keys ✅）
        -- =======================
        {
            "voldikss/vim-translator",
            cmd = { "Translate", "TranslateW", "TranslateR", "TranslateL" },
            dependencies = { "nvim-lua/plenary.nvim" },
            keys = {
                -- 弹窗翻译
                { "<leader>tt", ":TranslateW<CR>", mode = "n", desc = "翻译光标词(弹窗)" },
                { "<leader>tt", "<Esc>:TranslateW<CR>", mode = "v", desc = "翻译选中(弹窗)" },

                -- 英 → 中
                { "<leader>te", ":TranslateW! en zh<CR>", mode = "n", desc = "英→中(弹窗)" },
                { "<leader>te", "<Esc>:TranslateW! en zh<CR>", mode = "v", desc = "英→中(弹窗)" },

                -- 中 → 英
                { "<leader>tc", ":TranslateW! zh en<CR>", mode = "n", desc = "中→英(弹窗)" },
                { "<leader>tc", "<Esc>:TranslateW! zh en<CR>", mode = "v", desc = "中→英(弹窗)" },

                -- 替换原文
                { "<leader>tr", ":TranslateR<CR>", mode = "v", desc = "翻译并替换" },
            },
            config = function()
                vim.g.translator_target_lang = "zh"
                vim.g.translator_source_lang = "auto"
                vim.g.translator_default_engines = { "bing" }
                vim.g.translator_window_type = "popup"
            end,
        },

        -- =======================
        -- 缩进线
        -- =======================
        {
            "lukas-reineke/indent-blankline.nvim",
            main = "ibl",
            event = "BufReadPost",
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

        -- =======================
        -- 文件树（全 keys ✅）
        -- =======================
        {
            "nvim-tree/nvim-tree.lua",
            version = "*",

            lazy = false,
            dependencies = { "nvim-tree/nvim-web-devicons" },
            cmd = { "NvimTreeToggle", "NvimTreeFocus", "NvimTreeFindFile" },
            keys = {
                -- { "<leader>e", "<cmd>NvimTreeToggle<CR>",   desc = "Toggle file tree" },
                {
                    "<leader>e",
                    function()
                        vim.cmd("NvimTreeToggle")
                        vim.cmd("NvimTreeResize " .. vim.o.columns)
                    end,
                    desc = "Toggle FULLSCREEN file tree",
                },
                { "<leader>t", "<cmd>NvimTreeFocus<CR>",    desc = "Focus file tree" },
                { "<leader>o", "<cmd>NvimTreeFindFile<CR>", desc = "Find file in tree" },
            },
            config = function()
                require("nvim-tree").setup({
                    view = {
                        width = 30,
                        -- width = vim.o.columns,
                        side = "left",
                        number = true,
                        relativenumber = true,
                    },
                    filters = { dotfiles = false },

                    actions = {
                        open_file = {
                            quit_on_open = true, -- ✅ 打开文件后自动关闭树
                        },
                    },
                })
            end,
        },

        -- =======================
        -- Treesitter
        -- =======================
        {
            "nvim-treesitter/nvim-treesitter",
            build = ":TSUpdate",
            lazy = false,
            config = function()
                require("nvim-treesitter").install({ "lua", "bash" })
            end,
        },

        -- =======================
        -- Treesitter textobjects
        -- =======================
        {
            "nvim-treesitter/nvim-treesitter-textobjects",
            dependencies = { "nvim-treesitter/nvim-treesitter" },
            event = "VeryLazy",
            config = function()
                local map = vim.keymap.set
                local select = require("nvim-treesitter-textobjects.select")
                local move = require("nvim-treesitter-textobjects.move")

                local ts_objects = {
                    f = "function",
                    c = "class",
                    p = "parameter",
                    d = "conditional",
                    l = "loop",
                    a = "call",
                    m = "comment",
                }

                for key, name in pairs(ts_objects) do
                    local inner, outer = "@" .. name .. ".inner", "@" .. name .. ".outer"

                    map({ "x", "o" }, "s" .. key, function()
                        select.select_textobject(inner, "textobjects")
                    end)
                    map({ "x", "o" }, "s" .. key:upper(), function()
                        select.select_textobject(outer, "textobjects")
                    end)

                    map({ "n", "x", "o" }, "m" .. key, function()
                        move.goto_next_start(outer, "textobjects")
                    end)
                    map({ "n", "x", "o" }, "M" .. key, function()
                        move.goto_previous_start(outer, "textobjects")
                    end)
                end

                map({ "n", "x", "o" }, "ms", function()
                    move.goto_next_start("@local.scope", "locals")
                end)
                map({ "n", "x", "o" }, "Ms", function()
                    move.goto_previous_start("@local.scope", "locals")
                end)
            end,
        },
    },

    install = { colorscheme = { "tokyonight-night" } },
})
EOF
