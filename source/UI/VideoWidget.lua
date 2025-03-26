--[[
	desc: VideoWidget class.
	author: keke <243768648@qq.com>
]]--

local Widget = require("UI.Widget")
local WindowManager = require("UI.WindowManager")
local Label = require("UI.Label")

local _CONFIG = require("config")
local _RESOURCE = require("lib.resource")
local _Sprite = require("graphics.drawable.sprite")
local GraphicsLib = require("lib.graphics")
local _Mouse = require("lib.mouse")
local Touch = require("lib.touch")
local SysLib = require("lib.system")

---@class VideoWidget : Widget
local VideoWidget = require("core.class")(Widget)

---@param parentWindow Window
function VideoWidget.Create(parentWindow)
    -- 用于定义构造函数，解释使用，不做实际用途
    -- 使用class模块后，实际会调用Ctor函数
    return VideoWidget.New(parentWindow)
end

---@param parentWindow Window
function VideoWidget:Ctor(parentWindow)
    Widget.Ctor(self, parentWindow)

    ---@type love.Video
    self.video = nil
    self.isVideoChanged = false
    self.videoFilePath = ""
    self.isRepeat = false

    self.videoXScale = 1
    self.videoYScale = 1
end

function VideoWidget:Update(dt)
    if false == self.isVisible then
        return
    end

    if self.video == nil then
        return
    end

    if self:IsSizeChanged()
        or self.isVideoChanged
    then
        self.videoXScale = self.width / self.video:getWidth()
        self.videoYScale = self.height / self.video:getHeight()
    end

    if self.isRepeat and self:IsPlaying() == false then
        self:Play()
    end

    self.isVideoChanged = false
    Widget.Update(self, dt)
end

function VideoWidget:Draw()
    if false == self.isVisible then
        return
    end
    Widget.Draw(self)

    if self.video then
        GraphicsLib.DrawObj(self.video, self.xPos, self.yPos, 0,
            self.videoXScale, self.videoYScale)
    end
end

--- 连接信号
---@param signal function
---@param obj Object
function VideoWidget:MocConnectSignal(signal, receiver)
    Widget.MocConnectSignal(self, signal, receiver)
end

---@param signal function
function VideoWidget:GetReceiverListOfSignal(signal)
    return Widget.GetReceiverListOfSignal(self, signal)
end

---@param name string
function VideoWidget:SetObjectName(name)
    Widget.SetObjectName(self, name)
end

function VideoWidget:GetObjectName()
    return Widget.GetObjectName(self)
end

---@param x int
---@param y int
function VideoWidget:SetPosition(x, y)
    Widget.SetPosition(self, x, y)
end

---@return int, int 横坐标， 纵坐标
function VideoWidget:GetPosition()
    return Widget.GetPosition(self)
end

---@return int, int @宽，高
function VideoWidget:GetSize()
    return Widget.GetSize(self)
end

function VideoWidget:GetWidth()
    return self.width
end

function VideoWidget:GetHeight()
    return self.height
end

function VideoWidget:SetSize(width, height)
    Widget.SetSize(self, width, height)
end

function VideoWidget:SetEnable(enable)
    Widget.SetEnable(self, enable)
end

function VideoWidget:IsVisible()
    return Widget.IsVisible(self)
end

---@param isVisible bool
function VideoWidget:SetVisible(isVisible)
    Widget.SetVisible(self, isVisible)
end

function VideoWidget:CheckPoint(x, y)
    return Widget.CheckPoint(self, x, y)
end

---@param filePath string ogv video file path
function VideoWidget:SetVideoFilePath(filePath)
    if filePath == self.videoFilePath then
        return
    end
    if self.video then
        self.video:pause()
    end

    self.videoFilePath = filePath
    self.video = GraphicsLib.NewVideo(filePath)
    self.isVideoChanged = true
end

---@param video love.Video
function VideoWidget:SetVideo(video)
    if self.video == video then
        return
    end
    if self.video then
        self.video:pause()
    end

    self.video = video
    self.isVideoChanged = true
end

function VideoWidget:Play()
    if nil == self.video then
        return
    end

    self.video:play()
end

function VideoWidget:IsPlaying()
    if nil == self.video then
        return false
    end

    return self.video:isPlaying()
end

function VideoWidget:Pause()
    if nil == self.video then
        return
    end

    self.video:pause()
end

function VideoWidget:Rewind()
    if nil == self.video then
        return
    end

    self.video:rewind()
end

function VideoWidget:SetRepeat(is)
    self.isRepeat = is
end

return VideoWidget
