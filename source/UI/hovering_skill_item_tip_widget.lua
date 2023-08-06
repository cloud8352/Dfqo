--[[
	desc: HoveringSkillItemTipWidget class.
	author: keke <243768648@qq.com>
	since: 2023-8-1
	alter: 2023-8-1
]] --

local Widget = require("UI.Widget")
local Label = require("UI.Label")
local Common = require("UI.ui_common")

---@class HoveringSkillItemTipWidget
local HoveringSkillItemTipWidget = require("core.class")(Widget)

---@param parentWindow Window
function HoveringSkillItemTipWidget:Ctor(parentWindow)
    -- 父类构造函数
    Widget.Ctor(self, parentWindow)

    self.isSillInfoChanged = false

    self.nameLabel = Label.New(parentWindow)
    self.nameLabel:SetAlignments({Label.AlignmentFlag.AlignLeft, Label.AlignmentFlag.AlignTop})

    --- 属性类型 到 标签控件 的映射表
    ---@type table<SkillPropType, Label>
    self.mapOfPropTypeToLabel = {}
    --- 属性类型 到 值 的映射表
    ---@type table<SkillPropType, number>
    self.mapOfSkillPropTypeToValue = {}
    for _, typeValue in pairs(Common.SkillPropType) do
        local label = Label.New(parentWindow)
        label:SetAlignments({Label.AlignmentFlag.AlignLeft, Label.AlignmentFlag.AlignTop})
        self.mapOfPropTypeToLabel[typeValue] = label

        self.mapOfSkillPropTypeToValue[typeValue] = 0
    end

    --- description
    self.descriptionLabel = Label.New(parentWindow)
    self.descriptionLabel:SetAlignments({Label.AlignmentFlag.AlignLeft, Label.AlignmentFlag.AlignTop})
end

function HoveringSkillItemTipWidget:Update(dt)
    if (Widget.IsBaseDataChanged(self)
        or self.isSkillInfoChanged
        )
        then
        self.nameLabel:Update(dt)
        --- 更新各属性标签控件
        for _, label in pairs(self.mapOfPropTypeToLabel) do
            label:Update(dt)
        end

        --- 更新简介控件
        self.descriptionLabel:Update(dt)

        --- 整体布局控件
        local adjustYPosOffset = 0
        local viewContentSizeW = 0
        local viewContentSizeH = 0
        self.nameLabel:SetPosition(self.xPos, self.yPos)

        -- 布局各属性标签控件
        ---@type Label
        local theLastLabel = self.nameLabel
        for _, label in pairs(self.mapOfPropTypeToLabel) do
            viewContentSizeW, viewContentSizeH = theLastLabel:GetViewContentSize()
            adjustYPosOffset = adjustYPosOffset + viewContentSizeH
            label:SetPosition(self.xPos, self.yPos + adjustYPosOffset)

            theLastLabel = label
        end

        --- 布局简介控件
        viewContentSizeW, viewContentSizeH = theLastLabel:GetViewContentSize()
        adjustYPosOffset = adjustYPosOffset + viewContentSizeH
        self.descriptionLabel:SetPosition(self.xPos, self.yPos + adjustYPosOffset)
    end

    self.nameLabel:Update(dt)
    --- 更新各属性标签控件
    for _, label in pairs(self.mapOfPropTypeToLabel) do
        label:Update(dt)
    end

    --- 更新简介控件
    self.descriptionLabel:Update(dt)

    Widget.Update(self, dt)
end

function HoveringSkillItemTipWidget:Draw()
    Widget.Draw(self)

    self.nameLabel:Draw()
    --- 绘制各属性标签控件
    for _, label in pairs(self.mapOfPropTypeToLabel) do
        label:Draw()
    end

    --- 绘制简介控件
    self.descriptionLabel:Draw()
end

function HoveringSkillItemTipWidget:SetPosition(x, y)
    if self.xPos == x and self.yPos == y then
        return
    end

    Widget.SetPosition(self, x, y)

    self.nameLabel:SetPosition(x, y)
    --- 设置各属性标签控件坐标
    for _, label in pairs(self.mapOfPropTypeToLabel) do
        label:SetPosition(x, y)
    end

    --- 设置简介控件坐标
    self.descriptionLabel:SetPosition(x, y)
end

function HoveringSkillItemTipWidget:SetSize(width, height)
    if self.width == width and self.height == height then
        return
    end

    Widget.SetSize(self, width, height)

    self.nameLabel:SetSize(width, height)
    --- 设置各属性标签控件大小
    for _, label in pairs(self.mapOfPropTypeToLabel) do
        label:SetSize(width, height)
    end

    --- 设置简介控件大小
    self.descriptionLabel:SetSize(width, height)
end

function HoveringSkillItemTipWidget:SetEnable(enable)
    Widget.SetEnable(self, enable)

    self.nameLabel:SetEnable(enable)
    --- 使能各属性标签控件
    for _, label in pairs(self.mapOfPropTypeToLabel) do
        label:SetEnable(enable)
    end

    --- 设置简介控件大小
    self.descriptionLabel:SetEnable(enable)
end

--- 通过属性调整各控件可见性
function HoveringSkillItemTipWidget:AdjustWidgetsVisibilityByProp()
    for type, label in pairs(self.mapOfPropTypeToLabel) do
        local value = self.mapOfSkillPropTypeToValue[type]
        if value == 0 then
            -- 数值为0时不显示
            label:SetVisible(false)
        else
            label:SetVisible(self.isVisible)
        end
    end
end

---@param isVisible boolean
function HoveringSkillItemTipWidget:SetVisible(isVisible)
    Widget.SetVisible(self, isVisible)

    self.nameLabel:SetVisible(isVisible)
    
    -- 通过属性调整各控件可见性
    self:AdjustWidgetsVisibilityByProp()

    --- 设置简介控件可见性
    self.descriptionLabel:SetVisible(isVisible)
end

---
---@param info SkillInfo
function HoveringSkillItemTipWidget:SetSkillInfo(info)
    self.isSkillInfoChanged = true

    self.nameLabel:SetText("「" .. info.name .. "」")

    ---@type Label
    local label = nil
    -- SetCdStr
    label = self.mapOfPropTypeToLabel[Common.SkillPropType.CdTime]
    label:SetText("冷却时间：" .. tostring(info.cdTime) .. "s")
    self.mapOfSkillPropTypeToValue[Common.SkillPropType.CdTime] = info.cdTime
    -- mp
    label = self.mapOfPropTypeToLabel[Common.SkillPropType.Mp]
    label:SetText("消耗mp：" .. tostring(info.mp))
    self.mapOfSkillPropTypeToValue[Common.SkillPropType.Mp] = info.mp
    -- PhysicalDamageEnhanceRate
    label = self.mapOfPropTypeToLabel[Common.SkillPropType.PhysicalDamageEnhanceRate]
    label:SetText("物理伤害增幅：" .. tostring(info.physicalDamageEnhanceRate * 100) .. "%")
    self.mapOfSkillPropTypeToValue[Common.SkillPropType.PhysicalDamageEnhanceRate] = info.physicalDamageEnhanceRate
    -- MagicDamageEnhanceRate
    label = self.mapOfPropTypeToLabel[Common.SkillPropType.MagicDamageEnhanceRate]
    label:SetText("魔法伤害增幅：" .. tostring(info.magicDamageEnhanceRate * 100) .. "%")
    self.mapOfSkillPropTypeToValue[Common.SkillPropType.MagicDamageEnhanceRate] = info.magicDamageEnhanceRate

    --- 设置 简介 标签控件文字
    self.descriptionLabel:SetText(info.desc)

    -- 通过属性调整各控件可见性
    self:AdjustWidgetsVisibilityByProp()
end

return HoveringSkillItemTipWidget
