--[[
	desc: InventoryItems, a component.
	author: keke
]]--

local UiCommon = require("UI.ui_common")

local ResMgr = require("actor.resmgr")
local Collider = require("actor.collider")

local ResLib = require("lib.resource")

local _Caller = require("core.caller")
local _Container = require("core.container")

---@class Actor.Component.InventoryItems
---@field public container Core.Container
---@field public Collider Actor.Collider
local InventoryItems = require("core.class")()

function InventoryItems.HandleData(data)
end

function InventoryItems:Ctor(data)
    self.container = _Container.New()
    self.itemInsertedCaller = _Caller.New()
    self.data = data
    
    local colliderData = {
        {
            x = 0,
            y1 = 0,
            z = 0,
            y2 = 20,
            w = 20,
            h = 5
        }
    }
    self.Collider = Collider.New(colliderData)

    ---@type table<int, ArticleInfo>
    self.list = {}
    self.notEmptyItemCount = 0
    -- 设置物品数据
    local inventoryItems = data.List or {}
    for i, item in pairs(inventoryItems) do
        self:InsertItem(item.Index, item.Count, item.Path)
    end
end

function InventoryItems:GetList()
    return self.list
end

---@param obj table
---@param func function
function InventoryItems:AddListenerToItemInsertedCaller(obj, func)
    self.itemInsertedCaller:AddListener(obj, func)
end

---@param obj table
---@param func function
function InventoryItems:DelListenerToItemInsertedCaller(obj, func)
    self.itemInsertedCaller:DelListener(obj, func)
end

---@param index int
---@param count int
---@param inventoryItemConfigPath string
function InventoryItems:InsertItem(index, count, inventoryItemConfigPath)
    local articleInfo = UiCommon.NewArticleInfo()
    articleInfo.Index = index
    articleInfo.count = count
    if inventoryItemConfigPath == nil or inventoryItemConfigPath == "" then
        self.list[index] = articleInfo
        self.itemInsertedCaller:Call(articleInfo)
        return
    end

    local inventoryItemData = ResMgr.GetItemData(inventoryItemConfigPath)
    articleInfo.path = inventoryItemConfigPath
    local typeStr = inventoryItemData.type
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
    elseif typeStr == "Attribute" then
        articleInfo.type = UiCommon.ArticleType.Consumable
        ---@type Actor.RESMGR.AttributeData
        local resMgrConsumableData = inventoryItemData
        articleInfo.iconPath = "icon/Attribute/" .. resMgrConsumableData.icon
        articleInfo.consumableInfo.hpRecovery = resMgrConsumableData.HpRecovery
        articleInfo.consumableInfo.hpRecoveryRate = resMgrConsumableData.HpRecoveryRate
        articleInfo.consumableInfo.mpRecovery = resMgrConsumableData.MpRecovery
        articleInfo.consumableInfo.mpRecoveryRate = resMgrConsumableData.MpRecoveryRate
    elseif typeStr == "skill" then
        --
    elseif typeStr == "buff" then
        --
    end
    articleInfo.name = inventoryItemData.name
    articleInfo.desc = inventoryItemData.special or ""
    articleInfo.UsableJobs = inventoryItemData.UsableJobs
    articleInfo.UsableGenders = inventoryItemData.UsableGenders

    -- 加入到列表中
    self.list[index] = articleInfo
    -- 计算非空物品总数
    self:computeNotEmptyItemCount()
    self.itemInsertedCaller:Call(articleInfo)
end

---@param count int
---@param inventoryItemConfigPath string
function InventoryItems:AddItem(count, inventoryItemConfigPath)
    -- 如果存在同一非装备物品，则合并数量
    ---@type ArticleInfo
    local sameArticleInfo = nil
    for i, info in pairs(self.list) do
        if info.type ~= UiCommon.ArticleType.Equipment and
            info.path == inventoryItemConfigPath
        then
            sameArticleInfo = info
            break
        end
    end
    if sameArticleInfo then
        self:InsertItem(sameArticleInfo.Index, sameArticleInfo.count + count, 
            inventoryItemConfigPath)
        return
    end

    -- 如果不存在同一非装备物品，则添加
    local minimumUsableIndex = self:getMinimumUsableIndex()
    self:InsertItem(minimumUsableIndex, count, 
        inventoryItemConfigPath)
end

function InventoryItems:GetNotEmptyItemCount()
    return self.notEmptyItemCount
end

---@param n int
---@return ArticleInfo
function InventoryItems:GetNotEmptyItem(n)
    local foundCount = 0
    for _, info in pairs(self.list) do
        if info ~= nil and info.type ~= UiCommon.ArticleType.Empty then
            foundCount = foundCount + 1
        end

        if foundCount == n then
            return info
        end
    end

    return UiCommon.NewArticleInfo()
end

---@param n int
---@return ArticleInfo
function InventoryItems:GetFirstNotEmptyItem()
    return self:GetNotEmptyItem(1)
end

---@return ArticleInfo
function InventoryItems:RandomGetNotEmptyItem()
    local n = math.random(1, self.notEmptyItemCount)

    return self:GetNotEmptyItem(n)
end

---@return int
function InventoryItems:getMinimumUsableIndex()
    local minimumUsableIndex = 1
    while (minimumUsableIndex < 99) do
        local articleInfo = self.list[minimumUsableIndex]
        if articleInfo == nil or articleInfo.type == UiCommon.ArticleType.Empty then
            break
        end

        minimumUsableIndex = minimumUsableIndex + 1
    end

    return minimumUsableIndex
end

function InventoryItems:computeNotEmptyItemCount()
    self.notEmptyItemCount = 0
    for _, info in pairs(self.list) do
        if info ~= nil and info.type ~= UiCommon.ArticleType.Empty then
            self.notEmptyItemCount = self.notEmptyItemCount + 1
        end
    end
end

return InventoryItems
