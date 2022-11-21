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

    self.sprite = _Sprite.New()
    self.sprite:SwitchRect(true) -- 使用矩形
    self.spriteXScale, self.spriteYScale = self.sprite:GetAttri("scale")
    self.text = ""
    self.width = 30
    self.height = 10
    self.posX = 0
    self.posY = 0
    self.lastDisplayState = DisplayState.Unknown
    self.displayState = DisplayState.Normal
    self.enable = true

    -- 请求移动窗口位置信号的接收者
    self.receiverOfBtnClicked = nil
end

function PushButton:Update(dt)
    self:MouseEvent()
end

function PushButton:Draw()
    self.sprite:Draw()
    
    -- 计算文字居中显示时所处坐标
    local textPosX = self.posX + self.width * self.spriteXScale / 2 - _Graphics.GetFontWidth(self.text)* self.spriteXScale / 2
    local textPosY = self.posY + self.height * self.spriteYScale / 2 - _Graphics.GetFontHeight() * self.spriteYScale / 2
    _Graphics.Print(self.text, textPosX, textPosY, 0, self.spriteXScale, self.spriteYScale, 0, 0)
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
        if WindowManager.IsMouseCapturedAboveLayer(windowLayerIndex) then
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
        local spriteWidth, spriteHeight = self.sprite:GetImageDimensions()
        local spriteXScale = (self.width / spriteWidth) * self.spriteXScale
        local spriteYScale = (self.height / spriteHeight) * self.spriteYScale
        self.sprite:SetAttri("scale", spriteXScale, spriteYScale)
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

function PushButton:SetNormalSpriteDataPath(path)
    self.normalSpriteData = _RESOURCE.GetSpriteData(path)
end

function PushButton:SetHoveringSpriteDataPath(path)
    self.hoveringImgData = _RESOURCE.GetSpriteData(path)
end

function PushButton:SetPressingSpriteDataPath(path)
    self.pressingImgData = _RESOURCE.GetSpriteData(path)
end

function PushButton:SetDisableSpriteDataPath(path)
    self.disableImgData = _RESOURCE.GetSpriteData(path)
end

function PushButton:SetPosition(x, y)
    self.sprite:SetAttri("position", x, y)
    self.posX = x
    self.posY = y
end

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
end

function PushButton:SetText(text)
    self.text = text
end

function PushButton:SetEnable(enable)
    self.enable = enable
end

function PushButton:SetScale(xScale, yScale)
    self.spriteXScale = xScale
    self.spriteYScale = yScale
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
    self.receiverOfBtnClicked:OnBtnsClicked(self)
end

function PushButton:CheckPoint(x, y)
    return self.sprite:CheckPoint(x, y)
end

return PushButton
