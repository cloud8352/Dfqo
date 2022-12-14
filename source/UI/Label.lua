--[[
	desc: Label class.
	author: keke <243768648@qq.com>
	since: 2022-12-14
	alter: 2022-12-14
]] --

local _Sprite = require("graphics.drawable.sprite")
local _Graphics = require("lib.graphics")

---@class Label
local Label = require("core.class")()

---@param parentWindow Window
function Label:Ctor(parentWindow)
    assert(parentWindow, "must assign parent window")
    ---@type Window
    self.parentWindow = parentWindow

    self.sprite = _Sprite.New()
    -- self.sprite:SwitchRect(true) -- 使用矩形
    self.width = 30
    self.lastWidth = 0
    self.height = 10
    self.lastHeight = 0
    self.xPos = 0
    self.lastXPos = 0
    self.yPos = 0
    self.lastYPos = 0
    self.enable = true

    self.text = ""
    self.lastText = ""

    -- content margins
    self.leftMargin = 5
    self.topMargin = 5
    self.rightMargin = 5
    self.bottomMargin = 5
end

function Label:Update(dt)
    if (self.lastWidth ~= self.width
        or self.lastHeight ~= self.height
        or self.lastText ~= self.text)
        then
        self:updateSprite()
    end

    self.lastXPos = self.xPos
    self.lastYPos = self.yPos
    self.lastWidth = self.width
    self.lastHeight = self.height
    self.lastText = self.text
end

function Label:Draw()
    self.sprite:Draw()
end

function Label:SetPosition(x, y)
    self.sprite:SetAttri("position", x + self.leftMargin, y + self.topMargin)
    self.xPos = x
    self.yPos = y
end

function Label:SetSize(width, height)
    self.width = width
    self.height = height
end

function Label:SetEnable(enable)
    self.enable = enable
end

function Label:SetText(text)
    self.text = text
end

function Label:updateSprite()
    -- 创建背景画布
    local canvas = _Graphics.NewCanvas(self.width, self.height)
    _Graphics.SetCanvas(canvas)
    local originColorR, originColorG, originColorB, originColorA = _Graphics.GetColor()

    local txtR, txtG, txtB, txtA
    txtR = 255; txtG = 255; txtB = 255; txtA = 255
    _Graphics.SetColor(txtR, txtG, txtB, txtA)
    -- 计算文字垂直居中显示时所处坐标
    local textXPos = self.leftMargin
    local textYPos = self.topMargin + (self.height - self.topMargin - self.bottomMargin) / 2 
                    - _Graphics.GetFontHeight() / 2
    local textObj = _Graphics.NewNormalText(self.text)
    _Graphics.DrawObj(textObj, textXPos, textYPos, 0, 1, 1, 0, 0)

    -- 还原绘图数据
    _Graphics.SetCanvas()
    _Graphics.SetColor(originColorR, originColorG, originColorB, originColorA)
    self.sprite:SetImage(canvas)
    self.sprite:AdjustDimensions()
end

return Label
