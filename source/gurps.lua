require "gurps_tables"

function thrust_or_swing(typ, st)
  if st < 1 then
    return "0"
  end

  if _GTHRUSTSWINGTABLE[typ][st] then
    return _GTHRUSTSWINGTABLE[typ][st]
  else
    return thrust_or_swing(typ, st - 1)
  end
  -- TODO calculate thr and sw if it's too large for the table
end

function thrust(st)
  return thrust_or_swing("thrust", st)
end

function swing(st)
  return thrust_or_swing("swing", st)
end

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

function valued_trait(name, value, points)
  return {
    name=name,
    value=value,
    points=points or "?"
  }
end

function value(name, value)
  return {
    name=name,
    value=value
  }
end

function trait(name, points)
  return {
    name=name,
    points=points or "?"
  }
end

function base_stat(name, stat, multiplier, default)
  default = default or 10
  stat = stat or default
  multiplier = multiplier or 10
  return valued_trait(name, stat, (stat - default)*multiplier)
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

-- Create HP stat. default can be nil.
function create_hp_stat(value, default)
  return base_stat("HP", value, 2, default)
end

-- Create Per stat. default can be nil.
function create_per_stat(value, default)
  return base_stat("Per", value, 5, default)
end

-- Create Will stat. default can be nil.
function create_will_stat(value, default)
  return base_stat("Will", value, 5, default)
end

-- Create FP stat. default can be nil.
function create_fp_stat(value, default)
  return base_stat("FP", value, 3, default)
end

-- Creates a character
function create_character(args)
  local args = args or {}
  local c = {}

  c.pointless_stats = {}
  c.pointless_stats.DR = value("DR", args.DR or 0)
  c.pointless_stats.SM = value("SM", args.SM or 0)

  c.base_stats = {
    ST=base_stat("ST", args.ST, 10 - c.pointless_stats.SM.value),
    DX=base_stat("DX", args.DX, 20),
    IQ=base_stat("IQ", args.IQ, 20),
    HT=base_stat("HT", args.HT),
  }

  -- Gets the value for a base stat
  function gv(c, key)
    return c.base_stats[key].value
  end
  function calc_basic_speed(character)
    return (gv(c, "DX")+gv(c, "HT"))/4
  end
  function calc_basic_move(character)
    return math.floor(calc_basic_speed(character))
  end
  function calc_dodge(character)
    return math.floor(calc_basic_speed(character) + 3)
  end

  c.pointless_stats.thr = value("thr", thrust(gv(c, "ST")))
  c.pointless_stats.sw = value("sw", swing(gv(c, "ST")))
  c.pointless_stats['Basic Speed'] = base_stat(
    "Basic Speed",
    args['Basic Speed'],
    20,
    calc_basic_speed(c)
  )

value(
    "Basic Speed",
    args['Basic Speed'] or calc_basic_speed(c)
  )
  c.pointless_stats['Basic Move'] = value(
    "Basic Move",
    args['Basic Move'] or calc_basic_move(c)
  )
  c.pointless_stats.Dodge = value("Dodge", args.Dodge or calc_dodge(c))

  c.base_stats.HP = create_hp_stat(args.HP, gv(c, "ST"))
  c.base_stats.Per = create_per_stat(args.Per, gv(c, "IQ"))
  c.base_stats.Will = create_will_stat(args.Will, gv(c, "IQ"))
  c.base_stats.FP = create_fp_stat(args.FP, gv(c, "HT"))

  c.advantages = args.advantages
  c.disadvantages = args.disadvantages

  -- Create skill and spell arrays
  for _,arraytype in ipairs({"skills", "spells"}) do
    c[arraytype] = {}
    for key,obj in pairs(args[arraytype]) do
      if obj.difficulty then
        diff_pair = split(obj.difficulty)
        points = calculate_skill_points(c, diff_pair[1], diff_pair[2], obj.value)
        c[arraytype][key] = valued_trait(obj.name, obj.value, points)
      else
        c[arraytype][key] = valued_trait(obj.name, obj.value)
      end
    end
  end
  c.attacks = {}

  return c
end

-- Count total points in character
function count_points()
  running_total = 0
  for _,traits in ipairs({"base_stats",
                          "advantages",
                          "disadvantages",
                          "skills",
                          "spells",
                          "pointless_stats"}) do
    if character[traits] then
      for j,v in pairs(character[traits]) do
        if v.points ~= "?" and v.points ~= nil then
          running_total = running_total + v.points
        end
      end
    end
  end
  return running_total
end

-- Print a character section in LaTeX
function print_little_section(title, tbl)
  tex.sprint([[\charactersection*{]] .. title .. [[}]])

  local x = {}
  for k,v in pairs(tbl) do
    if v.value == nil then
      table.insert(x, k .. "[" .. v.points .. "]")
    elseif v.points == nil then
        table.insert(x, k .. [[ ]] .. v.value)
    else
      table.insert(x, k .. [[ ]] .. v.value .. "[" .. v.points .. "]")
    end
  end

  if next(tbl) == nil then
    table.insert(x, [[\ldots{}]])
  end

  -- Remove non-alphanumeric characters for sorting
  function compare_only_alphanumeric(a, b)
    return a:gsub('%W', '') < b:gsub('%W', '')
  end

  table.sort(x, compare_only_alphanumeric)

  tex.sprint([[\begin{charactertraitlist}]])
  for i,v in ipairs(x) do
    tex.sprint([[\item ]] .. v)
  end
  tex.sprint([[\end{charactertraitlist}]])
end


base_stats = {
  "ST", "DX", "IQ", "HT", "HP", "Per", "Will", "FP"
}


function print_character()
  -- For some reason, adding these custom commands to the table of contents
  -- breaks LaTeX in ways I don't understand. But since we probably never ever
  -- want to do that, we simply * the new headers and quietly forget about it
  -- ... (:
  --
  -- TODO figure out why the above happens and fix it, for completeness.
  tex.sprint([[\charactertitle*{Stats (]] .. count_points() .. [[~pt)}]])
  tex.sprint([[\charactersection*{Base stats}]])
  local x = {}
  for i, base_stat in ipairs(base_stats) do
    local obj = character.base_stats[base_stat]
    table.insert(
      x,
      base_stat .. [[ ]] .. obj.value
        .. "[" .. obj.points .. "]")
  end
  -- tex.sprint(table.concat(x, ", ") .. ".")
  tex.sprint([[\begin{charactertraitlist}]])
  for i,v in ipairs(x) do
    tex.sprint([[\item ]] .. v)
  end
  tex.sprint([[\end{charactertraitlist}]])

  print_little_section("Other", character.pointless_stats)

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


--- Splits string (on / by default)
function split(s, split_on)
  local split_on = split_on or [[/]]
  local rettable = {}
  for i in string.gmatch(s, "[^" .. split_on .. "]+") do
    table.insert(rettable, i)
  end
  return rettable
end


function calculate_skill_points(character, based_on, difficulty, skill_level)
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
