--[[
	desc: AboutDlg class.
	author: keke <243768648@qq.com>
]]
--

local Window = require("UI.Window")

local Label = require("UI.Label")
local PushButton = require("UI.PushButton")
local Widget = require("UI.Widget")

local Util = require("util.Util")

---@class AboutDlg : Window
local AboutDlg = require("core.class")(Window)

---@param model UiModel
function AboutDlg.Create(model)
    -- 用于定义构造函数，解释使用，不做实际用途
    -- 使用class模块后，实际会调用Ctor函数
    return AboutDlg.New(model)
end

---@param model UiModel
function AboutDlg:Ctor(model)
    Window.Ctor(self)

    self.model = model

    local windowSizeScale = Util.GetWindowSizeScale()
    self.contentWidgetBottomMargin = 10 * windowSizeScale

    self:SetIsWindowStayOnTopHint(true)
    self:SetTitleBarIsBackgroundVisible(false)
    self:SetTitleBarIconPath("icon/Logo")

    local label = Label.Create(self)
    self.label = label

    local text = "Dfqo\n\n" ..
        "版本：0.4.0\n\n" ..
        "https://gitee.com/ct243768648/DFQ-Original\n\n" ..
        "致谢：MusouCrow love2d 腾讯游戏 Neople\n\n"
    self.label:SetText(text)
end

function AboutDlg:Update(dt)
    if false == Window.IsVisible(self) then
        return
    end

    if self:IsSizeChanged() then
        self:updateUiPosBySize()
    end

    self.label:Update(dt)

    Window.Update(self, dt)
end

function AboutDlg:Draw()
    if false == Window.IsVisible(self) then
        return
    end
    Window.Draw(self)

    self.label:Draw()
end

--- 连接信号
---@param signal function
---@param obj Object
function AboutDlg:MocConnectSignal(signal, receiver)
    Window.MocConnectSignal(self, signal, receiver)
end

---@param signal function
function AboutDlg:GetReceiverListOfSignal(signal)
    return Window.GetReceiverListOfSignal(self, signal)
end

---@param name string
function AboutDlg:SetObjectName(name)
    Window.SetObjectName(self, name)
end

function AboutDlg:GetObjectName()
    return Window.GetObjectName(self)
end

function AboutDlg:GetParentWindow()
    return Window.GetParentWindow(self)
end

function AboutDlg:GetPosition()
    return Window.GetPosition(self)
end

function AboutDlg:SetPosition(x, y)
    Window.SetPosition(self, x, y)

    self:updateUiPosBySize()
end

---@param w int
---@param h int
function AboutDlg:SetSize(w, h)
    Window.SetSize(self, w, h)

    local contentWidget = self:GetContentWidget()
    local contentWidgetW, contentWidgetH = contentWidget:GetSize()
    self.label:SetSize(contentWidgetW, contentWidgetH)
end

---@return integer, integer
function AboutDlg:GetSize()
    return Window.GetSize(self)
end

function AboutDlg:IsSizeChanged()
    return Window.IsSizeChanged(self)
end

function AboutDlg:SetEnable(enable)
    Window.SetEnable(self, enable)
end

--- 是否可见
---@return boolean visible
function AboutDlg:IsVisible()
    return Window.IsVisible(self)
end

--- 设置是否可见
---@param visible boolean
function AboutDlg:SetVisible(visible)
    Window.SetVisible(self, visible)
end

---@param sprite Graphics.Drawable.Sprite
function AboutDlg:SetBgSprite(sprite)
    Window.SetBgSprite(self, sprite)
end

function AboutDlg:GetBgSprite()
    return Window.GetBgSprite(self)
end

--- 检查是否包含坐标。
--- 由窗管调用
---@param x number
---@param y number
---@return boolean
function AboutDlg:CheckPoint(x, y)
    return Window.CheckPoint(self, x, y)
end

--- 设置标题栏是否可见
---@param visible boolean
function AboutDlg:SetTitleBarVisible(visible)
    Window.SetTitleBarVisible(self, visible)
end

---@return boolean
function AboutDlg:IsInMoving()
    return Window.IsInMoving(self)
end

function AboutDlg:SetIsInMoving(moving)
    Window.SetIsInMoving(self, moving)
end

--- 获取窗口所处层数。
--- 由窗管调用
---@return number layerIndex
function AboutDlg:GetWindowLayerIndex()
    return Window.GetWindowLayerIndex(self)
end

--- 设置窗口所处层数。
--- 由窗管调用
---@param layerIndex number
function AboutDlg:SetWindowLayerIndex(layerIndex)
    Window.SetWindowLayerIndex(self, layerIndex)
end

function AboutDlg:SetIsTipToolWindow(is)
    Window.SetIsTipToolWindow(self, is)
end

---@return boolean isTipToolWindow
function AboutDlg:IsTipToolWindow()
    return Window.IsTipToolWindow(self)
end

---@param is boolean
function AboutDlg:SetIsWindowStayOnTopHint(is)
    Window.SetIsWindowStayOnTopHint(self, is)
end

---@return boolean isWindowStayOnTopHint
function AboutDlg:IsWindowStayOnTopHint()
    return Window.IsWindowStayOnTopHint(self)
end

---@param widget Widget
function AboutDlg:SetContentWidget(widget)
    Window.SetContentWidget(self, widget)
end

function AboutDlg:GetContentWidget()
    return Window.GetContentWidget(self)
end

---@param isVisible boolean
function AboutDlg:SetTitleBarIsBackgroundVisible(isVisible)
    Window.SetTitleBarIsBackgroundVisible(self, isVisible)
end

---@param path string
function AboutDlg:SetTitleBarIconPath(path)
    Window.SetTitleBarIconPath(self, path)
end

--- 设置窗口为普通控件，脱离窗管管理
---@param is boolean
function AboutDlg:SetIsNormalWidget(is)
    Window.SetIsNormalWidget(self, is)
end

---@param text string
function AboutDlg:SetText(text)
    self.label:SetText(text)
end

--- slots

---@param x int
---@param y int
function AboutDlg:OnRequestMoveWindow(x, y)
    Window.OnRequestMoveWindow(self, x, y)
end

function AboutDlg:OnRequestCloseWindow()
    Window.OnRequestCloseWindow(self)
end

--- signals

function AboutDlg:Signal_WindowClosed()
    Window.Signal_WindowClosed(self)
end

---- private methods

function AboutDlg:updateUiPosBySize()
    local contentWidget = self:GetContentWidget()
    local contentWidgetX, contentWidgetY = contentWidget:GetPosition()
    self.label:SetPosition(contentWidgetX, contentWidgetY)
end

return AboutDlg
