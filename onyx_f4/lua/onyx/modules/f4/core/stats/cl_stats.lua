--[[

Author: tochnonement
Email: tochnonement@gmail.com

03/01/2024

--]]

netchunk.Callback('onyx.f4:SendStats', function(data)
    hook.Run('onyx.f4.StatsReceived', data)
end)