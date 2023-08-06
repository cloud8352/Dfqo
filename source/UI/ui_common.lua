--[[
	desc: UiCommon table, ui通用变量和方法
	author: keke <243768648@qq.com>
	since: 2023-7-19
	alter: 2023-7-19
]] --

local _TABLE = require("lib.table")

---@generic UiCommon
local UiCommon = {}

---@enum ArticleType
UiCommon.ArticleType = {
	Empty = 0x0001,
	Consumable = 0x0002,
	Equpment = 0x0004,
	Material = 0x0008,
}
--- 消耗品属性类型
---@enum ConsumablePropType
UiCommon.ConsumablePropType = {
	HpRecovery = 1,
	HpRecoveryRate = 2,
	MpRecovery = 3,
	MpRecoveryRate = 4,
}

---@enum EquType
UiCommon.EquType = {
	Belt = 1,
	Cap = 2,
	Coat = 3,
	Face = 4,
	Hair = 5,
	Pants = 6,
	Shoes = 7,
	Skin = 8,
	Weapeon = 9,
	Title = 10,
}

--- 装备属性类型
---@enum EquPropType
UiCommon.EquPropType = {
	Type = 1,
	HpExtent = 2,
	HpExtentRate = 3,
	MpExtent = 4,
	MpExtentRate = 5,
}

--- 消耗品信息
---@class ConsumableInfo
local ConsumableInfo = {
	-- hp/mp
	hpRecovery = 0,
	hpRecoveryRate = 0.0,
	mpRecovery = 0,
	mpRecoveryRate = 0.0,
}

--- 装备信息
---@class EquInfo
local EquInfo = {
	type = UiCommon.EquType.Belt,
	hpExtent = 0,
	hpExtentRate = 0.0,
	mpExtent = 0,
	mpExtentRate = 0.0,
}

--- 物品项信息
---@class ArticleInfo
local ArticleInfo = {
	uuid = 0,
	type = UiCommon.ArticleType.Empty,
	name = "",
	desc = "",
	iconPath = "",
	count = 1,
	maxCount = 100,
	---@type ConsumableInfo
	consumableInfo = _TABLE.Clone(ConsumableInfo),
	---@type EquInfo
	equInfo = _TABLE.Clone(EquInfo)
}

--- 创建新的物品信息
---@return ArticleInfo
function UiCommon.NewArticleInfo()
	return _TABLE.Clone(ArticleInfo)
end

UiCommon.ArticleItemWidth = 58

UiCommon.ArticleTableColCount = 7
UiCommon.ArticleTableRowCount = 10

UiCommon.EquTableColCount = 5
UiCommon.EquTableRowCount = 2

--== 技能相关
--- 技能属性类型
---@enum SkillPropType
UiCommon.SkillPropType = {
	CdTime = 1,
	Mp = 2,
	PhysicalDamageEnhanceRate = 3,
	MagicDamageEnhanceRate = 4,
}

--- 技能信息
---@class SkillInfo
local SkillInfo = {
	uuid = 0,
	name = "",
	desc = "",
	iconPath = "",
	cdTime = 0,
	mp = 0,
	physicalDamageEnhanceRate = 0.0,
	magicDamageEnhanceRate = 0.0,
}

--- 创建新的物品信息
---@return SkillInfo
function UiCommon.NewSkillInfo()
	return _TABLE.Clone(SkillInfo)
end

return UiCommon
