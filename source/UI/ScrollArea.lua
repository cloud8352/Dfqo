--[[
    desc: ScrollArea class.
    author: keke <243768648@qq.com>
]] --

local _RESOURCE = require("lib.resource")
local _Sprite = require("graphics.drawable.sprite")
local _Graphics = require("lib.graphics")

local WindowManager = require("UI.WindowManager")
local Widget = require("UI.Widget")
local ScrollBar = require("UI.ScrollBar")

---@class ScrollArea
local ScrollArea = require("core.class")(Widget)

---@param parentWindow Window
function ScrollArea:Ctor(parentWindow)
    Widget.Ctor(self, parentWindow)
    assert(parentWindow, "must assign parent window")
    ---@type Window
    self.parentWindow = parentWindow

    self.bgSprite = _Sprite.New()
    self.bgSprite:SwitchRect(true) -- 使用矩形

    -- 背景图片数据
    self.leftTopBgImgDate = _RESOURCE.GetSpriteData("ui/WindowFrame/LeftTopBg")
    self.topBgImgDate = _RESOURCE.GetSpriteData("ui/WindowFrame/TopBg")
    self.rightTopBgImgDate = _RESOURCE.GetSpriteData("ui/WindowFrame/RightTopBg")
    self.leftBgImgDate = _RESOURCE.GetSpriteData("ui/WindowFrame/LeftBg")
    self.centerBgImgDate = _RESOURCE.GetSpriteData("ui/WindowFrame/CenterBg")
    self.rightBgImgDate = _RESOURCE.GetSpriteData("ui/WindowFrame/RightBg")
    self.leftBottomBgImgDate = _RESOURCE.GetSpriteData("ui/WindowFrame/LeftBottomBg")
    self.bottomBgImgDate = _RESOURCE.GetSpriteData("ui/WindowFrame/BottomBg")
    self.rightBottomBgImgDate = _RESOURCE.GetSpriteData("ui/WindowFrame/RightBottomBg")

    -- 内容控件
    ---@type Widget
    self.contentWidget = Widget.New(parentWindow)

    -- 实际显示内容（超出范围的内容不显示）
    ---@type Graphics.Drawable | Graphics.Drawable.IRect | Graphics.Drawable.IPath | Graphics.Drawable.Sprite
    self.contentSprite = _Sprite.New()
    self.contentSprite:SwitchRect(true)
    self.contentYOffset = 0

    -- 滑动条
    self.scrollBar = ScrollBar.New(self.parentWindow)
    self.scrollBar:SetSlideLength(self.height)

    self.needUpdateContentSprite = true

    -- content margins
    self.leftMargin = 5
    self.topMargin = 5
    self.rightMargin = 5
    self.bottomMargin = 5

    --- connection
    self.scrollBar:MocConnectSignal(self.scrollBar.Signal_RequestMoveContent, self)
end

function ScrollArea:Update(dt)
    if false == Widget.IsVisible(self) then
        return
    end

    if Widget.IsSizeChanged(self) then
        self:updateBgSprite()
    end

    if self.needUpdateContentSprite then
        self:updateContentSprite()
        self.needUpdateContentSprite = false
    end

    -- 更新滑动条控制的区域高度
    local _, contentWidgetHeight = self.contentWidget:GetSize()
    local scrollBarCtrlledContentLength = self.scrollBar:GetCtrlledContentLength()
    if contentWidgetHeight ~= scrollBarCtrlledContentLength then
        self.scrollBar:SetCtrlledContentLength(contentWidgetHeight)
    end

    self.scrollBar:Update(dt)

    Widget.Update(self, dt)
end

function ScrollArea:Draw()
    if (false == Widget.IsVisible(self)) then
        return
    end
    Widget.Draw(self)

    self.bgSprite:Draw()

    -- content sprite
    self.contentSprite:Draw()

    self.scrollBar:Draw()
end

--- 连接信号
---@param signal function
---@param obj Object
function ScrollArea:MocConnectSignal(signal, receiver)
    Widget.MocConnectSignal(self, signal, receiver)
end

---@param signal function
function ScrollArea:GetReceiverListOfSignal(signal)
    return Widget.GetReceiverListOfSignal(self, signal)
end

---@param name string
function ScrollArea:SetObjectName(name)
    Widget.SetObjectName(self, name)
end

function ScrollArea:GetObjectName()
    return Widget.GetObjectName(self)
end

function ScrollArea:SetPosition(x, y)
    Widget.SetPosition(self, x, y)

    self.bgSprite:SetAttri("position", x, y)
    self.contentSprite:SetAttri("position", x + self.leftMargin,
        y + self.topMargin)
    self.scrollBar:SetPosition(x + self.width - self.scrollBar:GetWidth() - self.rightMargin,
        y + self.topMargin)
end

function ScrollArea:GetPosition()
    return Widget.GetPosition(self)
end

function ScrollArea:SetSize(width, height)
    Widget.SetSize(self, width, height)

    -- scroll bar
    self.scrollBar:SetSlideLength(self.height - self.topMargin - self.bottomMargin)

    -- needUpdateContentSprite
    self.needUpdateContentSprite = true
end

function ScrollArea:GetSize()
    return Widget.GetSize(self)
end

function ScrollArea:SetEnable(enable)
    Widget.SetEnable(self, enable)
end

function ScrollArea:IsVisible()
    return Widget.IsVisible(self)
end

---@param isVisible bool
function ScrollArea:SetVisible(isVisible)
    Widget.SetVisible(self, isVisible)
end

---@param x int
---@param y int
---@return boolean
function ScrollArea:CheckPoint(x, y)
    return self.bgSprite:CheckPoint(x, y)
end

---@param w Widget
function ScrollArea:SetContentWidget(w)
    self.contentWidget = w
end

function ScrollArea:GetDisplayContentWidth()
    local w, _ = Widget.GetSize(self)
    local scrollBarW = self.scrollBar:GetWidth()

    local displayContentWidth = w - scrollBarW - self.leftMargin - self.rightMargin - 2
    if displayContentWidth < 0 then
        displayContentWidth = 0
    end
    return displayContentWidth
end

function ScrollArea:GetDisplayContentHeight()
    local _, h = Widget.GetSize(self)

    local displayContentHeight = h - self.topMargin - self.bottomMargin
    if displayContentHeight < 0 then
        displayContentHeight = 0
    end
    return displayContentHeight
end

---@return int, int, int, int leftMargin, topMargin, rightMargin, bottomMargin
function ScrollArea:GetMargins()
    return self.leftMargin, self.topMargin, self.rightMargin, self.bottomMargin
end

function ScrollArea:GetContentYOffset()
    return self.contentYOffset
end

---@param need boolean
function ScrollArea:SetNeedUpdateContentSprite(need)
    self.needUpdateContentSprite = need
end

--- slot
---
---@param sender Obj
---@param xOffset int
---@param yOffset int
function ScrollArea:Slot_RequestMoveContent(sender, xOffset, yOffset)
    print("ScrollArea:Slot_RequestMoveContent()", xOffset, yOffset)
    self.contentYOffset = yOffset
    self.needUpdateContentSprite = true
end

function ScrollArea:updateBgSprite()
    _Graphics.SaveCanvas()
    -- 创建背景画布
    local canvas = _Graphics.NewCanvas(self.width, self.height)
    _Graphics.SetCanvas(canvas)

    -- 创建临时绘图精灵
    local painterSprite = _Sprite.New()
    -- 画左上角背景
    painterSprite:SetData(self.leftTopBgImgDate)
    painterSprite:SetAttri("position", 0, 0)
    painterSprite:Draw()
    -- 画上中段背景
    painterSprite:SetData(self.topBgImgDate)
    painterSprite:SetAttri("position", self.leftTopBgImgDate.w, 0)
    local topCenterBgXScale = (self.width - self.leftTopBgImgDate.w - self.rightTopBgImgDate.w) / self.topBgImgDate.w
    painterSprite:SetAttri("scale", topCenterBgXScale, 1)
    painterSprite:Draw()

    -- 画右上角背景
    painterSprite:SetData(self.rightTopBgImgDate)
    painterSprite:SetAttri("position", self.width - self.rightTopBgImgDate.w, 0)
    painterSprite:Draw()

    -- 画左中段背景
    painterSprite:SetData(self.leftBgImgDate)
    painterSprite:SetAttri("position", 0, self.leftTopBgImgDate.h)
    local centerBgYScale = (self.height - self.leftTopBgImgDate.h - self.leftBottomBgImgDate.h) / self.leftBgImgDate.h
    painterSprite:SetAttri("scale", 1, centerBgYScale)
    painterSprite:Draw()
    -- 画中间部分的背景
    painterSprite:SetData(self.centerBgImgDate)
    painterSprite:SetAttri("position", self.leftBgImgDate.w, self.leftTopBgImgDate.h)
    painterSprite:SetAttri("scale", topCenterBgXScale, centerBgYScale)
    painterSprite:Draw()
    -- 画右中段背景
    painterSprite:SetData(self.rightBgImgDate)
    painterSprite:SetAttri("position", self.width - self.rightBgImgDate.w, self.leftTopBgImgDate.h)
    painterSprite:SetAttri("scale", 1, centerBgYScale)
    painterSprite:Draw()

    -- 画左下角背景
    painterSprite:SetData(self.leftBottomBgImgDate)
    painterSprite:SetAttri("position", 0, self.height - self.leftBottomBgImgDate.h)
    painterSprite:Draw()
    -- 画下中段背景
    painterSprite:SetData(self.bottomBgImgDate)
    painterSprite:SetAttri("position", self.leftBottomBgImgDate.w, self.height - self.leftBottomBgImgDate.h)
    painterSprite:SetAttri("scale", topCenterBgXScale, 1)
    painterSprite:Draw()
    -- 画右下角背景
    painterSprite:SetData(self.rightBottomBgImgDate)
    painterSprite:SetAttri("position", self.width - self.rightBottomBgImgDate.w, self.height - self.leftBottomBgImgDate.h)
    painterSprite:Draw()

    _Graphics.RestoreCanvas()
    self.bgSprite:SetImage(canvas)
    self.bgSprite:AdjustDimensions()
end

function ScrollArea:updateContentSprite()
    _Graphics.SaveCanvas()
    -- 创建背景画布
    local canvas = _Graphics.NewCanvas(self.width - self.leftMargin - self.rightMargin,
        self.height - self.topMargin - self.bottomMargin)
    _Graphics.SetCanvas(canvas)

    self.contentWidget:SetPosition(0, self.contentYOffset)
    self.contentWidget:Draw()

    _Graphics.RestoreCanvas()

    self.contentSprite:SetImage(canvas)
    self.contentSprite:AdjustDimensions()
end

return ScrollArea
