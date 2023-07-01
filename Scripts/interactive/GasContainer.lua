dofile( "$SURVIVAL_DATA/Scripts/game/survival_items.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_projectiles.lua" )

ConsumableContainer = class( nil )
ConsumableContainer.maxChildCount = 255

local ContainerSize = 5

function ConsumableContainer.server_onCreate( self )
	local container = self.shape.interactable:getContainer( 0 )
	if not container then
		container = self.shape:getInteractable():addContainer( 0, ContainerSize, self.data.stackSize )
	end
	if self.data.filterUid then
		local filters = { sm.uuid.new( self.data.filterUid ) }
		container:setFilters( filters )
	end
end

function ConsumableContainer.client_canCarry( self )
	local container = self.shape.interactable:getContainer( 0 )
	if container and sm.exists( container ) then
		return not container:isEmpty()
	end
	return false
end

function ConsumableContainer.client_onInteract( self, character, state )
	if state == true then
		local container = self.shape.interactable:getContainer( 0 )
		if container then
			local gui = nil

			local shapeUuid = self.shape:getShapeUuid()

			if shapeUuid == obj_container_ammo then
				gui = sm.gui.createAmmunitionContainerGui( true )

			elseif shapeUuid == obj_container_battery then
				gui = sm.gui.createBatteryContainerGui( true )

			elseif shapeUuid == obj_container_chemical then
				gui = sm.gui.createChemicalContainerGui( true )

			elseif shapeUuid == obj_container_fertilizer then
				gui = sm.gui.createFertilizerContainerGui( true )

			elseif shapeUuid == obj_container_gas then
				gui = sm.gui.createGasContainerGui( true )

			elseif shapeUuid == obj_container_seed then
				gui = sm.gui.createSeedContainerGui( true )

			elseif shapeUuid == obj_container_water then
				gui = sm.gui.createWaterContainerGui( true )
			end

			if gui == nil then
				gui = sm.gui.createContainerGui( true )
				gui:setText( "UpperName", "#{CONTAINER_TITLE_GENERIC}" )
			end

			gui:setContainer( "UpperGrid", container )
			gui:setText( "LowerName", "#{INVENTORY_TITLE}" )
			gui:setContainer( "LowerGrid", sm.localPlayer.getInventory() )
			gui:open()
		end
	end
end

function ConsumableContainer.client_onUpdate( self, dt )

	local container = self.shape.interactable:getContainer( 0 )
	if container and self.data.stackSize then
		local quantities = sm.container.quantity( container )

		local quantity = 0
		for _,q in ipairs( quantities ) do
			quantity = quantity + q
		end

		local frame = ContainerSize - math.ceil( quantity / self.data.stackSize )
		self.interactable:setUvFrameIndex( frame )
	end
end

SeedContainer = class( ConsumableContainer )

function SeedContainer.server_onCreate( self )
	local container = self.shape.interactable:getContainer( 0 )
	if not container then
		container =	self.shape:getInteractable():addContainer( 0, ContainerSize, self.data.stackSize )
	end
	container:setFilters( sm.item.getPlantableUuids() )
end

WaterContainer = class( ConsumableContainer )
WaterContainer.connectionOutput = sm.interactable.connectionType.water
WaterContainer.colorNormal = sm.color.new( 0x84ff32ff )
WaterContainer.colorHighlight = sm.color.new( 0xa7ff4fff )

-- function WaterContainer.server_onProjectile( self, hitPos, hitTime, hitVelocity, _, attacker, damage, userData, hitNormal, projectileUuid )
-- 	if projectileUuid == projectile_water and ( self.hitTick == nil or self.hitTick <= sm.game.getCurrentTick() - 4 ) then
-- 		local container = self.shape.interactable:getContainer( 0 )
-- 		if sm.container.beginTransaction() then
-- 			sm.container.collect( container, obj_consumable_water, 1, false )
-- 			sm.container.endTransaction()
-- 		end
-- 		self.hitTick = sm.game.getCurrentTick()
-- 	end
-- end

BatteryContainer = class( ConsumableContainer )
BatteryContainer.connectionOutput = sm.interactable.connectionType.electricity
BatteryContainer.colorNormal = sm.color.new( 0x84ff32ff )
BatteryContainer.colorHighlight = sm.color.new( 0xa7ff4fff )

GasolineContainer = class( ConsumableContainer )
GasolineContainer.connectionOutput = sm.interactable.connectionType.gasoline
GasolineContainer.colorNormal = sm.color.new( 0x84ff32ff )
GasolineContainer.colorHighlight = sm.color.new( 0xa7ff4fff )

local thruster_1, thruster_2, thruster_3, thruster_4, thruster_5 = sm.uuid.new("df8528ed-15ad-4a39-a33a-698880684001"), sm.uuid.new("9fc793b2-250b-40ab-bcb3-97cf97c7b481"), sm.uuid.new("4c1cc8de-7af1-4f8e-a5c4-c583460af9e5"), sm.uuid.new("e6db321c-6f98-47f6-9f7f-4e6794a62cb8"), sm.uuid.new("a736ffdf-22c1-40f2-8e40-988cab7c0559")

function GasolineContainer.server_onFixedUpdate( self, dt )
	local children = self.shape.interactable:getChildren()
	if #children > 0 then
		for _, interactable in ipairs(children) do
			if interactable:isActive() and (interactable.shape.uuid == thruster_1 or interactable.shape.uuid == thruster_2 or interactable.shape.uuid == thruster_3 or interactable.shape.uuid == thruster_4 or interactable.shape.uuid == thruster_5) then
				self.network:sendToClients( "cl_createTrail", interactable.shape.worldPosition + interactable.shape.worldRotation * sm.vec3.new( 0, 0, 1 ) )
			end
		end
	end
end

function GasolineContainer.cl_createTrail( self, position )
	sm.effect.playEffect( "Thruster - Exhaust", position, position * 5 )
end

AmmoContainer = class( ConsumableContainer )
AmmoContainer.connectionOutput = sm.interactable.connectionType.ammo
AmmoContainer.colorNormal = sm.color.new( 0x84ff32ff )
AmmoContainer.colorHighlight = sm.color.new( 0xa7ff4fff )

FoodContainer = class( ConsumableContainer )

local FoodUuids = {
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
}

function FoodContainer.server_onCreate( self )
	local container = self.shape.interactable:getContainer( 0 )
	if not container then
		container =	self.shape:getInteractable():addContainer( 0, 20 )
	end
	container:setFilters( FoodUuids )
end

FoodContainer.client_onUpdate = nil
