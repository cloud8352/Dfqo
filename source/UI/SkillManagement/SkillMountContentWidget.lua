--[[
	desc: SkillMountContentWidget class.
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

---@class SkillMountContentWidget
local SkillMountContentWidget = require("core.class")(Widget)

---@param parentWindow Window
---@param model UiModel
function SkillMountContentWidget:Ctor(parentWindow, model)
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
    self.clearSkillShortcutsBtn:MocConnectSignal(self.clearSkillShortcutsBtn.Signal_BtnClicked, self)
end

function SkillMountContentWidget:Update(dt)
    if (Widget.IsSizeChanged(self)
        )
    then
    end

    self.tipLabel:Update(dt)
    self.skillDockViewFrame:Update(dt)
    self.clearSkillShortcutsBtn:Update(dt)

    Widget.Update(self, dt)
end

function SkillMountContentWidget:Draw()
    Widget.Draw(self)

    self.tipLabel:Draw()
    self.skillDockViewFrame:Draw()
    self.clearSkillShortcutsBtn:Draw()
end

--- 连接信号
---@param signal function
---@param obj Object
function SkillMountContentWidget:MocConnectSignal(signal, receiver)
    Widget.MocConnectSignal(self, signal, receiver)
end

---@param signal function
function SkillMountContentWidget:GetReceiverListOfSignal(signal)
    return Widget.GetReceiverListOfSignal(self, signal)
end

---@param name string
function SkillMountContentWidget:SetObjectName(name)
    Widget.SetObjectName(self, name)
end

function SkillMountContentWidget:GetObjectName()
    return Widget.GetObjectName(self)
end

function SkillMountContentWidget:GetParentWindow()
    return Widget.GetParentWindow(self)
end

function SkillMountContentWidget:SetPosition(x, y)
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

function SkillMountContentWidget:GetPosition()
    return Widget.GetPosition(self)
end

function SkillMountContentWidget:SetSize(width, height)
    Widget.SetSize(self, width, height)

    local windowSizeScale = Util.GetWindowSizeScale()

    self.tipLabel:SetSize(width, 30 * windowSizeScale)
end

function SkillMountContentWidget:GetSize()
    return Widget.GetSize(self)
end

function SkillMountContentWidget:IsSizeChanged()
    return Widget.IsSizeChanged(self)
end

function SkillMountContentWidget:SetEnable(enable)
    Widget.SetEnable(self, enable)
end

function SkillMountContentWidget:IsVisible()
    return Widget.IsVisible(self)
end

---@param isVisible bool
function SkillMountContentWidget:SetVisible(isVisible)
    Widget.SetVisible(self, isVisible)
end

---@param sprite Graphics.Drawable.Sprite
function SkillMountContentWidget:SetBgSprite(sprite)
    Widget.SetBgSprite(self, sprite)
end

function SkillMountContentWidget:GetBgSprite()
    return Widget.GetBgSprite(self)
end

---@param x int
---@param y int
---@return boolean
function SkillMountContentWidget:CheckPoint(x, y)
    return Widget.CheckPoint(self, x, y)
end

---@param info SkillInfo
function SkillMountContentWidget:SetNeedMountingSkillInfo(info)
    self.needMountingSkillInfo = info
end

--- slots

---@param sender Obj
---@param skillTag string
function SkillMountContentWidget:Slot_ItemClicked(sender, skillTag)
    self.model:MountPlayerSkill(skillTag, self.needMountingSkillInfo)
end

---@param sender Obj
function SkillMountContentWidget:Slot_BtnClicked(sender)
    if self.clearSkillShortcutsBtn == sender then
        self.model:UnloadPlayerSkill(self.needMountingSkillInfo)
    end
end

--- private function

return SkillMountContentWidget
