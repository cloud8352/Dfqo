--[[
	desc: NpcDlg class.
	author: keke <243768648@qq.com>
]]
--

local Window = require("UI.Window")

local Label = require("UI.Label")
local PushButton = require("UI.PushButton")
local ArticleTableWidget = require("UI.ArticleTableWidget")
local Common = require("UI.ui_common")

local Util = require("util.Util")

---@class NpcDlg : Window
local NpcDlg = require("core.class")(Window)

---@param model UiModel
function NpcDlg.Create(model)
    -- 用于定义构造函数，解释使用，不做实际用途
    -- 使用class模块后，实际会调用Ctor函数
    return NpcDlg.New(model)
end

---@param model UiModel
function NpcDlg:Ctor(model)
    Window.Ctor(self)

    self.model = model

    local windowSizeScale = Util.GetWindowSizeScale()
    self.contentWidgetBottomMargin = 10 * windowSizeScale

    self:SetIsWindowStayOnTopHint(true)
    self:SetTitleBarIsBackgroundVisible(false)
    self:SetTitleBarIconPath("icon/Logo")

    local windowSizeScale = Util.GetWindowSizeScale()

    self.btnVSpace = 5 * windowSizeScale
    self.btnHeight = 40 * windowSizeScale

    local label = Label.Create(self)
    label:SetText("介绍 介绍")
    label:SetAlignments({ Label.AlignmentFlag.AlignLeft, Label.AlignmentFlag.AlignTop })
    self.introLabel = label

    local btn = PushButton.Create(self)
    btn:SetText("聊天")
    self.talkBtn = btn

    btn = PushButton.Create(self)
    btn:SetText("买卖物品")
    self.tradeBtn = btn

    label = Label.Create(self)
    label:SetAlignments({ Label.AlignmentFlag.AlignLeft, Label.AlignmentFlag.AlignTop })
    label:SetText("点击此窗口中物品进行购买，将物品拖入到此窗口中进行出售")
    self.articleTableTipLabel = label

    -- articleTableWidget
    self.articleTableWidget = ArticleTableWidget.Create(self, model)
    self.articleTableWidget:SetRowColCount(8, Common.ArticleTableColCount)

    -- connect
    self.tradeBtn:MocConnectSignal(self.tradeBtn.Signal_BtnClicked, self)

    -- post init
    self:setIsTrading(false)
end

function NpcDlg:Update(dt)
    if false == Window.IsVisible(self) then
        return
    end

    if self:IsSizeChanged() then
        self:updateUiPosBySize()
    end

    self.introLabel:Update(dt)
    self.talkBtn:Update(dt)
    self.tradeBtn:Update(dt)
    self.articleTableTipLabel:Update(dt)
    self.articleTableWidget:Update(dt)

    Window.Update(self, dt)
end

function NpcDlg:Draw()
    if false == Window.IsVisible(self) then
        return
    end
    Window.Draw(self)

    self.introLabel:Draw()
    self.talkBtn:Draw()
    self.tradeBtn:Draw()
    self.articleTableTipLabel:Draw()
    self.articleTableWidget:Draw()
end

--- 连接信号
---@param signal function
---@param obj Object
function NpcDlg:MocConnectSignal(signal, receiver)
    Window.MocConnectSignal(self, signal, receiver)
end

---@param signal function
function NpcDlg:GetReceiverListOfSignal(signal)
    return Window.GetReceiverListOfSignal(self, signal)
end

---@param name string
function NpcDlg:SetObjectName(name)
    Window.SetObjectName(self, name)
end

function NpcDlg:GetObjectName()
    return Window.GetObjectName(self)
end

function NpcDlg:GetParentWindow()
    return Window.GetParentWindow(self)
end

function NpcDlg:GetPosition()
    return Window.GetPosition(self)
end

function NpcDlg:SetPosition(x, y)
    Window.SetPosition(self, x, y)

    self:updateUiPosBySize()
end

---@param w int
---@param h int
function NpcDlg:SetSize(w, h)
    Window.SetSize(self, w, h)
    local windowSizeScale = Util.GetWindowSizeScale()

    local btnAreaHeight = self.btnVSpace * 2 + self.btnHeight

    local contentWidget = self:GetContentWidget()
    local contentWidgetW, contentWidgetH = contentWidget:GetSize()
    self.introLabel:SetSize(contentWidgetW, contentWidgetH - btnAreaHeight)

    self.talkBtn:SetSize(100 * windowSizeScale, self.btnHeight)
    self.tradeBtn:SetSize(100 * windowSizeScale, self.btnHeight)

    -- article table
    self.articleTableTipLabel:SetSize(contentWidgetW, 60 * windowSizeScale)
end

---@return integer, integer
function NpcDlg:GetSize()
    return Window.GetSize(self)
end

function NpcDlg:IsSizeChanged()
    return Window.IsSizeChanged(self)
end

function NpcDlg:SetEnable(enable)
    Window.SetEnable(self, enable)
end

--- 是否可见
---@return boolean visible
function NpcDlg:IsVisible()
    return Window.IsVisible(self)
end

--- 设置是否可见
---@param visible boolean
function NpcDlg:SetVisible(visible)
    Window.SetVisible(self, visible)
end

---@param sprite Graphics.Drawable.Sprite
function NpcDlg:SetBgSprite(sprite)
    Window.SetBgSprite(self, sprite)
end

function NpcDlg:GetBgSprite()
    return Window.GetBgSprite(self)
end

--- 检查是否包含坐标。
--- 由窗管调用
---@param x number
---@param y number
---@return boolean
function NpcDlg:CheckPoint(x, y)
    return Window.CheckPoint(self, x, y)
end

--- 设置标题栏是否可见
---@param visible boolean
function NpcDlg:SetTitleBarVisible(visible)
    Window.SetTitleBarVisible(self, visible)
end

---@return boolean
function NpcDlg:IsInMoving()
    return Window.IsInMoving(self)
end

function NpcDlg:SetIsInMoving(moving)
    Window.SetIsInMoving(self, moving)
end

--- 获取窗口所处层数。
--- 由窗管调用
---@return number layerIndex
function NpcDlg:GetWindowLayerIndex()
    return Window.GetWindowLayerIndex(self)
end

--- 设置窗口所处层数。
--- 由窗管调用
---@param layerIndex number
function NpcDlg:SetWindowLayerIndex(layerIndex)
    Window.SetWindowLayerIndex(self, layerIndex)
end

function NpcDlg:SetIsTipToolWindow(is)
    Window.SetIsTipToolWindow(self, is)
end

---@return boolean isTipToolWindow
function NpcDlg:IsTipToolWindow()
    return Window.IsTipToolWindow(self)
end

---@param is boolean
function NpcDlg:SetIsWindowStayOnTopHint(is)
    Window.SetIsWindowStayOnTopHint(self, is)
end

---@return boolean isWindowStayOnTopHint
function NpcDlg:IsWindowStayOnTopHint()
    return Window.IsWindowStayOnTopHint(self)
end

---@param widget Widget
function NpcDlg:SetContentWidget(widget)
    Window.SetContentWidget(self, widget)
end

function NpcDlg:GetContentWidget()
    return Window.GetContentWidget(self)
end

---@param isVisible boolean
function NpcDlg:SetTitleBarIsBackgroundVisible(isVisible)
    Window.SetTitleBarIsBackgroundVisible(self, isVisible)
end

---@param path string
function NpcDlg:SetTitleBarIconPath(path)
    Window.SetTitleBarIconPath(self, path)
end

--- 设置窗口为普通控件，脱离窗管管理
---@param is boolean
function NpcDlg:SetIsNormalWidget(is)
    Window.SetIsNormalWidget(self, is)
end

---@param info NpcInfo
function NpcDlg:SetInfo(info)
    self:SetTitle(info.Name)
    self.introLabel:SetText(info.Intro)
end

--- slots

---@param x int
---@param y int
function NpcDlg:OnRequestMoveWindow(x, y)
    Window.OnRequestMoveWindow(self, x, y)
end

function NpcDlg:OnRequestCloseWindow()
    Window.OnRequestCloseWindow(self)
end

---@param sender Obj
function NpcDlg:Slot_BtnClicked(sender)
    if sender == self.tradeBtn then
        self:setIsTrading(true)
    end
end

--- signals

function NpcDlg:Signal_WindowClosed()
    Window.Signal_WindowClosed(self)
end

---- private methods

function NpcDlg:updateUiPosBySize()
    local contentWidget = self:GetContentWidget()
    local contentWidgetX, contentWidgetY = contentWidget:GetPosition()
    self.introLabel:SetPosition(contentWidgetX, contentWidgetY)

    local widgetW, widgetH = self.introLabel:GetSize()

    local btnY = contentWidgetY + widgetH + self.btnVSpace
    local windowSizeScale = Util.GetWindowSizeScale()
    self.talkBtn:SetPosition(contentWidgetX + 20 * windowSizeScale, btnY)
    widgetW, widgetH = self.talkBtn:GetSize()

    self.tradeBtn:SetPosition(contentWidgetX + 20 * windowSizeScale + widgetW + 20 * windowSizeScale, btnY)

    -- article table
    self.articleTableTipLabel:SetPosition(contentWidgetX, contentWidgetY)
    widgetW, widgetH = self.articleTableTipLabel:GetSize()

    local contentWidgetW, _ = contentWidget:GetSize()
    local articleTableWidgetW, _ = self.articleTableWidget:GetSize()
    self.articleTableWidget:SetPosition(contentWidgetX + (contentWidgetW - articleTableWidgetW) / 2,
        contentWidgetY + widgetH)
end

---@param is boolean
function NpcDlg:setIsTrading(is)
    self.introLabel:SetVisible(false)
    self.talkBtn:SetVisible(false)
    self.tradeBtn:SetVisible(false)

    self.articleTableTipLabel:SetVisible(false)
    self.articleTableWidget:SetVisible(false)

    if is then
        self.articleTableTipLabel:SetVisible(true)
        self.articleTableWidget:SetVisible(true)
    else
        self.introLabel:SetVisible(true)
        self.talkBtn:SetVisible(true)
        self.tradeBtn:SetVisible(true)
    end
end

return NpcDlg
