-- Minimal init for tests
local plugin_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
vim.opt.runtimepath:prepend(plugin_dir)

-- Add chillout.nvim (assumed to be sibling directory or in packpath)
local parent_dir = vim.fn.fnamemodify(plugin_dir, ":h")
local chillout_dir = parent_dir .. "/chillout.nvim"
if vim.fn.isdirectory(chillout_dir) == 1 then
  vim.opt.runtimepath:prepend(chillout_dir)
end

vim.opt.swapfile = false
vim.cmd("runtime plugin/plenary.vim")
