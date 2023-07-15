---@diagnostic disable: lowercase-global
dofile("$SURVIVAL_DATA/Scripts/game/util/Timer.lua")

---@class SillyManager : ScriptableObjectClass
SillyManager = class()

local maxSillyScore = 10000000000000000 --donut decided on this
local scoreLossCooldown = 5*40
local scoreLoss = maxSillyScore/50
local eventScores = {
    toilet = 69420690000000,
    explode = 745510000000000
}

function SillyManager:client_onCreate()
    g_sillyManager = self
    self.cl = {}
    self.cl.sillyScore = 0
    self.cl.scoreLossCooldown = scoreLossCooldown

    g_sillyMeterHud = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/Layouts/SillyMeterHud.layout", nil, {
        isHud = true,
        isInteractive = false,
        needsCursor = false,
        hidesHotbar = false,
        isOverlapped = false,
        backgroundAlpha = 0.0,
    })
	assert(g_sillyMeterHud)
end

function SillyManager:server_onCreate()
    self.sv = {}
end

function SillyManager:client_onFixedUpdate(dt)
    local character = sm.localPlayer.getPlayer().character
    if not (character and sm.exists(character)) then return end

    --Score
    self.cl.scoreLossCooldown = self.cl.scoreLossCooldown - 1
    if self.cl.scoreLossCooldown <= 0 then
        self.cl.scoreLossCooldown = scoreLossCooldown
        self.cl.sillyScore = math.max(self.cl.sillyScore - scoreLoss, 0)
    end
    if self.cl.sillyScore > 0 then
        if not g_sillyMeterHud:isActive() then
            g_sillyMeterHud:open()
        end
        local percentage = self:cl_getScorePercentage()
        g_sillyMeterHud:setImage("SillyMeter", "$CONTENT_DATA/Gui/Images/SillyMeter/"..tostring(percentage)..".png")
    elseif g_sillyMeterHud:isActive() then
        g_sillyMeterHud:close()
    end

    --Enter toilet
    local locking = character:getLockingInteractable()
    if locking ~= self.cl.lastLocking then
        self.cl.lastLocking = locking
        if locking and locking.shape.uuid == sm.uuid.new("ca003562-fde7-463c-969e-f8334ae54387") then
            self:cl_onScoreEvent("toilet")
        end
    end
end

function SillyManager:server_onFixedUpdate(dt)
    for i, _ in ipairs(self.sv.sillyScores) do
        self.sv.sillyScores[i] = math.max(0, self.sv.sillyScores[i] - 0.5 / 40)
        --sm.gui.chatMessage(tostring(self.sv.sillyScores[i]))
    end
end

function SillyManager:Cl_OnScoreEvent(eventType)
    g_sillyManager:cl_onScoreEvent(eventType)
end

function SillyManager:sv_onScoreEvent(eventType, caller)
    self:sv_increaseSillyScore({ plr = caller, amount = self.eventScores[eventType] })
end

---@param params IncreaseSillyScoreParams
function SillyManager:sv_increaseSillyScore(params, caller)
    if caller then return end
    self.sv.sillyScores[params.plr.id] = (self.sv.sillyScores[params.plr.id] or 0) + params.amount
end

---@class IncreaseSillyScoreParams
---@field plr Player
---@field amount integer
