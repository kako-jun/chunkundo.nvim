local M = {}

function M.check()
  vim.health.start("chunkundo.nvim")

  -- Check Neovim version
  if vim.fn.has("nvim-0.10") == 1 then
    vim.health.ok("Neovim >= 0.10")
  else
    vim.health.error("Neovim >= 0.10 is required")
  end

  -- Check chillout.nvim dependency
  local chillout_ok, chillout = pcall(require, "chillout")
  if chillout_ok then
    vim.health.ok("chillout.nvim is installed")
    -- Check that required functions exist
    local has_debounce = type(chillout.debounce) == "function"
    local has_throttle = type(chillout.throttle) == "function"
    local has_batch = type(chillout.batch) == "function"
    if has_debounce and has_throttle and has_batch then
      vim.health.ok("chillout.nvim has debounce, throttle, and batch")
    else
      local missing = {}
      if not has_debounce then
        table.insert(missing, "debounce")
      end
      if not has_throttle then
        table.insert(missing, "throttle")
      end
      if not has_batch then
        table.insert(missing, "batch")
      end
      vim.health.error("chillout.nvim is missing: " .. table.concat(missing, ", "))
    end
  else
    vim.health.error("chillout.nvim is not installed", {
      "Install chillout.nvim: https://github.com/kako-jun/chillout.nvim",
      'lazy.nvim: { "kako-jun/chillout.nvim" }',
    })
  end

  -- Check if setup() has been called
  local chunkundo_ok, chunkundo = pcall(require, "chunkundo")
  if chunkundo_ok then
    if chunkundo.is_setup_done() then
      vim.health.ok("chunkundo.setup() has been called")
      local status = chunkundo.is_enabled() and "enabled" or "disabled"
      vim.health.info("Current status: " .. status)
      vim.health.info("Effective interval: " .. chunkundo.get_effective_interval() .. "ms")
      vim.health.info("Auto-adjust: " .. (chunkundo.is_auto_adjust_enabled() and "on" or "off"))
    else
      vim.health.warn("chunkundo.setup() may not have been called yet", {
        'Add require("chunkundo").setup() to your config',
      })
    end
  end
end

return M
