--[[
    desc: GRAPHICS, a lib that encapsulate love.graphics.
    author: Musoucrow
    since: 2018-3-13
    alter: 2018-8-8
]] --

local _TABLE = require("lib.table")
local _MATH = require("lib.math")

-- local Util = require("util.Util")

local _Tweener = require("util.gear.tweener")

local _nowShader
local _nowBlendmode = "alpha"
local _laterBlendmode
local _nowColor = { 255, 255, 255, 255 }
local _lateColor = { 255, 255, 255, 255 }
local _nowFont = love.graphics.getFont()
local _laterFont

local savedCanvas = nil

local _GRAPHICS = {} ---@class Lib.GRAPHICS

---@class Love.Object
local Object = {}
---@return string
function Object:type()
end

function Object:release()
end

---@class Love.Drawable : Love.Object
local Drawable = {}

---@class Love.Video : Love.Drawable
local Video = {}
---@return int
function Video:getHeight()
end
---@return int
function Video:getWidth()
end
---Gets whether the Video is currently playing
---@return boolean
function Video:isPlaying()
end
---Gets whether the Video is currently playing
---@return boolean
function Video:isPlaying()
end
function Video:pause()
end
function Video:play()
end
function Video:rewind()
end

---@class Love.Canvas : Love.Drawable
local Canvas = {}

---@return int
function Canvas:getHeight()
end
---@return int
function Canvas:getWidth()
end
--- Clears the contents of a Canvas to a specific color.
function Canvas:clear()
end

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
_GRAPHICS.Clear = love.graphics.clear

function _GRAPHICS.Init()
    love.graphics.setBackgroundColor(0, 0, 0, 255)
end

---@param text string
---@param x int
---@param y int
---@param r int Orientation (radians)
---@param sx int
---@param sy int
---@param ox int
---@param oy int
function _GRAPHICS.Print(text, x, y, r, sx, sy, ox, oy)
    love.graphics.print(text, x, y, r, sx, sy, ox, oy)
end

---@param text string
---@param x int
---@param y int
---@param limit int Wrap the line after this many horizontal pixels.
---@param align string center left right
---@param r int Orientation (radians)
---@param sx int
---@param sy int
---@param ox int
---@param oy int
---@param kx int Shearing factor (x-axis).
---@param ky int Shearing factor (y-axis).
function _GRAPHICS.PrintF(text, x, y, limit, align, r, sx, sy, ox, oy, kx, ky)
    love.graphics.printf(text, x, y, limit, align, r, sx, sy, ox, oy, kx, ky)
end

---@param shader Shader
function _GRAPHICS.SetShader(shader)
    if (_nowShader ~= shader) then
        love.graphics.setShader(shader)
        _nowShader = shader
    end
end

---@param blendmode string @Blendmode: "alpha" or "add" or "subtract" or "multiply" or "replace" or "screen"
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
        love.graphics.setColor(red / 255, green / 255, blue / 255, alpha / 255)

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

---@return love.Font font
function _GRAPHICS.GetFont()
    return _nowFont
end

---@return number height
function _GRAPHICS.GetFontHeight()
    return _nowFont:getHeight()
end

---@param text string
---@return number width
function _GRAPHICS.GetFontWidth(text)
    return _nowFont:getWidth(text)
end

---@param font love.Font
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

---@param x integer
---@param y integer
---@param size number
---@param mode string @DrawMode, value is: "fill" or "line"
function _GRAPHICS.DrawCircle(x, y, size, mode)
    mode = mode or "line"

    love.graphics.circle(mode, x, y, size)
end

---@param mode string @DrawMode, value is: "fill" or "line"
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
---@param drawable Love.Drawable A drawable object.
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

---@param width number
---@param height number
function _GRAPHICS.NewCanvas(width, height)
    -- print("NewCanvas")
    return love.graphics.newCanvas(width, height)
end

---@param canvas Love.Graphics.Canvas
function _GRAPHICS.SetCanvas(canvas)
    love.graphics.setCanvas(canvas)
end

---@return Love.Graphics.Canvas canvas
function _GRAPHICS.GetCanvas()
    return love.graphics.getCanvas()
end

---@param canvas Love.Graphics.Canvas
function _GRAPHICS.SaveCanvas()
    savedCanvas = _GRAPHICS.GetCanvas()
end

---@param canvas Love.Graphics.Canvas
function _GRAPHICS.RestoreCanvas()
    _GRAPHICS.SetCanvas(savedCanvas)
end

---@param filePath string
---@return Love.Video A drawable video
function _GRAPHICS.NewVideo(filePath)
    return love.graphics.newVideo(filePath)
end

return _GRAPHICS
