---@diagnostic disable: need-check-nil, undefined-global

SkyManager = class(nil)
SkyManager.moonStartTime = 0.9
SkyManager.moonEndTime = 0.185

local function calculateProgress(value, minValue, maxValue)
    local range = maxValue - minValue
    local progress = (value - minValue) % range
    local result = progress / range
    return (result-1)*-1
end

function SkyManager.client_onCreate(self)
    self.effects = self.effects or {}
    self.moon = { previousPosition = sm.vec3.zero(), angle = 0 }
    self.effects.moon = sm.effect.createEffect("Skybox - Moon")
end

function SkyManager:client_onFixedUpdate(dt)
    self.moon.angle = sm.util.lerp(-5, 185, calculateProgress(self.time, self.moonStartTime, self.moonEndTime))
end

function SkyManager.client_onUpdate(self, dt)
    if not sm.localPlayer.getPlayer().character then return end

    self.time = sm.game.getTimeOfDay()
    -- Sun disappears shortly after 0.8
    if self.time > self.moonStartTime or self.time <= self.moonEndTime then
        if not self.effects.moon:isPlaying() then
            self.effects.moon:start()
        end
        local angle = self.moon.angle *math.pi/180
        local radius = 1000
        local rotationOffset = sm.vec3.new(math.cos(angle)*radius, 0, math.sin(angle)*radius)
        local position = sm.localPlayer.getPlayer().character.worldPosition + rotationOffset
        self.moon.previousPosition = sm.vec3.lerp(self.moon.previousPosition, position, dt * 50)
        self.effects.moon:setPosition(self.moon.previousPosition)
    elseif self.time > self.moonEndTime then
        if self.effects.moon:isPlaying() then
            self.effects.moon:stopImmediate()
            self.moon.angle = 0
        end
    end
end

function SkyManager.client_onRefresh(self)
    self.moon.angle = 0
end