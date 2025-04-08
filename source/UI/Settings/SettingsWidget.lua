--[[
	desc: SettingsWidget class. 设置控件
	author: keke <243768648@qq.com>
]] --

local _CONFIG = require("config")
local _Mouse = require("lib.mouse")
local Timer = require("util.gear.timer")
local _MATH = require("lib.math")

local WindowManager = require("UI.WindowManager")
local Common = require("UI.ui_common")
local Util = require("util.Util")

local UiModel = require("UI.ui_model")
local Window = require("UI.Window")
local Widget = require("UI.Widget")
local ListView = require("UI.ListView")
local SkillManagementItem = require("UI.SkillManagement.SkillManagementItem")
local Label = require("UI.Label")
local PushButton = require("UI.PushButton")
local ScrollArea = require("UI.ScrollArea")
local KeySettingsWidget = require("UI.Settings.KeySettingsWidget")
local BasicSettingsWidget = require("UI.Settings.BasicSettingsWidget")

---@class SettingsWidget : Widget
local SettingsWidget = require("core.class")(Widget)

---@enum SettingShowingPageEnum
local SettingShowingPageEnum = {
    Basic = 1,
    Key = 2
}

---@param parentWindow Window
---@param model UiModel
function SettingsWidget:Ctor(parentWindow, model)
    -- 父类构造函数
    Widget.Ctor(self, parentWindow)
    self:SetBgSpriteColor(0, 0, 0, 0)

    self.model = model
    local windowSizeScale = Util.GetWindowSizeScale()

    self.leftMargin = 6 * Util.GetWindowSizeScale()
    self.leftMargin = math.floor(self.leftMargin)
    self.topMargin = self.leftMargin
    self.rightMargin = self.leftMargin
    self.bottomMargin = self.leftMargin

    self.showingPage = SettingShowingPageEnum.Basic

    self.basicSettingsTitleBtn = PushButton.Create(parentWindow)
    self.basicSettingsTitleBtn:SetText("基础")

    self.basicSettingsWidget = BasicSettingsWidget.Create(parentWindow, model)

    self.keySettingsTitleBtn = PushButton.Create(parentWindow)
    self.keySettingsTitleBtn:SetText("按键")

    self.titleBtnBoxKeySettingsWidgetVSpace = 5 * windowSizeScale
    self.keySettingsWidget = KeySettingsWidget.Create(parentWindow, model)
    
    -- connection
    self.basicSettingsTitleBtn:MocConnectSignal(self.basicSettingsTitleBtn.Signal_BtnClicked, self)
    self.keySettingsTitleBtn:MocConnectSignal(self.keySettingsTitleBtn.Signal_BtnClicked, self)

    -- post init
    self:updatePageVisible()

end

function SettingsWidget:Update(dt)
    self:MouseEvent()

    if (Widget.IsSizeChanged(self)
        )
    then
    end

    self.basicSettingsTitleBtn:Update(dt)
    self.basicSettingsWidget:Update(dt)

    self.keySettingsTitleBtn:Update(dt)
    self.keySettingsWidget:Update(dt)

    Widget.Update(self, dt)
end

function SettingsWidget:Draw()
    Widget.Draw(self)

    self.basicSettingsTitleBtn:Draw()
    self.basicSettingsWidget:Draw()

    self.keySettingsTitleBtn:Draw()
    self.keySettingsWidget:Draw()
end

function SettingsWidget:MouseEvent()
end

---@param x int
---@param y int
function SettingsWidget:SetPosition(x, y)
    Widget.SetPosition(self, x, y)
    local windowSizeScale = Util.GetWindowSizeScale()

    self.basicSettingsTitleBtn:SetPosition(x, y)
    local basicSettingsTitleBtnWidth = self.basicSettingsTitleBtn:GetWidth()
    self.keySettingsTitleBtn:SetPosition(x + basicSettingsTitleBtnWidth, y)

    local _, titleBtnBoxHeight = self.basicSettingsTitleBtn:GetSize()
    self.basicSettingsWidget:SetPosition(x, y + titleBtnBoxHeight + self.titleBtnBoxKeySettingsWidgetVSpace)
    self.keySettingsWidget:SetPosition(x, y + titleBtnBoxHeight + self.titleBtnBoxKeySettingsWidgetVSpace)
end

---@param width int
---@param height int
function SettingsWidget:SetSize(width, height)
    Widget.SetSize(self, width, height)
    local windowSizeScale = Util.GetWindowSizeScale()

    self.basicSettingsTitleBtn:SetSize(90 * windowSizeScale, 30 * windowSizeScale)
    self.keySettingsTitleBtn:SetSize(90 * windowSizeScale, 30 * windowSizeScale)

    local _, titleBtnBoxHeight = self.basicSettingsTitleBtn:GetSize()
    self.basicSettingsWidget:SetSize(width, 
        height - titleBtnBoxHeight - self.titleBtnBoxKeySettingsWidgetVSpace)
    self.keySettingsWidget:SetSize(width, 
        height - titleBtnBoxHeight - self.titleBtnBoxKeySettingsWidgetVSpace)
end

function SettingsWidget:SetEnable(enable)
    Widget.SetEnable(self, enable)

    self.basicSettingsTitleBtn:SetEnable(enable)
    self.basicSettingsWidget:SetEnable(enable)

    self.keySettingsTitleBtn:SetEnable(enable)
    self.keySettingsWidget:SetEnable(enable)
end

---@param isVisible boolean
function SettingsWidget:SetVisible(isVisible)
    Widget.SetVisible(self, isVisible)

    self:updatePageVisible()
end

--- slots

---@param sender Obj
function SettingsWidget:Slot_BtnClicked(sender)
    if sender == self.basicSettingsTitleBtn then
        self.showingPage = SettingShowingPageEnum.Basic
        self:updatePageVisible()
    elseif sender == self.keySettingsTitleBtn then
        self.showingPage = SettingShowingPageEnum.Key
        self:updatePageVisible()
    end
end

--- private function

function SettingsWidget:updatePageVisible()
    if self:IsVisible() == false then
        self.basicSettingsWidget:SetVisible(false)
        self.keySettingsWidget:SetVisible(false)
        return
    end

    if SettingShowingPageEnum.Basic == self.showingPage then
        self.basicSettingsTitleBtn:SetForcePressed(true)
        self.basicSettingsWidget:SetVisible(true)
        self.keySettingsTitleBtn:SetForcePressed(false)
        self.keySettingsWidget:SetVisible(false)
    elseif SettingShowingPageEnum.Key == self.showingPage then
        self.basicSettingsTitleBtn:SetForcePressed(false)
        self.basicSettingsWidget:SetVisible(false)
        self.keySettingsTitleBtn:SetForcePressed(true)
        self.keySettingsWidget:SetVisible(true)
    end
end

return SettingsWidget
