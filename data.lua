Config = require("config")
require("prototypes.prototypes")

data:extend({
  {
    type = "custom-input",
    name = "zy-uni-paste-alt",
    key_sequence = "SHIFT + ALT + mouse-button-1",
    consuming = "none"
  }
})

data.raw["gui-style"].default["zy-unipipe-note"] = {
  type = "label_style",
  resize_row_to_width = false,
  single_line = false,
}