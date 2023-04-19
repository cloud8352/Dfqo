--[[
	desc: HoveringItemTipWidget class.
	author: keke <243768648@qq.com>
	since: 2023-4-21
	alter: 2023-4-21
]] --

local Widget = require("UI.Widget")
local Label = require("UI.Label")

---@class HoveringItemTipWidget
local HoveringItemTipWidget = require("core.class")(Widget)

---@param parentWindow Window
function HoveringItemTipWidget:Ctor(parentWindow)
    -- 父类构造函数
    Widget.Ctor(self, parentWindow)

    self.nameLabel = Label.New(parentWindow)
    self.nameLabel:SetAlignments({Label.AlignmentFlag.AlignLeft, Label.AlignmentFlag.AlignTop})
    self.name = ""
    self.lastName = ""

    self.descriptionLabel = Label.New(parentWindow)
    self.descriptionLabel:SetAlignments({Label.AlignmentFlag.AlignLeft, Label.AlignmentFlag.AlignTop})
    self.description = ""
    self.lastDescription = ""

    self.cdLabel = Label.New(parentWindow)
    self.cdLabel:SetAlignments({Label.AlignmentFlag.AlignLeft, Label.AlignmentFlag.AlignTop})
    self.cdStr = ""
    self.lastCdStr = ""

    self.mpLabel = Label.New(parentWindow)
    self.mpLabel:SetAlignments({Label.AlignmentFlag.AlignLeft, Label.AlignmentFlag.AlignTop})
    self.mpStr = ""
    self.lastMpStr = ""

    self.damageTypeLabel = Label.New(parentWindow)
    self.damageTypeLabel:SetAlignments({Label.AlignmentFlag.AlignLeft, Label.AlignmentFlag.AlignTop})
    self.damageTypeStr = ""
    self.lastDamageTypeStr = ""

    self.damageRateLabel = Label.New(parentWindow)
    self.damageRateLabel:SetAlignments({Label.AlignmentFlag.AlignLeft, Label.AlignmentFlag.AlignTop})
    self.damageRateStr = ""
    self.lastDamageRateStr = ""
end

function HoveringItemTipWidget:Update(dt)
    if (self.lastXPos ~= self.xPos
        or self.lastYPos ~= self.yPos
        or self.lastWidth ~= self.width
        or self.lastHeight ~= self.height
        or self.lastName ~= self.name
        or self.lastDescription ~= self.description
        or self.lastCdStr ~= self.cdStr
        or self.lastMpStr ~= self.mpStr
        or self.lastDamageTypeStr ~= self.damageTypeStr
        or self.lastDamageRateStr ~= self.damageRateStr
        )
        then
        self.nameLabel:Update(dt)
        self.descriptionLabel:Update(dt)
        self.cdLabel:Update(dt)
        self.mpLabel:Update(dt)
        self.damageTypeLabel:Update(dt)
        self.damageRateLabel:Update(dt)


        local adjustYPosOffset = 0
        local viewContentSizeW = 0
        local viewContentSizeH = 0
        self.nameLabel:SetPosition(self.xPos, self.yPos)

        viewContentSizeW, viewContentSizeH = self.nameLabel:GetViewContentSize()
        adjustYPosOffset = adjustYPosOffset + viewContentSizeH
        self.descriptionLabel:SetPosition(self.xPos, self.yPos + adjustYPosOffset)

        viewContentSizeW, viewContentSizeH = self.descriptionLabel:GetViewContentSize()
        adjustYPosOffset = adjustYPosOffset + viewContentSizeH
        self.cdLabel:SetPosition(self.xPos, self.yPos + adjustYPosOffset)

        viewContentSizeW, viewContentSizeH = self.cdLabel:GetViewContentSize()
        adjustYPosOffset = adjustYPosOffset + viewContentSizeH
        self.mpLabel:SetPosition(self.xPos, self.yPos + adjustYPosOffset)

        viewContentSizeW, viewContentSizeH = self.mpLabel:GetViewContentSize()
        adjustYPosOffset = adjustYPosOffset + viewContentSizeH
        self.damageTypeLabel:SetPosition(self.xPos, self.yPos + adjustYPosOffset)

        viewContentSizeW, viewContentSizeH = self.damageTypeLabel:GetViewContentSize()
        adjustYPosOffset = adjustYPosOffset + viewContentSizeH
        self.damageRateLabel:SetPosition(self.xPos, self.yPos + adjustYPosOffset)
    end

    self.nameLabel:Update(dt)
    self.descriptionLabel:Update(dt)
    self.cdLabel:Update(dt)
    self.mpLabel:Update(dt)
    self.damageTypeLabel:Update(dt)
    self.damageRateLabel:Update(dt)

    Widget.Update(self, dt)
    self.lastName = self.name
    self.lastDescription = self.description
    self.lastCdStr = self.cdStr
    self.lastMpStr = self.mpStr
    self.lastDamageTypeStr = self.damageTypeStr
    self.lastDamageRateStr = self.damageRateStr
end

function HoveringItemTipWidget:Draw()
    Widget.Draw(self)

    self.nameLabel:Draw()
    self.descriptionLabel:Draw()
    self.cdLabel:Draw()
    self.mpLabel:Draw()
    self.damageTypeLabel:Draw()
    self.damageRateLabel:Draw()
end

function HoveringItemTipWidget:SetPosition(x, y)
    if self.xPos == x and self.yPos == y then
        return
    end

    Widget.SetPosition(self, x, y)

    self.nameLabel:SetPosition(x, y)
    self.descriptionLabel:SetPosition(x, y)
    self.cdLabel:SetPosition(x, y)
    self.mpLabel:SetPosition(x, y)
    self.damageTypeLabel:SetPosition(x, y)
    self.damageRateLabel:SetPosition(x, y)
end

function HoveringItemTipWidget:SetSize(width, height)
    if self.width == width and self.height == height then
        return
    end

    Widget.SetSize(self, width, height)

    self.nameLabel:SetSize(width, height)
    self.descriptionLabel:SetSize(width, height)
    self.cdLabel:SetSize(width, height)
    self.mpLabel:SetSize(width, height)
    self.damageTypeLabel:SetSize(width, height)
    self.damageRateLabel:SetSize(width, height)
end

function HoveringItemTipWidget:SetEnable(enable)
    Widget.SetEnable(self, enable)

    self.nameLabel:SetEnable(enable)
    self.descriptionLabel:SetEnable(enable)
    self.cdLabel:SetEnable(enable)
    self.mpLabel:SetEnable(enable)
    self.damageTypeLabel:SetEnable(enable)
    self.damageRateLabel:SetEnable(enable)
end

---@param isVisible boolean
function HoveringItemTipWidget:SetVisible(isVisible)
    Widget.SetVisible(self, isVisible)

    self.nameLabel:SetVisible(isVisible)
    self.descriptionLabel:SetVisible(isVisible)
    self.cdLabel:SetVisible(isVisible)
    self.mpLabel:SetVisible(isVisible)
    self.damageTypeLabel:SetVisible(isVisible)
    self.damageRateLabel:SetVisible(isVisible)
end

---@param name string
function HoveringItemTipWidget:SetName(name)
    self.nameLabel:SetText("「" .. name .. "」")
    self.name = name
end

---@param description string
function HoveringItemTipWidget:SetDescription(description)
    self.descriptionLabel:SetText(description)
    self.description = description
end

---@param cdStr string
function HoveringItemTipWidget:SetCdStr(cdStr)
    self.cdLabel:SetText("冷却时间：" .. cdStr .. "s")
    self.cdStr = cdStr
end

---@param mpStr string
function HoveringItemTipWidget:SetMpStr(mpStr)
    self.mpLabel:SetText("消耗mp：" .. mpStr)
    self.mpStr = mpStr
end

---@param isPhysical boolean
function HoveringItemTipWidget:SetIsPhysicalDamageType(isPhysical)
    local damageTypeStr = ""
    if isPhysical then
        damageTypeStr = "物理"
    else
        damageTypeStr = "魔法"
    end
    self.damageTypeLabel:SetText("伤害类型：" .. damageTypeStr)
    self.damageTypeStr = damageTypeStr
end

---@param damageRateStr string
function HoveringItemTipWidget:SetDamageRateStr(damageRateStr)
    self.damageRateLabel:SetText("伤害增加率：" .. damageRateStr .. "%")
    self.damageRateStr = damageRateStr
end

return HoveringItemTipWidget
