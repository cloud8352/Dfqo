--[[
	desc: Label class.
	author: keke <243768648@qq.com>
	since: 2022-12-14
	alter: 2023-1-7
]] --

local WindowManager = require("UI.WindowManager")
local Widget = require("UI.Widget")

local _Sprite = require("graphics.drawable.sprite")
local _Graphics = require("lib.graphics")
local _RESOURCE = require("lib.resource")
local _String = require("lib.string")

local bit = require("bit")

---@class Label : Widget
local Label = require("core.class")(Widget)

---@enum Label.AlignmentFlag
local localAlignLeft = 0x0001
local localAlignLeading = localAlignLeft
local localAlignRight = 0x0002
local localAlignTrailing = localAlignRight
local localAlignHCenter = 0x0004
local localAlignJustify = 0x0008
local localAlignAbsolute = 0x0010
local localAlignHorizontal_Mask = bit.bor(localAlignLeft, localAlignRight, localAlignHCenter, localAlignJustify, localAlignAbsolute)

local localAlignTop = 0x0020
local localAlignBottom = 0x0040
local localAlignVCenter = 0x0080
local localAlignBaseline = 0x0100
local localAlignVertical_Mask = bit.bor(localAlignTop, localAlignBottom, localAlignVCenter, localAlignBaseline)

local localAlignCenter = bit.bor(localAlignVCenter, localAlignHCenter)
Label.AlignmentFlag = {
    AlignLeft = localAlignLeft,
    AlignLeading = localAlignLeading,
    AlignRight = localAlignRight,
    AlignTrailing = localAlignTrailing,
    AlignHCenter = localAlignHCenter,
    AlignJustify = localAlignJustify,
    AlignAbsolute = localAlignAbsolute,
    AlignHorizontal_Mask = localAlignHorizontal_Mask,

    AlignTop = localAlignTop,
    AlignBottom = localAlignBottom,
    AlignVCenter = localAlignVCenter,
    AlignBaseline = localAlignBaseline,
    AlignVertical_Mask = localAlignVertical_Mask,

    AlignCenter = localAlignCenter
}

---@param parentWindow Window
function Label.Create(parentWindow)
    -- 用于定义构造函数，解释使用，不做实际用途
    -- 使用class模块后，实际会调用Ctor函数
    return Label.New(parentWindow)
end

---@param parentWindow Window
function Label:Ctor(parentWindow)
    Widget.Ctor(self, parentWindow)
    self:SetBgSpriteColor(0, 0, 0, 0)

    -- 文字显示对象
    self.sprite = _Sprite.New()
    -- 图标显示对象
    self.iconSpriteDataPath = ""
    self.lastIconSpriteDataPath = ""
    self.iconSizeW = 0
    self.lastIconSizeW = 0
    self.iconSizeH = 0
    self.lastIconSizeH = 0
    ---@type Graphics.Drawable | Graphics.Drawable.IRect | Graphics.Drawable.IPath | Graphics.Drawable.Sprite
    self.iconSprite = _Sprite.New()

    self.text = ""
    self.lastText = ""

    self.alignment = Label.AlignmentFlag.AlignCenter
    self.lastAlignment = self.alignment

    -- 显示内容尺寸 - 宽
    self.viewContentSizeW = 0
    -- 显示内容尺寸 - 高
    self.viewContentSizeH = 0
end

function Label:Update(dt)
    if not self.isVisible then
        return
    end

    if (self:IsSizeChanged()
            or self.lastText ~= self.text
            or self.lastAlignment ~= self.alignment
            or self.lastIconSpriteDataPath ~= self.iconSpriteDataPath
            or self.lastIconSizeW ~= self.iconSizeW
            or self.lastIconSizeH ~= self.iconSizeH
        )
    then
        self:updateSprite()
    end

    self.lastText = self.text
    self.lastAlignment = self.alignment
    self.lastIconSpriteDataPath = self.iconSpriteDataPath
    self.lastIconSizeW = self.iconSizeW
    self.lastIconSizeH = self.iconSizeH

    Widget.Update(self, dt)
end

function Label:Draw()
    if not self.isVisible then
        return
    end
    Widget.Draw(self)

    self.iconSprite:Draw()
    self.sprite:Draw()
end

function Label:SetPosition(x, y)
    Widget.SetPosition(self, x, y)

    self.sprite:SetAttri("position", self.xPos, self.yPos)

    -- 更新图标坐标
    self.iconSprite:SetAttri("position", self.xPos, self.yPos)
end

---@return int, int
function Label:GetPosition()
    return Widget.GetPosition(self)
end

function Label:SetSize(width, height)
    Widget.SetSize(self, width, height)
end

---@return int, int
function Label:GetSize()
    return Widget.GetSize(self)
end

function Label:SetEnable(enable)
    Widget.SetEnable(self, enable)
end

---@param isVisible boolean
function Label:SetVisible(isVisible)
    Widget.SetVisible(self, isVisible)
end

---@return boolean isVisible
function Label:IsVisible()
    return Widget.IsVisible(self)
end

---@param x integer
---@param y integer
function Label:CheckPoint(x, y)
    return Widget.CheckPoint(self, x, y)
end

---@param text string
function Label:SetText(text)
    self.text = text
end

function Label:GetText()
    return self.text
end

---@param alignments table<i, Label.AlignmentFlag>
function Label:SetAlignments(alignments)
    self.alignment = 0
    for i, v in pairs(alignments) do
        self.alignment = bit.bor(self.alignment, v)
    end
end

---@param path string
function Label:SetIconSpriteDataPath(path)
    if self.iconSpriteDataPath == path then
        return
    end

    self.iconSpriteDataPath = path
    if self.iconSpriteDataPath == "" then
        local canvas = _Graphics.NewCanvas(self.width, self.height)
        self.iconSprite:SetImage(canvas)
    else
        ---@type Lib.RESOURCE.SpriteData
        local spriteData = _RESOURCE.GetSpriteData(path)
        self.iconSprite:SetData(spriteData, true)
    end

    local spriteWidth, spriteHeight = self.iconSprite:GetImageDimensions()
    local spriteXScale = self.iconSizeW / spriteWidth
    local spriteYScale = self.iconSizeH / spriteHeight
    self.iconSprite:SetAttri("scale", spriteXScale, spriteYScale)
end

function Label:GetIconSpriteImgDimensions()
    return self.iconSprite:GetImageDimensions()
end

function Label:SetIconSize(w, h)
    if self.iconSizeW == w and self.iconSizeH == h then
        return
    end
    
    self.iconSizeW = w
    self.iconSizeH = h
end

---@return integer w, integer h
function Label:GetViewContentSize()
    if self.isVisible then
        return self.viewContentSizeW, self.viewContentSizeH
    else
        return 0, 0
    end
end

function Label:AdjustHeightByContent()
    local lineStrList = _String.WarpStr(self.text, _Graphics.GetFont(), self.width)
    local lineCount = #lineStrList
    local fontHeight = _Graphics.GetFontHeight()
    self:SetSize(self.width, lineCount * fontHeight)
end

function Label:AdjustWidthByContent()
    local fontWidth = _Graphics.GetFontWidth(self.text)
    self:SetSize(fontWidth, self.height)
end

function Label:updateSprite()
    _Graphics.SaveCanvas()
    -- 创建背景画布
    local canvas = _Graphics.NewCanvas(self.width, self.height)
    _Graphics.SetCanvas(canvas)

    local txtR, txtG, txtB, txtA
    txtR = 255; txtG = 255; txtB = 255; txtA = 255
    _Graphics.SetColor(txtR, txtG, txtB, txtA)
    _Graphics.SetBlendmode("alpha")

    -- 文本对象实际显示宽高
    local textSpriteViewWidth = self.width
    local textSpriteViewHeight = 0
    -- 获取按字体和宽度换行的字符串列表
    local lineStrList = _String.WarpStr(self.text, _Graphics.GetFont(), self.width)
    local lineCount = #lineStrList
    local fontHeight = _Graphics.GetFontHeight()
    for i, str in pairs(lineStrList) do
        -- 根据对齐方式计算文字x坐标
        local textXPos = 0
        if 0 ~= bit.band(Label.AlignmentFlag.AlignHCenter, self.alignment) then
            textXPos = self.width / 2 - _Graphics.GetFontWidth(str) / 2
        elseif 0 ~= bit.band(Label.AlignmentFlag.AlignLeft, self.alignment) then
            textXPos = 0
        elseif 0 ~= bit.band(Label.AlignmentFlag.AlignRight, self.alignment) then
            textXPos = self.width - _Graphics.GetFontWidth(str)
        end
        -- 根据对齐方式计算文字y坐标
        local textYPos = (i - 1) * fontHeight
        if 0 ~= bit.band(Label.AlignmentFlag.AlignVCenter, self.alignment) then
            textYPos = textYPos + self.height / 2 - _Graphics.GetFontHeight() * lineCount / 2
        elseif 0 ~= bit.band(Label.AlignmentFlag.AlignTop, self.alignment) then
            -- do nothing
        elseif 0 ~= bit.band(Label.AlignmentFlag.AlignBottom, self.alignment) then
            textYPos = textYPos + self.height - _Graphics.GetFontHeight() * lineCount
        end
        
        local textObj = _Graphics.NewNormalText(str)
        _Graphics.DrawObj(textObj, textXPos, textYPos, 0, 1, 1, 0, 0)
        
        textSpriteViewHeight = textSpriteViewHeight + fontHeight
    end

    -- 还原绘图数据
    _Graphics.RestoreCanvas()

    -- 设置文字对象数据
    self.sprite:SetImage(canvas)
    self.sprite:AdjustDimensions()
    self.sprite:SetAttri("position", self.xPos, self.yPos)

    -- 更新图标数据
    local spriteWidth, spriteHeight = self.iconSprite:GetImageDimensions()
    local spriteXScale = self.iconSizeW / spriteWidth
    local spriteYScale = self.iconSizeH / spriteHeight
    self.iconSprite:SetAttri("scale", spriteXScale, spriteYScale)
    self.iconSprite:SetAttri("position", self.xPos, self.yPos)

    -- 更新显示内容尺寸
    if textSpriteViewWidth > self.iconSizeW then
        self.viewContentSizeW = textSpriteViewWidth
    else
        self.viewContentSizeW = self.iconSizeW 
    end
    if textSpriteViewHeight > self.iconSizeH then
        self.viewContentSizeH = textSpriteViewHeight
    else
        self.viewContentSizeH = self.iconSizeH
    end
end

return Label
