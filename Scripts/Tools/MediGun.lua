---@diagnostic disable: need-check-nil
---@class Medi : ToolClass
Medi = class()

local defaultDir = sm.vec3.new(1,0,0) --I'm not exactly sure if the effect faces up but whatever

function Medi.sv_updateTarget( self, target )
    self.network:sendToClients("cl_updateTarget", target)
    self.effects = {}
end

function Medi.client_onCreate( self )
    self.target = nil
end

function Medi.client_onUpdate( self )
    if not self.target then return end

    local cycles = 20
    local owner = self.tool:getOwner().character
    local start = owner.worldPosition
    local mid = start + owner.direction * 5
    local _end = self.target.worldPosition
    local oldTick = sm.game.getCurrentTick()

    if owner.smoothDirection.z < -0.3 then --Fix beam clipping
        local hit, result = sm.localPlayer.getRaycast( (mid - start):length() )
        if hit then
            mid.x = result.pointWorld.x
            mid.y = result.pointWorld.y
            mid.z = result.pointWorld.z
        end
    end

    local posCache = {} --Generate position cache for rotation
    for j = 1, cycles do
        posCache[j] = sm.vec3.bezier2( start, mid, _end, j / cycles)
    end
    for i = 1, cycles do
        self.effects[#self.effects+1] = sm.effect.createEffect( "Medi - Beam_segment" )
        self.effects[i]:setPosition( sm.vec3.bezier2( start, mid, _end, i / cycles) )

        local pos = posCache[i]
        local nextPos = posCache[i + 1]
        if nextPos then
            self.effects[i]:setRotation( sm.vec3.getRotation((nextPos - pos):normalize(), defaultDir) )
        end
        self.effects[i]:start()
    end
    if sm.game.getCurrentTick() > oldTick then --Clears old particles
        if #self.effects > 0 then
            for _, effect in ipairs(self.effects) do
                effect:stopImmediate()
            end
            self.effects = {}
        end
    end

    local distance = (self.target.worldPosition - owner.worldPosition):length()
    if distance > 10 then
        self.target = nil
    end
end

function Medi.server_onFixedUpdate( self, dt )
    if not self.target then return end
    if self.target:isPlayer() then
        local edibleParams = {
            hpGain = 1
        }
        sm.event.sendToPlayer( self.target:getPlayer(), "sv_e_eat", edibleParams )
    else
        self.target:setTumbling( true )
    end
end

function Medi.client_onEquippedUpdate( self, lmb )
    if lmb == 1 then
        if self.target then
            self.network:sendToServer("sv_updateTarget", nil)
        else
            local hit, result = sm.localPlayer.getRaycast(7.5)
            if hit then
                local character = result:getCharacter()
                if character then
                    self.network:sendToServer("sv_updateTarget", character)
                end
            end
        end
    end

    return true, true
end

function Medi.cl_updateTarget( self, target )
    self.target = target
end