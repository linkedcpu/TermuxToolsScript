pkg i git stylua lua-language-server npm python3 neovim termux-api -y
termux-api-start
mkdir -p "$HOME/.config/nvim"
cat >"$HOME/.config/nvim/init.lua" <<-'EOF'
-- ============================================
-- 基础设置
-- ============================================

-- 设置 leader 键为空格，方便自定义快捷键
vim.g.mapleader = " "
-- 设置局部 leader 键也为空格（通常用于文件类型插件）
vim.g.maplocalleader = " "
----------------------------------------
-- 系统剪切板配置
local is_wsl = vim.fn.has("wsl") == 1
local is_termux = vim.env.PREFIX and vim.env.PREFIX:match("/com.termux")
local is_mac = vim.fn.has("mac") == 1
local is_linux = not (is_wsl or is_termux or is_mac) and vim.fn.has("unix") == 1

if is_wsl then
    vim.opt.clipboard = "unnamedplus"
    vim.g.clipboard = {
        name = "win32yank",
        copy = {
            ["+"] = { "win32yank.exe", "-i", "--crlf" },
            ["*"] = { "win32yank.exe", "-i", "--crlf" },
        },
        paste = {
            ["+"] = { "win32yank.exe", "-o", "--lf" },
            ["*"] = { "win32yank.exe", "-o", "--lf" },
        },
        cache_enabled = true,
    }
elseif is_mac then
    vim.opt.clipboard = "unnamedplus"
elseif is_termux then
    vim.opt.clipboard = "unnamedplus"
elseif is_linux then
    vim.opt.clipboard = "unnamedplus"
    if vim.fn.executable("wl-copy") == 1 then
        vim.g.clipboard = {
            name = "wl-clipboard",
            copy = { ["+"] = "wl-copy", ["*"] = "wl-copy" },
            paste = { ["+"] = "wl-paste", ["*"] = "wl-paste" },
            cache_enabled = 1,
        }
    elseif vim.fn.executable("xclip") == 1 then
        vim.g.clipboard = {
            name = "xclip",
            copy = { ["+"] = "xclip -selection clipboard", ["*"] = "xclip -selection primary" },
            paste = { ["+"] = "xclip -selection clipboard -o", ["*"] = "xclip -selection primary -o" },
            cache_enabled = 1,
        }
    end
end

----------------------------------------
-- 显示行号
vim.opt.number = true
-- 显示相对行号，便于跳转
vim.opt.relativenumber = true
-- 高亮当前光标所在行
vim.opt.cursorline = true
-- 隐藏标签栏（不显示已打开的标签页列表）
vim.opt.showtabline = 0
-- 全局状态栏，3 表示始终显示最下方状态栏（配合 lualine 等插件）
vim.opt.laststatus = 3
-- 启用终端真彩色（24 位颜色）
vim.opt.termguicolors = true
-- 显示当前模式（如 INSERT、NORMAL）在底部，部分插件可能依赖
vim.opt.showmode = true
-- 始终保留符号列（用于显示诊断、git 状态等），避免界面抖动
vim.opt.signcolumn = "yes"
-- 命令行高度为 1，减少界面占用
vim.opt.cmdheight = 1
-- 启用自动换行（超过窗口宽度时折行显示）
vim.opt.wrap = true

-- 制表符宽度为 4 个空格
vim.opt.tabstop = 4
-- 缩进操作（<< 和 >>）的宽度为 4
vim.opt.shiftwidth = 4
-- 插入模式下按 Tab 键时插入的空格数（与 tabstop 配合，建议一致）
vim.opt.softtabstop = 4
-- 将 Tab 展开为空格（推荐，避免混合缩进）
vim.opt.expandtab = true
-- 智能缩进，根据上一行决定新行的缩进
vim.opt.smartindent = true
-- 自动缩进，继承上一行的缩进
vim.opt.autoindent = true

-- 搜索时忽略大小写（默认）
vim.opt.ignorecase = true
-- 若搜索模式包含大写字母，则禁用 ignorecase，实现智能大小写敏感
vim.opt.smartcase = true
-- 高亮所有搜索结果
vim.opt.hlsearch = true
-- 增量搜索：输入时实时高亮匹配
vim.opt.incsearch = true

-- 启用鼠标所有模式（支持点击、滚动、选择等）
vim.opt.mouse = "a"

-- 插件或某些操作等待更新的时间（毫秒），用于触发异步事件
vim.opt.updatetime = 300
-- 按键映射超时时间（毫秒），用于等待组合键
vim.opt.timeoutlen = 700

-- 禁用备份文件（~ 文件）
vim.opt.backup = false
-- 禁用交换文件（.swp），避免产生临时文件
vim.opt.swapfile = false
-- 内部编码设为 UTF-8
vim.opt.encoding = "utf-8"
-- 文件编码也设为 UTF-8
vim.opt.fileencoding = "utf-8"

-- 关闭错误提示音（蜂鸣声）
vim.opt.errorbells = false
-- 关闭视觉闪烁（屏幕闪烁）
vim.opt.visualbell = false
-- 缩短消息显示：移除多余的 intro 信息，减少冗余
vim.opt.shortmess:append("sI")

-- 显示不可见字符（如空格、Tab、行尾等），便于发现多余空白
vim.opt.list = true
-- 自定义不可见字符的显示符号
vim.opt.listchars = {
    tab = "→ ", -- Tab 显示为 "→ "
    space = "·", -- 普通空格显示为 "·"
    lead = "·", -- 行首空格显示为 "·"
    multispace = "···", -- 连续多个空格显示为 "···"
    trail = "•", -- 行尾空格显示为 "•"
    eol = "↵", -- 行尾换行符显示为 "↵"
    nbsp = "␣", -- 不间断空格显示为 "␣"
    extends = "›", -- 行首被折叠时显示 "›"
    precedes = "‹", -- 行尾被折叠时显示 "‹"
}

-- ============================================
-- Treesitter 折叠（Neovim 0.12 原生支持）
-- ============================================
-- 使用 Treesitter 语法树进行代码折叠
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
-- 默认展开所有折叠层级（99 表示不折叠任何层）
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
-- 在行号旁显示折叠列（宽度为 1）
vim.opt.foldcolumn = "1"
-- 将 Bash 脚本（.sh）关联到 Treesitter 的 bash 语言解析器
vim.treesitter.language.register("bash", { "sh" })

-- ============================================
-- 撤销历史持久化
-- ============================================
-- 设置撤销文件存放目录
local undodir = vim.fn.stdpath("data") .. "/undo"
-- 若目录不存在则创建
if vim.fn.isdirectory(undodir) == 0 then
    vim.fn.mkdir(undodir, "p")
end
vim.opt.undodir = undodir
-- 禁用撤销文件持久化（设为 false 则关闭撤销历史跨会话保存）
vim.opt.undofile = false

-- ============================================
-- 自动命令（Autocommands）
-- ============================================
-- 保存文件前自动删除行尾多余空格
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*",
    callback = function()
        local view = vim.fn.winsaveview() -- 保存当前窗口视图（光标位置等）
        vim.cmd([[silent! %s/\s\+$//e]]) -- 删除行尾空格，忽略错误
        vim.fn.winrestview(view)    -- 恢复视图，避免光标跳动
    end,
})

-- 终端关闭时自动删除对应的缓冲区
vim.api.nvim_create_autocmd("TermClose", {
    pattern = "*",
    command = "bdelete! %", -- 强制删除当前终端缓冲区
})

-- 写入文件前自动创建其所在目录（若不存在）
vim.api.nvim_create_autocmd("BufWritePre", {
    callback = function(event)
        -- 获取文件所在目录并创建
        vim.fn.mkdir(vim.fs.dirname(event.match), "p")
    end,
})
-- ============================================
-- 全局快捷键（编辑器级，全带 desc）
-- ============================================
local map = vim.keymap.set

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
end, { desc = "发送path" })

map("n", "<leader>w", ":w<CR>", { desc = "保存" })
map("n", "<leader>q", ":q!<CR>", { desc = "强制退出" })

map("n", "<leader>J", ":m .+1<CR>==", { desc = "下移当前行" })

map("n", "<leader>K", ":m .-2<CR>==", { desc = "上移当前行" })
map("v", "<leader>J", ":m '>+1<CR>gv=gv", { desc = "下移选中行" })
map("v", "<leader>K", ":m '<-2<CR>gv=gv", { desc = "上移选中行" })

map("n", "<leader>wo", "<C-w>o", { desc = "关闭其他窗口" })
map("n", "<leader>wh", "<C-w>s", { desc = "水平分割" })
map("n", "<leader>wv", "<C-w>v", { desc = "垂直分割" })
map("n", "<leader>wn", ":new<CR>", { desc = "新建水平窗口" })
map("n", "<leader>wN", ":vnew<CR>", { desc = "新建垂直窗口" })
map("n", "<leader>wx", "<C-w>x", { desc = "交换窗口" })
map("n", "<leader>wc", "<C-w>c", { desc = "关闭窗口" })

-- ============================================
-- Lazy
-- ============================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local proxyUrl = "https://gh-proxy.org/"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local out = vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "--branch=stable",
        proxyUrl .. "https://github.com/folke/lazy.nvim.git",
        lazypath,
    })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({ { "Failed to clone lazy.nvim:\n", "ErrorMsg" }, { out, "WarningMsg" } }, true, {})
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

-- ============================================
-- 插件
-- ============================================
require("lazy").setup({
    git = { url_format = proxyUrl .. "https://github.com/%s.git" },
    spec = {
        -- which-key
        {
            "folke/which-key.nvim",
            event = "VeryLazy",
            opts = {
                preset = "modern",
                delay = 500,
                win = { border = "rounded" },
                spec = {
                    { "<leader>w", group = "窗口 / window" },
                    { "<leader>f", group = "格式化 / format" },
                    { "<leader>t", group = "文件树 | 翻译" },
                    { "<leader>l", group = "LSP" },
                    { "<leader>d", group = "诊断 / diagnostic" },
                },
            },
            keys = {
                {
                    "<leader>?",
                    function()
                        require("which-key").show({ global = true })
                    end,
                    desc = "显示所有 leader 快捷键",
                },
            },
        },

        -- 主题

        -- bufferline
        {
            "akinsho/bufferline.nvim",
            version = "*",
            dependencies = "nvim-tree/nvim-web-devicons",
            config = function()
                require("bufferline").setup({
                    options = {
                        enforce_regular_tabs = false,
                        tab_size = 10,
                        max_name_length = 12,
                        truncate_names = true,
                        show_buffer_icons = false,
                        separator_style = "thin",
                    },
                })
            end,
        },

        -- mason
        {
            "mason-org/mason.nvim",
            opts = {
                github = { download_url_template = proxyUrl .. "https://github.com/%s/releases/download/%s/%s" },
                pip = { install_args = { "--index-url", "https://pypi.tuna.tsinghua.edu.cn/simple" } },
                npm = { install_args = { "--registry", "https://registry.npmmirror.com" } },
            },
        },
        {
            "mason-org/mason-lspconfig.nvim",
            opts = { ensure_installed = { "yamlls", "jdtls" } },
            dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
        },
        {
            "WhoIsSethDaniel/mason-tool-installer.nvim",
            dependencies = { "mason-org/mason.nvim" },
            opts = {
                run_on_start = true,
                start_delay = 3000,
                ensure_installed = { "ktlint", "shfmt", "xmlformatter" },
            },
        },

        -- conform（普通格式化 ff）
        {
            "stevearc/conform.nvim",
            keys = {
                {
                    "<leader>ff",
                    function()
                        require("conform").format({ async = true, lsp_fallback = true }, function(err, did_edit)
                            if err then
                                vim.notify("conform:格式化失败: " .. err, vim.log.levels.ERROR)
                            elseif did_edit then
                                vim.notify("conform:格式化完成!", vim.log.levels.INFO)
                            else
                                vim.notify("conform:已格式化!", vim.log.levels.DEBUG)
                            end
                        end)
                    end,

                    desc = "普通格式化",
                },
            },
            config = function()
                require("conform").setup({
                    formatters_by_ft = {
                        lua = { "stylua" },
                        xml = { "xmlformat" },
                        kt = { "ktlint" },
                        kts = { "ktlint" },
                        sh = { "shfmt" },
                        bash = { "shfmt" },
                    },
                    formatters = {
                        codeformat = { command = "CodeFormat", args = { "format", "-i", "-d" }, stdin = true },
                    },
                })
            end,
        },

        -- LSP
        {
            "neovim/nvim-lspconfig",
            config = function()
                vim.lsp.config("lua_ls", {
                    settings = {
                        Lua = {
                            runtime = { version = "LuaJIT" },
                            diagnostics = { globals = { "vim" } },
                            telemetry = { enable = false },
                        },
                    },
                })
                vim.lsp.enable("lua_ls")
                local mbin = vim.fn.stdpath("data") .. "/mason/bin"
                vim.lsp.config("yamlls", { cmd = { "node", mbin .. "/yaml-language-server", "--stdio" } })
                vim.lsp.enable("yamlls")
                vim.lsp.config("jdtls", {
                    cmd = {
                        mbin .. "/jdtls",
                        "-data",
                        vim.fn.stdpath("cache") .. "/jdtls-ws/" .. vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t"),
                    },
                })
                vim.lsp.enable("jdtls")
            end,
            keys = {
                { "<leader>ld", vim.lsp.buf.definition, desc = "定义" },
                { "<leader>lD", vim.lsp.buf.declaration, desc = "声明" },
                { "<leader>li", vim.lsp.buf.implementation, desc = "实现" },
                { "<leader>lt", vim.lsp.buf.type_definition, desc = "类型定义" },
                { "<leader>lr", vim.lsp.buf.references, desc = "引用" },
                { "<leader>lh", vim.lsp.buf.hover, desc = "悬浮文档" },
                { "<leader>lk", vim.lsp.buf.signature_help, desc = "签名帮助" },
                { "<leader>lm", vim.lsp.buf.rename, desc = "重命名" },
                { "<leader>la", vim.lsp.buf.code_action, desc = "代码操作" },
                {
                    "<leader>fl",
                    function()
                        vim.lsp.buf.format({ async = true })
                    end,
                    desc = "LSP 格式化",
                },
                {
                    "<leader>dp",
                    function()
                        vim.diagnostic.jump({ count = -1, float = true })
                    end,
                    desc = "上一个诊断",
                },
                {
                    "<leader>dn",
                    function()
                        vim.diagnostic.jump({ count = 1, float = true })
                    end,
                    desc = "下一个诊断",
                },

                { "<leader>de", vim.diagnostic.open_float, desc = "Diagnostic details" },
                { "<leader>dq", vim.diagnostic.setloclist, desc = "Diagnostics list" },
            },
        },

        -- nvim-cmp
        {
            "hrsh7th/nvim-cmp",
            dependencies = { "hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path" },
            config = function()
                local cmp = require("cmp")
                cmp.setup({
                    sources = { { name = "nvim_lsp" }, { name = "buffer" }, { name = "path" } },
                    mapping = cmp.mapping.preset.insert({
                        ["<Tab>"] = cmp.mapping.select_next_item(),
                        ["<S-Tab>"] = cmp.mapping.select_prev_item(),
                        ["<CR>"] = cmp.mapping.confirm({ select = true }),
                    }),
                })
            end,
        },

        -- 翻译（只留 <leader>tt）
        {
            "voldikss/vim-translator",
            cmd = { "Translate", "TranslateW", "TranslateR", "TranslateL" },
            keys = {
                { "<leader>tt", ":TranslateW<CR>", mode = "n", desc = "翻译光标词" },
                { "<leader>tt", "<Esc>:TranslateW<CR>", mode = "v", desc = "翻译选中" },
            },
            config = function()
                vim.g.translator_target_lang = "zh"
                vim.g.translator_source_lang = "auto"
                vim.g.translator_default_engines = { "bing" }
                vim.g.translator_window_type = "popup"
            end,
        },

        -- 文件树（t 前缀）
        {
            "nvim-tree/nvim-tree.lua",
            version = "*",
            lazy = false,
            dependencies = { "nvim-tree/nvim-web-devicons" },
            keys = {
                {
                    "<leader>te",
                    function()
                        vim.cmd("NvimTreeToggle")
                        vim.cmd("NvimTreeResize " .. vim.o.columns)
                    end,
                    desc = "切换文件树",
                },
                { "<leader>tf", "<cmd>NvimTreeFocus<CR>", desc = "聚焦文件树" },
                { "<leader>to", "<cmd>NvimTreeFindFile<CR>", desc = "定位当前文件" },
            },
            config = function()
                require("nvim-tree").setup({
                    view = { width = 30, side = "left", number = true, relativenumber = true },
                    filters = { dotfiles = false },
                    actions = { open_file = { quit_on_open = true } },
                })
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
                },
            },
        },

        -- ✅ 彩虹缩进线（原样回归）
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

        {
            "numToStr/Comment.nvim",
            opts = {}, -- 留空就是用默认配置
        },
        {
            "folke/tokyonight.nvim",
            lazy = false,
            priority = 1000,
            opts = {
                style = "moon", -- moon / storm / night / day
                transparent = false, -- 想要透背改 true，并把下面 sidebars/floats 也改 transparent
                terminal_colors = true,
                styles = {
                    comments = { italic = true },
                    keywords = { italic = true },
                    functions = {},
                    variables = {},
                    sidebars = "dark", -- transparent / normal / dark
                    floats = "dark",
                },
            },
            config = function(_, opts)
                require("tokyonight").setup(opts)
                vim.cmd.colorscheme("tokyonight")
            end,
        },
        --[[
-- 状态栏同色（可选但推荐）
{
"nvim-lualine/lualine.nvim",
dependencies = { "folke/tokyonight.nvim" },
opts = {
options = {
theme = "tokyonight",
component_separators = { left = "", right = "" },
section_separators = { left = "", right = "" },
},
},
},
        --]]
    },
    -- install = { colorscheme = { "tokyonight-night" } },
    --
    rocks = { enabled = false },
})

-- print("🤖 Neovim 配置加载完成（最终版：彩虹缩进线已回归）")
if is_termux then
    print("Running on Termux")
elseif is_linux then
    print("Running on Linux")
end
EOF
