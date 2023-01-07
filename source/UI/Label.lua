--[[
	desc: Label class.
	author: keke <243768648@qq.com>
	since: 2022-12-14
	alter: 2023-1-7
]] --

local _Sprite = require("graphics.drawable.sprite")
local _Graphics = require("lib.graphics")

local bit = require("bit")

---@class Label
local Label = require("core.class")()

---@enum Label.AligmentFlag
local localAlignLeft = 0x0001
local localAlignLeading = localAlignLeft
local localAlignRight = 0x0002
local localAlignTrailing = localAlignRight
local localAlignHCenter = 0x0004
local localAlignJustify = 0x0008
local localAlignAbsolute = 0x0010
local localAlignHorizontal_Mask =  bit.bor(localAlignLeft, localAlignRight, localAlignHCenter, localAlignJustify, localAlignAbsolute)

local localAlignTop = 0x0020
local localAlignBottom = 0x0040
local localAlignVCenter = 0x0080
local localAlignBaseline = 0x0100
local localAlignVertical_Mask = bit.bor(localAlignTop, localAlignBottom, localAlignVCenter, localAlignBaseline)

local localAlignCenter = bit.bor(localAlignVCenter, localAlignHCenter)
Label.AligmentFlag = {
    AlignLeft = localAlignLeft,
    AlignLeading = localAlignLeading,
    AlignRight = localAlignRight,
    AlignTrailing = localAlignTrailing,
    AlignHCenter = localAlignHCenter,
    AlignJustify = localAlignJustify,
    AlignAbsolute = localAlignAbsolute,
    AlignHorizontal_Mask =  localAlignHorizontal_Mask,

    AlignTop = localAlignTop,
    AlignBottom = localAlignBottom,
    AlignVCenter = localAlignVCenter,
    AlignBaseline = localAlignBaseline,
    AlignVertical_Mask = localAlignVertical_Mask,

    AlignCenter = localAlignCenter
}

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

    self.aligment = Label.AligmentFlag.AlignCenter
    self.lastAligment = self.aligment
end

function Label:Update(dt)
    if (self.lastWidth ~= self.width
        or self.lastHeight ~= self.height
        or self.lastText ~= self.text
        or self.lastAligment ~= self.aligment
        )
        then
        self:updateSprite()
    end

    self.lastXPos = self.xPos
    self.lastYPos = self.yPos
    self.lastWidth = self.width
    self.lastHeight = self.height
    self.lastText = self.text
    self.lastAligment = self.aligment
end

function Label:Draw()
    self.sprite:Draw()
end

function Label:SetPosition(x, y)
    self.sprite:SetAttri("position", x, y)
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

---@param aligments table<i, Label.AligmentFlag>
function Label:SetAligments(aligments)
    self.aligment = 0
    for i, v in pairs(aligments) do
        self.aligment = bit.bor(self.aligment, v)
    end
end

function Label:updateSprite()
    -- 创建背景画布
    local canvas = _Graphics.NewCanvas(self.width, self.height)
    _Graphics.SetCanvas(canvas)
    local originColorR, originColorG, originColorB, originColorA = _Graphics.GetColor()

    local txtR, txtG, txtB, txtA
    txtR = 255; txtG = 255; txtB = 255; txtA = 255
    _Graphics.SetColor(txtR, txtG, txtB, txtA)

    -- 根据对齐方式计算文字x坐标
    local textXPos = 0
    if 0 ~= bit.band(Label.AligmentFlag.AlignHCenter, self.aligment) then
        textXPos = self.width / 2 - _Graphics.GetFontWidth(self.text) / 2
    elseif 0 ~= bit.band(Label.AligmentFlag.AlignLeft, self.aligment) then
        textXPos = 0
    elseif 0 ~= bit.band(Label.AligmentFlag.AlignRight, self.aligment) then
        textXPos = self.width - _Graphics.GetFontWidth(self.text)
    end
    -- 根据对齐方式计算文字y坐标
    local textYPos = 0
    if 0 ~= bit.band(Label.AligmentFlag.AlignVCenter, self.aligment) then
        textYPos = self.height / 2 - _Graphics.GetFontHeight() / 2
    elseif 0 ~= bit.band(Label.AligmentFlag.AlignTop, self.aligment) then
        textYPos = 0
    elseif 0 ~= bit.band(Label.AligmentFlag.AlignBottom, self.aligment) then
        textYPos = self.height - _Graphics.GetFontHeight()
    end

    local textObj = _Graphics.NewNormalText(self.text)
    _Graphics.DrawObj(textObj, textXPos, textYPos, 0, 1, 1, 0, 0)

    -- 还原绘图数据
    _Graphics.SetCanvas()
    _Graphics.SetColor(originColorR, originColorG, originColorB, originColorA)
    self.sprite:SetImage(canvas)
    self.sprite:AdjustDimensions()
end

return Label
