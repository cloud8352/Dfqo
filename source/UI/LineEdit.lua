--[[
	desc: LineEdit class.
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

---@class LineEdit : Widget
local LineEdit = require("core.class")(Widget)

local NormalImgPath = "ui/PushButton/Rectangle/Normal"

---@param parentWindow Window
function LineEdit.Create(parentWindow)
    -- 用于定义构造函数，解释使用，不做实际用途
    -- 使用class模块后，实际会调用Ctor函数
    return LineEdit.New(parentWindow)
end

---@param parentWindow Window
function LineEdit:Ctor(parentWindow)
    Widget.Ctor(self, parentWindow)
    self:SetBgSpriteColor(0, 0, 0, 0)

    self.label = Label.Create(parentWindow)
    self.label:SetIconSpriteDataPath(NormalImgPath)
    self.label:SetAlignments({Label.AlignmentFlag.AlignLeft, Label.AlignmentFlag.AlignVCenter})
end

function LineEdit:Update(dt)
    if false == self.isVisible then
        return
    end

    self.label:Update(dt)

    Widget.Update(self, dt)
end

function LineEdit:Draw()
    if false == self.isVisible then
        return
    end
    Widget.Draw(self)

    self.label:Draw()
end

--- 连接信号
---@param signal function
---@param obj Object
function LineEdit:MocConnectSignal(signal, receiver)
    Widget.MocConnectSignal(self, signal, receiver)
end

---@param signal function
function LineEdit:GetReceiverListOfSignal(signal)
    return Widget.GetReceiverListOfSignal(self, signal)
end

---@param name string
function LineEdit:SetObjectName(name)
    Widget.SetObjectName(self, name)
end

function LineEdit:GetObjectName()
    return Widget.GetObjectName(self)
end

---@param x int
---@param y int
function LineEdit:SetPosition(x, y)
    Widget.SetPosition(self, x, y)

    self.label:SetPosition(x, y)
end

---@return int, int 横坐标， 纵坐标
function LineEdit:GetPosition()
    return Widget.GetPosition(self)
end

---@return int, int @宽，高
function LineEdit:GetSize()
    return Widget.GetSize(self)
end

function LineEdit:GetWidth()
    return self.width
end

function LineEdit:GetHeight()
    return self.height
end

function LineEdit:SetSize(width, height)
    Widget.SetSize(self, width, height)

    self.label:SetSize(width, height)
    self.label:SetIconSize(width, height)
end

function LineEdit:SetEnable(enable)
    Widget.SetEnable(self, enable)
end

function LineEdit:IsVisible()
    return Widget.IsVisible(self)
end

---@param isVisible bool
function LineEdit:SetVisible(isVisible)
    Widget.SetVisible(self, isVisible)
end

function LineEdit:CheckPoint(x, y)
    return Widget.CheckPoint(self, x, y)
end

---@param text string
function LineEdit:SetText(text)
    self.label:SetText(text)
end

function LineEdit:GetText()
    return self.label:GetText()
end

return LineEdit
