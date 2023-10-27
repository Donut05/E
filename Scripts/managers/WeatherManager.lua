---@diagnostic disable: need-check-nil, undefined-global, undefined-field

WeatherManager = class(nil)

function WeatherManager.client_onCreate(self)
    self.rainSoundInsideVolume = 0
    self.rainSoundVolume = 0
    self.nexttick = sm.game.getCurrentTick()
    self.rain = sm.effect.createEffect("Environment - Rain")
    if sm.cae_injected then
        self.rainSound = sm.effect.createEffect("Environment - Rain_sound_DLL")
        self.rainSoundInside = sm.effect.createEffect("Environment - Rain_sound_inside_DLL")
        self.rainSound:setParameter("CAE_Volume", self.rainSoundVolume)
        self.rainSoundInside:setParameter("CAE_Volume", self.rainSoundInsideVolume)
    else
        self.rainSound = sm.effect.createEffect("Environment - Rain_sound_noDLL")
    end
end

function WeatherManager.client_onUpdate(self, dt)
    if self.rainSwitch then
        local player = sm.localPlayer.getPlayer()
        self.rain:setPosition(sm.vec3.new(player.character.worldPosition.x, player.character.worldPosition.y, 0) + sm.vec3.new(player.character.velocity.x / 10 + 0.5, player.character.velocity.y / 10 + 0.5, 0))
        local hit, result = sm.physics.raycast(player.character.worldPosition, player.character.worldPosition + sm.vec3.new(0, 0, 14))
        local hit2, hit3, hit4, hit5, trash
        hit2, trash = sm.physics.raycast(player.character.worldPosition, player.character.worldPosition + sm.vec3.new(14, 0, 0))
        hit3, trash = sm.physics.raycast(player.character.worldPosition, player.character.worldPosition + sm.vec3.new(-14, 0, 0))
        hit4, trash = sm.physics.raycast(player.character.worldPosition, player.character.worldPosition + sm.vec3.new(0, 14, 0))
        hit5, trash = sm.physics.raycast(player.character.worldPosition, player.character.worldPosition + sm.vec3.new(0, -14, 0))
        if hit and hit2 and hit3 and hit4 and hit5 then
            if sm.cae_injected then
                self.rainSoundInside:setPosition(result.pointWorld + sm.vec3.new(0, 0, 2))
                if self.rainSoundVolume >= 0 then
                    print(self.rainSoundVolume)
                    self.rainSound:setParameter("CAE_Volume", self.rainSoundVolume)
                    self.rainSoundVolume = self.rainSoundVolume - 0.01
                elseif self.rainSoundVolume <= 0 then
                    self.rainSound:stopImmediate()
                end
                print(self.rainSoundInsideVolume)
                if self.rainSoundInsideVolume <= 0 then
                    if not self.rainSoundInside:isPlaying() then
                        self.rainSoundInside:start()
                    end
                    self.rainSoundInside:setParameter("CAE_Volume", self.rainSoundInsideVolume)
                    self.rainSoundInsideVolume = self.rainSoundInsideVolume + 0.01
                end
            else
                self.rainSound:setPosition(result.pointWorld + sm.vec3.new(0, 0, 2))
                if not self.rainSound:isPlaying() then
                    self.rainSound:start()
                end
            end
            if self.rainSoundInside:isDone() or not self.rainSoundInside:isPlaying() then
                self.rainSoundInside:start()
            end
        else
            self.rainSound:setPosition(player.character.worldPosition + sm.vec3.new(0, 0, 0.5))
            if sm.cae_injected then
                if self.rainSoundInsideVolume >= 0 then
                    self.rainSound:setParameter("CAE_Volume", self.rainSoundInsideVolume)
                    self.rainSoundInsideVolume = self.rainSoundInsideVolume - 0.01
                elseif self.rainSoundInsideVolume <= 0 then
                    self.rainSoundInside:stop()
                end
                if self.rainSoundVolume <= 0 then
                    if not self.rainSound:isPlaying() then
                        self.rainSound:start()
                    end
                    self.rainSound:setParameter("CAE_Volume", self.rainSoundVolume)
                    self.rainSoundVolume = self.rainSoundVolume + 0.01
                end
            end
        end
        if sm.game.getCurrentTick() >= self.nexttick then
            self.nexttick = sm.game.getCurrentTick() + 40
        end
    else

    end
end

function WeatherManager.sv_toggle_rain(self)
    self.network:sendToClients("cl_toggle_rain")
end

function WeatherManager.cl_toggle_rain(self)
    self.rainSwitch = not self.rainSwitch
    if self.rainSwitch then
        self.rain:start()
    else
        self.rain:stop()
        self.rainSound:stop()
        self.rainSoundInside:stop()
    end
    print(self.rainSwitch)
end

function WeatherManager.client_onRefresh(self)
    WeatherManager.client_onCreate(self)
end