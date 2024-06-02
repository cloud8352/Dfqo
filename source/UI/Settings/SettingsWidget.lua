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

---@class SettingsWidget
local SettingsWidget = require("core.class")(Widget)

---@param parentWindow Window
---@param model UiModel
function SettingsWidget:Ctor(parentWindow, model)
    -- 父类构造函数
    Widget.Ctor(self, parentWindow)
    
    self.model = model
    local windowSizeScale = Util.GetWindowSizeScale()

    self.leftMargin = 6 * Util.GetWindowSizeScale()
    self.leftMargin = math.floor(self.leftMargin)
    self.topMargin = self.leftMargin
    self.rightMargin = self.leftMargin
    self.bottomMargin = self.leftMargin

    self.titleBtnBox = PushButton.New(parentWindow)
    self.titleBtnBox:SetText("按键设置")

    self.titleBtnBoxKeySettingsWidgetVSpace = 5 * windowSizeScale
    self.keySettingsWidget = KeySettingsWidget.New(parentWindow, model)
    
    -- connection

    -- post init
end

function SettingsWidget:Update(dt)
    self:MouseEvent()

    if (Widget.IsSizeChanged(self)
        )
    then
    end

    self.titleBtnBox:Update(dt)
    self.keySettingsWidget:Update(dt)

    Widget.Update(self, dt)
end

function SettingsWidget:Draw()
    Widget.Draw(self)

    self.titleBtnBox:Draw()
    self.keySettingsWidget:Draw()
end

function SettingsWidget:MouseEvent()
end

---@param x int
---@param y int
function SettingsWidget:SetPosition(x, y)
    Widget.SetPosition(self, x, y)
    local windowSizeScale = Util.GetWindowSizeScale()

    self.titleBtnBox:SetPosition(x, y)

    local _, titleBtnBoxHeight = self.titleBtnBox:GetSize()
    self.keySettingsWidget:SetPosition(x, y + titleBtnBoxHeight + self.titleBtnBoxKeySettingsWidgetVSpace)
end

---@param width int
---@param height int
function SettingsWidget:SetSize(width, height)
    Widget.SetSize(self, width, height)
    local windowSizeScale = Util.GetWindowSizeScale()

    self.titleBtnBox:SetSize(90 * windowSizeScale, 30 * windowSizeScale)
    local _, titleBtnBoxHeight = self.titleBtnBox:GetSize()
    self.keySettingsWidget:SetSize(width, height - titleBtnBoxHeight - self.titleBtnBoxKeySettingsWidgetVSpace)
end

function SettingsWidget:SetEnable(enable)
    Widget.SetEnable(self, enable)

    self.titleBtnBox:SetEnable(enable)
    self.keySettingsWidget:SetEnable(enable)
end

--- slots

--- private function

return SettingsWidget
