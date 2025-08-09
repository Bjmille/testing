-- Enhanced SCPXP Menu System
-- Place this in: addons/scprp_experience_system/lua/autorun/client/scpxp_enhanced_menu.lua

if not CLIENT then return end

SCPXP = SCPXP or {}
SCPXP.UI = SCPXP.UI or {}

-- Enhanced color scheme
SCPXP.UI.Colors = {
    -- Dark theme colors
    Background = Color(25, 25, 30, 245),
    Panel = Color(35, 35, 40, 230),
    Accent = Color(45, 45, 55, 200),
    Primary = Color(74, 144, 226),
    Success = Color(46, 204, 113),
    Warning = Color(230, 126, 34),
    Danger = Color(231, 76, 60),
    Info = Color(52, 152, 219),
    Text = Color(255, 255, 255),
    TextSecondary = Color(180, 180, 185),
    TextMuted = Color(120, 120, 125),
    Border = Color(60, 60, 70),
    Hover = Color(55, 55, 65),
    
    -- Category specific colors
    Research = Color(52, 152, 219),
    Security = Color(231, 76, 60),
    DClass = Color(230, 126, 34),
    SCP = Color(155, 89, 182)
}

-- Animation helper
function SCPXP.UI:AnimatePanel(panel, property, targetValue, duration, easing)
    if not IsValid(panel) then return end
    
    local startValue = panel[property] or 0
    local startTime = CurTime()
    
    local function animate()
        if not IsValid(panel) then return end
        
        local elapsed = CurTime() - startTime
        local progress = math.Clamp(elapsed / duration, 0, 1)
        
        -- Easing function
        if easing == "ease_out" then
            progress = 1 - math.pow(1 - progress, 3)
        elseif easing == "ease_in_out" then
            progress = progress < 0.5 and 2 * progress * progress or 1 - math.pow(-2 * progress + 2, 3) / 2
        end
        
        local currentValue = startValue + (targetValue - startValue) * progress
        panel[property] = currentValue
        
        if progress < 1 then
            timer.Simple(0.01, animate)
        end
    end
    
    animate()
end

-- Create modern button
function SCPXP.UI:CreateButton(parent, text, x, y, w, h, color, callback)
    local btn = vgui.Create("DButton", parent)
    btn:SetPos(x, y)
    btn:SetSize(w, h)
    btn:SetText("")
    btn.hoverAlpha = 0
    btn.clickAlpha = 0
    
    btn.Paint = function(self, width, height)
        local bgColor = ColorAlpha(color, 200 + self.hoverAlpha * 55)
        local borderColor = ColorAlpha(color, 255)
        
        -- Background with rounded corners
        draw.RoundedBox(8, 0, 0, width, height, bgColor)
        
        -- Border
        draw.RoundedBox(8, 0, 0, width, height, Color(0, 0, 0, 0))
        surface.SetDrawColor(borderColor)
        surface.DrawOutlinedRect(0, 0, width, height)
        
        -- Glow effect when hovered
        if self.hoverAlpha > 0 then
            draw.RoundedBox(8, -2, -2, width + 4, height + 4, ColorAlpha(color, self.hoverAlpha * 30))
        end
        
        -- Text
        draw.SimpleText(text, "DermaDefaultBold", width/2, height/2, 
            Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    btn.OnCursorEntered = function(self)
        self:LerpHover(true)
        surface.PlaySound("ui/buttonrollover.wav")
    end
    
    btn.OnCursorExited = function(self)
        self:LerpHover(false)
    end
    
    btn.OnMousePressed = function(self)
        self.clickAlpha = 100
        surface.PlaySound("ui/buttonclick.wav")
        if callback then callback() end
    end
    
    btn.LerpHover = function(self, hovered)
        local target = hovered and 100 or 0
        SCPXP.UI:AnimatePanel(self, "hoverAlpha", target, 0.2, "ease_out")
    end
    
    -- Fade out click effect
    btn.Think = function(self)
        if self.clickAlpha > 0 then
            self.clickAlpha = math.max(0, self.clickAlpha - 300 * FrameTime())
        end
    end
    
    return btn
end

-- Create progress bar with animation
function SCPXP.UI:CreateProgressBar(parent, x, y, w, h, progress, color, label)
    local bar = vgui.Create("DPanel", parent)
    bar:SetPos(x, y)
    bar:SetSize(w, h)
    bar.progress = 0
    bar.targetProgress = progress
    bar.animatedProgress = 0
    
    bar.Paint = function(self, width, height)
        -- Background
        draw.RoundedBox(4, 0, 0, width, height, SCPXP.UI.Colors.Accent)
        
        -- Progress fill with gradient
        if self.animatedProgress > 0 then
            local fillWidth = width * (self.animatedProgress / 100)
            draw.RoundedBox(4, 0, 0, fillWidth, height, color)
            
            -- Shine effect
            local shineWidth = 30
            local shinePos = (fillWidth - shineWidth) * (math.sin(CurTime() * 2) * 0.5 + 0.5)
            if fillWidth > shineWidth then
                draw.RoundedBox(4, shinePos, 0, shineWidth, height, ColorAlpha(Color(255, 255, 255), 50))
            end
        end
        
        -- Border
        surface.SetDrawColor(SCPXP.UI.Colors.Border)
        surface.DrawOutlinedRect(0, 0, width, height)
        
        -- Label
        if label then
            draw.SimpleText(label, "DermaDefault", width/2, height/2, 
                SCPXP.UI.Colors.Text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
    
    -- Animate progress
    bar.SetProgress = function(self, newProgress)
        self.targetProgress = newProgress
        SCPXP.UI:AnimatePanel(self, "animatedProgress", newProgress, 1.0, "ease_out")
    end
    
    -- Initial animation
    timer.Simple(0.1, function()
        if IsValid(bar) then
            bar:SetProgress(progress)
        end
    end)
    
    return bar
end

-- Create stat card
function SCPXP.UI:CreateStatCard(parent, x, y, w, h, category, data)
    local card = vgui.Create("DPanel", parent)
    card:SetPos(x, y)
    card:SetSize(w, h)
    card.hoverAlpha = 0
    
    local categoryInfo = SCPXP.Config.Categories[category]
    local categoryColor = categoryInfo.color or SCPXP.UI.Colors.Primary
    
    card.Paint = function(self, width, height)
        local bgColor = ColorAlpha(SCPXP.UI.Colors.Panel, 230 + self.hoverAlpha * 25)
        
        -- Background
        draw.RoundedBox(12, 0, 0, width, height, bgColor)
        
        -- Accent line
        draw.RoundedBox(12, 0, 0, 6, height, categoryColor)
        
        -- Hover glow
        if self.hoverAlpha > 0 then
            draw.RoundedBox(12, -2, -2, width + 4, height + 4, 
                ColorAlpha(categoryColor, self.hoverAlpha * 20))
        end
        
        -- Border
        surface.SetDrawColor(ColorAlpha(SCPXP.UI.Colors.Border, 150))
        surface.DrawOutlinedRect(0, 0, width, height)
    end
    
    card.OnCursorEntered = function(self)
        SCPXP.UI:AnimatePanel(self, "hoverAlpha", 100, 0.3, "ease_out")
    end
    
    card.OnCursorExited = function(self)
        SCPXP.UI:AnimatePanel(self, "hoverAlpha", 0, 0.3, "ease_out")
    end
    
    -- Category icon/name
    local nameLabel = vgui.Create("DLabel", card)
    nameLabel:SetPos(20, 15)
    nameLabel:SetSize(width - 40, 25)
    nameLabel:SetText(categoryInfo.name)
    nameLabel:SetTextColor(categoryColor)
    nameLabel:SetFont("DermaLarge")
    
    -- Level
    local levelLabel = vgui.Create("DLabel", card)
    levelLabel:SetPos(20, 45)
    levelLabel:SetSize(width - 40, 20)
    levelLabel:SetText(string.format("Level %d", data.level or 1))
    levelLabel:SetTextColor(SCPXP.UI.Colors.Text)
    levelLabel:SetFont("DermaDefaultBold")
    
    -- XP
    local xpLabel = vgui.Create("DLabel", card)
    xpLabel:SetPos(20, 65)
    xpLabel:SetSize(width - 40, 20)
    xpLabel:SetText(string.format("%s XP", string.Comma(data.totalXP or 0)))
    xpLabel:SetTextColor(SCPXP.UI.Colors.TextSecondary)
    xpLabel:SetFont("DermaDefault")
    
    -- Progress to next level
    local currentLevel = data.level or 1
    local currentXP = data.totalXP or 0
    local currentLevelXP = SCPXP:GetTotalXPForLevel(currentLevel)
    local nextLevelXP = SCPXP:GetTotalXPForLevel(currentLevel + 1)
    local progress = 0
    
    if nextLevelXP > currentLevelXP then
        progress = ((currentXP - currentLevelXP) / (nextLevelXP - currentLevelXP)) * 100
    end
    
    progress = math.Clamp(progress, 0, 100)
    
    local progressBar = SCPXP.UI:CreateProgressBar(card, 20, h - 35, w - 40, 20, 
        progress, categoryColor, string.format("%.1f%%", progress))
    
    -- Next level XP
    local nextLevelLabel = vgui.Create("DLabel", card)
    nextLevelLabel:SetPos(20, h - 50)
    nextLevelLabel:SetSize(width - 40, 15)
    nextLevelLabel:SetText(string.format("%s XP to level %d", 
        string.Comma(math.max(0, nextLevelXP - currentXP)), currentLevel + 1))
    nextLevelLabel:SetTextColor(SCPXP.UI.Colors.TextMuted)
    nextLevelLabel:SetFont("DermaDefault")
    
    return card
end

-- Create leaderboard entry
function SCPXP.UI:CreateLeaderboardEntry(parent, x, y, w, h, rank, playerName, level, xp, category)
    local entry = vgui.Create("DPanel", parent)
    entry:SetPos(x, y)
    entry:SetSize(w, h)
    entry.hoverAlpha = 0
    
    local categoryInfo = SCPXP.Config.Categories[category]
    local categoryColor = categoryInfo.color or SCPXP.UI.Colors.Primary
    
    entry.Paint = function(self, width, height)
        local bgColor = rank <= 3 and ColorAlpha(categoryColor, 30) or ColorAlpha(SCPXP.UI.Colors.Accent, 100)
        
        -- Background
        draw.RoundedBox(6, 0, 0, width, height, bgColor)
        
        -- Rank indicator for top 3
        if rank <= 3 then
            local rankColors = {Color(255, 215, 0), Color(192, 192, 192), Color(205, 127, 50)}
            draw.RoundedBox(6, 0, 0, 4, height, rankColors[rank])
        end
        
        -- Hover effect
        if self.hoverAlpha > 0 then
            draw.RoundedBox(6, 0, 0, width, height, ColorAlpha(Color(255, 255, 255), self.hoverAlpha * 10))
        end
    end
    
    entry.OnCursorEntered = function(self)
        SCPXP.UI:AnimatePanel(self, "hoverAlpha", 100, 0.2, "ease_out")
    end
    
    entry.OnCursorExited = function(self)
        SCPXP.UI:AnimatePanel(self, "hoverAlpha", 0, 0.2, "ease_out")
    end
    
    -- Rank
    local rankLabel = vgui.Create("DLabel", entry)
    rankLabel:SetPos(15, 5)
    rankLabel:SetSize(30, h - 10)
    rankLabel:SetText("#" .. rank)
    rankLabel:SetTextColor(rank <= 3 and Color(255, 215, 0) or SCPXP.UI.Colors.TextSecondary)
    rankLabel:SetFont("DermaDefaultBold")
    
    -- Player name
    local nameLabel = vgui.Create("DLabel", entry)
    nameLabel:SetPos(50, 5)
    nameLabel:SetSize(w - 200, h - 10)
    nameLabel:SetText(playerName)
    nameLabel:SetTextColor(SCPXP.UI.Colors.Text)
    nameLabel:SetFont("DermaDefault")
    
    -- Level
    local levelLabel = vgui.Create("DLabel", entry)
    levelLabel:SetPos(w - 150, 5)
    levelLabel:SetSize(60, h - 10)
    levelLabel:SetText("Lv. " .. level)
    levelLabel:SetTextColor(categoryColor)
    levelLabel:SetFont("DermaDefaultBold")
    
    -- XP
    local xpLabel = vgui.Create("DLabel", entry)
    xpLabel:SetPos(w - 90, 5)
    xpLabel:SetSize(80, h - 10)
    xpLabel:SetText(string.Comma(xp) .. " XP")
    xpLabel:SetTextColor(SCPXP.UI.Colors.TextSecondary)
    xpLabel:SetFont("DermaDefault")
    
    return entry
end

-- Main menu function
function SCPXP:OpenEnhancedMenu()
    if IsValid(self.EnhancedMenu) then
        self.EnhancedMenu:Close()
        return
    end
    
    -- Initialize PlayerData if it doesn't exist
    if not self.PlayerData then
        self.PlayerData = {}
        for categoryId, _ in pairs(self.Config.Categories) do
            self.PlayerData[categoryId] = {
                totalXP = 0,
                level = 1
            }
        end
    end
    
    local scrW, scrH = ScrW(), ScrH()
    
    -- Main frame
    local frame = vgui.Create("DFrame")
    frame:SetSize(1000, 650)
    frame:Center()
    frame:SetTitle("")
    frame:SetDeleteOnClose(true)
    frame:ShowCloseButton(false)
    frame:SetDraggable(true)
    frame:MakePopup()
    
    self.EnhancedMenu = frame
    
    frame.Paint = function(self, w, h)
        -- Background with gradient
        draw.RoundedBox(12, 0, 0, w, h, SCPXP.UI.Colors.Background)
        
        -- Header gradient
        local headerColor1 = ColorAlpha(SCPXP.UI.Colors.Primary, 200)
        local headerColor2 = ColorAlpha(SCPXP.UI.Colors.Primary, 50)
        
        -- Simple gradient simulation
        for i = 0, 80 do
            local alpha = 200 - (i * 2)
            draw.RoundedBox(12, 0, i, w, 1, ColorAlpha(SCPXP.UI.Colors.Primary, alpha))
        end
        
        -- Border
        surface.SetDrawColor(SCPXP.UI.Colors.Border)
        surface.DrawOutlinedRect(0, 0, w, h)
    end
    
    -- Header
    local header = vgui.Create("DPanel", frame)
    header:SetPos(0, 0)
    header:SetSize(1000, 80)
    header.Paint = function() end
    
    -- Title
    local title = vgui.Create("DLabel", header)
    title:SetPos(30, 20)
    title:SetSize(400, 40)
    title:SetText("SCP-RP Experience System")
    title:SetTextColor(Color(255, 255, 255))
    title:SetFont("DermaLarge")
    
    -- Subtitle
    local subtitle = vgui.Create("DLabel", header)
    subtitle:SetPos(30, 50)
    subtitle:SetSize(400, 20)
    subtitle:SetText("Track your progress across all departments")
    subtitle:SetTextColor(SCPXP.UI.Colors.TextSecondary)
    subtitle:SetFont("DermaDefault")
    
    -- Close button
    local closeBtn = vgui.Create("DButton", header)
    closeBtn:SetPos(940, 20)
    closeBtn:SetSize(40, 40)
    closeBtn:SetText("")
    
    closeBtn.Paint = function(self, w, h)
        local color = self:IsHovered() and SCPXP.UI.Colors.Danger or SCPXP.UI.Colors.TextMuted
        draw.RoundedBox(20, 0, 0, w, h, ColorAlpha(color, 100))
        draw.SimpleText("×", "DermaLarge", w/2, h/2 - 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    closeBtn.DoClick = function()
        frame:Close()
    end
    
    -- Tab system
    local tabContainer = vgui.Create("DPanel", frame)
    tabContainer:SetPos(20, 100)
    tabContainer:SetSize(960, 530)
    tabContainer.Paint = function() end
    
    -- Tab buttons
    local tabButtons = {}
    local tabPanels = {}
    local activeTab = 1
    
    local tabs = {
        {name = "Overview", icon = "📊"},
        {name = "Categories", icon = "📋"},
        {name = "Leaderboard", icon = "🏆"},
        {name = "Statistics", icon = "📈"}
    }
    
    -- Create tab buttons
    for i, tab in ipairs(tabs) do
        local btn = SCPXP.UI:CreateButton(tabContainer, tab.icon .. " " .. tab.name, 
            (i-1) * 160 + 10, 0, 150, 40, 
            i == activeTab and SCPXP.UI.Colors.Primary or SCPXP.UI.Colors.Accent,
            function()
                activeTab = i
                for j, tabBtn in ipairs(tabButtons) do
                    tabBtn.backgroundColor = j == i and SCPXP.UI.Colors.Primary or SCPXP.UI.Colors.Accent
                end
                for j, panel in ipairs(tabPanels) do
                    panel:SetVisible(j == i)
                end
            end)
        
        btn.backgroundColor = i == activeTab and SCPXP.UI.Colors.Primary or SCPXP.UI.Colors.Accent
        tabButtons[i] = btn
    end
    
    -- Tab content area
    local contentArea = vgui.Create("DPanel", tabContainer)
    contentArea:SetPos(0, 60)
    contentArea:SetSize(960, 470)
    contentArea.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, SCPXP.UI.Colors.Panel)
        surface.SetDrawColor(SCPXP.UI.Colors.Border)
        surface.DrawOutlinedRect(0, 0, w, h)
    end
    
    -- Overview Panel
    local overviewPanel = vgui.Create("DPanel", contentArea)
    overviewPanel:Dock(FILL)
    overviewPanel:SetVisible(true)
    overviewPanel.Paint = function() end
    tabPanels[1] = overviewPanel
    
    -- Player info section
    local playerInfo = vgui.Create("DPanel", overviewPanel)
    playerInfo:SetPos(20, 20)
    playerInfo:SetSize(920, 100)
    playerInfo.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, SCPXP.UI.Colors.Accent)
        surface.SetDrawColor(SCPXP.UI.Colors.Border)
        surface.DrawOutlinedRect(0, 0, w, h)
    end
    
    -- Player name and info
    local playerName = vgui.Create("DLabel", playerInfo)
    playerName:SetPos(20, 15)
    playerName:SetSize(400, 30)
    playerName:SetText("Player: " .. LocalPlayer():Nick())
    playerName:SetTextColor(SCPXP.UI.Colors.Text)
    playerName:SetFont("DermaLarge")
    
    -- Total stats
    local totalXP = 0
    local totalLevels = 0
    for category, data in pairs(SCPXP.PlayerData or {}) do
        totalXP = totalXP + (data.totalXP or 0)
        totalLevels = totalLevels + (data.level or 1)
    end
    
    local statsLabel = vgui.Create("DLabel", playerInfo)
    statsLabel:SetPos(20, 50)
    statsLabel:SetSize(400, 20)
    statsLabel:SetText(string.format("Total XP: %s | Combined Levels: %d", 
        string.Comma(totalXP), totalLevels))
    statsLabel:SetTextColor(SCPXP.UI.Colors.TextSecondary)
    statsLabel:SetFont("DermaDefault")
    
    -- Category cards
    local cardY = 140
    local cardIndex = 0
    
    for categoryId, categoryData in pairs(SCPXP.Config.Categories) do
        local playerData = SCPXP.PlayerData[categoryId] or {totalXP = 0, level = 1}
        local cardX = 20 + (cardIndex % 2) * 470
        
        if cardIndex % 2 == 0 and cardIndex > 0 then
            cardY = cardY + 160
        end
        
        local card = SCPXP.UI:CreateStatCard(overviewPanel, cardX, cardY, 450, 140, categoryId, playerData)
        
        cardIndex = cardIndex + 1
    end
    
    -- Categories Panel
    local categoriesPanel = vgui.Create("DScrollPanel", contentArea)
    categoriesPanel:Dock(FILL)
    categoriesPanel:SetVisible(false)
    tabPanels[2] = categoriesPanel
    
    -- Add detailed category information
    local categoryY = 20
    for categoryId, categoryData in pairs(SCPXP.Config.Categories) do
        local playerData = SCPXP.PlayerData[categoryId] or {totalXP = 0, level = 1}
        
        -- Category section
        local section = vgui.Create("DPanel", categoriesPanel)
        section:SetPos(20, categoryY)
        section:SetSize(900, 200)
        section.Paint = function(self, w, h)
            draw.RoundedBox(8, 0, 0, w, h, SCPXP.UI.Colors.Accent)
            surface.SetDrawColor(categoryData.color)
            surface.DrawOutlinedRect(0, 0, w, h)
        end
        
        -- Category details would go here...
        -- (Job requirements, XP sources, etc.)
        
        categoryY = categoryY + 220
    end
    
    -- Leaderboard Panel
    local leaderboardPanel = vgui.Create("DScrollPanel", contentArea)
    leaderboardPanel:Dock(FILL)
    leaderboardPanel:SetVisible(false)
    tabPanels[3] = leaderboardPanel
    
    -- Mock leaderboard data (you'd get this from server)
    local leaderboardData = {
        {name = "Player1", level = 25, xp = 15000, category = "research"},
        {name = "Player2", level = 22, xp = 12500, category = "security"},
        {name = "Player3", level = 20, xp = 11000, category = "research"},
        -- Add more entries...
    }
    
    for i, entry in ipairs(leaderboardData) do
        SCPXP.UI:CreateLeaderboardEntry(leaderboardPanel, 20, 20 + (i-1) * 50, 900, 40,
            i, entry.name, entry.level, entry.xp, entry.category)
    end
    
    -- Statistics Panel
    local statsPanel = vgui.Create("DPanel", contentArea)
    statsPanel:Dock(FILL)
    statsPanel:SetVisible(false)
    tabPanels[4] = statsPanel
    
    -- Add charts and detailed statistics here...
    
    surface.PlaySound("ui/buttonclick.wav")
end

-- Integration with Onyx F4 Menu
-- Add this to your Onyx F4 menu configuration

function SCPXP:IntegrateWithOnyxF4()
    -- Hook into Onyx F4 menu creation
    hook.Add("OnyxF4_AddTabs", "SCPXP_Integration", function(frame, tabContainer)
        -- Add SCPXP tab to Onyx F4
        local scpxpTab = vgui.Create("DButton", tabContainer)
        scpxpTab:SetText("📊 Experience")
        scpxpTab:SetSize(120, 40)
        scpxpTab.DoClick = function()
            SCPXP:OpenEnhancedMenu()
            if IsValid(frame) then
                frame:Close() -- Close F4 menu when opening SCPXP menu
            end
        end
        
        -- Style the button to match Onyx theme
        scpxpTab.Paint = function(self, w, h)
            local color = self:IsHovered() and SCPXP.UI.Colors.Primary or SCPXP.UI.Colors.Accent
            draw.RoundedBox(6, 0, 0, w, h, color)
            draw.SimpleText("📊 Experience", "DermaDefaultBold", w/2, h/2, 
                Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        return scpxpTab
    end)
    
    -- Alternative: Add to existing tabs
    hook.Add("OnyxF4_PopulateTab", "SCPXP_AddToTab", function(tabName, tabPanel)
        if tabName == "Settings" or tabName == "Information" then
            local btn = SCPXP.UI:CreateButton(tabPanel, "📊 Open Experience Menu", 
                20, 200, 200, 40, SCPXP.UI.Colors.Primary,
                function()
                    SCPXP:OpenEnhancedMenu()
                end)
        end
    end)
end

-- Initialize integration when client loads
hook.Add("InitPostEntity", "SCPXP_InitIntegration", function()
    timer.Simple(1, function()
        SCPXP:IntegrateWithOnyxF4()
    end)
end)

-- Console command for opening enhanced menu
concommand.Add("scpxp_enhanced_menu", function()
    SCPXP:OpenEnhancedMenu()
end)

-- Leaderboard data fetching (add this to your server-side code)
function SCPXP:RequestLeaderboardData(category)
    net.Start("SCPXP_RequestLeaderboard")
        net.WriteString(category or "all")
    net.SendToServer()
end

-- Network receiver for leaderboard data
net.Receive("SCPXP_LeaderboardData", function()
    local category = net.ReadString()
    local data = net.ReadTable()
    
    if SCPXP.EnhancedMenu and IsValid(SCPXP.EnhancedMenu) then
        SCPXP:UpdateLeaderboard(category, data)
    end
end)

-- Update leaderboard display
function SCPXP:UpdateLeaderboard(category, data)
    -- This would update the leaderboard panel with real data
    if self.LeaderboardPanel and IsValid(self.LeaderboardPanel) then
        self.LeaderboardPanel:Clear()
        
        for i, entry in ipairs(data) do
            SCPXP.UI:CreateLeaderboardEntry(self.LeaderboardPanel, 20, 20 + (i-1) * 50, 900, 40,
                i, entry.name, entry.level, entry.xp, entry.category)
        end
    end
end

-- Add HUD overlay for quick XP display
function SCPXP:CreateHUDOverlay()
    hook.Add("HUDPaint", "SCPXP_HUD", function()
        if not GetConVar("scpxp_show_hud"):GetBool() then return end
        
        local ply = LocalPlayer()
        if not IsValid(ply) or not ply:Alive() then return end
        
        -- Initialize PlayerData if it doesn't exist
        if not SCPXP.PlayerData then
            SCPXP.PlayerData = {}
            for categoryId, _ in pairs(SCPXP.Config.Categories) do
                SCPXP.PlayerData[categoryId] = {
                    totalXP = 0,
                    level = 1
                }
            end
        end
        
        local job = ply:getDarkRPVar("job") or ""
        local category = SCPXP:GetJobCategoryClient(job)
        
        if not category or not SCPXP.PlayerData[category] then return end
        
        local data = SCPXP.PlayerData[category]
        local scrW, scrH = ScrW(), ScrH()
        
        -- HUD Panel
        local x, y = scrW - 250, 50
        local w, h = 230, 70
        
        draw.RoundedBox(8, x, y, w, h, ColorAlpha(SCPXP.UI.Colors.Background, 200))
        draw.RoundedBox(8, x, y, 4, h, SCPXP.Config.Categories[category].color)
        
        -- Category name and level
        draw.SimpleText(string.format("%s - Level %d", 
            SCPXP.Config.Categories[category].name, data.level or 1),
            "DermaDefaultBold", x + 15, y + 10, SCPXP.UI.Colors.Text)
        
        -- XP
        draw.SimpleText(string.format("%s XP", string.Comma(data.totalXP or 0)),
            "DermaDefault", x + 15, y + 30, SCPXP.UI.Colors.TextSecondary)
        
        -- Progress bar
        local currentLevel = data.level or 1
        local currentXP = data.totalXP or 0
        local currentLevelXP = SCPXP:GetTotalXPForLevel(currentLevel)
        local nextLevelXP = SCPXP:GetTotalXPForLevel(currentLevel + 1)
        local progress = 0
        
        if nextLevelXP > currentLevelXP then
            progress = (currentXP - currentLevelXP) / (nextLevelXP - currentLevelXP)
        end
        
        progress = math.Clamp(progress, 0, 1)
        
        local barX, barY = x + 15, y + 50
        local barW, barH = w - 30, 12
        
        draw.RoundedBox(4, barX, barY, barW, barH, SCPXP.UI.Colors.Accent)
        draw.RoundedBox(4, barX, barY, barW * progress, barH, SCPXP.Config.Categories[category].color)
        
        -- Progress percentage
        draw.SimpleText(string.format("%.1f%%", progress * 100),
            "DermaDefault", barX + barW/2, barY + barH/2 - 6, SCPXP.UI.Colors.Text, TEXT_ALIGN_CENTER)
    end)
end

-- Client-side job category detection
function SCPXP:GetJobCategoryClient(jobName)
    if not jobName then return nil end
    
    local job = string.lower(jobName)
    
    -- Research jobs
    if string.find(job, "research") or string.find(job, "scientist") or 
       string.find(job, "doctor") or string.find(job, "medic") then
        return "research"
    end
    
    -- Security jobs
    if string.find(job, "security") or string.find(job, "guard") or 
       string.find(job, "mtf") or string.find(job, "officer") or
       string.find(job, "captain") or string.find(job, "sergeant") or
       string.find(job, "cadet") or string.find(job, "gensec") then
        return "security"
    end
    
    -- D-Class jobs
    if string.find(job, "d-class") or string.find(job, "d class") or
       string.find(job, "class-d") or string.find(job, "prisoner") then
        return "dclass"
    end
    
    -- SCP jobs
    if string.find(job, "scp") then
        return "scp"
    end
    
    return nil
end

-- Enhanced notification system with sound effects
function SCPXP:PlayXPSound(type, category)
    local sounds = {
        xp_gain = {
            research = "buttons/button14.wav",
            security = "buttons/button15.wav", 
            dclass = "buttons/button17.wav",
            scp = "ambient/machines/machine1_hit2.wav"
        },
        level_up = "buttons/button3.wav",
        timed_xp = "buttons/button9.wav"
    }
    
    local sound = sounds[type]
    if type == "xp_gain" and sound[category] then
        surface.PlaySound(sound[category])
    elseif type ~= "xp_gain" and sound then
        surface.PlaySound(sound)
    else
        surface.PlaySound("buttons/button15.wav") -- Default
    end
end

-- Add particle effects for level ups
function SCPXP:CreateLevelUpEffect(category)
    local categoryColor = SCPXP.Config.Categories[category].color
    
    -- Create a temporary panel for the effect
    local effect = vgui.Create("DPanel")
    effect:SetSize(ScrW(), ScrH())
    effect:SetPos(0, 0)
    effect:MakePopup()
    effect:SetKeyboardInputEnabled(false)
    effect:SetMouseInputEnabled(false)
    
    local particles = {}
    local startTime = CurTime()
    
    -- Create particles
    for i = 1, 20 do
        particles[i] = {
            x = ScrW() / 2 + math.random(-100, 100),
            y = ScrH() / 2 + math.random(-50, 50),
            vx = math.random(-5, 5),
            vy = math.random(-8, -3),
            life = math.random(2, 4),
            maxLife = math.random(2, 4),
            size = math.random(3, 8)
        }
    end
    
    effect.Paint = function(self, w, h)
        local elapsed = CurTime() - startTime
        
        -- Update and draw particles
        for i, p in ipairs(particles) do
            if p.life > 0 then
                p.x = p.x + p.vx
                p.y = p.y + p.vy
                p.vy = p.vy + 0.2 -- Gravity
                p.life = p.life - FrameTime()
                
                local alpha = (p.life / p.maxLife) * 255
                draw.RoundedBox(p.size/2, p.x - p.size/2, p.y - p.size/2, p.size, p.size,
                    ColorAlpha(categoryColor, alpha))
            end
        end
        
        -- Remove effect after 5 seconds
        if elapsed > 5 then
            self:Remove()
        end
    end
end

-- ConVars for customization
CreateClientConVar("scpxp_show_hud", "1", true, false, "Show XP HUD overlay")
CreateClientConVar("scpxp_hud_x", "0", true, false, "HUD X position offset")
CreateClientConVar("scpxp_hud_y", "0", true, false, "HUD Y position offset")
CreateClientConVar("scpxp_notifications", "1", true, false, "Enable XP notifications")
CreateClientConVar("scpxp_sounds", "1", true, false, "Enable XP sounds")
CreateClientConVar("scpxp_particle_effects", "1", true, false, "Enable particle effects")

-- Settings panel for the enhanced menu
function SCPXP.UI:CreateSettingsPanel(parent)
    local panel = vgui.Create("DPanel", parent)
    panel:Dock(FILL)
    panel.Paint = function() end
    
    -- Title
    local title = vgui.Create("DLabel", panel)
    title:SetPos(20, 20)
    title:SetSize(400, 30)
    title:SetText("XP System Settings")
    title:SetFont("DermaLarge")
    title:SetTextColor(SCPXP.UI.Colors.Text)
    
    local y = 70
    
    -- HUD Toggle
    local hudToggle = vgui.Create("DCheckBoxLabel", panel)
    hudToggle:SetPos(20, y)
    hudToggle:SetText("Show XP HUD Overlay")
    hudToggle:SetValue(GetConVar("scpxp_show_hud"):GetBool())
    hudToggle:SetTextColor(SCPXP.UI.Colors.Text)
    hudToggle.OnChange = function(self, val)
        RunConsoleCommand("scpxp_show_hud", val and "1" or "0")
    end
    
    y = y + 30
    
    -- Notifications Toggle
    local notifToggle = vgui.Create("DCheckBoxLabel", panel)
    notifToggle:SetPos(20, y)
    notifToggle:SetText("Enable XP Notifications")
    notifToggle:SetValue(GetConVar("scpxp_notifications"):GetBool())
    notifToggle:SetTextColor(SCPXP.UI.Colors.Text)
    notifToggle.OnChange = function(self, val)
        RunConsoleCommand("scpxp_notifications", val and "1" or "0")
    end
    
    y = y + 30
    
    -- Sounds Toggle
    local soundToggle = vgui.Create("DCheckBoxLabel", panel)
    soundToggle:SetPos(20, y)
    soundToggle:SetText("Enable XP Sounds")
    soundToggle:SetValue(GetConVar("scpxp_sounds"):GetBool())
    soundToggle:SetTextColor(SCPXP.UI.Colors.Text)
    soundToggle.OnChange = function(self, val)
        RunConsoleCommand("scpxp_sounds", val and "1" or "0")
    end
    
    y = y + 30
    
    -- Particle Effects Toggle
    local particleToggle = vgui.Create("DCheckBoxLabel", panel)
    particleToggle:SetPos(20, y)
    particleToggle:SetText("Enable Particle Effects")
    particleToggle:SetValue(GetConVar("scpxp_particle_effects"):GetBool())
    particleToggle:SetTextColor(SCPXP.UI.Colors.Text)
    particleToggle.OnChange = function(self, val)
        RunConsoleCommand("scpxp_particle_effects", val and "1" or "0")
    end
    
    y = y + 50
    
    -- Test buttons
    local testBtn = SCPXP.UI:CreateButton(panel, "Test XP Notification", 
        20, y, 200, 35, SCPXP.UI.Colors.Info,
        function()
            SCPXP:ShowXPGain("research", 25, "Settings Test")
        end)
    
    local testLevelBtn = SCPXP.UI:CreateButton(panel, "Test Level Up", 
        240, y, 200, 35, SCPXP.UI.Colors.Success,
        function()
            SCPXP:ShowLevelUp("research", 5, "Settings Test Level Up!")
            if GetConVar("scpxp_particle_effects"):GetBool() then
                SCPXP:CreateLevelUpEffect("research")
            end
        end)
    
    return panel
end

-- Initialize HUD overlay and data
hook.Add("InitPostEntity", "SCPXP_InitClient", function()
    timer.Simple(1, function()
        SCPXP:InitializeClientData()
        SCPXP:CreateHUDOverlay()
        
        -- Request data from server if we don't have it
        if not SCPXP.PlayerData or table.IsEmpty(SCPXP.PlayerData) then
            timer.Simple(2, function()
                if IsValid(LocalPlayer()) then
                    RunConsoleCommand("scpxp_request_data")
                end
            end)
        end
    end)
end)

-- Override the old menu function
SCPXP.OpenMainMenu = SCPXP.OpenEnhancedMenu

print("[SCPXP] Enhanced menu system loaded!")