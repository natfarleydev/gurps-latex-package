-- Defines helpers for character building
--
-- An `attribute` object is defined in the following way:
-- {
-- name: any string,
-- type: "advantage" | "disadvantage" | "skill" | "spell" | "basic_attribute" | "secondary_characteristic" | "attack",
-- level: any positive integer,
-- basedon: a table matching an attribute (e.g. one only containing name and type)
-- difficulty: "Easy" | "Average" | "Hard" | "Very Hard" | "Wildcard"
-- }

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
-- function store_character(character_key, character)
--   _GCHARACTERS[character_key] = character
-- end

-- TODO assert that I will only access the character via the key interface.
-- Maybe. Decide if this should be the case
--
-- Yes, I do want it that way, because it's the TeX way. Define something and
-- then do something with it

-- insert attribute into a character specified by a key
function insert_attr(character_key, attr)
  table.insert(_GCHARACTERS[character_key], attr)
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
                                 "attack"})
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
