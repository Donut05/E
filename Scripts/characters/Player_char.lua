---@diagnostic disable: need-check-nil, undefined-global

dofile "$SURVIVAL_DATA/Scripts/game/characters/MechanicCharacter.lua"

PlayerChar = class(MechanicCharacter)

local falling

function PlayerChar.server_onCreate(self)
    MechanicCharacter.server_onCreate(self)
    print("PlayerChar.server_onCreate")
end

function PlayerChar.client_onCreate(self)
    MechanicCharacter.client_onCreate(self)
    self.previousTick = sm.game.getCurrentTick()
    falling = sm.effect.createEffect("Player - Anime_lines")
    print("PlayerChar.client_onCreate")
end

function PlayerChar.client_onFixedUpdate(self, dt)
    if not sm.exists(self.character) then
        return
    end
    if not (sm.localPlayer.getPlayer() == self.character:getPlayer()) then return end
    if falling ~= nil then
        if math.abs(self.character.velocity.x) > 20 or math.abs(self.character.velocity.y) > 20 or math.abs(self.character.velocity.z) > 20 then
            falling:setPosition(sm.camera.getPosition() + sm.camera.getDirection())
            local rotation = sm.camera.getRotation() *
            sm.vec3.getRotation(sm.vec3.new(0, 0, -1), sm.vec3.new(0, 1, 0))
            falling:setRotation(rotation)
            falling:start()
        else
            if falling:isPlaying() then
                falling:stop()
            end
        end
    end
end
