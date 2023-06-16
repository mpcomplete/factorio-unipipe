local Config = {}

Config.CHEST_NAME = "filtered-linked-chest"
Config.TOOL_NAME = "filtered-linked-chest-tool"
Config.PIPE_NAME_PREFIX = "filtered-linked-pipe"
Config.PIPE_IN_NAME = Config.PIPE_NAME_PREFIX .. "-in"
Config.PIPE_OUT_NAME = Config.PIPE_NAME_PREFIX .. "-out"
Config.HIDDEN_INSERTER_NAME = "filtered-linked-pipe-hidden-inserter"
Config.HIDDEN_ASSEMBLER_NAME = "filtered-linked-pipe-hidden-assembler"
Config.HIDDEN_CHEST_NAME = "filtered-linked-pipe-hidden-chest"
Config.HIDDEN_FLUID_PREFIX = "filtered-linked-pipe-hidden-fluid"

function Config.getFluidItem(fluidName)
  return Config.HIDDEN_FLUID_PREFIX .. "-" .. fluidName
end

function Config.getFluidFillRecipe(fluidName)
  return "fill-" .. Config.HIDDEN_FLUID_PREFIX .. "-" .. fluidName
end

function Config.getFluidEmptyRecipe(fluidName)
  return "empty-" .. Config.HIDDEN_FLUID_PREFIX .. "-" .. fluidName
end

function Config.isPipeName(name)
  return name == Config.PIPE_IN_NAME or name == Config.PIPE_OUT_NAME
end

return Config