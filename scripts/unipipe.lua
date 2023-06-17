local Position = require('__stdlib__/stdlib/area/position')
local Area = require('__stdlib__/stdlib/area/area')
local table = require('__stdlib__/stdlib/utils/table')
local Direction = require('__stdlib__/stdlib/area/direction')
local Util = require('util')
local util = require("__core__/lualib/util")

Pipe = {}

function getDefaultFluidName()
  if game.fluid_prototypes["water"] then return "water" end
  for k,v in pairs(game.fluid_prototypes) do
    if v.valid and not v.hidden then return v.name end
  end
  return "steam" -- no fluids?
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
  local dir = entity.direction
  -- 3 entities from north to south: assembler -> inserter -> chest
  local assembler = entity.surface.create_entity{
    name = Config.HIDDEN_ASSEMBLER_NAME,
    position = pos,
    force = entity.force,
  }
  local inserter = entity.surface.create_entity{
    name = Config.HIDDEN_INSERTER_NAME,
    position = pos,
    direction = isInput and Direction.opposite(dir) or dir, -- sets pickup driection. `dir` points to chest
    force = entity.force,
  }
  local chest = entity.surface.create_entity{
    name = Config.HIDDEN_CHEST_NAME,
    position = pos:translate(dir, .5),
    force = entity.force,
  }
  inserter.inserter_stack_size_override = 20
  inserter.pickup_target = isInput and assembler or chest
  inserter.drop_target = isInput and chest or assembler
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

function Pipe.onMovedEntity(event)
  local entity = event.moved_entity
  if not Config.isPipeName(entity.name) then return end
  local hidden = global.hiddenEntities[entity.unit_number]
  if not hidden then return end
  local pos = Position.new(entity.position)
  hidden.assembler.teleport(pos)
  hidden.inserter.teleport(pos)
  hidden.chest.teleport(pos:translate(entity.direction, .5))
end

function Pipe.updateFluidFilter(entity)
  local hidden = global.hiddenEntities[entity.unit_number]
  if not hidden then return end
  updateUnipipesForSystem(hidden.assembler.fluidbox, hidden.assembler.fluidbox.get_fluid_system_id(1))
end

function Pipe.setFluidFilter(entity, fluidName)
  local hidden = global.hiddenEntities[entity.unit_number]
  if not hidden then return end
  local isInput = entity.name == Config.PIPE_IN_NAME
  local itemName = Config.getFluidItem(fluidName)
  hidden.assembler.set_recipe(isInput and Config.getFluidFillRecipe(fluidName) or Config.getFluidEmptyRecipe(fluidName))
  hidden.assembler.direction = Direction.opposite(entity.direction)  -- need to set after setting recipe
  hidden.inserter.set_filter(1, itemName)
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
      if not fluidType and not isUnipipe and fluidbox[i] then fluidType = fluidbox[i].name end
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

function Pipe.openGui(player, entity)
  player.gui.relative.unipipeFrame.visible = true
  script.on_event(defines.events.on_tick, function(event)
    local hidden = global.hiddenEntities[entity.unit_number]
    if hidden then
      local inventory = hidden.chest.get_output_inventory()
      local itemType = inventory.get_filter(1)
      local fluidType = Config.getFluidFromFluidItem(itemType)
      local itemCount = inventory.get_item_count()
      local fluidPerItem = 100
      local maxItems = (#inventory * game.item_prototypes[itemType].stack_size)
      local contentsRow = player.gui.relative.unipipeFrame.contentsRow
      contentsRow.fluidFilter.elem_value = fluidType
      contentsRow.fluidFilter.tooltip = game.fluid_prototypes[fluidType].localised_name
      contentsRow.amountLabel.caption = { "zy-unipipe.amount", util.format_number(itemCount * fluidPerItem, true), util.format_number(maxItems * fluidPerItem, true) }
      contentsRow.amountBar.value = itemCount / maxItems
    end
  end)

  script.on_event(defines.events.on_gui_elem_changed, function(event)
    local element = event.element
    if not element.parent or element ~= element.parent.fluidFilter then return end
    if element.elem_value and element.elem_value ~= "" then
      -- Don't let them set an empty filter.
      Pipe.setFluidFilter(entity, element.elem_value)
    end
  end)

  script.on_event(defines.events.on_gui_closed, function(event)
    player.gui.relative.unipipeFrame.visible = false
    script.on_event(defines.events.on_tick, nil)
    script.on_event(defines.events.on_gui_elem_changed, nil)
  end)
end

function Pipe.buildGui(player)
  player.gui.relative.add {
    type = "frame",
    name = "unipipeFrame",
    direction = "vertical",
    caption = { "zy-unipipe.heading" },
    anchor = {
      gui = defines.relative_gui_type.pipe_gui,
      position = defines.relative_gui_position.bottom
    },
    style = "statistics_frame",
    visible = false
  }
  local contentsRow = player.gui.relative.unipipeFrame.add {
    type = "flow",
    name = "contentsRow",
    direction = "horizontal",
    style = "horizontal_flow_with_extra_right_margin",
  }
  contentsRow.add {
    type = "choose-elem-button",
    elem_type = "fluid",
    name = "fluidFilter",
    mouse_button_filter = {"left"},
    tooltip = "Fluid type",
    style = "slot_button",
  }
  contentsRow.add {
    type = "label",
    name = "amountLabel",
    caption = "0",
  }
  contentsRow.add {
    type = "progressbar",
    name = "amountBar",
    value = 0,
  }
  local note = player.gui.relative.unipipeFrame.add {
    type = "label",
    name = "note",
    single_line = false,
    caption = { "zy-unipipe.note" },
    style = "zy-unipipe-note",
  }
  note.style.horizontally_stretchable = true  -- why in fuck's sake is this not settable in the data stage?
end

function Pipe.destroyGui(player)
  if player.gui.relative.unipipeFrame then player.gui.relative.unipipeFrame.destroy() end
end
