--[[
	desc: CONFIG, a data set.
	author: Musoucrow
	since: 2018-5-22
	alter: 2019-8-14
]] --
local _FILE = require("lib.file")

---@class CONFIG
---@field user User
local _CONFIG = {
    setting = {
        version = 1,
        hasModify = false,
        language = "cn",
        music = 0.3,
        sound = 1,
        digit = true,
        shadow = true
    },
    debug = {
        point = false,
        collider = false, -- 碰撞起调试开关
        ai = false,
        fps = false,
        bgm = true,
        transparency = false,
        transport = false,
        ui = true,
        map = {
            object = false,
            up = false,
            down = false,
            obstacle = false
        }
    }
}

_CONFIG.arrow = { "up", "down", "left", "right" }

_CONFIG.code = {
    up = "up",
    down = "down",
    left = "left",
    right = "right",
    getItem = "lctrl",
    goNext = "lshift",
    talk = "space",
    normalAttack = "x",
    jump = "c",
    counterAttack = "z",
    skill1 = "a",
    skill2 = "s",
    skill3 = "d",
    skill4 = "f",
    skill5 = "g",
    skill6 = "h",
    skill7 = "q",
    skill8 = "w",
    skill9 = "e",
    skill10 = "r",
    skill11 = "t",
    skill12 = "y",
    suptool1 = "q",
    suptool2 = "w",
    dash = "v",
    DockItem1 = "1",
    DockItem2 = "2",
    DockItem3 = "3",
    DockItem4 = "4",
    DockItem5 = "5",
    DockItem6 = "6",
}

_CONFIG.anticode = {}

_CONFIG.ConfigDirPath = "config/"
_CONFIG.DefaultSettingsFileName = "DefaultSettings.cfg"
_CONFIG.SettingsFileName = "Settings.cfg"

-- 加载用户配置
local userConfigs = nil
local settingsFilePath = _CONFIG.ConfigDirPath .. _CONFIG.SettingsFileName
if (_FILE.Exists(settingsFilePath)) then
    local content = _FILE.ReadFile(settingsFilePath)
    userConfigs = loadstring(content)()
end

--- 将a表的简单数据复制到b表
---@param a table
---@param b table
local function tableSimpleCopy(a, b)
    for k, v in pairs(a) do
        if type(v) ~= "table" then
            b[k] = v
        end
    end
end

if userConfigs and userConfigs.setting then
    local userData = userConfigs.setting
    local setting = _CONFIG.setting

    tableSimpleCopy(userData, setting)
end

if userConfigs and userConfigs.debug then
    local userData = userConfigs.debug
    local debug = _CONFIG.debug
    tableSimpleCopy(userData, debug)

    if userData.map then
        local userData2 = userData.map
        local map = debug.map
        tableSimpleCopy(userData2, map)
    end
end

if userConfigs and userConfigs.arrow then
    local userData = userConfigs.arrow
    local arrow = _CONFIG.arrow
    tableSimpleCopy(userData, arrow)
end

if userConfigs and userConfigs.code then
    local userData = userConfigs.code
    local code = _CONFIG.code
    tableSimpleCopy(userData, code)
end

for k, v in pairs(_CONFIG.code) do
    _CONFIG.anticode[v] = k
end

return _CONFIG
