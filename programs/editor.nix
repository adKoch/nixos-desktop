{
  config,
  pkgs,
  inputs,
  lib,
  ...
}: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    
    extraConfig = ''
      " Basic settings
      set number
      set relativenumber
      set tabstop=2
      set shiftwidth=2
      set expandtab
      set smartindent
      set nowrap
      set cursorline
      set termguicolors
      
      " Leader key
      let mapleader = " "
      
      " Key mappings
      nnoremap <leader>w :w<CR>
      nnoremap <leader>q :q<CR>
      
      " Enable syntax highlighting
      syntax enable
      
      " Color scheme
      colorscheme default
    '';
    
    plugins = with pkgs.vimPlugins; [
      # File explorer
      neo-tree-nvim
      
      # Dependencies for neo-tree
      nvim-web-devicons
      plenary-nvim
      nui-nvim
      
      # Fuzzy finder
      telescope-nvim
      
      # LSP
      nvim-lspconfig
      
      # Completion
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      
      # Treesitter
      nvim-treesitter.withAllGrammars
      
      # Git
      gitsigns-nvim
      
      # Status line
      lualine-nvim
      
      # Auto pairs
      nvim-autopairs
      
      # Comment
      comment-nvim
    ];
    
    extraLuaConfig = ''
      -- Configure neo-tree
      require("neo-tree").setup({
        close_if_last_window = true,
        window = {
          width = 30,
        },
      })
      
      -- Configure telescope
      require('telescope').setup{}
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
      vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
      
      -- Configure LSP
      local lspconfig = require('lspconfig')
      lspconfig.nil_ls.setup{}
      lspconfig.bashls.setup{}
      lspconfig.jsonls.setup{}
      
      -- Configure completion
      local cmp = require'cmp'
      cmp.setup({
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'buffer' },
          { name = 'path' },
        })
      })
      
      -- Configure treesitter
      require'nvim-treesitter.configs'.setup {
        highlight = {
          enable = true,
        },
        indent = {
          enable = true,
        },
      }
      
      -- Configure gitsigns
      require('gitsigns').setup()
      
      -- Configure lualine
      require('lualine').setup()
      
      -- Configure autopairs
      require("nvim-autopairs").setup {}
      
      -- Configure comment
      require('Comment').setup()
      
      -- Neo-tree toggle
      vim.keymap.set('n', '<leader>e', ':Neotree toggle<CR>', { desc = 'Toggle file explorer' })
    '';
  };

  programs.kitty = {
    enable = true;
    settings = {
      # Tab management
      tab_bar_edge = "top";
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
      tab_title_template = "{title}{' :{}:'.format(num_windows) if num_windows > 1 else ''}";
      
      # Window management
      remember_window_size = true;
      initial_window_width = 1200;
      initial_window_height = 800;
      
      # Font
      font_family = "JetBrains Mono";
      font_size = 12;
      
      # Colors
      background_opacity = "1";
      background_image = "/home/adam/Pictures/kitty_background";
      background_image_layout = "cscaled";
      background_tint = "0.9";
      # Scrollback
      scrollback_lines = 10000;
    };
    
    keybindings = {
      # Tab management
      "ctrl+shift+t" = "new_tab";
      "ctrl+shift+w" = "close_tab";
      "ctrl+shift+right" = "next_tab";
      "ctrl+shift+left" = "previous_tab";
      
      # Window management
      "ctrl+shift+enter" = "new_window";
      "ctrl+shift+n" = "new_os_window";
      
      # Pane splitting
      "ctrl+shift+minus" = "launch --location=hsplit";
      "ctrl+shift+backslash" = "launch --location=vsplit";
    };
  };
}
