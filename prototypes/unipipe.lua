local table = require('__stdlib__/stdlib/utils/table')
require("__base__/prototypes/entity/pipecovers")

local function makeEndcaps(isInput)
  local pipeToGround = table.deepcopy(data.raw["pipe-to-ground"]["pipe-to-ground"])
  local pictures = {
    north = pipeToGround.pictures.up,
    south = pipeToGround.pictures.down,
    east = pipeToGround.pictures.right,
    west = pipeToGround.pictures.left,
  }
  local shifts = {
    north = util.by_pixel(0, 44),
    south = util.by_pixel(0, -44),
    east = util.by_pixel(-44, 0),
    west = util.by_pixel(44, 0)
  }
  if isInput then
    shifts = {
      north = shifts.south,
      south = shifts.north,
      east = shifts.west,
      west = shifts.east
    }
    pictures = {
      north = pictures.south,
      south = pictures.north,
      east = pictures.west,
      west = pictures.east
    }
  end
  for k, v in pairs(shifts) do
    pictures[k].shift = v
    pictures[k].hr_version.shift = v
  end
  return pictures
end

local function createItemEntityRecipe(protoName, isInput)
  --- Item ---

  -- local pumpBase = table.deepcopy(data.raw["pump"]["pump"])
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

  local pumpBase = table.deepcopy(data.raw["pump"]["pump"])
  local endcaps = makeEndcaps(isInput)
  -- local endcaps = {
  --   north = {
  --     filename = "__base__/graphics/entity/pipe-to-ground/pipe-to-ground-down.png",
  --     priority = "high",
  --     width = 64,
  --     height = 64,
  --     shift = util.by_pixel(82, 0),
  --     hr_version =
  --     {
  --       filename = "__base__/graphics/entity/pipe-to-ground/hr-pipe-to-ground-down.png",
  --       priority = "extra-high",
  --       width = 128,
  --       height = 128,
  --       scale = 0.5,
  --       shift = util.by_pixel(82, 0),
  --     }
  --   },
  --   south = {
  --     filename = "__base__/graphics/entity/pipe-to-ground/pipe-to-ground-up.png",
  --     priority = "high",
  --     width = 64,
  --     height = 64,
  --     shift = util.by_pixel(83.5, 0),
  --     hr_version =
  --     {
  --       filename = "__base__/graphics/entity/pipe-to-ground/hr-pipe-to-ground-up.png",
  --       priority = "extra-high",
  --       width = 128,
  --       height = 128,
  --       scale = 0.5,
  --       shift = util.by_pixel(83.5, 0),
  --     }
  --   },
  --   east = {
  --     filename = "__base__/graphics/entity/pipe-to-ground/pipe-to-ground-right.png",
  --     priority = "high",
  --     width = 64,
  --     height = 64,
  --     shift = util.by_pixel(-44, 0),
  --     hr_version =
  --     {
  --       filename = "__base__/graphics/entity/pipe-to-ground/hr-pipe-to-ground-right.png",
  --       priority = "extra-high",
  --       width = 128,
  --       height = 128,
  --       scale = 0.5,
  --       shift = util.by_pixel(-44, 0),
  --     }
  --   },
  --   west = {
  --     filename = "__base__/graphics/entity/pipe-to-ground/pipe-to-ground-left.png",
  --     priority = "high",
  --     width = 64,
  --     height = 64,
  --     shift = util.by_pixel(44, 0),
  --     hr_version =
  --     {
  --       filename = "__base__/graphics/entity/pipe-to-ground/hr-pipe-to-ground-left.png",
  --       priority = "extra-high",
  --       width = 128,
  --       height = 128,
  --       scale = 0.5,
  --       shift = util.by_pixel(44, 0),
  --     }
  --   },
  -- }
  local entity = table.merge(table.deepcopy(data.raw["simple-entity-with-force"]["simple-entity-with-force"]), {
    name = protoName,
    icon = pumpBase.icon,
    icon_size = pumpBase.icon_size,
    icon_mipmaps = pumpBase.icon_mipmaps,
    minable = { mining_time = 0.2, result = protoName },
    gui_mode = "all",
    corpse = "",
    fluid_box = {},
    selecttable_in_game = true,
    collision_box = {{-0.29, -0.9}, {0.29, 0.9}},
    selection_box = {{-0.5, -1}, {0.5, 1}},
    picture = {
      north = { layers = {
        {
          filename = "__Unichest__/graphics/hr-unipipe-north.png",
          width = 88,
          height = 164,
          scale = 0.5,
          shift = util.by_pixel(4, 0),
          hr_version = {
            filename = "__Unichest__/graphics/hr-unipipe-north.png",
            width = 88,
            height = 164,
            scale = 0.5,
            shift = util.by_pixel(4, 0),
          }
        },
        endcaps.north
      }},
      south = { layers = {
        {
          filename = "__Unichest__/graphics/hr-unipipe-south.png",
          width = 88,
          height = 167,
          scale = 0.5,
          shift = util.by_pixel(4, 0),
          hr_version = {
            filename = "__Unichest__/graphics/hr-unipipe-south.png",
            width = 88,
            height = 167,
            scale = 0.5,
            shift = util.by_pixel(4, 0),
          }
        },
        endcaps.south
      }},
      east = { layers = {
        {
          filename = "__Unichest__/graphics/hr-unipipe-east.png",
          width = 144,
          height = 105,
          scale = 0.5,
          hr_version = {
            filename = "__Unichest__/graphics/hr-unipipe-east.png",
            width = 144,
            height = 105,
            scale = 0.5,
          }
        },
        endcaps.east
        -- {
        --   filename = "__base__/graphics/entity/pipe-to-ground/pipe-to-ground-right.png",
        --   priority = "high",
        --   width = 64,
        --   height = 64, --, shift = {0.1, 0.1}
        --   shift = util.by_pixel(-44, 0),
        --   hr_version =
        --   {
        --     filename = "__base__/graphics/entity/pipe-to-ground/hr-pipe-to-ground-right.png",
        --     priority = "extra-high",
        --     width = 128,
        --     height = 128,
        --     scale = 0.5,
        --     shift = util.by_pixel(-44, 0),
        --   }
        -- }
      }},
      west = { layers = {
        {
          filename = "__Unichest__/graphics/hr-unipipe-west.png",
          width = 144,
          height = 105,
          scale = 0.5,
          hr_version = {
            filename = "__Unichest__/graphics/hr-unipipe-west.png",
            width = 144,
            height = 105,
            scale = 0.5,
          }
        },
        endcaps.west
      }},
    }
  })

  --- Hidden entities ---

  local baseInserter = data.raw["inserter"]["stack-filter-inserter"]
  local baseHidden = {
      -- flags = {"placeable-player", "placeable-off-grid", "not-blueprintable", "not-deconstructable", "not-on-map", "hidden", "hide-alt-info", "not-flammable", "no-copy-paste", "not-selectable-in-game", "not-upgradable"},
      flags = {"placeable-player", "placeable-off-grid", "not-blueprintable", "not-deconstructable", "not-on-map", "hidden", "not-flammable", "no-copy-paste", "not-selectable-in-game", "not-upgradable"},
      collision_mask = {},
      -- selection_box = {{0,0}, {0,0}},
      order = "z",
      max_health = 2147483648,
      energy_source = { type = "void" },
  }
  local inserter = table.dictionary_combine(table.deepcopy(baseInserter), baseHidden, {
    name = Config.HIDDEN_INSERTER_NAME,
    extension_speed = 1,
    rotation_speed = 0.5,
    stack_size_bonus = 20,
    collision_box = {{-0.05, -0.05}, {0.05, 0.05}},
    pickup_position = {0, -.8},
    insert_position = {0, .8},
    draw_inserter_arrow = false,
    hand_base_picture = util.empty_sprite(1),
    hand_closed_picture = util.empty_sprite(1),
    hand_open_picture = util.empty_sprite(1),
    hand_base_shadow = util.empty_sprite(1),
    hand_closed_shadow = util.empty_sprite(1),
    hand_open_shadow = util.empty_sprite(1),
    platform_picture = util.empty_sprite(1),
  })
  inserter.minable = nil

  local baseAssembler = data.raw["assembling-machine"]["assembling-machine-3"]
  local assembler = table.dictionary_combine(table.deepcopy(baseAssembler), baseHidden, {
    name = Config.HIDDEN_ASSEMBLER_NAME,
    collision_box = {{-0.6, -0.6}, {0.6, 0.6}},
    drawing_box = {{0,0}, {0,0}},
    crafting_speed = 100,
    bottleneck_ignore = true,
  })
  assembler.fluid_boxes[1].pipe_connections[1].position = {0, -1.5}
  assembler.fluid_boxes[2].pipe_connections[1].position = {0, 1.5}
  assembler.minable = nil
  assembler.animation = nil
  assembler.module_specification = nil
  assembler.allowed_effects = nil

  local baseChest = data.raw["linked-container"]["linked-chest"]
  local chest = table.dictionary_combine(table.deepcopy(baseChest), baseHidden, {
    name = Config.HIDDEN_CHEST_NAME,
    picture = util.empty_sprite(1),
    inventory_size = 48,
    inventory_type = "with_filters_and_bar",
    gui_mode = "all",
  })
  chest.minable = nil
  -- function logtable(name, t)
  --   for k,v in pairs(t) do
  --     if type(v) == "table" then
  --       logtable(name .. "." .. k, v)
  --     elseif type(v) == "string" or type(v) == "number" then
  --       log(name .. "." .. k .. ": " .. v)
  --     else
  --       log(name .. "." .. k .. ": some type=" .. type(v))
  --     end
  --   end
  -- end
  -- logtable("asm", assembler)
  
  --- Recipe ---
  local crafting_cost = settings.startup["zy-uni-crafting-cost"].value
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

  return {item, entity, recipe, inserter, assembler, chest}
end

local function create(protoName, protoNameIn, protoNameOut)
  local inputProtos = createItemEntityRecipe(protoNameIn, true)
  local outputProtos = createItemEntityRecipe(protoNameOut, false)

  --- Technology ---

  local research = settings.startup["zy-uni-required-research"].value
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

create(Config.PIPE_PREFIX, Config.PIPE_IN_NAME, Config.PIPE_OUT_NAME)