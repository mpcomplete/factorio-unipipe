local Area = require('__kry_stdlib__/stdlib/area/area')
local Position = require('__kry_stdlib__/stdlib/area/position')
local Direction = require('__kry_stdlib__/stdlib/area/direction')
local table = require('__kry_stdlib__/stdlib/utils/table')
local util = require("__core__/lualib/util")

Pipe = {}

function getHiddenSurface()
  local surface = game.get_surface(Config.HIDDEN_SURFACE_NAME)
  if not surface then
    surface = game.create_surface(Config.HIDDEN_SURFACE_NAME)
    for _, force in pairs(game.forces) do
      force.set_surface_hidden(Config.HIDDEN_SURFACE_NAME, true)
    end
  end
  return surface
end

function fluidIdFromLinkedPipe(linkedPipe)
  for fluidId, data in pairs(storage.hiddenPipeData) do
    if linkedPipe.position.y == data.yPosition then
      return fluidId
    end
  end
end

function destroyLinkedPipe(linkedPipe)
  local fluidId = fluidIdFromLinkedPipe(linkedPipe)
  if fluidId then
    -- Recycle this now-available x position.
    table.insert(storage.hiddenPipeData[fluidId].recycledXPositions, linkedPipe.position.x)
  end
  linkedPipe.destroy()
end

function removeLinkConnection(entity)
  if entity.fluidbox == nil then return end
  for i, v in ipairs(entity.fluidbox.get_linked_connections()) do
    if v.other_entity.prototype.name == Config.HIDDEN_LINKED_PIPE_NAME then
      entity.fluidbox.remove_linked_connection(i)
      entity.clear_fluid_inside()
      destroyLinkedPipe(v.other_entity)
    end
  end
end

function getLinkConnection(entity)
  if entity.fluidbox == nil then return end
  for _, v in ipairs(entity.fluidbox.get_linked_connections()) do
    if v.other_entity.prototype.name == Config.HIDDEN_LINKED_PIPE_NAME then
      return {fluidId = fluidIdFromLinkedPipe(v.other_entity)}
    end
  end
end

function getFluidId(entity, fluidName)
  local surfaceName = "nauvis"
  if settings.startup["zy-unipipe-per-surface"].value then surfaceName = entity.surface.name end
  return surfaceName .. "/" .. entity.force.name .. "/" .. fluidName
end

function setupLinkConnection(entity, fluidName)
  local oldLinkConnection = getLinkConnection(entity)
  local fluidId = getFluidId(entity, fluidName)
  if oldLinkConnection and oldLinkConnection.fluidId == fluidId then return end
  removeLinkConnection(entity)
  storage.hiddenPipeData = storage.hiddenPipeData or {}
  if storage.hiddenPipeData[fluidId] == nil then
    storage.hiddenPipeData[fluidId] = {
      xPosition = 0.5,
      yPosition = table.size(storage.hiddenPipeData) * 3 + 0.5,
      recycledXPositions = {},
    }
  end
  local data = storage.hiddenPipeData[fluidId]

  -- Add (or reuse) a pipe to the row of pipes for this fluid.
  local xPosition = data.xPosition
  if #data.recycledXPositions > 0 then
    xPosition = table.remove(data.recycledXPositions)
  else
    getHiddenSurface().create_entity{
      name = Config.HIDDEN_PIPE_NAME,
      position = {xPosition, data.yPosition-1},
      direction = defines.direction.north,
      force = entity.force,
      create_build_effect_smoke = false,
    }
    data.xPosition = data.xPosition + 1
  end

  -- Add a linked pipe connected to the above row, linked to our unipipe.
  local linkedPipe = getHiddenSurface().create_entity{
		name = Config.HIDDEN_LINKED_PIPE_NAME,
		position = {xPosition, data.yPosition},
		direction = defines.direction.north,
		force = entity.force,
		create_build_effect_smoke = false,
	}
	linkedPipe.fluidbox.add_linked_connection(1, entity, 1)

	return linkedPipe
end

-- Support for Unichest selection tool.
script.on_event(defines.events.on_player_selected_area, function(event)
  if event.item ~= Config.TOOL_NAME then return end

  local player = game.players[event.player_index]

  table.each(player.surface.find_entities_filtered{name = Config.PIPE_FILL_NAME, area = event.area}, function(v)
    Pipe.updateFluidFilter(v)
  end)
  table.each(player.surface.find_entities_filtered{name = Config.PIPE_EXTRACT_NAME, area = event.area}, function(v)
    Pipe.updateFluidFilter(v)
  end)
end)

function Pipe.onBuiltEntity(event, entity)
  if entity.name == Config.PIPE_FILL_NAME or entity.name == Config.PIPE_EXTRACT_NAME then Pipe.onBuiltPipe(event, entity)
  elseif entity.fluidbox and entity.fluidbox.valid and #entity.fluidbox > 0 then Pipe.onBuiltFluidbox(event, entity)
  end
end

function Pipe.onBuiltPipe(event, entity)
  script.register_on_object_destroyed(entity)
  -- Pipe.setFluidFilter(entity, Config.NULL_FLUID_NAME)
  if settings.global["zy-unipipe-autofilter-mode"].value ~= "disabled" then
    updateUnipipesForSystem(entity.fluidbox)
  end
end

function Pipe.onBuiltFluidbox(event, entity)
  if settings.global["zy-unipipe-autofilter-mode"].value == "any" then
    updateUnipipesForSystem(entity.fluidbox)
  end
end

function Pipe.updateFluidFilter(entity)
  updateUnipipesForSystem(entity.fluidbox)
end

function Pipe.setFluidFilter(entity, fluidName)
  if fluidName then
    setupLinkConnection(entity, fluidName)
    entity.fluidbox.set_filter(1, fluidName and {name = fluidName, force = true} or nil)
  else
    removeLinkConnection(entity)
    entity.fluidbox.set_filter(1, nil)
  end
end

function updateUnipipesForSystem(fluidbox)
  local unipipes = {}
  local fluidType = findConnectedUnipipes(fluidbox, nil, unipipes, {})
  if not fluidType then return end
  for _, pipe in pairs(unipipes) do
    Pipe.setFluidFilter(pipe, fluidType)
  end
end

-- Stupid test to make sure the fluidbox *actually* has a given index, despite #fluidbox telling us it's valid.
function testFluidbox(fluidbox, i)
  return pcall(function() return fluidbox.get_filter(i) end) and pcall(function() return fluidbox[i] end)
end

-- fluidboxIdx may be nil to search all fluidbox indices, or non-nil to only consider one.
function findConnectedUnipipes(fluidbox, fluidboxIdx, unipipes, visited)
  if not fluidbox.valid or not fluidbox.owner then return end
  if table.any(visited[fluidbox.owner.unit_number] or {}, function(v) return v == fluidbox end) then return end
  visited[fluidbox.owner.unit_number] = visited[fluidbox.owner.unit_number] or {}
  table.insert(visited[fluidbox.owner.unit_number], fluidbox)
  local fluidType = nil
  local isUnipipe = fluidbox.owner and Config.isPipeName(fluidbox.owner.name)

  if isUnipipe then
    table.insert(unipipes, fluidbox.owner)
  end

  for i = 1, #fluidbox do
    if not fluidboxIdx or i == fluidboxIdx then
      -- if not fluidType and not isUnipipe and fluidbox.get_locked_fluid(i) then fluidType = fluidbox.get_locked_fluid(i) end
      if not fluidType and not isUnipipe and fluidbox.get_filter(i) then fluidType = fluidbox.get_filter(i).name end
      if not fluidType and not isUnipipe and fluidbox[i] then fluidType = fluidbox[i].name end
      for _, connection in pairs(fluidbox.get_pipe_connections(i) or {}) do
        if connection.target then
          local rv = findConnectedUnipipes(connection.target, connection.target_fluidbox_index, unipipes, visited)
          fluidType = fluidType or rv
        end
      end
    end
  end
  return fluidType
end

function onEntityDestroyed(event)
  if event.type ~= defines.target_type.entity then return end

  table.each(getHiddenSurface().find_entities_filtered{name = Config.HIDDEN_LINKED_PIPE_NAME}, function(linkedPipe)
    if #linkedPipe.fluidbox.get_linked_connections() == 0 then
      destroyLinkedPipe(linkedPipe)
    end
  end)
end

script.on_event(defines.events.on_object_destroyed, function(event)
  pcall(onEntityDestroyed, event)
end)

function Pipe.openGui(player, entity)
  local lastFilter = entity.fluidbox.get_filter(1)
  script.on_event(defines.events.on_tick, function(event)
    if not entity.valid then return end
    local filter = entity.fluidbox.get_filter(1)
    if (filter and filter.name) ~= (lastFilter and lastFilter.name) then
      -- Player changed the filter, update the unipipe.
      lastFilter = filter
      Pipe.setFluidFilter(entity, filter and filter.name)
    end
  end)

  script.on_event(defines.events.on_gui_closed, function(event)
    script.on_event(defines.events.on_tick, nil)
  end)
end

function Pipe.destroyGui(player)
  if player.gui.relative.unipipeFrame then player.gui.relative.unipipeFrame.destroy() end
end
