data:extend({
  {
    type = "int-setting",
    name = "flc-inventory-size",
    order = "c",
    setting_type = "startup",
    default_value = 10,
    minimum_value = 1,
    maximum_value = 4069
  },
  {
    type = "string-setting",
    name = "flc-required-research",
    setting_type = "startup",
    default_value = "chemical",
    allowed_values = { "automation", "logistic", "chemical", "production", "utility", "space" }
  },
  {
    type = "string-setting",
    name = "flc-crafting-cost",
    setting_type = "startup",
    default_value = "easy",
    allowed_values = { "easy", "medium", "hard" }
  }
})