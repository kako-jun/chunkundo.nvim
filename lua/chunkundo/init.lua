-- chunkundo.nvim
-- Batch consecutive edits into single undo units
-- Inspired by Chunk from The Goonies - "Hey Chunk, calm down!"

local M = {}

local chillout_ok, chillout = pcall(require, "chillout")
if not chillout_ok then
  error("chunkundo.nvim requires chillout.nvim: https://github.com/kako-jun/chillout.nvim")
end

local config = {
  enabled = true, -- enable chunking on startup

  -- Time-based chunking
  interval = 300, -- ms to wait before breaking undo sequence
  max_chunk_time = 10000, -- ms before forced chunk break (even while typing)
  auto_adjust = true, -- automatically adjust interval based on typing pattern

  -- Character-based chunking
  break_on_space = true, -- break chunk on space, tab, and enter
  break_on_punct = false, -- break chunk on punctuation (.,?!;:)
}

local state = {
  debounced_break = nil, -- chillout debounce function
  throttled_statusline = nil, -- chillout throttle function for statusline
  batched_pauses = nil, -- chillout batch for collecting pause durations
  chunk_size = 0, -- current chunk edit count
  last_chunk_size = 0, -- last confirmed chunk size
  cached_statusline = "u", -- cached statusline value
  last_edit_time = nil, -- timestamp of last TextChangedI for measuring pause
  learned_interval = nil, -- learned optimal interval from user's typing pattern
  last_break_char = nil, -- last character that triggered a break (for consecutive detection)
}

-- Debug flag (set to true to enable debug output)
local DEBUG = true

local function debug_print(msg)
  if DEBUG then
    vim.schedule(function()
      print("[chunkundo] " .. msg)
    end)
  end
end

-- Analyze collected pause durations to find optimal interval
-- Note: pauses comes from chillout.batch as {{duration1}, {duration2}, ...}
local function analyze_pause_pattern(pauses)
  if #pauses < 3 then
    return nil
  end

  -- Extract pause durations from batch format
  local durations = {}
  for _, item in ipairs(pauses) do
    local duration = item[1]
    -- Filter reasonable pauses (not too short, not distractions)
    if duration >= 100 and duration < 5000 then
      table.insert(durations, duration)
    end
  end

  if #durations < 3 then
    return nil
  end

  -- Sort and find median (more robust than average)
  table.sort(durations)
  local median_idx = math.floor(#durations / 2)
  local median_pause = durations[median_idx]

  -- Use 80% of median as the interval (break just before typical pause ends)
  local suggested = math.floor(median_pause * 0.8)

  -- Clamp to reasonable range
  return math.max(100, math.min(2000, suggested))
end

-- Check if character should trigger a chunk break
local function should_break_on_char(char)
  if config.break_on_space and (char == " " or char == "\t" or char == "\r" or char == "\n") then
    return true
  end
  if config.break_on_punct and char:match("[.,?!;:]") then
    return true
  end
  return false
end

-- Called BEFORE each character insert (InsertCharPre)
-- Used for character-based chunk breaking
local function on_insert_char_pre()
  if not config.enabled then
    return
  end

  local char = vim.v.char
  if should_break_on_char(char) then
    -- Don't break if same break char was pressed consecutively (e.g., multiple spaces)
    if state.last_break_char == char then
      debug_print("skip break (consecutive): " .. (char == " " and "space" or char == "\r" and "enter" or char))
      return
    end

    -- Insert undo break point before this character
    local ctrl_g_u = vim.api.nvim_replace_termcodes("<C-g>u", true, false, true)
    vim.api.nvim_feedkeys(ctrl_g_u, "n", false)
    state.last_break_char = char
    if state.chunk_size > 0 then
      state.last_chunk_size = state.chunk_size
      state.chunk_size = 0
    end
    debug_print("break on char: " .. (char == " " and "space" or char == "\r" and "enter" or char))
  else
    -- Non-break character clears the last break char
    state.last_break_char = nil
  end
end

-- Called when debounce timer fires (via chillout.debounce)
-- Insert an undo break point using CTRL-G u
local function on_debounce_timeout()
  -- Only break if we're still in insert mode and have edits
  if vim.fn.mode() ~= "i" then
    return
  end

  if state.chunk_size > 0 then
    state.last_chunk_size = state.chunk_size
    state.chunk_size = 0
    -- Insert undo break point (CTRL-G u breaks undo sequence in insert mode)
    local ctrl_g_u = vim.api.nvim_replace_termcodes("<C-g>u", true, false, true)
    vim.api.nvim_feedkeys(ctrl_g_u, "n", false)
    debug_print("chunk confirmed: " .. state.last_chunk_size .. " edits, inserted <C-g>u")
  end
end

-- Called AFTER text change in insert mode (TextChangedI)
local function on_text_changed()
  if not config.enabled then
    return
  end

  local now = vim.uv.hrtime() / 1e6 -- Convert to milliseconds

  -- Record pause duration for learning (time since last edit)
  if state.last_edit_time and config.auto_adjust and state.batched_pauses then
    local pause = now - state.last_edit_time
    -- Only collect meaningful pauses (debounce interval or longer)
    if pause >= M.get_effective_interval() then
      state.batched_pauses(pause)
      debug_print("collected pause: " .. math.floor(pause) .. "ms")
    end
  end
  state.last_edit_time = now

  state.chunk_size = state.chunk_size + 1
  debug_print("TextChangedI: chunk_size=" .. state.chunk_size)

  -- Reset the debounce timer - will fire after interval of no typing
  if state.debounced_break then
    state.debounced_break()
  end
end

-- Called when leaving insert mode
local function on_insert_leave()
  if state.chunk_size > 0 then
    state.last_chunk_size = state.chunk_size
  end
  state.chunk_size = 0
  state.last_break_char = nil -- Reset for next insert session
  debug_print("InsertLeave: chunk confirmed")
end

local augroup = nil

function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})

  -- Create debounced break function using chillout
  -- maxWait ensures chunks are broken even during continuous typing
  state.debounced_break = chillout.debounce(on_debounce_timeout, config.interval, {
    maxWait = config.max_chunk_time,
  })

  -- Create throttled statusline update function
  -- Limits statusline recalculation to once per 100ms for performance
  state.throttled_statusline = chillout.throttle(function()
    if not config.enabled then
      state.cached_statusline = "u-"
    elseif state.chunk_size > 0 then
      state.cached_statusline = "u+" .. state.chunk_size
    elseif state.last_chunk_size > 0 then
      state.cached_statusline = "u=" .. state.last_chunk_size
    else
      state.cached_statusline = "u"
    end
  end, 100)

  -- Create batched pause collector for learning typing patterns
  -- Fires after 3 pauses are collected (maxSize), not by time
  state.batched_pauses = chillout.batch(function(pauses)
    if not config.auto_adjust then
      return
    end

    local suggested = analyze_pause_pattern(pauses)
    if suggested then
      local alpha = 0.3 -- weight for new value (exponential moving average)
      local new_interval
      if state.learned_interval then
        -- Blend with previous learned value
        new_interval = math.floor(state.learned_interval * (1 - alpha) + suggested * alpha)
      else
        -- First learning: use suggested directly
        new_interval = suggested
      end

      -- Only update if changed significantly (> 10ms difference)
      if not state.learned_interval or math.abs(new_interval - state.learned_interval) > 10 then
        state.learned_interval = new_interval
        -- Update debounce with learned interval
        state.debounced_break = chillout.debounce(on_debounce_timeout, new_interval, {
          maxWait = config.max_chunk_time,
        })
        debug_print("Learned interval: " .. new_interval .. "ms (suggested: " .. suggested .. "ms)")
      end
    end
  end, nil, { maxSize = 3 }) -- 3 pauses trigger learning (no time-based flush)

  -- Set up autocommands
  if augroup then
    vim.api.nvim_del_augroup_by_id(augroup)
  end
  augroup = vim.api.nvim_create_augroup("chunkundo", { clear = true })

  vim.api.nvim_create_autocmd("InsertCharPre", {
    group = augroup,
    callback = on_insert_char_pre,
  })

  vim.api.nvim_create_autocmd("TextChangedI", {
    group = augroup,
    callback = on_text_changed,
  })

  vim.api.nvim_create_autocmd("InsertLeave", {
    group = augroup,
    callback = on_insert_leave,
  })
end

function M.enable()
  config.enabled = true
end

function M.disable()
  config.enabled = false
end

function M.toggle()
  if config.enabled then
    M.disable()
  else
    M.enable()
  end
end

function M.is_enabled()
  return config.enabled
end

function M.status()
  local status = config.enabled and "enabled" or "disabled"
  vim.notify("chunkundo: " .. status, vim.log.levels.INFO)
end

-- Statusline component
-- Returns: "u+5" (growing), "u=12" (confirmed), "u-" (disabled)
-- Uses throttled update for performance
function M.statusline()
  if state.throttled_statusline then
    state.throttled_statusline()
  end
  return state.cached_statusline
end

-- Interval adjustment API
function M.get_interval()
  return config.interval
end

function M.set_interval(ms)
  config.interval = math.max(50, ms) -- minimum 50ms
  state.learned_interval = nil -- Clear learned interval when manually set
  -- Recreate debounced function with new interval
  state.debounced_break = chillout.debounce(on_debounce_timeout, config.interval, {
    maxWait = config.max_chunk_time,
  })
end

-- Get the current effective interval (learned or configured)
function M.get_effective_interval()
  return state.learned_interval or config.interval
end

-- Auto-adjust API
function M.enable_auto_adjust()
  config.auto_adjust = true
end

function M.disable_auto_adjust()
  config.auto_adjust = false
  state.learned_interval = nil
  -- Reset to configured interval
  state.debounced_break = chillout.debounce(on_debounce_timeout, config.interval, {
    maxWait = config.max_chunk_time,
  })
end

function M.is_auto_adjust_enabled()
  return config.auto_adjust
end

-- Statusline visibility
local show_statusline = true

function M.show_statusline()
  show_statusline = true
end

function M.hide_statusline()
  show_statusline = false
end

function M.toggle_statusline()
  show_statusline = not show_statusline
end

-- Wrap statusline to respect visibility
local function statusline_wrapper()
  if not show_statusline then
    return ""
  end
  return M.statusline()
end

-- Export wrapper for lualine
M.statusline_component = statusline_wrapper

-- Create user command
vim.api.nvim_create_user_command("ChunkUndo", function(opts)
  local args = vim.split(opts.args, "%s+")
  local subcmd = args[1]

  if subcmd == "enable" then
    M.enable()
    vim.notify("chunkundo: enabled", vim.log.levels.INFO)
  elseif subcmd == "disable" then
    M.disable()
    vim.notify("chunkundo: disabled", vim.log.levels.INFO)
  elseif subcmd == "toggle" then
    M.toggle()
    vim.notify("chunkundo: " .. (config.enabled and "enabled" or "disabled"), vim.log.levels.INFO)
  elseif subcmd == "status" then
    M.status()
  elseif subcmd == "show" then
    M.show_statusline()
    vim.notify("chunkundo: statusline shown", vim.log.levels.INFO)
  elseif subcmd == "hide" then
    M.hide_statusline()
    vim.notify("chunkundo: statusline hidden", vim.log.levels.INFO)
  elseif subcmd == "interval" then
    local ms = tonumber(args[2])
    if ms then
      M.set_interval(ms)
      vim.notify("chunkundo: interval set to " .. M.get_interval() .. "ms", vim.log.levels.INFO)
    else
      local effective = M.get_effective_interval()
      local learned = state.learned_interval
      if learned then
        vim.notify(
          string.format("chunkundo: interval %dms (learned), base %dms", effective, config.interval),
          vim.log.levels.INFO
        )
      else
        vim.notify("chunkundo: interval " .. effective .. "ms", vim.log.levels.INFO)
      end
    end
  elseif subcmd == "auto" then
    local action = args[2]
    if action == "on" then
      M.enable_auto_adjust()
      vim.notify("chunkundo: auto-adjust enabled", vim.log.levels.INFO)
    elseif action == "off" then
      M.disable_auto_adjust()
      vim.notify("chunkundo: auto-adjust disabled", vim.log.levels.INFO)
    else
      local status = config.auto_adjust and "on" or "off"
      local learned = state.learned_interval
      if learned then
        vim.notify(string.format("chunkundo: auto-adjust %s (learned: %dms)", status, learned), vim.log.levels.INFO)
      else
        vim.notify("chunkundo: auto-adjust " .. status, vim.log.levels.INFO)
      end
    end
  elseif subcmd == "space" then
    local action = args[2]
    if action == "on" then
      config.break_on_space = true
      vim.notify("chunkundo: break on space/enter enabled", vim.log.levels.INFO)
    elseif action == "off" then
      config.break_on_space = false
      vim.notify("chunkundo: break on space/enter disabled", vim.log.levels.INFO)
    else
      vim.notify("chunkundo: break on space/enter " .. (config.break_on_space and "on" or "off"), vim.log.levels.INFO)
    end
  elseif subcmd == "punct" then
    local action = args[2]
    if action == "on" then
      config.break_on_punct = true
      vim.notify("chunkundo: break on punctuation enabled", vim.log.levels.INFO)
    elseif action == "off" then
      config.break_on_punct = false
      vim.notify("chunkundo: break on punctuation disabled", vim.log.levels.INFO)
    else
      vim.notify("chunkundo: break on punctuation " .. (config.break_on_punct and "on" or "off"), vim.log.levels.INFO)
    end
  else
    vim.notify(
      "ChunkUndo: unknown subcommand. Use: enable, disable, toggle, status, show, hide, interval, auto, space, punct",
      vim.log.levels.ERROR
    )
  end
end, {
  nargs = "+",
  complete = function(arg_lead, cmd_line)
    local args = vim.split(cmd_line, "%s+")
    if #args <= 2 then
      return { "enable", "disable", "toggle", "status", "show", "hide", "interval", "auto", "space", "punct" }
    elseif #args == 3 and (args[2] == "auto" or args[2] == "space" or args[2] == "punct") then
      return { "on", "off" }
    end
    return {}
  end,
})

return M
