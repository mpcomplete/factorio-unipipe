local Position = require('__stdlib__/stdlib/area/position')
local Area = require('__stdlib__/stdlib/area/area')
local table = require('__stdlib__/stdlib/utils/table')
local Util = require('util')

local chestName = "filtered-linked-chest"

-- From https://github.com/mrvn/factorio-example-entity-with-tags
script.on_event(defines.events.on_player_setup_blueprint, function(event)
  local player = game.players[event.player_index]
  -- get new blueprint or fake blueprint when selecting a new area
  local bp = player.blueprint_to_setup
  if not bp or not bp.valid_for_read then
    bp = player.cursor_stack
  end
  if not bp or not bp.valid_for_read then
    return
  end
  -- get entities in blueprint
  local entities = bp.get_blueprint_entities()
  if not entities then
    return
  end
  -- get mapping of blueprint entities to source entities
  if event.mapping.valid then
    local map = event.mapping.get()
    for _, bp_entity in pairs(entities) do
      if bp_entity.name == chestName then
        -- set tag for our example tag-chest
        local id = bp_entity.entity_number
        local entity = map[id]
        if entity then
          bp.set_blueprint_entity_tag(id, "filter", Util.getNameFromId(entity.link_id))
        else
          game.print("missing mapping for bp_entity " .. id .. ":" .. bp_entity.name)
        end
      end
    end
  else
    game.print("no entity mapping in event")
  end
end)

function rotateAndFlip(pos, dir, flipH, flipV)
  if flipH then pos.x = -pos.x end
  if flipV then pos.y = -pos.y end
  if dir == defines.direction.north then return pos end
  if dir == defines.direction.west then return Position.construct(pos.y, -pos.x) end
  if dir == defines.direction.south then return Position.construct(-pos.x, -pos.y) end
  if dir == defines.direction.east then return Position.construct(-pos.y, pos.x) end
  game.print("Warning: unexpected blueprint rotation " .. dir ". Chest filters will be incorrect.")
  return pos
end

script.on_event(defines.events.on_pre_build, function(event)
  local player = game.players[event.player_index]
  if not player.is_cursor_blueprint() or global.lastPreBuildTick == event.tick then return end
  if not player.get_blueprint_entities() then return end  -- might be all tiles
  global.lastPreBuildTick = event.tick

  -- Find the blueprint's bounding box.
  local positions = {}
  table.each(player.get_blueprint_entities(), function(v) table.insert(positions, Position.new(v.position)) end)
  local leftTop = Position.min_xy(positions)
  local rightBottom = Position.max_xy(positions)
  local bbox = Area.new{leftTop, rightBottom}
  local negCenter = bbox:center():flip()
  local bboxSize = bbox:offset(negCenter)  -- `bbox - bbox.center`
  -- Maybe rotate the bbox.
  local area = bboxSize:offset(event.position):ceil()
  if event.direction == defines.direction.east or event.direction == defines.direction.west then
    area = area:flip()
  end

  -- Find the positions where the blueprint *would* place the relevant entities.
  local bpEntityPositions = {}
  table.each(player.get_blueprint_entities(), function(v)
    if v.name == chestName then
      local bpPos = rotateAndFlip(Position.new(v.position):add(negCenter), event.direction, event.flip_horizontal, event.flip_vertical)
      local pos = bpPos:add(event.position):center()
      table.insert(bpEntityPositions, pos)
    end
  end)

  -- Destroy any existing entities where the blueprint would overwrite them.
  table.each(player.surface.find_entities_filtered {name = 'entity-ghost', area = area}, function(v)
    if v.ghost_name == chestName then
      local center = Position.center(v.position)
      if table.any(bpEntityPositions, function(p) return center:equals(p) end) then
        v.destroy()
      end
    end
  end)
end)

function onBuiltEntity(event)
  local entity = event.created_entity
  if entity.name == chestName then onBuiltChest(event, entity)
  else onBuiltPipe(event, entity)
  end
end

function onBuiltChest(event, entity)
  local tagFilter = event.tags and event.tags["filter"]   -- Extract filter from a blueprint tag

  if entity.link_id == 0 and tagFilter == nil and global.lastLinkId == nil then
      -- Ensure a valid filter for this chest. Will only happen for the first chest placed.
      for k, v in pairs(game.item_prototypes) do
        tagFilter = k
        break
      end
  end
  if tagFilter then
    Util.setLinkId(entity, Util.getOrCreateId(tagFilter), tagFilter)
  elseif entity.link_id == 0 then
    Util.setLinkId(entity, global.lastLinkId, Util.getNameFromId(global.lastLinkId))
  end
end

function onBuiltPipe(event, entity)
end

local onBuiltFilter =  { { filter = "name", name = chestName }, { filter = "name", name = pipeInName }, { filter = "name", name = pipeOutName } }
script.on_event(defines.events.on_built_entity, onBuiltEntity, onBuiltFilter)
script.on_event(defines.events.on_robot_built_entity, onBuiltEntity, onBuiltFilter)
script.on_event(defines.events.script_raised_built, onBuiltEntity, onBuiltFilter)

script.on_event("filtered-linked-chest-paste-alt", function(event)
  local player = game.players[event.player_index]
  Util.setChestFilter(player.selected, player.entity_copy_source, true)
end)

script.on_event(defines.events.on_entity_settings_pasted, function(event)
  local player = game.players[event.player_index]
  Util.setChestFilter(event.destination, event.source, false)
end)

script.on_event(defines.events.on_gui_opened, function(event)
  local player = game.get_player(event.player_index)
  if player == nil then return end
  if event.entity == nil then return end
  if event.entity.name == chestName then
    local guiEntity = event.entity
    local guiLinkId = guiEntity.link_id
    local guiFilter = Util.getNameFromId(guiLinkId)
    player.gui.relative.flcFrame.itemFilter.elem_value = guiFilter
    Util.setLinkId(guiEntity, guiLinkId, guiFilter)

    script.on_event(defines.events.on_tick, function(event)
      -- Reset any changes via the GUIs we can't control (e.g. Link bitmask and manual filtering).
      player.gui.relative.flcFrame.itemFilter.elem_value = guiFilter
      Util.setLinkId(guiEntity, guiLinkId, guiFilter)
    end)

    script.on_event(defines.events.on_gui_elem_changed, function(event)
      local element = event.element
      if element ~= player.gui.relative.flcFrame.itemFilter then return end
      if element.elem_value and element.elem_value ~= "" then
        -- Don't let them set an empty filter.
        guiLinkId = Util.getOrCreateId(element.elem_value)
        guiFilter = element.elem_value
      end
    end)
  end
end)

script.on_event(defines.events.on_gui_closed, function(event)
  script.on_event(defines.events.on_tick, nil)
  script.on_event(defines.events.on_gui_elem_changed, nil)
end)

function buildGui(player)
  player.gui.relative.add {
    type = "frame",
    name = "flcFrame",
    direction = "vertical",
    caption = { "flc.heading" },
    anchor = {
      gui = defines.relative_gui_type.linked_container_gui,
      position = defines.relative_gui_position.right
    },
    visible = true
  }
  player.gui.relative.flcFrame.add {
    type = "choose-elem-button",
    name = "itemFilter",
    tooltip = { "flc.chooseElemTooltip" },
    style = "slot_button",
    elem_type = "item"
  }
end

function destroyGui(player)
  if player.gui.relative.flcFrame ~= nil then player.gui.relative.flcFrame.destroy() end
  if player.gui.screen.flcFrame ~= nil then player.gui.screen.flcFrame.destroy() end
end

function initGui(player)
  destroyGui(player)
  buildGui(player)
end

script.on_init(function(event)
  global.nameToId = {}
  for i, player in pairs(game.players) do
    initGui(player)
  end
end)

script.on_nth_tick(nil)

script.on_configuration_changed(function(event)
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