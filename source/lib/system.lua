--[[
    desc: SYSTEM, a lib that encapsulate system and window function.
    author: Musoucrow
    since: 2018-5-27
    alter: 2019-10-8
]]
--

local _CONFIG = require("config")
local _FILE = require("lib.file")
local _TABLE = require("lib.table")
local Graphics = require("lib.graphics")
local String = require("lib.string")

local _os = love.system.getOS()
local _stdWidth = 1280
local _stdHeight = 720
local _width, _height = love.graphics.getDimensions()

-- local _realWidth, _realHeight = _width, _height
local _screenDiv = { x = 0, y = 0 }

--[[
do
    if ((_height / 9) ~= math.floor(_height / 9)) then
        local height = math.floor(_width / 16 * 9)
        _screenDiv.y = math.floor((_height - height) * 0.5)
        _height = height
    else
        local width = math.floor((_height / 9) * 16)
        _screenDiv.x = math.floor((_width - width) * 0.5)
        _width = width
    end
end
--]]

local _sx, _sy = _width / _stdWidth, _height / _stdHeight

local WhetherSetWindowToDefaultSize = true
local WindowsOsDpi = 1.0

local _SYSTEM = {} ---@class Lib.SYSTEM

function _SYSTEM.Init()
    -- _SYSTEM.initWindowOsDpi()
    _SYSTEM.initWindowSize()

    -- 把窗口移到屏幕中央
    local _, _, flags = love.window.getMode()
    local screenW, screenH = love.window.getDesktopDimensions(flags.display)
    love.window.setPosition(screenW / 2 - _width / 2, screenH / 2 - _height / 2 - 40 * _sy)
end

---@return string @OS X, Windows, Linux, Android, iOS
function _SYSTEM.GetOS()
    return _os
end

---@return boolean
function _SYSTEM.IsMobile()
    -- return true
    return _os == "Android" or _os == "iOS"
end

---@return boolean
function _SYSTEM.IsWindowsOs()
    return _os == "Windows"
end

---@param isReal boolean
---@return int @w & h
function _SYSTEM.GetWindowDimensions(notReal)
    if (notReal) then
        return _width, _height
    else
        return _width, _height
    end
end

---@return number w
---@return number h
function _SYSTEM.GetStdDimensions()
    return _stdWidth, _stdHeight
end

---@return number w
---@return number h
function _SYSTEM.GetUIStdDimensions()
    return _stdWidth, _stdHeight
end

---@param w number
---@param h number
function _SYSTEM.OnResize(w, h)
    _width = w
    _height = h
    _sx = _width / _stdWidth
    _sy = _height / _stdHeight

    -- 设置字体
    --字体文件,支持中文 SourceHanSerifSC-Medium.otf yan_zhen_qing_kai_shu_font.TTF
    local font = love.graphics.newFont("asset/font/yan_zhen_qing_kai_shu_font.TTF", 16 * _sx * WindowsOsDpi)
    Graphics.SetFont(font)
end

function _SYSTEM.initWindowSize()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local whetherWindowIsFullScreen = love.window.getFullscreen()
    if (WhetherSetWindowToDefaultSize and
            not whetherWindowIsFullScreen and
            not _SYSTEM.IsMobile()
        ) then
        local _, _, flags = love.window.getMode()
        local screenW, screenH = love.window.getDesktopDimensions(flags.display)
        local percentage = 0.85

        windowWidth = screenW * percentage
        windowHeight = screenW * percentage * 9 / 16
        love.window.setMode(windowWidth, windowHeight, flags)
    end

    _SYSTEM.OnResize(windowWidth, windowHeight)
end

function _SYSTEM.Collect()
    collectgarbage("collect")
end

---@return number, number
function _SYSTEM.GetScale()
    return _sx, _sy
end

---@return int, int
function _SYSTEM.GetScreenDiv()
    return _screenDiv.x, _screenDiv.y
end

function _SYSTEM.GetWindowsOsDpi()
    return WindowsOsDpi
end

function _SYSTEM.initWindowOsDpi()
    if _SYSTEM.IsWindowsOs() then
        local file = io.open("realWindowsOsScreenWidth.tmp", "r")
        if nil == file then
            print("_SYSTEM.initWindowOsDpi()" .. "open realWindowsOsScreenWidth.tmp failed!")
            return
        end

        local output = file:read('*a')
        local strList = String.Split(output, "\n")
        if strList[1] ~= "ScreenWidth" then
            return
        end

        local realWindowsOsScreenWidth = tonumber(strList[2]) or 0
        if realWindowsOsScreenWidth < 1 then
            return
        end
        -- 计算dpi
        local _, _, flags = love.window.getMode()
        local screenW, _ = love.window.getDesktopDimensions(flags.display)
        WindowsOsDpi = realWindowsOsScreenWidth / screenW
    end
end

return _SYSTEM
