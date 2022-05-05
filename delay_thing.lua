-- delay thing
-- E2 - scroll presets
-- K2 - load preset
-- E3 - dry/wet

local UI = require "ui"
local Audio = require "audio"
ddd = include('lib/dddelay')

--TODO:
-- initial preset
-- presets after saving/deleting
-- move preset stuff to lib
-- better dry/wet curves

local psets = {}
local pset_display = 1
local pset_current = 1
local pset_preview_metro = metro.init()
local dial_drywet

function init()
  params:add_control("drywet", "dry / wet", controlspec.AMP)
  params:set_action("drywet", function(value)
    Audio.level_monitor(1 - value)
    Audio.level_cut(value)
    dial_drywet:set_value(value)
  end)
  dial_drywet = UI.Dial.new(48, 20, 32, 0.5, 0, 1, 0.01, 0, {}, "", "dry / wet")
  
  ddd.init()
  
  pset_get_all()
  pset_preview_metro.event = pset_preview_cancel

  redraw()
end

function enc(n, delta)
  if n == 2 then
    pset_display = util.clamp(pset_display + delta, 1, #psets)
    pset_preview_metro:start(5, 1)
  elseif n == 3 then
    params:set("drywet", util.clamp(params:get("drywet") + (delta/20), 0, 1))
  end
  redraw()
end

function key(n, z)
  if z == 0 then
    if n == 2 then
      pset_load()
    elseif n == 3 then
      ddd.toggle_hold()
    end
  end
end

function redraw()
  screen.clear()
  screen.aa(1)
  
  screen.move(64, 6)
  screen.text_center(psets[pset_display].name)
  
  screen.move(0, 8)
  screen.line(128, 8)
  screen.stroke()
  
  dial_drywet:redraw()

  screen.update()
end

function pset_load()
  pset_current = pset_display
  params:read(psets[pset_current].path)
end

function pset_preview_cancel()
  pset_display = pset_current
  redraw()
end

function pset_get_name(file)
  local name = file:match("[^/]+$")
  
  local f = io.open(file, "r")
  io.input(file)
  local line = io.read("*line")
  if util.string_starts(line, "-- ") then
    name = string.sub(line, 4, -1)
  end
  io.close(f)
  
  return name
end

function pset_get_in_folder(path)
  if util.file_exists(path) then
    for x, fname in ipairs(util.scandir(path)) do
      if fname:sub(-5) == ".pset" then
        local file = path.."/"..fname
        table.insert(psets, {path = file, name = pset_get_name(file)})
      end
    end
  end
end

function pset_get_current()
  --norns.state.pset_last
end

function pset_get_all()
  psets = {}
  
  local script_path = _path.code..norns.state.name.."/presets"
  pset_get_in_folder(script_path)
  
  local user_path = _path.data..norns.state.name
  pset_get_in_folder(user_path)
end
