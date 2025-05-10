local Config = {}

Config.TOOL_NAME = "zy-unitool"
Config.PIPE_PREFIX = "zy-unipipe"
Config.PIPE_FILL_NAME = Config.PIPE_PREFIX .. "-fill"
Config.PIPE_EXTRACT_NAME = Config.PIPE_PREFIX .. "-extract"
Config.HIDDEN_SURFACE_NAME = Config.PIPE_PREFIX .. "-hidden-surface"
Config.HIDDEN_PIPE_NAME = Config.PIPE_PREFIX .. "-hidden-pipe" -- connects all pipes of the same fluid together
Config.HIDDEN_LINKED_PIPE_NAME = Config.PIPE_PREFIX .. "-hidden-linked-pipe" -- links pipe-fill and pipe-extract to the hidden-pipe

function Config.isPipeName(name)
  return name == Config.PIPE_FILL_NAME or name == Config.PIPE_EXTRACT_NAME
end

return Config