local modules = {} -- Table to store loaded module
require("config.lazy")

local function load_lua_files_from(folder)
	local lua_files = vim.fn.glob(folder .. "/**/*.lua", true, true)

	for _, file in ipairs(lua_files) do
		local relative_path = file:gsub(vim.fn.stdpath("config") .. "/lua/", ""):gsub("%.lua$", ""):gsub("/", ".")

		local ok, mod_or_err = pcall(require, relative_path)
		if ok then
			modules[relative_path] = mod_or_err -- Store the loaded module
		else
			vim.api.nvim_err_writeln("Error loading " .. relative_path .. ": " .. mod_or_err)
		end
	end
end

local plugins_path = vim.fn.stdpath("config") .. "/lua/config"
load_lua_files_from(plugins_path)
