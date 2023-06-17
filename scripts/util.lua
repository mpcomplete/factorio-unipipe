local table = require('__stdlib__/stdlib/utils/table')

local Util = {}

function Util.getNextId()
  global.nextId = (global.nextId or 0) + 1
  return global.nextId
end

function Util.getOrCreateId(name)
  local id = global.nameToId[name]
  if id == nil then
    id = Util.getNextId()
    global.nameToId[name] = id
  end
  return id
end

function Util.getNameFromId(id)
  for key, value in pairs(global.nameToId) do
    if value == id then
      return key
    end
  end
  return nil
end

function Util.setChestFilter(entity, itemName)
  local id = Util.getOrCreateId(itemName)
  entity.link_id = id
  local inventory = entity.get_output_inventory()
  for i = 1, #inventory do
    inventory.set_filter(i, itemName)
  end
end

return Util