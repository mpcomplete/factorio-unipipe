local Position = require('__stdlib__/stdlib/area/position')
local Area = require('__stdlib__/stdlib/area/area')
local table = require('__stdlib__/stdlib/utils/table')
local Direction = require('__stdlib__/stdlib/area/direction')
local Util = require('util')

function onBuiltPipe(event, entity)
  local isInput = entity.name == Config.PIPE_IN_NAME
  local player = game.players[event.player_index]
  game.print('built pipe ' .. entity.unit_number)
  local pos = Position.new(entity.position)
  local dir = entity.direction
  local flowDir = isInput and Direction.opposite(dir) or dir
  -- local inputOffset = 
  local assembler = player.surface.create_entity{
    name = Config.HIDDEN_ASSEMBLER_NAME,
    position = pos,
    force = player.force,
  }
  local inserter = player.surface.create_entity{
    name = Config.HIDDEN_INSERTER_NAME,
    position = pos:translate(flowDir, -1),
    direction = isInput and flowDir or Direction.opposite(flowDir),
    force = player.force,
  }
  local chest = player.surface.create_entity{
    name = Config.HIDDEN_CHEST_NAME,
    position = pos:translate(flowDir, -2),
    force = player.force,
  }
  local fluidName = "crude-oil"
  local itemName = Config.getFluidItem(fluidName)
  assembler.set_recipe(isInput and Config.getFluidFillRecipe(fluidName) or Config.getFluidEmptyRecipe(fluidName))
  assembler.direction = Direction.opposite(dir)  -- need to set after setting recipe
  inserter.inserter_stack_size_override = 20
  Util.setLinkId(chest, Util.getOrCreateId(itemName), itemName)
  global.hiddenEntities = global.hiddenEntities or {}
  global.hiddenEntities[entity.unit_number] = { inserter, assembler, chest }
  script.register_on_entity_destroyed(entity)
end

script.on_event(defines.events.on_entity_destroyed, function(event)
  game.print("destroyed pipe " .. (event.unit_number or "nil"))
  for k,v in pairs(global.hiddenEntities[event.unit_number] or {}) do
    game.print("killing linked entity " .. v.name)
    v.destroy()
  end
end)