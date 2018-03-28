-- Defines helpers for character building

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
  if attr.type and attr.name then
    return attr
  else
    return nil
  end
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
