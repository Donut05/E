---@class Grab : ToolClass

Grab = class()

local grabbing = false
local gui = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/Layouts/GrabHandHud.layout", false, {
    isHud = true,
    isInteractive = false,
    needsCursor = false,
    hidesHotbar = false,
    isOverlapped = false,
    backgroundAlpha = 0
})

local function GetBodyMass(result)
    local totalWeight = 0
    local shapes = result:getBody():getShapes()
    for _, shape in ipairs(shapes) do
        totalWeight = totalWeight + shape:getMass()
    end
    return totalWeight
end

function Grab.client_onEquip(self, animate)
    gui:open()
end

function Grab.client_onUnequip(self, animate)
    gui:close()
end

function Grab.client_onFixedUpdate(self, dt)
    ---@diagnostic disable-next-line: unbalanced-assignments
    local effectplaying, previousBody, mass = false
    local hit, result = sm.localPlayer.getRaycast(3)
    if hit then
        if result.type == "body" then
            if not previousBody then
                previousBody = result:getBody()
                mass = GetBodyMass(result)
            else
                if previousBody ~= result:getBody() then
                    mass = GetBodyMass(result)
                end
            end
            if mass < 50 and not grabbing then
                effectplaying = true
                gui:playEffect("HandIcon", "Hand - Open", true)
            end
        end
    elseif effectplaying then
        gui:stopEffect("HandIcon", "Hand - Open", true)
        effectplaying = false
    end
end
