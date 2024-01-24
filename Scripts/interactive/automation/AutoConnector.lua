---@diagnostic disable: need-check-nil, lowercase-global
---@class Connector : ShapeClass

dofile("$CONTENT_DATA/Scripts/visualised_trigger.lua")

Connector = class(nil)
Connector.maxParentCount = 1
Connector.connectionInput = sm.interactable.connectionType.logic
Connector.colorNormal = sm.color.new("f1ca06")
Connector.colorHighlight = sm.color.new("f6e857")

local defaultDir = sm.vec3.new(0, 0, 1)
local segments = 14
local reset_data = false

function Connector.client_onCreate(self)
    --Data
    self.start, self._end = sm.vec3.zero(), sm.vec3.zero()
    self.firstShape, self.secondShape = nil, nil
    --Flags for stage advancing
    self.stage, self.resetProgress, self.wasPowered, self.hasAcceptableInteratable, self.isFirstLoopAfterStageSwitch = 0, 0, false, false, true
    --Visual and audio effects
    self.effects = {}
    self.draggingAudioLoop = sm.effect.createEffect("Connector - Connecting_loop")
    self.pointer = sm.effect.createEffect("Connector - Pointer", self.interactable)
    self:cl_createBeam()
end

function Connector.cl_createBeam(self)
    for i = 1, segments do
        if i == 1 then
            self.effects[i] = sm.effect.createEffect("Connector - Connection_first")
        elseif i == segments then
            self.effects[i] = sm.effect.createEffect("Connector - Connection_last")
        else
            self.effects[i] = sm.effect.createEffect("Connector - Connection")
        end
    end
end

function Connector.client_onFixedUpdate(self, dt)
    --Reset if we loose the connection
    local parent = self.interactable:getSingleParent()
    if not parent then
        sm.gui.displayAlertText("NO PARENT!")
        self.stage, self.firstShape, self.secondShape, self.start, self._end, self.wasPowered, self.hasAcceptableInteratable, self.isFirstLoopAfterStageSwitch = 0, nil, nil, sm.vec3.zero(), sm.vec3.zero(), false, false, true
        self.pointer:stop()
        for j = 1, #self.effects do
            if not sm.exists(self.effects[j]) then return end
            self.effects[j]:stopImmediate()
        end
        return
    end

    sm.gui.displayAlertText("STAGE " .. tostring(self.stage))

    --Do a raycast all the time that we use a lot later
    local pos = self.interactable:getWorldBonePosition("pipe")
    local pos2 = self.interactable.shape:transformLocalPoint(sm.vec3.new(0, 0.2, 2.72))
    local sucess, result = sm.physics.raycast(pos, pos2)

    if self.stage == 0 then --Stage 0 | Buffer stage to make resetting intuitive
        if self.resetProgress == 0 then
            if not parent:isActive() then
                self.resetProgress = 1
            end
        elseif self.resetProgress == 1 then
            if parent:isActive() then
                self.stage = 1
                self.resetProgress = 0
            end
        end
    elseif self.stage == 1 then --Stage 1 | Power the part => point at the first shape => unpower the part => we start pulling a conncection

        --Check parent
        if parent:isActive() and not self.pointer:isPlaying() then
            self.pointer:start()
        end
        if parent:isActive() then
            --Remember that we achieved the first half of the rquirements to go to the next step
            self.wasPowered = true
        end

        --Use raycast data to find out if we are pointing at an interactible we can connect
        if sucess then
            if result.type == "body" then
                local shape = result:getShape()
                if sm.exists(shape) and shape.interactable then
                    --Remember the shape if it passes as acceptable
                    self.firstShape = shape
                    self.hasAcceptableInteratable = true
                    self.start = self.firstShape.worldPosition
                    if parent:isActive() then
                        sm.effect.playEffect("Saw - Debris", self.firstShape.worldPosition)
                    end
                else
                    reset_data = true
                end
            else
                reset_data = true
            end
        else
            reset_data = true
        end

        --Reset data if we move on from an acceptable shape
        if reset_data then
            reset_data = false
            self.firstShape, self.hasAcceptableInteratable = nil, false
        end

        --Remember that the first loop after a stage switch has passed
        self.isFirstLoopAfterStageSwitch = false

        --Go to the next stage if we have:
        --    1. An acceptable shape       2. We WERE powered 3. We are CURRENTLY unpowered
        if self.hasAcceptableInteratable and self.wasPowered and not parent:isActive() then
            self.stage = 2
            self.isFirstLoopAfterStageSwitch = true
        end
    elseif self.stage == 2 then --Stage 1 | Start drggaing the connection line => point at the second shape => wait for the part to get powered

        --Reset if any of the vital actors are not present
        if not sm.exists(self.firstShape) then
            print("Reset")
            self.stage, self.firstShape, self.hasAcceptableInteratable, self.isFirstLoopAfterStageSwitch = 0, nil, false, true
            if self.draggingAudioLoop:isPlaying() then
                self.draggingAudioLoop:stopImmediate()
            end
            return
        end

        --Start playing audio
        if not self.draggingAudioLoop:isPlaying() then
            self.draggingAudioLoop:start()
        end

        --Set up required data
        self.start = self.firstShape.worldPosition
        if self.isFirstLoopAfterStageSwitch then
            self.isFirstLoopAfterStageSwitch = false
            self.wasPowered, self.hasAcceptableInteratable = false, false
        end

       --Use raycast data to find out if we are pointing at an interactible we can connect
        if sucess then
            if result.type == "body" then
                local shape = result:getShape()
                if sm.exists(shape) and shape.interactable and shape ~= self.firstShape then
                    --Remember the shape if it passes as acceptable
                    self.secondShape = shape
                    self.hasAcceptableInteratable = true
                    self._end = self.secondShape.worldPosition
                    sm.effect.playEffect("Saw - Debris", self.secondShape.worldPosition)
                else
                    reset_data = true
                end
            else
                reset_data = true
            end
        else
            reset_data = true
        end

        --Reset data if we move on from an acceptable shape
        if reset_data then
            reset_data = false
            self._end = self.interactable:getWorldBonePosition("pipe")
            self.secondShape, self.hasAcceptableInteratable = nil, false
        end

        --Create and update the connection beam
        if self._end ~= sm.vec3.zero() and self.start ~= sm.vec3.zero() then
            for i = 1, segments do
                if not sm.exists(self.effects[i]) then self:cl_createBeam() return end
                self.effects[i]:setPosition(sm.vec3.lerp(self.start, self._end, i / segments))
                self.effects[i]:setRotation(sm.vec3.getRotation(defaultDir, self._end - self.start))
                self.effects[i]:setParameter("Color", self.shape:getColor())
                if not self.effects[i]:isPlaying() then self.effects[i]:start() end
            end
        end

        --Go to the next stage if we have:
        --    1. An acceptable shape        2. Parent is active
        if self.hasAcceptableInteratable and parent:isActive() then
            self.stage = 3
            self.isFirstLoopAfterStageSwitch = true
        end
    elseif self.stage == 3 then --Stage 3 | Connect the two interactibles

        --Stop audio
        if self.draggingAudioLoop:isPlaying() then
            self.draggingAudioLoop:stopImmediate()
        end

        --Stop the pointer
        if self.pointer:isPlaying() then
            self.pointer:stop()
        end

        --Stop the beam
        for _, effect in pairs(self.effects) do
            effect:stopImmediate()
            effect:destroy()
        end

        --Connect the two interactables
        local data = {
            firstShape = self.firstShape,
            secondShape = self.secondShape
        }
        self.network:sendToServer("sv_connect", data)

        --Play confimation effects on both
        sm.effect.playHostedEffect("Builderguide - Stagecomplete", self.firstShape.interactable)
        sm.effect.playHostedEffect("Builderguide - Stagecomplete", self.secondShape.interactable)

        --Reset
        self.stage, self.firstShape, self.secondShape, self.start, self._end, self.wasPowered, self.hasAcceptableInteratable = 0, nil, nil, sm.vec3.zero(), sm.vec3.zero(), false, false
        return
    end
end

function Connector.sv_connect(self, data)
    data.firstShape.interactable:connect(data.secondShape.interactable)
end

function Connector.client_onRefresh(self)
    print("REFRESHED")
    for _, effect in pairs(self.effects) do
        if sm.exists(effect) then
            effect:stopImmediate()
            effect:destroy()
        end
    end
    Connector.client_onCreate(self)
end
