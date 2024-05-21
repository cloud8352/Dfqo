--[[
	desc: SkillMountDialogContentWidget class.
	author: keke <243768648@qq.com>
]]--
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
local SkillDockViewFrame = require("UI.SkillDockViewFrame")
local PushButton = require("UI.PushButton")

---@class SkillMountDialogContentWidget
local SkillMountDialogContentWidget = require("core.class")(Widget)

local SkillShortcutsRowCount = 2
local SkillShortcutsColCount = 6

---@param parentWindow Window
---@param model UiModel
function SkillMountDialogContentWidget:Ctor(parentWindow, model)
    -- 父类构造函数
    Widget.Ctor(self, parentWindow)

    self.model = model
    self.needMountingSkillInfo = Common.NewSkillInfo()

    local windowSizeScale = Util.GetWindowSizeScale()

    self.tipLabel = Label.New(parentWindow)
    self.tipLabel:SetText("点击下列快捷栏以装备技能：")

    self.skillDockViewFrame = SkillDockViewFrame.New(parentWindow, model)

    self.clearSkillShortcutsBtn = PushButton.New(parentWindow)
    self.clearSkillShortcutsBtn:SetText("置空")
    self.clearSkillShortcutsBtn:SetSize(80 * windowSizeScale, 30 * windowSizeScale)

    -- connection
    self.skillDockViewFrame:MocConnectSignal(self.skillDockViewFrame.Signal_ItemClicked, self)
end

function SkillMountDialogContentWidget:Update(dt)
    if (Widget.IsSizeChanged(self)
        )
    then
    end

    self.tipLabel:Update(dt)
    self.skillDockViewFrame:Update(dt)
    self.clearSkillShortcutsBtn:Update(dt)

    Widget.Update(self, dt)
end

function SkillMountDialogContentWidget:Draw()
    Widget.Draw(self)

    self.tipLabel:Draw()
    self.skillDockViewFrame:Draw()
    self.clearSkillShortcutsBtn:Draw()
end

--- 连接信号
---@param signal function
---@param obj Object
function SkillMountDialogContentWidget:MocConnectSignal(signal, receiver)
    Widget.MocConnectSignal(self, signal, receiver)
end

---@param signal function
function SkillMountDialogContentWidget:GetReceiverListOfSignal(signal)
    return Widget.GetReceiverListOfSignal(self, signal)
end

---@param name string
function SkillMountDialogContentWidget:SetObjectName(name)
    Widget.SetObjectName(self, name)
end

function SkillMountDialogContentWidget:GetObjectName()
    return Widget.GetObjectName(self)
end

function SkillMountDialogContentWidget:GetParentWindow()
    return Widget.GetParentWindow(self)
end

function SkillMountDialogContentWidget:SetPosition(x, y)
    Widget.SetPosition(self, x, y)
    local width, height = self:GetSize()
    local windowSizeScale = Util.GetWindowSizeScale()
    local space = 10 * windowSizeScale

    self.tipLabel:SetPosition(x, y)

    local _, tipLabelHeight = self.tipLabel:GetSize()
    local skillDockViewFrameWidth, skillDockViewFrameHeight = self.skillDockViewFrame:GetSize()
    self.skillDockViewFrame:SetPosition(x + (width - skillDockViewFrameWidth) / 2, y + tipLabelHeight + space)

    self.clearSkillShortcutsBtn:SetPosition(x + space, y + tipLabelHeight + space + skillDockViewFrameHeight + space)
end

function SkillMountDialogContentWidget:GetPosition()
    return Widget.GetPosition(self)
end

function SkillMountDialogContentWidget:SetSize(width, height)
    Widget.SetSize(self, width, height)

    local windowSizeScale = Util.GetWindowSizeScale()

    self.tipLabel:SetSize(width, 30 * windowSizeScale)
end

function SkillMountDialogContentWidget:GetSize()
    return Widget.GetSize(self)
end

function SkillMountDialogContentWidget:SetEnable(enable)
    Widget.SetEnable(self, enable)
end

function SkillMountDialogContentWidget:IsVisible()
    return Widget.IsVisible(self)
end

---@param isVisible bool
function SkillMountDialogContentWidget:SetVisible(isVisible)
    Widget.SetVisible(self, isVisible)
end

---@param x int
---@param y int
---@return boolean
function SkillMountDialogContentWidget:CheckPoint(x, y)
    return Widget.CheckPoint(self, x, y)
end

---@param info SkillInfo
function SkillMountDialogContentWidget:SetNeedMountingSkillInfo(info)
    self.needMountingSkillInfo = info
end

--- slots

---@param sender Obj
---@param skillTag string
function SkillMountDialogContentWidget:Slot_ItemClicked(sender, skillTag)
    print(111, skillTag)
end

--- private function

return SkillMountDialogContentWidget
