--[[
	desc: InventoryItems, a component.
	author: keke
]]--

local UiCommon = require("UI.ui_common")

local ResMgr = require("actor.resmgr")
local _SKILL = require("actor.service.skill")

local ResLib = require("lib.resource")

local _Caller = require("core.caller")
local _Container = require("core.container")

---@class Actor.Component.InventoryItems
---@field public container Core.Container
---@field public caller Core.Caller
local InventoryItems = require("core.class")()

function InventoryItems.HandleData(data)
    for k, v in pairs(data) do
        if (k ~= "class" and type(v) ~= "boolean") then
            -- data[k] = _RESMGR.GetSkillData(v)
        end
    end
end

function InventoryItems:Ctor(data)
    self.container = _Container.New()
    self.caller = _Caller.New()
    self.data = data

    ---@type table<int, ArticleInfo>
    self.list = {}
    -- 设置物品数据
    local inventoryItems = data.List
    for i, item in pairs(inventoryItems) do
        local articleInfo = UiCommon.NewArticleInfo()
        articleInfo.Index = item.Index
        articleInfo.count = item.Count

        local inventoryItemData = ResLib.ReadConfig(item.Path, "config/actor/InventoryItem/%s.cfg")
        articleInfo.type = inventoryItemData.Type
        articleInfo.name = inventoryItemData.Name
        articleInfo.desc = inventoryItemData.Desc
        articleInfo.iconPath = inventoryItemData.IconPath
        articleInfo.UsableJob = inventoryItemData.UsableJob
        if articleInfo.type == UiCommon.ArticleType.Consumable and
            inventoryItemData.ConsumableInfo then
            local consumableInfoData = inventoryItemData.ConsumableInfo
            articleInfo.consumableInfo.hpRecovery = consumableInfoData.HpRecovery
            articleInfo.consumableInfo.hpRecoveryRate = consumableInfoData.HpRecoveryRate
            articleInfo.consumableInfo.mpRecovery = consumableInfoData.MpRecovery
            articleInfo.consumableInfo.mpRecoveryRate = consumableInfoData.MpRecoveryRate
        elseif inventoryItemData.ResMgrEquDataPath and 
            type(inventoryItemData.ResMgrEquDataPath) == "string"
        then
            local resMgrEquData = ResMgr.NewEquipmentData(inventoryItemData.ResMgrEquDataPath)
            articleInfo.equInfo.resMgrEquData = resMgrEquData
            articleInfo.type = UiCommon.ArticleType.Equipment
            articleInfo.name = resMgrEquData.name
            articleInfo.desc = resMgrEquData.comment or ""
            articleInfo.iconPath = "icon/equipment/" .. resMgrEquData.icon

            local equType = 0
            if resMgrEquData.kind == "clothes" then
                equType = UiCommon.MapOfTagToEquType[resMgrEquData.subKind]
            else 
                equType = UiCommon.MapOfTagToEquType[resMgrEquData.kind]
            end
            articleInfo.equInfo.type = equType
        end

        table.insert(self.list, articleInfo)
    end
end

function InventoryItems:GetList()
    return self.list
end

return InventoryItems
