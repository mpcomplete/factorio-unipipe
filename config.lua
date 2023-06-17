local Config = {}

Config.MOD_PREFIX = "zy-uni"
Config.PIPE_PREFIX = Config.MOD_PREFIX .. "pipe"
Config.CHEST_NAME = Config.MOD_PREFIX .. "chest"
Config.TOOL_NAME = Config.MOD_PREFIX .. "tool"
Config.PIPE_IN_NAME = Config.PIPE_PREFIX .. "-in"
Config.PIPE_OUT_NAME = Config.PIPE_PREFIX .. "-out"
Config.HIDDEN_INSERTER_NAME = Config.PIPE_PREFIX .. "-hidden-inserter"
Config.HIDDEN_ASSEMBLER_NAME = Config.PIPE_PREFIX .. "-hidden-assembler"
Config.HIDDEN_CHEST_NAME = Config.PIPE_PREFIX .. "-hidden-chest"
Config.HIDDEN_FLUID_PREFIX = Config.PIPE_PREFIX .. "-hidden-fluid"

function Config.getFluidItem(fluidName)
  return Config.HIDDEN_FLUID_PREFIX .. "-" .. fluidName
end

function Config.getFluidFromFluidItem(fluidItemName)
  local n = string.len(Config.HIDDEN_FLUID_PREFIX .. "-")
  return string.sub(fluidItemName, n+1, -1)
end

function Config.getFluidFillRecipe(fluidName)
  return Config.HIDDEN_FLUID_PREFIX .. "-fill-" .. fluidName
end

function Config.getFluidEmptyRecipe(fluidName)
  return Config.HIDDEN_FLUID_PREFIX .. "-empty-" .. fluidName
end

function Config.isPipeName(name)
  return name == Config.PIPE_IN_NAME or name == Config.PIPE_OUT_NAME
end

return Config