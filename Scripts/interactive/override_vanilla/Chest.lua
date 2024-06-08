---@diagnostic disable: undefined-field
dofile("$SURVIVAL_DATA/Scripts/game/survival_items.lua")
dofile("$CONTENT_DATA/Scripts/mod_utils.lua")

Chest = class()
Chest.poseWeightCount = 1

FoodUuids = {
	obj_plantables_banana,
	obj_plantables_blueberry,
	obj_plantables_orange,
	obj_plantables_pineapple,
	obj_plantables_carrot,
	obj_plantables_redbeet,
	obj_plantables_tomato,
	obj_plantables_broccoli,
	obj_plantables_potato,
	obj_consumable_sunshake,
	obj_consumable_carrotburger,
	obj_consumable_pizzaburger,
	obj_consumable_longsandwich,
	obj_consumable_milk,
	obj_resource_steak,
	obj_resource_corn,
	obj_forest_blueberry,
	obj_pizza_slice,
	obj_pizza,
	obj_bowl_carrot_soup,
	obj_bowl_salad,
	obj_plate_sbt,
	obj_bowl_goulash,
	obj_mug_water,
	obj_mug_orange_juice,
	obj_woc_patty,
	obj_french_fries,
}

function Chest:server_onCreate()
	self.loaded = true
	self.checkedForLift = 0
    if self.interactable:getContainer(0) == nil then
        self.chestContainer = self.interactable:addContainer( 0, self.data.slots or 10 )
    end
	if self.data.filter then
		self.interactable:getContainer(0):setFilters( self.data.filter == "fridge" and FoodUuids or self.data.filter )
	end

	self.lastPos = self.shape.worldPosition

	--initial contents load
	self.contents = mod_utils.getContainerItems(self.interactable:getContainer(0))
	self.loaded = true
end

function Chest:server_onFixedUpdate()
	self.loaded = true
	
	if self.checkedForLift == 7 then
		if self.interactable:getContainer(0) ~= nil and self.shape.body:isOnLift() and self.interactable.power ~= 69420 then
			self.interactable:removeContainer(0)
			self.chestContainer = self.interactable:addContainer( 0, self.data.slots or 10 )
		end
		self.network:setClientData(true)
		self.interactable.power = 0
	end
	if self.checkedForLift < 8 then
		self.checkedForLift = self.checkedForLift + 1
	end
	
	if sm.game.getCurrentTick() % 40 == 0 then
		self.lastPos = self.shape.worldPosition
	end
	--Only way to access the container stuff after DESTRUCTION
	local ownContainer = self.interactable:getContainer(0)
	if ownContainer == nil then return end
	if ownContainer:hasChanged( sm.game.getCurrentTick() - 1 ) then
		self.contents = mod_utils.getContainerItems(self.interactable:getContainer(0))
	end
end

function Chest:client_onClientDataUpdate(data)
	self.cl.checkedForLift = data
end

function Chest:server_onUnload()
	self.loaded = false
end

function Chest:server_onDestroy()
	if #self.contents < 1 or not self.loaded or not sm.game.getLimitedInventory() then return end
	SpawnLoot(sm.player.getAllPlayers()[1], self.contents, self.lastPos)
end

function Chest:sv_updateState( toggle )
    self.network:sendToClients("cl_updateState", toggle)
	local effectName = self.data.forcedEffect or ((self.data.effect or "Chest") .. " - " .. (toggle and "Open" or "Close"))
	--print(effectName)
	sm.effect.playEffect(effectName, self.shape.worldPosition)
end

function Chest:client_onCreate()
	self.cl = {}
	self.cl.checkedForLift = false
	self.animSpeedMultiplier = self.data.animationSpeed or 15
    self.gui = sm.gui.createContainerGui()
    self.gui:setOnCloseCallback("cl_onClose")
    self.gui:setText( "UpperName", string.upper(sm.shape.getShapeTitle(self.shape.uuid)) or "#{CONTAINER_TITLE_GENERIC}")
    self.gui:setText( "LowerName", "#{INVENTORY_TITLE}" )
	self.gui:setVisible( "TakeAll", self.data.takeAll == nil or self.data.takeAll )

    self.open = false
    self.animProgress = 0
end

function Chest:client_onInteract( character, state )
    if not state or not self.cl.checkedForLift then return end
	local container = self.shape.interactable:getContainer( 0 )
	if container then
		self.gui:setContainer( "UpperGrid", container )
		self.gui:setContainer( "LowerGrid", sm.localPlayer.getInventory() )
		self.gui:open()
	end
	if self.data.hasPose ~= nil or self.data.hasPose == false then return end
	self.network:sendToServer("sv_updateState", true)
end

function Chest:client_canCarry()
	self.loaded = false
	local container = self.shape.interactable:getContainer( 0 )
	if container and sm.exists( container ) then
		return not container:isEmpty()
	end
	return false
end


function Chest:client_onUpdate( dt )
	if sm.game.getCurrentTick() % 40 == 0 and self.open then
		if not self.gui:isActive() then
			self.network:sendToServer("sv_updateState", false)
		end
	end

    if self.open and self.animProgress == 1 or not self.open and self.animProgress == 0 then return end

    self.animProgress = sm.util.clamp(self.animProgress + (self.open and dt*self.animSpeedMultiplier or -dt*self.animSpeedMultiplier), 0, 1)
    self.interactable:setPoseWeight( 0, self.animProgress )
end

function Chest:cl_onClose()
    self.network:sendToServer("sv_updateState", false)
end

function Chest:cl_updateState( toggle )
    self.open = toggle
end