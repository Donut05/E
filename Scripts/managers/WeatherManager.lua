---@diagnostic disable: need-check-nil, undefined-global, undefined-field

WeatherManager = class(nil)

function WeatherManager.client_onCreate(self)
    self.rainSoundInsideVolume = 0
    self.rainSoundVolume = 0
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
                --Update inside ambient sound position
                self.rainSoundInside:setPosition(result.pointWorld + sm.vec3.new(0, 0, 2))
                --Lower outside ambient sound volume
                if self.rainSoundVolume > 0 then
                    self.rainSound:setParameter("CAE_Volume", self.rainSoundVolume)
                    self.rainSoundVolume = self.rainSoundVolume - 0.005
                elseif self.rainSoundVolume <= 0 then
                    self.rainSoundVolume = 0
                    self.rainSound:setParameter("CAE_Volume", self.rainSoundVolume) --Even though nothing bad should happen with negative volume, set it to 0 just in case because who the fuck knows
                    self.rainSound:stopImmediate()
                end
                --Boost inside ambient sound volume
                if self.rainSoundInsideVolume >= 1 then
                    self.rainSoundInsideVolume = 1
                    self.rainSoundInside:setParameter("CAE_Volume", self.rainSoundInsideVolume) --Set one more time to avoid ear rape
                elseif self.rainSoundInsideVolume < 1 then
                    self.rainSoundInside:setParameter("CAE_Volume", self.rainSoundInsideVolume)
                    self.rainSoundInsideVolume = self.rainSoundInsideVolume + 0.005
                end
            else
                self.rainSound:setPosition(result.pointWorld + sm.vec3.new(0, 0, 2))
                if not self.rainSound:isPlaying() then
                    self.rainSound:start()
                end
            end
            if self.rainSoundInside:isDone() or not self.rainSoundInside:isPlaying() then --This code loops the sound
                self.rainSoundInside:start()
            end
        else
            --Update outside ambient sound position
            self.rainSound:setPosition(player.character.worldPosition + sm.vec3.new(0, 0, 0.5))
            if sm.cae_injected then
                --Lower inside ambient sound volume
                if self.rainSoundInsideVolume > 0 then
                    self.rainSoundInside:setParameter("CAE_Volume", self.rainSoundInsideVolume)
                    self.rainSoundInsideVolume = self.rainSoundInsideVolume - 0.005
                elseif self.rainSoundInsideVolume <= 0 then
                    self.rainSoundInsideVolume = 0
                    self.rainSoundInside:setParameter("CAE_Volume", self.rainSoundVolume)
                    self.rainSoundInside:stopImmediate()
                end
                --Boost outside ambient sound volume
                if self.rainSoundVolume >= 1 then
                    self.rainSoundVolume = 1
                    self.rainSound:setParameter("CAE_Volume", self.rainSoundVolume)
                elseif self.rainSoundVolume < 1 then
                    self.rainSound:setParameter("CAE_Volume", self.rainSoundVolume)
                    self.rainSoundVolume = self.rainSoundVolume + 0.005
                end
            end
            if self.rainSound:isDone() or not self.rainSound:isPlaying() then --This code loops the sound
                self.rainSound:start()
            end
        end
    else
        if sm.cae_injected then
            if self.rainSoundVolume > 0 then
                self.rainSound:setParameter("CAE_Volume", self.rainSoundVolume)
                self.rainSoundVolume = self.rainSoundVolume - 0.005
            elseif self.rainSoundVolume <= 0 then
                self.rainSoundVolume = 0
                self.rainSound:setParameter("CAE_Volume", self.rainSoundVolume)
                self.rainSound:stopImmediate()
            end
            if self.rainSoundInsideVolume > 0 then
                self.rainSoundInside:setParameter("CAE_Volume", self.rainSoundInsideVolume)
                self.rainSoundInsideVolume = self.rainSoundInsideVolume - 0.005
            elseif self.rainSoundInsideVolume <= 0 then
                self.rainSoundInsideVolume = 0
                self.rainSoundInside:setParameter("CAE_Volume", self.rainSoundVolume)
                self.rainSoundInside:stopImmediate()
            end
        else
            self.rainSound:stop()
        end
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
    end
    print(self.rainSwitch)
end

function WeatherManager.client_onRefresh(self)
    WeatherManager.client_onCreate(self)
end