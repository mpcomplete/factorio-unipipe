Config = require("config")
require("scripts/main")
require("scripts/unipipe")

for modName, _ in pairs(script.active_mods) do
	if string.find(modName, "^factorissimo") then
		if settings.startup["zy-unipipe-factorissimo-compat"].value then
			require("compat/factorissimo")
			Pipe.getNetworkSurface = Pipe.getNetworkSurfaceFactorissimo
		end
		break
	end
end