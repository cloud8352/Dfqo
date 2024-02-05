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

local _os = love.system.getOS()
local _stdWidth = 1280
local _stdHeight = 720
local _width, _height = love.graphics.getDimensions()

-- local _realWidth, _realHeight = _width, _height
local _screenDiv = { x = 0, y = 0 }

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

local _sx, _sy = _width / _stdWidth, _height / _stdHeight

local WhetherSetWindowToDefaultSize = true

local _SYSTEM = {} ---@class Lib.SYSTEM

---@return string @OS X, Windows, Linux, Android, iOS
function _SYSTEM.GetOS()
    return _os
end

---@return bool
function _SYSTEM.IsMobile()
    return true
    -- return _os == "Android" or _os == "iOS"
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

---@return int @w & h
function _SYSTEM.GetStdDimensions()
    return _stdWidth, _stdHeight
end

---@return int @w & h
function _SYSTEM.GetUIStdDimensions()
    return _stdWidth, _stdHeight
end

---@param w int
---@param h int
function _SYSTEM.OnResize(w, h)
    _width = w
    _height = h
    _sx = _width / _stdWidth
    _sy = _height / _stdHeight

    -- 设置字体
    --字体文件,支持中文 SourceHanSerifSC-Medium.otf yan_zhen_qing_kai_shu_font.TTF
    local font = love.graphics.newFont("asset/font/yan_zhen_qing_kai_shu_font.TTF", 16 * _sx)
    Graphics.SetFont(font)
end

function _SYSTEM.InitWindowSize()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    if (WhetherSetWindowToDefaultSize) then
        local _, _, flags = love.window.getMode()
        local screenW, screenH = love.window.getDesktopDimensions(flags.display)
        local percentage = 0.9

        windowWidth = screenW * percentage
        windowHeight = screenW * percentage * 9 / 16
        love.window.setMode(windowWidth, windowHeight, flags)

        -- 把窗口移到屏幕中央
        love.window.setPosition(screenW / 2 - windowWidth / 2, screenH / 2 - windowHeight / 2)
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

return _SYSTEM
