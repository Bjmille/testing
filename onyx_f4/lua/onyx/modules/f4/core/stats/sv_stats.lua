--[[

Author: tochnonement
Email: tochnonement@gmail.com

03/01/2024

--]]

util.AddNetworkString('onyx.f4:RequestStats')

local DAY_SECONDS = (24 * 60 * 60)
local recordQueue = {}

do
    local q = onyx.f4.db:Create('onyx_f4_object_stats')
        q:Create('objectType', 'VARCHAR(64) NOT NULL')
        q:Create('objectID', 'VARCHAR(64) NOT NULL')
        q:Create('amount', 'INT NOT NULL')
        q:Create('unixDate', 'INT NOT NULL')
        q:Callback(function()
            onyx.f4:Print('Initialized stats database table.')
        end)
    q:Execute()
end

-- Less calls to the database
local function queueObjectRecord(objectType, objectID)
    if (not objectType) then return end
    if (not objectID) then return end

    if (not recordQueue[objectType]) then
        recordQueue[objectType] = {}
    end

    local objectCache = recordQueue[objectType]

    objectCache[objectID] = (objectCache[objectID] or 0) + 1
end

-- Excludes both hours and minutes
local function getTodayUnixTime()
    local curTimeTable = os.date('*t')
    local newUnixTime = os.time({
        day = curTimeTable.day,
        month = curTimeTable.month,
        year = curTimeTable.year
    })

    return newUnixTime
end

local function clearOldRecords()
    local todayUnixDate = getTodayUnixTime()
    local oldUnixDate = todayUnixDate - DAY_SECONDS * 31

    onyx.f4.db:Queue(string.format([[
        DELETE FROM `onyx_f4_object_stats`
            WHERE `unixDate` <= %d;
    ]], oldUnixDate), function()
        onyx.f4:Print('Cleared old records')
    end)
end
hook.Add('InitPostEntity', 'onyx.f4.ClearOldStats', clearOldRecords)

local function addObjectRecord(objectType, objectID, toAddAmount)
    local unixDate = getTodayUnixTime()
    local toAddAmount = toAddAmount or 1

    -- this got queued anyway
    local q = onyx.f4.db:Select('onyx_f4_object_stats')
        q:Where('objectType', objectType)
        q:Where('objectID', objectID)
        q:Where('unixDate', unixDate)
        q:Limit(1)
        q:Callback(function(result)
            local hasRecord = istable(result) and result[1]

            if (hasRecord) then
                local amount = result[1].amount
                local q = onyx.f4.db:Update('onyx_f4_object_stats')
                    q:Update('amount', (amount + toAddAmount))
                    q:Where('objectType', objectType)
                    q:Where('objectID', objectID)
                    q:Where('unixDate', unixDate)
                    q:Limit(1)
                q:Execute()
            else
                local q = onyx.f4.db:Insert('onyx_f4_object_stats')
                    q:Insert('objectType', objectType)
                    q:Insert('objectID', objectID)
                    q:Insert('amount', toAddAmount)
                    q:Insert('unixDate', unixDate)
                q:Execute()
            end
        end)
    q:Execute()
end

hook.Add('OnPlayerChangedTeam', 'onyx.f4.stats', function(ply, oldTeam, newTeam)
    local jobData = RPExtraTeams[newTeam]
    if (jobData) then
        local jobID = jobData.command
        queueObjectRecord('job', jobID)
    end
end)

do
    local OBJECTS = {
        ['entity'] = 'playerBoughtCustomEntity',
        ['gun'] = 'playerBoughtPistol',
        ['shipment'] = 'playerBoughtShipment',
    }

    for objectID, hookName in pairs(OBJECTS) do
        hook.Add(hookName, 'onyx.f4.stats', function(ply, item)
            if (istable(item)) then
                queueObjectRecord(objectID, (item.ent or item.entity))
            end
        end)
    end
end

timer.Create('onyx.f4.ProcessStatsQueue', 1, 0, function()
    if (not table.IsEmpty(recordQueue)) then
        for objectType, objects in pairs(recordQueue) do
            for objectID, amount in pairs(objects) do
                addObjectRecord(objectType, objectID, amount)
            end
        end

        recordQueue = {}
    end
end)

local function fetchObjectsData(objectType, timeRange, callback)
    local todayUnix = getTodayUnixTime()
    local minRange = todayUnix - timeRange

    onyx.f4.db:Queue(string.format([[
        SELECT objectID, SUM(amount) as amount FROM `onyx_f4_object_stats`
            WHERE `unixDate` >= %d AND `objectType` = '%s'
            GROUP BY `objectID`;
    ]], minRange, onyx.f4.db:Escape(objectType)), function(result)
        callback(result or {})
    end)
end

net.Receive('onyx.f4:RequestStats', function(len, ply)
    if ((ply.onyx_f4_NextNetRequest or 0) > CurTime()) then
        return
    end

    ply.onyx_f4_NextNetRequest = CurTime() + .33

    local objectType = net.ReadString()
    local timeID = net.ReadUInt(2)
    local timeRange = 0

    if (timeID == 1) then
        timeRange = DAY_SECONDS * 7
    elseif (timeID == 2) then
        timeRange = DAY_SECONDS * 30
    end

    CAMI.PlayerHasAccess(ply, 'onyx_f4_edit', function(bHasAccess)
        if (bHasAccess) then
            fetchObjectsData(objectType, timeRange, function(result)
                if (IsValid(ply)) then
                    netchunk.Send(ply, 'onyx.f4:SendStats', {
                        timeID = timeID,
                        objectType = objectType,
                        result = result
                    })
                end
            end)
        else
            -- increase delay
            ply.onyx_f4_NextNetRequest = CurTime() + 1
        end
    end)
end)