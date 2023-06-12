---@diagnostic disable: need-check-nil, undefined-global

WeatherManager = class( nil )

local rain

function WeatherManager.client_onCreate( self )
    rain = sm.effect.createEffect( "Environment - Rain" )
    --rain:setWorld( self.scriptableObject:getWorld() )
    rain:setOffsetRotation(sm.vec3.getRotation( sm.vec3.new( 0, 1, 0 ), sm.vec3.new( 0, 0, -1 ) ))
end

function WeatherManager.client_onUpdate( self, dt )
    local oldtick = sm.game.getCurrentTick()
    if self.rainSwitch then
        local players = sm.player.getAllPlayers()
        for i, player in pairs(players) do
            rain:setPosition( player.character.worldPosition + sm.vec3.new( player.character.velocity.x / 10 + 0.5, player.character.velocity.y / 10 + 0.5, 0 ) )
            if sm.game.getCurrentTick() > oldtick then
                sm.effect.playEffect( "Environment - Rain_sound", player.character.worldPosition + sm.vec3.new( math.random( 0, 5 ), math.random( 0, 5 ), 0 ) )
            end
        end
    end
end

function WeatherManager.sv_toggle_rain( self )
    self.network:sendToClients( "cl_toggle_rain" )
end

function WeatherManager.cl_toggle_rain( self )
    self.rainSwitch = not self.rainSwitch
    if self.rainSwitch then
        rain:start()
    else
        rain:stop()
    end
    print(self.rainSwitch)
end