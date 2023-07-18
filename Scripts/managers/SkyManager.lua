---@diagnostic disable: need-check-nil, undefined-global

SkyManager = class(nil)

-- Sun disappears shortly after 0.8 and disappears after 0.185
-- Moon and sun intentionally have a bit of an overlap for cool screenshot potential
-- Note: This WILL require an update once QMark makes moving sun into a dll plugin
SkyManager.moonStartTime = 0.8 --0.85 --Please don't change these values, I beg you
SkyManager.moonEndTime = 0.185 --0.16
SkyManager.moonDistance = 1500

function SkyManager.client_onCreate(self)
    self.effects = self.effects or {}
    self.moon = { previousPosition = sm.vec3.zero(), angle = 0 }
    self.effects.moon = sm.effect.createEffect("Skybox - Moon")
end

function convertToValue(floatValue, minRange, maxRange)
    local value = 0

    -- Handling the range [0.8, 1.0]
    if floatValue >= 0.8 and floatValue <= 1.0 then
        value = minRange + (floatValue - 0.8) * ((maxRange - minRange) / 0.2) -- Linear interpolation
    end

    -- Handling the range [0.0, 0.185]
    if floatValue > 0.0 and floatValue <= 0.185 then
        value = maxRange - (floatValue - 1.0) * ((maxRange - minRange) / 0.185) -- Linear interpolation
    end

    return value * -1
end

function SkyManager:client_onFixedUpdate(dt)
    if not self.time then return end

    self.moon.angle = convertToValue(self.time, SkyManager.moonStartTime, SkyManager.moonEndTime)
    print(self.moon.angle)
end

function SkyManager.client_onUpdate(self, dt)
    if not sm.localPlayer.getPlayer().character then return end

    self.time = sm.game.getTimeOfDay()
    if self.time > self.moonStartTime or self.time <= self.moonEndTime then
        if not self.effects.moon:isPlaying() then
            self.effects.moon:start()
        end
        local offset_pos = sm.localPlayer.getPlayer().character.worldPosition
        local angle = 1 * (math.pi / 12)
        local rotation = sm.quat.angleAxis(angle, sm.vec3.new(0, 0, 1))
        rotation = rotation * sm.quat.angleAxis(-math.rad(self.moon.angle), sm.vec3.new(0, 1, 0))
        local final_direction = rotation * sm.vec3.new(1, 0, 0) * SkyManager.moonDistance

        self.effects.moon:setPosition(offset_pos + final_direction)
    elseif self.time > self.moonEndTime then
        if self.effects.moon:isPlaying() then
            self.effects.moon:stopImmediate()
        end
    end
end

function SkyManager.client_onRefresh(self)
    self.moon.angle = 0
    self.effects.moon:stopImmediate()
    self.effects.moon:destroy()
    SkyManager.client_onCreate(self)
end
