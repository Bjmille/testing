-- Onyx F4 Menu Integration for SCPXP System
-- Place this in: addons/scprp_experience_system/lua/autorun/client/scpxp_onyx_integration.lua

if not CLIENT then return end

-- Wait for both systems to load
local function WaitForSystems()
    if not SCPXP or not SCPXP.OpenEnhancedMenu then
        timer.Simple(1, WaitForSystems)
        return
    end
    
    -- Now integrate with Onyx F4
    SCPXP:SetupOnyxIntegration()
end

-- Main integration function
function SCPXP:SetupOnyxIntegration()
    
    -- Method 1: Hook into Onyx F4 creation (most common)
    hook.Add("OnyxUI.F4Menu.PostInit", "SCPXP_Integration", function(f4Panel)
        if not IsValid(f4Panel) then return end
        
        -- Find the tab container (adjust based on your Onyx version)
        local tabContainer = f4Panel.TabContainer or f4Panel.Tabs
        if not IsValid(tabContainer) then
            print("[SCPXP] Warning: Could not find Onyx F4 tab container")
            return
        end
        
        -- Create SCPXP tab
        self:CreateOnyxTab(tabContainer)
        
        print("[SCPXP] Successfully integrated with Onyx F4 Menu")
    end)
    
    -- Method 2: Alternative hook (if the above doesn't work)
    hook.Add("OnyxUI.F4Menu.AddTabs", "SCPXP_Integration_Alt", function(tabs)
        table.insert(tabs, {
            name = "Experience",
            icon = "icon16/chart_line.png",
            panel = function(parent)
                return self:CreateOnyxXPPanel(parent)
            end
        })
    end)
    
    -- Method 3: Direct integration with existing tabs
    hook.Add("OnyxUI.F4Menu.Settings.PostInit", "SCPXP_SettingsIntegration", function(settingsPanel)
        if not IsValid(settingsPanel) then return end
        
        self:AddToOnyxSettings(settingsPanel)
    end)
end

-- Create a dedicated XP tab for Onyx F4
function SCPXP:CreateOnyxTab(tabContainer)
    -- Create tab button
    local xpTab = vgui.Create("OnyxUI.Button", tabContainer) -- Adjust class name based on Onyx version
    xpTab:SetText("📊 Experience")
    xpTab:SetSize(120, 35)
    
    -- Style to match Onyx theme (adjust colors based on your Onyx theme)
    xpTab.Paint = function(self, w, h)
        local isActive = self.Active or false
        local bgColor = isActive and Color(74, 144, 226, 200) or Color(45, 45, 55, 180)
        local textColor = Color(255, 255, 255, 255)
        
        -- Background
        draw.RoundedBox(6, 0, 0, w, h, bgColor)
        
        -- Hover effect
        if self:IsHovered() and not isActive then
            draw.RoundedBox(6, 0, 0, w, h, Color(55, 55, 65, 100))
        end
        
        -- Icon and text
        draw.SimpleText("📊", "DermaDefaultBold", 15, h/2, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("Experience", "DermaDefault", 35, h/2, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    
    -- Tab content panel
    local contentPanel = vgui.Create("DPanel", tabContainer:GetParent())
    contentPanel:SetVisible(false)
    contentPanel.Paint = function() end
    
    -- Populate the content panel
    self:PopulateOnyxXPTab(contentPanel)
    
    xpTab.DoClick = function()
        -- Hide other tab contents
        for _, child in pairs(tabContainer:GetParent():GetChildren()) do
            if child.IsOnyxTabContent then
                child:SetVisible(false)
            end
        end
        
        -- Show this tab's content
        contentPanel:SetVisible(true)
        contentPanel.IsOnyxTabContent = true
        
        -- Update tab states
        for _, child in pairs(tabContainer:GetChildren()) do
            if child.Active ~= nil then
                child.Active = false
            end
        end
        xpTab.Active = true
    end
    
    return xpTab, contentPanel
end

-- Populate the XP tab with content
function SCPXP:PopulateOnyxXPTab(panel)
    panel:Dock(FILL)
    
    -- Header section
    local header = vgui.Create("DPanel", panel)
    header:Dock(TOP)
    header:SetHeight(80)
    header.Paint = function(self, w, h)
        draw.RoundedBox(8, 5, 5, w-10, h-10, Color(35, 35, 40, 200))
        
        -- Title
        draw.SimpleText("SCP-RP Experience System", "DermaLarge", 20, 20, Color(255, 255, 255))
        draw.SimpleText("Track your progress across all departments", "DermaDefault", 20, 45, Color(180, 180, 185))
    end
    
    -- Quick stats section
    local statsPanel = vgui.Create("DPanel", panel)
    statsPanel:Dock(TOP)
    statsPanel:SetHeight(100)
    statsPanel:DockMargin(5, 5, 5, 5)
    
    statsPanel.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(45, 45, 55, 180))
    end
    
    -- Calculate total stats
    local totalXP = 0
    local totalLevels = 0
    local highestLevel = 0
    local highestCategory = "None"
    
    for category, data in pairs(SCPXP.PlayerData or {}) do
        local xp = data.totalXP or 0
        local level = data.level or 1
        
        totalXP = totalXP + xp
        totalLevels = totalLevels + level
        
        if level > highestLevel then
            highestLevel = level
            highestCategory = SCPXP.Config.Categories[category].name
        end
    end
    
    -- Stats labels
    local stats = {
        {label = "Total XP", value = string.Comma(totalXP)},
        {label = "Combined Levels", value = tostring(totalLevels)},
        {label = "Highest Level", value = string.format("%d (%s)", highestLevel, highestCategory)}
    }
    
    for i, stat in ipairs(stats) do
        local x = 20 + (i-1) * 250
        
        draw.SimpleText(stat.label, "DermaDefault", x, 25, Color(180, 180, 185))
        draw.SimpleText(stat.value, "DermaDefaultBold", x, 45, Color(255, 255, 255))
    end
    
    -- Category cards
    local cardContainer = vgui.Create("DScrollPanel", panel)
    cardContainer:Dock(FILL)
    cardContainer:DockMargin(5, 5, 5, 5)
    
    local cardY = 10
    for categoryId, categoryData in pairs(SCPXP.Config.Categories) do
        local playerData = SCPXP.PlayerData[categoryId] or {totalXP = 0, level = 1}
        
        -- Create mini stat card
        local card = vgui.Create("DPanel", cardContainer)
        card:SetPos(10, cardY)
        card:SetSize(cardContainer:GetWide() - 30, 80)
        
        card.Paint = function(self, w, h)
            local bgColor = Color(45, 45, 55, 200)
            local accentColor = categoryData.color
            
            -- Background
            draw.RoundedBox(8, 0, 0, w, h, bgColor)
            
            -- Accent line
            draw.RoundedBox(8, 0, 0, 6, h, accentColor)
            
            -- Category info
            draw.SimpleText(categoryData.name, "DermaDefaultBold", 20, 15, Color(255, 255, 255))
            draw.SimpleText(string.format("Level %d", playerData.level or 1), "DermaDefault", 20, 35, accentColor)
            draw.SimpleText(string.format("%s XP", string.Comma(playerData.totalXP or 0)), "DermaDefault", 20, 55, Color(180, 180, 185))
            
            -- Progress bar
            local currentLevel = playerData.level or 1
            local currentXP = playerData.totalXP or 0
            local currentLevelXP = SCPXP:GetTotalXPForLevel(currentLevel)
            local nextLevelXP = SCPXP:GetTotalXPForLevel(currentLevel + 1)
            local progress = 0
            
            if nextLevelXP > currentLevelXP then
                progress = (currentXP - currentLevelXP) / (nextLevelXP - currentLevelXP)
            end
            
            progress = math.Clamp(progress, 0, 1)
            
            local barX, barY = w - 200, 35
            local barW, barH = 180, 12
            
            draw.RoundedBox(4, barX, barY, barW, barH, Color(60, 60, 70))
            draw.RoundedBox(4, barX, barY, barW * progress, barH, accentColor)
            
            -- Progress text
            draw.SimpleText(string.format("%.1f%%", progress * 100), "DermaDefault", 
                barX + barW/2, barY + barH/2 - 6, Color(255, 255, 255), TEXT_ALIGN_CENTER)
        end
        
        cardY = cardY + 90
    end
    
    -- Action buttons
    local buttonPanel = vgui.Create("DPanel", panel)
    buttonPanel:Dock(BOTTOM)
    buttonPanel:SetHeight(60)
    buttonPanel:DockMargin(5, 5, 5, 5)
    buttonPanel.Paint = function() end
    
    -- Open full menu button
    local openMenuBtn = vgui.Create("DButton", buttonPanel)
    openMenuBtn:SetPos(10, 10)
    openMenuBtn:SetSize(200, 40)
    openMenuBtn:SetText("Open Detailed Menu")
    
    openMenuBtn.Paint = function(self, w, h)
        local bgColor = self:IsHovered() and Color(74, 144, 226) or Color(64, 134, 216)
        draw.RoundedBox(6, 0, 0, w, h, bgColor)
        draw.SimpleText("📊 Open Detailed Menu", "DermaDefaultBold", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    openMenuBtn.DoClick = function()
        SCPXP:OpenEnhancedMenu()
    end
    
    -- Quick credit button (for researchers)
    local ply = LocalPlayer()
    if IsValid(ply) then
        local job = string.lower(ply:getDarkRPVar("job") or "")
        if string.find(job, "research") or string.find(job, "scientist") then
            local creditBtn = vgui.Create("DButton", buttonPanel)
            creditBtn:SetPos(220, 10)
            creditBtn:SetSize(150, 40)
            creditBtn:SetText("Quick Credit")
            
            creditBtn.Paint = function(self, w, h)
                local bgColor = self:IsHovered() and Color(46, 204, 113) or Color(39, 174, 96)
                draw.RoundedBox(6, 0, 0, w, h, bgColor)
                draw.SimpleText("💳 Quick Credit", "DermaDefaultBold", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            
            creditBtn.DoClick = function()
                -- Open player selector for credit
                SCPXP:OpenQuickCreditMenu()
            end
        end
    end
end

-- Quick credit menu
function SCPXP:OpenQuickCreditMenu()
    local frame = vgui.Create("DFrame")
    frame:SetSize(400, 500)
    frame:Center()
    frame:SetTitle("Quick Credit Player")
    frame:MakePopup()
    
    local playerList = vgui.Create("DListView", frame)
    playerList:Dock(FILL)
    playerList:SetMultiSelect(false)
    playerList:AddColumn("Player")
    playerList:AddColumn("Job")
    
    -- Populate with nearby players or all players
    for _, ply in ipairs(player.GetAll()) do
        if ply ~= LocalPlayer() then
            local job = ply:getDarkRPVar("job") or "Unknown"
            playerList:AddLine(ply:Nick(), job).Player = ply
        end
    end
    
    local creditBtn = vgui.Create("DButton", frame)
    creditBtn:Dock(BOTTOM)
    creditBtn:SetHeight(40)
    creditBtn:SetText("Credit Selected Player")
    
    creditBtn.DoClick = function()
        local selected = playerList:GetSelected()
        if selected and selected[1] and selected[1].Player then
            local target = selected[1].Player
            RunConsoleCommand("say", "!credit " .. target:Nick())
            frame:Close()
        end
    end
end

-- Add settings to Onyx settings panel
function SCPXP:AddToOnyxSettings(settingsPanel)
    -- Create XP settings section
    local xpSection = vgui.Create("DCollapsibleCategory", settingsPanel)
    xpSection:SetSize(settingsPanel:GetWide(), 200)
    xpSection:SetExpanded(false)
    xpSection:SetLabel("Experience System Settings")
    
    local xpList = vgui.Create("DPanelList", xpSection)
    xpList:SetSize(xpSection:GetWide(), 150)
    xpList:EnableHorizontal(false)
    xpList:EnableVerticalScrollbar(true)
    
    xpSection:SetContents(xpList)
    
    -- HUD Toggle
    local hudToggle = vgui.Create("DCheckBoxLabel")
    hudToggle:SetText("Show XP HUD Overlay")
    hudToggle:SetValue(GetConVar("scpxp_show_hud"):GetBool())
    hudToggle.OnChange = function(self, val)
        RunConsoleCommand("scpxp_show_hud", val and "1" or "0")
    end
    xpList:AddItem(hudToggle)
    
    -- Notifications Toggle
    local notifToggle = vgui.Create("DCheckBoxLabel")
    notifToggle:SetText("Enable XP Notifications")
    notifToggle:SetValue(GetConVar("scpxp_notifications"):GetBool())
    notifToggle.OnChange = function(self, val)
        RunConsoleCommand("scpxp_notifications", val and "1" or "0")
    end
    xpList:AddItem(notifToggle)
    
    -- Sounds Toggle
    local soundToggle = vgui.Create("DCheckBoxLabel")
    soundToggle:SetText("Enable XP Sound Effects")
    soundToggle:SetValue(GetConVar("scpxp_sounds"):GetBool())
    soundToggle.OnChange = function(self, val)
        RunConsoleCommand("scpxp_sounds", val and "1" or "0")
    end
    xpList:AddItem(soundToggle)
    
    -- Open Menu Button
    local openMenuBtn = vgui.Create("DButton")
    openMenuBtn:SetText("Open XP Menu")
    openMenuBtn:SetSize(200, 30)
    openMenuBtn.DoClick = function()
        SCPXP:OpenEnhancedMenu()
    end
    xpList:AddItem(openMenuBtn)
end

-- Alternative integration methods for different Onyx versions
function SCPXP:TryAlternativeIntegration()
    -- Method A: Direct panel injection
    hook.Add("Think", "SCPXP_FindOnyxF4", function()
        for _, panel in pairs(vgui.GetWorldPanel():GetChildren()) do
            if IsValid(panel) and panel.ClassName == "OnyxF4Frame" then
                -- Found Onyx F4, try to integrate
                SCPXP:InjectIntoExistingF4(panel)
                hook.Remove("Think", "SCPXP_FindOnyxF4")
                break
            end
        end
    end)
    
    -- Method B: Command integration
    hook.Add("OnPlayerChat", "SCPXP_ChatCommands", function(ply, text, team, dead)
        if ply == LocalPlayer() then
            local cmd = string.lower(text)
            if cmd == "!xp" or cmd == "/xp" or cmd == "!experience" then
                SCPXP:OpenEnhancedMenu()
                return true
            elseif cmd == "!xpmenu" or cmd == "/xpmenu" then
                SCPXP:OpenEnhancedMenu()
                return true
            end
        end
    end)
end

function SCPXP:InjectIntoExistingF4(f4Panel)
    if not IsValid(f4Panel) then return end
    
    -- Try to find buttons panel or similar
    local function findButtonsPanel(parent)
        for _, child in pairs(parent:GetChildren()) do
            if IsValid(child) then
                if child.ClassName == "DPanel" or child.ClassName == "OnyxPanel" then
                    local found = findButtonsPanel(child)
                    if found then return found end
                elseif child.ClassName == "DButton" or string.find(child.ClassName or "", "Button") then
                    return child:GetParent()
                end
            end
        end
        return nil
    end
    
    local buttonsPanel = findButtonsPanel(f4Panel)
    if IsValid(buttonsPanel) then
        -- Add XP button to existing buttons
        local xpBtn = vgui.Create("DButton", buttonsPanel)
        xpBtn:SetText("📊 Experience")
        xpBtn:SetSize(120, 35)
        
        -- Position it (you may need to adjust this)
        local children = buttonsPanel:GetChildren()
        local yPos = 10
        for _, child in pairs(children) do
            if IsValid(child) and child ~= xpBtn then
                yPos = math.max(yPos, child.y + child:GetTall() + 5)
            end
        end
        xpBtn:SetPos(10, yPos)
        
        xpBtn.DoClick = function()
            SCPXP:OpenEnhancedMenu()
            f4Panel:Close()
        end
        
        print("[SCPXP] Successfully injected into existing Onyx F4")
    end
end

-- Generic integration for any F4 menu system
function SCPXP:GenericF4Integration()
    -- Hook into common F4 menu creation patterns
    local f4Hooks = {
        "F4Menu.Init",
        "F4Menu.PostInit", 
        "F4.PostInit",
        "OnyxF4.Init",
        "ModernF4.Init",
        "CustomF4.Init"
    }
    
    for _, hookName in ipairs(f4Hooks) do
        hook.Add(hookName, "SCPXP_Integration_" .. hookName, function(...)
            local args = {...}
            local frame = args[1]
            
            if IsValid(frame) then
                timer.Simple(0.1, function()
                    if IsValid(frame) then
                        SCPXP:TryGenericIntegration(frame)
                    end
                end)
            end
        end)
    end
    
    -- Also try to hook into F4 key press
    hook.Add("PlayerButtonDown", "SCPXP_F4Integration", function(ply, button)
        if ply == LocalPlayer() and button == KEY_F4 then
            -- Small delay to let F4 menu open first
            timer.Simple(0.2, function()
                SCPXP:FindAndIntegrateWithF4()
            end)
        end
    end)
end

function SCPXP:TryGenericIntegration(frame)
    -- Look for common panel types that might contain buttons
    local function findIntegrationPoint(parent, depth)
        if depth > 3 then return nil end -- Prevent infinite recursion
        
        for _, child in pairs(parent:GetChildren()) do
            if IsValid(child) then
                -- Look for button containers
                if child.ClassName == "DPanel" or 
                   child.ClassName == "OnyxPanel" or 
                   string.find(child.ClassName or "", "Panel") then
                    
                    -- Check if this panel contains buttons
                    local hasButtons = false
                    for _, grandchild in pairs(child:GetChildren()) do
                        if string.find(grandchild.ClassName or "", "Button") then
                            hasButtons = true
                            break
                        end
                    end
                    
                    if hasButtons then
                        return child
                    else
                        -- Recurse deeper
                        local found = findIntegrationPoint(child, depth + 1)
                        if found then return found end
                    end
                end
            end
        end
        return nil
    end
    
    local integrationPanel = findIntegrationPoint(frame, 0)
    if IsValid(integrationPanel) then
        SCPXP:AddButtonToPanel(integrationPanel)
    end
end

function SCPXP:AddButtonToPanel(panel)
    local xpBtn = vgui.Create("DButton", panel)
    xpBtn:SetText("📊 XP System")
    xpBtn:SetSize(100, 30)
    
    -- Try to position it nicely
    local x, y = 10, 10
    local maxY = 10
    
    for _, child in pairs(panel:GetChildren()) do
        if IsValid(child) and child ~= xpBtn then
            maxY = math.max(maxY, child.y + child:GetTall() + 5)
        end
    end
    
    xpBtn:SetPos(x, maxY)
    
    -- Style the button
    xpBtn.Paint = function(self, w, h)
        local bgColor = self:IsHovered() and Color(74, 144, 226, 200) or Color(64, 134, 216, 180)
        draw.RoundedBox(4, 0, 0, w, h, bgColor)
        draw.SimpleText("📊 XP System", "DermaDefault", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    xpBtn.DoClick = function()
        SCPXP:OpenEnhancedMenu()
        -- Try to close the F4 menu
        if IsValid(panel:GetParent()) then
            local topParent = panel
            while IsValid(topParent:GetParent()) and topParent:GetParent() ~= vgui.GetWorldPanel() do
                topParent = topParent:GetParent()
            end
            if IsValid(topParent) and topParent.Close then
                topParent:Close()
            end
        end
    end
    
    print("[SCPXP] Added XP button to F4 menu panel")
end

function SCPXP:FindAndIntegrateWithF4()
    -- Search for open F4-like panels
    local function findF4Panel(parent)
        for _, child in pairs(parent:GetChildren()) do
            if IsValid(child) then
                local className = child.ClassName or ""
                local title = ""
                
                if child.GetTitle then
                    title = string.lower(child:GetTitle() or "")
                end
                
                -- Look for F4 menu indicators
                if string.find(className, "F4") or 
                   string.find(className, "Onyx") or
                   string.find(title, "f4") or
                   string.find(title, "menu") or
                   (child:GetWide() > 600 and child:GetTall() > 400 and child:IsVisible()) then
                    
                    return child
                end
                
                -- Recurse into children
                local found = findF4Panel(child)
                if found then return found end
            end
        end
        return nil
    end
    
    local f4Panel = findF4Panel(vgui.GetWorldPanel())
    if IsValid(f4Panel) then
        timer.Simple(0.1, function()
            if IsValid(f4Panel) then
                SCPXP:TryGenericIntegration(f4Panel)
            end
        end)
    end
end

-- Fallback: Add to spawn menu if all else fails
function SCPXP:AddToSpawnMenu()
    hook.Add("SpawnMenuOpen", "SCPXP_SpawnMenuIntegration", function()
        -- Add to utilities tab or create new tab
        spawnmenu.AddToolMenuOption("Utilities", "SCPXP", "Experience System", "Experience System", "", "", function(panel)
            panel:Clear()
            
            local header = vgui.Create("DLabel", panel)
            header:SetText("SCP-RP Experience System")
            header:SetFont("DermaLarge")
            header:Dock(TOP)
            
            local openBtn = vgui.Create("DButton", panel)
            openBtn:SetText("Open XP Menu")
            openBtn:SetSize(200, 40)
            openBtn:Dock(TOP)
            openBtn:DockMargin(0, 10, 0, 0)
            openBtn.DoClick = function()
                SCPXP:OpenEnhancedMenu()
            end
            
            -- Add quick stats display
            local statsPanel = vgui.Create("DPanel", panel)
            statsPanel:SetSize(300, 200)
            statsPanel:Dock(FILL)
            statsPanel:DockMargin(0, 10, 0, 0)
            
            statsPanel.Paint = function(self, w, h)
                draw.RoundedBox(4, 0, 0, w, h, Color(45, 45, 55, 200))
                
                local y = 20
                draw.SimpleText("Your XP Progress:", "DermaDefaultBold", 20, y, Color(255, 255, 255))
                y = y + 25
                
                for categoryId, categoryData in pairs(SCPXP.Config.Categories) do
                    local playerData = SCPXP.PlayerData[categoryId] or {totalXP = 0, level = 1}
                    
                    draw.SimpleText(string.format("%s: Level %d (%s XP)", 
                        categoryData.name, playerData.level or 1, string.Comma(playerData.totalXP or 0)),
                        "DermaDefault", 30, y, categoryData.color)
                    y = y + 20
                end
            end
        end)
    end)
end

-- Initialize all integration methods
hook.Add("InitPostEntity", "SCPXP_InitIntegration", function()
    timer.Simple(2, function() -- Wait for other systems to load
        WaitForSystems()
        SCPXP:TryAlternativeIntegration()
        SCPXP:GenericF4Integration()
        SCPXP:AddToSpawnMenu()
        
        print("[SCPXP] All integration methods initialized")
    end)
end)

-- Console command to test integration
concommand.Add("scpxp_test_integration", function()
    print("[SCPXP] Testing F4 integration...")
    SCPXP:FindAndIntegrateWithF4()
end)

-- Keybind registration (players can bind a key to open XP menu)
concommand.Add("+scpxp_menu", function()
    SCPXP:OpenEnhancedMenu()
end)

concommand.Add("-scpxp_menu", function()
    -- Do nothing on release
end)

print("[SCPXP] Onyx F4 integration loaded successfully!")

--[[
INTEGRATION INSTRUCTIONS:

1. AUTOMATIC INTEGRATION:
   - This file tries multiple methods to automatically integrate with your Onyx F4 menu
   - It should work with most Onyx versions without modification

2. MANUAL INTEGRATION (if automatic doesn't work):
   - Find your Onyx F4 menu files (usually in addons/onyx_f4/ or similar)
   - Look for the main F4 creation function
   - Add this code where tabs/buttons are created:
   
   local xpBtn = vgui.Create("DButton", yourButtonPanel)
   xpBtn:SetText("📊 Experience")
   xpBtn:SetSize(120, 35)
   xpBtn.DoClick = function()
       if SCPXP and SCPXP.OpenEnhancedMenu then
           SCPXP:OpenEnhancedMenu()
       end
   end

3. CONSOLE COMMANDS FOR TESTING:
   - scpxp_test_integration - Test integration
   - scpxp_enhanced_menu - Open XP menu directly
   - bind KEY +scpxp_menu - Bind a key to open XP menu

4. CHAT COMMANDS:
   - !xp or /xp - Open XP menu
   - !xpmenu or /xpmenu - Open XP menu

5. FALLBACK ACCESS:
   - Spawn menu -> Utilities -> SCPXP -> Experience System
   - Console: scpxp_enhanced_menu

The integration will automatically detect when it successfully connects to your F4 menu.
]]