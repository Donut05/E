---@diagnostic disable: need-check-nil, undefined-global

SkyManager = class(nil)

function SkyManager.client_onCreate(self)
    self.effects = {}
    self.moon = {}
    self.effects.moon = sm.effect.createEffect("Skybox - Moon")
end

function SkyManager.client_onFixedUpdate(self, dt)
    self.time = sm.game.getTimeOfDay()
    -- Sun disappears shortly after 0.8
    if self.time > 0.8 then
        print("moon")
        self.moon.previousPosition = sm.localPlayer.getPlayer().character.worldPosition
        if not self.effects.moon:isPlaying() then
            self.effects.moon:start()
        end
        local position = sm.localPlayer.getPlayer().character.worldPosition
        self.effects.moon:setPosition(sm.vec3.lerp(self.moon.previousPosition, position, dt * 2))
    elseif self.time > 0.185 then
        print("no moon")
        if self.effects.moon:isPlaying() then
            self.effects.moon:stopImmediate()
        end
    end
    local angle = (self.time - 0.8) / (1.8 - 0.8) * math.pi
    local scaledY = math.sin(angle)
    local scaledZ = math.cos(angle)
    local rotator = sm.vec3.new(0, scaledY, scaledZ)
    self.effects.moon:setRotation( sm.vec3.getRotation(sm.vec3.new(0, 0, 1), rotator) )
end

function SkyManager.client_onRefresh(self)
    self.effects.moon:destroy()
    self:client_onCreate()
end
