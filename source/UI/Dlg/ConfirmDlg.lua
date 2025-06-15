--[[
	desc: ConfirmDlg class.
	author: keke <243768648@qq.com>
]]
--

local Window = require("UI.Window")

local Label = require("UI.Label")
local PushButton = require("UI.PushButton")
local WindowManager = require("UI.WindowManager")

local Util = require("util.Util")

---@class ConfirmDlg : Window
local ConfirmDlg = require("core.class")(Window)

function ConfirmDlg.Create()
    -- 用于定义构造函数，解释使用，不做实际用途
    -- 使用class模块后，实际会调用Ctor函数
    return ConfirmDlg.New()
end

function ConfirmDlg:Ctor()
    Window.Ctor(self)
    WindowManager.AppendWindowWidget(self, self)

    local windowSizeScale = Util.GetWindowSizeScale()
    self.contentWidgetBottomMargin = 10 * windowSizeScale

    self:SetIsWindowStayOnTopHint(true)
    self:SetTitleBarVisible(false)

    local label = Label.Create(self)
    self.label = label

    self.yesBtn = PushButton.Create(self)
    self.yesBtn:SetText("确定")

    self.cancelBtn = PushButton.Create(self)
    self.cancelBtn:SetText("取消")

    --- connection
    self.yesBtn:MocConnectSignal(self.yesBtn.Signal_BtnClicked, self)
    self.cancelBtn:MocConnectSignal(self.cancelBtn.Signal_BtnClicked, self)
end

function ConfirmDlg:Update(dt)
    if false == Window.IsVisible(self) then
        return
    end

    if self:IsSizeChanged() then
        self:updateUiPosBySize()
    end

    self.label:Update(dt)
    self.yesBtn:Update(dt)
    self.cancelBtn:Update(dt)

    Window.Update(self, dt)
end

function ConfirmDlg:Draw()
    if false == Window.IsVisible(self) then
        return
    end
    Window.Draw(self)

    self.label:Draw()
    self.yesBtn:Draw()
    self.cancelBtn:Draw()
end

--- 连接信号
---@param signal function
---@param obj Object
function ConfirmDlg:MocConnectSignal(signal, receiver)
    Window.MocConnectSignal(self, signal, receiver)
end

---@param signal function
function ConfirmDlg:GetReceiverListOfSignal(signal)
    return Window.GetReceiverListOfSignal(self, signal)
end

---@param name string
function ConfirmDlg:SetObjectName(name)
    Window.SetObjectName(self, name)
end

function ConfirmDlg:GetObjectName()
    return Window.GetObjectName(self)
end

function ConfirmDlg:GetParentWindow()
    return Window.GetParentWindow(self)
end

function ConfirmDlg:GetPosition()
    return Window.GetPosition(self)
end

function ConfirmDlg:SetPosition(x, y)
    Window.SetPosition(self, x, y)

    self:updateUiPosBySize()
end

---@param w int
---@param h int
function ConfirmDlg:SetSize(w, h)
    Window.SetSize(self, w, h)

    local windowSizeScale = Util.GetWindowSizeScale()
    local contentWidget = self:GetContentWidget()
    local contentWidgetW, contentWidgetH = contentWidget:GetSize()
    self.yesBtn:SetSize(80 * windowSizeScale, 40 * windowSizeScale)

    self.cancelBtn:SetSize(80 * windowSizeScale, 40 * windowSizeScale)

    local btnH = self.yesBtn:GetHeight()
    self.label:SetSize(contentWidgetW, 
        contentWidgetH - btnH - self.contentWidgetBottomMargin)
end

---@return integer, integer
function ConfirmDlg:GetSize()
    return Window.GetSize(self)
end

function ConfirmDlg:IsSizeChanged()
    return Window.IsSizeChanged(self)
end

function ConfirmDlg:SetEnable(enable)
    Window.SetEnable(self, enable)
end

--- 是否可见
---@return boolean visible
function ConfirmDlg:IsVisible()
    return Window.IsVisible(self)
end

--- 设置是否可见
---@param visible boolean
function ConfirmDlg:SetVisible(visible)
    Window.SetVisible(self, visible)
end

---@param sprite Graphics.Drawable.Sprite
function ConfirmDlg:SetBgSprite(sprite)
    Window.SetBgSprite(self, sprite)
end

function ConfirmDlg:GetBgSprite()
    return Window.GetBgSprite(self)
end

--- 检查是否包含坐标。
--- 由窗管调用
---@param x number
---@param y number
---@return boolean
function ConfirmDlg:CheckPoint(x, y)
    return Window.CheckPoint(self, x, y)
end

--- 设置标题栏是否可见
---@param visible boolean
function ConfirmDlg:SetTitleBarVisible(visible)
    Window.SetTitleBarVisible(self, visible)
end

---@return boolean
function ConfirmDlg:IsInMoving()
    return Window.IsInMoving(self)
end

function ConfirmDlg:SetIsInMoving(moving)
    Window.SetIsInMoving(self, moving)
end

--- 获取窗口所处层数。
--- 由窗管调用
---@return number layerIndex
function ConfirmDlg:GetWindowLayerIndex()
    return Window.GetWindowLayerIndex(self)
end

--- 设置窗口所处层数。
--- 由窗管调用
---@param layerIndex number
function ConfirmDlg:SetWindowLayerIndex(layerIndex)
    Window.SetWindowLayerIndex(self, layerIndex)
end

function ConfirmDlg:SetIsTipToolWindow(is)
    Window.SetIsTipToolWindow(self, is)
end

---@return boolean isTipToolWindow
function ConfirmDlg:IsTipToolWindow()
    return Window.IsTipToolWindow(self)
end

---@param is boolean
function ConfirmDlg:SetIsWindowStayOnTopHint(is)
    Window.SetIsWindowStayOnTopHint(self, is)
end

---@return boolean isWindowStayOnTopHint
function ConfirmDlg:IsWindowStayOnTopHint()
    return Window.IsWindowStayOnTopHint(self)
end

---@param widget Widget
function ConfirmDlg:SetContentWidget(widget)
    Window.SetContentWidget(self, widget)
end

function ConfirmDlg:GetContentWidget()
    return Window.GetContentWidget(self)
end

---@param isVisible boolean
function ConfirmDlg:SetTitleBarIsBackgroundVisible(isVisible)
    Window.SetTitleBarIsBackgroundVisible(self, isVisible)
end

---@param path string
function ConfirmDlg:SetTitleBarIconPath(path)
    Window.SetTitleBarIconPath(self, path)
end

--- 设置窗口为普通控件，脱离窗管管理
---@param is boolean
function ConfirmDlg:SetIsNormalWidget(is)
    Window.SetIsNormalWidget(self, is)
end

---@param text string
function ConfirmDlg:SetText(text)
    self.label:SetText(text)
end

--- slots

---@param x int
---@param y int
function ConfirmDlg:OnRequestMoveWindow(x, y)
    Window.OnRequestMoveWindow(self, x, y)
end

function ConfirmDlg:OnRequestCloseWindow()
    Window.OnRequestCloseWindow(self)
end

---@param sender PushButton 被电击的按钮对象
function ConfirmDlg:Slot_BtnClicked(sender)
    if self.yesBtn == sender then
        self:SetVisible(false)
        self:Signal_Yes()
    end

    if self.cancelBtn == sender then
        self:SetVisible(false)
    end
end

--- signals

function ConfirmDlg:Signal_WindowClosed()
    Window.Signal_WindowClosed(self)
end

function ConfirmDlg:Signal_Yes()
    print("ConfirmDlg:Signal_Yes()")
    local receiverList = self:GetReceiverListOfSignal(self.Signal_Yes)
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.Slot_Yes
        if func == nil then
            goto continue
        end

        func(receiver, self)

        ::continue::
    end
end

---- private methods

function ConfirmDlg:updateUiPosBySize()
    local contentWidget = self:GetContentWidget()
    local contentWidgetX, contentWidgetY = contentWidget:GetPosition()
    local contentWidgetW, contentWidgetH = contentWidget:GetSize()
    self.label:SetPosition(contentWidgetX, contentWidgetY)

    local windowSizeScale = Util.GetWindowSizeScale()
    local btnSpace = 80 * windowSizeScale

    local yesBtnW, yesBtnH = self.yesBtn:GetSize()
    local cancelBtnW, cancelBtnH = self.cancelBtn:GetSize()
    local yesBtnX = contentWidgetX + (contentWidgetW - yesBtnW - btnSpace - cancelBtnW) / 2
    local yesBtnY = contentWidgetY + contentWidgetH - yesBtnH - self.contentWidgetBottomMargin
    self.yesBtn:SetPosition(yesBtnX, yesBtnY)

    self.cancelBtn:SetPosition(yesBtnX + yesBtnW + btnSpace, yesBtnY)
end

return ConfirmDlg
