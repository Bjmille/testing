--[[

Author: tochnonement
Email: tochnonement@gmail.com

25/12/2023

--]]

onyx.f4:Print('Loaded SQL configuration.')

local MySQL = {Credentials = {}}

-- Enable MySQL
-- (requires `mysqloo` module and mysql database)
MySQL.Enabled = false

-- MySQL Credentials
MySQL.Credentials.Hostname  = 'localhost'
MySQL.Credentials.Username  = 'username'
MySQL.Credentials.Password  = 'password'
MySQL.Credentials.Schema    = 'example'
MySQL.Credentials.Port      = 3306

--[[------------------------------
DO NOT TOUCH STUFF BELOW
--------------------------------]]
onyx.f4:SetupDatabase(MySQL.Enabled, MySQL.Credentials)