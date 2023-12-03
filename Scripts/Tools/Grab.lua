---@diagnostic disable: need-check-nil, duplicate-set-field
---@class Grab : ToolClass

Grab = class()

function Grab.client_onCreate(self)
    self.grabbing = false
    self.hit = false
    self.result = {}
    self.gui = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/Layouts/GrabHandHud.layout", false, {
        isHud = true,
        isInteractive = false,
        needsCursor = false,
        hidesHotbar = false,
        isOverlapped = false,
        backgroundAlpha = 0
    })
end

local function GetBodyMass(result)
    local totalWeight = 0
    local shapes = result:getBody():getShapes()
    for _, shape in ipairs(shapes) do
        totalWeight = totalWeight + shape:getMass()
    end
    return totalWeight
end

function Grab.client_onEquip(self, animate)
    if sm.exists(self.gui) then
        self.gui:open()
    end
end

function Grab.client_onUnequip(self, animate)
    if sm.exists(self.gui) then
        self.gui:close()
    end
    self.hit = false
    self.result = nil
    self.grabbing = false
end

function Grab.client_onEquippedUpdate(self, primaryState, secondaryState, forceBuild)
    --Fire a raycast upon pressing LMB
    if primaryState == 1 then
        self.hit, self.result = sm.localPlayer.getRaycast(3)
    end
    --Check if we can grab the object or not
    if primaryState == 2 and self.hit and self.result.type == "body" and not self.result:getBody():isStatic() then
        if GetBodyMass(self.result) > 1000 then
            self.gui:setImage("HandIcon", "$CONTENT_DATA/Gui/Images/Ui/hand-heavy-icon.png")
        elseif GetBodyMass(self.result) < 1000 then
            self.grabbing = true
        end
    end
    --Clear the variables when releasing LMB or RMB
    if primaryState == 3 then
        self.hit = false
        self.result = nil
        self.grabbing = false
    end

    return true, true
end

function Grab.client_onFixedUpdate(self, dt)
    --If we are trying to grab and the body no longer exists for some reason, clear the data and stop the code execution
    if self.grabbing and not sm.exists(self.result:getBody()) then
        self.hit = false
        self.result = nil
        self.grabbing = false
    end
    --Raycast that checks if the shape can be grabbed and sets the appropriate icon
    if not self.grabbing then
        local hit, result = sm.localPlayer.getRaycast(3)
        if hit and result.type == "body" and not result:getBody():isStatic() then
            self.gui:setImage("HandIcon", "$CONTENT_DATA/Gui/Images/Ui/hand-open-icon.png")
        else
            self.gui:setImage("HandIcon", "$CONTENT_DATA/Gui/Images/empty.png")
        end
    end
    --Handle the grabbing
    if self.grabbing and sm.exists(self.gui) then
        local mass, grabbedBody = GetBodyMass(self.result), self.result:getBody()
        if mass < 1000 then
            self.gui:setImage("HandIcon", "$CONTENT_DATA/Gui/Images/Ui/hand-grab-icon.png")
            local CooM = grabbedBody:getCenterOfMassPosition()
            local FinalDestination = sm.localPlayer.getRaycastStart() + sm.camera.getDirection() * 2
            local Direction = FinalDestination - CooM
            sm.physics.applyImpulse(grabbedBody, (Direction * mass) - (grabbedBody:getVelocity() * (mass * 0.1)), true)
            if Direction:length() > 1.5 then
                self.hit = false
                self.result = nil
                self.grabbing = false
            end
        end
    end
end

function Grab.client_onDestroy(self)
    if sm.exists(self.gui) then
        self.gui:close()
        self.gui:destroy()
    end
end

function Grab.client_onRefresh(self)
    Grab.client_onCreate(self)
end