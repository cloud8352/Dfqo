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
local Label = require("UI.Label")
local SkillDockViewItem = require("UI.SkillDockViewItem")
local Window = require("UI.Window")
local RoleEquTableWidget = require("UI.role_info.role_equipment_table_widget")
local ArticleTableWidget = require("UI.role_info.article_table_widget")
local UiModel = require("UI.ui_model")

local Util = require("source.util.Util")


local LeftPartWidth = _MATH.Round(570 * Util.GetWindowSizeScale())
local EachPartSpace = _MATH.Round(30 * Util.GetWindowSizeScale())

---@class RoleInfoWidget
local RoleInfoWidget = require("core.class")(Widget)

---@param parentWindow Window
---@param model UiModel
function RoleInfoWidget:Ctor(parentWindow, model)
    -- 父类构造函数
    Widget.Ctor(self, parentWindow)

    self.model = model
    self.roleEquTableWidget = RoleEquTableWidget.New(parentWindow, self.model)

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

    self.articleTableWidget:Draw()
end

function RoleInfoWidget:MouseEvent()
end

function RoleInfoWidget:SetPosition(x, y)
    self.xPos = x
    self.yPos = y

    self.roleEquTableWidget:SetPosition(self.xPos, self.yPos)

    self.articleTableWidget:SetPosition(self.xPos + LeftPartWidth + EachPartSpace, self.yPos)
end

function RoleInfoWidget:SetSize(width, height)
    self.width = width
    self.height = height

    self.roleEquTableWidget:SetSize(LeftPartWidth, self.height)

    self.articleTableWidget:SetSize(self.width - LeftPartWidth - EachPartSpace, self.height)
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

return RoleInfoWidget
