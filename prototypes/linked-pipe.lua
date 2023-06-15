local table = require('__stdlib__/stdlib/utils/table')

local function createItemEntityRecipe(protoName, isInput)
  --- Item ---

  local pumpBase = table.deepcopy(data.raw["pump"]["pump"])
  local icon = pumpBase.icon
  local item = table.merge(table.deepcopy(data.raw["item"]["pump"]), {
    type = "item",
    name = protoName,
    -- icon = icon,
    -- icon_size = 64,
    -- icon_mipmaps = 4,
    subgroup = "storage",
    order = "b[fluid]-a[" .. protoName .. "]",
    place_result = protoName,
    stack_size = 50
  })

  --- Entity ---

  local fluidBox =
      isInput and {
        production_type = "input",
        pipe_covers = pumpBase.fluid_box.pipe_covers,
        base_area = 10,
        base_level = -1,
        pipe_connections =
        {
          {
            type = "input",
            position = { 1, -2 }
          }
        }
      } or {
        production_type = "output",
        pipe_covers = pumpBase.fluid_box.pipe_covers,
        base_level = 1,
        pipe_connections =
        {
          {
            type = "output",
            position = { -1, 2 }
          }
        }
      }
  local entity = table.merge(pumpBase, {
    type = "pump",
    name = protoName,
    minable = { mining_time = 0.2, result = protoName },
    gui_mode = "all",
    corpse = "",
    -- fluid_box = fluidBox,
    selecttable_in_game = true,
    collision_box = {{-0.29, -0.9}, {0.29, 0.9}},
    selection_box = {{-0.5, -1}, {0.5, 1}},
  })

  --- Recipe ---
  local crafting_cost = settings.startup["flc-crafting-cost"].value
  local ingredients = {
      --crafting_cost == "easy" and {
        { "iron-plate", 20 }
  }
  ingredients =
      crafting_cost == "medium" and {
        { "steel-chest",        10 },
        { "iron-plate",         100 },
        { "copper-plate",       100 },
        { "electronic-circuit", 50 },
      } or crafting_cost == "hard" and {
        { "steel-chest",      20 },
        { "iron-plate",       100 },
        { "copper-plate",     100 },
        { "advanced-circuit", 50 },
        { "processing-unit",  10 }
      } or ingredients
  local recipe = {
    type = "recipe",
    name = protoName,
    enabled = false,
    ingredients = ingredients,
    result = protoName
  }

  return {item, entity, recipe}
end

local function create(protoName, protoNameIn, protoNameOut)
  local inputProtos = createItemEntityRecipe(protoNameIn, true)
  local outputProtos = createItemEntityRecipe(protoNameOut, false)

  --- Technology ---

  local research = settings.startup["flc-required-research"].value
  local tech = {
      -- research == "automation" and {
        count = 10,
        ingredients = {
          { "automation-science-pack", 1 },
        },
        prerequisites = {
          "logistics",
          "electronics",
          "steel-processing"
        }
      }
  tech =
      research == "logistic" and {
        count = 50,
        ingredients = {
          { "automation-science-pack", 1 },
          { "logistic-science-pack",   1 }
        },
        prerequisites = {
          "logistics",
          "fast-inserter",
          "steel-processing",
          "logistic-science-pack"
        }
      } or research == "chemical" and {
        count = 100,
        ingredients = {
          { "automation-science-pack", 1 },
          { "logistic-science-pack",   1 },
          { "chemical-science-pack",   1 }
        },
        prerequisites = {
          "logistics-2",
          "stack-inserter",
          "logistic-science-pack",
          "chemical-science-pack"
        }
      } or research == "production" and {
        count = 200,
        ingredients = {
          { "automation-science-pack", 1 },
          { "logistic-science-pack",   1 },
          { "chemical-science-pack",   1 },
          { "production-science-pack", 1 }
        },
        prerequisites = {
          "logistics-3",
          "stack-inserter",
          "advanced-electronics",
          "logistic-science-pack",
          "chemical-science-pack",
          "production-science-pack"
        }
      } or research == "utility" and {
        count = 500,
        ingredients = {
          { "automation-science-pack", 1 },
          { "logistic-science-pack",   1 },
          { "chemical-science-pack",   1 },
          { "production-science-pack", 1 },
          { "utility-science-pack",    1 }
        },
        prerequisites = {
          "logistics-3",
          "stack-inserter",
          "inserter-capacity-bonus-1",
          "logistic-science-pack",
          "chemical-science-pack",
          "production-science-pack",
          "utility-science-pack"
        }
      } or research == "space" and {
        count = 1000,
        ingredients = {
          { "automation-science-pack", 1 },
          { "logistic-science-pack",   1 },
          { "chemical-science-pack",   1 },
          { "production-science-pack", 1 },
          { "utility-science-pack",    1 },
          { "space-science-pack",      1 }
        },
        prerequisites = {
          "logistics-3",
          "stack-inserter",
          "inserter-capacity-bonus-1",
          "logistic-science-pack",
          "chemical-science-pack",
          "production-science-pack",
          "utility-science-pack",
          "space-science-pack"
        }
      } or tech
  local technology = {
    type = "technology",
    name = protoName,
    icon = inputProtos[1].icon,
    icon_size = 64,
    icon_mipmaps = 4,
    effects = {
      {
        type = "unlock-recipe",
        recipe = protoNameIn
      },
      {
        type = "unlock-recipe",
        recipe = protoNameOut
      }
    },
    unit = {
      count = tech.count,
      ingredients = tech.ingredients,
      time = 30
    },
    prerequisites = tech.prerequisites,
    order = "a-b-b",
  }

  data:extend(inputProtos)
  data:extend(outputProtos)
  data:extend({ technology })
end

create(Config.PIPE_NAME_PREFIX, Config.PIPE_IN_NAME, Config.PIPE_OUT_NAME)