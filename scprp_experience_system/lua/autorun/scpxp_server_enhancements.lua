-- Server-Side Enhancements for SCPXP Enhanced Menu
-- Place this in: addons/scprp_experience_system/lua/autorun/server/scpxp_server_enhancements.lua

if not SERVER then return end

-- Add new network strings for enhanced features
util.AddNetworkString("SCPXP_RequestLeaderboard")
util.AddNetworkString("SCPXP_LeaderboardData") 
util.AddNetworkString("SCPXP_RequestPlayerStats")
util.AddNetworkString("SCPXP_PlayerStatsData")
util.AddNetworkString("SCPXP_RequestServerStats")
util.AddNetworkString("SCPXP_ServerStatsData")

-- Leaderboard System
function SCPXP:GetLeaderboardData(category, limit)
    limit = limit or 50
    local query
    
    if category == "all" then
        -- Combined leaderboard across all categories
        query = string.format([[
            SELECT steamid, nick, 
                   (research_xp + security_xp + dclass_xp + scp_xp) as total_xp,
                   (research_level + security_level + dclass_level + scp_level) as total_levels,
                   research_xp, security_xp, dclass_xp, scp_xp,
                   research_level, security_level, dclass_level, scp_level
            FROM scpxp_players 
            ORDER BY total_xp DESC 
            LIMIT %d
        ]], limit)
    else
        -- Category-specific leaderboard
        local xpCol = category .. "_xp"
        local levelCol = category .. "_level"
        query = string.format([[
            SELECT steamid, nick, %s as xp, %s as level
            FROM scpxp_players 
            WHERE %s > 0
            ORDER BY %s DESC 
            LIMIT %d
        ]], xpCol, levelCol, xpCol, xpCol, limit)
    end
    
    local result = sql.Query(query)
    if not result then return {} end
    
    local leaderboard = {}
    for i, row in ipairs(result) do
        if category == "all" then
            table.insert(leaderboard, {
                rank = i,
                steamid = row.steamid,
                name = row.nick,
                totalXP = tonumber(row.total_xp) or 0,
                totalLevels = tonumber(row.total_levels) or 0,
                categories = {
                    research = {xp = tonumber(row.research_xp) or 0, level = tonumber(row.research_level) or 1},
                    security = {xp = tonumber(row.security_xp) or 0, level = tonumber(row.security_level) or 1},
                    dclass = {xp = tonumber(row.dclass_xp) or 0, level = tonumber(row.dclass_level) or 1},
                    scp = {xp = tonumber(row.scp_xp) or 0, level = tonumber(row.scp_level) or 1}
                }
            })
        else
            table.insert(leaderboard, {
                rank = i,
                steamid = row.steamid,
                name = row.nick,
                xp = tonumber(row.xp) or 0,
                level = tonumber(row.level) or 1,
                category = category
            })
        end
    end
    
    return leaderboard
end

-- Get detailed player statistics
function SCPXP:GetPlayerDetailedStats(steamid)
    local query = string.format([[
        SELECT p.*, COUNT(l.id) as xp_gains, 
               SUM(l.amount) as total_gained_xp,
               MIN(l.timestamp) as first_gain,
               MAX(l.timestamp) as last_gain
        FROM scpxp_players p
        LEFT JOIN scpxp_logs l ON p.steamid = l.steamid
        WHERE p.steamid = '%s'
        GROUP BY p.steamid
    ]], steamid)
    
    local result = sql.Query(query)
    if not result or not result[1] then return nil end
    
    local data = result[1]
    
    -- Get recent XP gains
    local recentQuery = string.format([[
        SELECT category, amount, reason, timestamp
        FROM scpxp_logs 
        WHERE steamid = '%s'
        ORDER BY timestamp DESC
        LIMIT 20
    ]], steamid)
    
    local recentResult = sql.Query(recentQuery) or {}
    
    -- Get category breakdown
    local categoryQuery = string.format([[
        SELECT category, SUM(amount) as total_amount, COUNT(*) as gain_count
        FROM scpxp_logs 
        WHERE steamid = '%s'
        GROUP BY category
    ]], steamid)
    
    local categoryResult = sql.Query(categoryQuery) or {}
    
    return {
        basic = data,
        recent_gains = recentResult,
        category_breakdown = categoryResult
    }
end

-- Get server-wide statistics
function SCPXP:GetServerStats()
    local queries = {
        -- Total players with XP
        total_players = "SELECT COUNT(DISTINCT steamid) as count FROM scpxp_players WHERE research_xp + security_xp + dclass_xp + scp_xp > 0",
        
        -- Total XP distributed
        total_xp = "SELECT SUM(research_xp + security_xp + dclass_xp + scp_xp) as total FROM scpxp_players",
        
        -- XP by category
        category_totals = "SELECT SUM(research_xp) as research, SUM(security_xp) as security, SUM(dclass_xp) as dclass, SUM(scp_xp) as scp FROM scpxp_players",
        
        -- Top categories by player count
        category_players = [[
            SELECT 
                SUM(CASE WHEN research_xp > 0 THEN 1 ELSE 0 END) as research_players,
                SUM(CASE WHEN security_xp > 0 THEN 1 ELSE 0 END) as security_players,
                SUM(CASE WHEN dclass_xp > 0 THEN 1 ELSE 0 END) as dclass_players,
                SUM(CASE WHEN scp_xp > 0 THEN 1 ELSE 0 END) as scp_players
            FROM scpxp_players
        ]],
        
        -- Recent activity (last 24 hours)
        recent_activity = string.format([[
            SELECT COUNT(*) as recent_gains, SUM(amount) as recent_xp
            FROM scpxp_logs 
            WHERE datetime(timestamp) >= datetime('now', '-24 hours')
        ]]),
        
        -- Most popular XP sources
        popular_sources = [[
            SELECT reason, COUNT(*) as usage_count, SUM(amount) as total_xp
            FROM scpxp_logs 
            GROUP BY reason
            ORDER BY usage_count DESC
            LIMIT 10
        ]]
    }
    
    local stats = {}
    
    for key, query in pairs(queries) do
        local result = sql.Query(query)
        if result and result[1] then
            stats[key] = result[1]
        end
    end
    
    -- Get popular sources as array
    local sourcesResult = sql.Query(queries.popular_sources)
    stats.popular_sources = sourcesResult or {}
    
    return stats
end

-- Network handlers
net.Receive("SCPXP_RequestLeaderboard", function(len, ply)
    local category = net.ReadString()
    local leaderboard = SCPXP:GetLeaderboardData(category, 50)
    
    net.Start("SCPXP_LeaderboardData")
        net.WriteString(category)
        net.WriteTable(leaderboard)
    net.Send(ply)
end)

net.Receive("SCPXP_RequestPlayerStats", function(len, ply)
    local targetSteamID = net.ReadString()
    
    -- Allow players to view their own stats, staff can view anyone's
    if targetSteamID ~= ply:SteamID64() and not table.HasValue(SCPXP.StaffRanks, ply:GetUserGroup()) then
        return
    end
    
    local stats = SCPXP:GetPlayerDetailedStats(targetSteamID)
    
    net.Start("SCPXP_PlayerStatsData")
        net.WriteString(targetSteamID)
        net.WriteTable(stats or {})
    net.Send(ply)
end)

net.Receive("SCPXP_RequestServerStats", function(len, ply)
    -- Only staff can view server stats
    if not table.HasValue(SCPXP.StaffRanks, ply:GetUserGroup()) then
        return
    end
    
    local stats = SCPXP:GetServerStats()
    
    net.Start("SCPXP_ServerStatsData")
        net.WriteTable(stats)
    net.Send(ply)
end)

-- Admin commands for enhanced system
concommand.Add("scpxp_top", function(ply, cmd, args)
    if not table.HasValue(SCPXP.StaffRanks, ply:GetUserGroup()) then return end
    
    local category = args[1] or "all"
    local limit = tonumber(args[2]) or 10
    
    local leaderboard = SCPXP:GetLeaderboardData(category, limit)
    
    ply:ChatPrint("=== Top " .. limit .. " Players (" .. category .. ") ===")
    
    if category == "all" then
        for _, entry in ipairs(leaderboard) do
            ply:ChatPrint(string.format("%d. %s - %s Total XP", 
                entry.rank, entry.name, string.Comma(entry.totalXP)))
        end
    else
        for _, entry in ipairs(leaderboard) do
            ply:ChatPrint(string.format("%d. %s - Level %d (%s XP)", 
                entry.rank, entry.name, entry.level, string.Comma(entry.xp)))
        end
    end
end)

concommand.Add("scpxp_player_stats", function(ply, cmd, args)
    if not ply:IsSuperAdmin() then return end
    
    local target = ply
    if args[1] then
        target = player.GetByID(tonumber(args[1]))
    end
    
    if not IsValid(target) then
        ply:ChatPrint("Invalid player")
        return
    end
    
    local stats = SCPXP:GetPlayerDetailedStats(target:SteamID64())
    if not stats then
        ply:ChatPrint("No stats found for " .. target:Nick())
        return
    end
    
    ply:ChatPrint("=== " .. target:Nick() .. "'s Detailed Stats ===")
    ply:ChatPrint("Total XP Gains: " .. (stats.basic.xp_gains or 0))
    ply:ChatPrint("Total XP Earned: " .. string.Comma(tonumber(stats.basic.total_gained_xp) or 0))
    ply:ChatPrint("First XP Gain: " .. (stats.basic.first_gain or "Never"))
    ply:ChatPrint("Last XP Gain: " .. (stats.basic.last_gain or "Never"))
    
    ply:ChatPrint("Category Breakdown:")
    for _, breakdown in ipairs(stats.category_breakdown) do
        ply:ChatPrint(string.format("  %s: %s XP (%d gains)", 
            breakdown.category, string.Comma(tonumber(breakdown.total_amount)), tonumber(breakdown.gain_count)))
    end
end)

concommand.Add("scpxp_server_stats", function(ply, cmd, args)
    if not ply:IsSuperAdmin() then return end
    
    local stats = SCPXP:GetServerStats()
    
    ply:ChatPrint("=== Server XP Statistics ===")
    ply:ChatPrint("Total Players with XP: " .. (stats.total_players.count or 0))
    ply:ChatPrint("Total XP Distributed: " .. string.Comma(tonumber(stats.total_xp.total) or 0))
    
    if stats.category_totals then
        ply:ChatPrint("XP by Category:")
        ply:ChatPrint("  Research: " .. string.Comma(tonumber(stats.category_totals.research) or 0))
        ply:ChatPrint("  Security: " .. string.Comma(tonumber(stats.category_totals.security) or 0))
        ply:ChatPrint("  D-Class: " .. string.Comma(tonumber(stats.category_totals.dclass) or 0))
        ply:ChatPrint("  SCP: " .. string.Comma(tonumber(stats.category_totals.scp) or 0))
    end
    
    if stats.recent_activity then
        ply:ChatPrint("Recent Activity (24h):")
        ply:ChatPrint("  XP Gains: " .. (stats.recent_activity.recent_gains or 0))
        ply:ChatPrint("  XP Amount: " .. string.Comma(tonumber(stats.recent_activity.recent_xp) or 0))
    end
    
    ply:ChatPrint("Top XP Sources:")
    for i, source in ipairs(stats.popular_sources) do
        if i <= 5 then
            ply:ChatPrint(string.format("  %d. %s: %d times (%s XP)", 
                i, source.reason, tonumber(source.usage_count), string.Comma(tonumber(source.total_xp))))
        end
    end
end)

-- Reset player XP (admin only)
concommand.Add("scpxp_reset_player", function(ply, cmd, args)
    if not ply:IsSuperAdmin() then return end
    if #args < 1 then
        ply:ChatPrint("Usage: scpxp_reset_player <player_id> [category]")
        return
    end
    
    local target = player.GetByID(tonumber(args[1]))
    if not IsValid(target) then
        ply:ChatPrint("Invalid player")
        return
    end
    
    local category = args[2]
    
    if category and SCPXP.Config.Categories[category] then
        -- Reset specific category
        target.SCPXPData[category].totalXP = 0
        target.SCPXPData[category].level = 1
        ply:ChatPrint(string.format("Reset %s's %s XP", target:Nick(), category))
        
        -- Update database
        local xpCol = category .. "_xp"
        local levelCol = category .. "_level"
        sql.Query(string.format("UPDATE scpxp_players SET %s = 0, %s = 1 WHERE steamid = '%s'", 
            xpCol, levelCol, target:SteamID64()))
    else
        -- Reset all categories
        for cat, _ in pairs(SCPXP.Config.Categories) do
            target.SCPXPData[cat].totalXP = 0
            target.SCPXPData[cat].level = 1
        end
        ply:ChatPrint("Reset all XP for " .. target:Nick())
        
        -- Update database
        sql.Query(string.format([[
            UPDATE scpxp_players SET 
                research_xp = 0, research_level = 1,
                security_xp = 0, security_level = 1,
                dclass_xp = 0, dclass_level = 1,
                scp_xp = 0, scp_level = 1
            WHERE steamid = '%s'
        ]], target:SteamID64()))
    end
    
    SCPXP:SyncToClient(target)
end)

-- Backup and restore system
concommand.Add("scpxp_backup", function(ply, cmd, args)
    if not ply:IsSuperAdmin() then return end
    
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local filename = "scpxp_backup_" .. timestamp .. ".txt"
    
    -- Get all player data
    local result = sql.Query("SELECT * FROM scpxp_players")
    if not result then
        ply:ChatPrint("No data to backup")
        return
    end
    
    -- Save to file (you'd want to implement proper file handling)
    local backupData = util.TableToJSON(result)
    file.Write(filename, backupData)
    
    ply:ChatPrint("Backup saved as " .. filename .. " (" .. #result .. " players)")
end)

-- Import XP from external system (if migrating)
concommand.Add("scpxp_import", function(ply, cmd, args)
    if not ply:IsSuperAdmin() then return end
    if #args < 1 then
        ply:ChatPrint("Usage: scpxp_import <filename>")
        return
    end
    
    local filename = args[1]
    if not file.Exists(filename, "DATA") then
        ply:ChatPrint("File not found: " .. filename)
        return
    end
    
    local data = file.Read(filename, "DATA")
    local imported = util.JSONToTable(data)
    
    if not imported then
        ply:ChatPrint("Invalid file format")
        return
    end
    
    local count = 0
    for _, playerData in ipairs(imported) do
        -- Insert imported data
        sql.Query(string.format([[
            REPLACE INTO scpxp_players (
                steamid, nick, research_xp, security_xp, dclass_xp, scp_xp,
                research_level, security_level, dclass_level, scp_level,
                last_seen, total_playtime
            ) VALUES (
                '%s', %s, %d, %d, %d, %d, %d, %d, %d, %d, %s, %d
            )
        ]], playerData.steamid, sql.SQLStr(playerData.nick or "Unknown"),
            tonumber(playerData.research_xp) or 0, tonumber(playerData.security_xp) or 0,
            tonumber(playerData.dclass_xp) or 0, tonumber(playerData.scp_xp) or 0,
            tonumber(playerData.research_level) or 1, tonumber(playerData.security_level) or 1,
            tonumber(playerData.dclass_level) or 1, tonumber(playerData.scp_level) or 1,
            sql.SQLStr(playerData.last_seen or os.date("%Y-%m-%d %H:%M:%S")),
            tonumber(playerData.total_playtime) or 0))
        count = count + 1
    end
    
    ply:ChatPrint("Imported " .. count .. " player records")
    
    -- Reload data for online players
    for _, target in ipairs(player.GetAll()) do
        SCPXP:LoadPlayerData(target)
    end
end)

-- Maintenance commands
concommand.Add("scpxp_cleanup", function(ply, cmd, args)
    if not ply:IsSuperAdmin() then return end
    
    -- Clean up old log entries (older than 30 days)
    local deletedLogs = sql.Query("DELETE FROM scpxp_logs WHERE datetime(timestamp) < datetime('now', '-30 days')")
    
    -- Clean up players with 0 XP (optional)
    if args[1] == "zero_players" then
        local deletedPlayers = sql.Query("DELETE FROM scpxp_players WHERE research_xp + security_xp + dclass_xp + scp_xp = 0")
        ply:ChatPrint("Cleaned up players with 0 XP")
    end
    
    ply:ChatPrint("Database cleanup completed")
end)

-- Real-time XP tracking for admins
concommand.Add("scpxp_monitor", function(ply, cmd, args)
    if not table.HasValue(SCPXP.StaffRanks, ply:GetUserGroup()) then return end
    
    local target = ply
    if args[1] then
        target = player.GetByID(tonumber(args[1]))
    end
    
    if not IsValid(target) then
        ply:ChatPrint("Invalid player")
        return
    end
    
    -- Toggle monitoring
    ply.SCPXPMonitoring = ply.SCPXPMonitoring or {}
    
    if ply.SCPXPMonitoring[target:SteamID64()] then
        ply.SCPXPMonitoring[target:SteamID64()] = nil
        ply:ChatPrint("Stopped monitoring " .. target:Nick())
    else
        ply.SCPXPMonitoring[target:SteamID64()] = target
        ply:ChatPrint("Started monitoring " .. target:Nick() .. "'s XP gains")
    end
end)

-- Hook into XP gain to notify monitoring admins
hook.Add("SCPXP_XPGained", "SCPXP_NotifyMonitors", function(ply, category, amount, reason)
    for _, admin in ipairs(player.GetAll()) do
        if admin.SCPXPMonitoring and admin.SCPXPMonitoring[ply:SteamID64()] then
            admin:ChatPrint(string.format("[MONITOR] %s gained %d %s XP: %s", 
                ply:Nick(), amount, category, reason))
        end
    end
end)

-- Enhanced periodic XP save (every 5 minutes instead of only on disconnect)
timer.Create("SCPXP_PeriodicSave", 300, 0, function()
    local saved = 0
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply.SCPXPData then
            SCPXP:SavePlayerData(ply)
            saved = saved + 1
        end
    end
    
    if saved > 0 then
        print("[SCPXP] Periodic save completed for " .. saved .. " players")
    end
end)

-- XP Boost System (temporary multipliers)
SCPXP.ActiveBoosts = {}

function SCPXP:CreateXPBoost(category, multiplier, duration, reason)
    local boostId = "boost_" .. category .. "_" .. CurTime()
    
    self.ActiveBoosts[boostId] = {
        category = category,
        multiplier = multiplier,
        endTime = CurTime() + duration,
        reason = reason or "Server Boost"
    }
    
    -- Notify all players
    for _, ply in ipairs(player.GetAll()) do
        ply:ChatPrint(string.format("[SCPXP] %s XP boost active! %.1fx multiplier for %d minutes - %s", 
            self.Config.Categories[category].name, multiplier, math.floor(duration/60), reason))
    end
    
    -- Remove boost when expired
    timer.Simple(duration, function()
        if self.ActiveBoosts[boostId] then
            self.ActiveBoosts[boostId] = nil
            
            for _, ply in ipairs(player.GetAll()) do
                ply:ChatPrint(string.format("[SCPXP] %s XP boost has ended", 
                    self.Config.Categories[category].name))
            end
        end
    end)
    
    return boostId
end

function SCPXP:GetXPMultiplier(category)
    local multiplier = 1.0
    
    for _, boost in pairs(self.ActiveBoosts) do
        if boost.category == category and CurTime() < boost.endTime then
            multiplier = multiplier * boost.multiplier
        end
    end
    
    return multiplier
end

-- Override GiveXP to apply multipliers
local originalGiveXP = SCPXP.GiveXP
function SCPXP:GiveXP(ply, category, amount, reason)
    local multiplier = self:GetXPMultiplier(category)
    local finalAmount = math.floor(amount * multiplier)
    
    -- Call original function with boosted amount
    originalGiveXP(self, ply, category, finalAmount, reason)
    
    -- Fire hook for monitoring
    hook.Run("SCPXP_XPGained", ply, category, finalAmount, reason)
    
    -- Show boost notification if applicable
    if multiplier > 1.0 then
        net.Start("SCPXP_ShowBriefNotification")
            net.WriteString(string.format("Boost Applied! %.1fx multiplier", multiplier))
            net.WriteColor(Color(255, 215, 0))
        net.Send(ply)
    end
end

-- Boost commands
concommand.Add("scpxp_boost", function(ply, cmd, args)
    if not ply:IsSuperAdmin() then return end
    if #args < 3 then
        ply:ChatPrint("Usage: scpxp_boost <category> <multiplier> <minutes> [reason]")
        return
    end
    
    local category = args[1]
    local multiplier = tonumber(args[2])
    local minutes = tonumber(args[3])
    local reason = table.concat(args, " ", 4) or "Admin Boost"
    
    if not SCPXP.Config.Categories[category] then
        ply:ChatPrint("Invalid category: " .. category)
        return
    end
    
    if not multiplier or multiplier <= 0 then
        ply:ChatPrint("Invalid multiplier")
        return
    end
    
    if not minutes or minutes <= 0 then
        ply:ChatPrint("Invalid duration")
        return
    end
    
    local boostId = SCPXP:CreateXPBoost(category, multiplier, minutes * 60, reason)
    ply:ChatPrint(string.format("Created XP boost: %s %.1fx for %d minutes", 
        category, multiplier, minutes))
end)

concommand.Add("scpxp_boost_all", function(ply, cmd, args)
    if not ply:IsSuperAdmin() then return end
    if #args < 2 then
        ply:ChatPrint("Usage: scpxp_boost_all <multiplier> <minutes> [reason]")
        return
    end
    
    local multiplier = tonumber(args[1])
    local minutes = tonumber(args[2])
    local reason = table.concat(args, " ", 3) or "Server-Wide Boost"
    
    if not multiplier or multiplier <= 0 then
        ply:ChatPrint("Invalid multiplier")
        return
    end
    
    if not minutes or minutes <= 0 then
        ply:ChatPrint("Invalid duration")
        return
    end
    
    -- Create boost for all categories
    for category, _ in pairs(SCPXP.Config.Categories) do
        SCPXP:CreateXPBoost(category, multiplier, minutes * 60, reason)
    end
    
    ply:ChatPrint(string.format("Created server-wide XP boost: %.1fx for %d minutes", 
        multiplier, minutes))
end)

concommand.Add("scpxp_boosts", function(ply, cmd, args)
    if not table.HasValue(SCPXP.StaffRanks, ply:GetUserGroup()) then return end
    
    local count = 0
    ply:ChatPrint("=== Active XP Boosts ===")
    
    for boostId, boost in pairs(SCPXP.ActiveBoosts) do
        if CurTime() < boost.endTime then
            local remaining = math.floor((boost.endTime - CurTime()) / 60)
            ply:ChatPrint(string.format("%s: %.1fx multiplier (%d min remaining) - %s", 
                boost.category, boost.multiplier, remaining, boost.reason))
            count = count + 1
        end
    end
    
    if count == 0 then
        ply:ChatPrint("No active boosts")
    end
end)

-- Event System - Automatic XP events
SCPXP.Events = {}

function SCPXP:CreateXPEvent(name, description, duration, rewards)
    local eventId = "event_" .. string.lower(name):gsub(" ", "_") .. "_" .. CurTime()
    
    self.Events[eventId] = {
        name = name,
        description = description,
        endTime = CurTime() + duration,
        rewards = rewards, -- {category = {multiplier = 2.0, bonus = 50}}
        active = true
    }
    
    -- Announce event
    for _, ply in ipairs(player.GetAll()) do
        ply:ChatPrint(string.format("[SCPXP EVENT] %s has started! %s", name, description))
        
        -- Show detailed rewards
        for category, reward in pairs(rewards) do
            if reward.multiplier and reward.multiplier > 1 then
                ply:ChatPrint(string.format("- %s: %.1fx XP multiplier", 
                    SCPXP.Config.Categories[category].name, reward.multiplier))
            end
            if reward.bonus and reward.bonus > 0 then
                ply:ChatPrint(string.format("- %s: +%d bonus XP per gain", 
                    SCPXP.Config.Categories[category].name, reward.bonus))
            end
        end
    end
    
    -- End event automatically
    timer.Simple(duration, function()
        if self.Events[eventId] then
            self.Events[eventId].active = false
            
            for _, ply in ipairs(player.GetAll()) do
                ply:ChatPrint("[SCPXP EVENT] " .. name .. " has ended!")
            end
        end
    end)
    
    return eventId
end

-- Apply event bonuses to XP gains
hook.Add("SCPXP_XPGained", "SCPXP_ApplyEventBonuses", function(ply, category, amount, reason)
    for _, event in pairs(SCPXP.Events) do
        if event.active and CurTime() < event.endTime and event.rewards[category] then
            local reward = event.rewards[category]
            
            if reward.bonus and reward.bonus > 0 then
                SCPXP:GiveXP(ply, category, reward.bonus, "Event Bonus: " .. event.name)
            end
        end
    end
end)

concommand.Add("scpxp_event", function(ply, cmd, args)
    if not ply:IsSuperAdmin() then return end
    if #args < 3 then
        ply:ChatPrint("Usage: scpxp_event <name> <duration_minutes> <description>")
        ply:ChatPrint("Then use scpxp_event_reward to add rewards")
        return
    end
    
    local name = args[1]
    local minutes = tonumber(args[2])
    local description = table.concat(args, " ", 3)
    
    if not minutes or minutes <= 0 then
        ply:ChatPrint("Invalid duration")
        return
    end
    
    -- Create basic event (rewards added separately)
    local eventId = SCPXP:CreateXPEvent(name, description, minutes * 60, {})
    ply:ChatPrint("Created event: " .. name .. " (ID: " .. eventId .. ")")
    ply:ChatPrint("Use 'scpxp_event_reward " .. eventId .. " <category> <multiplier> [bonus]' to add rewards")
end)

print("[SCPXP] Server enhancements loaded successfully!")