--[[
	desc: Util, A common utility.
	author: keke
	since: 20122-12-10
	alter: 20122-12-10
]] --

local System = require("lib.system")
local _TABLE = require("lib.table")
local _SOUND = require("lib.sound")

local Util = {}

-- 获取窗口缩放比例
function Util.GetWindowSizeScale()
    local sx, _ = System.GetScale()
    return sx
end

---@return number
function Util.GetWindowHeight()
    local width, height, flags = love.window.getMode()
    return height
end

---@return number
function Util.GetWindowWidth()
    local width, height, flags = love.window.getMode()
    return width
end

---@param soundDataSet table
---@param gender number @ 1 - male, 2 - female
function Util.RandomPlaySoundByGender(soundDataSet, gender)
    ---@type table<number, SoundData>
    local soundDataList = {}
    if gender == 1 then
        soundDataList = soundDataSet.voice
    else
        soundDataList = soundDataSet.femaleVoice
    end
    if soundDataList == nil then
        return
    end
    local n = math.random(1, _TABLE.Len(soundDataList))
    _SOUND.Play(soundDataList[n])
end

---@param soundDataSet table
---@param index number
---@param gender number @ 1 - male, 2 - female
function Util.PlaySoundByGender(soundDataSet, index, gender)
    ---@type table<number, SoundData>
    local soundDataList = {}
    if gender == 1 then
        soundDataList = soundDataSet.voice
    else
        soundDataList = soundDataSet.femaleVoice
    end
    if (soundDataList and #soundDataList > 0) then
        _SOUND.Play(soundDataList[index])
    end
end

---@param w Window
function Util.MoveWindowToCenter(w)
    local mainWindowWidth = Util.GetWindowWidth()
    local mainWindowHeight = Util.GetWindowHeight()
    local width, height = w:GetSize()
    w:SetPosition((mainWindowWidth - width) / 2, (mainWindowHeight - height) / 2)
end

return Util
