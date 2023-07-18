---@diagnostic disable: need-check-nil, undefined-global

SkyManager = class(nil)

-- Sun disappears shortly after 0.85 and disappears after 0.16
-- Moon and sun intentionally have a bit of an overlap for cool screenshot potential
-- Note: This WILL require an update once QMark makes moving sun into a dll plugin
SkyManager.moonStartTime = 0.85 --Please don't change these values, I beg you
SkyManager.moonEndTime = 0.16

function SkyManager.client_onCreate(self)
    self.effects = self.effects or {}
    self.moon = { previousPosition = sm.vec3.zero(), angle = 0 }
    self.effects.moon = sm.effect.createEffect("Skybox - Moon")
end

function SkyManager:client_onFixedUpdate(dt)
    if not self.time then return end

    local offsetAngle = 70 --please don't change any of these either
    local maxAngleMul = 2
    self.moon.angle = sm.util.lerp(0, 360*maxAngleMul, self.time) + offsetAngle
end

function SkyManager.client_onUpdate(self, dt)
    if not sm.localPlayer.getPlayer().character then return end

    self.time = sm.game.getTimeOfDay()
    if self.time > self.moonStartTime or self.time <= self.moonEndTime then
        if not self.effects.moon:isPlaying() then
            self.effects.moon:start()
        end
        local angle = self.moon.angle * math.pi / 180
        local radius = 1000
        local rotationOffset = sm.vec3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
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
