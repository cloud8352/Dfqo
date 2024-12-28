--[[
	desc: DirPadItemWidget class.
	author: keke <243768648@qq.com>
]] --

local Widget = require("UI.Widget")
local Label = require("UI.Label")

local WindowManager = require("UI.WindowManager")
local _RESOURCE = require("lib.resource")
local _Sprite = require("graphics.drawable.sprite")
local _Graphics = require("lib.graphics")
local TouchLib = require("lib.touch")


---@class DirPadItemWidget : Widget
local DirPadItemWidget = require("core.class")(Widget)

local NormalImgPath = "ui/PushButton/Rectangle/Normal"
local PressingImgPath = "ui/PushButton/Rectangle/Pressing"

---@param parentWindow Window
function DirPadItemWidget:Ctor(parentWindow)
    Widget.Ctor(self, parentWindow)

    self.isTransparent = false

    self.normalLabel = Label.New(parentWindow)
    self.normalLabel:SetIconSpriteDataPath(NormalImgPath)

    self.pressingLabel = Label.New(parentWindow)
    self.pressingLabel:SetIconSpriteDataPath(PressingImgPath)
    self.pressingLabel:SetVisible(false)
end

function DirPadItemWidget:Update(dt)
    if false == Widget.IsVisible(self) then
        return
    end

    if Widget.IsSizeChanged(self) then
        
    end

    self.normalLabel:Update(dt)
    self.pressingLabel:Update(dt)

    Widget.Update(self, dt)
end

function DirPadItemWidget:Draw()
    if (false == Widget.IsVisible(self)) then
        return
    end
    if self.isTransparent then
        return
    end
    Widget.Draw(self)

    self.normalLabel:Draw()
    self.pressingLabel:Draw()
end

---@param label Label
---@param idList table<number, string>
---@return id string
function DirPadItemWidget:getTouchedId(idList)
    for _, id in pairs(idList) do
        local point = TouchLib.GetPoint(id)
        if (self:CheckPoint(point.x, point.y)) then
            return id
        end
    end

    return ""
end

--- 连接信号
---@param signal function
---@param obj Object
function DirPadItemWidget:MocConnectSignal(signal, receiver)
    Widget.MocConnectSignal(self, signal, receiver)
end

---@param signal function
function DirPadItemWidget:GetReceiverListOfSignal(signal)
    return Widget.GetReceiverListOfSignal(self, signal)
end

---@param name string
function DirPadItemWidget:SetObjectName(name)
    Widget.SetObjectName(self, name)
end

function DirPadItemWidget:GetObjectName()
    return Widget.GetObjectName(self)
end

function DirPadItemWidget:GetParentWindow()
    return Widget.GetParentWindow(self)
end

function DirPadItemWidget:SetPosition(x, y)
    Widget.SetPosition(self, x, y)
    
    self.normalLabel:SetPosition(x, y)
    self.pressingLabel:SetPosition(x, y)
end

function DirPadItemWidget:GetPosition()
    return Widget.GetPosition(self)
end

---@param width int
---@param height int
function DirPadItemWidget:SetSize(width, height)
    Widget.SetSize(self, width, height)
    
    self.normalLabel:SetSize(width, height)
    self.normalLabel:SetIconSize(width, height)

    self.pressingLabel:SetSize(width, height)
    self.pressingLabel:SetIconSize(width, height)
end

function DirPadItemWidget:GetSize()
    return Widget.GetSize(self)
end

function DirPadItemWidget:IsSizeChanged()
    return Widget.IsSizeChanged(self)
end

function DirPadItemWidget:SetEnable(enable)
    Widget.SetEnable(self, enable)
end

function DirPadItemWidget:IsVisible()
    return Widget.IsVisible(self)
end

---@param isVisible bool
function DirPadItemWidget:SetVisible(isVisible)
    Widget.SetVisible(self, isVisible)
end

---@param sprite Graphics.Drawable.Sprite
function DirPadItemWidget:SetBgSprite(sprite)
    Widget.SetBgSprite(self, sprite)
end

function DirPadItemWidget:GetBgSprite()
    return Widget.GetBgSprite(self)
end

---@param x int
---@param y int
---@return boolean
function DirPadItemWidget:CheckPoint(x, y)
    return Widget.CheckPoint(self, x, y)
end

function DirPadItemWidget:SetIsPressing(pressing)
    if pressing then
        self.normalLabel:SetVisible(false)
        self.pressingLabel:SetVisible(true)
    else
        self.normalLabel:SetVisible(true)
        self.pressingLabel:SetVisible(false)
    end
end

function DirPadItemWidget:SetTransparent(is)
    self.isTransparent = is
end

return DirPadItemWidget
