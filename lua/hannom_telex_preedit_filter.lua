-- Change only the active candidate's preedit field. Its Han-Nom text and
-- ranking stay intact, while the composition shows the Vietnamese spelling.
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

local function should_convert(raw)
  return (raw:match("^[A-Za-z ']+$") ~= nil and raw:match("[A-Za-z]") ~= nil)
      or (raw:match("^%p$") ~= nil and raw ~= "'" and raw ~= "`")
end

function M.func(translation, env)
  local context = env.engine.context
  local input = context.input or ""
  local source = source_for(context, input)

  for candidate in translation:iter() do
    local raw = input:sub(candidate.start + 1, candidate._end)
    if candidate.type == "hannom_preview" or not should_convert(raw) then
      yield(candidate)
    else
      local source_span = source:sub(candidate.start + 1, candidate._end)
      local preedit = enter.convert_input(raw, source_span, env.syllables)
      if not preedit then
        yield(candidate)
      else
        if raw:match("^[A-Za-z ']+$") and raw:match("[A-Za-z]") then
          if needs_leading_space(context, candidate.start, input) then
            preedit = " " .. preedit
          end
          local next_char = input:sub(candidate._end + 1, candidate._end + 1)
          if next_char == " " or next_char == "'" then
            preedit = preedit .. " "
          end
        elseif enter.punctuation_needs_space(raw) and candidate._end < #input then
          preedit = preedit .. " "
        end

        local adjusted = Candidate(candidate.type, candidate.start, candidate._end,
            candidate.text, candidate.comment)
        adjusted.quality = candidate.quality
        adjusted.preedit = preedit
        yield(adjusted)
      end
    end
  end
end

return M
