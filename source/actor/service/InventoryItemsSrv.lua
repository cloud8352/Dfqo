--[[
	desc: InventoryItemsSrv, a service for InventoryItems.
	author: keke
]]--

local Common = require("UI.ui_common")

local DrawableSprite = require("actor.drawable.sprite")
local ResMgr = require("actor.resmgr")
local Factory = require("actor.factory")

local ResLib = require("lib.resource")
local SoundLib = require("lib.sound")

-- 物品掉落音效
local ItemDroppedSoundData = ResLib.GetSoundData("ui/InventoryItemDropped")

---@class Actor.Service.InventoryItemsSrv
local InventoryItemsSrv = {}

---@param entity Actor.Entity
local function updateEntityAspect(entity)
    local inventoryItems = entity.InventoryItems
    local articleInfo = inventoryItems:GetFirstNotEmptyItem()
    if entity.identity.Job == Common.JobEnum.InventoryItem then
        local aspect = entity.aspect
        local configData = {}
        configData.spriteData = ResMgr.GetSpriteData(articleInfo.iconPath)
        ---@type Actor.Drawable.Sprite | Graphics.Drawable.Sprite
        local sprite = aspect.layer:Add("body", _, DrawableSprite.NewWithConfig, configData)

        -- 设置尺寸
        local spriteWidth, spriteHeight = sprite:GetImageDimensions()
        local spriteXScale = 20 / spriteWidth
        local spriteYScale = 20 / spriteHeight
        sprite:SetAttri("scale", spriteXScale, spriteYScale)
    end
end

---@param entity Actor.Entity
-----@param entity Actor.Component.InventoryItems
---@param index int
---@param count int
---@param inventoryItemConfigPath string
function InventoryItemsSrv.InsertItemToEntity(entity, index, count, inventoryItemConfigPath)
    local inventoryItems = entity.InventoryItems
    if inventoryItems == nil then
        return
    end

    inventoryItems:InsertItem(index, count, inventoryItemConfigPath)
    updateEntityAspect(entity)
end

---@param entity Actor.Entity
---@param count int
---@param inventoryItemConfigPath string
function InventoryItemsSrv.AddItemToEntity(entity, count, inventoryItemConfigPath)
    local inventoryItems = entity.InventoryItems
    if inventoryItems == nil then
        return
    end
    inventoryItems:AddItem(count, inventoryItemConfigPath)
    updateEntityAspect(entity)
end

---@param x int
---@param y int
---@param z int
---@param inventoryItemConfigPath string
function InventoryItemsSrv.CreateEntity(x, y, z, inventoryItemConfigPath)
    local params = {
        x = x,
        y = y,
        z = z,
        direction = 1,
        camp = 1,
        dulist = {
            isEnemy = false
        }
    }
    local entity = Factory.New("article/InventoryItem", params)
    InventoryItemsSrv.AddItemToEntity(entity, 1, 
        inventoryItemConfigPath)
end

--- 从实例中掉落物品
---@param entity Actor.Entity
function InventoryItemsSrv.DropItemFromEntity(entity)
    local transform = entity.transform
    if transform == nil then
        return
    end
    local x = transform.position.x - 10
    local y = transform.position.y - 10
    local z = 0

    local inventoryItems = entity.InventoryItems
    if inventoryItems == nil then
        return
    end
    if inventoryItems:GetNotEmptyItemCount() < 1 then
        return
    end
    local articleInfo = inventoryItems:RandomGetNotEmptyItem()
    if articleInfo.type == Common.ArticleType.Empty then
        return
    end
    InventoryItemsSrv.CreateEntity(x, y, z, articleInfo.path)

    -- 播放物品掉落音效
    SoundLib.Play(ItemDroppedSoundData)
end

return InventoryItemsSrv
