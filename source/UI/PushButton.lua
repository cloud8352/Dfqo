--[[
	desc: PushButton class.
	author: keke <243768648@qq.com>
]]--

local Widget = require("UI.Widget")
local WindowManager = require("UI.WindowManager")
local Label = require("UI.Label")

local _CONFIG = require("config")
local _RESOURCE = require("lib.resource")
local _Sprite = require("graphics.drawable.sprite")
local _Graphics = require("lib.graphics")
local _Mouse = require("lib.mouse")
local Touch = require("lib.touch")
local SysLib = require("lib.system")

---@class PushButton : Widget
local PushButton = require("core.class")(Widget)

local DisplayState = {
    Unknown = 0,
    Normal = 1,
    Hovering = 2,
    Pressing = 3,
    Disable = 4,
}

---@param parentWindow Window
function PushButton:Ctor(parentWindow)
    Widget.Ctor(self, parentWindow)

    self.normalSpriteData = _RESOURCE.GetSpriteData("ui/PushButton/normal")
    self.hoveringSpriteData = _RESOURCE.GetSpriteData("ui/PushButton/hovering")
    self.pressingSpriteData = _RESOURCE.GetSpriteData("ui/PushButton/pressing")
    self.disableSpriteData = _RESOURCE.GetSpriteData("ui/PushButton/disable")
    self.whetherSpriteDataUpdate = true

    -- clicked sound
    self.clickedSoundSource = _RESOURCE.NewSource("asset/sound/ui/btn_clicked.wav")
    self.whetherEnableClickedSound = true

    ---@type Graphics.Drawable.Sprite
    self.sprite = _Sprite.New()
    self.sprite:SwitchRect(true) -- 使用矩形

    -- content margins
    self.leftMargin = 0
    self.topMargin = 0
    self.rightMargin = 0
    self.bottomMargin = 0
    self.isContentsMarginsUpdated = true

    self.lastDisplayState = DisplayState.Unknown
    self.displayState = DisplayState.Normal

    self.textLabel = Label.New(self.parentWindow)
    self.isTextUpdated = true
    self.isPressing = false

    -- mask sprite
    self.maskSprite = _Sprite.New()
    self.maskPercent = 1.0
    self.isMaskPercentUpdated = true

    self.opacity = 1.0
    self.opacityChanged = true
end

function PushButton:Update(dt)
    if false == self.isVisible then
        return
    end
    if not SysLib.IsMobile() then
        self:MouseEvent()
    else
        self:TouchEvent()
    end
    self:judgeSignals()

    if self.isContentsMarginsUpdated
        or self:IsSizeChanged()
        or self.whetherSpriteDataUpdate
        or self.lastDisplayState ~= self.displayState
        or self.isMaskPercentUpdated
        or self.isTextUpdated
        or self.opacityChanged
    then
        self:updateSprites()
    end

    self.textLabel:Update(dt)

    self.isContentsMarginsUpdated = false
    self.whetherSpriteDataUpdate = false
    self.isMaskPercentUpdated = false
    self.isTextUpdated = false
    self.lastDisplayState = self.displayState
    self.opacityChanged = false

    Widget.Update(self, dt)
end

function PushButton:Draw()
    if false == self.isVisible then
        return
    end
    Widget.Draw(self)

    self.sprite:Draw()
    self.textLabel:Draw()
    self.maskSprite:Draw()
end

function PushButton:MouseEvent()
    -- 判断鼠标
    while true do
        -- 是否处于禁用状态
        if false == self.enable then
            self.displayState = DisplayState.Disable
            break
        end

        -- 检查是否有上层窗口遮挡
        local windowLayerIndex = self.parentWindow:GetWindowLayerIndex()
        if WindowManager.IsMouseCapturedAboveLayer(windowLayerIndex)
            or self.parentWindow:IsInMoving() then
            self.displayState = DisplayState.Normal
            break
        end

        -- 确保鼠标在按钮上
        local mousePosX, mousePosY = _Mouse.GetPosition(1, 1)
        if false == self.sprite:CheckPoint(mousePosX, mousePosY) then
            self.displayState = DisplayState.Normal
            break
        end

        -- 是否处于按压中
        if _Mouse.IsHold(1) then -- 1 is the primary mouse button, 2 is the secondary mouse button and 3 is the middle button
            self.displayState = DisplayState.Pressing
            break
        end

        -- 处于悬停中
        self.displayState = DisplayState.Hovering
        break
    end
end

function PushButton:TouchEvent()
    -- 判断鼠标
    while true do
        -- 是否处于禁用状态
        if false == self.enable then
            self.displayState = DisplayState.Disable
            break
        end

        -- 检查是否有上层窗口遮挡
        local capturedTouchIdList = WindowManager.GetWindowCapturedTouchIdList(self.parentWindow)
        if #capturedTouchIdList == 0
            or self.parentWindow:IsInMoving() then
            self.displayState = DisplayState.Normal
            break
        end

        ---@param sprite Graphics.Drawable.Sprite
        ---@param idList table<number, string>
        ---@return id string
        local function getSpriteTouchedId(sprite, idList)
            for _, id in pairs(idList) do
                local point = Touch.GetPoint(id)
                if (sprite:CheckPoint(point.x, point.y)) then
                    return id
                end
            end

            return ""
        end

        -- 确保触控点在按钮上
        local touchedId = getSpriteTouchedId(self.sprite, capturedTouchIdList)
        if "" == touchedId then
            self.displayState = DisplayState.Normal
            break
        end

        -- 是否处于按压中
        local point = Touch.GetPoint(touchedId)
        if (Touch.WhetherPointIsHold(point)) then
            self.displayState = DisplayState.Pressing
            break
        end

        -- 处于悬停中
        self.displayState = DisplayState.Hovering
        break
    end
end

--- 连接信号
---@param signal function
---@param obj Object
function PushButton:MocConnectSignal(signal, receiver)
    Widget.MocConnectSignal(self, signal, receiver)
end

---@param signal function
function PushButton:GetReceiverListOfSignal(signal)
    return Widget.GetReceiverListOfSignal(self, signal)
end

---@param name string
function PushButton:SetObjectName(name)
    Widget.SetObjectName(self, name)
end

function PushButton:GetObjectName()
    return Widget.GetObjectName(self)
end

---@param x int
---@param y int
function PushButton:SetPosition(x, y)
    Widget.SetPosition(self, x, y)

    self.textLabel:SetPosition(x, y)

    self.sprite:SetAttri("position", self.xPos + self.leftMargin, self.yPos + self.topMargin)
    self.maskSprite:SetAttri("position", self.xPos, self.yPos)
end

---@return int, int 横坐标， 纵坐标
function PushButton:GetPosition()
    return Widget.GetPosition(self)
end

---@return int, int @宽，高
function PushButton:GetSize()
    return Widget.GetSize(self)
end

function PushButton:GetWidth()
    return self.width
end

function PushButton:GetHeight()
    return self.height
end

function PushButton:SetSize(width, height)
    Widget.SetSize(self, width, height)
end

function PushButton:SetText(text)
    self.textLabel:SetText(text)

    self.isTextUpdated = true
end

function PushButton:SetEnable(enable)
    Widget.SetEnable(self, enable)
end

function PushButton:IsVisible()
    return Widget.IsVisible(self)
end

---@param isVisible bool
function PushButton:SetVisible(isVisible)
    Widget.SetVisible(self, isVisible)
end

function PushButton:CheckPoint(x, y)
    return Widget.CheckPoint(self, x, y)
end

---@param path string
function PushButton:SetBgSpriteDataPath(path)
    local spriteData = _RESOURCE.GetSpriteData(path)
    self.bgSprite:SetData(spriteData)
end

---@param path string
function PushButton:SetNormalSpriteDataPath(path)
    if (path == "" or path == nil) then
        return
    end
    self.normalSpriteData = _RESOURCE.GetSpriteData(path)
    self.whetherSpriteDataUpdate = true
end

---@param path string
function PushButton:SetHoveringSpriteDataPath(path)
    self.hoveringSpriteData = _RESOURCE.GetSpriteData(path)
end

---@param path string
function PushButton:SetPressingSpriteDataPath(path)
    self.pressingSpriteData = _RESOURCE.GetSpriteData(path)
end

---@param path string
function PushButton:SetDisabledSpriteDataPath(path)
    self.disableSpriteData = _RESOURCE.GetSpriteData(path)
end

---@param left int
---@param top int
---@param right int
---@param bottom int
function PushButton:SetContentsMargins(left, top, right, bottom)
    self.leftMargin = left
    self.topMargin = top
    self.rightMargin = right
    self.bottomMargin = bottom

    self.isContentsMarginsUpdated = true
end

function PushButton:IsPressing()
    return self.isPressing
end

---@param percent number
function PushButton:SetMaskPercent(percent)
    if self.maskPercent == percent then
        return
    end
    self.maskPercent = percent
    self.isMaskPercentUpdated = true
end

---@param enable boolean
function PushButton:EnableClickedSound(enable)
    self.whetherEnableClickedSound = enable
end

---@param path string
function PushButton:SetClickedSoundSourceByPath(path)
    self.clickedSoundSource = _RESOURCE.NewSource(path)
end

---@param opacity num @ 0.0 - 1.0
function PushButton:SetOpacity(opacity)
    if opacity == self.opacity then
        return
    end
    self.opacity = opacity
    self.opacityChanged = true
end

--- 信号 - 被点击
function PushButton:Signal_BtnClicked()
    print("PushButton:Signal_BtnClicked()")
    local receiverList = self.mapOfSignalToReceiverList[self.Signal_BtnClicked]
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.Slot_BtnClicked
        if func == nil then
            goto continue
        end

        func(receiver, self)

        ::continue::
    end
end

function PushButton:updateSprites()
    --- 更新 sprite
    -- 根据状态设置按钮图片
    if DisplayState.Normal == self.displayState then
        self.sprite:SetData(self.normalSpriteData)
    elseif DisplayState.Hovering == self.displayState then
        self.sprite:SetData(self.hoveringSpriteData)
    elseif DisplayState.Pressing == self.displayState then
        if self.whetherEnableClickedSound then
            -- 播放点击音效
            self.clickedSoundSource:stop()
            self.clickedSoundSource:setVolume(_CONFIG.setting.sound)
            self.clickedSoundSource:play()
        end
        -- 设置按钮图片
        self.sprite:SetData(self.pressingSpriteData)

        self.isPressing = true
    elseif DisplayState.Disable == self.displayState then
        self.sprite:SetData(self.disableSpriteData)
    end

    local spriteWidth, spriteHeight = self.sprite:GetImageDimensions()
    local spriteXScale = (self.width - self.leftMargin - self.rightMargin) / spriteWidth
    local spriteYScale = (self.height - self.topMargin - self.bottomMargin) / spriteHeight
    self.sprite:SetAttri("scale", spriteXScale, spriteYScale)

    -- opacity
    local r, g, b, a = self.sprite:GetAttri("color")
    a = 255 * self.opacity
    self.sprite:SetAttri("color", r, g, b, a)

    self.textLabel:SetSize(self.width - self.leftMargin - self.rightMargin,
        self.height - self.topMargin - self.bottomMargin)
    self.textLabel:SetPosition(self.xPos + self.leftMargin, self.yPos + self.topMargin)

    self:updateMaskSprite()
end

function PushButton:updateMaskSprite()
    _Graphics.SaveCanvas()
    -- 创建背景画布
    local canvas = _Graphics.NewCanvas(self.width, self.height)
    _Graphics.SetCanvas(canvas)

    ---@type int
    local r, g, b, a
    _Graphics.SetColor(0, 0, 0, 200)
    local shadowHeight = self.height * (1 - self.maskPercent)
    _Graphics.DrawRect(0, self.height * self.maskPercent, self.width, shadowHeight, "fill")

    -- 还原绘图数据
    _Graphics.RestoreCanvas()

    self.maskSprite:SetImage(canvas)
    self.maskSprite:AdjustDimensions()

    -- opacity
    local r, g, b, a = self.maskSprite:GetAttri("color")
    a = 255 * self.opacity
    self.maskSprite:SetAttri("color", r, g, b, a)
end

function PushButton:judgeSignals()
    -- 释放点击后
    if self.lastDisplayState == DisplayState.Pressing
        and self.displayState ~= DisplayState.Pressing
    then
        self.isPressing = false

        -- 判断和执行点击触发事件
        self:Signal_BtnClicked()
    end
end

return PushButton
