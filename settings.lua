data:extend({
  {
    type = "int-setting",
    name = "zy-unipipe-storage-size",
    order = "c",
    setting_type = "startup",
    -- 20k per hidden chest slot (see data-updates.lua)
    minimum_value = 20,
    maximum_value = 20*4000,
    default_value = 20*42,
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
