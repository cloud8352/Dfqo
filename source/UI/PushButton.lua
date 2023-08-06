--[[
	desc: PushButton class.
	author: keke <243768648@qq.com>
	since: 2022-11-15
	alter: 2022-11-15
]] --

local _CONFIG = require("config")
local _RESOURCE = require("lib.resource")
local _Sprite = require("graphics.drawable.sprite")
local _Graphics = require("lib.graphics")
local _Mouse = require("lib.mouse")

local WindowManager = require("UI.WindowManager")
local Label = require("UI.Label")

---@class PushButton
local PushButton = require("core.class")()

local DisplayState = {
    Unknown = 0,
    Normal = 1,
    Hovering = 2,
    Pressing = 3,
    Disable = 4,
}

---@param parentWindow Window
function PushButton:Ctor(parentWindow)
    assert(parentWindow, "must assign parent window")
    ---@type Window
    self.parentWindow = parentWindow

    self.normalSpriteData = _RESOURCE.GetSpriteData("ui/PushButton/normal")
    self.hoveringImgData = _RESOURCE.GetSpriteData("ui/PushButton/hovering")
    self.pressingImgData = _RESOURCE.GetSpriteData("ui/PushButton/pressing")
    self.disableImgData = _RESOURCE.GetSpriteData("ui/PushButton/disable")

    -- clicked sound
    self.clickedSoundSource = _RESOURCE.NewSource("asset/sound/ui/btn_clicked.wav")

    ---@type Graphics.Drawable | Graphics.Drawable.IRect | Graphics.Drawable.IPath | Graphics.Drawable.Sprite
    self.bgSprite = nil -- 背景，默认无背景
    ---@type Graphics.Drawable | Graphics.Drawable.IRect | Graphics.Drawable.IPath | Graphics.Drawable.Sprite
    self.sprite = _Sprite.New()
    self.sprite:SwitchRect(true) -- 使用矩形

    -- content margins
    self.leftMargin = 0
    self.topMargin = 0
    self.rightMargin = 0
    self.bottomMargin = 0
    self.isContentsMarginsUpdated = true

    self.width = 30
    self.height = 10
    self.isSizeUpdated = true
    self.xPos = 0
    self.yPos = 0
    self.isPosUpdated = true
    self.enable = true
    self.isVisible = true
    self.isDisplayStateUpdated = true
    self.lastDisplayState = DisplayState.Unknown
    self.displayState = DisplayState.Normal
    self.isbgSpriteUpdated = true

    self.textLabel = Label.New(self.parentWindow)
    self.isTextUpdated = true

    -- 按钮点击信号的接收者
    self.receiverOfBtnClicked = nil
end

function PushButton:Update(dt)
    if false == self.isVisible then
        return
    end
    self:MouseEvent()

    if (self.isContentsMarginsUpdated
        or self.isSizeUpdated
        or self.isPosUpdated
        or self.isDisplayStateUpdated
        or self.isbgSpriteUpdated
        or self.isTextUpdated)
        then
        self:updateSprites()
    end

    self.textLabel:Update(dt)

    self.isContentsMarginsUpdated = false
    self.isSizeUpdated = false
    self.isPosUpdated = false
    self.isDisplayStateUpdated = false
    self.isbgSpriteUpdated = false
    self.isTextUpdated = false
end

function PushButton:Draw()
    if false == self.isVisible then
        return
    end

    if nil ~= self.bgSprite then
        self.bgSprite:Draw()
    end

    self.sprite:Draw()
    self.textLabel:Draw()
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

    -- 根据状态设置按钮图片
    if self.lastDisplayState ~= self.displayState then
        if DisplayState.Normal == self.displayState then
            self.sprite:SetData(self.normalSpriteData)
        elseif DisplayState.Hovering == self.displayState then
            self.sprite:SetData(self.hoveringImgData)
        elseif DisplayState.Pressing == self.displayState then
            -- 播放点击音效
            self.clickedSoundSource:stop()
            self.clickedSoundSource:setVolume(_CONFIG.setting.sound)
            self.clickedSoundSource:play()
            -- 设置按钮图片
            self.sprite:SetData(self.pressingImgData)
        elseif DisplayState.Disable == self.displayState then
            self.sprite:SetData(self.disableImgData)
        end
        self.isDisplayStateUpdated = true
    end

    -- 释放点击后
    if self.lastDisplayState == DisplayState.Pressing 
        and self.displayState ~= DisplayState.Pressing 
        then
        -- 判断和执行点击触发事件
        self:judgeAndExecClicked()
    end

    self.lastDisplayState = self.displayState
end

---@param path string
function PushButton:SetBgSpriteDataPath(path)
    local spriteData = _RESOURCE.GetSpriteData(path)

    if nil == self.bgSprite then
        self.bgSprite = _Sprite.New()
    end
    self.bgSprite:SetData(spriteData)
end

---@param path string
function PushButton:SetNormalSpriteDataPath(path)
    self.normalSpriteData = _RESOURCE.GetSpriteData(path)
end

---@param path string
function PushButton:SetHoveringSpriteDataPath(path)
    self.hoveringImgData = _RESOURCE.GetSpriteData(path)
end

---@param path string
function PushButton:SetPressingSpriteDataPath(path)
    self.pressingImgData = _RESOURCE.GetSpriteData(path)
end

---@param path string
function PushButton:SetDisabledSpriteDataPath(path)
    self.disableImgData = _RESOURCE.GetSpriteData(path)
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

---@param x int
---@param y int
function PushButton:SetPosition(x, y)
    self.xPos = x
    self.yPos = y

    self.isPosUpdated = true
end

---@return int, int @宽，高
function PushButton:GetSize()
    return self.width, self.height
end

function PushButton:GetWidth()
    return self.width
end

function PushButton:GetHeight()
    return self.height
end

function PushButton:SetSize(width, height)
    self.width = width
    self.height = height

    self.isSizeUpdated = true
end

function PushButton:SetText(text)
    self.textLabel:SetText(text)

    self.isTextUpdated = true
end

function PushButton:SetEnable(enable)
    self.enable = enable
end

function PushButton:IsVisible()
    return self.isVisible
end

---@param isVisible bool
function PushButton:SetVisible(isVisible)
    self.isVisible = isVisible
end

function PushButton:SetReceiverOfBtnClicked(receiver)
    self.receiverOfBtnClicked = receiver
end

function PushButton:judgeAndExecClicked()
    if nil == self.receiverOfBtnClicked then
        return
    end

    if nil == self.receiverOfBtnClicked.OnBtnsClicked then
        return
    end

    -- 向接收者请求点击触发事件
    self.receiverOfBtnClicked.OnBtnsClicked(self.receiverOfBtnClicked, self)
end

function PushButton:CheckPoint(x, y)
    return self.sprite:CheckPoint(x, y)
end

function PushButton:updateSprites()
    if nil ~= self.bgSprite then
        -- 更新 bgSprite
        local bgSpriteWidth, bgSpriteHeight = self.bgSprite:GetImageDimensions()
        local bgSpriteXScale = (self.width / bgSpriteWidth)
        local bgSpriteYScale = (self.height / bgSpriteHeight)
        self.bgSprite:SetAttri("scale", bgSpriteXScale, bgSpriteYScale)
        self.bgSprite:SetAttri("position", self.xPos, self.yPos)
    end

    -- 更新 sprite
    local spriteWidth, spriteHeight = self.sprite:GetImageDimensions()
    local spriteXScale = (self.width - self.leftMargin - self.rightMargin) / spriteWidth
    local spriteYScale = (self.height - self.topMargin - self.bottomMargin) / spriteHeight
    self.sprite:SetAttri("scale", spriteXScale, spriteYScale)
    self.sprite:SetAttri("position", self.xPos + self.leftMargin, self.yPos + self.topMargin)

    self.textLabel:SetSize(self.width - self.leftMargin - self.rightMargin, self.height - self.topMargin - self.bottomMargin)
    self.textLabel:SetPosition(self.xPos + self.leftMargin, self.yPos + self.topMargin)
end

return PushButton
