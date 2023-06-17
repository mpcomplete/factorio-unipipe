data:extend({
  {
    type = "int-setting",
    name = "zy-unipipe-storage-size",
    order = "c",
    setting_type = "startup",
    default_value = 42*200,
    minimum_value = 200,
    maximum_value = 4000*200,
  },
  {
    type = "string-setting",
    name = "zy-unipipe-required-research",
    setting_type = "startup",
    default_value = "chemical",
    allowed_values = { "automation", "logistic", "chemical", "production", "utility", "space" }
  },
  {
    type = "string-setting",
    name = "zy-unipipe-crafting-cost",
    setting_type = "startup",
    default_value = "easy",
    allowed_values = { "easy", "medium", "hard" }
  }
})
