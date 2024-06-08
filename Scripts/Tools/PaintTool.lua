---@diagnostic disable: need-check-nil, undefined-global
---@class PaintTool : ToolClass

dofile "$GAME_DATA/Scripts/game/AnimationUtil.lua"
dofile "$SURVIVAL_DATA/Scripts/util.lua"

PaintTool = class()

local renderables = {
    "$GAME_DATA/Character/Char_Tools/Char_painttool/char_painttool.rend"
}

local renderablesTp = {
    "$GAME_DATA/Character/Char_Male/Animations/char_male_tp_painttool.rend",
    "$GAME_DATA/Character/Char_Tools/Char_painttool/char_painttool_tp_animlist.rend"
}
local renderablesFp = {
    "$GAME_DATA/Character/Char_Tools/Char_painttool/char_painttool_fp_animlist.rend"
}

sm.tool.preloadRenderables(renderables)
sm.tool.preloadRenderables(renderablesTp)
sm.tool.preloadRenderables(renderablesFp)

local harvestableSelectOffsetList = {
    Harvestable_Wood_Birch01 = { x = -0.125, y = 0.250, z = -0.125 },
    Harvestable_Wood_Birch02 = { x = -0.125, y = 0.250, z = -0.125 },
    Harvestable_Wood_Birch03 = { x = -0.125, y = 0.250, z = -0.125 },

    Harvestable_Wood_Leafy01 = { x = -0.375, y = 0.0, z = -0.375 },
    Harvestable_Wood_Leafy02 = { x = -0.375, y = 0.0, z = -0.375 },
    Harvestable_Wood_Leafy03 = { x = -0.375, y = 0.0, z = -0.375 },

    Harvestable_Wood_Spruce01 = { x = -0.375, y = -0.5, z = -0.375 },
    Harvestable_Wood_Spruce02 = { x = -0.375, y = -0.5, z = -0.375 },
    Harvestable_Wood_Spruce03 = { x = -0.375, y = -0.5, z = -0.375 },

    Harvestable_Wood_Pine01 = { x = -0.625, y = -0.250, z = -0.625 },
    Harvestable_Wood_Pine02 = { x = -0.625, y = -0.250, z = -0.625 },
    Harvestable_Wood_Pine03 = { x = -0.625, y = -0.250, z = -0.625 }
}
local harvestableSelectBlueprintNameList = {
    "Harvestable_Wood_Birch01",
    "Harvestable_Wood_Birch02",
    "Harvestable_Wood_Birch03",

    "Harvestable_Wood_Leafy01",
    "Harvestable_Wood_Leafy02",
    "Harvestable_Wood_Leafy03",

    "Harvestable_Wood_Spruce01",
    "Harvestable_Wood_Spruce02",
    "Harvestable_Wood_Spruce03",

    "Harvestable_Wood_Pine01",
    "Harvestable_Wood_Pine02",
    "Harvestable_Wood_Pine03"
}
local harvestableSelectUuidList = {
    sm.uuid.new("c4ea19d3-2469-4059-9f13-3ddb4f7e0b79"),
    sm.uuid.new("711c3e72-7ba1-4424-ae70-c13d23afe818"),
    sm.uuid.new("a7aa52af-4276-4b2d-af44-36bc41864e04"),

    sm.uuid.new("91ec04ea-9bf7-4a9d-bb7f-3d0125ff78c7"),
    sm.uuid.new("4d482999-98b7-4023-a149-d47be709b8f7"),
    sm.uuid.new("3db0a60d-8668-4c8a-8dd2-f5ceb294977e"),

    sm.uuid.new("73f968f0-d3a3-4334-86a8-a90203a3a56d"),
    sm.uuid.new("86324c5b-e97a-41f6-aa2c-7c6462f1f2e7"),
    sm.uuid.new("27aa53ea-1e09-4251-a284-437f93850409"),

    sm.uuid.new("8411caba-63db-4b93-ad67-7ae8e350d360"),
    sm.uuid.new("1cb503a4-9306-412f-9e13-371bc634af60"),
    sm.uuid.new("fa864e51-67db-4ac9-823b-cfbdf523375d")
}
local harvestableDefaultColors = {
    sm.color.new("#90c900"),
    sm.color.new("#90c900"),
    sm.color.new("#90c900"),

    sm.color.new("#00bd1c"),
    sm.color.new("#00bd1c"),
    sm.color.new("#00bd1c"),

    sm.color.new("#005e0e"),
    sm.color.new("#005e0e"),
    sm.color.new("#005e0e"),

    sm.color.new("#177825"),
    sm.color.new("#177825"),
    sm.color.new("#177825")
}
local harvestableCrownPositions = {
    11,
    13,
    13,

    9,
    15,
    19,

    11,
    11,
    11,

    23,
    21,
    21
}

local function matchTablePositions(value, table)
    for i, v in ipairs(table) do
        if v == value then
            return i
        end
    end
    return 1
end

function PaintTool.loadAnimations(self)
    self.tpAnimations = createTpAnimations(
        self.tool,
        {
            idle = { "painttool_idle" },
            pickup = { "painttool_pickup", { nextAnimation = "idle" } },
            putdown = { "painttool_putdown" },
        }
    )
    local movementAnimations = {
        idle = "painttool_idle",
        idleRelaxed = "painttool_idle_relaxed",

        sprint = "painttool_sprint",
        runFwd = "painttool_run_fwd",
        runBwd = "painttool_run_bwd",

        jump = "painttool_jump",
        jumpUp = "painttool_jump_up",
        jumpDown = "painttool_jump_down",

        land = "painttool_jump_land",
        landFwd = "painttool_jump_land_fwd",
        landBwd = "painttool_jump_land_bwd",

        crouchIdle = "painttool_crouch_idle",
        crouchFwd = "painttool_crouch_fwd",
        crouchBwd = "painttool_crouch_bwd"
    }

    for name, animation in pairs(movementAnimations) do
        self.tool:setMovementAnimation(name, animation)
    end

    setTpAnimation(self.tpAnimations, "painttool_idle", 5.0)

    if self.tool:isLocal() then
        self.fpAnimations = createFpAnimations(
            self.tool,
            {
                equip = { "painttool_pickup", { nextAnimation = "idle" } },
                unequip = { "painttool_putdown" },

                idle = { "painttool_idle", { looping = true } },
                idlePick = { "painttool_colorpick_idle", { looping = true } },

                pick = { "painttool_colorpick", { nextAnimation = "idle", blendNext = 0.2 } },
                paint = { "painttool_paint", { nextAnimation = "idle", blendNext = 0.2 } },
                erase = { "painttool_erase", { nextAnimation = "idle", blendNext = 0.2 } },
                reload = { "painttool_reload", { nextAnimation = "idle", blendNext = 0.2 } },

                sprintInto = { "painttool_sprint_into", { nextAnimation = "sprintIdle", blendNext = 5.0 } },
                sprintExit = { "painttool_sprint_exit", { nextAnimation = "idle", blendNext = 0 } },
                sprintIdle = { "painttool_sprint_idle", { looping = true } }
            }
        )
    end
    self.blendTime = 0.2
end

function PaintTool.client_onCreate(self)
    self.gui = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/Layouts/PaintTool.layout", false, {
        isHud = false,
        isInteractive = true,
        needsCursor = true,
        hidesHotbar = false,
        isOverlapped = true,
        backgroundAlpha = 1.0
    })
    self.botSelect = sm.effect.createEffect("PaintTool - Bot_highlight")
    self.partSelect = sm.effect.createEffect("ShapeRenderable")
    self.partSelect:setScale(sm.vec3.new(0.25, 0.25, 0.25))
    self.partSelect:setParameter("visualization", true)
    self.oldPartSelectUuid = sm.uuid.getNil()
    self.harvestableSelect = nil
end

function PaintTool.client_onUpdate(self, dt)
    local isSprinting = self.tool:isSprinting()
    local isCrouching = self.tool:isCrouching()

    if self.tool:isLocal() then
        if self.equipped then
            if self.fpAnimations.currentAnimation ~= "paint" and self.fpAnimations.currentAnimation ~= "erase" then
                if isSprinting and self.fpAnimations.currentAnimation ~= "sprintInto" and self.fpAnimations.currentAnimation ~= "sprintIdle" then
                    swapFpAnimation(self.fpAnimations, "sprintExit", "sprintInto", 0.0)
                elseif not self.tool:isSprinting() and (self.fpAnimations.currentAnimation == "sprintIdle" or self.fpAnimations.currentAnimation == "sprintInto") then
                    swapFpAnimation(self.fpAnimations, "sprintInto", "sprintExit", 0.0)
                end
            end
        end
        updateFpAnimations(self.fpAnimations, self.equipped, dt)
    end

    if not self.equipped then
        if self.wantEquipped then
            self.wantEquipped = false
            self.equipped = true
        end
        return
    end

    for name, animation in pairs(self.tpAnimations.animations) do
        animation.time = animation.time + dt

        if name == self.tpAnimations.currentAnimation then
            if animation.time >= animation.info.duration - self.blendTime then
                if name == "pickup" then
                    setTpAnimation(self.tpAnimations, "idle", 0.001)
                elseif animation.nextAnimation ~= "" then
                    setTpAnimation(self.tpAnimations, animation.nextAnimation, 0.001)
                end
            end
        end
    end
end

function PaintTool.client_onFixedUpdate(self, dt)

end

function PaintTool.client_onReload(self)
    setFpAnimation(self.fpAnimations, "reload", 0.15)
    sm.audio.play("PaintTool - Reload", self.tool:getOwner().character.worldPosition)

    return true
end

function PaintTool.client_onToggle(self)
    setFpAnimation(self.fpAnimations, "idlePick", 0.15)
    sm.audio.play("PaintTool - Open", self.tool:getOwner().character.worldPosition)

    return true
end

function PaintTool.client_onEquippedUpdate(self, primaryState, secondaryState, forceBuild)
    --Locals that reset every time
    local resetPartVisual, resetHarvestableVisual, resetBotVisual = true, true, true

    --Main raycast
    local hit, result = sm.localPlayer.getRaycast(7.5)

    --Light up the selected object
    if hit then
        --Reset uuid of the part visualisation effect
        self.partSelect:setParameter("uuid", sm.uuid.getNil())
        if result.type == "body" then
            local shape = result:getShape()
            if sm.item.isBlock(shape.uuid) then
                sm.visualization.setBlockVisualization(shape:getClosestBlockLocalPosition(result.pointWorld), false,
                    shape)
            else
                if shape.uuid ~= self.oldPartSelectUuid and self.partSelect:isPlaying() then
                    self.oldPartSelectUuid = shape.uuid
                    self.partSelect:stopImmediate()
                end
                self.partSelect:setPosition(shape.worldPosition)
                self.partSelect:setRotation(shape.worldRotation)
                self.partSelect:setParameter("uuid", shape.uuid)
                if not self.partSelect:isPlaying() then
                    self.partSelect:start()
                end
                resetPartVisual = false
            end
        elseif result.type == "joint" then
            local joint = result:getJoint()
            if joint.uuid ~= self.oldPartSelectUuid and self.partSelect:isPlaying() then
                self.oldPartSelectUuid = joint.uuid
                self.partSelect:stopImmediate()
            end
            local offset = sm.vec3.new(math.abs(joint:getBoundingBox().x) - 0.25,
                math.abs(joint:getBoundingBox().y) - 0.25, math.abs(joint:getBoundingBox().z) - 0.25)
            if offset.x < 0 then
                offset.x = 0
            end
            if offset.y < 0 then
                offset.y = 0
            end
            if offset.z < 0 then
                offset.z = 0
            end
            local offsetDir = joint.worldPosition - joint:getShapeA().worldPosition
            if offsetDir.x ~= 0 then
                if offsetDir.x < 0 then
                    offsetDir.x = -1
                else
                    offsetDir.x = 1
                end
            end
            if offsetDir.y ~= 0 then
                if offsetDir.y < 0 then
                    offsetDir.y = -1
                else
                    offsetDir.y = 1
                end
            end
            if offsetDir.z ~= 0 then
                if offsetDir.z < 0 then
                    offsetDir.z = -1
                else
                    offsetDir.z = 1
                end
            end
            self.partSelect:setPosition(joint.worldPosition + offset / 2 * offsetDir)
            self.partSelect:setRotation(joint:getLocalRotation())
            self.partSelect:setParameter("uuid", joint.uuid)
            if not self.partSelect:isPlaying() then
                self.partSelect:start()
            end
            resetPartVisual = false
        elseif result.type == "harvestable" then
            local harvestable = result:getHarvestable()
            local blueprintName = harvestableSelectBlueprintNameList
            [matchTablePositions(harvestable.uuid, harvestableSelectUuidList)]
            if not self.harvestableSelect then
                self.harvestableSelect = sm.visualization.createBlueprint(("$SURVIVAL_DATA/LocalBlueprints/harvestable_blueprints/" .. blueprintName .. ".blueprint"))
            end
            local offset = harvestable.worldRotation *
            sm.vec3.new(harvestableSelectOffsetList[blueprintName].x, harvestableSelectOffsetList[blueprintName].y,
                harvestableSelectOffsetList[blueprintName].z)
            self.harvestableSelect:setPosition(harvestable.worldPosition + offset)
            self.harvestableSelect:setRotation(harvestable.worldRotation)
            resetHarvestableVisual = false
        elseif result.type == "character" then
            local character = result:getCharacter()
            self.botSelect:setPosition(character.worldPosition + sm.vec3.new(0, 0, 4))
            if not self.botSelect:isPlaying() then
                self.botSelect:start()
            end
            resetBotVisual = false
        end
    end

    --Save start shape when we click
    if primaryState == 1 then
        if result.type == "harvestable" then
            local color = sm.color.new("#ff0000") --placeholder
            local harvestable, splooshesCounter = result:getHarvestable(), 0
            local boxMin, boxMax = harvestable:getAabb()
            for x = math.ceil(boxMin.x), math.floor(boxMax.x) do
                for y = math.ceil(boxMin.y), math.floor(boxMax.y) do
                    for z = math.ceil(boxMin.z), math.floor(boxMax.z) do
                        if x % 2 == 0 and y % 2 == 0 and z % 2 == 0 then
                            splooshesCounter = splooshesCounter + 1
                            local blueprintName = harvestableSelectBlueprintNameList
                            [matchTablePositions(harvestable.uuid, harvestableSelectUuidList)]
                            local offset = harvestable.worldRotation *
                            sm.vec3.new(harvestableSelectOffsetList[blueprintName].x,
                                harvestableSelectOffsetList[blueprintName].y,
                                harvestableSelectOffsetList[blueprintName].z)
                            sm.particle.createParticle("p_painteffect_medium", sm.vec3.new(x, y, z) + offset, nil, color)
                        end
                    end
                end
            end
            if splooshesCounter == 0 then
                sm.particle.createParticle("p_painteffect_large",
                    sm.vec3.new(harvestable.worldPosition.x, harvestable.worldPosition.y,
                        harvestable.worldPosition.z +
                        harvestableCrownPositions[matchTablePositions(harvestable.uuid, harvestableSelectUuidList)]), nil,
                    color)
            end
            harvestable:setColor(color)
            setFpAnimation(self.fpAnimations, "paint", 0.1)
            sm.audio.play("PaintTool - Paint", harvestable.worldPosition)
        end
    end

    --Drag the box
    if primaryState == 2 and hit then
        if result.type == "body" or result.type == "joint" or result.type == "character" or result.type == "harvestable" then

        end
    end

    --Paint
    if primaryState == 3 and hit then
        if result.type == "body" or result.type == "joint" or result.type == "character" or result.type == "harvestable" then

        end
    end

    --Select area to erase
    if secondaryState == 1 then
        if result.type == "harvestable" then
            local harvestable = result:getHarvestable()
            local defaultColor = harvestableDefaultColors
            [matchTablePositions(harvestable.uuid, harvestableSelectUuidList)]
            harvestable:setColor(defaultColor)
            setFpAnimation(self.fpAnimations, "erase", 0.1)
            sm.audio.play("PaintTool - Erase", harvestable.worldPosition)
        end
    end

    --After all the code is executed, reset stuff that we don't need
    if resetPartVisual and self.partSelect:isPlaying() then
        self.partSelect:stopImmediate()
    end

    if resetHarvestableVisual and self.harvestableSelect then
        self.harvestableSelect:destroy()
        self.harvestableSelect = nil
    end

    if resetBotVisual and self.botSelect:isPlaying() then
        self.botSelect:stop()
    end

    return true, true
end

function PaintTool.client_onEquip(self, animate)
    --Play sound
    sm.audio.play("PaintTool - Equip", self.tool:getOwner().character.worldPosition)
    self.wantEquipped = true
    self.jointWeight = 0.0

    currentRenderablesTp = {}
    currentRenderablesFp = {}

    for k, v in pairs(renderablesTp) do currentRenderablesTp[#currentRenderablesTp + 1] = v end
    for k, v in pairs(renderablesFp) do currentRenderablesFp[#currentRenderablesFp + 1] = v end
    for k, v in pairs(renderables) do currentRenderablesTp[#currentRenderablesTp + 1] = v end
    for k, v in pairs(renderables) do currentRenderablesFp[#currentRenderablesFp + 1] = v end
    self.tool:setTpRenderables(currentRenderablesTp)

    self:loadAnimations()

    setTpAnimation(self.tpAnimations, "pickup", 0.0001)

    if self.tool:isLocal() then
        self.tool:setFpRenderables(currentRenderablesFp)
        swapFpAnimation(self.fpAnimations, "unequip", "equip", 0.2)
    end
end

function PaintTool.client_onUnequip(self, animate)
    if self.partSelect:isPlaying() then
        self.partSelect:stopImmediate()
    end
    if self.harvestableSelect then
        self.harvestableSelect:destroy()
        self.harvestableSelect = nil
    end

    sm.audio.play("PaintTool - Unequip", self.tool:getOwner().character.worldPosition)
    self.wantEquipped = false
    self.equipped = false
    if sm.exists(self.tool) then
        setTpAnimation(self.tpAnimations, "putdown")
        if self.tool:isLocal() then
            if self.fpAnimations.currentAnimation ~= "unequip" then
                swapFpAnimation(self.fpAnimations, "equip", "unequip", 0.2)
            end
        end
    end
end

function PaintTool.client_onRefresh(self)
    print("PaintTool refreshed")
    self:client_onCreate()
end
