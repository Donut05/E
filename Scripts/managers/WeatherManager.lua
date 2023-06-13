---@diagnostic disable: need-check-nil, undefined-global

WeatherManager = class( nil )

function WeatherManager.client_onCreate( self )
    self.nexttick = sm.game.getCurrentTick()
    self.rainSoundOffset = sm.vec3.zero()
    self.rain = sm.effect.createEffect( "Environment - Rain" )
    self.rainSound = sm.effect.createEffect( "Environment - Rain_sound" )
    self.rain:setOffsetRotation(sm.vec3.getRotation( sm.vec3.new( 0, 1, 0 ), sm.vec3.new( 0, 0, -1 ) ))
end

function WeatherManager.client_onUpdate( self, dt )
    if self.rainSwitch then
        local player = sm.localPlayer.getPlayer()
        self.rain:setPosition( player.character.worldPosition + sm.vec3.new( player.character.velocity.x / 10 + 0.5, player.character.velocity.y / 10 + 0.5, 0 ) )
        local hit, result = sm.physics.raycast( player.character.worldPosition, player.character.worldPosition + sm.vec3.new( 0, 0, 1000 ) )
        if hit then
            self.rainSound:setPosition( result.pointWorld + sm.vec3.new( 0, 0, 2 ) + self.rainSoundOffset )
            --sm.particle.createParticle("construct_welding", result.pointWorld + sm.vec3.new( 0, 0, 2 ) )
        else
            self.rainSound:setPosition( player.character.worldPosition + sm.vec3.new( 0, 0, 0.5 ) + self.rainSoundOffset )
        end
        if sm.game.getCurrentTick() >= self.nexttick then
            self.nexttick = sm.game.getCurrentTick() + 40
            self.rainSoundOffset = sm.vec3.new( math.random( -0.2, 0.2 ), math.random( -0.2, 0.2 ), 0 )
        end
    end
end

function WeatherManager.sv_toggle_rain( self )
    self.network:sendToClients( "cl_toggle_rain" )
end

function WeatherManager.cl_toggle_rain( self )
    self.rainSwitch = not self.rainSwitch
    if self.rainSwitch then
        self.rain:start()
        self.rainSound:start()
    else
        self.rain:stop()
        self.rainSound:stop()
    end
    print(self.rainSwitch)
end