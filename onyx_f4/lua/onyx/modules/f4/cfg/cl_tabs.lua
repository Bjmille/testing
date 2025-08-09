--[[

Author: tochnonement
Email: tochnonement@gmail.com

30/12/2023

--]]

onyx.f4.tabs = {}

onyx.f4:RegisterTab('dashboard', {
    order = 1,
    name = 'f4_dashboard_u',
    desc = 'f4_dashboard_desc',
    icon = 'https://i.imgur.com/L6Dbwjm.png',
    class = 'onyx.f4.Dashboard'
})

onyx.f4:RegisterTab('jobs', {
    order = 2,
    name = 'f4_jobs_u',
    desc = 'f4_jobs_desc',
    icon = 'https://i.imgur.com/B5jmfXa.png',
    class = 'onyx.f4.Jobs'
})

onyx.f4:RegisterTab('shop', {
    order = 3,
    name = 'f4_shop_u',
    desc = 'f4_shop_desc',
    icon = 'https://i.imgur.com/duyBVAS.png',
    class = 'onyx.f4.Shop'
})

