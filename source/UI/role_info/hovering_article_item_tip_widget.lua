--[[
	desc: HoveringArticleItemTipWidget class.
	author: keke <243768648@qq.com>
	since: 2023-7-20
	alter: 2023-7-21
]]
--

local Widget = require("UI.Widget")
local Label = require("UI.Label")
local Common = require("UI.ui_common")

---@class HoveringArticleItemTipWidget
local HoveringArticleItemTipWidget = require("core.class")(Widget)

---@param parentWindow Window
function HoveringArticleItemTipWidget:Ctor(parentWindow)
    -- 父类构造函数
    Widget.Ctor(self, parentWindow)

    self.isArticleInfoChanged = false

    self.nameLabel = Label.New(parentWindow)
    self.nameLabel:SetAlignments({ Label.AlignmentFlag.AlignLeft, Label.AlignmentFlag.AlignTop })

    self.type = Common.ArticleType.Empty
    self.typeLabel = Label.New(parentWindow)
    self.typeLabel:SetAlignments({ Label.AlignmentFlag.AlignLeft, Label.AlignmentFlag.AlignTop })

    --- 消耗品属性类型 到 标签控件 的映射表
    ---@type table<ConsumablePropType, Label>
    self.mapOfConsumablePropTypeToLabel = {}
    --- 消耗品属性类型 到 值 的映射表
    ---@type table<ConsumablePropType, number>
    self.mapOfConsumablePropTypeToValue = {}
    for _, typeValue in pairs(Common.ConsumablePropType) do
        local label = Label.New(parentWindow)
        label:SetAlignments({ Label.AlignmentFlag.AlignLeft, Label.AlignmentFlag.AlignTop })
        self.mapOfConsumablePropTypeToLabel[typeValue] = label

        self.mapOfConsumablePropTypeToValue[typeValue] = 0
    end

    --- 装备属性类型 到 标签控件 的映射表
    ---@type table<EquPropType, Label>
    self.mapOfEquPropTypeToLabel = {}
    --- 装备属性类型 到 值 的映射表
    ---@type table<EquPropType, number>
    self.mapOfEquPropTypeToValue = {}
    for _, typeValue in pairs(Common.EquPropType) do
        local label = Label.New(parentWindow)
        label:SetAlignments({ Label.AlignmentFlag.AlignLeft, Label.AlignmentFlag.AlignTop })
        self.mapOfEquPropTypeToLabel[typeValue] = label

        self.mapOfEquPropTypeToValue[typeValue] = 0
    end

    --- description
    self.descriptionLabel = Label.New(parentWindow)
    self.descriptionLabel:SetAlignments({ Label.AlignmentFlag.AlignLeft, Label.AlignmentFlag.AlignTop })
end

function HoveringArticleItemTipWidget:Update(dt)
    if (Widget.IsSizeChanged(self)
            or self.isArticleInfoChanged
        )
    then
        self.nameLabel:Update(dt)
        self.typeLabel:Update(dt)
        --- 更新各属性标签控件
        for _, label in pairs(self.mapOfConsumablePropTypeToLabel) do
            label:Update(dt)
        end
        for _, label in pairs(self.mapOfEquPropTypeToLabel) do
            label:Update(dt)
        end

        --- 更新简介控件
        self.descriptionLabel:Update(dt)

        --- 整体布局控件
        local adjustYPosOffset = 0
        local viewContentSizeW = 0
        local viewContentSizeH = 0
        self.nameLabel:SetPosition(self.xPos, self.yPos)

        viewContentSizeW, viewContentSizeH = self.nameLabel:GetViewContentSize()
        adjustYPosOffset = adjustYPosOffset + viewContentSizeH
        self.typeLabel:SetPosition(self.xPos, self.yPos + adjustYPosOffset)

        -- 布局各属性标签控件
        ---@type Label
        local theLastLabel = self.typeLabel
        for _, label in pairs(self.mapOfConsumablePropTypeToLabel) do
            viewContentSizeW, viewContentSizeH = theLastLabel:GetViewContentSize()
            adjustYPosOffset = adjustYPosOffset + viewContentSizeH
            label:SetPosition(self.xPos, self.yPos + adjustYPosOffset)

            theLastLabel = label
        end
        for _, label in pairs(self.mapOfEquPropTypeToLabel) do
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
    self.typeLabel:Update(dt)
    --- 更新各属性标签控件
    for _, label in pairs(self.mapOfConsumablePropTypeToLabel) do
        label:Update(dt)
    end
    for _, label in pairs(self.mapOfEquPropTypeToLabel) do
        label:Update(dt)
    end

    --- 更新简介控件
    self.descriptionLabel:Update(dt)

    Widget.Update(self, dt)
end

function HoveringArticleItemTipWidget:Draw()
    Widget.Draw(self)

    self.nameLabel:Draw()
    self.typeLabel:Draw()
    --- 绘制各属性标签控件
    for _, label in pairs(self.mapOfConsumablePropTypeToLabel) do
        label:Draw()
    end
    for _, label in pairs(self.mapOfEquPropTypeToLabel) do
        label:Draw()
    end

    --- 绘制简介控件
    self.descriptionLabel:Draw()
end

function HoveringArticleItemTipWidget:SetPosition(x, y)
    if self.xPos == x and self.yPos == y then
        return
    end

    Widget.SetPosition(self, x, y)

    self.nameLabel:SetPosition(x, y)
    self.typeLabel:SetPosition(x, y)
    --- 设置各属性标签控件坐标
    for _, label in pairs(self.mapOfConsumablePropTypeToLabel) do
        label:SetPosition(x, y)
    end
    for _, label in pairs(self.mapOfEquPropTypeToLabel) do
        label:SetPosition(x, y)
    end

    --- 设置简介控件坐标
    self.descriptionLabel:SetPosition(x, y)
end

function HoveringArticleItemTipWidget:SetSize(width, height)
    if self.width == width and self.height == height then
        return
    end

    Widget.SetSize(self, width, height)

    self.nameLabel:SetSize(width, height)
    self.typeLabel:SetSize(width, height)
    --- 设置各属性标签控件大小
    for _, label in pairs(self.mapOfConsumablePropTypeToLabel) do
        label:SetSize(width, height)
    end
    for _, label in pairs(self.mapOfEquPropTypeToLabel) do
        label:SetSize(width, height)
    end

    --- 设置简介控件大小
    self.descriptionLabel:SetSize(width, height)
end

function HoveringArticleItemTipWidget:SetEnable(enable)
    Widget.SetEnable(self, enable)

    self.nameLabel:SetEnable(enable)
    self.typeLabel:SetEnable(enable)
    --- 使能各属性标签控件
    for _, label in pairs(self.mapOfConsumablePropTypeToLabel) do
        label:SetEnable(enable)
    end
    for _, label in pairs(self.mapOfEquPropTypeToLabel) do
        label:SetEnable(enable)
    end

    --- 设置简介控件大小
    self.descriptionLabel:SetEnable(enable)
end

--- 通过属性调整各控件可见性
function HoveringArticleItemTipWidget:AdjustWidgetsVisibilityByProp()
    if self.type == Common.ArticleType.Consumable then
        for type, label in pairs(self.mapOfConsumablePropTypeToLabel) do
            local value = self.mapOfConsumablePropTypeToValue[type]
            if value == 0 then
                -- 数值为0时不显示
                label:SetVisible(false)
            else
                label:SetVisible(self.isVisible)
            end
        end
        -- 隐藏装备属性控件
        for _, label in pairs(self.mapOfEquPropTypeToLabel) do
            label:SetVisible(false)
        end
    elseif self.type == Common.ArticleType.Equipment then
        -- 隐藏消耗品属性控件
        for _, label in pairs(self.mapOfConsumablePropTypeToLabel) do
            label:SetVisible(false)
        end
        for type, label in pairs(self.mapOfEquPropTypeToLabel) do
            local value = self.mapOfEquPropTypeToValue[type]
            if value == 0 then
                -- 数值为0时不显示
                label:SetVisible(false)
            else
                label:SetVisible(self.isVisible)
            end
        end
    end
end

---@param isVisible boolean
function HoveringArticleItemTipWidget:SetVisible(isVisible)
    Widget.SetVisible(self, isVisible)

    self.nameLabel:SetVisible(isVisible)
    self.typeLabel:SetVisible(isVisible)

    -- 通过属性调整各控件可见性
    self:AdjustWidgetsVisibilityByProp()

    --- 设置简介控件可见性
    self.descriptionLabel:SetVisible(isVisible)
end

---
---@param info ArticleInfo
function HoveringArticleItemTipWidget:SetArticleInfo(info)
    self.isArticleInfoChanged = true

    self.nameLabel:SetText("「" .. info.name .. "」")

    local typeStr = ""
    if info.type == Common.ArticleType.Consumable then
        typeStr = "物品类型：" .. "消耗品"
    elseif info.type == Common.ArticleType.Equipment then
        typeStr = "物品类型：" .. "装备"
    elseif info.type == Common.ArticleType.Material then
        typeStr = "物品类型：" .. "材料"
    end
    self.typeLabel:SetText(typeStr)
    self.type = info.type

    ---@type Label
    local label = nil
    --- 设置 消耗品 属性标签控件文字和数值
    local consumableInfo = info.consumableInfo
    -- HpRecovery
    label = self.mapOfConsumablePropTypeToLabel[Common.ConsumablePropType.HpRecovery]
    label:SetText("hp恢复量：" .. tostring(consumableInfo.hpRecovery))
    self.mapOfConsumablePropTypeToValue[Common.ConsumablePropType.HpRecovery] = consumableInfo.hpRecovery
    -- MpRecoveryRate
    label = self.mapOfConsumablePropTypeToLabel[Common.ConsumablePropType.HpRecoveryRate]
    label:SetText("hp恢复比例：" .. tostring(consumableInfo.hpRecoveryRate * 100) .. "%")
    self.mapOfConsumablePropTypeToValue[Common.ConsumablePropType.HpRecoveryRate] = consumableInfo.hpRecoveryRate
    -- MpRecovery
    label = self.mapOfConsumablePropTypeToLabel[Common.ConsumablePropType.MpRecovery]
    label:SetText("mp恢复量：" .. tostring(consumableInfo.mpRecovery))
    self.mapOfConsumablePropTypeToValue[Common.ConsumablePropType.MpRecovery] = consumableInfo.mpRecovery
    -- MpRecoveryRate
    label = self.mapOfConsumablePropTypeToLabel[Common.ConsumablePropType.MpRecoveryRate]
    label:SetText("mp恢复比例：" .. tostring(consumableInfo.mpRecoveryRate * 100) .. "%")
    self.mapOfConsumablePropTypeToValue[Common.ConsumablePropType.MpRecoveryRate] = consumableInfo.mpRecoveryRate

    --- 设置 装备 属性标签控件文字和数值
    local equInfo = info.equInfo
    -- equType
    local equType = equInfo.type
    local equTypeStr = ""
    if equType == Common.EquType.Belt then
        equTypeStr = "装备类型：" .. "Belt"
    elseif equType == Common.EquType.Cap then
        equTypeStr = "装备类型：" .. "Cap"
    elseif equType == Common.EquType.Coat then
        equTypeStr = "装备类型：" .. "Coat"
    elseif equType == Common.EquType.Face then
        equTypeStr = "装备类型：" .. "Face"
    elseif equType == Common.EquType.Hair then
        equTypeStr = "装备类型：" .. "Hair"
    elseif equType == Common.EquType.Pants then
        equTypeStr = "装备类型：" .. "Pants"
    elseif equType == Common.EquType.Shoes then
        equTypeStr = "装备类型：" .. "Shoes"
    elseif equType == Common.EquType.Skin then
        equTypeStr = "装备类型：" .. "Skin"
    elseif equType == Common.EquType.Title then
        equTypeStr = "装备类型：" .. "Title"
    elseif equType == Common.EquType.Weapon then
        equTypeStr = "装备类型：" .. "Weapon"
    end
    label = self.mapOfEquPropTypeToLabel[Common.EquPropType.Type]
    label:SetText(equTypeStr)
    self.mapOfEquPropTypeToValue[Common.EquPropType.Type] = equInfo.type

    -- HpExtent
    label = self.mapOfEquPropTypeToLabel[Common.EquPropType.HpExtent]
    label:SetText("hp最大值增加量：" .. tostring(equInfo.hpExtent))
    self.mapOfEquPropTypeToValue[Common.EquPropType.HpExtent] = equInfo.hpExtent
    -- HpExtentRate
    label = self.mapOfEquPropTypeToLabel[Common.EquPropType.HpExtentRate]
    label:SetText("hp最大值增加比例：" .. tostring(equInfo.hpExtentRate * 100) .. "%")
    self.mapOfEquPropTypeToValue[Common.EquPropType.HpExtentRate] = equInfo.hpExtentRate
    -- MpExtent
    label = self.mapOfEquPropTypeToLabel[Common.EquPropType.MpExtent]
    label:SetText("mp最大值增加量：" .. tostring(equInfo.mpExtent))
    self.mapOfEquPropTypeToValue[Common.EquPropType.MpExtent] = equInfo.mpExtent
    -- MpExtentRate
    label = self.mapOfEquPropTypeToLabel[Common.EquPropType.MpExtentRate]
    label:SetText("mp最大值增加比例：" .. tostring(equInfo.mpExtentRate * 100) .. "%")
    self.mapOfEquPropTypeToValue[Common.EquPropType.MpExtentRate] = equInfo.mpExtentRate

    --- 设置 简介 标签控件文字
    self.descriptionLabel:SetText(info.desc)

    -- 通过属性调整各控件可见性
    self:AdjustWidgetsVisibilityByProp()
end

return HoveringArticleItemTipWidget
