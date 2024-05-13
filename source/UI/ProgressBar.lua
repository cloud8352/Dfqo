--[[
	desc: ProgressBar class.
	author: keke <243768648@qq.com>
]]
--

local Util = require("util.Util")

local _Sprite = require("graphics.drawable.sprite")
local _Graphics = require("lib.graphics")

local Widget = require("UI.Widget")
local Label = require("UI.Label")

---@class ProgressBar
local ProgressBar = require("core.class")(Widget)

---@param parentWindow Window
function ProgressBar:Ctor(parentWindow)
    assert(parentWindow, "must assign parent window")
    -- 父类构造函数
    Widget.Ctor(self, parentWindow)

    self.lastProgress = 0.0
    self.currentProgress = 0.0
    self.barColor = { r = 100, g = 40, b = 55, a = 255 }
    self.rectSprite = _Sprite.New()

    self.textLabel = Label.New(parentWindow)
end

function ProgressBar:Update(dt)
    if (not Widget.IsVisible(self)) then
        return
    end

    if (Widget.IsSizeChanged(self)
            or math.abs(self.lastProgress - self.currentProgress) > 0.001
        )
    then
        self:updateSprite()

        local width, height = Widget.GetSize(self)
        self.textLabel:SetSize(width, height)
    end

    self.textLabel:Update(dt)
    Widget.Update(self, dt)
    self.lastProgress = self.currentProgress
end

function ProgressBar:Draw()
    if (not Widget.IsVisible(self)) then
        return
    end

    Widget.Draw(self)
    self.rectSprite:Draw()
    self.textLabel:Draw()
end

---@param x int
---@param y int
function ProgressBar:SetPosition(x, y)
    Widget.SetPosition(self, x, y)

    local xPos, yPos = Widget.GetPosition(self)
    self.rectSprite:SetAttri("position", xPos, yPos)
    self.textLabel:SetPosition(x, y)
end

function ProgressBar:GetPosition()
    return Widget.GetPosition(self)
end

function ProgressBar:SetSize(width, height)
    Widget.SetSize(self, width, height)

    self.textLabel:SetSize(width, height)
end

function ProgressBar:SetEnable(enable)
    Widget.SetEnable(self, enable)

    self.textLabel:SetEnable(enable)
end

---@param isVisible boolean
function ProgressBar:SetVisible(isVisible)
    Widget.SetVisible(self, isVisible)

    self.textLabel:SetVisible(isVisible)
end

---@param red integer
---@param green integer
---@param blue integer
---@param alpha integer
function ProgressBar:SetBarColor(red, green, blue, alpha)
    self.barColor.r = red
    self.barColor.g = green
    self.barColor.b = blue
    self.barColor.a = alpha

    self:updateSprite()
end

---@param progress number
function ProgressBar:SetProgress(progress)
    if (math.abs(self.currentProgress - progress) < 0.001) then
        return
    end
    self.currentProgress = progress
end

---@param text string
function ProgressBar:SetText(text)
    self.textLabel:SetText(text)
end

function ProgressBar:updateSprite()
    _Graphics.SaveCanvas()
    -- 创建背景画布
    local width, height = Widget.GetSize(self)
    local canvas = _Graphics.NewCanvas(width, height)
    _Graphics.SetCanvas(canvas)

    -- 先画背景
    _Graphics.SetColor(10, 10, 10, 150)
    _Graphics.DrawRect(0, 0, width, height, "fill")

    -- 再画进度条
    _Graphics.SetColor(self.barColor.r, self.barColor.g, self.barColor.b, self.barColor.a)
    local rectWidth = 0
    if self.maxHp ~= 0 then
        rectWidth = width * self.currentProgress
    end
    _Graphics.DrawRect(0, 0, rectWidth, height, "fill")

    -- 还原绘图数据
    _Graphics.RestoreCanvas()

    self.rectSprite:SetImage(canvas)
    self.rectSprite:AdjustDimensions()
end

return ProgressBar
