-- Preserve confirmed user selections and keep each unconfirmed alphabet run
-- intact for dictionary/phrase lookup. Vietnamese syllable splitting belongs
-- in the candidate preedit; splitting Rime's segment here limits lookup to the
-- final syllable and drops phrase context.
local M = {}

function M.init(env)
  env.last_input = nil
end

local function add_segment(segmentation, start, finish, tags)
  local segment = Segment(start, finish)
  segment.tags = Set(tags)
  segmentation:add_segment(segment)
end

local function is_selected(segment)
  return segment.status == "kSelected" or segment.status == "kConfirmed"
end

local function retain_selected_prefix(segmentation, old_input, input)
  local keep = 0
  for i = 0, (segmentation.size or 0) - 1 do
    local segment = segmentation:get_at(i)
    if not segment or not is_selected(segment) or segment._end > #input then
      break
    end
    if old_input
        and old_input:sub(segment.start + 1, segment._end)
          ~= input:sub(segment.start + 1, segment._end) then
      break
    end
    keep = keep + 1
  end
  segmentation:reset_length(keep)
end

function M.func(segmentation, env)
  local context = env.engine.context
  if context:get_option("ascii_mode") then return true end

  local input = segmentation.input or ""
  local context_input = context.input or ""
  -- Keep cursor editing under Rime's normal segmentor behavior.
  if context.caret_pos ~= #context_input then return true end

  if env.last_input ~= input then
    retain_selected_prefix(segmentation, env.last_input, input)
    env.last_input = input
  end

  local start = segmentation:get_current_start_position()
  local suffix = input:sub(start + 1)
  if suffix == "" then return true end

  local char = suffix:sub(1, 1)
  if char:match("^%p$") and char ~= "`" and char ~= "'" then
    -- A separate punctuation segment keeps the mark in the composition. The
    -- preview translator adds the following space when appropriate.
    add_segment(segmentation, start, start + 1, {"abc", "hannom_auto", "hannom_punctuation"})
    return false
  end

  if char:match("^%s$") or char == "'" then
    -- Skip a leading delimiter by itself. If it is grouped with the following
    -- letters, the translator sees a spelling that begins with a separator
    -- and can lose the first letter's candidates. Internal delimiters stay
    -- inside the full lookup span below.
    add_segment(segmentation, start, start + 1, {"phony"})
    return false
  end

  local phrase = suffix:match("^([A-Za-z ']+)")
  if phrase and phrase:match("[A-Za-z]") then
    -- Keep manually delimited syllables in the same lookup segment. The
    -- delimiter guides Vietnamese preview parsing but must not hide the
    -- preceding code from Han-Nom and phrase lookup.
    add_segment(segmentation, start, start + #phrase, {"abc"})
    return false
  end

  return true
end

return M
