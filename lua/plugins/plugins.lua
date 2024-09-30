return {
	-- Mason Plugin
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup({
				ui = {
					icons = {
						package_installed = "✓",
						package_pending = "➜",
						package_uninstalled = "✗",
					},
				},
			})
		end,
	},

	-- Mason LSPconfig Plugin
	{
		"williamboman/mason-lspconfig.nvim",
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = { "lua_ls" }, -- Automatically install these tools
			})
		end,
	},
	-- Neotree
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		opt = true,
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
			"MunifTanjim/nui.nvim",
			-- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
		},
		keys = {
			{
				"<leader>fE",
				function()
					require("neo-tree.command").execute({ toggle = true, dir = vim.uv.cwd() })
				end,
				desc = "Explorer NeoTree (cwd)",
			},

			{
				"<leader>fe",
				function()
					require("neo-tree.command").execute({ toggle = true, dir = PotatoVim.root() })
				end,
				desc = "Explorer NeoTree (root)",
			},
		},
		opts = {
			sources = { "filesystem", "buffers", "git_status" },
			open_files_do_not_replace_types = { "terminal", "Trouble", "trouble", "qf", "Outline" },
			filesystem = {
				bind_to_cwd = false,
				follow_current_file = { enabled = true },
				use_libuv_file_watcher = true,
				statusline = false,
			},
			window = {
				mappings = {
					["l"] = "open",
					["h"] = "close_node",
					["<space>"] = "none",
					["Y"] = {
						function(state)
							local node = state.tree:get_node()
							local path = node:get_id()
							vim.fn.setreg("+", path, "c")
						end,
						desc = "Copy Path to Clipboard",
					},
				},
			},
		},
	},
	-- Catcapuccin
	{ "catppuccin/nvim",      name = "catppuccin", priority = 1000 },
	-- LSP Config
	{ "neovim/nvim-lspconfig" },
	-- Dashboard
	{
		"nvimdev/dashboard-nvim",
		event = "VimEnter",
		config = function()
			require("dashboard").setup({
				theme = "hyper",
				config = {
					week_header = {
						enable = true,
					},
					shortcut = {
						{ desc = "󰊳 Update", group = "@property", action = "Lazy update", key = "u" },
						{
							icon = " ",
							icon_hl = "@variable",
							desc = "Files",
							group = "Label",
							action = "Telescope find_files",
							key = "f",
						},
						{
							desc = " Apps",
							group = "DiagnosticHint",
							action = "Telescope app",
							key = "a",
						},
						{
							desc = " dotfiles",
							group = "Number",
							action = "Telescope dotfiles",
							key = "d",
						},
					},
				},
			})
		end,
		dependencies = { { "nvim-tree/nvim-web-devicons" } },
	},
	-- Lualine
	{

		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		init = function()
			vim.g.lualine_laststatus = vim.o.laststatus
			if vim.fn.argc(-1) > 0 then
				-- set an empty statusline till lualine loads
				vim.o.statusline = " "
			else
				-- hide the statusline on the starter page
				vim.o.laststatus = 0
			end
		end,
		opts = function()
			-- PERF: we don't need this lualine require madness 🤷
			local lualine_require = require("lualine_require")
			lualine_require.require = require

			local icons = PotatoVim.config.icons

			vim.o.laststatus = 3 -- Make sure it's a global status line (so work both for neotree and buffer)

			local opts = {
				options = {
					theme = "auto",
					globalstatus = vim.o.laststatus == 3,
					disabled_filetypes = { statusline = { "dashboard", "alpha", "ministarter" } },
				},
				sections = {
					lualine_a = { "mode" },
					lualine_b = { "branch" },

					lualine_c = {
						PotatoVim.lualine.root_dir(),
						{
							"diagnostics",
							symbols = {
								error = icons.diagnostics.Error,
								warn = icons.diagnostics.Warn,
								info = icons.diagnostics.Info,
								hint = icons.diagnostics.Hint,
							},
						},
						{
							"filetype",
							icon_only = true,
							separator = "",
							padding = { left = 1, right = 0 },
						},
						{ PotatoVim.lualine.pretty_path() },
					},
					lualine_x = {
						-- stylua: ignore
						{
							function() return require("noice").api.status.command.get() end,
							cond = function() return package.loaded["noice"] and require("noice").api.status.command.has() end,
							color = function() return PotatoVim.ui.fg("Statement") end,
						},
						-- stylua: ignore
						{
							function() return require("noice").api.status.mode.get() end,
							cond = function() return package.loaded["noice"] and require("noice").api.status.mode.has() end,
							color = function() return PotatoVim.ui.fg("Constant") end,
						},
						-- stylua: ignore
						{
							function() return "  " .. require("dap").status() end,
							cond = function() return package.loaded["dap"] and require("dap").status() ~= "" end,
							color = function() return PotatoVim.ui.fg("Debug") end,
						},
						-- stylua: ignore
						{
							require("lazy.status").updates,
							cond = require("lazy.status").has_updates,
							color = function() return PotatoVim.ui.fg("Special") end,
						},
						{
							"diff",
							symbols = {
								added = icons.git.added,
								modified = icons.git.modified,
								removed = icons.git.removed,
							},
							source = function()
								local gitsigns = vim.b.gitsigns_status_dict
								if gitsigns then
									return {
										added = gitsigns.added,
										modified = gitsigns.changed,
										removed = gitsigns.removed,
									}
								end
							end,
						},
					},
					lualine_y = {
						{ "progress", separator = " ",                  padding = { left = 1, right = 0 } },
						{ "location", padding = { left = 0, right = 1 } },
					},
					lualine_z = {
						function()
							return " " .. os.date("%R")
						end,
					},
				},
				extensions = { "neo-tree", "lazy" },
			}

			-- do not add trouble symbols if aerial is enabled
			-- And allow it to be overriden for some buffer types (see autocmds)
			if vim.g.trouble_lualine and PotatoVim.has("trouble.nvim") then
				local trouble = require("trouble")
				local symbols = trouble.statusline({
					mode = "symbols",
					groups = {},
					title = false,
					filter = { range = true },
					format = "{kind_icon}{symbol.name:Normal}",
					hl_group = "lualine_c_normal",
				})
				table.insert(opts.sections.lualine_c, {
					symbols and symbols.get,
					cond = function()
						return vim.b.trouble_lualine ~= false and symbols.has()
					end,
				})
			end

			return opts
		end,
	},
	-- Whichkey
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts_extend = { "spec" },
		opts = {
			-- your configuration comes here
			-- or leave it empty to use the default settings
			-- refer to the configuration section below
			spec = {
				mode = { "n", "v" },
				{ "<leader><tab>", group = "tabs" },
				{ "<leader>c", group = "code" },
				{ "<leader>f", group = "file/find" },
				{ "<leader>g", group = "git" },
				{ "<leader>gh", group = "hunks" },
				{ "<leader>q", group = "quit/session" },
				{ "<leader>s", group = "search" },
				{ "<leader>u", group = "ui", icon = { icon = "󰙵 ", color = "cyan" } },
				{ "<leader>x", group = "diagnostics/quickfix", icon = { icon = "󱖫 ", color = "green" } },
				{
					"<leader>b",
					group = "buffer",
					expand = function()
						return require("which-key.extras").expand.buf()
					end,
				},
				{ "<leader>ut", icon = { icon = "󰵆", color = "blue" } },
			},
		},
		keys = {
			{
				"<leader>?",
				function()
					require("which-key").show({ global = false })
				end,
				desc = "Buffer Local Keymaps (which-key)",
			},
		},
	},
	-- Nvim-Notify
	{
		"rcarriga/nvim-notify",
		keys = {
			{
				"<leader>un",
				function()
					require("notify").dismiss({ silent = true, pending = true })
				end,
				desc = "Dismiss All Notifications",
			},
		},
		opts = {
			stages = "static",
			timeout = 3000,
			max_height = function()
				return math.floor(vim.o.lines * 0.75)
			end,
			max_width = function()
				return math.floor(vim.o.columns * 0.75)
			end,
			on_open = function(win)
				vim.api.nvim_win_set_config(win, { zindex = 100 })
			end,
		},
	},
	-- Telescope
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		dependencies = { "nvim-lua/plenary.nvim" },
		cmd = "Telescope",
	},
	-- Telescope Commandline
	{
		{
			"nvim-telescope/telescope.nvim",
			tag = "0.1.5",
			dependencies = {
				"nvim-lua/plenary.nvim",
			},
			opts = {
				extensions = {
					cmdline = {},
				},
			},
			config = function(_, opts)
				require("telescope").setup(opts)
			end,
		},
	},
	{
		"folke/trouble.nvim",
		opts = {}, -- for default options, refer to the configuration section for custom setup.
		cmd = "Trouble",
		keys = {
			{
				"<leader>xx",
				"<cmd>Trouble diagnostics toggle<cr>",
				desc = "Diagnostics (Trouble)",
			},
			{
				"<leader>xX",
				"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
				desc = "Buffer Diagnostics (Trouble)",
			},
			{
				"<leader>cs",
				"<cmd>Trouble symbols toggle focus=false<cr>",
				desc = "Symbols (Trouble)",
			},
			{
				"<leader>cl",
				"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
				desc = "LSP Definitions / references / ... (Trouble)",
			},
			{
				"<leader>xL",
				"<cmd>Trouble loclist toggle<cr>",
				desc = "Location List (Trouble)",
			},
			{
				"<leader>xQ",
				"<cmd>Trouble qflist toggle<cr>",
				desc = "Quickfix List (Trouble)",
			},
		},
	},
	-- Persistence
	{
		"folke/persistence.nvim",
		event = "BufReadPre",
		opts = {},
		-- stylua: ignore
		keys = {
			{ "<leader>qs", function() require("persistence").load() end,                desc = "Restore Session" },
			{ "<leader>qS", function() require("persistence").select() end,              desc = "Select Session" },
			{ "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
			{ "<leader>qd", function() require("persistence").stop() end,                desc = "Don't Save Current Session" },
		},
	},
	-- Tokyonight
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		opts = {},
	},

	-- Mini.Pairs
	{
		"echasnovski/mini.pairs",
		event = "VeryLazy",
		opts = {
			modes = { insert = true, command = true, terminal = false },
			-- skip autopair when next character is one of these
			skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
			-- skip autopair when the cursor is inside these treesitter nodes
			skip_ts = { "string" },
			-- skip autopair when next character is closing pair
			-- and there are more closing pairs than opening pairs
			skip_unbalanced = true,
			-- better deal with markdown code blocks
			markdown = true,
		},
	},

	-- Noice
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		opts = {
			lsp = {
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.stylize_markdown"] = true,
					["cmp.entry.get_documentation"] = true,
				},
			},
			routes = {
				{
					filter = {
						event = "msg_show",
						any = {
							{ find = "%d+L, %d+B" },
							{ find = "; after #%d+" },
							{ find = "; before #%d+" },
						},
					},
					view = "mini",
				},
			},
			presets = {
				bottom_search = true,
				command_palette = true,
				long_message_to_split = true,
			},
		},
		-- stylua: ignore
		keys = {
			{ "<leader>sn",  "",                                                                            desc = "+noice" },
			{ "<S-Enter>",   function() require("noice").redirect(vim.fn.getcmdline()) end,                 mode = "c",                              desc = "Redirect Cmdline" },
			{ "<leader>snl", function() require("noice").cmd("last") end,                                   desc = "Noice Last Message" },
			{ "<leader>snh", function() require("noice").cmd("history") end,                                desc = "Noice History" },
			{ "<leader>sna", function() require("noice").cmd("all") end,                                    desc = "Noice All" },
			{ "<leader>snd", function() require("noice").cmd("dismiss") end,                                desc = "Dismiss All" },
			{ "<leader>snt", function() require("noice").cmd("pick") end,                                   desc = "Noice Picker (Telescope/FzfLua)" },
			{ "<c-f>",       function() if not require("noice.lsp").scroll(4) then return "<c-f>" end end,  silent = true,                           expr = true,              desc = "Scroll Forward",  mode = { "i", "n", "s" } },
			{ "<c-b>",       function() if not require("noice.lsp").scroll(-4) then return "<c-b>" end end, silent = true,                           expr = true,              desc = "Scroll Backward", mode = { "i", "n", "s" } },
		},
		config = function(_, opts)
			-- HACK: noice shows messages from before it was enabled,
			-- but this is not ideal when Lazy is installing plugins,
			-- so clear the messages in this case.
			if vim.o.filetype == "lazy" then
				vim.cmd([[messages clear]])
			end
			require("noice").setup(opts)
		end,
	},

	{
		"lukas-reineke/indent-blankline.nvim",
		opts = function()
			return {
				indent = {
					char = "│",
					tab_char = "│",
				},
				scope = { show_start = false, show_end = false },
				exclude = {
					filetypes = {
						"help",
						"alpha",
						"dashboard",
						"neo-tree",
						"Trouble",
						"trouble",
						"lazy",
						"mason",
						"notify",
						"toggleterm",
						"lazyterm",
					},
				},
			}
		end,
		main = "ibl",
	},

	{
		"folke/todo-comments.nvim",
		cmd = { "TodoTrouble", "TodoTelescope" },
		opts = {},
		-- stylua: ignore
		keys = {
			{ "]t",         function() require("todo-comments").jump_next() end,              desc = "Next Todo Comment" },
			{ "[t",         function() require("todo-comments").jump_prev() end,              desc = "Previous Todo Comment" },
			{ "<leader>xt", "<cmd>Trouble todo toggle<cr>",                                   desc = "Todo (Trouble)" },
			{ "<leader>xT", "<cmd>Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}<cr>", desc = "Todo/Fix/Fixme (Trouble)" },
			{ "<leader>st", "<cmd>TodoTelescope<cr>",                                         desc = "Todo" },
			{ "<leader>sT", "<cmd>TodoTelescope keywords=TODO,FIX,FIXME<cr>",                 desc = "Todo/Fix/Fixme" },
		},
	},
	{ "MunifTanjim/nui.nvim", lazy = true },

	{
		"akinsho/bufferline.nvim",
		event = "VeryLazy",
		keys = {
			{ "<leader>bp", "<Cmd>BufferLineTogglePin<CR>",            desc = "Toggle Pin" },
			{ "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete Non-Pinned Buffers" },
			{ "<leader>bo", "<Cmd>BufferLineCloseOthers<CR>",          desc = "Delete Other Buffers" },
			{ "<leader>br", "<Cmd>BufferLineCloseRight<CR>",           desc = "Delete Buffers to the Right" },
			{ "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>",            desc = "Delete Buffers to the Left" },
			{ "<S-h>",      "<cmd>BufferLineCyclePrev<cr>",            desc = "Prev Buffer" },
			{ "<S-l>",      "<cmd>BufferLineCycleNext<cr>",            desc = "Next Buffer" },
			{ "[b",         "<cmd>BufferLineCyclePrev<cr>",            desc = "Prev Buffer" },
			{ "]b",         "<cmd>BufferLineCycleNext<cr>",            desc = "Next Buffer" },
			{ "[B",         "<cmd>BufferLineMovePrev<cr>",             desc = "Move buffer prev" },
			{ "]B",         "<cmd>BufferLineMoveNext<cr>",             desc = "Move buffer next" },
		},
		opts = {
			options = {
				-- stylua: ignore
				close_command = function(n) PotatoVim.ui.bufremove(n) end,
				-- stylua: ignore
				right_mouse_command = function(n) PotatoVim.ui.bufremove(n) end,
				diagnostics = "nvim_lsp",
				always_show_bufferline = false,
				diagnostics_indicator = function(_, _, diag)
					local icons = PotatoVim.config.icons.diagnostics
					local ret = (diag.error and icons.Error .. diag.error .. " " or "")
							.. (diag.warning and icons.Warn .. diag.warning or "")
					return vim.trim(ret)
				end,
				offsets = {
					{
						filetype = "neo-tree",
						text = "Neo-tree",
						highlight = "Directory",
						text_align = "left",
					},
				},
				---@param opts bufferline.IconFetcherOpts
				get_element_icon = function(opts)
					return PotatoVim.config.icons.ft[opts.filetype]
				end,
			},
		},
		config = function(_, opts)
			require("bufferline").setup(opts)
			-- Fix bufferline when restoring a session
			vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
				callback = function()
					vim.schedule(function()
						pcall(nvim_bufferline)
					end)
				end,
			})
		end,
	},
	{
		"zaldih/themery.nvim",
		event = "VeryLazy",
		config = function()
			-- Minimal config
			require("themery").setup({
				themes = { "catppuccin-latte", "catppuccin-frappe", "catppuccin-macchiato", "catppuccin-mocha" }, -- Your list of installed colorschemes.
				livePreview = true,                                                                           -- Apply theme while picking. Default to true.
			})
		end,
	},
}
