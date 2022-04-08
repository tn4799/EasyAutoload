-- A basic autoloading script
-- put together by alfalfa6945
-- version 0.1.1.2
-- ***script is still in early development, you really shouldn't use it in a production environment

easyAutoLoader = {}

local autoloadModName = g_currentModName

function easyAutoLoader.prerequisitesPresent(specializations)
	return true
end

function easyAutoLoader.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "doStateChange", easyAutoLoader.doStateChange)
	SpecializationUtil.registerFunction(vehicleType, "setMarkerVisibility", easyAutoLoader.setMarkerVisibility)
	SpecializationUtil.registerFunction(vehicleType, "setMarkerPosition", easyAutoLoader.setMarkerPosition)
	SpecializationUtil.registerFunction(vehicleType, "setUnloadPosition", easyAutoLoader.setUnloadPosition)
	SpecializationUtil.registerFunction(vehicleType, "objectCallback", easyAutoLoader.objectCallback)
	SpecializationUtil.registerFunction(vehicleType, "setWorkMode", easyAutoLoader.setWorkMode)
	SpecializationUtil.registerFunction(vehicleType, "setSelect", easyAutoLoader.setSelect)
	SpecializationUtil.registerFunction(vehicleType, "setUnload", easyAutoLoader.setUnload)
	SpecializationUtil.registerFunction(vehicleType, "changeMarkerPosition", easyAutoLoader.changeMarkerPosition)
	SpecializationUtil.registerFunction(vehicleType, "moveMarkerLeft", easyAutoLoader.moveMarkerLeft)
	SpecializationUtil.registerFunction(vehicleType, "moveMarkerRight", easyAutoLoader.moveMarkerRight)
	SpecializationUtil.registerFunction(vehicleType, "moveMarkerUp", easyAutoLoader.moveMarkerUp)
	SpecializationUtil.registerFunction(vehicleType, "moveMarkerDown", easyAutoLoader.moveMarkerDown)
	SpecializationUtil.registerFunction(vehicleType, "moveMarkerForward", easyAutoLoader.moveMarkerForward)
	SpecializationUtil.registerFunction(vehicleType, "moveMarkerBackward", easyAutoLoader.moveMarkerBackward)
	SpecializationUtil.registerFunction(vehicleType, "moveMarkerOriginal", easyAutoLoader.moveMarkerOriginal)
	SpecializationUtil.registerFunction(vehicleType, "setMarkerRotation", easyAutoLoader.setMarkerRotation)
	SpecializationUtil.registerFunction(vehicleType, "triggerHelperMode", easyAutoLoader.triggerHelperMode)
	SpecializationUtil.registerFunction(vehicleType, "updateBindings", easyAutoLoader.updateBindings)
	SpecializationUtil.registerFunction(vehicleType, "isDedicatedServer", easyAutoLoader.isDedicatedServer)
end

function easyAutoLoader.registerEventListeners(vehicleType)
	for _, spec in pairs({"onLoad", "onPostLoad", "onDelete", "onUpdate", "onDraw", "onReadStream", "onWriteStream", "onRegisterActionEvents", "saveToXMLFile"}) do
		SpecializationUtil.registerEventListener(vehicleType, spec, easyAutoLoader)
	end
end

function easyAutoLoader:onLoad(savegame)
	self.spec_easyAutoLoader = {}
	local spec = self.spec_easyAutoLoader
	spec.moveTrigger = getXMLString(self.xmlFile, "vehicle.easyAutoLoad#triggerAnimation")
	spec.workMode = false
	spec.currentNumObjects = 0
	spec.unloadPosition = 1
	spec.state = 1
	spec.var = 0
	spec.centerMarkerIndex = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.easyAutoLoad#centerMarkerIndex"), 1)
	spec.unloadHeightOffset = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.easyAutoLoad#unloadHeightOffset"), 1.1)
	spec.unloadMarker = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.easyAutoLoad#markerIndex"), self.i3dMappings)
	spec.useMarkerRotate = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.easyAutoLoad#useMarkerRotate"), false)
	spec.markerVisible = false
	if spec.unloadMarker then
		local markerLength = Utils.getNoNil(getUserAttribute(spec.unloadMarker, "markerLength"), 15.77)
		local markerLengthCenterOffset = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.easyAutoLoad.moveableMarkerOptions#markerLengthCenterOffset"), 0)
		 spec.unloaderMarkerYoffset = (markerLength + markerLengthCenterOffset) / 2 
		if getVisibility(spec.unloadMarker) then
			spec.markerVisible = true
			self:setMarkerVisibility(false, true)
		end
	end
	spec.markerMoveSpeed = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.easyAutoLoad.moveableMarkerOptions#markerMoveSpeed"), 0.05)
	spec.markerMinX = StringUtil.splitString(" ", Utils.getNoNil(getXMLString(self.xmlFile, "vehicle.easyAutoLoad.moveableMarkerOptions#minX"), "0 4 -25 -25"))
	spec.markerMaxX = StringUtil.splitString(" ", Utils.getNoNil(getXMLString(self.xmlFile, "vehicle.easyAutoLoad.moveableMarkerOptions#maxX"), "0 25 25 -4"))
	spec.markerMinY = StringUtil.splitString(" ", Utils.getNoNil(getXMLString(self.xmlFile, "vehicle.easyAutoLoad.moveableMarkerOptions#minY"), "0 -0.7 -0.7 -0.7"))
	spec.markerMaxY = StringUtil.splitString(" ", Utils.getNoNil(getXMLString(self.xmlFile, "vehicle.easyAutoLoad.moveableMarkerOptions#maxY"), "0 15 15 15"))
	spec.markerMinZ = StringUtil.splitString(" ", Utils.getNoNil(getXMLString(self.xmlFile, "vehicle.easyAutoLoad.moveableMarkerOptions#minZ"), "0 -20 -30 -20"))
	spec.markerMaxZ = StringUtil.splitString(" ", Utils.getNoNil(getXMLString(self.xmlFile, "vehicle.easyAutoLoad.moveableMarkerOptions#maxZ"), "0 20 -16 20"))
	spec.palletIcon = false
	spec.squareBaleIcon = false
	spec.roundBaleIcon = false
	local markerPositions = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.easyAutoLoad#markerPositionsIndex"), self.i3dMappings)
	local numMarkerChildren = getNumOfChildren(markerPositions)
	if numMarkerChildren > 0 then
		spec.markerPositions = {}
		for i = 1, numMarkerChildren do
			local entry = {}
			local markerId = getChildAt(markerPositions, i-1)
			local name = getName(markerId)
			entry.index = markerId
			entry.translation = {getTranslation(markerId)}
			entry.name = g_i18n:hasText(name, self.customEnvironment) and g_i18n:getText(name, self.customEnvironment) or name
			table.insert(spec.markerPositions, entry)
		end
	end
	local triggerNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.easyAutoLoad#triggersIndex"), self.i3dMappings)
	local numTriggerChildren = getNumOfChildren(triggerNode)
	if numTriggerChildren > 0 then
		spec.objectTriggers = {}
		for i = 1, numTriggerChildren do
			local triggerId = getChildAt(triggerNode, i-1)
			if getCollisionMask(triggerId) ~= 16777216 then
				setCollisionMask(triggerId, 16777216)
			end
			table.insert(spec.objectTriggers, triggerId)
			addTrigger(triggerId, "objectCallback", self)
		end
	end
	local objectsNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.easyAutoLoad#objectsIndex"), self.i3dMappings)
	local numChildren = getNumOfChildren(objectsNode)
	if numChildren > 0 then
		local function updateTable(objectTable, id)
			local count = getNumOfChildren(id) - 1
			local entry, index = {}, nil
			for i = 0, count do
				entry = {}
				index = getChildAt(id, i)
				if index ~= nil then
					entry.node = index
					entry.objectId = nil
					table.insert(objectTable, entry)
				end
			end
		end
		spec.autoLoadObjects = {}
		for i = 1, numChildren do
			local entry = {}
			local objectId = getChildAt(objectsNode, i-1)
			local name = getName(objectId)
			entry.index = objectId
			entry.name = name
			entry.nameL = g_i18n:hasText(name, self.customEnvironment) and g_i18n:getText(name, self.customEnvironment) or name
			entry.maxNumObjects = getNumOfChildren(objectId)
			entry.isRoundBale = Utils.getNoNil(getUserAttribute(objectId, "isRoundBale"), false)
			if entry.isRoundBale then
				entry.diameter = Utils.getNoNil(getUserAttribute(objectId, "diameter"), "1.30")
			end
			entry.isSquareBale = Utils.getNoNil(getUserAttribute(objectId, "isSquareBale"), false)
			if entry.isSquareBale then
				entry.width = Utils.getNoNil(getUserAttribute(objectId, "baleWidth"), "1.20")
				entry.length = Utils.getNoNil(getUserAttribute(objectId, "baleLength"), "2.40")
				entry.height = Utils.getNoNil(getUserAttribute(objectId, "baleHeight"), "0.80")
			end
			entry.isHDbale = Utils.getNoNil(getUserAttribute(objectId, "isHDbale"), false)
			entry.isMissionPallet = Utils.getNoNil(getUserAttribute(objectId, "isMissionPallet"), false)
			entry.excludedFillTypes = StringUtil.splitString(" ", getUserAttribute(objectId, "excludedFillTypes"))
			entry.includedFillTypes = StringUtil.splitString(" ", getUserAttribute(objectId, "includedFillTypes"))
			entry.usePalletSize = Utils.getNoNil(getUserAttribute(objectId, "usePalletSize"), false)
			if entry.usePalletSize then
				entry.sizeLength = Utils.getNoNil(getUserAttribute(objectId, "sizeLength"), "2.00")
				entry.sizeWidth = Utils.getNoNil(getUserAttribute(objectId, "sizeWidth"), "2.00")
				entry.secondaryPalletSize = Utils.getNoNil(getUserAttribute(objectId, "secondaryPalletSize"), false)
				if entry.secondaryPalletSize then
					entry.secondarySizeLength = Utils.getNoNil(getUserAttribute(objectId, "secondarySizeLength"), "1.50")
					entry.secondarySizeWidth = Utils.getNoNil(getUserAttribute(objectId, "secondarySizeWidth"), "2.00")
				end
			end
			entry.toMount = {}
			entry.objects = {}
			updateTable(entry.objects, objectId)
			table.insert(spec.autoLoadObjects, entry)
		end
	end
	spec.easyAutoLoaderRegistrationList = {}
	spec.easyAutoLoaderRegistrationList[InputAction.workMode] = { callback=easyAutoLoader.setWorkMode, triggerUp=false, triggerDown=true, triggerAlways=false, startActive=true, callbackState=-1, text=g_i18n:getText("workModeOn", self.customEnvironment), textVisibility=true }
	spec.easyAutoLoaderRegistrationList[InputAction.select] = { callback=easyAutoLoader.setSelect, triggerUp=false, triggerDown=true, triggerAlways=false, startActive=true, callbackState=-1, text=spec.autoLoadObjects[spec.state].nameL, textVisibility=true }
	spec.easyAutoLoaderRegistrationList[InputAction.markerPosition] = { callback=easyAutoLoader.changeMarkerPosition, triggerUp=false, triggerDown=true, triggerAlways=false, startActive=false, callbackState=-1, text=g_i18n:getText("input_markerPosition"), textVisibility=true }
	spec.easyAutoLoaderRegistrationList[InputAction.unload] = { callback=easyAutoLoader.setUnload, triggerUp=false, triggerDown=true, triggerAlways=false, startActive=false, callbackState=-1, text=g_i18n:getText("input_unload"), textVisibility=true }
	spec.easyAutoLoaderRegistrationList[InputAction.moveMarkerUp] = { callback=easyAutoLoader.moveMarkerUp, triggerUp=false, triggerDown=true, triggerAlways=true, startActive=false, callbackState=-1, text=g_i18n:getText("input_moveMarkerUp"), textVisibility=false }
	spec.easyAutoLoaderRegistrationList[InputAction.moveMarkerDown] = { callback=easyAutoLoader.moveMarkerDown, triggerUp=false, triggerDown=true, triggerAlways=true, startActive=false, callbackState=-1, text=g_i18n:getText("input_moveMarkerDown"), textVisibility=false }
	spec.easyAutoLoaderRegistrationList[InputAction.moveMarkerLeft] = { callback=easyAutoLoader.moveMarkerLeft, triggerUp=false, triggerDown=true, triggerAlways=true, startActive=false, callbackState=-1, text=g_i18n:getText("input_moveMarkerLeft"), textVisibility=false }
	spec.easyAutoLoaderRegistrationList[InputAction.moveMarkerRight] = { callback=easyAutoLoader.moveMarkerRight, triggerUp=false, triggerDown=true, triggerAlways=true, startActive=false, callbackState=-1, text=g_i18n:getText("input_moveMarkerRight"), textVisibility=false }
	spec.easyAutoLoaderRegistrationList[InputAction.moveMarkerForward] = { callback=easyAutoLoader.moveMarkerForward, triggerUp=false, triggerDown=true, triggerAlways=true, startActive=false, callbackState=-1, text=g_i18n:getText("input_moveMarkerForward"), textVisibility=false }
	spec.easyAutoLoaderRegistrationList[InputAction.moveMarkerBackward] = { callback=easyAutoLoader.moveMarkerBackward, triggerUp=false, triggerDown=true, triggerAlways=true, startActive=false, callbackState=-1, text=g_i18n:getText("input_moveMarkerBackward"), textVisibility=false }
	spec.easyAutoLoaderRegistrationList[InputAction.moveMarkerOriginal] = { callback=easyAutoLoader.moveMarkerOriginal, triggerUp=false, triggerDown=true, triggerAlways=false, startActive=false, callbackState=-1, text=g_i18n:getText("input_moveMarkerOriginal"), textVisibility=true }
	if spec.useMarkerRotate then
		spec.easyAutoLoaderRegistrationList[InputAction.markerRotation] = { callback=easyAutoLoader.triggerHelperMode, triggerUp=false, triggerDown=true, triggerAlways=false, startActive=false, callbackState=-1, text=g_i18n:getText("input_markerRotation"), textVisibility=true }
	end
	spec.coloredIcons = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.easyAutoLoad.levelBarOptions#coloredIcons"), false)
	if not self:isDedicatedServer() then
		spec.easyAutoLoaderIcons = {}
		local fillLevelColor = ConfigurationUtil.getColorFromString(Utils.getNoNil(getXMLString(self.xmlFile, "vehicle.easyAutoLoad.levelBarOptions#fillLevelColor"), "0.991 0.3865 0.01 1"))
		local fillLevelTextColor = {1, 1, 1, 0.2}
		spec.fillLevelsTextColor = {1, 1, 1, 1}
		local uiScale = g_gameSettings:getValue("uiScale")
		local iconWidth, iconHeight = getNormalizedScreenValues(33 * uiScale, 33 * uiScale)
		local offsetX, offsetY = getNormalizedScreenValues(2 * uiScale, 4 * uiScale)
		local numFillLevelDisplays = 0
		if self.spec_fillUnit then
			for i = 1, #self.spec_fillUnit.fillUnits do
				if self.spec_fillUnit.fillUnits[i].showOnHud then
					numFillLevelDisplays = numFillLevelDisplays + 1
				end
			end
		end
		spec.fillLevelBarHeight = g_currentMission.hud.fillLevelsDisplay.origY + ((offsetY + iconHeight) * numFillLevelDisplays)
		spec.easyAutoLoaderIcons.palletIconOverlay = Overlay:new(Utils.getFilename(spec.coloredIcons and getXMLString(self.xmlFile, "vehicle.easyAutoLoad.palletIcon#colorIcon") or getXMLString(self.xmlFile, "vehicle.easyAutoLoad.palletIcon#overlayIcon"), self.baseDirectory), g_currentMission.hud.fillLevelsDisplay.origX - offsetX, spec.fillLevelBarHeight, iconWidth, iconHeight)
		spec.easyAutoLoaderIcons.roundBaleIconOverlay = Overlay:new(Utils.getFilename(spec.coloredIcons and getXMLString(self.xmlFile, "vehicle.easyAutoLoad.roundBaleIcon#colorIcon") or getXMLString(self.xmlFile, "vehicle.easyAutoLoad.roundBaleIcon#overlayIcon"), self.baseDirectory), g_currentMission.hud.fillLevelsDisplay.origX - offsetX, spec.fillLevelBarHeight, iconWidth, iconHeight)
		spec.easyAutoLoaderIcons.squareBaleIconOverlay = Overlay:new(Utils.getFilename(spec.coloredIcons and getXMLString(self.xmlFile, "vehicle.easyAutoLoad.squareBaleIcon#colorIcon") or getXMLString(self.xmlFile, "vehicle.easyAutoLoad.squareBaleIcon#overlayIcon"), self.baseDirectory), g_currentMission.hud.fillLevelsDisplay.origX - offsetX, spec.fillLevelBarHeight, iconWidth, iconHeight)
		if not spec.coloredIcons then
			local iconColor = ConfigurationUtil.getColorFromString(Utils.getNoNil(getXMLString(self.xmlFile, "vehicle.easyAutoLoad.levelBarOptions#iconColor"), "0.6307 0.6307 0.6307 1"))
			for _, icon in pairs(spec.easyAutoLoaderIcons) do
				icon:setColor(unpack(iconColor))
			end
		end
		local width, height = getNormalizedScreenValues(144 * uiScale, 10 * uiScale)
		spec.fillLevelBar = StatusBar:new(g_baseUIFilename, g_colorBgUVs, nil, fillLevelTextColor, fillLevelColor, nil, g_currentMission.hud.fillLevelsDisplay.origX + iconWidth + offsetX, spec.fillLevelBarHeight + offsetY, width, height)
	end
	spec.currentObjectId = 0
	spec.triggerHelperModeEnabled = false
end

function easyAutoLoader:onPostLoad(savegame)
	local spec = self.spec_easyAutoLoader
	if savegame ~= nil and not savegame.resetVehicles then
		local key = savegame.key.."."..autoloadModName..".easyAutoLoader"
		local state = Utils.getNoNil(getXMLInt(savegame.xmlFile, key.."#objectMode"), 1)
		self:doStateChange(3, false, state, 0, spec.palletIcon, spec.squareBaleIcon, spec.roundBaleIcon, false)
	end
end

function easyAutoLoader:onDelete()
	local spec = self.spec_easyAutoLoader
	if spec.currentNumObjects > 0 then
		self:setUnload()
	end
	for i = 1, #spec.objectTriggers do
		removeTrigger(spec.objectTriggers[i])
	end
	if spec.easyAutoLoaderIcons then
		for _, icon in pairs(spec.easyAutoLoaderIcons) do
			icon:delete()
		end
		spec.fillLevelBar:delete()
	end
end

function easyAutoLoader:onReadStream(streamId, connection)
	local spec = self.spec_easyAutoLoader
    spec.currentNumObjects = streamReadUInt16(streamId)
    spec.state = streamReadUInt8(streamId)
	for i = 1, #spec.autoLoadObjects[spec.state].objects do
		local objectId = NetworkUtil.readNodeObjectId(streamId)
		if objectId == 694500 then
			objectId = nil
		end
		spec.autoLoadObjects[spec.state].objects[i].objectId = objectId
		if objectId then
			spec.autoLoadObjects[spec.state].toMount[objectId] = {serverId = objectId, linkNode = spec.autoLoadObjects[spec.state].objects[i].node, trans = {0,0,0}, rot = {0,0,0}}
		end
	end
	spec.palletIcon = streamReadBool(streamId)
	spec.squareBaleIcon = streamReadBool(streamId)
	spec.roundBaleIcon = streamReadBool(streamId)
	local markerVisibility = streamReadBool(streamId)
	self:setMarkerVisibility(markerVisibility, true)
	spec.unloadPosition = streamReadUInt8(streamId)
end

function easyAutoLoader:onWriteStream(streamId, connection)
	local spec = self.spec_easyAutoLoader
    streamWriteUInt16(streamId, spec.currentNumObjects)
    streamWriteUInt8(streamId, spec.state)
	for _, object in pairs(spec.autoLoadObjects[spec.state].objects) do
		local objectId = Utils.getNoNil(object.objectId, 694500)
		NetworkUtil.writeNodeObjectId(streamId, objectId)
	end
	streamWriteBool(streamId, spec.palletIcon)
	streamWriteBool(streamId, spec.squareBaleIcon)
	streamWriteBool(streamId, spec.roundBaleIcon)
	streamWriteBool(streamId, spec.markerVisible)
	streamWriteUInt8(streamId, spec.unloadPosition)
end

function easyAutoLoader:onUpdate(dt)
	local spec = self.spec_easyAutoLoader
	if not spec.runOnce then
		spec.runOnce = true
		for index, objectToMount in pairs(spec.autoLoadObjects[spec.state].toMount) do
			local object = NetworkUtil.getObject(objectToMount.serverId)
			if object ~= nil then
				local x,y,z = unpack(objectToMount.trans)
				local rx,ry,rz = unpack(objectToMount.rot)
				if object:isa(Vehicle) then
					object.synchronizePosition = false
				end
				object:mount(self, objectToMount.linkNode, x,y,z, rx,ry,rz, true)
				spec.autoLoadObjects[spec.state].toMount[index] = nil
			end
		end
	end
end

function easyAutoLoader:onDraw()
	local spec = self.spec_easyAutoLoader
	if not self:isDedicatedServer() and spec.currentNumObjects >= 1 then
		local percentage = spec.currentNumObjects / spec.autoLoadObjects[spec.state].maxNumObjects
		spec.fillLevelBar:setValue(percentage)
		spec.fillLevelBar:render()
		if spec.easyAutoLoaderIcons.palletIconOverlay and spec.palletIcon then
			spec.easyAutoLoaderIcons.palletIconOverlay:render()
		end
		if spec.easyAutoLoaderIcons.squareBaleIconOverlay and spec.squareBaleIcon then
			spec.easyAutoLoaderIcons.squareBaleIconOverlay:render()
		end
		if spec.easyAutoLoaderIcons.roundBaleIconOverlay and spec.roundBaleIcon then
			spec.easyAutoLoaderIcons.roundBaleIconOverlay:render()
		end
		setTextBold(true)
		setTextColor(unpack(spec.fillLevelsTextColor))
		setTextAlignment(RenderText.ALIGN_RIGHT)
		renderText(g_currentMission.hud.fillLevelsDisplay.origX + spec.fillLevelBar.width + spec.easyAutoLoaderIcons.palletIconOverlay.width, spec.fillLevelBarHeight + g_currentMission.hud.fillLevelsDisplay.fillLevelTextOffsetY, g_currentMission.hud.fillLevelsDisplay.fillLevelTextSize, spec.currentNumObjects.." / "..spec.autoLoadObjects[spec.state].maxNumObjects)
		setTextBold(false)
	end
end

function easyAutoLoader:doStateChange(mode, bool, state, var, palletIcon, squareBaleIcon, roundBaleIcon, noEventSend)
	easyAutoLoaderEvent.sendEvent(self, mode, bool, state, var, palletIcon, squareBaleIcon, roundBaleIcon, noEventSend)
	local spec = self.spec_easyAutoLoader
	if mode == 1 then
		local object = NetworkUtil.getObject(var)
        if object == nil then
            return
        end
		local okToLoad = true
		for _, loadObject in ipairs(spec.autoLoadObjects[state].objects) do
			if var == loadObject.objectId then
				okToLoad = false
				break
			end
		end
		if okToLoad then
			spec.currentNumObjects = spec.currentNumObjects + 1
			if spec.autoLoadObjects[state].objects[spec.currentNumObjects].node ~= nil then
				if object:isa(Vehicle) then
					object.synchronizePosition = false
				end
				object:mount(self, spec.autoLoadObjects[state].objects[spec.currentNumObjects].node, 0,0,0, 0,0,0, true)
				spec.autoLoadObjects[state].objects[spec.currentNumObjects].objectId = var
				spec.currentObjectId = var
			end
		end
	elseif mode == 2 then
		local x, y, z = getTranslation(spec.unloadMarker)
		local rx, ry, rz = getRotation(spec.unloadMarker)
		if state > 1 then
			setTranslation(spec.autoLoadObjects[spec.state].index, x, y + spec.unloadHeightOffset, z)
			setRotation(spec.autoLoadObjects[spec.state].index, rx, ry, rz)
		else
			setTranslation(spec.autoLoadObjects[spec.state].index, unpack(spec.markerPositions[spec.centerMarkerIndex].translation))
			setRotation(spec.autoLoadObjects[spec.state].index, 0, 0, 0)
		end
		for _, placeholder in ipairs(spec.autoLoadObjects[spec.state].objects) do
			if placeholder.objectId ~= nil then
				local object = NetworkUtil.getObject(placeholder.objectId)
				if object ~= nil then
					if object:isa(Vehicle) then
						object.synchronizePosition = true
					end
					object:unmount()
				end
				placeholder.objectId = nil
			end
		end
        spec.currentNumObjects = var
		self:setMarkerVisibility(bool)
		self:setMarkerPosition(unpack(spec.markerPositions[spec.centerMarkerIndex].translation))
		self:setUnloadPosition(spec.centerMarkerIndex)
		setTranslation(spec.autoLoadObjects[spec.state].index, unpack(spec.markerPositions[spec.centerMarkerIndex].translation))
		setRotation(spec.autoLoadObjects[spec.state].index, 0, 0, 0)
		if spec.triggerHelperModeEnabled then
			self:triggerHelperMode()
		end
		spec.currentObjectId = var
	elseif mode == 3 then
        spec.state = state
	elseif mode == 4 then
        spec.workMode = bool
		if spec.moveTrigger then
			self:playAnimation(spec.moveTrigger, spec.workMode and 1 or -1, nil, true)
		end
	end
	spec.palletIcon = palletIcon
	spec.squareBaleIcon = squareBaleIcon
	spec.roundBaleIcon = roundBaleIcon
	if  spec.actionEvents ~= nil and spec.actionEvents[InputAction.workMode] then
		self:updateBindings()
	end
end

function easyAutoLoader:objectCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	local spec = self.spec_easyAutoLoader
	if onEnter and spec.workMode then
		local object = g_currentMission:getNodeObject(otherId)
		if object == nil or object.mountObject ~= nil then
			return
		end
		local objectId = NetworkUtil.getObjectId(object)
		if objectId == spec.currentObjectId then
			return
		end
		local isPallet = object:isa(Vehicle) and object.getFillUnits ~= nil and next(object:getFillUnits()) ~= nil
		local isRoundbale = false
		local isHDbale = false
		local isNotExcluded = false
		if object:isa(Bale) then
			isRoundbale = spec.autoLoadObjects[spec.state].isRoundBale and Utils.getNoNil(getUserAttribute(object.nodeId, "isRoundbale"), false)
			isHDbale = spec.autoLoadObjects[spec.state].isHDbale and Utils.getNoNil(getUserAttribute(object.nodeId, "isHDbale"), false)
			if isRoundbale and spec.autoLoadObjects[spec.state].diameter == string.format("%1.2f", object.baleDiameter) then
				isNotExcluded = true
			elseif isHDbale and spec.autoLoadObjects[spec.state].isHDbale then
				isNotExcluded = true
			elseif object.baleLength ~= nil and object.baleWidth ~= nil and object.baleHeight ~= nil then
				isNotExcluded = spec.autoLoadObjects[spec.state].length == string.format("%1.2f", object.baleLength) and spec.autoLoadObjects[spec.state].width == string.format("%1.2f", object.baleWidth) and spec.autoLoadObjects[spec.state].height == string.format("%1.2f", object.baleHeight)
			end
		elseif isPallet then
			local objectFillType = object:getFillUnitFillType(1)
			if objectFillType == nil then
				return
			elseif objectFillType ~= nil and objectFillType == g_fillTypeManager:getFillTypeIndexByName("potato") and object:getFillUnitFillLevelPercentage(1) < 1 then
				return
			end
			if spec.autoLoadObjects[spec.state].includedFillTypes then
				for _, includedFillType in pairs(spec.autoLoadObjects[spec.state].includedFillTypes) do
					if objectFillType == g_fillTypeManager:getFillTypeIndexByName(includedFillType) then
						isNotExcluded = true
						break
					end
				end
			end
			if spec.autoLoadObjects[spec.state].usePalletSize then
				if string.format("%1.2f", object.sizeWidth) == spec.autoLoadObjects[spec.state].sizeWidth and string.format("%1.2f", object.sizeLength) == spec.autoLoadObjects[spec.state].sizeLength then
					isNotExcluded = true
				else
					isNotExcluded = false
				end
				if not isNotExcluded and spec.autoLoadObjects[spec.state].secondaryPalletSize then
					if string.format("%1.2f", object.sizeWidth) == spec.autoLoadObjects[spec.state].secondarySizeWidth and string.format("%1.2f", object.sizeLength) == spec.autoLoadObjects[spec.state].secondarySizeLength then
						isNotExcluded = true
					else
						isNotExcluded = false
					end
				end
			end
			if spec.autoLoadObjects[spec.state].excludedFillTypes and isNotExcluded then
				for _, excludedFillType in pairs(spec.autoLoadObjects[spec.state].excludedFillTypes) do
					if objectFillType == g_fillTypeManager:getFillTypeIndexByName(excludedFillType) then
						isNotExcluded = false
						break
					else
						isNotExcluded = true
					end
				end
			end
		elseif object.mission ~= nil and spec.autoLoadObjects[spec.state].isMissionPallet then
			isNotExcluded = true
			isPallet = true
		end
		if isNotExcluded then
			local palletIcon = isPallet
			local squareBaleIcon = not isRoundbale and not isPallet
			local roundBaleIcon = isRoundbale
			self:doStateChange(1, false, spec.state, objectId, palletIcon, squareBaleIcon, roundBaleIcon, false)
			if spec.currentNumObjects == spec.autoLoadObjects[spec.state].maxNumObjects then
				self:doStateChange(4, false, 0, 0, palletIcon, squareBaleIcon, roundBaleIcon, false)
			end
		end
	end
end

function easyAutoLoader:setMarkerVisibility(markervisibility, noEventSend)
	local spec = self.spec_easyAutoLoader
	if markervisibility ~= spec.markerVisible then
		SetMarkerVisibilityEvent.sendEvent(self, markervisibility, noEventSend)
        spec.markerVisible = markervisibility
        setVisibility(spec.unloadMarker, markervisibility)
    end
	self:updateBindings()
end

function easyAutoLoader:setUnloadPosition(unloadPosition, noEventSend)
	local spec = self.spec_easyAutoLoader
	if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(SetUnloadPositionEvent:new(self, unloadPosition), nil, nil, self)
        else
            g_client:getServerConnection():sendEvent(SetUnloadPositionEvent:new(self, unloadPosition))
        end
    end
	spec.unloadPosition = unloadPosition
end

function easyAutoLoader:onRegisterActionEvents(isSelected, isOnActiveVehicle)
	if self.isClient then
		local spec = self.spec_easyAutoLoader
		if spec.actionEvents == nil then
			spec.actionEvents = {}
		else
			self:clearActionEventsTable(spec.actionEvents)
		end
		if isSelected then
			local eventAdded, eventId = false, nil
			for actionId, entry in pairs(spec.easyAutoLoaderRegistrationList) do
				eventAdded, eventId = self:addActionEvent(spec.actionEvents, actionId, self, entry.callback, entry.triggerUp, entry.triggerDown, entry.triggerAlways, entry.startActive, nil)
				if eventAdded then
					if actionId == InputAction.workMode then
						g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_VERY_HIGH)
					elseif actionId == InputAction.select or actionId == InputAction.unload or actionId == InputAction.markerPosition or (spec.useMarkerRotate and actionId == InputAction.markerRotation) then
						g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_HIGH)
					else
						g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_NORMAL)
					end
				end
			end
			self:updateBindings()
		end
	end
end

function easyAutoLoader:updateBindings()
	local spec = self.spec_easyAutoLoader
	if self:getIsActiveForInput() and self:getIsActive() then
		g_inputBinding:setActionEventActive(spec.actionEvents[InputAction.workMode].actionEventId, spec.currentNumObjects ~= spec.autoLoadObjects[spec.state].maxNumObjects)
		if spec.workMode then
			g_inputBinding:setActionEventText(spec.actionEvents[InputAction.workMode].actionEventId, g_i18n:getText("workModeOff", self.customEnvironment))
		elseif not spec.workMode then
			g_inputBinding:setActionEventText(spec.actionEvents[InputAction.workMode].actionEventId, g_i18n:getText("workModeOn", self.customEnvironment))
		end
		g_inputBinding:setActionEventActive(spec.actionEvents[InputAction.select].actionEventId, spec.currentNumObjects == 0 and not spec.workMode)
		g_inputBinding:setActionEventText(spec.actionEvents[InputAction.select].actionEventId, spec.autoLoadObjects[spec.state].nameL)
		g_inputBinding:setActionEventActive(spec.actionEvents[InputAction.markerPosition].actionEventId, spec.currentNumObjects >= 1 and not spec.workMode)
		g_inputBinding:setActionEventActive(spec.actionEvents[InputAction.unload].actionEventId, spec.currentNumObjects >= 1 and not spec.workMode)
		g_inputBinding:setActionEventActive(spec.actionEvents[InputAction.moveMarkerUp].actionEventId, spec.markerVisible)
		g_inputBinding:setActionEventActive(spec.actionEvents[InputAction.moveMarkerDown].actionEventId, spec.markerVisible)
		g_inputBinding:setActionEventActive(spec.actionEvents[InputAction.moveMarkerLeft].actionEventId, spec.markerVisible)
		g_inputBinding:setActionEventActive(spec.actionEvents[InputAction.moveMarkerRight].actionEventId, spec.markerVisible)
		g_inputBinding:setActionEventActive(spec.actionEvents[InputAction.moveMarkerForward].actionEventId, spec.markerVisible)
		g_inputBinding:setActionEventActive(spec.actionEvents[InputAction.moveMarkerBackward].actionEventId, spec.markerVisible)
		g_inputBinding:setActionEventActive(spec.actionEvents[InputAction.moveMarkerOriginal].actionEventId, spec.markerVisible)
		if spec.useMarkerRotate then
			g_inputBinding:setActionEventActive(spec.actionEvents[InputAction.markerRotation].actionEventId, spec.markerVisible and (spec.squareBaleIcon or spec.roundBaleIcon))
		end
    end
end

function easyAutoLoader:setWorkMode()
	local spec = self.spec_easyAutoLoader
	if spec.currentNumObjects ~= spec.autoLoadObjects[spec.state].maxNumObjects then
		self:setMarkerVisibility(false)
		self:setUnloadPosition(spec.centerMarkerIndex)
		self:doStateChange(4, not spec.workMode, 0, 0, spec.palletIcon, spec.squareBaleIcon, spec.roundBaleIcon, false)
		if spec.triggerHelperModeEnabled then
			self:triggerHelperMode()
		end
	end
	self:updateBindings()
end

function easyAutoLoader:setSelect()
	local spec = self.spec_easyAutoLoader
	spec.state = spec.state + 1
	if spec.state > #spec.autoLoadObjects then
		spec.state = 1
	end
	self:doStateChange(3, false, spec.state, 0, spec.palletIcon, spec.squareBaleIcon, spec.roundBaleIcon, false)
end

function easyAutoLoader:changeMarkerPosition()
	local spec = self.spec_easyAutoLoader
	local unloadPosition = spec.unloadPosition + 1
	if unloadPosition > #spec.markerPositions then
		unloadPosition = 1
	end
	self:setUnloadPosition(unloadPosition)
	self:setMarkerVisibility(unloadPosition > 1)
	self:setMarkerPosition(unpack(spec.markerPositions[unloadPosition].translation))
	if spec.triggerHelperModeEnabled then
		self:triggerHelperMode()
	end
end

function easyAutoLoader:setUnload()
	local spec = self.spec_easyAutoLoader
	self:doStateChange(2, false, spec.unloadPosition, 0, false, false, false, false)
end

function easyAutoLoader:setMarkerPosition(markerX, markerY, markerZ, noEventSend)
	local spec = self.spec_easyAutoLoader
	if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(SetMarkerMoveEvent:new(self, markerX, markerY, markerZ), nil, nil, self)
        else
            g_client:getServerConnection():sendEvent(SetMarkerMoveEvent:new(self, markerX, markerY, markerZ))
        end
    end
	setTranslation(spec.unloadMarker, markerX, markerY, markerZ)
end

function easyAutoLoader:moveMarkerLeft()
	local spec = self.spec_easyAutoLoader
	local x, y, z = getTranslation(spec.unloadMarker)
	x = MathUtil.clamp(x + spec.markerMoveSpeed, spec.markerMinX[spec.unloadPosition], spec.markerMaxX[spec.unloadPosition])
	self:setMarkerPosition(x, y, z)
end

function easyAutoLoader:moveMarkerRight()
	local spec = self.spec_easyAutoLoader
	local x, y, z = getTranslation(spec.unloadMarker)
	x = MathUtil.clamp(x - spec.markerMoveSpeed, spec.markerMinX[spec.unloadPosition], spec.markerMaxX[spec.unloadPosition])
	self:setMarkerPosition(x, y, z)
end

function easyAutoLoader:moveMarkerUp()
	local spec = self.spec_easyAutoLoader
	local x, y, z = getTranslation(spec.unloadMarker)
	y = MathUtil.clamp(y + spec.markerMoveSpeed, spec.markerMinY[spec.unloadPosition], spec.markerMaxY[spec.unloadPosition])
	self:setMarkerPosition(x, y, z)
end

function easyAutoLoader:moveMarkerDown()
	local spec = self.spec_easyAutoLoader
	local x, y, z = getTranslation(spec.unloadMarker)
	y = MathUtil.clamp(y - spec.markerMoveSpeed, spec.markerMinY[spec.unloadPosition], spec.markerMaxY[spec.unloadPosition])
	self:setMarkerPosition(x, y, z)
end

function easyAutoLoader:moveMarkerForward()
	local spec = self.spec_easyAutoLoader
	local x, y, z = getTranslation(spec.unloadMarker)
	z = MathUtil.clamp(z + spec.markerMoveSpeed, spec.markerMinZ[spec.unloadPosition], spec.markerMaxZ[spec.unloadPosition])
	self:setMarkerPosition(x, y, z)
end

function easyAutoLoader:moveMarkerBackward()
	local spec = self.spec_easyAutoLoader
	local x, y, z = getTranslation(spec.unloadMarker)
	z = MathUtil.clamp(z - spec.markerMoveSpeed, spec.markerMinZ[spec.unloadPosition], spec.markerMaxZ[spec.unloadPosition])
	self:setMarkerPosition(x, y, z)
end

function easyAutoLoader:moveMarkerOriginal()
	local spec = self.spec_easyAutoLoader
	x, y, z = unpack(spec.markerPositions[spec.unloadPosition].translation)
	self:setMarkerPosition(x, y, z)
	if spec.triggerHelperModeEnabled then
		self:triggerHelperMode()
	end
end

function easyAutoLoader:saveToXMLFile(xmlFile, key)
	local spec = self.spec_easyAutoLoader
	setXMLInt(xmlFile, key.."#objectMode", Utils.getNoNil(spec.state, 1))
	if spec.currentNumObjects > 0 then
		self:setUnload()
	end
end

function easyAutoLoader:isDedicatedServer()
	if g_server ~= nil and g_client ~= nil and g_dedicatedServerInfo ~= nil then
		return true
	end
	return
end

function easyAutoLoader:triggerHelperMode()
	local spec = self.spec_easyAutoLoader
	spec.triggerHelperModeEnabled = not spec.triggerHelperModeEnabled
	local x, y, z = getTranslation(spec.unloadMarker)
	local rx, ry, rz = getRotation(spec.unloadMarker)
	if spec.triggerHelperModeEnabled then
		y =  spec.unloaderMarkerYoffset + y
		rx = math.rad(90)
	else
		_, y, _ = unpack(spec.markerPositions[spec.unloadPosition].translation)
		rx = 0
	end
	if spec.useMarkerRotate then
		self:setMarkerRotation(rx, ry, rz)
	end
	self:setMarkerPosition(x, y, z)
end

function easyAutoLoader:setMarkerRotation(markerRX, markerRY, markerRZ, noEventSend)
	local spec = self.spec_easyAutoLoader
	if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(SetMarkerRotationEvent:new(self, markerRX, markerRY, markerRZ), nil, nil, self)
        else
            g_client:getServerConnection():sendEvent(SetMarkerRotationEvent:new(self, markerRX, markerRY, markerRZ))
        end
    end
	setRotation(spec.unloadMarker, markerRX, markerRY, markerRZ)
end

easyAutoLoaderEvent = {}
easyAutoLoaderEvent_mt = Class(easyAutoLoaderEvent, Event)
InitEventClass(easyAutoLoaderEvent, "easyAutoLoaderEvent")

function easyAutoLoaderEvent:emptyNew()
	local self = Event:new(easyAutoLoaderEvent_mt)
    self.className = "easyAutoLoaderEvent"
    return self
end

function easyAutoLoaderEvent:new(vehicle, mode, bool, state, var, palletIcon, squareBaleIcon, roundBaleIcon)
    local self = easyAutoLoaderEvent:emptyNew()
    self.vehicle = vehicle
    self.mode = mode
    self.bool = bool
    self.stateNum = state
    self.var = var
    self.palletIcon = palletIcon
    self.squareBaleIcon = squareBaleIcon
    self.roundBaleIcon = roundBaleIcon
    return self
end

function easyAutoLoaderEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.mode = streamReadUInt8(streamId)
    self.bool = streamReadBool(streamId)
    self.stateNum = streamReadUInt8(streamId)
	self.var = NetworkUtil.readNodeObjectId(streamId)
    self.palletIcon = streamReadBool(streamId)
    self.squareBaleIcon = streamReadBool(streamId)
    self.roundBaleIcon = streamReadBool(streamId)
    self:run(connection)
end

function easyAutoLoaderEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUInt8(streamId, self.mode)
    streamWriteBool(streamId, self.bool)
    streamWriteUInt8(streamId, self.stateNum)
	NetworkUtil.writeNodeObjectId(streamId, self.var)
    streamWriteBool(streamId, self.palletIcon)
    streamWriteBool(streamId, self.squareBaleIcon)
    streamWriteBool(streamId, self.roundBaleIcon)
end

function easyAutoLoaderEvent:run(connection)  
    self.vehicle:doStateChange(self.mode, self.bool, self.stateNum, self.var, self.palletIcon, self.squareBaleIcon, self.roundBaleIcon, true)
    if not connection:getIsServer() then
        g_server:broadcastEvent(easyAutoLoaderEvent:new(self.vehicle, self.mode, self.bool, self.stateNum, self.var, self.palletIcon, self.squareBaleIcon, self.roundBaleIcon), nil, connection, self.vehicle)
    end
end

function easyAutoLoaderEvent.sendEvent(vehicle, mode, bool, state, var, palletIcon, squareBaleIcon, roundBaleIcon, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(easyAutoLoaderEvent:new(vehicle, mode, bool, state, var, palletIcon, squareBaleIcon, roundBaleIcon), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(easyAutoLoaderEvent:new(vehicle, mode, bool, state, var, palletIcon, squareBaleIcon, roundBaleIcon))
        end
    end
end

SetMarkerVisibilityEvent = {}
SetMarkerVisibilityEvent_mt = Class(SetMarkerVisibilityEvent, Event)
InitEventClass(SetMarkerVisibilityEvent, "SetMarkerVisibilityEvent")

function SetMarkerVisibilityEvent:emptyNew()
    return Event:new(SetMarkerVisibilityEvent_mt)
end

function SetMarkerVisibilityEvent:new(markerObject, active)
    local self = SetMarkerVisibilityEvent:emptyNew()
    self.markerObject = markerObject
	self.markerActive = active
    return self
end

function SetMarkerVisibilityEvent:readStream(streamId, connection)
    self.markerObject = NetworkUtil.readNodeObject(streamId)
    self.markerActive = streamReadBool(streamId)
    self:run(connection)
end

function SetMarkerVisibilityEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.markerObject)
    streamWriteBool(streamId, self.markerActive)
end

function SetMarkerVisibilityEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.markerObject)
    end
    if self.markerObject ~= nil then
        self.markerObject:setMarkerVisibility(self.markerActive, true)
    end
end

function SetMarkerVisibilityEvent.sendEvent(markerObject, markerActive, noEventSend)
    if markerObject.spec_easyAutoLoader.markerActive ~= markerActive then
        if noEventSend == nil or noEventSend == false then
            if g_server ~= nil then
                g_server:broadcastEvent(SetMarkerVisibilityEvent:new(markerObject, markerActive), nil, nil, markerObject)
            else
                g_client:getServerConnection():sendEvent(SetMarkerVisibilityEvent:new(markerObject, markerActive))
            end
        end
    end
end

SetUnloadPositionEvent = {}
SetUnloadPositionEvent_mt = Class(SetUnloadPositionEvent, Event)
InitEventClass(SetUnloadPositionEvent, "SetUnloadPositionEvent")

function SetUnloadPositionEvent:emptyNew()
    local self = Event:new(SetUnloadPositionEvent_mt)
    self.className="SetUnloadPositionEvent"
    return self
end

function SetUnloadPositionEvent:new(object, unloadPosition)
    local self = SetUnloadPositionEvent:emptyNew()
    self.object = object
	self.unloadPosition = unloadPosition
    return self
end

function SetUnloadPositionEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.unloadPosition = streamReadInt8(streamId)
    self:run(connection)
 end

function SetUnloadPositionEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteInt8(streamId, self.unloadPosition)
end

function SetUnloadPositionEvent:run(connection)
    self.object:setUnloadPosition(self.unloadPosition, true)
    if not connection:getIsServer() then
        g_server:broadcastEvent(SetUnloadPositionEvent:new(self.object, self.unloadPosition), nil, connection, self.object)
    end
end

SetMarkerMoveEvent = {}
SetMarkerMoveEvent_mt = Class(SetMarkerMoveEvent, Event)
InitEventClass(SetMarkerMoveEvent, "SetMarkerMoveEvent")

function SetMarkerMoveEvent:emptyNew()
    local self = Event:new(SetMarkerMoveEvent_mt)
    self.className="SetMarkerMoveEvent"
    return self
end

function SetMarkerMoveEvent:new(object, markerX, markerY, markerZ)
    local self = SetMarkerMoveEvent:emptyNew()
    self.object = object
	self.markerX = markerX
	self.markerY = markerY
	self.markerZ = markerZ
    return self
end

function SetMarkerMoveEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
    self.markerX = streamReadFloat32(streamId)
	self.markerY = streamReadFloat32(streamId)
	self.markerZ = streamReadFloat32(streamId)
    self:run(connection)
 end

function SetMarkerMoveEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteFloat32(streamId, self.markerX)
	streamWriteFloat32(streamId, self.markerY)
	streamWriteFloat32(streamId, self.markerZ)
end

function SetMarkerMoveEvent:run(connection)
	self.object:setMarkerPosition(self.markerX, self.markerY, self.markerZ, true)
    if not connection:getIsServer() then
        g_server:broadcastEvent(SetMarkerMoveEvent:new(self.object, self.markerX, self.markerY, self.markerZ), nil, connection, self.object)
    end
end

SetMarkerRotationEvent = {}
SetMarkerRotationEvent_mt = Class(SetMarkerRotationEvent, Event)
InitEventClass(SetMarkerRotationEvent, "SetMarkerRotationEvent")

function SetMarkerRotationEvent:emptyNew()
    local self = Event:new(SetMarkerRotationEvent_mt)
    self.className="SetMarkerRoationEvent"
    return self
end

function SetMarkerRotationEvent:new(object, markerX, markerY, markerZ)
    local self = SetMarkerRotationEvent:emptyNew()
    self.object = object
	self.markerRX = markerRX
	self.markerRY = markerRY
	self.markerRZ = markerRZ
    return self
end

function SetMarkerRotationEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
    self.markerRX = streamReadFloat32(streamId)
	self.markerRY = streamReadFloat32(streamId)
	self.markerRZ = streamReadFloat32(streamId)
    self:run(connection)
 end

function SetMarkerRotationEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteFloat32(streamId, self.markerRX)
	streamWriteFloat32(streamId, self.markerRY)
	streamWriteFloat32(streamId, self.markerRZ)
end

function SetMarkerRotationEvent:run(connection)
	self.object:setMarkerRotation(self.markerRX, self.markerRY, self.markerRZ, true)
    if not connection:getIsServer() then
        g_server:broadcastEvent(SetMarkerRotationEvent:new(self.object, self.markerRX, self.markerRY, self.markerRZ), nil, connection, self.object)
    end
end