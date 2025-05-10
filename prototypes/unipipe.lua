-- TODO
-- item/research/tech icons

local table = require('__kry_stdlib__/stdlib/utils/table')

local function makeEndcaps(isInput)
  local pictures = {
    north = {
      filename = "__Unipipe__/graphics/hr-pipe-to-ground-up.png",
      priority = "high",
      width = 128,
      height = 128,
      scale = 0.5,
      hr_version = {
        filename = "__Unipipe__/graphics/hr-pipe-to-ground-up.png",
        priority = "extra-high",
        width = 128,
        height = 128,
        scale = 0.5
      }
    },
    south = {
      filename = "__Unipipe__/graphics/hr-pipe-to-ground-down.png",
      priority = "high",
      width = 128,
      height = 128,
      scale = 0.5,
      hr_version = {
        filename = "__Unipipe__/graphics/hr-pipe-to-ground-down.png",
        priority = "extra-high",
        width = 128,
        height = 128,
        scale = 0.5
      }
    },
    west = {
      filename = "__Unipipe__/graphics/hr-pipe-to-ground-left.png",
      priority = "high",
      width = 128,
      height = 128,
      scale = 0.5,
      hr_version = {
        filename = "__Unipipe__/graphics/hr-pipe-to-ground-left.png",
        priority = "extra-high",
        width = 128,
        height = 128,
        scale = 0.5
      }
    },
    east = {
      filename = "__Unipipe__/graphics/hr-pipe-to-ground-right.png",
      priority = "high",
      width = 128,
      height = 128,
      scale = 0.5,
      hr_version = {
        filename = "__Unipipe__/graphics/hr-pipe-to-ground-right.png",
        priority = "extra-high",
        width = 128,
        height = 128,
        scale = 0.5
      }
    }
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

  local icon = isInput and "__Unipipe__/graphics/unipipe-fill.png" or "__Unipipe__/graphics/unipipe-extract.png"
  local item = table.merge(table.deepcopy(data.raw["item"]["pump"]), {
    type = "item",
    name = protoName,
    icon = icon,
    icon_size = 64,
    icon_mipmaps = 4,
    subgroup = "storage",
    order = "b[fluid]-a[" .. protoName .. "]",
    place_result = protoName,
    stack_size = 50
  })

  --- Entity ---

  local endcaps = makeEndcaps(isInput)
  local entity = table.merge(table.deepcopy(data.raw["pump"]["pump"]), {
    name = protoName,
    icon = icon,
    icon_size = 64,
    icon_mipmaps = 4,
    minable = { mining_time = 0.2, result = protoName },
    gui_mode = "all",
    corpse = "",
		fluid_box =
		{
			max_pipeline_extent = 4294967295,
			volume = 20,
			pipe_covers = pipecoverspictures(),
			pipe_connections =
        isInput and
          {
            { direction = defines.direction.south, position = {0, 0.5}, flow_direction = "input" },
            { connection_type="linked", linked_connection_id=1, flow_direction = "output" },
          }
        or
          {
            { direction = defines.direction.north, position = {0, -0.5}, flow_direction = "output" },
            { connection_type="linked", linked_connection_id=1, flow_direction = "input" },
          }
		},
    -- fluid_box = { volume = 10000, pipe_connections = {} },
    energy_source = { type = "void" },
    pumping_speed = 200,
    selecttable_in_game = true,
    -- collision_box = {{-0.29, -0.9}, {0.29, 0.9}},
    -- selection_box = {{-0.2, -.2}, {0.2, .2}},
    -- selection_box = {{-0.5, -1}, {0.5, 1}},
    animations = {
      north = { layers = {
        {
          filename = "__Unipipe__/graphics/hr-unipipe-north.png",
          width = 88,
          height = 164,
          scale = 0.5,
          shift = util.by_pixel(4, 0),
          hr_version = {
            filename = "__Unipipe__/graphics/hr-unipipe-north.png",
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
          filename = "__Unipipe__/graphics/hr-unipipe-south.png",
          width = 88,
          height = 167,
          scale = 0.5,
          shift = util.by_pixel(4, 0),
          hr_version = {
            filename = "__Unipipe__/graphics/hr-unipipe-south.png",
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
          filename = "__Unipipe__/graphics/hr-unipipe-east.png",
          width = 144,
          height = 105,
          scale = 0.5,
          hr_version = {
            filename = "__Unipipe__/graphics/hr-unipipe-east.png",
            width = 144,
            height = 105,
            scale = 0.5,
          }
        },
        endcaps.east
      }},
      west = { layers = {
        {
          filename = "__Unipipe__/graphics/hr-unipipe-west.png",
          width = 144,
          height = 105,
          scale = 0.5,
          hr_version = {
            filename = "__Unipipe__/graphics/hr-unipipe-west.png",
            width = 144,
            height = 105,
            scale = 0.5,
          }
        },
        endcaps.west
      }},
    }
  })

  --- Recipe ---
  local crafting_cost = settings.startup["zy-unipipe-crafting-cost"].value
  local ingredients = {
      --crafting_cost == "easy" and {
        { type = "item", name = "iron-gear-wheel", amount = 1 },
        { type = "item", name = "electronic-circuit", amount = 1 },
        { type = "item", name = "pipe-to-ground", amount = 1 },
  }
  ingredients =
      crafting_cost == "medium" and {
        { type = "item", name = "pump",               amount = 2 },
        { type = "item", name = "pipe-to-ground",     amount = 1 },
        { type = "item", name = "storage-tank",       amount = 5 },
        { type = "item", name = "advanced-circuit",   amount = 5 },
      } or crafting_cost == "hard" and {
        { type = "item", name = "pump",               amount = 2 },
        { type = "item", name = "pipe-to-ground",     amount = 1 },
        { type = "item", name = "storage-tank",       amount = 50 },
        { type = "item", name = "processing-unit",    amount = 10 }
      } or ingredients
  local recipe = {
    type = "recipe",
    name = protoName,
    enabled = false,
    ingredients = ingredients,
    results = { { type = "item", name = protoName, amount = 1 } },
    auto_recycle = false,
  }

  return {item, entity, recipe}
end

local function create(protoName, protoNameIn, protoNameOut)
  local inputProtos = createItemEntityRecipe(protoNameIn, true)
  local outputProtos = createItemEntityRecipe(protoNameOut, false)

  --- Hidden entities ---
  local baseHidden = {
    flags = {"placeable-player", "placeable-off-grid", "not-blueprintable", "not-deconstructable", "not-on-map", "hide-alt-info", "not-flammable", "no-copy-paste", "not-selectable-in-game", "not-upgradable"},
    -- hidden = true,
    hidden_in_factoriopedia = true,
    order = "z",
    max_health = 2147483648,
    energy_source = { type = "void" },
  }
  local linkedPipe = table.merge(
    table.merge(table.deepcopy(data.raw["pipe-to-ground"]["pipe-to-ground"]), baseHidden), {
      name = Config.HIDDEN_LINKED_PIPE_NAME,
    }
  )
  linkedPipe["fluid_box"].volume = 100
  linkedPipe["fluid_box"].max_pipeline_extent=4294967295
  linkedPipe["fluid_box"]["pipe_connections"][2]={
    connection_type = "linked",
    linked_connection_id = 1,
  }

  local pipe = table.merge(
    table.merge(table.deepcopy(data.raw["pipe"]["pipe"]), baseHidden), {
      name = Config.HIDDEN_PIPE_NAME,
    }
  )
  pipe["fluid_box"].volume = 100
  pipe["fluid_box"].max_pipeline_extent=4294967295

  --- Technology ---

  local research = settings.startup["zy-unipipe-required-research"].value
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
  data:extend({ pipe, linkedPipe, technology })
end

create(Config.PIPE_PREFIX, Config.PIPE_FILL_NAME, Config.PIPE_EXTRACT_NAME)