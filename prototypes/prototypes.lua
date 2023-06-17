require("unipipe")

-- Add null fluid for default unipipe recipe.
data:extend({
  {
    type = "fluid",
    name = Config.NULL_FLUID_NAME,
    default_temperature = 15,
    max_temperature = 100,
    heat_capacity = "0.2KJ",
    base_color = {r=0, g=0.34, b=0.6},
    flow_color = {r=0.7, g=0.7, b=0.7},
    icon = "__base__/graphics/icons/signal/signal_each.png",
    icon_size = 64, icon_mipmaps = 4,
    order = "a[fluid]-a[null]",
    hidden = true,
    flags = {"hidden", "hide-from-bonus-gui"},
    auto_barrel = false,
  }
})