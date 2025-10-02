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

--- 信号
---@class SlotInfo
---@field public Obj Obj
---@field public Func function
local SlotInfo = {
    ---@type Obj
    Obj = nil,
    ---@type function
    Func = nil,
}
function UiCommon.NewSlotInfo()
    _TABLE.DeepClone(SlotInfo)
end

---@enum ArticleType
UiCommon.ArticleType = {
    Empty = 1,
    Consumable = 2,
    Equipment = 3,
    Material = 4,
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
    Suit = 12,
}
UiCommon.EquTypeCount = 12

---@enum WeaponSubType
UiCommon.WeaponSubType = {
    HSword = 1, -- 武器 - 巨剑
    Katana = 2, -- 武器 - 太刀
    BeamSwd = 3, -- 武器 - 光剑
}

---@enum GameState
local GameState = {
    ActorSelect = 1,
    Started = 2,
}
UiCommon.GameState = GameState

---@enum GenderEnum
local GenderEnum = {
    Male = 1,
    Female = 2,
}
UiCommon.GenderEnum = GenderEnum

---@type table<int, string>
local mapOfGenderToTxt = {}
mapOfGenderToTxt[GenderEnum.Male] = "男"
mapOfGenderToTxt[GenderEnum.Female] = "女"
UiCommon.MapOfGenderToTxt = mapOfGenderToTxt

---@enum JobEnum
local JobEnum = {
    Other = 0,
    SwordMan = 1,
    Fighter = 2,
    InventoryItem = 3,
    Kyo = 4,
    Tsunade = 5,
    Iori = 6,
}
UiCommon.JobEnum = JobEnum

---@type table<int, string>
local mapOfJobToTxt = {}
mapOfJobToTxt[JobEnum.Other] = "其他"
mapOfJobToTxt[JobEnum.SwordMan] = "鬼剑士"
mapOfJobToTxt[JobEnum.Fighter] = "格斗家"
mapOfJobToTxt[JobEnum.InventoryItem] = "物品"
mapOfJobToTxt[JobEnum.Kyo] = "草薙京"
mapOfJobToTxt[JobEnum.Tsunade] = "纲手"
mapOfJobToTxt[JobEnum.Iori] = "八神庵"
UiCommon.MapOfJobToTxt = mapOfJobToTxt

---@type table<int, string>
local mapOfJobToPath = {}
mapOfJobToPath[JobEnum.Other] = "----"
mapOfJobToPath[JobEnum.SwordMan] = "duelist/swordman"
mapOfJobToPath[JobEnum.Fighter] = "duelist/Fighter"
mapOfJobToPath[JobEnum.InventoryItem] = "----"
mapOfJobToPath[JobEnum.Kyo] = "duelist/Kyo"
mapOfJobToPath[JobEnum.Tsunade] = "duelist/Tsunade"
mapOfJobToPath[JobEnum.Iori] = "duelist/Iori"
UiCommon.MapOfJobToPath = mapOfJobToPath

---@type table<int, string>
local mapOfJobToIntroVideoPath = {}
mapOfJobToIntroVideoPath[JobEnum.Other] = ""
mapOfJobToIntroVideoPath[JobEnum.SwordMan] = "asset/Video/MaleSwormanSkillIntro.ogv"
mapOfJobToIntroVideoPath[JobEnum.Fighter] = "asset/Video/FemaleFighterSkillIntro.ogv"
mapOfJobToIntroVideoPath[JobEnum.InventoryItem] = ""
mapOfJobToIntroVideoPath[JobEnum.Kyo] = ""
mapOfJobToIntroVideoPath[JobEnum.Tsunade] = ""
mapOfJobToIntroVideoPath[JobEnum.Iori] = ""
UiCommon.MapOfJobToIntroVideoPath = mapOfJobToIntroVideoPath

---@type table<int, string>
local mapOfJobToIntroStr = {}
mapOfJobToIntroStr[JobEnum.Other] = "其他职业"
mapOfJobToIntroStr[JobEnum.SwordMan] = "鬼剑士，能够使用鬼神的力量和独特的剑术进行战斗"
mapOfJobToIntroStr[JobEnum.Fighter] = "格斗家，擅长使用拳法和腿法进行快速连击"
mapOfJobToIntroStr[JobEnum.InventoryItem] = "物品"
mapOfJobToIntroStr[JobEnum.Kyo] = "草薙京，草薙流古武术的继承者，拥有操控赤炎的能力"
mapOfJobToIntroStr[JobEnum.Tsunade] = "《天外魔境真传-东方伊甸园》 - 纲手"
mapOfJobToIntroStr[JobEnum.Iori] = "与草薙京相对，使用着能操作紫色火焰的格斗术。"
UiCommon.MapOfJobToIntroStr = mapOfJobToIntroStr

---@type table<int, string>
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
mapOfEquTypeToTag[UiCommon.EquType.Suit] = "Suit"
--- 装备类型到标签的映射表
UiCommon.MapOfEquTypeToTag = mapOfEquTypeToTag

---@type table<string, int>
local mapOfTagToEquType = {}
for k, v in pairs(mapOfEquTypeToTag) do
    mapOfTagToEquType[v] = k
end
UiCommon.MapOfTagToEquType = mapOfTagToEquType

--- 消耗品属性类型
---@enum ConsumablePropType
UiCommon.ConsumablePropType = {
    HpRecovery = 1,
    HpRecoveryRate = 2,
    MpRecovery = 3,
    MpRecoveryRate = 4,
}

--- 消耗品信息
---@class ConsumableInfo
---@field hpRecovery number
---@field hpRecoveryRate number
---@field mpRecovery number
---@field mpRecoveryRate number
---@field SkillPath string
---@field StateName string
local ConsumableInfo = {
    -- hp/mp
    hpRecovery = 0,
    hpRecoveryRate = 0.0,
    mpRecovery = 0,
    mpRecoveryRate = 0.0,
    SkillPath = "",
    StateName = "",
}

--- 装备属性类型
---@enum EquPropType
UiCommon.EquPropType = {
    Type = 1,
    MaxHp = 2,
    HpRecovery = 3,
    MaxMp = 4,
    PhyAtk = 5,
    MagAtk = 6,
    PhyDef = 7,
    MagDef = 8,
    MoveSpeedRatio = 9,
    AttackSpeedRatio = 10,
    CoolDownSpeedRatio = 11,
    PhyAtkRatio = 12,
    MagAtkRatio = 13,
    HpRecoverySpeedRatio = 14
}

--- 装备信息
---@class EquInfo
---@field type EquType
---@field resMgrEquData Actor.RESMGR.EquipmentData
---@field MaxHp number
---@field HpRecovery number
---@field PhyAtk number
---@field MagAtk number
---@field PhyDef number
---@field MagDef number
---@field MoveSpeedRatio number
---@field AttackSpeedRatio number
---@field CoolDownSpeedRatio number
---@field PhyAtkRatio number
---@field MagAtkRatio number
---@field HpRecoverySpeedRatio number
local EquInfo = {
    type = UiCommon.EquType.Belt,
    ---@type Actor.RESMGR.EquipmentData
    resMgrEquData = { kind = "", subKind = "" },
    MaxHp = 0,
    HpRecovery = 0,
    MaxMp = 0,
    PhyAtk = 0,
    MagAtk = 0,
    PhyDef = 0,
    MagDef = 0,
    MoveSpeedRatio = 0,
    AttackSpeedRatio = 0,
    CoolDownSpeedRatio = 0,
    PhyAtkRatio = 0,
    MagAtkRatio = 0,
    HpRecoverySpeedRatio = 0 
}

---@class ArticleInfo 物品项信息
---@field id number
---@field path string
---@field Index int
---@field type ArticleType
---@field name string
---@field desc string
---@field iconPath string
---@field count number
---@field maxCount number
---@field UsableJobs table<int, int>
---@field UsableGenders table<int, GenderEnum>
---@field consumableInfo ConsumableInfo
---@field equInfo EquInfo
local ArticleInfo = {
    id = 0,
    path = "", -- Inventory Item config path
    Index = -1,
    type = UiCommon.ArticleType.Empty,
    name = "",
    desc = "",
    iconPath = "",
    count = 1,
    maxCount = 100,
    ---@type table<int, int>
    UsableJobs = {},
    ---@type table<int, int>
    UsableGenders = _TABLE.DeepClone(GenderEnum),
    ---@type ConsumableInfo
    consumableInfo = _TABLE.DeepClone(ConsumableInfo),
    ---@type EquInfo
    equInfo = _TABLE.DeepClone(EquInfo)
}

--- 创建新的物品信息
---@return ArticleInfo 创建新的物品信息
function UiCommon.NewArticleInfo()
    return _TABLE.DeepClone(ArticleInfo)
end


---@param articleInfo ArticleInfo
---@param inventoryItemData Actor.RESMGR.ItemData
function UiCommon.UpdateArticleInfoFromData(articleInfo, inventoryItemData)
    local typeStr = inventoryItemData.type
    articleInfo.path = typeStr .. "/" .. inventoryItemData.path
    if typeStr == "equipment" then
        articleInfo.type = UiCommon.ArticleType.Equipment
        ---@type Actor.RESMGR.EquipmentData
        local resMgrEquData = inventoryItemData
        articleInfo.equInfo.resMgrEquData = resMgrEquData
        articleInfo.iconPath = "icon/equipment/" .. resMgrEquData.icon

        local equType = 0
        if resMgrEquData.kind == "clothes" then
            equType = UiCommon.MapOfTagToEquType[resMgrEquData.subKind]
        else 
            equType = UiCommon.MapOfTagToEquType[resMgrEquData.kind]
        end
        articleInfo.equInfo.type = equType

        ---@type table
        local addedPropData = resMgrEquData.add
        local equInfo = articleInfo.equInfo
        if addedPropData then
            equInfo.MaxHp = addedPropData.maxHp or 0
            equInfo.HpRecovery = addedPropData.hpRecovery or 0
            equInfo.MaxMp = addedPropData.maxMp or 0
            equInfo.PhyAtk = addedPropData.phyAtk or 0
            equInfo.MagAtk = addedPropData.magAtk or 0
            equInfo.PhyDef = addedPropData.phyDef or 0
            equInfo.MagDef = addedPropData.magDef or 0
            equInfo.MoveSpeedRatio = addedPropData.moveRate or 0
            equInfo.AttackSpeedRatio = addedPropData.attackRate or 0
            equInfo.CoolDownSpeedRatio = addedPropData.coolDownRate or 0
            equInfo.PhyAtkRatio = addedPropData.phyAtkRate or 0
            equInfo.MagAtkRatio = addedPropData.magAtkRate or 0
            equInfo.HpRecoverySpeedRatio = addedPropData.hpRecoveryRate or 0
        end
    elseif typeStr == "Attribute" then
        articleInfo.type = UiCommon.ArticleType.Consumable
        ---@type Actor.RESMGR.AttributeData
        local resMgrConsumableData = inventoryItemData
        articleInfo.iconPath = "icon/Attribute/" .. resMgrConsumableData.icon
        articleInfo.consumableInfo.hpRecovery = resMgrConsumableData.HpRecovery
        articleInfo.consumableInfo.hpRecoveryRate = resMgrConsumableData.HpRecoveryRate
        articleInfo.consumableInfo.mpRecovery = resMgrConsumableData.MpRecovery
        articleInfo.consumableInfo.mpRecoveryRate = resMgrConsumableData.MpRecoveryRate
        articleInfo.consumableInfo.StateName = resMgrConsumableData.StateName
    elseif typeStr == "skill" then
        articleInfo.type = UiCommon.ArticleType.Consumable
        ---@type Actor.RESMGR.SkillData
        local resMgrSkillData = inventoryItemData
        articleInfo.iconPath = "icon/skill/" .. resMgrSkillData.icon
        articleInfo.consumableInfo.SkillPath = resMgrSkillData.path
    elseif typeStr == "buff" then
        --
    end
    articleInfo.name = inventoryItemData.name
    articleInfo.desc = inventoryItemData.special or ""
    articleInfo.UsableJobs = inventoryItemData.UsableJobs
    articleInfo.UsableGenders = inventoryItemData.UsableGenders
end

---@param info ArticleInfo
---@param job int JobEnum
---@return boolean
function UiCommon.IsArticleInfoFitForJob(info, job)
    for _, usableJob in pairs(info.UsableJobs) do
        if usableJob == job then
            return true
        end
    end

    return false
end

---@param info ArticleInfo
---@param gender int GenderEnum
---@return boolean
function UiCommon.IsArticleInfoFitForGender(info, gender)
    for _, usableGender in pairs(info.UsableGenders) do
        if usableGender == gender then
            return true
        end
    end

    return false
end

---@class ArticleInfoItemIndex 物品信息项检索
---@field Index number
---@field Info ArticleInfo
local ArticleInfoItemIndex = {
    Index = -1,
    Info = UiCommon.NewArticleInfo()
}

--- 创建新的物品信息项检索
---@return ArticleInfoItemIndex
function UiCommon.NewArticleInfoItemIndex()
    return _TABLE.DeepClone(ArticleInfoItemIndex)
end

UiCommon.ArticleItemWidth = 45

UiCommon.ArticleTableColCount = 8
UiCommon.ArticleTableRowCount = 12
---@type int
UiCommon.ArticleTableTotalCount = UiCommon.ArticleTableColCount * UiCommon.ArticleTableRowCount

-- 物品托盘表格列数
UiCommon.ArticleDockColCount = 6

--== 技能相关
--- 技能属性类型
---@enum SkillPropType
UiCommon.SkillPropType = {
    CdTime = 1,
    Mp = 2,
    PhysicalDamageEnhanceRate = 3,
    MagicDamageEnhanceRate = 4,
}

---- 技能信息
--- 技能升级所需的基础经验
local BaseExpOfSkillLevelUp = 500

---@class SkillInfo
---@field id number
---@field name string
---@field desc string
---@field resDataPath string
---@field iconPath string
---@field cdTime number
---@field mp number
---@field physicalDamageEnhanceRate number
---@field magicDamageEnhanceRate number
---@field Exp int
---@field Level int
---@field ExpOfCurrentLevel int
---@field MaxExpOfCurrentLevel int
local SkillInfo = {
    id = 0,
    name = "",
    desc = "",
    resDataPath = "",
    iconPath = "",
    cdTime = 0,
    mp = 0,
    physicalDamageEnhanceRate = 0.0,
    magicDamageEnhanceRate = 0.0,
    Exp = 0,
    Level = 1,
    ExpOfCurrentLevel = 0,
    MaxExpOfCurrentLevel = 0
}

--- 创建新的物品信息
---@return SkillInfo
function UiCommon.NewSkillInfo()
    return _TABLE.DeepClone(SkillInfo)
end


---@param skillInfo SkillInfo
---@param data Actor.RESMGR.SkillData
function UiCommon.UpdateSkillInfoFromData(skillInfo, data)
    skillInfo.name = data.name
    skillInfo.desc = data.special
    skillInfo.resDataPath = data.path
    skillInfo.iconPath = "icon/skill/" .. data.icon
    skillInfo.cdTime = data.time
    skillInfo.mp = data.mp
    -- 此处解析错误
    if data.attackValues and data.attackValues.isPhysical then
        skillInfo.physicalDamageEnhanceRate = 0 or data.attackValues.damageRate
    else
        skillInfo.magicDamageEnhanceRate = 0 or data.attackValues.damageRate
    end
end

---@param data Actor.RESMGR.SkillData
---@return SkillInfo
function UiCommon.NewSkillInfoFromData(data)
    local skillInfo = UiCommon.NewSkillInfo()
    skillInfo.id = 1
    UiCommon.UpdateSkillInfoFromData(skillInfo, data)
    return skillInfo
end

---@param skillInfo SkillInfo
---@param skillObj Actor.Skill
function UiCommon.UpdateSkillInfoFromSkillObj(skillInfo, skillObj)
    skillInfo.name = skillObj.Name
    skillInfo.desc = skillObj.Desc
    skillInfo.resDataPath = skillObj:GetData().path
    skillInfo.iconPath = "icon/skill/" .. skillObj.icon
    skillInfo.cdTime = skillObj.time
    skillInfo.mp = skillObj.mp
    -- 此处解析错误
    if skillObj.attackValues and skillObj.attackValues.isPhysical then
        skillInfo.physicalDamageEnhanceRate = 0 or skillObj.attackValues.damageRate
    else
        skillInfo.magicDamageEnhanceRate = 0 or skillObj.attackValues.damageRate
    end
end

---@param info SkillInfo
---@param exp int
function UiCommon.SetExpToSkillInfo(info, exp)
    info.Exp = exp
    info.ExpOfCurrentLevel = exp
    local level = 1
    local lastExpOfSkillLevelUp = 0
    while (1) do
        local expOfSkillLevelUp = BaseExpOfSkillLevelUp * 2 ^ (level - 1)
        if expOfSkillLevelUp > exp then
            info.Level = level
            info.MaxExpOfCurrentLevel = expOfSkillLevelUp - lastExpOfSkillLevelUp
            break
        end

        info.ExpOfCurrentLevel = exp - expOfSkillLevelUp
        level = level + 1
        lastExpOfSkillLevelUp = expOfSkillLevelUp
    end
end

---@param info SkillInfo
---@param exp int
---@return boolean whetherSkillLevelUp
function UiCommon.AddExpOfSkillInfo(info, exp)
    info.Exp = info.Exp + exp
    info.ExpOfCurrentLevel = info.ExpOfCurrentLevel + exp
    if info.MaxExpOfCurrentLevel < info.ExpOfCurrentLevel then
        -- 技能升级
        UiCommon.SetExpToSkillInfo(info, info.Exp)
        return true
    end

    return false
end

--- 角色属性类型
---@enum ActorAttributeType
UiCommon.ActorAttributeType = {
    Hp = 1,
    MaxHp = 2,
    HpRecovery = 3,
    Mp = 4,
    MaxMp = 5,
    PhyAtk = 6,
    MagAtk = 7,
    PhyDef = 8,
    MagDef = 9,
    MoveSpeed = 10,
    AttackSpeed = 11,
    PhyAtkRate = 12,
    MagAtkRate = 13
}


--- 输入键值结构体
---@class ItemKeyGroup.InputKeyValueStruct
---@field Up string
---@field Down string
---@field Left string
---@field Right string
---@field NormalAttack string
---@field CounterAttack string
---@field GetItem string
---@field Skill1 string
---@field Skill2 string
---@field Skill3 string
---@field Skill4 string
---@field Skill5 string
---@field Skill6 string
---@field Skill7 string
local InputKeyValueStruct = {
    Up = "up",
    Down = "down",
    Left = "left",
    Right = "right",
    NormalAttack = "normalAttack",
    Jump = "jump",
    CounterAttack = "counterAttack",
    GetItem = "getItem",
    Skill1 = "skill1",
    Skill2 = "skill2",
    Skill3 = "skill3",
    Skill4 = "skill4",
    Skill5 = "skill5",
    Skill6 = "skill6",
    Skill7 = "skill7",
    DockItem1 = "DockItem1",
    DockItem2 = "DockItem2",
    DockItem3 = "DockItem3",
    DockItem4 = "DockItem4",
    DockItem5 = "DockItem5",
    DockItem6 = "DockItem6",
}
UiCommon.InputKeyValueStruct = InputKeyValueStruct

---@class ActorInstanceInventoryItemInfo
local ActorInstanceInventoryItemInfo = {
    Index = 1,
    Count = 1,
    Path = ""
}
UiCommon.ActorInstanceInventoryItemInfo = ActorInstanceInventoryItemInfo

---@enum DirEnum
local DirEnum = {
    Up = 1,
    UpRight = 2,
    Right = 3,
    RightDown = 4,
    Down = 5,
    DownLeft = 6,
    Left = 7,
    LeftUp = 8,
    Center = 9,
}
UiCommon.DirEnum = DirEnum

---@enum WindowSizeEnum
local WindowSizeEnum = {
    Small = 1,
    Medium = 2,
    Large = 3
}
UiCommon.WindowSizeEnum = WindowSizeEnum

local MapOfWindowSizeEnumToPercentage = {}
MapOfWindowSizeEnumToPercentage[WindowSizeEnum.Small] = 0.5
MapOfWindowSizeEnumToPercentage[WindowSizeEnum.Medium] = 0.7
MapOfWindowSizeEnumToPercentage[WindowSizeEnum.Large] = 0.85
UiCommon.MapOfWindowSizeEnumToPercentage = MapOfWindowSizeEnumToPercentage

----- 开始界面相关参数

UiCommon.UserActorCfgDirPath = "config/UserActors"
UiCommon.UserActorPageColCount = 7
UiCommon.UserActorPageRowCount = 2
UiCommon.UserActorPageTotalCount = UiCommon.UserActorPageColCount * UiCommon.UserActorPageRowCount

---@class UserActorDataStruct
---@field OriCfgSimplePath string
---@field Content table
local UserActorDataStruct = {
    OriCfgSimplePath = "",
    Content = {}
}

function UiCommon.NewUserActorData()
    ---@type UserActorDataStruct
    local o = _TABLE.DeepClone(UserActorDataStruct)
    return o
end

---@class UserActorInfoStruct
---@field Id int
---@field Data Actor.RESMGR.InstanceData
---@field Entity Actor.Entity
---@field OriCfgSimplePath string
local UserActorInfoStruct = {
    Id = 0,
    Data = {},
    Entity = nil,
    OriCfgSimplePath = ""
}

---@return UserActorInfoStruct
function UiCommon.NewUserActorInfo()
    local o = _TABLE.DeepClone(UserActorInfoStruct)
    return o
end

UiCommon.JobActorPageColCount = 3
UiCommon.JobActorPageRowCount = 3
UiCommon.JobActorPageTotalCount = UiCommon.JobActorPageColCount * UiCommon.JobActorPageRowCount

----- Npc
---@class NpcInfo
local NpcInfo = {
    Name = "",
    Intro = "",
    ---@type Actor.Entity
    Entity = nil
}

function UiCommon.NewNpcInfo()
    ---@type NpcInfo
    local o = _TABLE.DeepClone(NpcInfo)
    return o
end

UiCommon.MobaSkillCdScale = 3

return UiCommon
