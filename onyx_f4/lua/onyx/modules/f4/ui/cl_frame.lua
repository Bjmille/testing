--[[

Author: tochnonement
Email: tochnonement@gmail.com

25/12/2023

--]]

local colorPrimary = onyx:Config('colors.primary')
local colorTertiary = onyx:Config('colors.tertiary')
local wimgLoading = onyx.wimg.Simple('https://i.imgur.com/VVswRpx.png', 'smooth mips')
local lastChosenTab = 1

local L = function(...) return onyx.lang:Get(...) end

DEFINE_BASECLASS('onyx.Frame')

local PANEL = {}

function PANEL:Init()
    onyx.f4.frame = self

    local padding = onyx.ScaleTall(10)
    self.containerPadding = padding

    self.container = self:Add('Panel')
    self.container:DockPadding(padding, padding, padding, padding)

    self.sidebar = self:Add('onyx.Sidebar')
    self.sidebar:SetDescriptionEnabled(true)
    self.sidebar:SetContainer(self.container)
    self.sidebar:SetKeepTabContent(true)
    self:Combine(self.sidebar, 'ChooseTab')
    self.sidebar:On('OnTabSwitched', function(panel, tab)
        if (tab.data.class ~= 'HTML') then
            lastChosenTab = tab.tabIndex
        end
    end)

    self.profile = self:InitProfile()

    self:SetTitle(onyx.f4:GetOptionValue('title'))
    self:LoadTabs()
    self:ChooseTab(lastChosenTab)
    self.currentJob = LocalPlayer():Team()
end

function PANEL:PerformLayout(w, h)
    BaseClass.PerformLayout(self, w, h)

    self.sidebar:Dock(LEFT)
    self.sidebar:SetWide(w * .2)

    self.container:Dock(FILL)
end

function PANEL:InitProfile()
    local sidebar = self.sidebar
    local padding = onyx.ScaleTall(7.5)
    local client = LocalPlayer()

    local labelText = team.GetName(client:Team())
    local labelColor = onyx.f4.ConvertJobColor(team.GetColor(client:Team()))
    local labelFont = onyx.Font('Comfortaa@14')

    local profile = sidebar:Add('Panel')
    profile:SetTall(onyx.ScaleTall(50))
    profile:Dock(TOP)
    profile:DockMargin(0, 0, 0, onyx.ScaleTall(5))
    profile:DockPadding(padding, padding, padding, padding)
    profile.Paint = function(panel, w, h)
        draw.RoundedBox(8, 0, 0, w, h, colorTertiary)
        draw.RoundedBox(8, 1, 1, w - 2, h - 2, colorPrimary)
    end
    profile.Think = function(panel)
        if ((panel.nextThink or 0) > CurTime()) then return end
        panel.nextThink = CurTime() + .25

        local lblJob = panel.lblJob

        labelColor = onyx.f4.ConvertJobColor(team.GetColor(client:Team()))                                                                                                                                                                            -- 20e43b27-0afb-4386-887f-444008bf7ad7
        labelText = team.GetName(client:Team())

        if (IsValid(lblJob)) then
            lblJob:SetText(labelText)
        end
    end

    local avatar = profile:Add('onyx.RoundedAvatar')
    avatar:Dock(LEFT)
    avatar:SetWide(profile:GetTall() - padding * 2)
    avatar:SetPlayer(LocalPlayer(), 64)
    avatar:DockMargin(0, 0, onyx.ScaleWide(10), 0)
    avatar.PaintOver = function(panel, w, h)
        onyx.DrawOutlinedCircle(w * .5, h * .5, w * .5, 4, labelColor)
    end

    local lblTitle = profile:Add('onyx.Label')
    lblTitle:Dock(TOP)
    lblTitle:SetText(client:Name())
    lblTitle:Font('Comfortaa Bold@16')
    lblTitle:SetContentAlignment(4)

    local lblJob = profile:Add('onyx.Label')
    lblJob:Dock(FILL)
    lblJob:SetText(labelText)
    lblJob:SetTextColor(labelColor)
    lblJob:SetFont(labelFont)
    lblJob:SetContentAlignment(7)
    profile.lblJob = lblJob

    profile.PerformLayout = function(panel, w, h)
        lblTitle:SetTall((h - padding * 2) / 2)
    end

    return profile
end

do
    local LINKS = {
        {
            name = 'discord_url',
            desc = 'f4.discord_url.desc',
            icon = 'https://i.imgur.com/tYNtgoR.png'
        },
        {
            name = 'forum_url',
            desc = 'f4.forum_url.desc',
            icon = 'https://i.imgur.com/RH3sx4q.png'
        },
        {
            name = 'steam_url',
            desc = 'f4.steam_url.desc',
            icon = 'https://i.imgur.com/jB5T1Wo.png'
        },
        {
            name = 'rules_url',
            desc = 'f4.rules_url.desc',
            icon = 'https://i.imgur.com/JFhx1xW.png'
        },
        {
            name = 'donate_url',
            icon = 'https://i.imgur.com/MrgKOkL.png',
            desc = 'f4_donate_desc',
            donate = true
        },
    }

    function PANEL:LoadTabs()
        local tabs = onyx.f4:GetSortedTabs()
        local hideDonateTab = onyx.f4:GetOptionValue('hide_donate_tab')
        local donateTabAdded = false

        for _, tab in ipairs(tabs) do
            self.sidebar:AddTab({
                name = L(tab.name),
                desc = L(tab.desc),
                icon = tab.icon,
                class = tab.class,
                onClick = tab.onClick
            })
        end

        if (onyx.creditstore and not hideDonateTab) then
            local colorGold = Color(255, 225, 106)
            local colorGoldDesc = Color(157, 143, 84)

            self.sidebar:AddTab({
                name = onyx.lang:Get('f4_donate_u'),
                desc = onyx.lang:Get('f4_donate_desc'),
                wimg = 'creditstore_currency',
                nameColor = colorGold,
                descColor = colorGoldDesc,
                iconColor = colorGold,
                onClick = function()
                    RunConsoleCommand('onyx_store_open')
                    self:Close()
                    return false
                end
            })

            donateTabAdded = true
        end

        local allowedLinks = {}
        for _, link in ipairs(LINKS) do
            local url = onyx.f4:GetOptionValue(link.name):Trim()
            if (link.donate and donateTabAdded) then continue end

            if (url ~= '') then
                table.insert(allowedLinks, link)
            end
        end

        if (#allowedLinks > 0) then
            local spacer = self.sidebar:Add('Panel')
            spacer:Dock(TOP)
            spacer:SetTall(1)
            spacer:DockMargin(0, 0, 0, onyx.ScaleTall(5))
            spacer.Paint = function(panel, w, h)
                surface.SetDrawColor(0, 0, 0, 50)
                surface.DrawRect(0, 0, w, h)
            end
        end

        for _, link in ipairs(allowedLinks) do
            local option = onyx.inconfig.options['f4_' .. link.name]
            local name = L(option.title)
            local url = onyx.f4:GetOptionValue(link.name):Trim()

            self.sidebar:AddTab({
                name = name:upper(),
                desc = (link.desc and L(link.desc) or ''),
                icon = link.icon,
                wimg = link.wimg,
                class = 'HTML',
                onSelected = function(content)
                    content:OpenURL(url)
                    content.OnBeginLoadingDocument = function(panel)
                        if (not panel.bLoaded) then
                            panel.bLoading = true
                        end
                    end
                    content.OnFinishLoadingDocument = function(panel)
                        panel.bLoading = nil
                        panel.bLoaded = true
                    end
                    content.PaintOver = function(panel, w, h)
                        if (panel.bLoading) then
                            local maxSize = onyx.ScaleTall(64)
                            local size = maxSize * .5 + maxSize * .5 * math.abs(math.sin(CurTime()))

                            wimgLoading:DrawRotated(w * .5, h * .5, size, size, (CurTime() * 100) % 360)
                        end
                    end
                end,
                onClick = function()
                    if ( not onyx.f4:GetOptionValue('website_ingame') or url:find( 'discord.gg/' ) ) then
                        gui.OpenURL(url)
                        self:Close()
                        return false
                    end
                
                    return true
                end
            })
        end

        CAMI.PlayerHasAccess(LocalPlayer(), 'onyx_f4_edit', function(bAllowed)
            if (not bAllowed) then return end
            self.sidebar:AddTab({
                name = L('f4_admin_u'),
                desc = L('f4_admin_desc'),
                icon = 'https://i.imgur.com/l4M12dO.png',
                onClick = function()
                    onyx.f4.OpenAdminSettings()
                    self:Remove()
                    return false
                end
            })
        end)
    end
end

function PANEL:Think()
    if (self.currentJob ~= LocalPlayer():Team() and not self.jobRemoveCalled) then
        self:Remove()
        self.jobRemoveCalled = true
    end

    local keyName = input.LookupBinding('gm_showspare2', true)
    if (keyName) then
        local keyIndex = input.GetKeyCode(keyName)
        if (keyIndex and keyIndex > 0) then
            local keyDown = input.IsKeyDown(keyIndex)

            if (self.keyDown == nil) then
                self.keyDown = keyDown
            elseif (self.keyDown ~= keyDown) then
                self.keyDown = keyDown
                if (keyDown) then
                    self:Remove()
                end
            end
        end
    end
end

onyx.gui.Register('onyx.f4.Frame', PANEL, 'onyx.Frame')

--[[------------------------------
DEBUG
--------------------------------]]
-- onyx.gui.Test('onyx.f4.Frame', .65, .65, function(panel)
--     panel:MakePopup()
-- end)