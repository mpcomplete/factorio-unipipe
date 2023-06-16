local Position = require('__stdlib__/stdlib/area/position')
local Area = require('__stdlib__/stdlib/area/area')
local table = require('__stdlib__/stdlib/utils/table')
local Util = require('util')

Chest = {}

function Chest.onBuiltEntity(event, entity)
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

function Chest.onGuiOpened(event, player, entity)
  local player = game.get_player(event.player_index)
  if player == nil then return end
  if event.entity == nil then return end
  if event.entity.name == Config.CHEST_NAME then
    local guiEntity = event.entity
    local guiLinkId = guiEntity.link_id
    local guiFilter = Util.getNameFromId(guiLinkId)
    player.gui.relative.unichestFrame.itemFilter.elem_value = guiFilter
    Util.setLinkId(guiEntity, guiLinkId, guiFilter)

    script.on_event(defines.events.on_tick, function(event)
      -- Reset any changes via the GUIs we can't control (e.g. Link bitmask and manual filtering).
      player.gui.relative.unichestFrame.itemFilter.elem_value = guiFilter
      Util.setLinkId(guiEntity, guiLinkId, guiFilter)
    end)

    script.on_event(defines.events.on_gui_elem_changed, function(event)
      local element = event.element
      if element ~= player.gui.relative.unichestFrame.itemFilter then return end
      if element.elem_value and element.elem_value ~= "" then
        -- Don't let them set an empty filter.
        guiLinkId = Util.getOrCreateId(element.elem_value)
        guiFilter = element.elem_value
      end
    end)
  end
end

function Chest.buildGui(player)
  player.gui.relative.add {
    type = "frame",
    name = "unichestFrame",
    direction = "vertical",
    caption = { "zy-uni.heading" },
    anchor = {
      gui = defines.relative_gui_type.linked_container_gui,
      position = defines.relative_gui_position.right
    },
    visible = true
  }
  player.gui.relative.unichestFrame.add {
    type = "choose-elem-button",
    name = "itemFilter",
    tooltip = { "zy-uni.chooseElemTooltip" },
    style = "slot_button",
    elem_type = "item"
  }
end

function Chest.destroyGui(player)
  if player.gui.relative.unichestFrame ~= nil then player.gui.relative.unichestFrame.destroy() end
end