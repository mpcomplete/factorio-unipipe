local Position = require('__stdlib__/stdlib/area/position')
local Area = require('__stdlib__/stdlib/area/area')
local table = require('__stdlib__/stdlib/utils/table')
local Direction = require('__stdlib__/stdlib/area/direction')
local Util = require('util')

Pipe = {}

function getDefaultFluidName()
  for k,v in pairs(game.fluid_prototypes) do
    if v.valid then return v.name end
  end
  return "water"
end

function Pipe.onBuiltEntity(event, entity)
  if entity.name == Config.PIPE_IN_NAME or entity.name == Config.PIPE_OUT_NAME then Pipe.onBuiltPipe(event, entity)
  elseif entity.fluidbox and entity.fluidbox.valid and #entity.fluidbox > 0 then Pipe.onBuiltFluidbox(event, entity)
  end
end

function Pipe.onBuiltPipe(event, entity)
  local isInput = entity.name == Config.PIPE_IN_NAME
  game.print('built pipe ' .. entity.unit_number)
  local pos = Position.new(entity.position)
  -- 3 entities from north to south: assembler -> inserter -> chest
  local assembler = entity.surface.create_entity{
    name = Config.HIDDEN_ASSEMBLER_NAME,
    position = pos,
    force = entity.force,
  }
  local inserter = entity.surface.create_entity{
    name = Config.HIDDEN_INSERTER_NAME,
    position = pos,
    direction = isInput and defines.direction.north or defines.direction.south, -- direction is pickup source
    force = entity.force,
  }
  local chest = entity.surface.create_entity{
    name = Config.HIDDEN_CHEST_NAME,
    position = pos:add({0, .5}),
    force = entity.force,
  }
  inserter.inserter_stack_size_override = 20
  global.hiddenEntities = global.hiddenEntities or {}
  global.hiddenEntities[entity.unit_number] = { assembler = assembler, inserter = inserter, chest = chest }
  global.hiddenAssemblerToPipe = global.hiddenAssemblerToPipe or {}
  global.hiddenAssemblerToPipe[assembler.unit_number] = entity
  script.register_on_entity_destroyed(entity)
  Pipe.setFluidFilter(entity, getDefaultFluidName())  -- Need to set the assembler's fluid recipe so it has a fluidbox
  updateUnipipesForSystem(assembler.fluidbox, assembler.fluidbox.get_fluid_system_id(1))
end

function Pipe.onBuiltFluidbox(event, entity)
  local lastSystemId = nil
  for i = 1, #entity.fluidbox do
    local systemId = entity.fluidbox.get_fluid_system_id(i)
    if systemId ~= lastSystemId then
      lastSystemId = systemId
      updateUnipipesForSystem(entity.fluidbox, systemId)
    end
  end
end

function Pipe.setFluidFilter(entity, fluidName)
  local hidden = global.hiddenEntities[entity.unit_number]
  if not hidden then return end
  local isInput = entity.name == Config.PIPE_IN_NAME
  local itemName = Config.getFluidItem(fluidName)
  hidden.assembler.set_recipe(isInput and Config.getFluidFillRecipe(fluidName) or Config.getFluidEmptyRecipe(fluidName))
  hidden.assembler.direction = Direction.opposite(entity.direction)  -- need to set after setting recipe
  Util.setLinkId(hidden.chest, Util.getOrCreateId(itemName), itemName)
end

function updateUnipipesForSystem(fluidbox, systemId)
  local unipipes = {}
  local fluidType = findConnectedUnipipes(fluidbox, systemId, unipipes, {})
  if not fluidType then return end
  for _, pipe in pairs(unipipes) do
    Pipe.setFluidFilter(pipe, fluidType)
  end
end

function findConnectedUnipipes(fluidbox, systemId, unipipes, visited)
  if not fluidbox.valid then return end
  if table.any(visited, function(v) return v == fluidbox end) then return end
  table.insert(visited, fluidbox)
  local fluidType = nil
  local isUnipipe = fluidbox.owner and fluidbox.owner.name == Config.HIDDEN_ASSEMBLER_NAME

  if isUnipipe then
    local unipipe = global.hiddenAssemblerToPipe[fluidbox.owner.unit_number]
    if unipipe and unipipe.valid then table.insert(unipipes, unipipe) end
  end

  for i = 1, #fluidbox do
    if fluidbox.get_fluid_system_id(i) == systemId then
      if not fluidType and not isUnipipe and fluidbox.get_filter(i) then fluidType = fluidbox.get_filter(i).name end
      for _, connection in pairs(fluidbox.get_connections(i) or {}) do
        local rv = findConnectedUnipipes(connection, systemId, unipipes, visited)
        fluidType = fluidType or rv
      end
    end
  end
  return fluidType
end

script.on_event(defines.events.on_entity_destroyed, function(event)
  game.print("destroyed pipe " .. (event.unit_number or "nil"))
  local hidden = global.hiddenEntities[event.unit_number]
  if hidden then
    global.hiddenAssemblerToPipe[hidden.assembler.unit_number] = nil
    for k,v in pairs(hidden) do
      game.print("killing linked " .. v.name)
      v.destroy()
    end
  end
  global.hiddenEntities[event.unit_number] = nil
end)

script.on_event(defines.events.on_player_rotated_entity, function(event)
  local entity = event.entity
  if not Config.isPipeName(entity.name) then return end
  local hidden = global.hiddenEntities[entity.unit_number]
  if hidden then
    hidden.assembler.direction = Direction.opposite(entity.direction)
  end
end)