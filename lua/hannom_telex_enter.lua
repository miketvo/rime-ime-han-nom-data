-- Convert unspaced Telex input to Vietnamese syllables when Return is pressed.
-- The lookup is frequency-ranked; explicit Rime delimiters remain word boundaries.
local M = {}

local function insert(root, code, text, rank)
  local node = root
  for i = 1, #code do
    local ch = code:sub(i, i)
    node.next = node.next or {}
    node.next[ch] = node.next[ch] or {}
    node = node.next[ch]
  end
  node.values = node.values or {}
  for _, value in ipairs(node.values) do
    if value.text == text then
      if rank < value.rank then value.rank = rank end
      return
    end
  end
  node.values[#node.values + 1] = { text = text, rank = rank }
end

local function load_syllables()
  local root = {}
  local path = rime_api.get_user_data_dir() .. "/lua/hannom-telex-syllables.tsv"
  local file = io.open(path, "r")
  if not file then return root end
  for line in file:lines() do
    if line:sub(1, 1) ~= "#" then
      local code, text, rank = line:match("^([a-z]+)\t([^\t]+)\t(%d+)$")
      if code and text and rank then
        insert(root, code, text, tonumber(rank))
      end
    end
  end
  file:close()
  return root
end

local tone_letters = {
  s = {"á", "ắ", "ấ", "é", "ế", "í", "ó", "ố", "ớ", "ú", "ứ", "ý"},
  f = {"à", "ằ", "ầ", "è", "ề", "ì", "ò", "ồ", "ờ", "ù", "ừ", "ỳ"},
  r = {"ả", "ẳ", "ẩ", "ẻ", "ể", "ỉ", "ỏ", "ổ", "ở", "ủ", "ử", "ỷ"},
  x = {"ã", "ẵ", "ẫ", "ẽ", "ễ", "ĩ", "õ", "ỗ", "ỡ", "ũ", "ữ", "ỹ"},
  j = {"ạ", "ặ", "ậ", "ẹ", "ệ", "ị", "ọ", "ộ", "ợ", "ụ", "ự", "ỵ"}
}

local function normalize_code(input)
  local code = input:lower():gsub("uwow", "uow")
  -- Accept a tone key inside a vowel sequence, such as maaxu -> maaux.
  code = code:gsub("([aeiouy])([sfjxr])([aeiouy])", "%1%3%2")
  -- Move a tone key placed after the vowel and before a coda to the
  -- dictionary's whole-syllable position. This must run on one syllable at a time.
  local codas = {"ng", "nh", "ch", "m", "n", "p", "t", "c"}
  for _, coda in ipairs(codas) do
    code = code:gsub("([aeiouyw])([sfjxr])" .. coda, "%1" .. coda .. "%2")
  end
  return code
end

local function tone_key_for_code(code)
  local tone
  for i = 1, #code do
    local char = code:sub(i, i)
    if char:match("^[sfjxr]$") and code:sub(1, i - 1):match("[aeiouy]") then
      tone = char
    end
  end
  return tone
end

local function tone_key_for_text(text)
  for key, letters in pairs(tone_letters) do
    for _, letter in ipairs(letters) do
      if text:find(letter, 1, true) then return key end
    end
  end
  return nil
end

local function tone_matches(code, text)
  return tone_key_for_code(code) == tone_key_for_text(text)
end

local function segment_chunk(input, trie)
  -- Normalize each candidate syllable separately. Normalizing the whole
  -- unspaced phrase can mistake a tone before the next syllable's onset for
  -- a tone placed before the current syllable's coda (for example, lafcon...).
  local code = input:lower()
  local n = #code
  local best = {}
  best[n + 1] = { cost = 0, syllables = {} }
  for i = n, 1, -1 do
    for j = i, n do
      -- Accept ươ typed as uw + ow as well as the canonical uow spelling.
      local syllable_code = normalize_code(code:sub(i, j))
      local node = trie
      for k = 1, #syllable_code do
        node = node.next and node.next[syllable_code:sub(k, k)]
        if not node then break end
      end
      if node and node.values and best[j + 1] then
        for _, value in ipairs(node.values) do
          if tone_matches(syllable_code, value.text) then
            local cost = math.log(value.rank) + best[j + 1].cost + 0.2
            if not best[i] or cost < best[i].cost then
              local syllables = {{
                text = value.text,
                start = i,
                finish = j
              }}
              for _, syllable in ipairs(best[j + 1].syllables) do
                syllables[#syllables + 1] = syllable
              end
              best[i] = {
                cost = cost,
                syllables = syllables
              }
            end
          end
        end
      end
    end
  end
  return best[1] and best[1].syllables or nil
end

-- Shared with the live segmentor so the preedit and Return use the same
-- frequency-ranked syllable split.
M.load_syllables = load_syllables
M.segment_chunk = segment_chunk

local lowercase_to_uppercase

local function capitalize_first(text)
  local first_byte = text:byte(1)
  if not first_byte then return text end
  local length = first_byte < 0x80 and 1
    or (first_byte < 0xe0 and 2 or (first_byte < 0xf0 and 3 or 4))
  local first = text:sub(1, length)
  local uppercase = lowercase_to_uppercase[first] or first:upper()
  return uppercase .. text:sub(length + 1)
end

lowercase_to_uppercase = {
  a = "A", b = "B", c = "C", d = "D", e = "E", f = "F", g = "G",
  h = "H", i = "I", j = "J", k = "K", l = "L", m = "M", n = "N",
  o = "O", p = "P", q = "Q", r = "R", s = "S", t = "T", u = "U",
  v = "V", w = "W", x = "X", y = "Y", z = "Z",
  ["á"] = "Á", ["à"] = "À", ["ả"] = "Ả", ["ã"] = "Ã", ["ạ"] = "Ạ",
  ["ă"] = "Ă", ["ắ"] = "Ắ", ["ằ"] = "Ằ", ["ẳ"] = "Ẳ", ["ẵ"] = "Ẵ", ["ặ"] = "Ặ",
  ["â"] = "Â", ["ấ"] = "Ấ", ["ầ"] = "Ầ", ["ẩ"] = "Ẩ", ["ẫ"] = "Ẫ", ["ậ"] = "Ậ",
  ["é"] = "É", ["è"] = "È", ["ẻ"] = "Ẻ", ["ẽ"] = "Ẽ", ["ẹ"] = "Ẹ",
  ["ê"] = "Ê", ["ế"] = "Ế", ["ề"] = "Ề", ["ể"] = "Ể", ["ễ"] = "Ễ", ["ệ"] = "Ệ",
  ["í"] = "Í", ["ì"] = "Ì", ["ỉ"] = "Ỉ", ["ĩ"] = "Ĩ", ["ị"] = "Ị",
  ["ó"] = "Ó", ["ò"] = "Ò", ["ỏ"] = "Ỏ", ["õ"] = "Õ", ["ọ"] = "Ọ",
  ["ô"] = "Ô", ["ố"] = "Ố", ["ồ"] = "Ồ", ["ổ"] = "Ổ", ["ỗ"] = "Ỗ", ["ộ"] = "Ộ",
  ["ơ"] = "Ơ", ["ớ"] = "Ớ", ["ờ"] = "Ờ", ["ở"] = "Ở", ["ỡ"] = "Ỡ", ["ợ"] = "Ợ",
  ["ú"] = "Ú", ["ù"] = "Ù", ["ủ"] = "Ủ", ["ũ"] = "Ũ", ["ụ"] = "Ụ",
  ["ư"] = "Ư", ["ứ"] = "Ứ", ["ừ"] = "Ừ", ["ử"] = "Ử", ["ữ"] = "Ữ", ["ự"] = "Ự",
  ["ý"] = "Ý", ["ỳ"] = "Ỳ", ["ỷ"] = "Ỷ", ["ỹ"] = "Ỹ", ["ỵ"] = "Ỵ",
  ["đ"] = "Đ"
}

local function uppercase_vietnamese(text)
  for lowercase, uppercase in pairs(lowercase_to_uppercase) do
    text = text:gsub(lowercase, function() return uppercase end)
  end
  return text
end

local function apply_case(text, source)
  local letters = source:gsub("[^A-Za-z]", "")
  if letters:match("^[A-Z]+$") then return uppercase_vietnamese(text) end
  -- A shifted tone/shape key can make a title-cased Telex syllable mixed-case
  -- (for example, an uppercase initial followed by an uppercase tone key).
  -- Keep the word's uppercase initial instead of dropping all case information.
  if letters:match("^[A-Z]") then return capitalize_first(text) end
  return text
end

M.apply_case = apply_case

local function punctuation_needs_space(char)
  return char == "," or char == "." or char == "?" or char == "!"
      or char == ":" or char == ";" or char == ")" or char == "]"
      or char == "}" or char == "%" or char == '"'
end

M.punctuation_needs_space = punctuation_needs_space

local incomplete_onsets = {
  b = true, c = true, ch = true, d = true, dd = true,
  g = true, gh = true, gi = true, h = true, k = true, kh = true,
  l = true, m = true, n = true, ng = true, ngh = true, nh = true,
  p = true, ph = true, q = true, qu = true, r = true, s = true,
  t = true, th = true, tr = true, v = true, x = true
}

local function split_trailing_onset(token, trie)
  -- Keep an incomplete next-word onset out of the preceding syllable. The
  -- current run may fail whole-string segmentation while its prefix is valid.
  for cut = #token - 1, math.max(1, #token - 3), -1 do
    local tail = token:sub(cut + 1):lower()
    if incomplete_onsets[tail] then
      local prefix = segment_chunk(token:sub(1, cut), trie)
      if prefix then return prefix, cut end
    end
  end
  return nil
end

local function convert_input(input, source, trie)
  input = input or ""
  source = source or input
  if #source ~= #input then source = input end

  local output = {}
  local function append(text)
    if text and text ~= "" then output[#output + 1] = text end
  end

  local i = 1
  while i <= #input do
    local char = input:sub(i, i)
    if char:match("[A-Za-z]") then
      local finish = i
      while finish <= #input and input:sub(finish, finish):match("[A-Za-z]") do
        finish = finish + 1
      end
      local token = input:sub(i, finish - 1)
      local source_token = source:sub(i, finish - 1)
      local converted = segment_chunk(token, trie)
      local incomplete_cut
      if not converted then
        converted, incomplete_cut = split_trailing_onset(token, trie)
      end
      -- Keep unknown names and loanwords intact. If only a trailing onset is
      -- incomplete, retain the already recognized syllables and show that
      -- onset separately until more input arrives.
      if converted then
        for index, syllable in ipairs(converted) do
          if index > 1 then append(" ") end
          local typed_syllable = source_token:sub(syllable.start, syllable.finish)
          append(apply_case(syllable.text, typed_syllable))
        end
        if incomplete_cut then
          append(" ")
          local tail = source_token:sub(incomplete_cut + 1)
          if token:sub(incomplete_cut + 1):lower() == "dd" then
            append(apply_case("đ", tail))
          else
            append(tail)
          end
        end
      elseif token:lower() == "dd" then
        -- `dd` is a valid Telex letter transformation even before a vowel is
        -- typed, so show đ/Đ while the syllable is still incomplete.
        append(apply_case("đ", source_token))
      else
        append(source_token)
      end
      i = finish
    elseif char:match("^%p$") and char ~= "'" then
      append(char)
      local next_pos = i + 1
      if punctuation_needs_space(char) then
        while input:sub(next_pos, next_pos) == " " do
          next_pos = next_pos + 1
        end
        -- Phrase-ending punctuation is followed by one space when another
        -- character follows, or when the user explicitly typed a space.
        if next_pos > i + 1 or next_pos <= #input then append(" ") end
        i = next_pos
      else
        i = i + 1
      end
    elseif char == "'" then
      if #output > 0 and output[#output] ~= " " then append(" ") end
      i = i + 1
    elseif char == " " then
      if #output > 0 and output[#output] ~= " " then append(" ") end
      repeat i = i + 1 until input:sub(i, i) ~= " "
    else
      append(char)
      i = i + 1
    end
  end
  if #output == 0 then return nil end
  return table.concat(output)
end

M.convert_input = convert_input

local function typed_ascii_char(key)
  if key:release() or key:ctrl() or key:alt() or key:super() then return nil end
  local code = key.keycode
  if code >= string.byte("A") and code <= string.byte("Z") then
    return string.char(code), true
  end
  if code >= string.byte("a") and code <= string.byte("z") then
    local uppercase = key:shift() ~= key:caps()
    local char = string.char(code)
    return uppercase and char:upper() or char, uppercase
  end
  if code >= 32 and code <= 126 then
    return string.char(code), false
  end
  return nil
end

local function sync_case_input(env, context)
  context:set_property("_hannom_telex_case_input", env.case_input or "")
end

local function case_source(context, input, fallback)
  local source = context:get_property("_hannom_telex_case_input")
  if not source or #source ~= #input then source = fallback or input end
  if #source ~= #input then source = input end
  return source
end

local function composition_state(context, input)
  local composition = context.composition
  if not composition then return false, false end
  local segmentation = composition:toSegmentation()
  if not segmentation then return false, false end

  local has_selection = false
  local all_selected = true
  local covered = 0
  for i = 0, (segmentation.size or 0) - 1 do
    local segment = segmentation:get_at(i)
    if segment and segment._end > segment.start then
      local selected = segment.status == "kSelected" or segment.status == "kConfirmed"
      if selected then
        has_selection = true
      else
        all_selected = false
      end
      if segment._end > covered then covered = segment._end end
    end
  end
  if covered < #input then all_selected = false end
  return has_selection, all_selected
end

function M.init(env)
  env.syllables = load_syllables()
  env.case_input = ""
end

function M.func(key, env)
  local repr = key:repr()
  local context = env.engine.context

  if repr == "Return" or repr == "KP_Enter" then
    if context:get_option("ascii_mode") or not context:is_composing() then return 2 end
    local input = context.input or ""
    local source = case_source(context, input, env.case_input or input)
    local has_selection, all_selected = composition_state(context, input)
    local result
    if has_selection and all_selected then
      result = context:get_commit_text()
    elseif has_selection then
      local preedit = context:get_preedit()
      result = preedit and preedit.text or nil
    else
      local preedit = context:get_preedit()
      result = preedit and preedit.text or nil
      if not result or result == "" then
        result = convert_input(input, source, env.syllables)
      end
    end
    if not result then return 2 end
    env.engine:commit_text(result)
    context:clear()
    env.case_input = ""
    sync_case_input(env, context)
    return 1
  end

  if context:get_option("ascii_mode") then return 2 end

  local char, uppercase = typed_ascii_char(key)
  if char then
    local input = context.input or ""
    if not context:is_composing() then env.case_input = "" end
    if char ~= " " and enter.punctuation_needs_space(input:sub(-1))
        and context.caret_pos == #input then
      context:push_input(" ")
      env.case_input = (env.case_input or "") .. " "
    end
    env.case_input = (env.case_input or "") .. char
    sync_case_input(env, context)
    if char:match("^[A-Za-z]$") then
      -- Let ascii_composer retain normal Shift behavior and pass the letter to
      -- the speller's generated uppercase aliases.
      return 2
    end
  elseif repr == "BackSpace" and env.case_input then
    env.case_input = env.case_input:sub(1, -2)
    sync_case_input(env, context)
  elseif repr == "Escape" then
    env.case_input = ""
    sync_case_input(env, context)
  end

  return 2
end

return M
