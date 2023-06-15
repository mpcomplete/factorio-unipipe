local icon = "__base__/graphics/icons/linked-chest-icon.png"

data:extend({
  {
    type = "selection-tool",
    name = "filtered-linked-chest-tool",
    icon = icon,
    flags = { "hidden", "only-in-cursor", "not-stackable", "spawnable" },
    subgroup = "tool",
    order = "c[automated-construction]-b[deconstruction-planner]",
    stack_size = 1,
    icon_size = 64,
    stackable = false,
    selection_color = { r = 0, g = 1, b = 0 },
    alt_selection_color = { r = 0, g = 1, b = 0 },
    selection_mode = { "nothing" },
    alt_selection_mode = { "nothing" },
    selection_cursor_box_type = "pair",
    alt_selection_cursor_box_type = "pair",
    show_in_library = true
  },
  {
    type = "shortcut",
    name = "filtered-linked-chest-tool",
    order = "o[filtered-linked-chest-tool]",
    action = "spawn-item",
    item_to_spawn = "filtered-linked-chest-tool",
    toggleable = true,
    icon = {
      filename = icon,
      -- priority = "extra-high-no-scale",
      size = 64,
      scale = 0.5,
      flags = { "gui-icon" }
    }
    -- small_icon = {
    --   filename = icon,
    --   -- priority = "extra-high-no-scale",
    --   size = 64,
    --   scale = 0.5,
    --   flags = { "gui-icon" }
    -- },
    -- disabled_small_icon = {
    --   filename = icon,
    --   -- priority = "extra-high-no-scale",
    --   size = 64,
    --   scale = 0.5,
    --   flags = { "gui-icon" }
    -- }
  }
})
