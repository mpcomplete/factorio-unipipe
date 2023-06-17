local Util = require('util')

function onBuiltEntity(event)
  local entity = event.created_entity
  if entity and entity.valid then
    Pipe.onBuiltEntity(event, entity)
  end
end

script.on_event(defines.events.on_built_entity, onBuiltEntity)
script.on_event(defines.events.on_robot_built_entity, onBuiltEntity)
script.on_event(defines.events.script_raised_built, onBuiltEntity)

function initGui(player)
  Pipe.destroyGui(player)
  Pipe.buildGui(player)
end

script.on_event(defines.events.on_gui_opened, function(event)
  local player = game.get_player(event.player_index)
  if not player or not event.entity then return end
  if Config.isPipeName(event.entity.name) then Pipe.openGui(player, event.entity)
  end
end)

script.on_init(function(event)
  global.nameToId = {}
  for i, player in pairs(game.players) do
    initGui(player)
  end
  if remote.interfaces["PickerDollies"] and remote.interfaces["PickerDollies"]["dolly_moved_entity_id"] then
    script.on_event(remote.call("PickerDollies", "dolly_moved_entity_id"), Pipe.onMovedEntity)
  end
end)

script.on_load(function(event)
  if remote.interfaces["PickerDollies"] and remote.interfaces["PickerDollies"]["dolly_moved_entity_id"] then
    script.on_event(remote.call("PickerDollies", "dolly_moved_entity_id"), Pipe.onMovedEntity)
  end
end)

script.on_configuration_changed(function(event)
  global.nameToId = {}
  for i, player in pairs(game.players) do
    initGui(player)
  end
end)

script.on_event(defines.events.on_player_created, function(event)
  initGui(game.get_player(event.player_index))
end)

script.on_event(defines.events.on_player_joined_game, function(event)
  initGui(game.get_player(event.player_index))
end)