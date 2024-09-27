local M = {}
function M.map(lhs, toggle)
	local t = M.wrap(toggle)
	PotatoVim.safe_keymap_set("n", lhs, function()
		t()
	end, { desc = "Toggle " .. toggle.name })
	M.wk(lhs, toggle)
end

return M
