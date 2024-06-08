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

function Connector.client_onCreate(self)
    --Shape data
    self.firstShape, self.secondShape = nil, nil
    --Flags
    self.animateBeam, self.firstTime, self.setEndasShape, self.passedStep1, self.playSelf = false, true, false, false, false
    --Beam data
    self.start, self._end = sm.vec3.zero(), sm.vec3.zero()
    --Visual and audio effects
    self.effects = {}
    self.pointer = sm.effect.createEffect("Connector - Pointer", self.interactable)
    self.connectionToSelf = sm.effect.createEffect("Connector - Connection_self")
    self.draggingAudioLoop = sm.effect.createEffect("Connector - Connecting_loop", self.interactable)
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

function Connector.cl_stopBeam(self)
    for j = 1, #self.effects do
        if not sm.exists(self.effects[j]) then return end
        self.effects[j]:stopImmediate()
    end
end

function Connector.cl_resetData(self)
    --Shapes
    self.firstShape, self.secondShape = nil, nil
    --Beam data
    self.start, self._end = sm.vec3.zero(), sm.vec3.zero()
    --Flags
    self.animateBeam, self.firstTime, self.setEndasShape, self.passedStep1 = false, true, false, false
end

function Connector.cl_checkForShape(self, isFirst)
    local pos = self.interactable:getWorldBonePosition("pipe")
    local pos2 = self.interactable.shape:transformLocalPoint(sm.vec3.new(0, 0.2, 2.72))
    local sucess, result = sm.physics.raycast(pos, pos2)
    if sucess then
        if result.type == "body" then
            local shape = result:getShape()
            if sm.exists(shape) and shape.interactable then
                if isFirst then
                    print("Selected first shape")
                    self.firstShape = shape
                    self.animateBeam = true
                    self.passedStep1 = true
                else
                    print("Selected second shape")
                    self.secondShape = shape
                    self.animateBeam = true
                end
            else
                self:cl_resetData()
            end
        else
            self:cl_resetData()
        end
    else
        self:cl_resetData()
    end
end

function Connector.cl_visualCheck(self)
    self.playSelf = false
    local pos = self.interactable:getWorldBonePosition("pipe")
    local pos2 = self.interactable.shape:transformLocalPoint(sm.vec3.new(0, 0.2, 2.72))
    local sucess, result = sm.physics.raycast(pos, pos2)
    if sucess then
        if result.type == "body" then
            local shape = result:getShape()
            if sm.exists(shape) and shape.interactable then
                if shape == self.firstShape then
                    self.connectionToSelf:setPosition(shape.worldPosition)
                    self.playSelf = true
                else
                    self.setEndasShape = true
                    self._end = shape.worldPosition
                end
            end
        end
    end
end

function Connector.client_onFixedUpdate(self, dt)
    --Reset if we loose parent
    local parent = self.interactable:getSingleParent()
    if not parent then
        self.firstShape, self.secondShape, self.animateBeam, self.start, self._end = nil, nil, false, sm.vec3.zero(), sm.vec3.zero()
        self.pointer:stop()
        for j = 1, #self.effects do
            if not sm.exists(self.effects[j]) then return end
            self.effects[j]:stopImmediate()
        end
        return
    end

    --Switch pointer on and off
    if parent:isActive() and not self.pointer:isPlaying() then
        self.pointer:start()
    elseif not parent:isActive() and self.pointer:isPlaying() then
        self.pointer:stop()
    end

    --Selection code
    --1. Check for the first shape
    if parent:isActive() and self.firstTime and not self.passedStep1 then
        self.firstTime = false
        self:cl_checkForShape(true)
    end

    --Reset the variable if fail
    if self.firstTime and parent:isActive() == false and sm.exists(self.firstShape) == false then
        self.firstTime = true
    end

    --2. Check for the second shape, connect if needed and reset data
    if sm.exists(self.firstShape) and self.passedStep1 and not (parent:isActive()) then
        self:cl_checkForShape(false)
        if sm.exists(self.firstShape) and sm.exists(self.secondShape) then
            local data = {
                firstShape = self.firstShape,
                secondShape = self.secondShape
            }
            self.network:sendToServer("sv_connect", data)
            sm.effect.playHostedEffect("Builderguide - Stagecomplete", self.firstShape.interactable)
            sm.effect.playHostedEffect("Builderguide - Stagecomplete", self.secondShape.interactable)
            self:cl_resetData()
        end
    end

    --Visualization code
    if self.animateBeam then
        --Try to get the data needed to animate
        if sm.exists(self.firstShape) then
            self.start = self.firstShape.worldPosition
        end
        self:cl_visualCheck()
        if not self.setEndasShape then
            self._end = self.interactable:getWorldBonePosition("pipe")
        else
            self.setEndasShape = false
        end

        --Don't do anything if we don't have all of the nececary data or data will make the algorithm shit itself
        if not (self.start) or not (self._end) or self._end - self.start == sm.vec3.zero() then return end

        --Set and update the connection beam
        for i = 1, segments do
            if not sm.exists(self.effects[i]) then self:cl_createBeam() return end
            self.effects[i]:setPosition(sm.vec3.lerp(self.start, self._end, i / segments))
            self.effects[i]:setRotation(sm.vec3.getRotation(defaultDir, self._end - self.start))
            self.effects[i]:setParameter("Color", self.shape:getColor())
            if not self.effects[i]:isPlaying() then self.effects[i]:start() end
        end
    else
        self.playSelf = false
        self:cl_stopBeam()
    end

    --Play self connect effect
    if self.playSelf then
        if not self.connectionToSelf:isPlaying() then
            self.connectionToSelf:start()
        end
    else
        if self.connectionToSelf:isPlaying() then
            self.connectionToSelf:stopImmediate()
        end
    end
end

function Connector.sv_connect(self, data)
    data.firstShape.interactable:connect(data.secondShape.interactable)
end

function Connector.client_onRefresh(self)
    print("[E mod] (Autoconnnector) Refreshed")
    self:cl_stopBeam()
    self:cl_resetData()
    Connector.client_onCreate(self)
end

function Connector.client_onDestroy(self)
    self:cl_stopBeam()
end