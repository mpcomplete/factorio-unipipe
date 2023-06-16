local Position = require('__stdlib__/stdlib/area/position')
local Area = require('__stdlib__/stdlib/area/area')
local table = require('__stdlib__/stdlib/utils/table')
local Direction = require('__stdlib__/stdlib/area/direction')
local Util = require('util')

function onBuiltPipe(event, entity)
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
  local fluidName = "crude-oil"
  local itemName = Config.getFluidItem(fluidName)
  assembler.set_recipe(isInput and Config.getFluidFillRecipe(fluidName) or Config.getFluidEmptyRecipe(fluidName))
  assembler.direction = Direction.opposite(entity.direction)  -- need to set after setting recipe
  inserter.inserter_stack_size_override = 20
  Util.setLinkId(chest, Util.getOrCreateId(itemName), itemName)
  global.hiddenEntities = global.hiddenEntities or {}
  global.hiddenEntities[entity.unit_number] = { assembler = assembler, inserter = inserter, chest = chest }
  script.register_on_entity_destroyed(entity)
end

script.on_event(defines.events.on_entity_destroyed, function(event)
  game.print("destroyed pipe " .. (event.unit_number or "nil"))
  for k,v in pairs(global.hiddenEntities[event.unit_number] or {}) do
    game.print("killing linked entity " .. v.name)
    v.destroy()
  end
end)

script.on_event(defines.events.on_player_rotated_entity, function(event)
  local entity = event.entity
  if not Config.isPipeName(entity.name) then return end
  local hidden = global.hiddenEntities[entity.unit_number]
  if hidden then
    hidden.assembler.direction = Direction.opposite(entity.direction)
  end
end)