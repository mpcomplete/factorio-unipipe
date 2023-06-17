local Config = {}

Config.CHEST_NAME = "zy-unichest"
Config.TOOL_NAME = "zy-unitool"
Config.PIPE_PREFIX = "zy-unipipe"
Config.PIPE_FILL_NAME = Config.PIPE_PREFIX .. "-fill"
Config.PIPE_EXTRACT_NAME = Config.PIPE_PREFIX .. "-extract"
Config.HIDDEN_INSERTER_NAME = Config.PIPE_PREFIX .. "-hidden-inserter"
Config.HIDDEN_ASSEMBLER_NAME = Config.PIPE_PREFIX .. "-hidden-assembler"
Config.HIDDEN_CHEST_NAME = Config.PIPE_PREFIX .. "-hidden-chest"
Config.HIDDEN_FLUID_PREFIX = Config.PIPE_PREFIX .. "-hidden-fluid"
Config.NULL_FLUID_NAME = Config.PIPE_PREFIX .. "-null-fluid"

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

function Config.getFluidExtractRecipe(fluidName)
  return Config.HIDDEN_FLUID_PREFIX .. "-extract-" .. fluidName
end

function Config.isPipeName(name)
  return name == Config.PIPE_FILL_NAME or name == Config.PIPE_EXTRACT_NAME
end

return Config