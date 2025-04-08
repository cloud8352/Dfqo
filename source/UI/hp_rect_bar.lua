--[[
	desc: HpRectBar class.
	author: keke <243768648@qq.com>
	alter: 2023-9-15
]]
--

local Util = require("util.Util")

local Widget = require("UI.Widget")
local _Sprite = require("graphics.drawable.sprite")
local _Graphics = require("lib.graphics")
local Label = require("UI.Label")

local RightLabelWidth = 100

---@class HpRectBar : Widget
local HpRectBar = require("core.class")(Widget)

---@param parentWindow Window
function HpRectBar:Ctor(parentWindow)
    assert(parentWindow, "must assign parent window")
    RightLabelWidth = 100 * Util.GetWindowSizeScale()
    -- 父类构造函数
    Widget.Ctor(self, parentWindow)
    self:SetBgSpriteColor(0, 0, 0, 0)

    self.lastHp = 0
    self.currentHp = 0
    self.lastMaxHp = 0
    self.maxHp = 0
    self.rectSprite = _Sprite.New()
    self.textLabel = Label.New(parentWindow)

    self.rightLabel = Label.New(parentWindow)
    self.rightLabel:SetAlignments({ Label.AlignmentFlag.AlignLeft, Label.AlignmentFlag.AlignVCenter })
    self.rightLabel:SetSize(RightLabelWidth, 30 * Util.GetWindowSizeScale())
end

function HpRectBar:Update(dt)
    if (not self:IsVisible()) then
        return
    end

    if (self:IsSizeChanged()
            or self.lastHp ~= self.currentHp
            or self.lastMaxHp ~= self.maxHp
        )
    then
        self:updateSprite()

        self.textLabel:SetSize(self.width, self.height)

        self.rightLabel:SetSize(RightLabelWidth, self.height)
        self.rightLabel:SetIconSize(RightLabelWidth, self.height)
    end

    self.textLabel:Update(dt)
    self.rightLabel:Update(dt)

    self.lastHp = self.currentHp
    self.lastMaxHp = self.maxHp
    Widget.Update(self, dt)
end

function HpRectBar:Draw()
    if (not self:IsVisible()) then
        return
    end
    Widget.Draw(self)

    self.rectSprite:Draw()
    self.textLabel:Draw()
    self.rightLabel:Draw()
end

function HpRectBar:SetPosition(x, y)
    Widget.SetPosition(self, x, y)
    self.textLabel:SetPosition(x, y)
    self.rightLabel:SetPosition(self.xPos + self.width - RightLabelWidth,
        self.yPos)
end

function HpRectBar:SetSize(width, height)
    Widget.SetSize(self, width, height)
    self.textLabel:SetSize(width - RightLabelWidth, height)
    self.rightLabel:SetSize(RightLabelWidth, height)
end

function HpRectBar:SetEnable(enable)
    Widget.SetEnable(self, enable)
    self.textLabel:SetEnable(enable)
    self.rightLabel:SetEnable(enable)
end

---@param isVisible boolean
function HpRectBar:SetVisible(isVisible)
    Widget.SetVisible(self, isVisible)
    self.textLabel:SetVisible(isVisible)
    self.rightLabel:SetVisible(self.rightLabelVisible)
end

---@param hp integer
function HpRectBar:SetHp(hp)
    if self.currentHp == hp then
        return
    end
    self.currentHp = hp
    self.rightLabel:SetText(tostring(hp) .. "/" .. tostring(self.maxHp))
end

---@param maxHp integer
function HpRectBar:SetMaxHp(maxHp)
    self.maxHp = maxHp
    self.rightLabel:SetText(tostring(self.currentHp) .. "/" .. tostring(self.maxHp))
end

---@param isVisible boolean
function HpRectBar:SetRightLabelVisible(isVisible)
    self.rightLabelVisible = isVisible
    self.rightLabel:SetVisible(isVisible)
end

---@param text string
function HpRectBar:SetText(text)
    self.textLabel:SetText(text)
end

function HpRectBar:updateSprite()
    _Graphics.SaveCanvas()
    -- 创建背景画布
    local rightLabelWidth = 0
    if self.rightLabel:IsVisible() then
        local tmpH
        rightLabelWidth, tmpH = self.rightLabel:GetSize()
    end
    local canvas = _Graphics.NewCanvas(self.width - rightLabelWidth, self.height)
    _Graphics.SetCanvas(canvas)

    -- 先画血槽背景
    _Graphics.SetColor(10, 10, 10, 150)
    _Graphics.DrawRect(0, 0, self.width - rightLabelWidth, self.height, "fill")

    -- 再画血条
    _Graphics.SetColor(255, 0, 0, 200)
    local hpRectWidth = 0
    if self.maxHp ~= 0 then
        hpRectWidth = (self.width - rightLabelWidth) * (self.currentHp / self.maxHp)
    end
    _Graphics.DrawRect(0, 0, hpRectWidth, self.height, "fill")

    -- 还原绘图数据
    _Graphics.RestoreCanvas()

    self.rectSprite:SetImage(canvas)
    self.rectSprite:AdjustDimensions()
    self.rectSprite:SetAttri("position", self.xPos, self.yPos)
end

return HpRectBar
