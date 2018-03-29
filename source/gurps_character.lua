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

-- Store the character in the global characters table
function store_character(key, character)
  _GCHARACTERS[key] = character
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
  wildcard="Wildcard"
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

function is_basic_attribute(attr)
  return attr.type == "basic_attribute"
end

function is_secondary_characteristic(attr)
  return attr.type == "secondary_characteristic"
end
