--[[
    desc: GRAPHICS, a lib that encapsulate love.graphics.
    author: Musoucrow
    since: 2018-3-13
    alter: 2018-8-8
]] --

local _TABLE = require("lib.table")
local _MATH = require("lib.math")
local _SYSTEM = require("lib.system")

local Util = require("source.util.Util")

local _Tweener = require("util.gear.tweener")

local _nowShader
local _nowBlendmode = "alpha"
local _laterBlendmode
local _nowColor = { 255, 255, 255, 255 }
local _lateColor = { 255, 255, 255, 255 }
local _nowFont = love.graphics.getFont()
local _laterFont

local _GRAPHICS = {} ---@class Lib.GRAPHICS
_GRAPHICS.Print = love.graphics.print
_GRAPHICS.SetScissor = love.graphics.setScissor
_GRAPHICS.DrawLine = love.graphics.line
_GRAPHICS.Push = love.graphics.push
_GRAPHICS.Pop = love.graphics.pop
_GRAPHICS.Scale = love.graphics.scale
_GRAPHICS.Translate = love.graphics.translate
_GRAPHICS.Rotate = love.graphics.rotate
_GRAPHICS.Stencil = love.graphics.stencil
_GRAPHICS.SetStencilTest = love.graphics.setStencilTest
_GRAPHICS.SetLineWidth = love.graphics.setLineWidth
_GRAPHICS.GetLineWidth = love.graphics.getLineWidth
_GRAPHICS.NewCanvas = love.graphics.newCanvas
_GRAPHICS.SetCanvas = love.graphics.setCanvas
_GRAPHICS.Clear = love.graphics.clear

function _GRAPHICS.Init()
    love.graphics.setBackgroundColor(0, 0, 0, 255)

    local windowSizeScale = Util.GetWindowSizeScale()

    -- 设置初始适合的窗口大小
    local _, _, flags = love.window.getMode()
    local windowWidth = 1600 * windowSizeScale
    local windowHeight = 900 * windowSizeScale
    love.window.setMode(windowWidth, windowHeight, flags)
    _SYSTEM.OnResize(windowWidth, windowHeight)

    -- 把窗口移到屏幕中央
    local screenW, screenH = love.window.getDesktopDimensions(flags.display)
    love.window.setPosition(screenW / 2 - windowWidth / 2, screenH / 2 - windowHeight / 2)

    -- 设置字体
    --字体文件,支持中文 SourceHanSerifSC-Medium.otf yan_zhen_qing_kai_shu_font.TTF
    local font = love.graphics.newFont("asset/font/yan_zhen_qing_kai_shu_font.TTF", 16 * windowSizeScale)
    _GRAPHICS.SetFont(font)
end

---@param shader Shader
function _GRAPHICS.SetShader(shader)
    if (_nowShader ~= shader) then
        love.graphics.setShader(shader)
        _nowShader = shader
    end
end

---@param blendmode Blendmode @alpha, add, subtract, multiply, replace, screen
function _GRAPHICS.SetBlendmode(blendmode)
    if (_nowBlendmode ~= blendmode) then
        love.graphics.setBlendMode(blendmode)
        _laterBlendmode = _nowBlendmode
        _nowBlendmode = blendmode
    end
end

function _GRAPHICS.ResetBlendmode()
    _GRAPHICS.SetBlendmode(_laterBlendmode)
end

---@param red integer
---@param green integer
---@param blue integer
---@param alpha integer
function _GRAPHICS.SetColor(red, green, blue, alpha)
    if (_nowColor[1] ~= red or _nowColor[2] ~= green or _nowColor[3] ~= blue or _nowColor[4] ~= alpha) then
        love.graphics.setColor(red, green, blue, alpha)

        _TABLE.Paste(_nowColor, _lateColor)

        _nowColor[1] = red
        _nowColor[2] = green
        _nowColor[3] = blue
        _nowColor[4] = alpha
    end
end

function _GRAPHICS.ResetColor()
    _GRAPHICS.SetColor(unpack(_lateColor))
end

function _GRAPHICS.GetColor()
    return unpack(_nowColor)
end

---@return font Font
function _GRAPHICS.GetFont()
    return _nowFont
end

---@return height number
function _GRAPHICS.GetFontHeight()
    return _nowFont:getHeight()
end

---@param text string
---@return Width number
function _GRAPHICS.GetFontWidth(text)
    return _nowFont:getWidth(text)
end

---@param font Font
function _GRAPHICS.SetFont(font)
    if (_nowFont ~= font) then
        _laterFont = _nowFont
        _nowFont = font
        love.graphics.setFont(font)
    end
end

function _GRAPHICS.ResetFont()
    _GRAPHICS.SetFont(_laterFont)
end

---@param x int
---@param y int
---@param size number
---@param mode DrawMode @fill, line
function _GRAPHICS.DrawCircle(x, y, size, mode)
    mode = mode or "line"

    love.graphics.circle(mode, x, y, size)
end

---@param mode DrawMode @fill, line
function _GRAPHICS.DrawPolygon(mode, ...)
    love.graphics.polygon(mode, ...)
end

---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@param mode DrawMode @"fill" or "line"
function _GRAPHICS.DrawRect(x, y, w, h, mode)
    mode = mode or "line"

    love.graphics.rectangle(mode, x, y, w, h)
end

---@param drawable Graphics.Drawable
function _GRAPHICS.NewDrawableAttriTweener(drawable, subject, type)
    return _Tweener.New(subject, _, _, function()
        drawable:SetAttri(type, subject:Get())
    end)
end

---@param text string
---@return love.Text
function _GRAPHICS.NewNormalText(text)
    local font = love.graphics.getFont()
    local drawableTextObj = love.graphics.newText(font, text)
    return drawableTextObj
end

--- 画物体
---@param drawable love.Drawable A drawable object.
---@param x number The position to draw the object (x-axis).
---@param y number The position to draw the object (y-axis).
---@param r number Orientation (radians).
---@param sx number Scale factor (x-axis).
---@param sy number Scale factor (y-axis).
---@param ox number Origin offset (x-axis).
---@param oy number Origin offset (y-axis).
---@param kx number Shearing factor (x-axis). can nil
---@param ky number Shearing factor (x-axis). can nil
function _GRAPHICS.DrawObj(drawable, x, y, r, sx, sy, ox, oy, kx, ky)
    love.graphics.draw(drawable, x, y, r, sx, sy, ox, oy, kx, ky)
end

return _GRAPHICS
