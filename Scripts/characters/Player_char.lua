---@diagnostic disable: need-check-nil, undefined-global

dofile "$SURVIVAL_DATA/Scripts/game/characters/MechanicCharacter.lua"

PlayerChar = class( MechanicCharacter )

local falling

function PlayerChar.server_onCreate( self )
    MechanicCharacter.server_onCreate( self )
    print("PlayerChar.server_onCreate")
end

function PlayerChar.client_onCreate( self )
    MechanicCharacter.client_onCreate( self )
    falling = sm.effect.createEffect( "Player - Anime_lines", self.character )
    print("PlayerChar.client_onCreate")
end

function PlayerChar.client_onFixedUpdate( self, dt )
    local fast
    if not sm.exists( self.character ) then
        return
    end
    print(self.character.velocity:length())
    if falling ~= nil then
        local lockingInteractable = self.character:getLockingInteractable()
        local velocity = 0
        local isDriving = false
        if lockingInteractable then
            fast = sm.effect.createEffect( "Player - Anime_lines", lockingInteractable )
            velocity = lockingInteractable.shape.velocity:length()
            isDriving = true
        else
            velocity = self.character.velocity:length()
        end
        if velocity > 20 then
            local offset
            if isDriving then
                if lockingInteractable and fast ~= nil then
                    local rotate = sm.vec3.getRotation( sm.vec3.new( 0, 1, 0 ), sm.vec3.new( 0, 0, 1 ) )
                    offset = ( rotate * lockingInteractable.shape.worldRotation )
                    fast:setOffsetRotation(offset)
                    fast:start()
                end
            else
                offset = sm.vec3.getRotation( sm.vec3.new( 0, 1, 0 ), self.character:getVelocity() )
                falling:setOffsetRotation(offset)
                falling:start()
            end
        else
            if falling:isPlaying() then
                falling:stop()
            end
            if fast ~= nil and fast:isPlaying() then
                fast:stop()
                fast:destroy()
            end
        end
    end
end