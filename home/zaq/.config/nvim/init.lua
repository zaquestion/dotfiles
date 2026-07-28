-- ============================================================================
-- Neovim config (Lua). Modernized from the old init.vim:
--   plugin mgr : vim-plug            -> folke/lazy.nvim
--   completion : ncm2 + nvim-yarp    -> saghen/blink.cmp
--   LSP        : LanguageClient-nvim -> built-in vim.lsp + nvim-lspconfig
--   rust       : rust-tools.nvim     -> mrcjkb/rustaceanvim
--   format     : vim-autoformat      -> stevearc/conform.nvim
--   lint       : syntastic           -> vim.diagnostic (LSP) + nvim-lint
--   search     : ack.vim/vim-ripgrep -> telescope (ripgrep + fzf-native)
--   snippets   : ultisnips           -> dropped
-- ============================================================================

-- Leader must be set before lazy loads so plugin keymaps see it.
vim.g.mapleader = ','

-- No remote-plugin hosts are used; disable to quiet :checkhealth.
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0

-- true-color (foot supports it); needed for monokai's gui colors + treesitter
vim.opt.termguicolors = true

-- ---------------------------------------------------------------------------
-- Bootstrap lazy.nvim
-- ---------------------------------------------------------------------------
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    'git', 'clone', '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git', '--branch=stable', lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ---------------------------------------------------------------------------
-- Plugins
-- ---------------------------------------------------------------------------
require('lazy').setup({
  -- Colorscheme (treesitter-aware monokai) ---------------------------------
  {
    'tanvirtin/monokai.nvim',
    priority = 1000,
    config = function()
      vim.cmd.colorscheme('monokai')
    end,
  },

  -- Completion -------------------------------------------------------------
  {
    'saghen/blink.cmp',
    version = '1.*', -- prebuilt Rust fuzzy binary; falls back to Lua matcher
    opts = {
      keymap = {
        preset = 'enter',                            -- <CR> accepts
        ['<Tab>'] = { 'select_next', 'fallback' },   -- keep old Tab-cycles muscle memory
        ['<S-Tab>'] = { 'select_prev', 'fallback' },
      },
      appearance = { nerd_font_variant = 'mono' },
      sources = { default = { 'lsp', 'path', 'buffer' } }, -- no 'snippets'
      signature = { enabled = true },
      -- leave ':' command-line completion to native wildmenu (wildmode below)
      cmdline = { enabled = false },
    },
  },

  -- LSP --------------------------------------------------------------------
  {
    'neovim/nvim-lspconfig',
    -- blink is a dependency so it loads first and registers its completion
    -- capabilities on every server via vim.lsp.config('*') before we enable.
    dependencies = { 'saghen/blink.cmp' },
    config = function()
      vim.diagnostic.config({
        virtual_text = true,
        severity_sort = true,
        float = { border = 'rounded' },
      })

      -- gopls: preserve the old build tags + placeholders.
      vim.lsp.config('gopls', {
        settings = {
          gopls = {
            usePlaceholders = true,
            buildFlags = { '-tags=or_test,or_dev,or_e2e,or_int' },
          },
        },
      })

      -- Enable a server only if its binary is installed, so missing servers
      -- don't spam errors. Install any of these to activate them:
      --   go rust ts ruby python
      local servers = {
        gopls = 'gopls',
        ts_ls = 'typescript-language-server',
        solargraph = 'solargraph',
        pyright = 'pyright-langserver',
        -- rust is handled by rustaceanvim, not here.
      }
      local enable = {}
      for name, bin in pairs(servers) do
        if vim.fn.executable(bin) == 1 then
          table.insert(enable, name)
        end
      end
      if #enable > 0 then
        vim.lsp.enable(enable)
      end
    end,
  },

  -- Rust (replaces rust-tools.nvim; drives rust-analyzer + DAP) ------------
  {
    'mrcjkb/rustaceanvim',
    init = function()
      -- codelldb DAP adapter, extracted from the vscode-lldb .vsix release
      local root = vim.fn.expand('~/.local/share/nvim/codelldb/extension')
      local codelldb = root .. '/adapter/codelldb'
      local liblldb = root .. '/lldb/lib/liblldb.so'
      -- a function value is evaluated lazily, once rustaceanvim is loaded
      vim.g.rustaceanvim = function()
        return {
          dap = {
            adapter = require('rustaceanvim.config').get_codelldb_adapter(codelldb, liblldb),
          },
        }
      end
    end,
  },

  -- Treesitter (the 'main' branch rewrite) --------------------------------
  -- Parsers via require('nvim-treesitter').install(); highlighting + indent
  -- are enabled per-buffer through vim.treesitter (no configs.setup here).
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter').install({
        'bash', 'c', 'diff', 'go', 'gomod', 'gosum', 'gotmpl', 'gowork',
        'json', 'jsonc', 'jsonnet', 'lua', 'luadoc', 'markdown',
        'markdown_inline', 'python', 'query', 'regex', 'ruby', 'rust',
        'toml', 'vim', 'vimdoc', 'yaml',
      })

      -- Enable treesitter for any buffer whose parser is installed; pcall
      -- skips filetypes without one. indentexpr is experimental on main --
      -- drop that line if indentation misbehaves.
      vim.api.nvim_create_autocmd('FileType', {
        callback = function(ev)
          if pcall(vim.treesitter.start, ev.buf) then
            vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },

  -- Formatting (replaces vim-autoformat) -----------------------------------
  {
    'stevearc/conform.nvim',
    config = function()
      require('conform').setup({
        formatters_by_ft = {
          python = { 'yapf' },
          lua = { 'stylua' },
          go = { 'gofmt' },
          rust = { 'rustfmt' },
          json = { 'jq' },
        },
        formatters = {
          -- carry over the old g:formatdef_yapf style
          yapf = {
            prepend_args = {
              '--style',
              '{based_on_style: pep8, indent_width: 4, join_multiple_lines: true, '
                .. 'SPACE_BETWEEN_ENDING_COMMA_AND_CLOSING_BRACKET: false, '
                .. 'COALESCE_BRACKETS: true, DEDENT_CLOSING_BRACKETS: true, COLUMN_LIMIT: 120}',
            },
          },
        },
      })
      vim.keymap.set({ 'n', 'v' }, '<leader>F', function()
        require('conform').format({ async = true, lsp_format = 'fallback' })
      end, { desc = 'Format buffer/selection' })
    end,
  },

  -- Linting (replaces syntastic; LSP diagnostics cover most cases) ----------
  {
    'mfussenegger/nvim-lint',
    config = function()
      -- Add non-LSP linters per filetype here, e.g.:
      --   require('lint').linters_by_ft = { go = { 'golangcilint' } }
      require('lint').linters_by_ft = {}
      vim.api.nvim_create_autocmd({ 'BufWritePost', 'BufReadPost', 'InsertLeave' }, {
        callback = function()
          require('lint').try_lint()
        end,
      })
    end,
  },

  -- Fuzzy finder / search (replaces ack.vim + vim-ripgrep) -----------------
  {
    'nvim-telescope/telescope.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    },
    config = function()
      local telescope = require('telescope')
      telescope.setup({
        defaults = {
          -- ripgrep backend; --hidden but never descend into .git
          vimgrep_arguments = {
            'rg', '--color=never', '--no-heading', '--with-filename',
            '--line-number', '--column', '--smart-case', '--hidden',
            '--glob', '!**/.git/*',
          },
          file_ignore_patterns = { 'node_modules', '%.git/', 'vendor/' },
        },
        pickers = {
          find_files = { hidden = true },
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = 'smart_case',
          },
        },
      })
      telescope.load_extension('fzf')

      local tb = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', tb.find_files, { desc = 'Find files' })
      vim.keymap.set('n', '<leader>fg', tb.live_grep, { desc = 'Live grep (ripgrep)' })
      vim.keymap.set('n', '<leader>fb', tb.buffers, { desc = 'Buffers' })
      vim.keymap.set('n', '<leader>fh', tb.help_tags, { desc = 'Help tags' })
      -- old <C-\> :Rg -> grep the word under the cursor
      vim.keymap.set('n', '<C-\\>', tb.grep_string, { desc = 'Grep word under cursor' })
    end,
  },

  -- Git --------------------------------------------------------------------
  { 'tpope/vim-fugitive' },
  {
    'shumphrey/fugitive-gitlab.vim',
    init = function()
      vim.g.fugitive_gitlab_domains = { 'https://gitlab.com' }
    end,
  },
  { 'tpope/vim-rhubarb' },

  -- Debugging (nvim-dap; replaces vimspector + vim-delve) ------------------
  -- Rust debugging is driven by rustaceanvim (:RustLsp debuggables), Go by
  -- nvim-dap-go (delve). Keys roughly mirror vimspector's HUMAN preset.
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      { 'rcarriga/nvim-dap-ui', dependencies = { 'nvim-neotest/nvim-nio' } },
      'theHamsta/nvim-dap-virtual-text',
      'leoluz/nvim-dap-go',
    },
    config = function()
      local dap = require('dap')
      local dapui = require('dapui')
      dapui.setup()
      require('nvim-dap-virtual-text').setup()
      require('dap-go').setup()

      -- open/close the UI automatically around a session
      dap.listeners.before.attach.dapui_config = function() dapui.open() end
      dap.listeners.before.launch.dapui_config = function() dapui.open() end
      dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
      dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

      local map = vim.keymap.set
      map('n', '<F5>', dap.continue, { desc = 'DAP continue/start' })
      map('n', '<F9>', dap.toggle_breakpoint, { desc = 'DAP toggle breakpoint' })
      map('n', '<F10>', dap.step_over, { desc = 'DAP step over' })
      map('n', '<F11>', dap.step_into, { desc = 'DAP step into' })
      map('n', '<F12>', dap.step_out, { desc = 'DAP step out' })
      map('n', '<leader>dB', function()
        dap.set_breakpoint(vim.fn.input('Breakpoint condition: '))
      end, { desc = 'DAP conditional breakpoint' })
      map('n', '<leader>dr', dap.repl.toggle, { desc = 'DAP REPL' })
      map('n', '<leader>du', dapui.toggle, { desc = 'DAP UI toggle' })
      -- <leader>di kept from the old vimspector balloon-eval binding
      map({ 'n', 'x' }, '<leader>di', function() dapui.eval() end, { desc = 'DAP eval' })
    end,
  },

  -- Language & filetype support -------------------------------------------
  { 'google/vim-jsonnet' },
  { 'tpope/vim-rails' },
  { 'wannesm/wmgraphviz.vim' },
  { 'tmhedberg/SimpylFold' },

  -- Editing / UI -----------------------------------------------------------
  {
    'preservim/tagbar', -- (was majutsushi/tagbar)
    config = function()
      vim.keymap.set('n', '<F8>', '<cmd>TagbarToggle<cr>', { desc = 'Toggle tagbar' })
    end,
  },
  { 'godlygeek/tabular' },
  { 'Yggdroot/indentLine' },

  -- Library used by claudecode's terminal (must load early, not lazily) -----
  {
    'folke/snacks.nvim',
    lazy = false,
    priority = 1000,
    opts = {},
  },

  -- AI ---------------------------------------------------------------------
  {
    'coder/claudecode.nvim',
    dependencies = { 'folke/snacks.nvim' },
    config = function()
      require('claudecode').setup({})
      vim.keymap.set('n', '<leader>ac', '<cmd>ClaudeCode<cr>', { desc = 'Claude: toggle' })
      vim.keymap.set('n', '<leader>af', '<cmd>ClaudeCodeFocus<cr>', { desc = 'Claude: focus' })
      vim.keymap.set('v', '<leader>as', '<cmd>ClaudeCodeSend<cr>', { desc = 'Claude: send selection' })
    end,
  },

  -- Notes ------------------------------------------------------------------
  {
    'vimwiki/vimwiki',
    init = function()
      vim.g.vimwiki_list = {
        { path = '~/vimwiki/', syntax = 'markdown', ext = '.md' },
      }
    end,
    config = function()
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'vimwiki',
        command = 'silent! iunmap <buffer> <Tab>',
      })
    end,
  },
}, {
  ui = { border = 'rounded' },
  rocks = { enabled = false }, -- no plugins need luarocks/hererocks
})

-- ===========================================================================
-- LSP buffer keymaps (native, work for every server incl. rustaceanvim)
-- ===========================================================================
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local buf = ev.buf
    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
    end
    map('n', 'gd', vim.lsp.buf.definition, 'Goto definition')
    map('n', '<C-]>', vim.lsp.buf.definition, 'Goto definition')
    map('n', 'gD', vim.lsp.buf.declaration, 'Goto declaration')
    map('n', 'gi', vim.lsp.buf.implementation, 'Goto implementation')
    map('n', 'gr', '<cmd>Telescope lsp_references<cr>', 'References')
    map('n', 'K', vim.lsp.buf.hover, 'Hover')
    map('n', '<leader>rn', vim.lsp.buf.rename, 'Rename')
    map({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, 'Code action')
    map('n', '[d', function() vim.diagnostic.jump({ count = -1, float = true }) end, 'Prev diagnostic')
    map('n', ']d', function() vim.diagnostic.jump({ count = 1, float = true }) end, 'Next diagnostic')
    map('n', '<leader>dd', vim.diagnostic.open_float, 'Line diagnostics')
  end,
})

-- ===========================================================================
-- Options
-- ===========================================================================
vim.opt.timeoutlen = 1000
vim.opt.ttimeoutlen = 10

vim.opt.lazyredraw = true

-- splits
vim.opt.splitbelow = true
vim.opt.splitright = true

-- line numbers
vim.opt.relativenumber = true
vim.opt.number = true

-- completion menu (blink-friendly; no preview scratch window)
vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }
vim.opt.shortmess:append('c')

vim.opt.showmatch = true

-- searching
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true

-- command-line completion
vim.opt.wildmode = { 'longest', 'list' }
vim.opt.wildmenu = true

-- indentation
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- tags file
vim.opt.tags:append('$projects/tags')

-- netrw
vim.g.netrw_liststyle = 3
vim.g.netrw_bufsettings = 'noma nomod nu nobl nowrap ro'

-- terminal
vim.g.terminal_scrollback_buffer_size = 2147483647

-- Wayland clipboard (wl-copy/wl-paste). Wayland has no "secondary" selection,
-- so the old shared-yank-across-sessions trick now rides the PRIMARY selection:
--   +  system clipboard   (only touched via "+y / "+p)
--   *  primary selection  (the unnamed register; shared across nvim sessions)
vim.g.clipboard = {
  name = 'wl-clipboard',
  copy = {
    ['+'] = 'wl-copy',
    ['*'] = 'wl-copy --primary',
  },
  paste = {
    ['+'] = 'wl-paste --no-newline',
    ['*'] = 'wl-paste --no-newline --primary',
  },
  cache_enabled = 1,
}
-- unnamed -> '*' (primary); keeps yanks out of the system clipboard
vim.opt.clipboard = 'unnamed'

-- project-specific macro carried over from the old config
vim.fn.setreg('s', '^/self\\.dwdwicfg["lguwwi"]')

-- ===========================================================================
-- Filetypes
-- ===========================================================================
vim.filetype.add({
  extension = {
    diag = 'diag',
    gv = 'dot',
    -- Go templates: register 'gotmpl' so gopls attaches (and quiets the
    -- "Unknown filetype 'gotmpl'" warning from :checkhealth vim.lsp).
    tmpl = 'gotmpl',
    gotmpl = 'gotmpl',
  },
})

-- ===========================================================================
-- Autocommands
-- ===========================================================================
-- strip trailing whitespace on save
vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = '*',
  command = [[%s/\s\+$//e]],
})

-- ===========================================================================
-- Keymaps
-- ===========================================================================
-- window navigation
vim.keymap.set('', '<C-h>', '<C-w>h')
vim.keymap.set('', '<C-j>', '<C-w>j')
vim.keymap.set('', '<C-k>', '<C-w>k')
vim.keymap.set('', '<C-l>', '<C-w>l')

-- window resize
vim.keymap.set('', '+', '<C-w>+')
vim.keymap.set('', '-', '<C-w>-')

-- clear search highlight
vim.keymap.set('n', '<leader><CR>', '<cmd>noh<cr>')

-- edit a file in the same dir as the current buffer
vim.keymap.set('n', '<leader>e', ':e <C-R>=expand("%:p:h") . "/"<CR>', { desc = 'Edit in buffer dir' })
vim.keymap.set('n', '<leader>E', '<cmd>Explore<cr>', { desc = 'Explore' })
-- re-run last command
vim.keymap.set('n', '<leader><leader>', '@:', { desc = 'Repeat last : command' })
-- open the ftplugin for the current filetype
vim.keymap.set('n', '<leader>ft', function()
  vim.cmd('sp ~/.config/nvim/ftplugin/' .. vim.bo.filetype .. '.vim')
end, { desc = 'Edit ftplugin' })

-- jq the whole buffer
vim.keymap.set('n', '<leader>jf', '<cmd>%!jq .<cr>', { desc = 'Format JSON with jq' })

-- terminal: <Esc> leaves terminal mode
vim.keymap.set('t', '<Esc>', [[<C-\><C-n>]])

-- <C-c> triggers InsertLeave properly
vim.keymap.set('i', '<C-c>', '<Esc>')
