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
local Window = require("core.class")()

local MarginSpace = 15
local TitleBarHeight = 50

function Window:Ctor()
    MarginSpace = _MATH.Round(15 * _Util.GetWindowSizeScale())
    TitleBarHeight = _MATH.Round(50 * _Util.GetWindowSizeScale())

    -- WindowLayerIndex
    self.windowLayerIndex = WindowManager.GetMaxLayerIndex() + 1
    WindowManager.AppendToWindowList(self)

    self.objName = ""
    self.bgSprite = _Sprite.New()
    self.bgSprite:SwitchRect(true) -- 使用矩形
    self.spriteXScale, self.spriteYScale = self.bgSprite:GetAttri("scale")
    self.width = 30
    self.height = 10
    self.posX = 0
    self.posY = 0
    self.enable = true
    self.isVisible = true
    self.isTipToolWindow = false
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

    self.receiverOfRequestMoveWindow = nil
    self.receiverOfRequestCloseWindow = nil

    -- connect
    self.titleBar:SetReceiverOfRequestMoveWindow(self)
    self.titleBar:SetReceiverOfRequestCloseWindow(self)
end

function Window:Update(dt)
    if false == self.isVisible then
        return
    end
    self.titleBar:Update(dt)

    self.contentWidget:Update(dt)
end

function Window:Draw()
    self:MouseEvent()

    if false == self.isVisible then
        return
    end

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

---@param name string
function Window:SetObjName(name)
    self.objName = name
end

function Window:GetObjName()
    return self.objName
end

function Window:SetPosition(x, y)
    self.bgSprite:SetAttri("position", x, y)
    self.posX = x
    self.posY = y

    local realTitleBarHeight = 0
    if self.titleBar:IsVisible() then
        realTitleBarHeight = TitleBarHeight
    end
    self.contentWidget:SetPosition(x + MarginSpace, y + MarginSpace + realTitleBarHeight)

    self.titleBar:SetPosition(x, y)
end

function Window:SetSize(width, height)
    self.width = width
    self.height = height

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

    _Graphics.SetCanvas()
    self.bgSprite:SetImage(canvas)
    self.bgSprite:AdjustDimensions()

    -- content
    local realTitleBarHeight = 0
    if self.titleBar:IsVisible() then
        realTitleBarHeight = TitleBarHeight
    end
    self.contentWidget:SetSize(self.width - MarginSpace * 2,
        self.height - MarginSpace * 2 - realTitleBarHeight)

    -- 设置标题栏尺寸
    self.titleBar:SetSize(self.width, TitleBarHeight)
end

---@return integer, integer
function Window:GetSize()
    return self.width, self.height
end

function Window:SetEnable(enable)
    self.enable = enable
end

--- 是否可见
---@return boolean visible
function Window:IsVisible()
    return self.isVisible
end

--- 设置是否可见
---@param visible boolean
function Window:SetVisible(visible)
    self.isVisible = visible
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

function Window:OnRequestMoveWindow(x, y)
    self:judgeAndExecRequestMoveWindow(x, y)
end

function Window:OnRequestCloseWindow()
    self:judgeAndExecRequestCloseWindow()
end

function Window:SetReceiverOfRequestMoveWindow(receiver)
    self.receiverOfRequestMoveWindow = receiver
end

function Window:judgeAndExecRequestMoveWindow(x, y)
    if nil == self.receiverOfRequestMoveWindow then
        return
    end
    if nil == self.receiverOfRequestMoveWindow.OnRequestMoveWindow then
        return
    end

    self.receiverOfRequestMoveWindow.OnRequestMoveWindow(self, x, y)
end

function Window:SetReceiverOfRequestCloseWindow(receiver)
    self.receiverOfRequestCloseWindow = receiver
end

function Window:judgeAndExecRequestCloseWindow(x, y)
    if nil == self.receiverOfRequestCloseWindow then
        return
    end
    if nil == self.receiverOfRequestCloseWindow.OnRequestCloseWindow then
        return
    end

    self.receiverOfRequestCloseWindow.OnRequestCloseWindow(self)
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
    if self.isTipToolWindow then
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

---@param widget Widget
function Window:SetContentWidget(widget)
    self.contentWidget = widget

    local realTitleBarHeight = 0
    if self.titleBar:IsVisible() then
        realTitleBarHeight = TitleBarHeight
    end
    self.contentWidget:SetPosition(self.posX + MarginSpace, self.posY + MarginSpace + realTitleBarHeight)
    self.contentWidget:SetSize(self.width - MarginSpace * 2,
        self.height - MarginSpace * 2 - realTitleBarHeight)
end

return Window
