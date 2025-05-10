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
  local filter = entity.fluidbox.get_filter(1)
  Pipe.setFluidFilter(entity, filter and filter.name)
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

local fluidIteratorData = { visited = {}, toVisit = {}, unipipes = {}, fluidTypes = {} }
function updateUnipipesForSystem(fluidbox)
  for i = 1, #fluidbox do
    table.insert(fluidIteratorData.toVisit, {fluidbox = fluidbox, fluidboxIdx = i, networkId = fluidbox.owner.unit_number .. "/" .. i})
  end
  script.on_nth_tick(1, function(v)
    findConnectedUnipipes(fluidIteratorData.toVisit, fluidIteratorData.unipipes, fluidIteratorData.visited, fluidIteratorData.fluidTypes)
    if #fluidIteratorData.toVisit == 0 then
      script.on_nth_tick(1, nil)

      for _, pipeData in pairs(fluidIteratorData.unipipes) do
        local fluidType = fluidIteratorData.fluidTypes[pipeData.networkId]
        if fluidType then
          Pipe.setFluidFilter(pipeData.pipe, fluidType)
        end
      end
      fluidIteratorData = { visited = {}, toVisit = {}, unipipes = {}, fluidTypes = {} }
    end
  end)
end

function findConnectedUnipipes(toVisit, unipipes, visited, fluidTypes)
  local maxVisitsPerTick = 10
  local visitCounter = 0
  while #toVisit > 0 and visitCounter < maxVisitsPerTick do
    local visit = table.remove(toVisit)
    local fluidbox = visit.fluidbox
    local fluidboxIdx = visit.fluidboxIdx
    if not fluidbox.valid or not fluidbox.owner then goto continue end

    local key = fluidbox.owner.unit_number .. '/' .. fluidboxIdx
    if visited[key] then
      if visited[key] ~= visit.networkId then
        -- We reached a fluidbox visited as part of a different network. Merge ours with it.
        local otherNetworkId = visited[key]
        for k,v in pairs(visited) do
          if v == visit.networkId then visited[k] = otherNetworkId end
        end
        for k,v in pairs(toVisit) do
          if v.networkId == visit.networkId then toVisit[k].networkId = otherNetworkId end
        end
        for k,v in pairs(unipipes) do
          if v.networkId == visit.networkId then unipipes[k].networkId = otherNetworkId end
        end
        for k,v in pairs(fluidTypes) do
          if k == visit.networkId then fluidTypes[otherNetworkId] = v end
        end
      end
      goto continue
    end
    visited[key] = visit.networkId
    visitCounter = visitCounter + 1

    local isUnipipe = fluidbox.owner and Config.isPipeName(fluidbox.owner.name)
    if isUnipipe then
      table.insert(unipipes, { pipe = fluidbox.owner, networkId = visit.networkId })
    end

    -- if not fluidType and not isUnipipe and fluidbox.get_locked_fluid(i) then fluidType = fluidbox.get_locked_fluid(i) end
    if not fluidTypes[visit.networkId] and not isUnipipe and fluidbox.get_filter(fluidboxIdx) then
      fluidTypes[visit.networkId] = fluidbox.get_filter(fluidboxIdx).name
    end
    if not fluidTypes[visit.networkId] and not isUnipipe and fluidbox[fluidboxIdx] then
      fluidTypes[visit.networkId] = fluidbox[fluidboxIdx].name
    end
    for _, connection in pairs(fluidbox.get_pipe_connections(fluidboxIdx) or {}) do
      if connection.target and connection.connection_type ~= "linked" then
        table.insert(toVisit, {fluidbox = connection.target, fluidboxIdx = connection.target_fluidbox_index, networkId = visit.networkId})
      end
    end
    ::continue::
  end
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
