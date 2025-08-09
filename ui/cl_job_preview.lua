--[[

Author: tochnonement
Email: tochnonement@gmail.com

30/12/2023

--]]

local colorPrimary = onyx:Config('colors.primary')
local colorSecondary = onyx:Config('colors.secondary')
local colorAccent = onyx:Config('colors.accent')
local colorTertiary = onyx:Config('colors.tertiary')
local colorLine = Color(75, 75, 75)
local colorBG = onyx.OffsetColor(colorPrimary, -3)
local colorFavoriteIconIdle = Color(235, 235, 235)
local colorFavoriteIconActive = Color(255, 241, 93)
local COLOR_NEGATIVE = Color(221, 107, 107)
local COLOR_LABEL = Color(161, 161, 161)

local ANIMATIONS = {
    'pose_standing_01',
    'pose_standing_02',
    -- 'pose_standing_03',
    'pose_standing_04'
}

local L = function(...) return onyx.lang:Get(...) end

local function generateDescHTML(desc)
    -- white-space: pre-wrap -- supports /t aswell
    local size = onyx.ScaleTall(12)
    local html = [[
        <head>
            <meta charset="UTF-8">
            <style>
                @import url('https://fonts.googleapis.com/css2?family=Comfortaa&family=Overpass:wght@400;600&display=swap');
                body {
                    color: white;
                    font-family: 'Comfortaa';
                    font-size: %dpx;
                    opacity: 0.999;
                    padding: 0;
                    margin: 0;
                    white-space: pre-line;
                    scroll-margin: 20px;
                    line-height: 1.5;
                }

                li {
                    line-height: 5px;
                }

                img {
                    text-align: center;
                    vertical-align: middle;
                    width: 24px;
                    height: 24px;
                }

                /* width */
                ::-webkit-scrollbar {
                    width: 4px;
                }

                /* Track */
                ::-webkit-scrollbar-track {
                    background: rgba(0, 0, 0, 0.1);
                    border-radius: 5px;
                }

                /* Handle */
                ::-webkit-scrollbar-thumb {
                    background: ]] .. onyx.ColorToHex(colorAccent) .. [[;
                    border-radius: 5px;
                }

                /* Handle on hover */
                ::-webkit-scrollbar-thumb:hover {
                    background: ]] .. onyx.ColorToHex(onyx.OffsetColor(colorAccent, -30)) .. [[;
                }
            </style>
        </head>
        <body>
            %s
        </body>
    ]]
    return string.format(html, size, desc)
end

local PANEL = {}

function PANEL:Init()
    self.colorSlightGradient = colorTertiary

    self.divInfo = self:Add('Panel')

    self.divModel = self:Add('Panel')

    self.iconModel = self.divModel:Add('DModelPanel')
    self.iconModel:Dock(FILL)
    self.iconModel:SetCursor('arrow')
    self.iconModel.LayoutEntity = function(panel, ent) end
    self.iconModel.slots = {}
    self.iconModel.PerformLayout = function(panel, w, h)
        local children = panel.slots
        local amount = #children
        local columns = 2
        local rows = math.ceil(amount / columns)
        local size = onyx.ScaleTall(36)
        local padding = onyx.ScaleTall(10)
        local space = onyx.ScaleTall(5)
        local X = w - size * columns - padding - space
        local Y = h - size * rows - padding - space * (rows - 1)

        local x = X
        for index = 1, amount do
            local button = children[index]

            button:SetSize(size, size)
            button:SetPos(x, Y)

            if (index % columns == 0) then
                x = X
                Y = Y + size + space
            else
                x = x + size + space
            end
        end
    end

    self.lblName = self.divInfo:Add('onyx.Label')
    self.lblName:Font('Comfortaa Bold@20')
    self.lblName:SetWrap(true)
    self.lblName:SetTextColor(color_white)
    self.lblName:SetAutoStretchVertical(true)
    self.lblName:Dock(TOP)

    self.lblSalary = self.divInfo:Add('onyx.Label')
    self.lblSalary:Font('Comfortaa Bold@16')
    self.lblSalary:SetTextColor(COLOR_LABEL)
    self.lblSalary:Dock(TOP)
    self.lblSalary:DockMargin(0, 0, 0, onyx.ScaleTall(20))

    self.navbar = self.divInfo:Add('onyx.Navbar')
    self.navbar:Dock(TOP)
    self.navbar:SetTall(onyx.ScaleTall(35))
    self.navbar:DockMargin(0, 0, 0, onyx.ScaleTall(5))
    self.navbar:SetSpace(onyx.ScaleWide(15))
    self.navbar.Paint = function(panel, w, h)
        local x1 = -self.padding
        local w1 = w + self.padding * 2

        local parent = self:GetParent()
        local x, y = parent:LocalToScreen(0, 0)
        local realW, realH = parent:GetSize()

        DisableClipping(true)
            render.SetScissorRect(x, y, x + realW, y + realH, true)
                surface.SetDrawColor(colorLine)
                surface.DrawRect(x1, h - 1, w1, 1)
            render.SetScissorRect(0, 0, 0, 0, false)
        DisableClipping(false)
    end
    self.navbar.OnTabAdded = function(panel, tab)
        tab:SizeToContents()
        tab:SetFont(onyx.Font('Comfortaa Bold@14'))
    end

    self.navbarContent = self.divInfo:Add('Panel')
    self.navbarContent:Dock(FILL)

    self.navbar:SetKeepTabContent(true)
    self.navbar:SetContainer(self.navbarContent)

    self.footer = self.divInfo:Add('Panel')
    self.footer:Dock(BOTTOM)
    self.footer:SetTall(onyx.ScaleTall(30))

    self.btnChoose = self.footer:Add('onyx.Button')
    self.btnChoose:SetText(L('f4_become_u'))
    self.btnChoose:SetGradientColor(onyx.OffsetColor(colorAccent, -50))
    self.btnChoose:SetMasking(true)
    self.btnChoose:Font('Comfortaa Bold@16')
    self.btnChoose:Dock(FILL)

    self.btnFavorite = self.footer:Add('onyx.ImageButton')
    self.btnFavorite:Dock(RIGHT)
    self.btnFavorite:SetWide(self.footer:GetTall( ))
    self.btnFavorite:DockMargin(onyx.ScaleTall(10), 0, 0, 0)
    self.btnFavorite.SetState = function(panel, state, ignore)
        panel.bState = state

        if (not ignore) then
            onyx.f4:SetFavorite(self.teamCommand, state)
            self:Call('OnFavoriteStateSwitched', nil, self.teamCommand, state)
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
    end

    self.btnFavorite.m_Angle = 0
    self.btnFavorite.onyxEvents['OnCursorEntered'] = nil
    self.btnFavorite.onyxEvents['OnCursorExited'] = nil
    self.btnFavorite.onyxEvents['OnRelease'] = nil
    self.btnFavorite.onyxEvents['OnPress'] = nil
    self.btnFavorite:InstallRotationAnim()
    self.btnFavorite.m_iImageScale = 1
    self.btnFavorite.m_iImageScaleInitial = 1

    self.btnFavorite.DoClick = function(panel)
        panel:SetState(not panel.bState)
    end

    self.spacer = self.divInfo:Add('Panel')
    self.spacer:Dock(BOTTOM)
    self.spacer:DockMargin(0, onyx.ScaleTall(10), 0, onyx.ScaleTall(5))
    self.spacer.Paint = function(panel, w, h)
        local x1 = -self.padding
        local w1 = w + self.padding * 2

        local parent = self:GetParent()
        local x, y = parent:LocalToScreen(0, 0)
        local realW, realH = parent:GetSize()

        DisableClipping(true)
            render.SetScissorRect(x, y, x + realW, y + realH, true)
                surface.SetDrawColor(colorLine)
                surface.DrawRect(x1, h * .5, w1, 1)
            render.SetScissorRect(0, 0, 0, 0, false)
        DisableClipping(false)
    end

    self.navbar:AddTab({
        name = L('f4_description_u'),
        class = 'DHTML',
        onBuild = function(content)
            content:SetHTML(generateDescHTML(''))
        end
    })

    self.navbar:AddTab({
        name = L('f4_weapons_u'),
        class = 'onyx.ScrollPanel'
    })
end

function PANEL:SetupJob(job)
    local models = job.model
    local multipleModels = istable(models) and #models > 1
    local defaultModel = istable(models) and models[1] or models
    local chosenIndex = 1
    local desc = job.description:Trim()
    local weaponsList = job.weapons or {}
    local teamIndex = job.team
    local level = job.level

    if (multipleModels) then
        local preferredModel = DarkRP.getPreferredJobModel(job.team)
        if (preferredModel) then
            local preferredIndex
            for index, model in ipairs(models) do
                if (model == preferredModel) then
                    preferredIndex = index
                    break
                end
            end
        
            if ( preferredIndex ) then
                defaultModel = preferredModel
                chosenIndex = preferredIndex
            end
        end
    end

    local navbar = self.navbar
    local tabs = navbar.tabs
    local descTab = tabs[1]
    local weaponsTab = tabs[2]
    local btnChoose = self.btnChoose

    self.teamIndex = teamIndex
    self.teamCommand = job.command
    self.teamData = job

    self.btnFavorite:SetState(onyx.f4:IsFavorite(job.command), true)

    if (job.vote or job.RequiresVote and job.RequiresVote(LocalPlayer(), job.team)) then
        btnChoose:SetText(L('f4_create_vote_u'))
        btnChoose.DoClick = function(panel)
            DarkRP.setPreferredJobModel(teamIndex, self.chosenModelPath)
            RunConsoleCommand('darkrp', 'vote' .. self.teamCommand)
        end
    else
        btnChoose:SetText(L('f4_become_u'))
        btnChoose.DoClick = function(panel)
            DarkRP.setPreferredJobModel(teamIndex, self.chosenModelPath)
            RunConsoleCommand('darkrp', self.teamCommand)
        end
    end

    self.lblName:SetText(onyx.utf8.upper(job.name))

    if (level and onyx.f4.GetPlayerLevel(LocalPlayer(), math.huge) < level) then
        self.lblSalary:SetText(L('requires_level', {level = string.Comma(level)}))
        self.lblSalary:SetTextColor(COLOR_NEGATIVE)
        self.hideButton = true
    else
        self.lblSalary:SetText(L('f4_salary') .. ': ' .. DarkRP.formatMoney(job.salary))
        self.lblSalary:SetTextColor(COLOR_LABEL)
        self.hideButton = false
    end

    self.colorSlightGradient = onyx.LerpColor(.1, colorSecondary, job.color)

    self.iconModel:SetModel(defaultModel)
    self.iconModel:SetCamPos(Vector(80, 0, 50))
    self.iconModel:SetFOV(30)

    self.chosenModelPath = defaultModel

    local ent = self.iconModel.Entity
    if (IsValid(ent) ) then
        local animID = ent:LookupSequence(ANIMATIONS[math.random(#ANIMATIONS)])
        if (animID >= 0) then
            ent:SetSequence(animID)
            ent:SetEyeTarget(self.iconModel:GetCamPos())
        end
    end

    self.iconModel:Clear()
    self.iconModel.slots = {}

    if (multipleModels) then
        local oldActiveModel
        for index, model in ipairs(models) do
            if (index > 14) then break end

            local button = self.iconModel:Add('DButton')
            button:SetText('')
            button:SetAlpha(defaultModel == model and 255 or 100)
            button.active = index == chosenIndex
            button.PerformLayout = function(panel, w, h)
                panel.mask = onyx.CalculateCircle(w * .5, h * .5, h * .5 - 2, 16)
            end
            button.Paint = function(panel, w, h)
                local child = panel:GetChild(0)

                onyx.DrawCircle(w * .5, h * .5, h * .5, colorSecondary)

                if (IsValid(child)) then
                    onyx.DrawWithPolyMask(panel.mask, function()
                        child:PaintManual()
                    end)
                end

                onyx.DrawOutlinedCircle(w * .5, h * .5, h * .5, 3, panel.active and colorAccent or color_white)
            end
            button.DoClick = function(panel)
                if (oldActiveModel) then
                    oldActiveModel.active = false
                    oldActiveModel:SetAlpha(100)
                end

                self.iconModel:SetModel(model)

                panel:SetAlpha(255)
                panel.active = true

                oldActiveModel = panel

                self.chosenModelPath = model
            end

            if (index == chosenIndex) then
                oldActiveModel = button
            end

            local modelicon = button:Add('SpawnIcon')
            modelicon:Dock(FILL)
            modelicon:SetModel(model)
            modelicon:SetMouseInputEnabled(false)
            modelicon:SetPaintedManually(true)

            table.insert(self.iconModel.slots, button)
        end
    end

    navbar:SelectTab(descTab, true)

    if (IsValid(descTab.content)) then
        desc = desc:gsub('\t', '')
        desc = string.JavascriptSafe(desc)

        descTab.content:QueueJavascript([[
            document.body.innerHTML = ']] .. desc .. [[';
        ]])
    end

    weaponsTab:SetVisible(#weaponsList > 0)
    weaponsTab.tabData.onBuild = function(content)
        for _, class in ipairs(weaponsList) do
            local swepTable = weapons.Get(class)
            local name
            if (swepTable) then
                name = language.GetPhrase(swepTable.PrintName)
            else
                name = language.GetPhrase(class)
            end

            local panel = content:Add('onyx.Label')
            panel:Dock(TOP)
            panel:SetText(name)
            panel:SetTall(onyx.ScaleTall(30))
            panel:SetContentAlignment(5)
            panel:SetFont(onyx.Font('Comfortaa Bold@16'))
            panel.Paint = function(this, w, h)
                draw.RoundedBox(8, 0, 0, w, h, colorPrimary)
                draw.RoundedBox(8, 1, 1, w - 2, h - 2, colorTertiary)
            end
        end
    end

    if (IsValid(weaponsTab.content)) then
        weaponsTab.content:Remove()
    end
end

function PANEL:PerformLayout(w, h)
    local padding = onyx.ScaleTall(15)
    self.padding = padding

    self.divInfo:Dock(FILL)
    self.divInfo:DockPadding(padding, padding, padding, onyx.ScaleTall(5))

    self.divModel:Dock(RIGHT)
    self.divModel:SetWide(w * .5)
end

function PANEL:Paint(w, h)
    local x, y = self:LocalToScreen(0, 0)

    local frame = onyx.f4.frame
    if (not IsValid(frame)) then return end -- just in case

    local realX, realY = frame.container:LocalToScreen(0, 0)
    local realW, realH = frame.container:GetSize()
    local padding = frame.containerPadding

    local divModel = self.divModel
    local Y = -padding
    local H = h + padding * 2
    local W = w + padding

    if (self.enabled) then
        onyx.bshadows.BeginShadow()
            surface.SetDrawColor(colorSecondary)
            surface.DrawRect(x, y, w, h)
        onyx.bshadows.EndShadow(1, 2, 2, nil, 90, 2, true)
    end

    DisableClipping(true)
        render.SetScissorRect(realX, realY, realX + realW, realY + realH, true)
            draw.RoundedBoxEx(8, 0, Y, W, H, colorSecondary, false, false, false, true)

            draw.RoundedBoxEx(8, divModel:GetPos(), Y, divModel:GetWide() + padding, H, colorBG, false, false, false, true)

            onyx.DrawMatGradient(0, Y, self.divInfo:GetWide(), H * .5, BOTTOM, self.colorSlightGradient)
        render.SetScissorRect(0, 0, 0, 0, false)
    DisableClipping(false)
end

onyx.gui.Register('onyx.f4.JobPreview', PANEL)