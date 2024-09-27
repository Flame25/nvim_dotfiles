local M = {}

---@type table<string, table<vim.lsp.Client, table<number, boolean>>>
M._supports_method = {}

---@param opts? lsp.Client.filter
function M.get_clients(opts)
	local ret = {} ---@type vim.lsp.Client[]
	if vim.lsp.get_clients then
		ret = vim.lsp.get_clients(opts)
	else
		---@diagnostic disable-next-line: deprecated
		ret = vim.lsp.get_active_clients(opts)
		if opts and opts.method then
			---@param client vim.lsp.Client
			ret = vim.tbl_filter(function(client)
				return client.supports_method(opts.method, { bufnr = opts.bufnr })
			end, ret)
		end
	end
	return opts and opts.filter and vim.tbl_filter(opts.filter, ret) or ret
end

---@param opts? LazyFormatter| {filter?: (string|lsp.Client.filter)}
function M.formatter(opts)
	opts = opts or {}
	local filter = opts.filter or {}
	filter = type(filter) == "string" and { name = filter } or filter
	---@cast filter lsp.Client.filter
	---@type LazyFormatter
	local ret = {
		name = "LSP",
		primary = true,
		priority = 1,
		format = function(buf)
			M.format(PotatoVim.merge({}, filter, { bufnr = buf }))
		end,
		sources = function(buf)
			local clients = M.get_clients(PotatoVim.merge({}, filter, { bufnr = buf }))
			---@param client vim.lsp.Client
			local ret = vim.tbl_filter(function(client)
				return client.supports_method("textDocument/formatting")
					or client.supports_method("textDocument/rangeFormatting")
			end, clients)
			---@param client vim.lsp.Client
			return vim.tbl_map(function(client)
				return client.name
			end, ret)
		end,
	}
	return PotatoVim.merge(ret, opts) --[[@as LazyFormatter]]
end

---@alias LspWord {from:{[1]:number, [2]:number}, to:{[1]:number, [2]:number}} 1-0 indexed
M.words = {}
M.words.enabled = false
M.words.ns = vim.api.nvim_create_namespace("vim_lsp_references")

--@param opts? {enabled?: boolean}
function M.words.setup(opts)
	opts = opts or {}
	if not opts.enabled then
		return
	end
	M.words.enabled = true
	local handler = vim.lsp.handlers["textDocument/documentHighlight"]
	vim.lsp.handlers["textDocument/documentHighlight"] = function(err, result, ctx, config)
		if not vim.api.nvim_buf_is_loaded(ctx.bufnr) then
			return
		end
		vim.lsp.buf.clear_references()
		return handler(err, result, ctx, config)
	end

	M.on_supports_method("textDocument/documentHighlight", function(_, buf)
		vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI", "CursorMoved", "CursorMovedI" }, {
			group = vim.api.nvim_create_augroup("lsp_word_" .. buf, { clear = true }),
			buffer = buf,
			callback = function(ev)
				if not require("lazyvim.plugins.lsp.keymaps").has(buf, "documentHighlight") then
					return false
				end

				if not ({ M.words.get() })[2] then
					if ev.event:find("CursorMoved") then
						vim.lsp.buf.clear_references()
					elseif not PotatoVim.cmp.visible() then
						vim.lsp.buf.document_highlight()
					end
				end
			end,
		})
	end)
end

---@param fn fun(client:vim.lsp.Client, buffer):boolean?
---@param opts? {group?: integer}
function M.on_dynamic_capability(fn, opts)
	return vim.api.nvim_create_autocmd("User", {
		pattern = "LspDynamicCapability",
		group = opts and opts.group or nil,
		callback = function(args)
			local client = vim.lsp.get_client_by_id(args.data.client_id)
			local buffer = args.data.buffer ---@type number
			if client then
				return fn(client, buffer)
			end
		end,
	})
end

M.words = {}
M.words.enabled = false
M.words.ns = vim.api.nvim_create_namespace("vim_lsp_references")

---@param opts? {enabled?: boolean}
function M.words.setup(opts)
	opts = opts or {}
	if not opts.enabled then
		return
	end
	M.words.enabled = true
	local handler = vim.lsp.handlers["textDocument/documentHighlight"]
	vim.lsp.handlers["textDocument/documentHighlight"] = function(err, result, ctx, config)
		if not vim.api.nvim_buf_is_loaded(ctx.bufnr) then
			return
		end
		vim.lsp.buf.clear_references()
		return handler(err, result, ctx, config)
	end

	M.on_supports_method("textDocument/documentHighlight", function(_, buf)
		vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI", "CursorMoved", "CursorMovedI" }, {
			group = vim.api.nvim_create_augroup("lsp_word_" .. buf, { clear = true }),
			buffer = buf,
			callback = function(ev)
				if not require("lazyvim.plugins.lsp.keymaps").has(buf, "documentHighlight") then
					return false
				end

				if not ({ M.words.get() })[2] then
					if ev.event:find("CursorMoved") then
						vim.lsp.buf.clear_references()
					elseif not PotatoVim.cmp.visible() then
						vim.lsp.buf.document_highlight()
					end
				end
			end,
		})
	end)
end

---@param method string
---@param fn fun(client:vim.lsp.Client, buffer)
function M.on_supports_method(method, fn)
	M._supports_method[method] = M._supports_method[method] or setmetatable({}, { __mode = "k" })
	return vim.api.nvim_create_autocmd("User", {
		pattern = "LspSupportsMethod",
		callback = function(args)
			local client = vim.lsp.get_client_by_id(args.data.client_id)
			local buffer = args.data.buffer ---@type number
			if client and method == args.data.method then
				return fn(client, buffer)
			end
		end,
	})
end

function M.is_enabled(server)
	local c = M.get_config(server)
	return c and c.enabled ~= false
end

--@param server string
---@param cond fun( root_dir, config): boolean
function M.disable(server, cond)
	local util = require("lspconfig.util")
	local def = M.get_config(server)
	---@diagnostic disable-next-line: undefined-field
	def.document_config.on_new_config = util.add_hook_before(
		def.document_config.on_new_config,
		function(config, root_dir)
			if cond(root_dir, config) then
				config.enabled = false
			end
		end
	)
end

---@param on_attach fun(client:vim.lsp.Client, buffer)
---@param name? string
function M.on_attach(on_attach, name)
	return vim.api.nvim_create_autocmd("LspAttach", {
		callback = function(args)
			local buffer = args.buf ---@type number
			local client = vim.lsp.get_client_by_id(args.data.client_id)
			if client and (not name or client.name == name) then
				return on_attach(client, buffer)
			end
		end,
	})
end

function M.setup()
	M.health()

	-- Autoformat autocmd
	vim.api.nvim_create_autocmd("BufWritePre", {
		group = vim.api.nvim_create_augroup("LazyFormat", {}),
		callback = function(event)
			M.format({ buf = event.buf })
		end,
	})

	-- Manual format
	vim.api.nvim_create_user_command("LazyFormat", function()
		M.format({ force = true })
	end, { desc = "Format selection or buffer" })

	-- Format info
	vim.api.nvim_create_user_command("LazyFormatInfo", function()
		M.info()
	end, { desc = "Show info about the formatters for the current buffer" })
end

function M.health()
	local Config = require("lazy.core.config")
	local has_plugin = Config.spec.plugins["none-ls.nvim"]
	local has_extra = vim.tbl_contains(Config.spec.modules, "lazyvim.plugins.extras.lsp.none-ls")
	if has_plugin and not has_extra then
		PotatoVim.warn({
			"`conform.nvim` and `nvim-lint` are now the default formatters and linters in LazyVim.",
			"",
			"You can use those plugins together with `none-ls.nvim`,",
			"but you need to enable the `lazyvim.plugins.extras.lsp.none-ls` extra,",
			"for formatting to work correctly.",
			"",
			"In case you no longer want to use `none-ls.nvim`, just remove the spec from your config.",
		})
	end
end

---@return _.lspconfig.options
function M.get_config(server)
	local configs = require("lspconfig.configs")
	return rawget(configs, server)
end

function M.is_enabled(server)
	local c = M.get_config(server)
	return c and c.enabled ~= false
end

---@param opts? lsp.Client.format
function M.format(opts)
	opts = vim.tbl_deep_extend(
		"force",
		{},
		opts or {},
		PotatoVim.opts("nvim-lspconfig").format or {},
		PotatoVim.opts("conform.nvim").format or {}
	)
	local ok, conform = pcall(require, "conform")
	-- use conform for formatting with LSP when available,
	-- since it has better format diffing
	if ok then
		opts.formatters = {}
		conform.format(opts)
	else
		vim.lsp.buf.format(opts)
	end
end

function M.rename_file()
	local buf = vim.api.nvim_get_current_buf()
	local old = assert(PotatoVim.root.realpath(vim.api.nvim_buf_get_name(buf)))
	local root = assert(PotatoVim.root.realpath(PotatoVim.root.get({ normalize = true })))
	assert(old:find(root, 1, true) == 1, "File not in project root")

	local extra = old:sub(#root + 2)

	vim.ui.input({
		prompt = "New File Name: ",
		default = extra,
		completion = "file",
	}, function(new)
		if not new or new == "" or new == extra then
			return
		end
		new = PotatoVim.norm(root .. "/" .. new)
		vim.fn.mkdir(vim.fs.dirname(new), "p")
		M.on_rename(old, new, function()
			vim.fn.rename(old, new)
			vim.cmd.edit(new)
			vim.api.nvim_buf_delete(buf, { force = true })
			vim.fn.delete(old)
		end)
	end)
end

---@param count number
---@param cycle? boolean
function M.words.jump(count, cycle)
	local words, idx = M.words.get()
	if not idx then
		return
	end
	idx = idx + count
	if cycle then
		idx = (idx - 1) % #words + 1
	end
	local target = words[idx]
	if target then
		vim.api.nvim_win_set_cursor(0, target.from)
	end
end

M.action = setmetatable({}, {
	__index = function(_, action)
		return function()
			vim.lsp.buf.code_action({
				apply = true,
				context = {
					only = { action },
					diagnostics = {},
				},
			})
		end
	end,
})

return M
