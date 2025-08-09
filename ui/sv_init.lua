util.AddNetworkString("exp_request_data")
util.AddNetworkString("exp_send_data")

-- Example XP storage structure:
-- ply.XPData = {
--     ["research"] = 125,
--     ["security"] = 300,
-- }

-- Calculates level based on XP
function GetLevelFromXP(category, xp)
    return math.floor(xp / 100) -- e.g. 100 XP per level
end

-- Calculates XP needed for next level
function GetXPForNextLevel(category, level)
    return 100 -- static for now; can be made dynamic later
end

-- Send XP data to a player
function SendXPData(ply)
    if not IsValid(ply) then return end

    local data = {}
    for category, xp in pairs(ply.XPData or {}) do
        local level = GetLevelFromXP(category, xp)
        local required = GetXPForNextLevel(category, level)

        data[category] = {
            xp = xp,
            level = level,
            required = required
        }
    end

    net.Start("exp_send_data")
    net.WriteTable(data)
    net.Send(ply)
end

-- When the client asks for XP data
net.Receive("exp_request_data", function(len, ply)
    SendXPData(ply)
end)

-- Optional: give XP to a player
function GivePlayerXP(ply, category, amount)
    if not IsValid(ply) then return end
    if not category then return end

    ply.XPData = ply.XPData or {}
    ply.XPData[category] = (ply.XPData[category] or 0) + amount

    SendXPData(ply) -- Update client UI
end

-- Example: Give 25 XP to players every 10 minutes
timer.Create("GiveTimeXP", 600, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        local teamName = team.GetName(ply:Team())
        local category = nil

        for jobID, catName in pairs(EXPConfig.JobCategories) do
            local jobConst = _G[jobID]
            if jobConst and jobConst == ply:Team() then
                category = catName
                break
            end
        end

        if category then
            GivePlayerXP(ply, category, EXPConfig.TimeXP or 25)
            ply:ChatPrint("[EXP] You gained " .. (EXPConfig.TimeXP or 25) .. " XP in " .. category)
        else
            print("[EXP] Skipping ", ply:Nick(), " - no category mapped for team: ", ply:Team())
        end
    end
end)
