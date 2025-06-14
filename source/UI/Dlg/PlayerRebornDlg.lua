--[[
	desc: PlayerRebornDlg class.
	author: keke <243768648@qq.com>
]]
--

local Window = require("UI.Window")

local Label = require("UI.Label")
local PushButton = require("UI.PushButton")
local Widget = require("UI.Widget")

local Util = require("util.Util")

---@class PlayerRebornDlg : Window
local PlayerRebornDlg = require("core.class")(Window)

---@param model UiModel
function PlayerRebornDlg.Create(model)
    -- 用于定义构造函数，解释使用，不做实际用途
    -- 使用class模块后，实际会调用Ctor函数
    return PlayerRebornDlg.New(model)
end

---@param model UiModel
function PlayerRebornDlg:Ctor(model)
    Window.Ctor(self)

    self.model = model

    local windowSizeScale = Util.GetWindowSizeScale()
    self.contentWidgetBottomMargin = 10 * windowSizeScale

    self:SetIsWindowStayOnTopHint(true)
    self:SetTitleBarVisible(false)

    local label = Label.Create(self)
    self.label = label

    self.retStartGamePageBtn = PushButton.Create(self)
    self.retStartGamePageBtn:SetText("返回开始界面")

    --- connection
    self.retStartGamePageBtn:MocConnectSignal(self.retStartGamePageBtn.Signal_BtnClicked, self)
end

function PlayerRebornDlg:Update(dt)
    if false == Window.IsVisible(self) then
        return
    end

    if self:IsSizeChanged() then
        self:updateUiPosBySize()
    end

    self.label:Update(dt)
    self.retStartGamePageBtn:Update(dt)

    Window.Update(self, dt)
end

function PlayerRebornDlg:Draw()
    if false == Window.IsVisible(self) then
        return
    end
    Window.Draw(self)

    self.label:Draw()
    self.retStartGamePageBtn:Draw()
end

--- 连接信号
---@param signal function
---@param obj Object
function PlayerRebornDlg:MocConnectSignal(signal, receiver)
    Window.MocConnectSignal(self, signal, receiver)
end

---@param signal function
function PlayerRebornDlg:GetReceiverListOfSignal(signal)
    return Window.GetReceiverListOfSignal(self, signal)
end

---@param name string
function PlayerRebornDlg:SetObjectName(name)
    Window.SetObjectName(self, name)
end

function PlayerRebornDlg:GetObjectName()
    return Window.GetObjectName(self)
end

function PlayerRebornDlg:GetParentWindow()
    return Window.GetParentWindow(self)
end

function PlayerRebornDlg:GetPosition()
    return Window.GetPosition(self)
end

function PlayerRebornDlg:SetPosition(x, y)
    Window.SetPosition(self, x, y)

    self:updateUiPosBySize()
end

---@param w int
---@param h int
function PlayerRebornDlg:SetSize(w, h)
    Window.SetSize(self, w, h)

    local windowSizeScale = Util.GetWindowSizeScale()
    local contentWidget = self:GetContentWidget()
    local contentWidgetW, contentWidgetH = contentWidget:GetSize()
    self.retStartGamePageBtn:SetSize(120 * windowSizeScale, 40 * windowSizeScale)

    local btnH = self.retStartGamePageBtn:GetHeight()
    self.label:SetSize(contentWidgetW, 
        contentWidgetH - btnH - self.contentWidgetBottomMargin)
end

---@return integer, integer
function PlayerRebornDlg:GetSize()
    return Window.GetSize(self)
end

function PlayerRebornDlg:IsSizeChanged()
    return Window.IsSizeChanged(self)
end

function PlayerRebornDlg:SetEnable(enable)
    Window.SetEnable(self, enable)
end

--- 是否可见
---@return boolean visible
function PlayerRebornDlg:IsVisible()
    return Window.IsVisible(self)
end

--- 设置是否可见
---@param visible boolean
function PlayerRebornDlg:SetVisible(visible)
    Window.SetVisible(self, visible)
end

---@param sprite Graphics.Drawable.Sprite
function PlayerRebornDlg:SetBgSprite(sprite)
    Window.SetBgSprite(self, sprite)
end

function PlayerRebornDlg:GetBgSprite()
    return Window.GetBgSprite(self)
end

--- 检查是否包含坐标。
--- 由窗管调用
---@param x number
---@param y number
---@return boolean
function PlayerRebornDlg:CheckPoint(x, y)
    return Window.CheckPoint(self, x, y)
end

--- 设置标题栏是否可见
---@param visible boolean
function PlayerRebornDlg:SetTitleBarVisible(visible)
    Window.SetTitleBarVisible(self, visible)
end

---@return boolean
function PlayerRebornDlg:IsInMoving()
    return Window.IsInMoving(self)
end

function PlayerRebornDlg:SetIsInMoving(moving)
    Window.SetIsInMoving(self, moving)
end

--- 获取窗口所处层数。
--- 由窗管调用
---@return number layerIndex
function PlayerRebornDlg:GetWindowLayerIndex()
    return Window.GetWindowLayerIndex(self)
end

--- 设置窗口所处层数。
--- 由窗管调用
---@param layerIndex number
function PlayerRebornDlg:SetWindowLayerIndex(layerIndex)
    Window.SetWindowLayerIndex(self, layerIndex)
end

function PlayerRebornDlg:SetIsTipToolWindow(is)
    Window.SetIsTipToolWindow(self, is)
end

---@return boolean isTipToolWindow
function PlayerRebornDlg:IsTipToolWindow()
    return Window.IsTipToolWindow(self)
end

---@param is boolean
function PlayerRebornDlg:SetIsWindowStayOnTopHint(is)
    Window.SetIsWindowStayOnTopHint(self, is)
end

---@return boolean isWindowStayOnTopHint
function PlayerRebornDlg:IsWindowStayOnTopHint()
    return Window.IsWindowStayOnTopHint(self)
end

---@param widget Widget
function PlayerRebornDlg:SetContentWidget(widget)
    Window.SetContentWidget(self, widget)
end

function PlayerRebornDlg:GetContentWidget()
    return Window.GetContentWidget(self)
end

---@param isVisible boolean
function PlayerRebornDlg:SetTitleBarIsBackgroundVisible(isVisible)
    Window.SetTitleBarIsBackgroundVisible(self, isVisible)
end

---@param path string
function PlayerRebornDlg:SetTitleBarIconPath(path)
    Window.SetTitleBarIconPath(self, path)
end

--- 设置窗口为普通控件，脱离窗管管理
---@param is boolean
function PlayerRebornDlg:SetIsNormalWidget(is)
    Window.SetIsNormalWidget(self, is)
end

---@param text string
function PlayerRebornDlg:SetText(text)
    self.label:SetText(text)
end

--- slots

---@param x int
---@param y int
function PlayerRebornDlg:OnRequestMoveWindow(x, y)
    Window.OnRequestMoveWindow(self, x, y)
end

function PlayerRebornDlg:OnRequestCloseWindow()
    Window.OnRequestCloseWindow(self)
end

---@param sender PushButton 被电击的按钮对象
function PlayerRebornDlg:Slot_BtnClicked(sender)
    if self.retStartGamePageBtn == sender then
        self.model:GoToGameStartPage()
    end
end

--- signals

function PlayerRebornDlg:Signal_WindowClosed()
    Window.Signal_WindowClosed(self)
end

function PlayerRebornDlg:Signal_GameStarted()
    print("PlayerRebornDlg:Signal_GameStarted()")
    local receiverList = self:GetReceiverListOfSignal(self.Signal_GameStarted)
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.Slot_GameStarted
        if func == nil then
            goto continue
        end

        func(receiver, self)

        ::continue::
    end
end

---- private methods

function PlayerRebornDlg:updateUiPosBySize()
    local contentWidget = self:GetContentWidget()
    local contentWidgetX, contentWidgetY = contentWidget:GetPosition()
    local contentWidgetW, contentWidgetH = contentWidget:GetSize()
    self.label:SetPosition(contentWidgetX, contentWidgetY)

    local btnW, btnH = self.retStartGamePageBtn:GetSize()
    local btnX = contentWidgetX + (contentWidgetW - btnW) / 2
    local btnY = contentWidgetY + contentWidgetH - btnH - self.contentWidgetBottomMargin
    self.retStartGamePageBtn:SetPosition(btnX, btnY)
end

return PlayerRebornDlg
