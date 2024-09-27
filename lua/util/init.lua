local LazyUtil = require("lazy.core.util")
local M = {}

---@type table<string, string|string[]>
local deprecated = {
	get_clients = "lsp",
	on_attach = "lsp",
	on_rename = "lsp",
	root_patterns = { "root", "patterns" },
	get_root = { "root", "get" },
	float_term = { "terminal", "open" },
	toggle_diagnostics = { "toggle", "diagnostics" },
	toggle_number = { "toggle", "number" },
	fg = "ui",
	telescope = "pick",
}

function M.is_loaded(name)
	local Config = require("lazy.core.config")
	return Config.plugins[name] and Config.plugins[name]._.loaded
end

setmetatable(M, {
	__index = function(t, k)
		if LazyUtil[k] then
			return LazyUtil[k]
		end
		local dep = deprecated[k]
		if dep then
			local mod = type(dep) == "table" and dep[1] or dep
			local key = type(dep) == "table" and dep[2] or k
			M.deprecate([[LazyVim.]] .. k, [[LazyVim.]] .. mod .. "." .. key)
			---@diagnostic disable-next-line: no-unknown
			t[mod] = require("util." .. mod) -- load here to prevent loops
			return t[mod][key]
		end
		---@diagnostic disable-next-line: no-unknown
		t[k] = require("util." .. k)
		return t[k]
	end,
})

function M.is_win()
	return vim.uv.os_uname().sysname:find("Windows") ~= nil
end

function M.deprecate(old, new)
	M.warn(("`%s` is deprecated. Please use `%s` instead"):format(old, new), {
		title = "LazyVim",
		once = true,
		stacktrace = true,
		stacklevel = 6,
	})
end

function M.norm(path)
	-- Ensure path uses forward slashes
	path = path:gsub("\\", "/")

	-- Remove redundant segments
	local normalized_path = vim.fn.resolve(path)

	-- Optionally check if the path exists
	if vim.loop.fs_stat(normalized_path) then
		return normalized_path
	else
		return nil -- or some error handling
	end
end

---@param fn fun()
function M.on_very_potato(fn)
	vim.api.nvim_create_autocmd("User", {
		pattern = "VeryPotato",
		callback = function()
			fn()
		end,
	})
end

---@param plugin string
function M.has(plugin)
	return M.get_plugin(plugin) ~= nil
end

function M.safe_keymap_set(mode, lhs, rhs, opts)
	local keys = require("lazy.core.handler").handlers.keys
	---@cast keys LazyKeysHandler
	local modes = type(mode) == "string" and { mode } or mode

	---@param m string
	modes = vim.tbl_filter(function(m)
		return not (keys.have and keys:have(lhs, m))
	end, modes)

	-- do not create the keymap if a lazy keys handler exists
	if #modes > 0 then
		opts = opts or {}
		opts.silent = opts.silent ~= false
		if opts.remap and not vim.g.vscode then
			---@diagnostic disable-next-line: no-unknown
			opts.remap = nil
		end
		vim.keymap.set(modes, lhs, rhs, opts)
	end
end

function M.opts(name)
	local plugin = M.get_plugin(name)
	if not plugin then
		return {}
	end
	local Plugin = require("lazy.core.plugin")
	return Plugin.values(plugin, "opts", false)
end

---@param name string
function M.get_plugin(name)
	return require("lazy.core.config").spec.plugins[name]
end

---@param name string
---@param path string?
function M.get_plugin_path(name, path)
	local plugin = M.get_plugin(name)
	path = path and "/" .. path or ""
	return plugin and (plugin.dir .. path)
end

---@generic T
---@param list T[]
---@return T[]
function M.dedup(list)
	local ret = {}
	local seen = {}
	for _, v in ipairs(list) do
		if not seen[v] then
			table.insert(ret, v)
			seen[v] = true
		end
	end
	return ret
end

M.CREATE_UNDO = vim.api.nvim_replace_termcodes("<c-G>u", true, true, true)
function M.create_undo()
	if vim.api.nvim_get_mode().mode == "i" then
		vim.api.nvim_feedkeys(M.CREATE_UNDO, "n", false)
	end
end

return M
