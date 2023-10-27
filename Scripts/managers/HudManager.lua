---@diagnostic disable: need-check-nil, undefined-field

HudManager = class(nil)

local frame = 1

function HudManager.client_onCreate(self)
    self.phoneHUD = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/Layouts/PhoneHud.layout", nil, {
        isHud = true,
        isInteractive = false,
        needsCursor = false,
        hidesHotbar = false,
        isOverlapped = true,
        backgroundAlpha = 0
    })
    self.phoneHUD:setImage("Iphone", "$CONTENT_DATA/Gui/Images/Ui/memes/iphone.png")
    self.phoneHUD:setImage("Crack", "$CONTENT_DATA/Gui/Images/Ui/memes/cracked_screen.png.png")
    self.phoneHUD:setImage("Crack2", "$CONTENT_DATA/Gui/Images/Ui/memes/cracked_screen.png.png")
    self.phoneHUD:open()
end

function HudManager.client_onFixedUpdate(self, dt)
    if frame >= 389 then
        frame = 1
    end
    self.phoneHUD:setImage("SS_gameplay", "$CONTENT_DATA/Gui/Images/Ui/memes/SS_gameplay/" .. tostring(frame) .. ".jpg")
    frame = frame + 1
end