local Position = require('__stdlib__/stdlib/area/position')
local Area = require('__stdlib__/stdlib/area/area')
local table = require('__stdlib__/stdlib/utils/table')
local Util = require('util')

function onBuiltPipe(event, entity)
  local player = game.players[event.player_index]
  game.print('built pipe ' .. entity.unit_number)
  local pos = Position.new(entity.position)
  -- local inputOffset = 
  local chest = player.surface.create_entity{
    name = Config.HIDDEN_CHEST_NAME,
    position = pos:translate(defines.direction.north, 1),
    direction = defines.direction.north
  }
  local inserter = player.surface.create_entity{
    name = Config.HIDDEN_INSERTER_NAME,
    position = pos:translate(defines.direction.north, 2),
    direction = defines.direction.south
  }
  local assembler = player.surface.create_entity{
    name = Config.HIDDEN_ASSEMBLER_NAME,
    position = pos:translate(defines.direction.north, 4),
    direction = defines.direction.north
  }
  assembler.set_recipe("iron-gear-wheel")
  Util.setLinkId(chest, Util.getOrCreateId("iron-plate"), "iron-plate")
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