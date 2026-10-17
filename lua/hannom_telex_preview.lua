-- Render automatic Vietnamese syllable boundaries in preedit while keeping
-- the full letter run available to Rime's Han-Nom and phrase lookup.
local enter = require("hannom_telex_enter")

local M = {}

function M.init(env)
  env.syllables = enter.load_syllables()
end

local function source_for(context, input)
  local source = context:get_property("_hannom_telex_case_input")
  if not source or #source ~= #input then return input end
  return source
end

local function needs_leading_space(context, position, input)
  local composition = context.composition
  if not composition then return false end
  local segmentation = composition:toSegmentation()
  if not segmentation then return false end

  local last_visible
  for i = 0, (segmentation.size or 0) - 1 do
    local previous = segmentation:get_at(i)
    if previous and previous._end <= position
        and previous._end > previous.start
        and not previous:has_tag("phony") then
      last_visible = previous
    end
  end
  if not last_visible
      or (last_visible.status ~= "kSelected" and last_visible.status ~= "kConfirmed") then
    return false
  end

  local candidate = last_visible:get_selected_candidate()
  local visible = candidate and candidate.text
    or input:sub(last_visible.start + 1, last_visible._end)
  return not visible:match("%s$")
end

local function is_telex_run(raw)
  return raw:match("^[A-Za-z ']+$") ~= nil and raw:match("[A-Za-z]") ~= nil
end

function M.func(input, segment, env)
  if segment.status == "kSelected" or segment.status == "kConfirmed" then return end

  local context = env.engine.context
  local full_input = context.input or input or ""
  local raw = full_input:sub(segment.start + 1, segment._end)
  if raw == "" then return end

  local source = source_for(context, full_input)
  local source_span = source:sub(segment.start + 1, segment._end)
  local text

  if segment:has_tag("hannom_punctuation") then
    text = raw
    if enter.punctuation_needs_space(raw) and segment._end < #full_input then
      -- The delimiter space is phony in Rime, so carry it on the punctuation
      -- preview candidate to keep the visible preedit and Return in sync.
      text = text .. " "
    end
  elseif segment:has_tag("hannom_raw") then
    text = source_span
  else
    text = enter.convert_input(raw, source_span, env.syllables)
  end
  if not text then return end

  if not segment:has_tag("hannom_punctuation") and is_telex_run(raw) then
    local next_char = full_input:sub(segment._end + 1, segment._end + 1)
    if next_char == " " or next_char == "'" then
      text = text .. " "
    end
    if needs_leading_space(context, segment.start, full_input) then
      text = " " .. text
    end
  end

  local candidate = Candidate("hannom_preview", segment.start, segment._end, text, "")
  candidate.preedit = text
  if segment:has_tag("hannom_punctuation") then
    candidate.quality = 1000000000
  elseif segment._end < #full_input then
    -- Rime builds preedit for a completed, non-final segment from its default
    -- candidate text. Make the Vietnamese fallback that default so the Han
    -- glyphs stay in the candidate menu until explicitly selected.
    candidate.quality = 1000000000
  else
    -- Keep Han-Nom and phrase candidates ahead of the Vietnamese fallback.
    candidate.quality = -1000000
  end
  yield(candidate)
end

function M.tags_match(segment)
  return segment:has_tag("abc")
      or segment:has_tag("hannom_auto")
      or segment:has_tag("hannom_live")
      or segment:has_tag("hannom_raw")
      or segment:has_tag("hannom_punctuation")
end

return M
