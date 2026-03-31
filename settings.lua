data:extend({
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
  },
  {
    type = "bool-setting",
    name = "zy-unipipe-per-surface",
    setting_type = "startup",
    default_value = true
  },
  {
    type = "bool-setting",
    name = "zy-unipipe-factorissimo-compat",
    setting_type = "startup",
    default_value = true,
    description = "When enabled, Unipipe networks treat Factorissimo building interiors as part of their parent surface, even with per-surface mode enabled."
  },
  {
    type = "string-setting",
    name = "zy-unipipe-autofilter-mode",
    setting_type = "runtime-global",
    default_value = "any",
    allowed_values = { "any", "unipipe", "disabled" }
  }
})