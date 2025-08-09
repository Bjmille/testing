--[[

Author: tochnonement
Email: tochnonement@gmail.com

04/01/2024

--]]

onyx.f4.actions = {}

local CATEGORY = 'f4_general_u'

local L = function(...) return onyx.lang:Get(...) end

local CUSTOMCHECK_POLICE = function(client)
    return client:isCP()
end

local CUSTOMCHECK_MAYOR = function(client)
    return client:isMayor()
end

onyx.f4:RegisterAction({
    name = 'f4_action_drop_money',
    category = CATEGORY,
    func = function()
        onyx.SimpleQuery(
            L('f4_action_drop_money'),
            L('f4_action_input_amount'),
            true,
            function(value)
                RunConsoleCommand('darkrp', 'dropmoney', value)
            end, L('f4_confirm_u'),
            nil, L('f4_cancel_u')
        )
    end
})

onyx.f4:RegisterAction({
    name = 'f4_action_give_money',
    category = CATEGORY,
    func = function()
        onyx.SimpleQuery(
            L('f4_action_give_money'),
            L('f4_action_input_amount'),
            true,
            function(value)
                RunConsoleCommand('darkrp', 'give', value)
            end, L('f4_confirm_u'),
            nil, L('f4_cancel_u')
        )
    end
})

onyx.f4:RegisterAction({
    name = 'f4_action_change_name',
    category = CATEGORY,
    func = function()
        onyx.SimpleQuery(
            L('f4_action_change_name'),
            L('f4_action_input_text'),
            true,
            function(value)
                RunConsoleCommand('darkrp', 'rpname', value)
            end, L('f4_confirm_u'),
            nil, L('f4_cancel_u')
        )
    end
})

onyx.f4:RegisterAction({
    name = 'f4_action_drop_weapon',
    category = CATEGORY,
    func = function()
        RunConsoleCommand('darkrp', 'dropweapon')
    end
})

onyx.f4:RegisterAction({
    name = 'f4_action_sell_doors',
    category = CATEGORY,
    func = function()
        onyx.SimpleQuery(
            L('f4_action_sell_doors'),
            L('f4_action_confirm_action'),
            false,
            function()
                RunConsoleCommand('darkrp', 'sellalldoors')
            end, L('f4_confirm_u'),
            nil, L('f4_cancel_u')
        )
    end
})

CATEGORY = 'f4_police_u'

onyx.f4:RegisterAction({
    name = 'f4_action_warrant',
    category = CATEGORY,
    canSee = CUSTOMCHECK_POLICE,
    func = function()
        onyx.ChoosePlayer(
            L('f4_action_warrant'),
            L('f4_action_choose_player'),
            function(ply)
                local name = ply:Name()

                onyx.SimpleQuery(
                    L('f4_action_warrant'),
                    L('f4_action_input_reason'),
                    true,
                    function(reason)
                        RunConsoleCommand('darkrp', 'warrant', name, reason)
                    end
                )
            end
        )
    end
})

onyx.f4:RegisterAction({
    name = 'f4_action_wanted',
    category = CATEGORY,
    canSee = CUSTOMCHECK_POLICE,
    func = function()
        onyx.ChoosePlayer(
            L('f4_action_wanted'),
            L('f4_action_choose_player'),
            function(ply)
                local name = ply:Name()

                onyx.SimpleQuery(
                    L('f4_action_wanted'),
                    L('f4_action_input_reason'),
                    true,
                    function(reason)
                        RunConsoleCommand('darkrp', 'wanted', name, reason)
                    end
                )
            end
        )
    end
})

CATEGORY = 'f4_mayor_u'

onyx.f4:RegisterAction({
    name = 'f4_toggle_lockdown',
    category = CATEGORY,
    canSee = CUSTOMCHECK_MAYOR,
    func = function()
        if (GetGlobalBool('DarkRP_LockDown')) then
            RunConsoleCommand('darkrp', 'unlockdown')
        else
            RunConsoleCommand('darkrp', 'lockdown')
        end
    end
})

onyx.f4:RegisterAction({
    name = 'f4_give_license',
    category = CATEGORY,
    canSee = CUSTOMCHECK_MAYOR,
    func = function()
        RunConsoleCommand('darkrp', 'givelicense')
    end
})