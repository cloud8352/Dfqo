--[[
	desc: SkillDockViewFrame class. 技能托盘显示框架
	author: keke <243768648@qq.com>
	since: 2023-4-15
	alter: 2023-4-15
]] --

local _CONFIG = require("config")
local _Mouse = require("lib.mouse")
local Timer = require("util.gear.timer")
local _MATH = require("lib.math")

local WindowManager = require("UI.WindowManager")
local Widget = require("UI.Widget")
local IconTextLabel = require("UI.IconTextLabel")
local SkillDockViewItem = require("UI.SkillDockViewItem")
local Window = require("UI.Window")
local RoleEquTableWidget = require("UI.role_info.role_equipment_table_widget")
local ArticleTableWidget = require("UI.role_info.article_table_widget")
local Common = require("UI.ui_common")
local UiModel = require("UI.ui_model")

local Util = require("util.Util")


local LeftPartWidth = 570
local EachPartSpace = 30

---@class RoleInfoWidget
local RoleInfoWidget = require("core.class")(Widget)

---@param parentWindow Window
---@param model UiModel
function RoleInfoWidget:Ctor(parentWindow, model)
    -- 父类构造函数
    Widget.Ctor(self, parentWindow)

    LeftPartWidth = _MATH.Round(570 * Util.GetWindowSizeScale())
    EachPartSpace = _MATH.Round(30 * Util.GetWindowSizeScale())

    self.model = model
    self.roleEquTableWidget = RoleEquTableWidget.New(parentWindow, self.model)

    -- 角色信息
    self.hpLabel = IconTextLabel.New(parentWindow)
    self.hpLabel:SetIconSpriteDataPath("icon/characterProfile/hp")
    self.hpLabel:SetText("生命：1800/1800（+165/秒）")
    self.hpLabel:SetSize(500, 30)

    self.physicalAttackLabel = IconTextLabel.New(parentWindow)
    self.physicalAttackLabel:SetIconSpriteDataPath("icon/characterProfile/physicalAttack")
    self.physicalAttackLabel:SetText("物攻：110")
    self.physicalAttackLabel:SetSize(300, 30)

    self.physicalDefenseLabel = IconTextLabel.New(parentWindow)
    self.physicalDefenseLabel:SetIconSpriteDataPath("icon/characterProfile/physicalDefense")
    self.physicalDefenseLabel:SetText("物防：629")
    self.physicalDefenseLabel:SetSize(300, 30)

    self.attackSpeedLabel = IconTextLabel.New(parentWindow)
    self.attackSpeedLabel:SetIconSpriteDataPath("icon/characterProfile/attackSpeed")
    self.attackSpeedLabel:SetText("攻速：122")
    self.attackSpeedLabel:SetSize(300, 30)

    self.magicalAttackLabel = IconTextLabel.New(parentWindow)
    self.magicalAttackLabel:SetIconSpriteDataPath("icon/characterProfile/magicalAttack")
    self.magicalAttackLabel:SetText("魔攻：131")
    self.magicalAttackLabel:SetSize(300, 30)

    self.magicalDefenseLabel = IconTextLabel.New(parentWindow)
    self.magicalDefenseLabel:SetIconSpriteDataPath("icon/characterProfile/magicalDefense")
    self.magicalDefenseLabel:SetText("魔防：69")
    self.magicalDefenseLabel:SetSize(300, 30)

    self.moveSpeedLabel = IconTextLabel.New(parentWindow)
    self.moveSpeedLabel:SetIconSpriteDataPath("icon/characterProfile/moveSpeed")
    self.moveSpeedLabel:SetText("移速：124")
    self.moveSpeedLabel:SetSize(300, 30)

    self.articleTableWidget = ArticleTableWidget.New(parentWindow, self.model)
end

function RoleInfoWidget:Update(dt)
    self:MouseEvent()

    if (Widget.IsSizeChanged(self)
        )
    then
        self:updateData()
    end

    self.roleEquTableWidget:Update(dt)

    self:updateActorAttributes()
    self.hpLabel:Update(dt)
    self.physicalAttackLabel:Update(dt)
    self.physicalDefenseLabel:Update(dt)
    self.attackSpeedLabel:Update(dt)
    self.magicalAttackLabel:Update(dt)
    self.magicalDefenseLabel:Update(dt)
    self.moveSpeedLabel:Update(dt)

    self.articleTableWidget:Update(dt)

    Widget.Update(self, dt)
    --- 更新上次和当前的所有状态
    self.lastXPos = self.xPos
    self.lastYPos = self.yPos
    self.lastWidth = self.width
    self.lastHeight = self.height
end

function RoleInfoWidget:Draw()
    self.roleEquTableWidget:Draw()

    self.hpLabel:Draw()
    self.physicalAttackLabel:Draw()
    self.physicalDefenseLabel:Draw()
    self.attackSpeedLabel:Draw()
    self.magicalAttackLabel:Draw()
    self.magicalDefenseLabel:Draw()
    self.moveSpeedLabel:Draw()

    self.articleTableWidget:Draw()
end

function RoleInfoWidget:MouseEvent()
end

function RoleInfoWidget:SetPosition(x, y)
    self.xPos = x
    self.yPos = y

    local leftMargin = 6 * Util.GetWindowSizeScale()
    leftMargin = math.floor(leftMargin)
    local rightMargin = leftMargin
    self.roleEquTableWidget:SetPosition(self.xPos + leftMargin, self.yPos)

    local hpLabelYPos = self.yPos + self.height - 73 * Util.GetWindowSizeScale()
    local infoLabelLineSpace = 3 * Util.GetWindowSizeScale()
    self.hpLabel:SetPosition(self.xPos + leftMargin, hpLabelYPos)

    local _, hpLabelHeight = self.hpLabel:GetSize()
    local secondLineYPos = hpLabelYPos + hpLabelHeight + infoLabelLineSpace
    self.physicalAttackLabel:SetPosition(self.xPos + leftMargin, secondLineYPos)
    local physicalAttackLabelWidth, _ = self.physicalAttackLabel:GetSize()
    self.physicalDefenseLabel:SetPosition(self.xPos + leftMargin + physicalAttackLabelWidth, secondLineYPos)
    local physicalDefenseLabelWidth, _ = self.physicalAttackLabel:GetSize()
    self.attackSpeedLabel:SetPosition(self.xPos + leftMargin + physicalAttackLabelWidth + physicalDefenseLabelWidth,
        secondLineYPos)

    local _, physicalAttackLabelHeight = self.physicalAttackLabel:GetSize()
    local thirdLineYPos = hpLabelYPos + hpLabelHeight + infoLabelLineSpace + physicalAttackLabelHeight + infoLabelLineSpace
    self.magicalAttackLabel:SetPosition(self.xPos + leftMargin, thirdLineYPos)
    local magicalAttackLabelWidth, _ = self.physicalAttackLabel:GetSize()
    self.magicalDefenseLabel:SetPosition(self.xPos + leftMargin + magicalAttackLabelWidth, thirdLineYPos)
    local magicalDefenseLabelWidth, _ = self.magicalDefenseLabel:GetSize()
    self.moveSpeedLabel:SetPosition(self.xPos + leftMargin + magicalAttackLabelWidth + magicalDefenseLabelWidth,
        thirdLineYPos)

    local articleTableWidgetWidth, _ = self.articleTableWidget:GetSize()
    self.articleTableWidget:SetPosition(self.xPos + self.width - rightMargin - articleTableWidgetWidth, self.yPos)
end

function RoleInfoWidget:SetSize(width, height)
    self.width = width
    self.height = height

    self.roleEquTableWidget:SetSize(LeftPartWidth, self.height)

    local labelHeight = 20 * Util.GetWindowSizeScale()
    self.hpLabel:SetSize(self.width, labelHeight)

    local unitLabelWidth = 200 * Util.GetWindowSizeScale()
    self.physicalAttackLabel:SetSize(unitLabelWidth, labelHeight)
    self.physicalDefenseLabel:SetSize(unitLabelWidth, labelHeight)
    self.attackSpeedLabel:SetSize(unitLabelWidth, labelHeight)

    self.magicalAttackLabel:SetSize(unitLabelWidth, labelHeight)
    self.magicalDefenseLabel:SetSize(unitLabelWidth, labelHeight)
    self.moveSpeedLabel:SetSize(unitLabelWidth, labelHeight)
end

function RoleInfoWidget:SetEnable(enable)
    self.enable = enable

    self.roleEquTableWidget:SetEnable(enable)

    self.articleTableWidget:SetEnable(enable)
end

--- 设置物品栏某一显示项的信息
---@param index number
---@param itemInfo ArticleInfo
function RoleInfoWidget:SetArticleTableItemInfo(index, itemInfo)
    self.articleTableWidget:SetIndexItemInfo(index, itemInfo)
end

--- 设置装备栏某一显示项的信息
---@param index number
---@param itemInfo ArticleInfo
function RoleInfoWidget:SetEquTableItemInfo(index, itemInfo)
    self.roleEquTableWidget:SetIndexItemInfo(index, itemInfo)
end

function RoleInfoWidget:updateData()
end

function RoleInfoWidget:updateActorAttributes()
    local hp = self.model:GetPlayerAttribute(Common.ActorAttributeType.Hp)
    local maxHp = self.model:GetPlayerAttribute(Common.ActorAttributeType.MaxHp)
    local hpRecovery = self.model:GetPlayerAttribute(Common.ActorAttributeType.HpRecovery)
    self.hpLabel:SetText("生命：" .. tostring(hp) .. "/" ..
        tostring(maxHp) .. "（+" .. tostring(hpRecovery) .. "/秒）")

    local phyAtk = self.model:GetPlayerAttribute(Common.ActorAttributeType.PhyAtk)
    self.physicalAttackLabel:SetText("物攻：" .. tostring(phyAtk))

    local phyDef = self.model:GetPlayerAttribute(Common.ActorAttributeType.PhyDef)
    self.physicalDefenseLabel:SetText("物防：" .. tostring(phyDef))

    local attackSpeed = self.model:GetPlayerAttribute(Common.ActorAttributeType.AttackSpeed)
    self.attackSpeedLabel:SetText("攻速：" .. tostring(attackSpeed))


    local magAtk = self.model:GetPlayerAttribute(Common.ActorAttributeType.MagAtk)
    self.magicalAttackLabel:SetText("魔攻：" .. tostring(magAtk))

    local magDef = self.model:GetPlayerAttribute(Common.ActorAttributeType.MagDef)
    self.magicalDefenseLabel:SetText("魔防：" .. tostring(magDef))

    local moveSpeed = self.model:GetPlayerAttribute(Common.ActorAttributeType.MoveSpeed)
    self.moveSpeedLabel:SetText("移速：" .. tostring(moveSpeed))
end

return RoleInfoWidget
