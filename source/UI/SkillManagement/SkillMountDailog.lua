--[[
	desc: SkillMountDialog class. 技能装配对话框
	author: keke <243768648@qq.com>
]]--

local Util = require("util.Util")

local _CONFIG = require("config")
local _RESOURCE = require("lib.resource")
local _Sprite = require("graphics.drawable.sprite")
local _Graphics = require("lib.graphics")
local _Mouse = require("lib.mouse")
local _MATH = require("lib.math")
local Common = require("UI.ui_common")

local TitleBar = require("UI.TitleBar")
local WindowManager = require("UI.WindowManager")
local Window = require("UI.Window")
local SkillMountDialogContentWidget = require("UI.SkillManagement.SkillMountDialogContentWidget")

---@class SkillMountDialog
local SkillMountDialog = require("core.class")(Window)

---@param model UiModel
---@param skillInfo SkillInfo
function SkillMountDialog:Ctor(model)
    Window.Ctor(self)
    self.model = model
    self.needMountingSkillInfo = Common.NewSkillInfo()

    self:SetIsWindowStayOnTopHint(true)
    self:SetTitleBarIsBackgroundVisible(false)
    local width = 400 * Util.GetWindowSizeScale()
    local height = 233 * Util.GetWindowSizeScale()
    self:SetSize(width, height)
    -- 移到程序窗口中央
    Util.MoveWindowToCenter(self)

    WindowManager.AppendWindowWidget(self, self)
    WindowManager.SortWindowList()

    self.skillMountDialogContentWidget = SkillMountDialogContentWidget.New(self, model)
    self:SetContentWidget(self.skillMountDialogContentWidget)

    -- post init
end

function SkillMountDialog:Update(dt)
    if false == Window.IsVisible(self) then
        return
    end

    Window.Update(self, dt)
end

function SkillMountDialog:Draw()
    if false == Window.IsVisible(self) then
        return
    end
    Window.Draw(self)
end

function SkillMountDialog:MouseEvent()
end

--- 连接信号
---@param signal function
---@param obj Object
function SkillMountDialog:MocConnectSignal(signal, receiver)
    Window.MocConnectSignal(self, signal, receiver)
end

---@param signal function
function SkillMountDialog:GetReceiverListOfSignal(signal)
    return Window.GetReceiverListOfSignal(self, signal)
end

---@param name string
function SkillMountDialog:SetObjectName(name)
    Window.SetObjectName(self, name)
end

function SkillMountDialog:GetObjectName()
    return Window.GetObjectName(self)
end

function SkillMountDialog:GetPosition()
    return Window.GetPosition(self)
end

function SkillMountDialog:SetPosition(x, y)
    Window.SetPosition(self, x, y) 
end

function SkillMountDialog:SetSize(w, h)
    Window.SetSize(self, w, h)
end

---@return integer, integer
function SkillMountDialog:GetSize()
    return Window.GetSize(self)
end

function SkillMountDialog:SetEnable(enable)
    Window.SetEnable(self, enable)
end

--- 是否可见
---@return boolean visible
function SkillMountDialog:IsVisible()
    return Window.IsVisible(self)
end

--- 设置是否可见
---@param visible boolean
function SkillMountDialog:SetVisible(visible)
    Window.SetVisible(self, visible)
end

--- 设置标题栏是否可见
---@param visible boolean
function SkillMountDialog:SetTitleBarVisible(visible)
    Window.SetTitleBarVisible(self, visible)
end

---@return boolean
function SkillMountDialog:IsInMoving()
    return Window.IsInMoving(self)
end

function SkillMountDialog:SetIsInMoving(moving)
    Window.SetIsInMoving(self, moving)
end

--- 获取窗口所处层数。
--- 由窗管调用
---@return number layerIndex
function SkillMountDialog:GetWindowLayerIndex()
    return Window.GetWindowLayerIndex(self)
end

--- 设置窗口所处层数。
--- 由窗管调用
---@param layerIndex number
function SkillMountDialog:SetWindowLayerIndex(layerIndex)
    Window.SetWindowLayerIndex(self, layerIndex)
end

--- 检查是否包含坐标。
--- 由窗管调用
---@param x number
---@param y number
---@return boolean
function SkillMountDialog:CheckPoint(x, y)
    return Window.CheckPoint(self, x, y)
end

function SkillMountDialog:SetIsTipToolWindow(is)
    Window.SetIsTipToolWindow(self, is)
end

---@return boolean isTipToolWindow
function SkillMountDialog:IsTipToolWindow()
    return Window.IsTipToolWindow(self)
end

---@param is boolean
function SkillMountDialog:SetIsWindowStayOnTopHint(is)
    Window.SetIsWindowStayOnTopHint(self, is)
end

---@return boolean isWindowStayOnTopHint
function SkillMountDialog:IsWindowStayOnTopHint()
    return Window.IsWindowStayOnTopHint(self)
end

---@param widget Widget
function SkillMountDialog:SetContentWidget(widget)
    Window.SetContentWidget(self, widget)
end

---@param isVisible boolean
function SkillMountDialog:SetTitleBarIsBackgroundVisible(isVisible)
    Window.SetTitleBarIsBackgroundVisible(self, isVisible)
end

---@param path string
function SkillMountDialog:SetTitleBarIconPath(path)
    Window.SetTitleBarIconPath(self, path)
end

---@param info SkillInfo
function SkillMountDialog:SetNeedMountingSkillInfo(info)
    self.needMountingSkillInfo = info
    self.skillMountDialogContentWidget:SetNeedMountingSkillInfo(info)

    self:SetTitleBarIconPath(info.iconPath)
end

--- slots

---@param x int
---@param y int
function SkillMountDialog:OnRequestMoveWindow(x, y)
    Window.OnRequestMoveWindow(self, x, y)
end

function SkillMountDialog:OnRequestCloseWindow()
    Window.OnRequestCloseWindow(self)
end

--- signals

function SkillMountDialog:Signal_WindowClosed()
    Window.Signal_WindowClosed(self)
end

return SkillMountDialog
