---@diagnostic disable: lowercase-global
dofile("$SURVIVAL_DATA/Scripts/game/util/Timer.lua")

---@class SillyManager : ScriptableObjectClass
SillyManager = class()
SillyManager.eventScores = {
    toilet = 2,
    explode = 5
}

function SillyManager:client_onCreate()
    g_sillyManager = self
    self.cl = {}
end

function SillyManager:server_onCreate()
    self.sv = {}
    self.sv.sillyScores = {}
end

function SillyManager:client_onFixedUpdate(dt)
    local character = sm.localPlayer.getPlayer().character
    if not (character and sm.exists(character)) then return end

    --Enter toilet
    local locking = character:getLockingInteractable()
    if locking ~= self.cl.lastLocking then
        self.cl.lastLocking = locking
        if locking and locking.shape.uuid == sm.uuid.new("ca003562-fde7-463c-969e-f8334ae54387") then
            self.network:sendToServer("sv_onScoreEvent", "toilet")
        end
    end
end

function SillyManager:server_onFixedUpdate(dt)
    for i, _ in ipairs(self.sv.sillyScores) do
        self.sv.sillyScores[i] = math.max(0, self.sv.sillyScores[i] - 0.5/40)
        --sm.gui.chatMessage(tostring(self.sv.sillyScores[i]))
    end
end

function SillyManager:Sv_OnScoreEvent(eventType, player)
    g_sillyManager:sv_onScoreEvent(eventType, player)
end

function SillyManager:sv_onScoreEvent(eventType, caller)
    self:sv_increaseSillyScore({plr = caller, amount = self.eventScores[eventType]})
end

---@param params IncreaseSillyScoreParams
function SillyManager:sv_increaseSillyScore(params, caller)
    if caller then return end
    self.sv.sillyScores[params.plr.id] = (self.sv.sillyScores[params.plr.id] or 0) + params.amount
end

---@class IncreaseSillyScoreParams
---@field plr Player
---@field amount integer