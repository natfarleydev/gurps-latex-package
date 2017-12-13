function print_dice(dice_no, modifier)
  tex.sprint([[\mbox{]])
  tex.sprint(dice_no .. "d")

  -- If `modifier` is a valid number
  local modifier_number = tonumber(modifier)
  if modifier_number then
    if modifier_number > 0 then
      tex.sprint("+" .. modifier_number)
    elseif modifier_number < 0 then
      tex.sprint("-" .. modifier_number)
    -- else, don't print anything
    end
  -- elseif `modifier` is non-nil
  elseif modifier then
    tex.sprint("+" .. modifier)
  end
  tex.sprint("}")
end

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

function base_stat(stat, multiplier, default)
  default = default or 10
  stat = stat or default
  multiplier = multiplier or 10
  return valued_trait(stat, (stat - default)*multiplier)
end

-- Creates an attack table.
function attack(stat, damage, based_on)
  rettable = {
    stat=stat or "?",
    damage=damage or "?",
    based_on=based_on or "?"
  }

  -- i.e. if it's based on a real stat and that stat is a skill
  if based_on ~= "?" and character.skills[based_on] then
    rettable.adjustment = character.skills[based_on] - stat
  elseif based_on ~= "?" and character.spells[based_on] then
    rettable.adjustment = character.spells[based_on] - stat
  end

  return rettable
end

function create_character(args)
  -- Creates a character
  local args = args or {}
  local c = {}
  c.base_stats = {
    ST=base_stat(args.ST),
    DX=base_stat(args.DX, 20),
    IQ=base_stat(args.IQ, 20),
    HT=base_stat(args.HT),
  }
  c.base_stats.HP = valued_trait(c.base_stats.ST.value, 0)
  c.base_stats.Per = valued_trait(c.base_stats.IQ.value, 0)
  c.base_stats.Will = valued_trait(c.base_stats.IQ.value, 0)
  c.base_stats.FP = valued_trait(c.base_stats.HT.value, 0)

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
  for i,traits in pairs({"base_stats",
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
    local obj = character.base_stats[base_stat]
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
    local obj = character.base_stats[base_stat]
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
  if next(character.spells) ~= nil then
    print_little_section("Spells", character.spells)
  end
end


-- Creates a new LaTeX command
-- 
-- TODO move this to the dtx file because that's where documentation for LaTeX
-- files lives
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
print_set_cmd("HP", {"5", "character.base_stats.ST.value"})
print_set_cmd("Per", {"5", "character.base_stats.IQ.value"})
print_set_cmd("Will", {"5", "character.base_stats.IQ.value"})
print_set_cmd("FP", {"5", "character.base_stats.HT.value"})

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
  local relative_level = skill_level - character.base_stats[based_on].value
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
