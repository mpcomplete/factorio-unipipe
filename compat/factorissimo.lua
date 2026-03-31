local FACTORISSIMO_REMOTE_NAME = "factorissimo"

function Pipe.getNetworkSurfaceFactorissimo(entity)
  local surface = entity.surface
  local position = entity.position

  local interfaces = remote.interfaces[FACTORISSIMO_REMOTE_NAME]
  if not interfaces or not interfaces.find_surrounding_factory then
    return surface
  end

  -- Recursively resolve nested factories upward to the topmost surface.
  -- Factorissimo interiors live on separate surfaces; keep mapping them to their parent surfaces
  -- until reaching a surface that is not itself inside a factory building.
  while true do
    local ok, factory = pcall(remote.call, FACTORISSIMO_REMOTE_NAME, "find_surrounding_factory", surface, position)
    if ok and factory and factory.outside_surface and factory.outside_surface.valid then
      -- Move up to the parent surface and continue checking from the parent factory's position
      surface = factory.outside_surface
      position = {x = factory.outside_x, y = factory.outside_y}
    else
      -- No more factories above; we've reached the outermost surface
      return surface
    end
  end
end
