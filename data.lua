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

data.raw["gui-style"].default["zy-unipipe-frame-contentsrow-style"] = {
  type = "horizontal_flow_style",
  padding = 0,
  horizontal_spacing = 0,
  vertical_spacing = 0,
  resize_row_to_width = true,
  resize_to_row_height = true,
  scalable = false,
}