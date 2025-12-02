-- Minimal init for tests
-- Get the directory of this file
local this_file = debug.getinfo(1, "S").source:sub(2)
local this_dir = vim.fn.fnamemodify(this_file, ":p:h")
local plugin_dir = vim.fn.fnamemodify(this_dir, ":h")
vim.opt.runtimepath:prepend(plugin_dir)

-- Add chillout.nvim (assumed to be sibling directory or in packpath)
local parent_dir = vim.fn.fnamemodify(plugin_dir, ":h")
local chillout_dir = parent_dir .. "/chillout.nvim"
if vim.fn.isdirectory(chillout_dir) == 1 then
  vim.opt.runtimepath:prepend(chillout_dir)
end

-- Add plenary.nvim for testing
local plenary_paths = {
  vim.fn.stdpath("data") .. "/lazy/plenary.nvim",
  parent_dir .. "/plenary.nvim",
  vim.fn.stdpath("data") .. "/site/pack/packer/start/plenary.nvim",
}
for _, path in ipairs(plenary_paths) do
  if vim.fn.isdirectory(path) == 1 then
    vim.opt.runtimepath:prepend(path)
    break
  end
end

vim.opt.swapfile = false
vim.cmd("runtime plugin/plenary.vim")
