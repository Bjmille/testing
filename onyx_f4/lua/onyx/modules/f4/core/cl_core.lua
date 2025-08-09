--[[

Author: tochnonement
Email: tochnonement@gmail.com

25/12/2023

--]]

onyx.f4.tabs = onyx.f4.tabs or {}
onyx.f4.actions = onyx.f4.actions or {}
onyx.f4.ranks = onyx.f4.ranks or {}

onyx.wimg.Register('favorite_fill', 'https://i.imgur.com/wviPFMQ.png')
onyx.wimg.Register('favorite_outline', 'https://i.imgur.com/FCXcBsu.png')

function onyx.f4:RegisterTab(id, data)
    onyx.AssertType(id, 'string', 'RegisterTab', 1)
    onyx.AssertType(data, 'table', 'RegisterTab', 2)

    data.id = id
    data.order = data.order or 99
    self.tabs[id] = data
end

function onyx.f4:DefineRank(id, data)
    onyx.AssertType(id, 'string', 'DefineRank', 1)
    onyx.AssertType(data, 'table', 'DefineRank', 2)
    assert(isstring(data.name), 'missing <name> field in data for `DefineRank`')

    data.id = id
    self.ranks[id] = data
end

function onyx.f4:RegisterAction(data)
    onyx.AssertType(data, 'table', 'RegisterAction', 1)

    table.insert(self.actions, data)
end

function onyx.f4.IsAdmin(ply)
    local jobOnly = onyx.f4:GetOptionValue('admin_on_duty')
    local jobName = onyx.f4:GetOptionValue('admin_on_duty_job')
    if (jobOnly) then
        local userGroup = ply:GetUserGroup()
        local jobTable = RPExtraTeams[ply:Team()]
        if (jobTable and userGroup ~= 'user' and jobTable.name == jobName) then
            return true
        else
            return false
        end
    else
        return (ply:IsAdmin() or onyx.f4.ranks[ply:GetUserGroup()])
    end
end

function onyx.f4:GetSortedTabs()
    local sorted = {}

    for id, tab in pairs(onyx.f4.tabs) do
        table.insert(sorted, tab)
    end

    table.sort(sorted, function(a, b)
        return a.order < b.order
    end)

    return sorted
end

function onyx.f4.ConvertJobColor(color)
    local bEnabled = onyx.f4:GetOptionValue('edit_job_colors')
    if (bEnabled) then
        local h, s, v = ColorToHSV(color)
        return onyx.ColorEditHSV(color, nil, s - .2, v + .2)
    else
        return color
    end
end

function onyx.f4.OpenFrame()
    local scrH = ScrH()
    local height = scrH * .65
    local halfHeight = height * .5
    
    local frame = vgui.Create('onyx.f4.Frame')
    frame:SetSize(ScrW() * .65, height)
    frame:MakePopup()
    frame:SetAlpha(0)
    
    local x0 = ScrW() * .5 - frame:GetWide() * .5

    frame:SetPos(x0, scrH - halfHeight)
    frame.anim = 0

    onyx.anim.Create(frame, .2, {
        easing = 'outQuad',
        index = 1,
        target = {anim = 1},
        think = function(_, panel)
            panel:SetAlpha(panel.anim * 255)
            panel:SetPos(x0, Lerp(panel.anim, scrH - halfHeight, scrH * .5 - halfHeight))
        end
    })

    return frame
end

function onyx.f4.OpenAdminSettings()
    local frame = vgui.Create('onyx.Frame')
    frame:SetSize(ScrW() * .66, ScrH() * .66)
    frame:Center()
    frame:MakePopup()
    frame:SetTitle('ONYX F4 (ADMIN)')

    local p = onyx.ScaleTall(15)
    local content = frame:Add('Panel')
    content:Dock(FILL)
    content:DockPadding(p, p, p, p)

    local sidebar = frame:Add('onyx.Sidebar')
    sidebar:SetContainer(content)
    sidebar:SetWide(frame:GetWide() * .2)
    sidebar:Dock(LEFT)

    sidebar:AddTab({
        name = onyx.lang:Get('addon_settings_u'),
        desc = onyx.lang:Get('addon_settings_desc'),
        icon = 'https://i.imgur.com/ECLKU9s.png',
        class = 'onyx.Configuration',
        onSelected = function(panel)
            panel:LoadAddonSettings('f4')
            panel:OpenCategories()
        end
    })

    sidebar:AddTab({
        name = onyx.lang:Get('addon_stats_u'),
        desc = onyx.lang:Get('addon_stats_desc'),
        icon = 'https://i.imgur.com/L6jCQe0.png',
        class = 'onyx.f4.AdminStats'
    })

    sidebar:AddTab({
        name = onyx.lang:Get('addon_return_u'),
        desc = onyx.lang:Get('addon_return_desc'),
        icon = 'https://i.imgur.com/gCI6kX5.png',
        onClick = function()
            onyx.f4.OpenFrame()
            frame:Remove()
            return false
        end
    })

    sidebar:ChooseTab(1)

    return frame
end

hook.Add('ShowSpare2', 'onyx.f4', function(ply)
    if (not IsValid(onyx.f4.frame)) then
        onyx.f4.OpenFrame()
    end
    return true
end)