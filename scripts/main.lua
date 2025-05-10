local table = require('__kry_stdlib__/stdlib/utils/table')

function onBuiltEntity(event)
  local entity = event.entity
  if entity and entity.valid then
    Pipe.onBuiltEntity(event, entity)
  end
end

script.on_event(defines.events.on_built_entity, onBuiltEntity)
script.on_event(defines.events.on_robot_built_entity, onBuiltEntity)
script.on_event(defines.events.script_raised_built, onBuiltEntity)

script.on_event(defines.events.on_entity_settings_pasted, function(event)
  if not Config.isPipeName(event.destination.name) then return end
  local filter = event.destination.fluidbox.get_filter(1)
  Pipe.setFluidFilter(event.destination, filter and filter.name)
end)

function initGui(player)
  -- Custom GUI doesn't exist anymore
  Pipe.destroyGui(player)
end

script.on_event(defines.events.on_gui_opened, function(event)
  local player = game.get_player(event.player_index)
  if not player or not event.entity then return end
  if Config.isPipeName(event.entity.name) then Pipe.openGui(player, event.entity) end
end)

script.on_init(function(event)
  storage.filterToId = {}
  for i, player in pairs(game.players) do
    initGui(player)
  end
end)

script.on_configuration_changed(function(event)
  for i, player in pairs(game.players) do
    initGui(player)
  end

  game.print("Unipipe: mod configuration changed, trying to repair pipe filters on every surface")
  for _, surface in pairs(game.surfaces) do
    table.each(surface.find_entities_filtered {name = {Config.PIPE_FILL_NAME, Config.PIPE_EXTRACT_NAME}}, function(v)
      Pipe.updateFluidFilter(v)
    end)
  end
end)

script.on_event(defines.events.on_player_created, function(event)
  local player = game.get_player(event.player_index)
  initGui(player)
end)

script.on_event(defines.events.on_player_joined_game, function(event)
  local player = game.get_player(event.player_index)
  initGui(player)
end)