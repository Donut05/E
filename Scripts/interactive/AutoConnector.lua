---@diagnostic disable: need-check-nil, lowercase-global

Connector = class(nil)
Connector.maxParentCount = 1
Connector.connectionInput = sm.interactable.connectionType.logic
Connector.colorNormal = sm.color.new("f1ca06")
Connector.colorHighlight = sm.color.new("f6e857")

local defaultDir = sm.vec3.new(0, 0, 1)
g_prevlength = 0

local function recreateParticles(self)
    self.effects = {}
    local loops = (self._end - self.start):length()
    for i = 1, loops do
        if i == 1 then
            self.effects[#self.effects + 1] = sm.effect.createEffect("Connector - Connection_first")
        elseif i == loops then
            self.effects[#self.effects + 1] = sm.effect.createEffect("Connector - Connection_last")
        else
            self.effects[#self.effects + 1] = sm.effect.createEffect("Connector - Connection")
        end
    end
end

function Connector.client_onCreate(self)
    self.pointer = sm.effect.createEffect("Connector - Pointer", self.interactable)
    self.start = sm.vec3.zero()
end

function Connector.client_onUpdate(self, dt)
    local parent = self.interactable:getSingleParent()
    if not parent then
        self.pointer:stop()
        return
    end

    self._end = self.interactable:getWorldBonePosition("pipe")

    local length = (self._end - self.start):length()
    if length ~= g_prevlength then
        print("EEEE")
        g_prevlength = length
        recreateParticles(self)
    end

    local posCache = {} --Generate position cache for rotation
    local loops = (self._end - self.start):length()
    for j = 1, loops do
        posCache[j] = sm.vec3.lerp(self.start, self._end, j / loops)
    end

    for i = 1, loops do
        local pos = posCache[i]
        local effect = self.effects[i]
        if not effect then return end
        effect:setPosition(pos)

        local nextPos = posCache[i + 1]
        if nextPos then
            effect:setRotation(sm.vec3.getRotation(defaultDir, nextPos - pos))
        else
            effect:setRotation(sm.vec3.getRotation(defaultDir, posCache[i - 1] - posCache[i - 2]))
        end
        effect:setParameter("Color", self.shape:getColor())
        if not effect:isPlaying() then effect:start() end
    end
    if parent:isActive() then
        if not self.pointer:isPlaying() then
            self.pointer:start()
        end
    else
        self.pointer:stop()
    end
end

function Connector.client_onRefresh(self)
    Connector.client_onCreate(self)
end
