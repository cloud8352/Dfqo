--[[
    desc: IconTextLabel class. 技能托盘显示框架
    author: keke <243768648@qq.com>
]] --

local WindowManager = require("UI.WindowManager")
local Widget = require("UI.Widget")
local Label = require("UI.Label")

local Util = require("util.Util")

local IconMargin = 3
local IconTextSpace = 5

---@class IconTextLabel
local IconTextLabel = require("core.class")()

---@param parentWindow Window
function IconTextLabel:Ctor(parentWindow)
    assert(parentWindow, "must assign parent window")
    -- 父类构造函数
    self.baseWidget = Widget.New(parentWindow)

    self.iconBgLabel = Label.New(parentWindow)
    self.iconBgLabel:SetIconSpriteDataPath("icon/characterProfile/profileIconBg")
    self.iconLabel = Label.New(parentWindow)

    self.textLabel = Label.New(parentWindow)
    self.textLabel:SetAlignments({ Label.AlignmentFlag.AlignLeft, Label.AlignmentFlag.AlignVCenter })
end

function IconTextLabel:Update(dt)
    self.baseWidget:Update(dt)

    self.iconBgLabel:Update(dt)
    self.iconLabel:Update(dt)
    self.textLabel:Update(dt)
end

function IconTextLabel:Draw()
    self.baseWidget:Draw()

    self.iconBgLabel:Draw()
    self.iconLabel:Draw()
    self.textLabel:Draw()
end

function IconTextLabel:SetPosition(x, y)
    self.baseWidget:SetPosition(x, y)

    self.iconBgLabel:SetPosition(x, y)
    self.iconLabel:SetPosition(x + IconMargin, y + IconMargin)

    local iconSize, _ = self.iconBgLabel:GetSize()
    self.textLabel:SetPosition(x + iconSize + IconTextSpace, y)
end

---@return number, number w, h
function IconTextLabel:GetSize()
    return self.baseWidget:GetSize()
end

function IconTextLabel:SetSize(width, height)
    self.baseWidget:SetSize(width, height)

    local iconBgSize = height
    self.iconBgLabel:SetSize(iconBgSize, iconBgSize)
    self.iconBgLabel:SetIconSize(iconBgSize, iconBgSize)
    local iconSize = height - IconMargin * 2
    self.iconLabel:SetSize(iconSize, iconSize)
    self.iconLabel:SetIconSize(iconSize, iconSize)

    self.textLabel:SetSize(width - iconSize - IconTextSpace, height)
end

function Widget:SetEnable(enable)
    self.baseWidget:SetEnable(enable)
end

---@param isVisible boolean
function IconTextLabel:SetVisible(isVisible)
    self.baseWidget:SetVisible(isVisible)
end

function IconTextLabel:SetIconSpriteDataPath(path)
    self.iconLabel:SetIconSpriteDataPath(path)
end

function IconTextLabel:SetText(text)
    self.textLabel:SetText(text)
end

return IconTextLabel
