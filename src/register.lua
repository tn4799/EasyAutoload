-- init easyAutoLoad
-- put together by alfalfa6945

if g_modIsLoaded["FS19_EasyAutoLoad"] then
	local specTypeName = "easyAutoLoader"
	local className = "easyAutoLoader"
	local filename = Utils.getFilename("easyAutoLoader.lua", g_currentModDirectory.."scripts/")
	g_specializationManager:addSpecialization(specTypeName, className, filename)
	local baseType = {"baseAttachable", "baseDrivable"}
	for index, typeName in ipairs({"autoloadTrailer", "autoloadTruck"}) do
		local parentName = baseType[index]
		local parent = g_vehicleTypeManager.vehicleTypes[parentName]
		if parent ~= nil then
			g_vehicleTypeManager:addVehicleType(typeName, "Vehicle", parent.filename, nil)
			for _, specName in ipairs(parent.specializationNames) do
				g_vehicleTypeManager:addSpecialization(typeName, specName)
			end
		end
		for _, specName in ipairs({"tensionBelts", "easyAutoLoader"}) do
			local spec = g_specializationManager:getSpecializationByName(specName)
			g_vehicleTypeManager:addSpecialization(typeName, spec.name)
		end
	end
end
-- interim prepend, too many mods using easyAutoLoad script...
Mission00.load = Utils.prependedFunction(Mission00.load, function (mission)
	if g_modIsLoaded["FS19_EasyAutoLoad"] then
		local conflict = false
		for typeName, typeEntry in pairs(g_vehicleTypeManager.vehicleTypes) do
			for i = 1, #typeEntry.specializationNames do
				if string.match(typeEntry.specializationNames[i], 'easyAutoLoader') then
					if typeEntry.specializationNames[i] ~= "FS19_EasyAutoLoad.easyAutoLoader"  then
						conflict = true
						local mod, vehicleTypeName = string.match(typeName, "([^.]+).([^.]+)")
						print("  Warning: vehicleType "..'"'..vehicleTypeName..'"'.." in the mod "..'"'..mod..'"'.." conflicts with FS19_EasyAutoLoad")
					end
				end
			end
		end
		if conflict then
			print("  Valid easyAutoLoad vehicleTypes are \"autoloadTrailer\", \"autoloadTruck\"")
		end
	end
end)