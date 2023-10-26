---@diagnostic disable: need-check-nil, undefined-global, undefined-field

WeatherManager = class(nil)

function WeatherManager.client_onCreate(self)
    self.volumeDownGeneric = 1
    self.volumeUpGeneric = 0
    self.startLoweringVolume = false
    self.startBoostingVolume = false
    self.doneLowering = false
    self.doneBoosting = false
    self.nexttick = sm.game.getCurrentTick()
    self.rain = sm.effect.createEffect("Environment - Rain")
    if sm.cae_injected then
        self.rainSound = sm.effect.createEffect("Environment - Rain_sound_DLL")
        self.rainSoundInside = sm.effect.createEffect("Environment - Rain_sound_inside_DLL")
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
            if sm.cae_injected and self.rainSoundInside then
                self.rainSoundInside:setPosition(result.pointWorld + sm.vec3.new(0, 0, 2))
                if not self.doneLowering then
                    self.effectWeAreLowering = self.rainSound
                    self.startLoweringVolume = true
                end
                if not self.doneBoosting then
                    self.effectWeAreBoosting = self.rainSoundInside
                    self.startBoostingVolume = true
                else
                    if self.rainSoundInside:isDone() or not self.rainSoundInside:isPlaying() then
                        self.rainSoundInside:start()
                    end
                end
            else
                self.rainSound:setPosition(result.pointWorld + sm.vec3.new(0, 0, 2))
            end
        else
            if self.doneLowering then
                self.doneLowering = false
                self.effectWeAreBoosting = self.rainSound
                self.startBoostingVolume = true
            end
            if self.doneBoosting then
                self.doneBoosting = false
                self.effectWeAreLowering = self.rainSoundInside
                self.startLoweringVolume = true
            end
            self.rainSound:setPosition(player.character.worldPosition + sm.vec3.new(0, 0, 0.5))
        end
        if sm.game.getCurrentTick() >= self.nexttick then
            self.nexttick = sm.game.getCurrentTick() + 40
        end
    else
        self.doneBoosting = true
        self.effectWeAreLowering = self.rainSound
        self.startLoweringVolume = true
    end
end

function WeatherManager.client_onFixedUpdate(self, dt)
    if self.startLoweringVolume and self.effectWeAreLowering then
        self.effectWeAreLowering:setParameter("CAE_Volume", self.volumeDownGeneric)
        self.volumeDownGeneric = self.volumeDownGeneric - 0.01
        --print(self.volumeDownGeneric)
        if self.volumeDownGeneric >= 0 then
            self.startLoweringVolume = false
            self.doneLowering = true
            self.effectWeAreLowering:setParameter("CAE_Volume", 0)
            self.effectWeAreLowering:stopImmediate()
            self.effectWeAreLowering = nil
            self.volumeDownGeneric = 1
        end
    end
    if self.startBoostingVolume and self.effectWeAreBoosting then
        if not self.effectWeAreBoosting:isPlaying() then
            self.effectWeAreBoosting:start()
        end
        self.effectWeAreBoosting:setParameter("CAE_Volume", self.volumeUpGeneric)
        self.volumeUpGeneric = self.volumeUpGeneric + 0.01
        --print(self.volumeUpGeneric)
        if self.volumeUpGeneric >= 1 then
            self.startBoostingVolume = false
            self.doneBoosting = true
            self.effectWeAreBoosting:setParameter("CAE_Volume", 1)
            self.effectWeAreBoosting = nil
            self.volumeUpGeneric = 0
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
        self.rainSound:start()
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