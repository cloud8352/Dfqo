--[[
	desc: UiCommon table, ui通用变量和方法
	author: keke <243768648@qq.com>
	since: 2023-7-19
	alter: 2023-7-19
]]
--

local _TABLE = require("lib.table")

---@generic UiCommon
local UiCommon = {}

---@enum ArticleType
UiCommon.ArticleType = {
    Empty = 0x0001,
    Consumable = 0x0002,
    Equipment = 0x0004,
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
    Neck = 7,
    Shoes = 8,
    Skin = 9,
    Weapon = 10,
    Title = 11,
}

local mapOfEquTypeToTag = {}
mapOfEquTypeToTag[UiCommon.EquType.Belt] = "belt"
mapOfEquTypeToTag[UiCommon.EquType.Cap] = "cap"
mapOfEquTypeToTag[UiCommon.EquType.Coat] = "coat"
mapOfEquTypeToTag[UiCommon.EquType.Face] = "face"
mapOfEquTypeToTag[UiCommon.EquType.Hair] = "hair"
mapOfEquTypeToTag[UiCommon.EquType.Pants] = "pants"
mapOfEquTypeToTag[UiCommon.EquType.Neck] = "neck"
mapOfEquTypeToTag[UiCommon.EquType.Shoes] = "shoes"
mapOfEquTypeToTag[UiCommon.EquType.Skin] = "skin"
mapOfEquTypeToTag[UiCommon.EquType.Weapon] = "weapon"
mapOfEquTypeToTag[UiCommon.EquType.Title] = "title"
--- 装备类型到标签的映射表
UiCommon.MapOfEquTypeToTag = mapOfEquTypeToTag

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
---@field hpRecovery number
---@field hpRecoveryRate number
---@field mpRecovery number
---@field mpRecoveryRate number
local ConsumableInfo = {
    -- hp/mp
    hpRecovery = 0,
    hpRecoveryRate = 0.0,
    mpRecovery = 0,
    mpRecoveryRate = 0.0,
}

--- 装备信息
---@class EquInfo
---@field type EquType
---@field resMgrEquData Actor.RESMGR.EquipmentData
---@field hpExtent number
---@field hpExtentRate number
---@field mpExtent number
---@field mpExtentRate number
local EquInfo = {
    type = UiCommon.EquType.Belt,
    ---@type Actor.RESMGR.EquipmentData
    resMgrEquData = { kind = "", subKind = "" },
    hpExtent = 0,
    hpExtentRate = 0.0,
    mpExtent = 0,
    mpExtentRate = 0.0,
}

--- 物品项信息
---@class ArticleInfo
---@field id number
---@field type ArticleType
---@field name string
---@field desc string
---@field iconPath string
---@field count number
---@field maxCount number
---@field consumableInfo ConsumableInfo
---@field equInfo EquInfo
local ArticleInfo = {
    id = 0,
    type = UiCommon.ArticleType.Empty,
    name = "",
    desc = "",
    iconPath = "",
    count = 1,
    maxCount = 100,
    ---@type ConsumableInfo
    consumableInfo = _TABLE.DeepClone(ConsumableInfo),
    ---@type EquInfo
    equInfo = _TABLE.DeepClone(EquInfo)
}

--- 创建新的物品信息
---@return ArticleInfo
function UiCommon.NewArticleInfo()
    return _TABLE.DeepClone(ArticleInfo)
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
---@field id number
---@field name string
---@field desc string
---@field iconPath string
---@field cdTime number
---@field mp number
---@field physicalDamageEnhanceRate number
---@field magicDamageEnhanceRate number
local SkillInfo = {
    id = 0,
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
    return _TABLE.DeepClone(SkillInfo)
end

return UiCommon
