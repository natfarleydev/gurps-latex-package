-- Defines helpers for character building
--
-- An `attribute` object is defined in the following way:
-- {
-- name: any string,
-- type: "advantage" | "disadvantage" | "skill" | "spell" | "basic_attribute" | "secondary_characteristic" | "attack",
-- level: any positive integer,
-- diceexpr: any string matching [0-9]+d[+-]?[0-9]*
-- basedon: a table matching an attribute (e.g. one only containing name and type)
-- difficulty: "Easy" | "Average" | "Hard" | "Very Hard" | "Wildcard"
-- }

-- Thrust and Swing
-- TODO find out how the lua table serialisation works and use that instead.
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


_GCHARACTERS = {}

function package_error(msg)
  return tex.sprint([[\PackageError{gurps}{]] .. msg .. [[}{}]])
end

-- Creates a new character with that key name
function new_character(character_key)
  _GCHARACTERS[character_key] = {}
end

function get_character(character_key)
  retval = _GCHARACTERS[character_key]
  if retval == nil then
    tex.error("Character '" .. character_key .. "' not found!")
  end
  return retval
end

-- -- Store the character in the global characters table
function set_character(character_key, character)
  _GCHARACTERS[character_key] = character
end

-- TODO assert that I will only access the character via the key interface.
-- Maybe. Decide if this should be the case
--
-- Yes, I do want it that way, because it's the TeX way. Define something and
-- then do something with it

-- insert attribute into a character specified by a key
function insert_attr(character_key, attr)
  table.insert(get_character(character_key), attr)
end

-- Turns an array into a table with identical key/value pairs
function _identity_pairs_tbl(tbl)
  rettbl = {}
  for _,v in ipairs(tbl) do
    rettbl[v] = v
  end

  return rettbl
end

-- Enums for things with allowed values
enums = {}
enums.type = _identity_pairs_tbl({"advantage" ,
                                 "disadvantage" ,
                                 "skill" ,
                                 "spell" ,
                                 "basic_attribute" ,
                                 "secondary_characteristic" ,
                                 "melee_attack",
                                 "ranged_attack",
                                 "property"})
enums.difficulty = {
  easy="Easy",
  average="Average",
  hard="Hard",
  very_hard="Very Hard",
  wildcard="Wildcard",
  notset="NotSet"
}

-- Create a function that returns attr if all key=value pairs match (tbl -> attr
-- direction only)
function tbl_to_filter_pred(tbl)
  return function(attr)
    for k,v in pairs(tbl) do
      if attr[k] ~= v then
        return nil
      end
    end
    return attr
  end
end

function filter(predicate, array)
  if type(predicate) == "table" then
    predicate = tbl_to_filter_pred(predicate)
  end
  ret_array = {}

  if not array then
    tex.error("Array passed to filter is nil...")
  end

  at_least_one_match = false
  for _,v in ipairs(array) do
    if predicate(v) then
      table.insert(ret_array, v)
      at_least_one_match = true
    end
  end

  -- if at_least_one_match has been defined
  if at_least_one_match then
    return ret_array
  else
    return nil
  end
end

function reduce(f, arr)
  retval = arr[1]
  for i=2,#arr,1 do
    retval = f(retval, arr[i])
  end

  return retval
end

function is_valid_attribute(attr)
  return attr.name and attr.type
end

function is_advantage(attr)
  return attr.type == "advantage"
end

function is_disadvantage(attr)
  return attr.type == "disadvantage"
end

function is_skill(attr)
  return attr.type == "skill"
end

function is_spell(attr)
  return attr.type == "spell"
end

function is_basic_attribute(attr)
  return attr.type == "basic_attribute"
end

function is_secondary_characteristic(attr)
  return attr.type == "secondary_characteristic"
end

function is_property(attr)
  return attr.type == "property"
end

function is_melee_attack(attr)
  return attr.type == enums.type.melee_attack
end
function is_ranged_attack(attr)
  return attr.type == enums.type.ranged_attack
end
function is_attack(attr)
  return is_ranged_attack(attr) or is_melee_attack(attr)
end

function is_valid_type(t)
  for k,v in pairs(enums.type) do
    if t == v then
      return v
    end
  end

  return false
end

function is_valid_difficulty(t)
  for k,v in pairs(enums.difficulty) do
    if t == v then
      return v
    end
  end

  return false
end

function is_valid_points(p)
  if tonumber(p) or p == nil or p == "-" then
    return true
  end

  return false
end

function if_else_packageerror(pred, message)
  if pred() then
    return true
  else
    tex.sprint([[\PackageError{gurps}{]] .. message .. [[}{}]])
  end
end

function attr_to_tex(attr)
  s = [[\gurps@char@print@attr]]
  level_str = ""
  if attr.level or attr.diceexpr ~= "NotSet" then
    level_str = "[" .. (attr.level or attr.diceexpr) .. "]"
  end

  points_str = ""
  if not is_property(attr) and not is_attack(attr) then
    if attr.points then
      points_str = "[" .. attr.points .. "]"
    elseif attr.type ~= enums.type.property then
      points_str = "[?]"
    end
  end

  s = s .. level_str .. "{" .. attr.name .. "}" .. points_str

  return s
end

function basic_attributes_sorter(a, b)
  x = {}
  x['ST'] = 1
  x['DX'] = 2
  x['IQ'] = 3
  x['HT'] = 4
  return x[a.name] < x[b.name]
end

function secondary_characteristics_sorter(a, b)
  x = {}
  x['HP'] = 1
  x['Per'] = 2
  x['Will'] = 3
  x['FP'] = 4
  x['Basic Speed'] = 5
  x['Basic Move'] = 6
  return x[a.name] < x[b.name]
end

-- predicate to filter by
-- character_key to get character with get_character()
-- sortby function to sort by
function traitlistmaker(predicate, character_key, sortby)
  s = [[\begin{charactertraitlist}]]

  array = filter(predicate, get_character(character_key))
  if array then
    if sortby then
      table.sort(array, sortby)
    end

    for _,v in ipairs(array) do
      s = s .. [[ \item ]] .. attr_to_tex(v)
    end
  else
    s = s .. [[\item ...]]
  end
  s = s .. [[ \end{charactertraitlist}]]
  tex.sprint(s)
end

function meleeattacklist(character_key)
  melee_attacks = filter(is_melee_attack, get_character(character_key))
  if melee_attacks then
    for _,attack in ipairs(melee_attacks) do
      tex.sprint([[\makeatletter]])
      tex.print([[\gurps@char@print@meleeattack]]
          .. "{" .. attack.name .. "}"
          .. "{" .. tostring(attack.level) .. "}"
          .. "{" .. attack.damage .. "}"
          .. "{" .. attack.reach .. "}"
          .. "{" .. attack.notes .. "}"
      )
      tex.sprint([[\makeatother]])
    end
  end
end

function rangedattacklist(character_key)
  ranged_attacks = filter(is_ranged_attack, get_character(character_key))
  if ranged_attacks then
    for _,attack in ipairs(ranged_attacks) do
      tex.sprint([[\makeatletter]])
      tex.print([[\gurps@char@print@rangedattack]]
          .. "{" .. attack.name .. "}"
          .. "{" .. tostring(attack.level) .. "}"
          .. "{" .. attack.damage .. "}"
          .. "{" .. attack.range .. "}"
          .. "{" .. attack.notes .. "}"
      )
      tex.sprint([[\makeatother]])
    end
  end
end

function check_and_fix_attrs(character_key)
  function get(name)
    arr = filter({name=name}, get_character(character_key))
    if arr then
      return arr[1]
    else
      return nil
    end
  end

  function create_if_missing(name, attr)
    if not get(name) then
      insert_attr(character_key, attr)
    end
  end

  -- Check for properties
  create_if_missing("SM", {name="SM", level=1, type=enums.type.property})
  create_if_missing("DR", {name="DR", level=0, type=enums.type.property})

  -- Check for basic attributes
  for _,v in ipairs({"ST", "DX", "IQ", "HT"}) do
    create_if_missing(v, {name=v,
                          type=enums.type.basic_attribute,
                          points=0,
                          level=10})
  end

  -- Check for secondary attributes
  create_if_missing("HP", {name="HP",
                           level=get("ST").level,
                           points=0,
                           type=enums.type.secondary_characteristic})
  create_if_missing("Per", {name="Per",
                           level=get("IQ").level,
                           points=0,
                           type=enums.type.secondary_characteristic})
  create_if_missing("Will", {name="Will",
                             level=get("IQ").level,
                             points=0,
                             type=enums.type.secondary_characteristic})
  create_if_missing("FP", {name="FP",
                           level=get("HT").level,
                           points=0,
                           type=enums.type.secondary_characteristic})
  create_if_missing("Basic Speed", {name="Basic Speed",
                                   level=(get("DX").level+get("HT").level)/4.0,
                                   points=0,
                                   type=enums.type.secondary_characteristic})
  create_if_missing("Basic Move", {name="Basic Move",
                                  level=math.floor(get("Basic Speed").level),
                                  points=0,
                                  type=enums.type.secondary_characteristic})
  -- NOTE dodge here is technically a property as it has no points assigned to
  -- it. It can be made better with advantages (just like DR), but this should
  -- be handled manually (i.e. by setting dodge higher).
  create_if_missing("Dodge", {name="Dodge",
                              level=math.floor(get("Basic Speed").level+3),
                              type=enums.type.property})
  create_if_missing("thr", {name="thr",
                            diceexpr=thrust(get("ST").level),
                            type=enums.type.property})
  create_if_missing("sw", {name="sw",
                           diceexpr=swing(get("ST").level),
                           type=enums.type.property})
end

function check_and_fix_points(character_key)
  function get(name)
    arr = filter({name=name}, get_character(character_key))
    if arr then
      return arr[1]
    else
      return nil
    end
  end

  function add_stat_points_if_needed(name, default, multiplier)
    if not get(name).points then
      get(name).points = (get(name).level - default)*multiplier
    end
  end

  add_stat_points_if_needed("ST", 10, 10)
  add_stat_points_if_needed("DX", 10, 20)
  add_stat_points_if_needed("IQ", 10, 20)
  add_stat_points_if_needed("HT", 10, 10)

  add_stat_points_if_needed("HP", get("ST").level, 2)
  add_stat_points_if_needed("Per", get("IQ").level, 5)
  add_stat_points_if_needed("Will", get("IQ").level, 5)
  add_stat_points_if_needed("FP", get("HT").level, 2)

  -- I can't calculate dis/advantages so straight on to skills and spells

  -- Skills
  --
  -- TODO tidy up this section. Maybe move functions out? Or make more pure
  -- (i.e. separate into several functions which are used in the function that
  -- changes `attr`)?
  function add_skill_points_if_possible(attr)
    if attr.difficulty == enums.difficulty.notset then
      return
    end
    points_multiplier = 1
    if attr.difficulty == enums.difficulty.easy then
      difficulty_modifier = 0
    elseif attr.difficulty == enums.difficulty.average then
      difficulty_modifier = 1
    elseif attr.difficulty == enums.difficulty.hard then
      difficulty_modifier = 2
    elseif attr.difficulty == enums.difficulty.very_hard then
      difficulty_modifier = 3
    elseif attr.difficulty == enums.difficulty.wildcard then
      points_multiplier = 3
      difficulty_modifier = 3
    else
      tex.error("Difficulty '" .. attr.difficulty .. "' not recognised! (For"
                  .. " skill '" .. attr.name .. "'.)")
    end

    if get(attr.basedon) == nil then
      tex.error("Unable to base '" .. attr.name .. "' on '" .. attr.basedon 
                  .. "'! Does '" .. attr.basedon .. "' exist?")
    end
    relative_level = attr.level - get(attr.basedon).level
    if relative_level == (0 - difficulty_modifier) then
      attr.points = 1*points_multiplier
    elseif relative_level == (1 - difficulty_modifier) then
      attr.points = 2*points_multiplier
    elseif relative_level == (2 - difficulty_modifier) then
      attr.points = 4*points_multiplier
    elseif relative_level > (2 - difficulty_modifier) then
      attr.points = (relative_level-1+difficulty_modifier)*4 * points_multiplier
    end
  end

  skills_and_spells = filter(
    function(v) return is_skill(v) or is_spell(v) end,
    get_character(character_key)
  )
  if skills_and_spells then
    for _,v in ipairs(skills_and_spells) do
      add_skill_points_if_possible(v)
    end
  end

end

-- Sum the points for the character
function sum_points(character_key)
  local points = 0
  for _,v in ipairs(get_character(character_key)) do
    points = points + (v.points or 0)
  end
  return points
end

function check_and_fix_attrs_and_points(character_key)
  check_and_fix_attrs(character_key)
  check_and_fix_points(character_key)


  -- Sort the character
  function compare_only_alphanumeric(a, b)
    if not a or not b then
      tex.error("Looks like there's a problem with character ordering..."
                  .. " problems with a: " .. tostring(a) .. " and b: "
                  .. tostring(b) .. ".")
    end
    return a.name:gsub('%W', '') < b.name:gsub('%W', '')
  end
  table.sort(
    get_character(character_key),
    compare_only_alphanumeric
  )
end
