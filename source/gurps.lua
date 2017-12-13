function valued_trait(value, points)
  return {
    value=value,
    points=points or "?"
  }
end

function trait(points)
  return {
    points=points or "?"
  }
end

function vantage(points)
  return {
    points=points or "?"
  }
end

function base_stat(stat, multiplier, default)
  default = default or 10
  stat = stat or default
  multiplier = multiplier or 10
  return valued_trait(stat, (stat - default)*multiplier)
end

function create_character(args)
  -- Creates a character
  local args = args or {}
  local c = {}
  c.base = {
    ST=base_stat(args.ST),
    DX=base_stat(args.DX, 20),
    IQ=base_stat(args.IQ, 20),
    HT=base_stat(args.HT),
  }
  c.base.HP = valued_trait(c.base.ST.value, 0)
  c.base.Per = valued_trait(c.base.IQ.value, 0)
  c.base.Will = valued_trait(c.base.IQ.value, 0)
  c.base.FP = valued_trait(c.base.HT.value, 0)

  c.advantages = {}
  c.disadvantages = {}
  c.skills = {}
  c.spells = {}
  c.attacks = {}

  return c
end

character = create_character()


function count_points()
  running_total = 0
  -- for i,base_stat in pairs(base_stats) do
  --   running_total = running_total + character[base_stat].points
  -- end
  for i,traits in pairs({"base",
                         "advantages",
                         "disadvantages",
                         "skills",
                         "spells"}) do
    for j,v in pairs(character[traits]) do
      if v.points ~= "?" then
        running_total = running_total + v.points
      end
    end
  end
  return running_total
end


function print_little_section(title, tbl)
  tex.print([[\paragraph{]] .. title .. [[}]])

  local x = {}
  for k,v in pairs(tbl) do
    if v.value == nil then
      table.insert(x, k .. "[" .. v.points .. "]")
    else
      table.insert(x, k .. "~" .. v.value .. "[" .. v.points .. "]")
    end
  end

  if next(tbl) == nil then
    table.insert(x, [[\ldots{}]])
  end
  tex.print(table.concat(x, ", ") .. ".")
end


base_stats = {
  "ST", "DX", "IQ", "HT", "HP", "Per", "Will", "FP"
}


function print_character()
  tex.print([[\subsubsection{Stats (]] .. count_points() .. [[~pt)}]])
  tex.print([[\paragraph{Base stats}]])
  local x = {}
  for i, base_stat in ipairs(base_stats) do
    local obj = character.base[base_stat]
    table.insert(
      x,
      base_stat .. [[~]] .. obj.value
        .. "[" .. obj.points .. "]")
  end
  tex.print(table.concat(x, ", ") .. ".")

  print_little_section("Advantages", character.advantages)
  print_little_section("Disadvantages", character.disadvantages)
  print_little_section("Skills", character.skills)
  if next(character.spells) then
    print_little_section("Spells", character.spells)
  end
end

function print_character_as_lens()
  tex.print([[\subsubsection{Lens (+]] .. count_points() .. [[~pt)}]])
  tex.print([[\paragraph{Base stats}]])
  local x = {}
  for i, base_stat in ipairs(base_stats) do
    local obj = character.base[base_stat]
    if obj.value ~= 10 then
      table.insert(
        x,
        base_stat .. [[~+]] .. obj.value - 10
          .. "[" .. obj.points .. "]")
    end
  end
  tex.print(table.concat(x, ", ") .. ".")

  if next(character.advantages) ~= nil then
    print_little_section("Advantages", character.advantages)
  end
  if next(character.disadvantages) ~= nil then
    print_little_section("Disadvantages", character.disadvantages)
  end
  if next(character.skills) ~= nil then
    print_little_section("Skills", character.skills)
  end
end


-- for i,v in ipairs(base_stats) do
--   -- \setST[10]{10}
--   tex.print([[\newcommand\set]] 
--       .. v
--       .. [[[1]{\luadirect{print(character.ST) character[]] .. v 
--       .. [[] = base_stat(#1)}}]])


function print_set_cmd(name, extra_args)
  extra_args = extra_args or {"nil"}
  tex.print(
    string.format(
      [[\NewDocumentCommand\set%s{m}]]
        .. [[{\luadirect{character.%s = base_stat(#1, %s)}}]],
      name,
      name,
      table.concat(extra_args, ", ")
    )
  )
end

print_set_cmd("ST")
print_set_cmd("DX", {"20"})
print_set_cmd("IQ", {"20"})
print_set_cmd("HT")
print_set_cmd("HP", {"5", "character.ST.value"})
print_set_cmd("Per", {"5", "character.IQ.value"})
print_set_cmd("Will", {"5", "character.IQ.value"})
print_set_cmd("FP", {"5", "character.HT.value"})

-- tex.print([[\newcommand\setHP[1]{\luadirect{character.setHP = base_stat(#1, 5, character.ST.value)}}]])

--- Splits string (on / by default)
function split(s, split_on)
  local split_on = split_on or [[/]]
  local rettable = {}
  for i in string.gmatch(s, "[^" .. split_on .. "]+") do
    table.insert(rettable, i)
  end
  return rettable
end


function calculate_skill_points(based_on, difficulty, skill_level)
  -- TODO rename this variable
  if difficulty == "Easy" then
    difficulty_modifier = 0
  elseif difficulty == "Average" then
    difficulty_modifier = 1
  elseif difficulty == "Hard" then
    difficulty_modifier = 2
  elseif difficulty == "Very Hard" then
    difficulty_modifier = 3
  elseif difficulty == "Wildcard" then
    return 3*calculate_skill_points(based_on, "Very Hard", skill_level)
  end

  -- TODO make support for non-base stat based_on values
  local relative_level = skill_level - character.base[based_on].value
  if relative_level == (0 - difficulty_modifier) then
    return 1
  elseif relative_level == (1 - difficulty_modifier) then
    return 2
  elseif relative_level == (2 - difficulty_modifier) then
    return 4
  elseif relative_level > (2 - difficulty_modifier) then
    return (relative_level - 1 + difficulty_modifier) * 4
  end
end
