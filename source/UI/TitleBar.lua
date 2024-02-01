--[[
	desc: Window class.
	author: keke <243768648@qq.com>
	since: 2022-11-15
	alter: 2022-11-15
]] --

local Util = require("util.Util")

local _CONFIG = require("config")
local _RESOURCE = require("lib.resource")
local _Sprite = require("graphics.drawable.sprite")
local _Graphics = require("lib.graphics")
local _Mouse = require("lib.mouse")

local WindowManager = require("UI.WindowManager")
local PushButton = require("UI.PushButton")
local Widget = require("UI.Widget")

---@class TitleBar
local TitleBar = require("core.class")(Widget)

local TitleBarMargin = 30

---@param parentWindow Window
function TitleBar:Ctor(parentWindow)
    Widget.Ctor(self, parentWindow)

    TitleBarMargin = 30 * Util.GetWindowSizeScale()

    -- 请求移动窗口位置信号的接收者
    self.receiverOfRequestMoveWindow = nil
    self.requestMoveWindow = false -- 是否请求移动窗口
    self.originMouseXPosWhenReqMvWindow = 0 -- 当请求移动窗口时原始鼠标位置，用于计算窗口移动偏差
    self.originMouseYPosWhenReqMvWindow = 0
    self.originXPosWhenReqMvWindow = 0 -- 当请求移动窗口时原始自身位置，用于计算窗口移动偏差
    self.originYPosWhenReqMvWindow = 0

    -- 背景图片数据
    self.frameSprite = _Sprite.New()
    self.frameSprite:SwitchRect(true) -- 使用矩形
    self.spriteXScale, self.spriteYScale = self.frameSprite:GetAttri("scale")
    self.leftFrameImgData = _RESOURCE.GetSpriteData("ui/TitleBar/LeftFrame")
    self.centerFrameImgData = _RESOURCE.GetSpriteData("ui/TitleBar/CenterFrame")
    self.rightFrameImgData = _RESOURCE.GetSpriteData("ui/TitleBar/RightFrame")

    -- 上一帧时是否被按压
    self.lastIsPressed = false

    self.leftMargin = 2
    self.topMargin = 2
    self.rightMargin = 2
    self.bottomMargin = 0

    -- 图标
    self.iconSprite = _Sprite.New()
    local spriteData = _RESOURCE.GetSpriteData("ui/TitleBar/TaskIcon")
    self.iconSprite:SetData(spriteData)
    self.iconLeftMargin = 2
    self.iconTopMargin = 2
    self.iconRightMargin = 2
    self.iconBottomMargin = 2

    -- 关闭按钮
    self.closeBtn = PushButton.New(self.parentWindow)
    self.closeBtn:SetNormalSpriteDataPath("ui/CloseButton/normal")
    self.closeBtn:SetHoveringSpriteDataPath("ui/CloseButton/hovering")
    self.closeBtn:SetPressingSpriteDataPath("ui/CloseButton/pressing")
    self.closeBtn:SetDisabledSpriteDataPath("ui/CloseButton/disable")

    -- 请求关闭窗口的接收者
    ---@type Window
    self.receiverOfRequestCloseWindow = nil

    -- connect
    self.closeBtn:MocConnectSignal(self.closeBtn.Signal_Clicked, self)

    -- post init
    self:adjustScaleByMargin()
end

function TitleBar:Update(dt)
    if false == self.isVisible then
        Widget.Update(self, dt)
        return
    end

    self:MouseEvent()
    
    if (Widget.IsSizeChanged(self)
        )
    then
        self:PaintEvent()
    end

    self.closeBtn:Update(dt)

    Widget.Update(self, dt)
end

function TitleBar:Draw()
    if false == self.isVisible then
        return
    end
    
    self.frameSprite:Draw()
    self.iconSprite:Draw()
    self.closeBtn:Draw()
end

function TitleBar:PaintEvent()
    -- image
    local frameCanvas = self:createFrameCanvasBySize(self.width, self.height)
    self.frameSprite:SetImage(frameCanvas)
    self.frameSprite:AdjustDimensions() -- 设置图片后调整精灵维度

    self:adjustScaleByMargin()

    Widget.PaintEvent(self)
end

function TitleBar:MouseEvent()
    -- 检查是否有上层窗口遮挡
    local windowLayerIndex = self.parentWindow:GetWindowLayerIndex()
    if WindowManager.IsMouseCapturedAboveLayer(windowLayerIndex) then
        return
    end

    self:judgeAndExecRequestMoveWindow()
end

-- 设置请求移动窗口位置时执行的函数
---@param receiver Window
function TitleBar:SetReceiverOfRequestMoveWindow(receiver)
    self.receiverOfRequestMoveWindow = receiver
end

function TitleBar:SetPosition(x, y)
    Widget.SetPosition(self, x, y)

    local closeBtnWidth = self.closeBtn:GetWidth()
    self.closeBtn:SetPosition(x + self.width - self.rightMargin - closeBtnWidth - 10,
        y + self.topMargin + 15 * Util.GetWindowSizeScale())

    -- position
    self.frameSprite:SetAttri("position", self.xPos + self.leftMargin, self.yPos + self.topMargin)
    self.iconSprite:SetAttri("position", self.xPos + self.leftMargin + self.iconLeftMargin,
        self.yPos + self.topMargin + self.iconTopMargin)
end

function TitleBar:SetSize(width, height)
    -- 关闭按钮
    self.closeBtn:SetSize(height - TitleBarMargin, height - TitleBarMargin)

    Widget.SetSize(self, width, height)
end

function TitleBar:SetEnable(enable)
    self.enable = enable
end

--- 设置是否可见
---@param visible boolean
function TitleBar:SetVisible(visible)
    self.isVisible = visible
end

--- 是否可见
---@return visible boolean
function TitleBar:IsVisible()
    return self.isVisible
end

function TitleBar:SetScale(xScale, yScale)
    self.spriteXScale = xScale
    self.spriteYScale = yScale

    self:adjustScaleByMargin()
end

function TitleBar:adjustScaleByMargin()
    -- 调整间距
    local spriteDisplayXScale = (self.width - self.leftMargin - self.rightMargin) / self.width * self.spriteXScale
    local spriteDisplayYScale = (self.height - self.topMargin - self.bottomMargin) / self.height * self.spriteYScale
    self.frameSprite:SetAttri("scale", spriteDisplayXScale, spriteDisplayYScale)

    -- 图标
    local iconSpriteWidth, iconSpriteHeight = self.iconSprite:GetImageDimensions()
    local iconSpriteDisplayXScale = (self.height - self.iconLeftMargin - self.iconRightMargin) / iconSpriteWidth * self.spriteXScale
    local iconSpriteDisplayYScale = (self.height - self.iconTopMargin - self.iconBottomMargin) / iconSpriteHeight * self.spriteYScale
    self.iconSprite:SetAttri("scale", iconSpriteDisplayXScale, iconSpriteDisplayYScale)
end

function TitleBar:createFrameCanvasBySize(width, height)
    -- 创建背景画布
    local canvas = _Graphics.NewCanvas(width, height)
    _Graphics.SetCanvas(canvas)

    local allYScale = height / self.centerFrameImgData.h

    -- 创建临时绘图精灵
    local painterSprite = _Sprite.New()
    -- 画左侧图片
    painterSprite:SetData(self.leftFrameImgData)
    painterSprite:SetAttri("position", 0, 0)
    painterSprite:SetAttri("scale", 1, allYScale)
    painterSprite:Draw()
    -- 画中间图片
    painterSprite:SetData(self.centerFrameImgData)
    painterSprite:SetAttri("position", self.leftFrameImgData.w, 0)
    local centerXScale = (width - self.leftFrameImgData.w - self.rightFrameImgData.w) / self.centerFrameImgData.w
    painterSprite:SetAttri("scale", centerXScale, allYScale)
    painterSprite:Draw()

    -- 画右侧图片
    painterSprite:SetData(self.rightFrameImgData)
    painterSprite:SetAttri("position", width - self.rightFrameImgData.w, 0)
    painterSprite:SetAttri("scale", 1, allYScale)
    painterSprite:Draw()

    _Graphics.SetCanvas()
    return canvas
end

function TitleBar:judgeAndExecRequestMoveWindow()
    if nil == self.receiverOfRequestMoveWindow then
        return
    end

    if nil == self.receiverOfRequestMoveWindow.OnRequestMoveWindow then
        return
    end

    local currentMouseXPos = 0
    local currentMouseYPos = 0
    -- 判断鼠标
    while true do
        -- 是否处于按压中
        if false == _Mouse.IsHold(1) then -- 1 is the primary mouse button, 2 is the secondary mouse button and 3 is the middle button
            self.requestMoveWindow = false
            self.parentWindow:SetIsInMoving(false)
            break
        end

        -- 获取当前鼠标位置
        currentMouseXPos, currentMouseYPos = _Mouse.GetPosition(1, 1)
        -- 如果正处于请求移动窗口中，则直接退出循环执行移动窗口逻辑
        if self.requestMoveWindow then
            break
        end

        if not self.lastIsPressed then
            break
        end

        -- 确保鼠标在按钮上
        if false == self.frameSprite:CheckPoint(currentMouseXPos, currentMouseYPos)
            or self.closeBtn:CheckPoint(currentMouseXPos, currentMouseYPos) then
            break
        end

        -- 请求移动窗口
        self.requestMoveWindow = true
        self.parentWindow:SetIsInMoving(true)
        self.originMouseXPosWhenReqMvWindow = currentMouseXPos
        self.originMouseYPosWhenReqMvWindow = currentMouseYPos
        self.originXPosWhenReqMvWindow = self.xPos
        self.originYPosWhenReqMvWindow = self.yPos
        break
    end


    if _Mouse.IsPressed(1) then
        self.lastIsPressed = true
    else
        self.lastIsPressed = false
    end

    if self.requestMoveWindow then
        local destXPos = self.originXPosWhenReqMvWindow + currentMouseXPos - self.originMouseXPosWhenReqMvWindow
        local destYPos = self.originYPosWhenReqMvWindow + currentMouseYPos - self.originMouseYPosWhenReqMvWindow
        self.receiverOfRequestMoveWindow:OnRequestMoveWindow(destXPos, destYPos)
    end
end

function TitleBar:SetIconSpriteDataPath(path)
    local spriteData = _RESOURCE.GetSpriteData(path)
    self.iconSprite:SetData(spriteData)

    self:adjustScaleByMargin()
end

---@param sender PushButton
function TitleBar:Slot_BtnClicked(sender)
    if sender == self.closeBtn then
        self:judgeAndExecRequestCloseWindow()
    end
end

function TitleBar:SetReceiverOfRequestCloseWindow(receiver)
    self.receiverOfRequestCloseWindow = receiver
end

function TitleBar:judgeAndExecRequestCloseWindow()
    if nil == self.receiverOfRequestCloseWindow then
        return
    end
    if nil == self.receiverOfRequestCloseWindow.OnRequestCloseWindow then
        return
    end

    self.receiverOfRequestCloseWindow:OnRequestCloseWindow()
end

return TitleBar
