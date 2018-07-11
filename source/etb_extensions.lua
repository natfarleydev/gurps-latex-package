-- Based on code from https://tex.stackexchange.com/questions/439902/how-to-access-etoolbox-toggle-inside-lua/439903#439903
_GETB_TOGGLE_TRUE = token.create("etb@toggletrue")
_GETB_TOGGLE_FALSE = token.create("etb@togglefalse")

-- Transforms x to etb toggle namespace
function etb_tgl(x)
  return "etb@tgl@" .. x
end

function etb_is_toggletrue(togglename)
  local toggle = token.create(etb_tgl(togglename))
  if toggle.mode == _GETB_TOGGLE_TRUE.mode then
    return true
  elseif toggle.mode == _GETB_TOGGLE_FALSE.mode then
    return false
  else
    tex.error("etb_extensions.lua: Invalid toggle passed? " .. togglename)
  end
end

function etb_set_toggle(togglename, value)
  if value ~= true and value ~= false then
    tex.error("value is set to " .. value .. "! Please set it to true or false.")
  end

  if value == true then
    set_macro(etb_tgl(togglename, _ETB_TOGGLE_TRUE))
  elseif value == false then
    set_macro(etb_tgl(togglename, _ETB_TOGGLE_FALSE))
  end
end
