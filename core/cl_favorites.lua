--[[

Author: tochnonement
Email: tochnonement@gmail.com

12/01/2024

--]]

onyx.f4.favorites = onyx.f4.favorites or {}

file.CreateDir('onyx_f4_favorites')

local function getFileName()
    local ip = game.GetIPAddress()
    return string.Explode(':', ip:gsub('%.', '_'))[1]
end

local function saveFavorites()
    local name = getFileName()

    file.Write('onyx_f4_favorites/' .. name .. '.json', util.TableToJSON(onyx.f4.favorites))
end

local function loadFavorites()
    local name = getFileName()
    local content = file.Read('onyx_f4_favorites/' .. name .. '.json', 'DATA')
    if (content) then
        local success, data = pcall(util.JSONToTable, content)
        if (success) then
            onyx.f4.favorites = data
        else
            onyx.f4:PrintError('Failed to load favorites.')
            print(data)
        end
    end
end
hook.Add('InitPostEntity', 'onyx.f4.LoadFavorites', loadFavorites)

function onyx.f4:SetFavorite(itemIdentifier, bState)
    self.favorites[itemIdentifier] = bState
    saveFavorites()
end

function onyx.f4:IsFavorite(itemIdentifier)
    return self.favorites[itemIdentifier]
end

function onyx.f4:FetchFavoriteObjects(itemType)
    local categories = DarkRP.getCategories()[itemType]
    if (not categories) then return false end

    local client = LocalPlayer()
    local clientTeam = client:Team()
    local showUnavailable = onyx.f4:GetOptionValue('job_show_unavailable')
    local showWrong = onyx.f4:GetOptionValue('job_show_requirejob')
    local result = {}

    for _, cat in ipairs(categories) do
        if ( cat.canSee and not cat.canSee( client ) ) then continue end

        for _, member in ipairs(cat.members or {}) do
            local id = (member.command or member.ent or member.entity or member.name)
            local customCheck = member.customCheck
            local needToChangeFrom = member.NeedToChangeFrom
            local allowed = member.allowed
            local reason

            if (customCheck and not customCheck(client)) then
                if (showUnavailable) then
                    reason = onyx.lang:Get('f4_unavailable')
                else
                    continue
                end
            end

            if (needToChangeFrom and needToChangeFrom ~= clientTeam) then
                if (showWrong) then
                    reason = onyx.lang:Get('f4_unavailable')
                else
                    continue
                end
            end

            if (allowed and not table.HasValue(allowed, clientTeam)) then
                continue
            end

            if (self:IsFavorite(id)) then
                table.insert(result, {
                    job = member,
                    item = member,
                    reason = reason
                })
            end
        end
    end

    return result
end