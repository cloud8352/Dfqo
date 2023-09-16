--[[
	desc: HpRectBar class.
	author: keke <243768648@qq.com>
	alter: 2023-9-15
]] --

local Widget = require("UI.Widget")
local _Sprite = require("graphics.drawable.sprite")
local _Graphics = require("lib.graphics")
local Label = require("UI.Label")

local RightLabelWidth = 100

---@class HpRectBar
local HpRectBar = require("core.class")(Widget)

---@param parentWindow Window
function HpRectBar:Ctor(parentWindow)
    assert(parentWindow, "must assign parent window")
    -- 父类构造函数
    Widget.Ctor(self, parentWindow)
    self.baseWidget = Widget.New(parentWindow)

    self.baseWidget.width = 100
    self.baseWidget.height = 20

    self.lastHp = 0
    self.currentHp = 0
    self.lastMaxHp = 0
    self.maxHp = 0
    self.rectSprite = _Sprite.New()
    self.rightLabel = Label.New(parentWindow)
    self.rightLabel:SetAlignments({Label.AlignmentFlag.AlignLeft, Label.AlignmentFlag.AlignVCenter})
    self.rightLabel:SetSize(RightLabelWidth, 30)
end

function HpRectBar:Update(dt)
    if (self.baseWidget:IsBaseDataChanged()
        or self.lastHp ~= self.currentHp
        or self.lastMaxHp ~= self.maxHp
        )
        then
        self:updateSprite()

        self.rightLabel:SetPosition(self.baseWidget.xPos + self.baseWidget.width - RightLabelWidth,
                                    self.baseWidget.yPos)
        self.rightLabel:SetSize(RightLabelWidth, self.baseWidget.height)
        self.rightLabel:SetIconSize(RightLabelWidth, self.baseWidget.height)
    end

    self.rightLabel:Update(dt)

    self.baseWidget:Update(dt)
    self.lastHp = self.currentHp
    self.lastMaxHp = self.maxHp
end

function HpRectBar:Draw()
    self.baseWidget:Draw()
    self.rectSprite:Draw()
    self.rightLabel:Draw()
end

function HpRectBar:SetPosition(x, y)
    self.baseWidget:SetPosition(x, y)
end

function HpRectBar:SetSize(width, height)
    self.baseWidget:SetSize(width, height)
    self.rightLabel:SetSize(RightLabelWidth, height)
end

function HpRectBar:SetEnable(enable)
    self.baseWidget:SetEnable(enable)
    self.rightLabel:SetEnable(enable)
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

function HpRectBar:updateSprite()
    -- 创建背景画布
    local rightLabelWidth, _ = self.rightLabel:GetSize()
    local canvas = _Graphics.NewCanvas(self.baseWidget.width - rightLabelWidth, self.baseWidget.height)
    _Graphics.SetCanvas(canvas)
    local originColorR, originColorG, originColorB, originColorA = _Graphics.GetColor()

    -- 先画血槽背景
    _Graphics.SetColor(10, 10, 10, 150)
    _Graphics.DrawRect(0, 0, self.baseWidget.width - rightLabelWidth, self.baseWidget.height, "fill")

    -- 再画血条
    _Graphics.SetColor(255, 0, 0, 200)
    local hpRectWidth = 0
    if self.maxHp ~= 0 then
        hpRectWidth = (self.baseWidget.width - rightLabelWidth) * (self.currentHp / self.maxHp)
    end
    _Graphics.DrawRect(0, 0, hpRectWidth, self.baseWidget.height, "fill")

    -- 还原绘图数据
    _Graphics.SetCanvas()
    _Graphics.SetColor(originColorR, originColorG, originColorB, originColorA)

    self.rectSprite:SetImage(canvas)
    self.rectSprite:AdjustDimensions()
    self.rectSprite:SetAttri("position", self.baseWidget.xPos, self.baseWidget.yPos)
end

return HpRectBar
