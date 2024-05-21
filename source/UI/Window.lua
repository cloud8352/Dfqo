--[[
	desc: Window class.
	author: keke <243768648@qq.com>
	since: 2022-11-15
	alter: 2022-11-15
]]
--

local _Util = require("util.Util")

local _CONFIG = require("config")
local _RESOURCE = require("lib.resource")
local _Sprite = require("graphics.drawable.sprite")
local _Graphics = require("lib.graphics")
local _Mouse = require("lib.mouse")
local _MATH = require("lib.math")

local TitleBar = require("UI.TitleBar")
local WindowManager = require("UI.WindowManager")
local Widget = require("UI.Widget")

---@class Window
local Window = require("core.class")(Widget)

local MarginSpace = 15
local TitleBarHeight = 20

function Window:Ctor()
    Widget.Ctor(self, self)
    MarginSpace = math.floor(5 * _Util.GetWindowSizeScale())
    TitleBarHeight = math.floor(40 * _Util.GetWindowSizeScale())

    -- WindowLayerIndex
    self.windowLayerIndex = WindowManager.GetMaxLayerIndex() + 1
    WindowManager.AppendToWindowList(self)

    self.bgSprite = _Sprite.New()
    self.bgSprite:SwitchRect(true) -- 使用矩形
    self.spriteXScale, self.spriteYScale = self.bgSprite:GetAttri("scale")
    self.isTipToolWindow = false
    self.isWindowStaysOnTopHint = false
    self.isInMoving = false

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

    self.contentWidget = Widget.New(self)

    -- title bar
    self.titleBar = TitleBar.New(self)

    -- connect
    self.titleBar:SetReceiverOfRequestMoveWindow(self)
    self.titleBar:SetReceiverOfRequestCloseWindow(self)
end

function Window:Update(dt)
    if false == Widget.IsVisible(self) then
        return
    end
    self:MouseEvent()
    
    self.titleBar:Update(dt)

    self.contentWidget:Update(dt)

    Widget.Update(self, dt)
end

function Window:Draw()
    if false == Widget.IsVisible(self) then
        return
    end
    Widget.Draw(self)

    self.bgSprite:Draw()

    self.contentWidget:Draw()

    self.titleBar:Draw()
end

function Window:MouseEvent()
    -- 判断鼠标
    while true do
        -- 检查是否有上层窗口遮挡
        if WindowManager.IsMouseCapturedAboveLayer(self.windowLayerIndex) then
            break
        end

        local mouseX, mouseY = _Mouse.GetPosition(1, 1)
        if false == self:CheckPoint(mouseX, mouseY) then
            break
        end

        -- 鼠标左键是否点击
        if _Mouse.IsPressed(1)
            or _Mouse.IsHold(1)
            or _Mouse.IsReleased(1) then -- 1 is the primary mouse button, 2 is the secondary mouse button and 3 is the middle button
            WindowManager.SetWindowToTopLayer(self)
            break
        end

        break
    end
end

--- 连接信号
---@param signal function
---@param obj Object
function Window:MocConnectSignal(signal, receiver)
    Widget.MocConnectSignal(self, signal, receiver)
end

---@param signal function
function Window:GetReceiverListOfSignal(signal)
    return Widget.GetReceiverListOfSignal(self, signal)
end

---@param name string
function Window:SetObjectName(name)
    Widget.SetObjectName(self, name)
end

function Window:GetObjectName()
    return Widget.GetObjectName(self)
end

function Window:GetParentWindow()
    return Widget.GetParentWindow(self)
end

function Window:GetPosition()
    return Widget.GetPosition(self)
end

function Window:SetPosition(x, y)
    Widget.SetPosition(self, x, y)

    self.bgSprite:SetAttri("position", x, y)

    local realTitleBarHeight = 0
    if self.titleBar:IsVisible() then
        realTitleBarHeight = TitleBarHeight
    end
    self.contentWidget:SetPosition(x + MarginSpace, y + MarginSpace + realTitleBarHeight)

    self.titleBar:SetPosition(x, y)
end

function Window:SetSize(w, h)
    local width = math.floor(w)
    local height = math.floor(h)
    Widget.SetSize(self, width, height)

    _Graphics.SaveCanvas()
    -- 创建背景画布
    local canvas = _Graphics.NewCanvas(width, height)
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
    local topCenterBgXScale = (width - self.leftTopBgImgDate.w - self.rightTopBgImgDate.w) / self.topBgImgDate.w
    painterSprite:SetAttri("scale", topCenterBgXScale, 1)
    painterSprite:Draw()

    -- 画右上角背景
    painterSprite:SetData(self.rightTopBgImgDate)
    painterSprite:SetAttri("position", width - self.rightTopBgImgDate.w, 0)
    painterSprite:Draw()

    -- 画左中段背景
    painterSprite:SetData(self.leftBgImgDate)
    painterSprite:SetAttri("position", 0, self.leftTopBgImgDate.h)
    local centerBgYScale = (height - self.leftTopBgImgDate.h - self.leftBottomBgImgDate.h) / self.leftBgImgDate.h
    painterSprite:SetAttri("scale", 1, centerBgYScale)
    painterSprite:Draw()
    -- 画中间部分的背景
    painterSprite:SetData(self.centerBgImgDate)
    painterSprite:SetAttri("position", self.leftBgImgDate.w, self.leftTopBgImgDate.h)
    painterSprite:SetAttri("scale", topCenterBgXScale, centerBgYScale)
    painterSprite:Draw()
    -- 画右中段背景
    painterSprite:SetData(self.rightBgImgDate)
    painterSprite:SetAttri("position", width - self.rightBgImgDate.w, self.leftTopBgImgDate.h)
    painterSprite:SetAttri("scale", 1, centerBgYScale)
    painterSprite:Draw()

    -- 画左下角背景
    painterSprite:SetData(self.leftBottomBgImgDate)
    painterSprite:SetAttri("position", 0, height - self.leftBottomBgImgDate.h)
    painterSprite:Draw()
    -- 画下中段背景
    painterSprite:SetData(self.bottomBgImgDate)
    painterSprite:SetAttri("position", self.leftBottomBgImgDate.w, height - self.leftBottomBgImgDate.h)
    painterSprite:SetAttri("scale", topCenterBgXScale, 1)
    painterSprite:Draw()
    -- 画右下角背景
    painterSprite:SetData(self.rightBottomBgImgDate)
    painterSprite:SetAttri("position", width - self.rightBottomBgImgDate.w, height - self.leftBottomBgImgDate.h)
    painterSprite:Draw()

    _Graphics.RestoreCanvas()
    self.bgSprite:SetImage(canvas)
    self.bgSprite:AdjustDimensions()

    -- content
    local realTitleBarHeight = 0
    if self.titleBar:IsVisible() then
        realTitleBarHeight = TitleBarHeight
    end
    self.contentWidget:SetSize(width - MarginSpace * 2,
        height - MarginSpace * 2 - realTitleBarHeight)

    -- 设置标题栏尺寸
    self.titleBar:SetSize(width, TitleBarHeight)
end

---@return integer, integer
function Window:GetSize()
    return Widget.GetSize(self)
end

function Window:SetEnable(enable)
    Widget.SetEnable(self, enable)
end

--- 是否可见
---@return boolean visible
function Window:IsVisible()
    return Widget.IsVisible(self)
end

--- 设置是否可见
---@param visible boolean
function Window:SetVisible(visible)
    Widget.SetVisible(self, visible)
end

--- 设置标题栏是否可见
---@param visible boolean
function Window:SetTitleBarVisible(visible)
    self.titleBar:SetVisible(visible)
end

function Window:SetScale(xScale, yScale)
    self.spriteXScale = xScale
    self.spriteYScale = yScale
end

---@return boolean
function Window:IsInMoving()
    return self.isInMoving
end

function Window:SetIsInMoving(moving)
    self.isInMoving = moving
end

--- 获取窗口所处层数。
--- 由窗管调用
---@return number layerIndex
function Window:GetWindowLayerIndex()
    return self.windowLayerIndex
end

--- 设置窗口所处层数。
--- 由窗管调用
---@param layerIndex number
function Window:SetWindowLayerIndex(layerIndex)
    self.windowLayerIndex = layerIndex
end

--- 检查是否包含坐标。
--- 由窗管调用
---@param x number
---@param y number
---@return boolean
function Window:CheckPoint(x, y)
    if self.isTipToolWindow and
        self.isWindowStaysOnTopHint == false
    then
        return false
    end

    if not self.isVisible then
        return false
    end

    return self.bgSprite:CheckPoint(x, y)
end

function Window:SetIsTipToolWindow(is)
    self.isTipToolWindow = is
end

---@return boolean isTipToolWindow
function Window:IsTipToolWindow()
    return self.isTipToolWindow
end

---@param is boolean
function Window:SetIsWindowStayOnTopHint(is)
    self.isWindowStaysOnTopHint = is
end

---@return boolean isWindowStayOnTopHint
function Window:IsWindowStayOnTopHint()
    return self.isWindowStaysOnTopHint
end

---@param widget Widget
function Window:SetContentWidget(widget)
    self.contentWidget = widget

    local realTitleBarHeight = 0
    if self.titleBar:IsVisible() then
        realTitleBarHeight = TitleBarHeight
    end
    local width, height = self:GetSize()
    self.contentWidget:SetSize(width - MarginSpace * 2,
        height - MarginSpace * 2 - realTitleBarHeight)
    local xPos, yPos = self:GetPosition()
    self.contentWidget:SetPosition(xPos + MarginSpace, yPos + MarginSpace + realTitleBarHeight)
end

---@param isVisible boolean
function Window:SetTitleBarIsBackgroundVisible(isVisible)
    self.titleBar:SetIsBackgroundVisible(isVisible)
end

--- slots

---@param x int
---@param y int
function Window:OnRequestMoveWindow(x, y)
    self:SetPosition(x, y)
end

function Window:OnRequestCloseWindow()
    self:SetVisible(false)
    self:Signal_WindowClosed()
end

--- signals

function Window:Signal_WindowClosed()
    print("Window:Signal_WindowClosed()")
    local receiverList = self:GetReceiverListOfSignal(self.Signal_WindowClosed)
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.Slot_WindowClosed
        if func == nil then
            goto continue
        end

        func(receiver, self)

        ::continue::
    end
end

return Window
