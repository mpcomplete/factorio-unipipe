local Config = require("config")

-- 20000 fluid per slot (200*100)
local fluid_per_item = 100
local fluid_item_stack_size = 200

-- Generates a fluid item with the provided name and fluid definition using the provided empty barrel stack size
local function createFluidItem(name, fluid)
  local icon = fluid.icon and {
    icon = fluid.icon,
    icon_size = fluid.icon_size,
    icon_mipmaps = fluid.icon_mipmaps,
  } or {
    icon = util.empty_sprite(1).filename,
    icon_size = 1,
    icon_mipmaps = 1,
  }
  local result = {
    type = "item",
    name = name,
    localised_name = {"item-name.zy-unipipe-fluid-item", fluid.localised_name or {"fluid-name." .. fluid.name}},
    flags = {"hidden", "hide-from-bonus-gui"},
    icon = icon.icon,
    icon_size = icon.icon_size,
    icon_mipmaps = icon.icon_mipmaps,
    subgroup = "barrel",
    order = "b[" .. name .. "]",
    stack_size = fluid_item_stack_size,
  }

  data:extend({result})
  return result
end

-- Creates a recipe to fill the provided fluid item with the provided fluid
local function createFillRecipe(item, fluid)
  local recipe = {
    type = "recipe",
    name = Config.getFluidFillRecipe(fluid.name),
    localised_name = {"recipe-name.zy-unipipe-fill", fluid.localised_name or {"fluid-name." .. fluid.name}},
    category = "crafting-with-fluid",
    subgroup = "fill-barrel",
    order = "b[fill-" .. item.name .. "]",
    energy_required = 0.01,
    enabled = true,
    hidden = true,
    hide_from_stats = true,
    icon = item.icon,
    icon_size = item.icon_size,
    icon_mipmaps = item.icon_mipmaps,
    ingredients =
    {
      {type = "fluid", name = fluid.name, amount = fluid_per_item, catalyst_amount = fluid_per_item},
    },
    results =
    {
      {type = "item", name = item.name, amount = 1, catalyst_amount = 1}
    },
    allow_decomposition = false
  }

  data:extend({recipe})
  return recipe
end

-- Creates a recipe to extract the provided fluid item producing the provided fluid
local function createExtractRecipe(item, fluid)
  local recipe = {
    type = "recipe",
    name = Config.getFluidExtractRecipe(fluid.name),
    localised_name = {"recipe-name.zy-unipipe-extract", fluid.localised_name or {"fluid-name." .. fluid.name}},
    category = "crafting-with-fluid",
    subgroup = "empty-barrel",
    order = "c[empty-" .. item.name .. "]",
    energy_required = 0.01,
    enabled = true,
    hidden = true,
    hide_from_stats = true,
    icon = item.icon,
    icon_size = item.icon_size,
    icon_mipmaps = item.icon_mipmaps,
    ingredients =
    {
      {type = "item", name = item.name, amount = 1, catalyst_amount = 1}
    },
    results=
    {
      {type = "fluid", name = fluid.name, amount = fluid_per_item, catalyst_amount = fluid_per_item},
    },
    allow_decomposition = false
  }

  data:extend({recipe})
  return recipe
end

local function processFluid(fluid)
  local item = createFluidItem(Config.getFluidItem(fluid.name), fluid)
  createFillRecipe(item, fluid)
  createExtractRecipe(item, fluid)
end

for _, fluid in pairs(data.raw["fluid"] or {}) do
  processFluid(fluid)
end