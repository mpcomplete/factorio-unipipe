local Area = require('__kry_stdlib__/stdlib/area/area')
local Position = require('__kry_stdlib__/stdlib/area/position')
local Direction = require('__kry_stdlib__/stdlib/area/direction')
local table = require('__kry_stdlib__/stdlib/utils/table')
local util = require("__core__/lualib/util")

Pipe = {}

    -- Normalize 2.1 filter objects into a string
function Pipe.getFluidNameFromFilter(filter)
  if not filter then return nil end
  local fluid = filter.fluid or filter.name
  if type(fluid) == "string" then return fluid end
  if type(fluid) == "table" or type(fluid) == "userdata" then
    local ok, fluidName = pcall(function() return fluid.name end)
    if ok and type(fluidName) == "string" then return fluidName end
  end
  if type(filter.name) == "string" then return filter.name end
  return nil
end

local function getFluidSegmentFilterSafe(entity, fluidboxIdx)
  if not entity.get_fluid_segment_filter then return nil end
  local ok, filter = pcall(entity.get_fluid_segment_filter, fluidboxIdx)
  if ok then return filter end
  return nil
end

    -- Get the fluid name for a given fluidbox index, using the recipe as a fallback if no filter is set.
local function getFluidNameFromRecipeForFluidbox(entity, fluidboxIdx, incomingPipeConnectionIdx)
  if not entity.get_recipe then return nil end
  -- Some fluidbox-owning entities expose get_recipe but throw when called.
  local ok, recipe = pcall(entity.get_recipe)
  if not ok then return nil end
  if not recipe then return nil end

  local segmentFilter = getFluidSegmentFilterSafe(entity, fluidboxIdx)
  local segmentFluidName = Pipe.getFluidNameFromFilter(segmentFilter)
  if segmentFluidName then return segmentFluidName end

  local fluidboxPrototype = entity.get_fluid_box_prototype(fluidboxIdx)
  if not fluidboxPrototype then return nil end
  if type(fluidboxPrototype) == "table" then
    -- Recipe-created merged fluidboxes can return multiple prototypes. Prefer one
    -- that matches the incoming connection index when available.
    local filteredPrototype = nil
    if incomingPipeConnectionIdx then
      for _, prototype in ipairs(fluidboxPrototype) do
        if prototype.pipe_connections and prototype.pipe_connections[incomingPipeConnectionIdx] then
          filteredPrototype = prototype
          break
        end
      end
    end
    if not filteredPrototype then
      -- Fallback: pick any filtered prototype.
      for _, prototype in ipairs(fluidboxPrototype) do
        if prototype.filter and prototype.filter.valid then
          filteredPrototype = prototype
          break
        end
      end
    end
    fluidboxPrototype = filteredPrototype or fluidboxPrototype[fluidboxIdx] or fluidboxPrototype[1]
  end
  if not fluidboxPrototype then return nil end

  -- Best source: per-fluidbox prototype filter. This gives exact port mapping
  -- (e.g. heavy/light/petroleum outputs on distinct ports). 
  -- Not nearly enough stuff actually seems to have this.
  if fluidboxPrototype.filter and fluidboxPrototype.filter.valid then
    return fluidboxPrototype.filter.name
  end

  -- Fallback when there is no explicit per-port filter. 
  local productionType = fluidboxPrototype.production_type
  local fluidNames = {}
  if productionType == "input" or productionType == "input-output" then
    for _, ingredient in pairs(recipe.ingredients or {}) do
      if ingredient.type == "fluid" then table.insert(fluidNames, ingredient.name) end
    end
  end
  if productionType == "output" or productionType == "input-output" then
    for _, product in pairs(recipe.products or {}) do
      if product.type == "fluid" then table.insert(fluidNames, product.name) end
    end
  end

  if #fluidNames == 0 then return nil end
  if #fluidNames == 1 then return fluidNames[1] end

  -- Use incoming pipe connection index to disambiguate multi-fluid recipes. Pipe 1, Pipe 2, etc.
  if incomingPipeConnectionIdx then
    local connectionOrd = 0
    for connectionIdx, connection in ipairs(entity.get_fluid_box_pipe_connections(fluidboxIdx) or {}) do
      if connection.connection_type ~= "linked" then
        local flow = connection.flow_direction
        local flowMatches =
          (productionType == "input" and flow == "input") or
          (productionType == "output" and flow == "output") or
          (productionType == "input-output")
        if flowMatches then
          connectionOrd = connectionOrd + 1
          if connectionIdx == incomingPipeConnectionIdx then
            return fluidNames[math.min(connectionOrd, #fluidNames)]
          end
        end
      end
    end
  end

  return fluidNames[1]
end

function Pipe.getNetworkSurface(entity)
  return entity.surface
end

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
  if entity.fluids_count == 0 then return end
  for _, v in ipairs(entity.get_fluid_box_linked_connections()) do
    if v.other_entity.valid and v.other_entity.prototype.name == Config.HIDDEN_LINKED_PIPE_NAME then
      entity.remove_fluid_box_linked_connection(v.this_linked_connection_id)
      entity.clear_fluid_inside()
      destroyLinkedPipe(v.other_entity)
    end
  end
end

function getLinkConnection(entity)
  if entity.fluids_count == 0 then return end
  for _, v in ipairs(entity.get_fluid_box_linked_connections()) do
    if v.other_entity.valid and v.other_entity.prototype.name == Config.HIDDEN_LINKED_PIPE_NAME then
      return {fluidId = fluidIdFromLinkedPipe(v.other_entity)}
    end
  end
end

function getFluidId(entity, fluidName)
  local surfaceName = "nauvis"
  if settings.startup["zy-unipipe-per-surface"].value then
    local networkSurface = Pipe.getNetworkSurface(entity) or entity.surface
    surfaceName = networkSurface.name
  end
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
  linkedPipe.add_fluid_box_linked_connection(1, entity, 1)

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
  elseif entity.fluids_count and entity.fluids_count > 0 then Pipe.onBuiltFluidbox(event, entity)
  end
end

function Pipe.onBuiltPipe(event, entity)
  script.register_on_object_destroyed(entity)
  local filter = entity.get_fluid_filter(1)
  Pipe.setFluidFilter(entity, Pipe.getFluidNameFromFilter(filter))
  if settings.global["zy-unipipe-autofilter-mode"].value ~= "disabled" then
    updateUnipipesForSystem(entity)
  end
end

function Pipe.onBuiltFluidbox(event, entity)
  if settings.global["zy-unipipe-autofilter-mode"].value == "any" then
    updateUnipipesForSystem(entity)
  end
end

function Pipe.updateFluidFilter(entity)
  updateUnipipesForSystem(entity)
end

    -- STOP BEING BROKEN (Scans and fixes connections for all pipes on all surfaces, used on init and configuration change)
function Pipe.reconcileAllFilters()
  for _, surface in pairs(game.surfaces) do
    local entities = surface.find_entities_filtered{name = {Config.PIPE_FILL_NAME, Config.PIPE_EXTRACT_NAME}}
    for _, entity in pairs(entities) do
      if entity.valid then
        local filterName = Pipe.getFluidNameFromFilter(entity.get_fluid_filter(1))
        -- Safety behavior: only ever add/repair links here.
        if filterName then
          setupLinkConnection(entity, filterName)
        end
      end
    end
  end
end

function Pipe.setFluidFilter(entity, fluidName)
  if fluidName then
    setupLinkConnection(entity, fluidName)
    entity.set_fluid_filter(1, {fluid = fluidName})
  else
    removeLinkConnection(entity)
    entity.set_fluid_filter(1, nil)
  end
end

local fluidIteratorData = { visited = {}, toVisit = {}, unipipes = {}, fluidTypes = {} }
function updateUnipipesForSystem(entity)
  if not entity.valid or not entity.unit_number then return end
  for i = 1, entity.fluids_count do
    table.insert(fluidIteratorData.toVisit, {entity = entity, fluidboxIdx = i, pipeConnectionIdx = nil, networkId = entity.unit_number .. "/" .. i})
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
    local entity = visit.entity
    local fluidboxIdx = visit.fluidboxIdx
    if not entity.valid then goto continue end

    local key = entity.unit_number .. '/' .. fluidboxIdx
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

    local isUnipipe = Config.isPipeName(entity.name)
    if isUnipipe then
      table.insert(unipipes, { pipe = entity, networkId = visit.networkId })
    end

    local fluidFilter = entity.get_fluid_filter(fluidboxIdx)
    if not fluidTypes[visit.networkId] and not isUnipipe and fluidFilter then
      fluidTypes[visit.networkId] = Pipe.getFluidNameFromFilter(fluidFilter)
    end
    local fluid = entity.get_fluid(fluidboxIdx)
    if not fluidTypes[visit.networkId] and not isUnipipe and fluid then
      fluidTypes[visit.networkId] = fluid.name
    end

    if not fluidTypes[visit.networkId] and not isUnipipe then
      local segmentFilter = getFluidSegmentFilterSafe(entity, fluidboxIdx)
      local segmentFluidName = Pipe.getFluidNameFromFilter(segmentFilter)
      if segmentFluidName then
        fluidTypes[visit.networkId] = segmentFluidName
      end
    end
    if not fluidTypes[visit.networkId] and not isUnipipe then
      local fluidName = getFluidNameFromRecipeForFluidbox(entity, fluidboxIdx, visit.pipeConnectionIdx)
      if fluidName then
        fluidTypes[visit.networkId] = fluidName
      end
    end
    for _, connection in pairs(entity.get_fluid_box_pipe_connections(fluidboxIdx) or {}) do
      if connection.target and connection.target.valid and connection.connection_type ~= "linked" then
        table.insert(toVisit, {
          entity = connection.target,
          fluidboxIdx = connection.target_fluidbox_index,
          pipeConnectionIdx = connection.target_pipe_connection_index,
          networkId = visit.networkId
        })
      end
    end
    ::continue::
  end
end

function onEntityDestroyed(event)
  if event.type ~= defines.target_type.entity then return end

  table.each(getHiddenSurface().find_entities_filtered{name = Config.HIDDEN_LINKED_PIPE_NAME}, function(linkedPipe)
    if #linkedPipe.get_fluid_box_linked_connections() == 0 then
      destroyLinkedPipe(linkedPipe)
    end
  end)
end

script.on_event(defines.events.on_object_destroyed, function(event)
  pcall(onEntityDestroyed, event)
end)

function Pipe.openGui(player, entity)
  local lastFilterName = Pipe.getFluidNameFromFilter(entity.get_fluid_filter(1))
  local onTickHandler = function(event)
    if not entity.valid then return end
    local currentFilter = entity.get_fluid_filter(1)
    local currentFilterName = Pipe.getFluidNameFromFilter(currentFilter)
    if currentFilterName ~= lastFilterName then
      lastFilterName = currentFilterName
      Pipe.setFluidFilter(entity, currentFilterName)
    end
  end

  script.on_event(defines.events.on_tick, onTickHandler)

  local guiClosedHandler = function(event)
    if event.entity and event.entity == entity then
      script.on_event(defines.events.on_tick, nil)
    end
  end

  script.on_event(defines.events.on_gui_closed, guiClosedHandler)
end

function Pipe.destroyGui(player)
  if player.gui.relative.unipipeFrame then player.gui.relative.unipipeFrame.destroy() end
end
