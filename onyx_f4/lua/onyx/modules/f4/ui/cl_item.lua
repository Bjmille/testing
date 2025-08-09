--[[

Author: tochnonement
Email: tochnonement@gmail.com

30/12/2023

--]]

local colorPrimary = onyx:Config('colors.primary')
local colorSecondary = onyx:Config('colors.secondary')
local colorOutline = Color(255, 255, 255, 5)
local colorGray = Color(159, 159, 159)
local fontDesc = onyx.Font('Comfortaa@16')
local colorFavoriteIconIdle = Color(235, 235, 235)
local colorFavoriteIconActive = Color(255, 241, 93)

local PANEL = {}

function PANEL:Init()
    self.padding = onyx.ScaleTall(7.5)
    self.itemColor = color_white
    self.itemColorBG = colorPrimary
    self.colorBG = colorSecondary
    self.colorBGGradient = Color(57, 57, 57, 25)
    self.gradientEnabled = onyx.f4:GetOptionValue('colored_items')

    self.iconContainer = self:Add('Panel')
    self.iconContainer:SetMouseInputEnabled(false)
    self.iconContainer.PerformLayout = function(panel, w, h)
        panel.mask = onyx.CalculateCircle(w * .5, h * .5, h * .5 - 2, 24)
    end
    self.iconContainer.Paint = function(panel, w, h)
        local child = panel:GetChild(0)
        if (IsValid(child)) then
            onyx.DrawCircle(w * .5, h * .5, h * .5, self.itemColorBG)

            onyx.DrawWithPolyMask(panel.mask, function()
                child:PaintManual()
            end)

            onyx.DrawOutlinedCircle(w * .5, h * .5, h * .5, 3, self.itemColor)
        end
    end

    if (onyx.f4:GetOptionValue('model_3d')) then
        self.iconModel = self.iconContainer:Add('DModelPanel')
        self.iconModel.LayoutEntity = function() end
        self.iconModel.PreDrawModel = function(panel)
            if (surface.GetAlphaMultiplier() < .5) then
                return false
            end
        end
    else
        self.iconModel = self.iconContainer:Add('SpawnIcon')
    end
    self.iconModel:Dock(FILL)
    self.iconModel:SetPaintedManually(true)
    self.iconModel:DockMargin(2, 2, 2, 2)

    self.lblName = self:Add('onyx.Label')
    self.lblName:SetText('Name')
    self.lblName:Font('Comfortaa Bold@18')
    self.lblName:SetContentAlignment(1)

    self.pnlDesc = self:Add('Panel')
    self.pnlDesc:SetMouseInputEnabled(false)
    self.pnlDesc.label = ''
    self.pnlDesc.text = ''
    self.pnlDesc.color = ''
    self.pnlDesc.Paint = function(panel, w, h)
        local label = panel.label:Trim()
        if (label ~= '') then
            local textW = draw.SimpleText(label .. ': ', fontDesc, 0, 0, colorGray, 0, 0)
            draw.SimpleText(panel.text, fontDesc, textW, 0, panel.color, 0, 0)
        else
            draw.SimpleText(panel.text, fontDesc, 0, 0, panel.color, 0, 0)
        end
    end
end

function PANEL:GetName()
    return self.lblName:GetText()
end

function PANEL:SetDescLabel(label)
    self.pnlDesc.label = label
end

function PANEL:SetDesc(desc)
    self.pnlDesc.text = desc
end

function PANEL:SetDescColor(label)
    self.pnlDesc.color = label
end

function PANEL:SetColor(color, bgFraction)
    self.itemColor = color
    if (bgFraction) then
        self.colorBGGradient = onyx.LerpColor(.05, colorSecondary, self.itemColor)
        self.itemColorBG = onyx.LerpColor(bgFraction, colorSecondary, onyx.CopyColor(self.itemColor))
    end
end

function PANEL:PerformLayout(w, h)
    local padding = self.padding
    local height = h - padding * 2
    local btnFavorite = self.btnFavorite

    self:DockPadding(padding, padding, padding, padding)
    self.mask = onyx.CalculateRoundedBox(8, 1, 1, w - 2, h - 2)

    self.iconContainer:Dock(LEFT)
    self.iconContainer:SetWide(height)
    self.iconContainer:DockMargin(0, 0, onyx.ScaleWide(10), 0)

    self.lblName:Dock(TOP)
    self.lblName:SetTall(height * .5)

    self.pnlDesc:Dock(FILL)

    if (IsValid(btnFavorite) and btnFavorite:IsVisible()) then
        btnFavorite:Dock(RIGHT)
        btnFavorite:SetZPos(-1)
        btnFavorite:SetWide(height)
    end
end

function PANEL:Paint(w, h)
    draw.RoundedBox(8, 0, 0, w, h, colorOutline)
    draw.RoundedBox(8, 1, 1, w - 2, h - 2, self.colorBG)

    if (self.gradientEnabled) then
        onyx.DrawWithPolyMask(self.mask, function()
            onyx.DrawMatGradient(0, 0, w, h, TOP, self.colorBGGradient)
        end)
    end
end

function PANEL:SetModel(modelPath)
    self.iconModel:SetModel(modelPath)
end

function PANEL:SetName(name)
    self.lblName:SetText(name)
end

local AXIS = {'x', 'y', 'z'}
function PANEL:PositionCamera(pos)
    local iconModel = self.iconModel

    if (not IsValid(iconModel)) then return end
    if (iconModel.ClassName ~= 'DModelPanel') then return end

    local ent = iconModel.Entity
    if (not IsValid(ent)) then return end

    if (pos == 'face') then
        local bone = ent:LookupBone('ValveBiped.Bip01_Head1')
        if (not bone) then return end

        local eyepos = ent:GetBonePosition(bone)
        eyepos:Add(Vector(0, 0, 2))

        iconModel:SetLookAt(eyepos)
        iconModel:SetCamPos(eyepos - Vector(-20, 0, 0))
        iconModel:SetFOV(45)

        ent:SetEyeTarget(eyepos - Vector(-20, 0, 0))
    elseif (pos == 'center') then
        local min, max = ent:GetRenderBounds()
        local center = (min + max) / 2
        local distance = 0

        for _, key in ipairs(AXIS) do
            distance = math.max(distance, max[key])
        end

        iconModel:SetLookAt(center)
        iconModel:SetFOV(distance + 10)
    end
end

function PANEL:AddFavoriteButton()
    self.btnFavorite = self:Add('onyx.ImageButton')
    self.btnFavorite.SetState = function(panel, state, ignore)
        panel.bState = state

        if (not ignore and self.objectIdentifier) then
            onyx.f4:SetFavorite(self.objectIdentifier, state)
        end

        local targetColor = state and colorFavoriteIconActive or colorFavoriteIconIdle

        if (state) then
            panel:SetWebImage('favorite_fill', 'smooth mips')
        else
            panel:SetWebImage('favorite_outline', 'smooth mips')
        end

        onyx.anim.Create(panel, .33, {
            index = onyx.anim.ANIM_HOVER,
            target = {
                m_colColor = targetColor
            }
        })

        self:Call('OnFavoriteStateSwitched', nil, state)
    end

    self.btnFavorite.m_Angle = 0
    self.btnFavorite.onyxEvents['OnCursorEntered'] = nil
    self.btnFavorite.onyxEvents['OnCursorExited'] = nil
    self.btnFavorite.onyxEvents['OnRelease'] = nil
    self.btnFavorite.onyxEvents['OnPress'] = nil
    self.btnFavorite:InstallRotationAnim()
    self.btnFavorite.m_iImageScale = .5
    self.btnFavorite.m_iImageScaleInitial = .5

    self.btnFavorite.DoClick = function(panel)
        panel:SetState(not panel.bState)
    end

    self.btnFavorite:SetState(onyx.f4:IsFavorite(self.objectIdentifier), true)
end

onyx.gui.Register('onyx.f4.Item', PANEL)

-- onyx.gui.Test('onyx.f4.Frame', .65, .65, function(panel)
--     panel:MakePopup()
--     panel:ChooseTab(3)
-- end)