--[[
	desc: UiModel class, ui数据处理类
	author: keke <243768648@qq.com>
	since: 2023-7-19
	alter: 2023-7-19
]] --

local Common = require("UI.ui_common")

local _TABLE = require("lib.table")

-- service
local SkillSrv = require("actor.service.skill")
local _CONFIG = require("config")
local _MAP = require("map.init")

---@class UiModel
local UiModel = require("core.class")()

function UiModel:Ctor()
    --- 信号到接收者的映射表
    ---@type table<function, table<number, Object>>
    self.mapOfSignalToReceiverList = {}

    ---@type Actor.Entity
    self.player = nil

    --- 携带的物品列表
    ---@type table<number, ArticleInfo>
    self.articleInfoList = {}

    --- 已装配的装备列表
    ---@type table<number, ArticleInfo>
    self.mountedEquInfoList = {}

    self.articleTableHoveringItemIndex = -1
    self.articleTableDraggingItemIndex = -1

    -- post init
    for i = 1, Common.ArticleTableColCount*Common.ArticleTableRowCount do
        local articleInfo = Common.NewArticleInfo()
        self.articleInfoList[i] = articleInfo
    end

    -- equ
    for i = 1, Common.EquTableColCount*Common.EquTableRowCount do
        local articleInfo = Common.NewArticleInfo()
        self.mountedEquInfoList[i] = articleInfo
    end
end

--- 获取携带的物品列表
---@return table<number, ArticleInfo>
function UiModel:GetArticleInfoList()
    return self.articleInfoList
end

--- 获取已装配的装备列表
---@return table<number, ArticleInfo>
function UiModel:GetMountedEquInfoList()
    return self.mountedEquInfoList
end

---@param index number
function UiModel:OnRightKeyClickedArticleTableItem(index)
    local clickedItemInfo = self.articleInfoList[index]
    if clickedItemInfo == nil then
        print("UiModel:OnRightKeyClickedArticleTableItem(index)", "err: can not find itemInfo")
        return
    end

    if clickedItemInfo.type == Common.ArticleType.Consumable then
        self:useConsumable(index, clickedItemInfo)
    elseif clickedItemInfo.type == Common.ArticleType.Equpment then
        self:mountEqupment(index, clickedItemInfo)
    end
end

---@param index number
function UiModel:OnRightKeyClickedEquTableItem(index)
    local clickedItemInfo = self.mountedEquInfoList[index]
    if clickedItemInfo == nil then
        print("UiModel:OnRightKeyClickedEquTableItem(index)", "err: can not find itemInfo")
        return
    end

    if clickedItemInfo.type == Common.ArticleType.Equpment then
        self:unmountEqupment(index, clickedItemInfo)
    else
        print("UiModel:OnRightKeyClickedEquTableItem(index)", "err: item info type is not equpment")
    end
end

--- 连接信号
---@param signal function
---@param obj Object
function UiModel:MocConnectSignal(signal, receiver)
    local receiverList = self.mapOfSignalToReceiverList[signal]
    if receiverList == nil then
        receiverList = {}
        self.mapOfSignalToReceiverList[signal] = receiverList
    end
    table.insert(receiverList, receiver)
end

--- 请求去设置物品栏某一显示项的信息
---@param index number
---@param itemInfo ArticleInfo
function UiModel:RequestSetAticleTableItemInfo(index, itemInfo)
    print("UiModel:RequestSetAticleTableItemInfo(index, itemInfo)", index, itemInfo.name)
    local receiverList = self.mapOfSignalToReceiverList[self.RequestSetAticleTableItemInfo]
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.OnRequestSetAticleTableItemInfo
        if func == nil then
            goto continue
        end

        func(receiver, self, index, itemInfo)

        ::continue::
    end
end

--- 请求去设置装备栏某一显示项的信息
---@param index number
---@param itemInfo ArticleInfo
function UiModel:RequestSetEquTableItemInfo(index, itemInfo)
    print("UiModel:RequestSetEquTableItemInfo(index, itemInfo)", index, itemInfo.name)
    local receiverList = self.mapOfSignalToReceiverList[self.RequestSetAticleTableItemInfo]
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.OnRequestSetEquTableItemInfo
        if func == nil then
            goto continue
        end

        func(receiver, self, index, itemInfo)
        
        ::continue::
    end
end

function UiModel:SetArticleTableHoveringItemIndex(index)
    self.articleTableHoveringItemIndex = index
end

--- 拖拽物品项
---@param index number 物品项检索
function UiModel:DragArticleItem(index)
    self.articleTableDraggingItemIndex = index
    self:RequestSetDraggingItemVisibility(true)
    local info = self.articleInfoList[index]
    self:RequestSetDraggingItemInfo(info)
end

--- 放下物品项
function UiModel:DropArticleItem()
    -- 拖拽项放到了何处
    if self.articleTableHoveringItemIndex ~= -1 then
        local hoveringArticleInfo = self.articleInfoList[self.articleTableHoveringItemIndex]

        -- 移动拖拽项到当前悬停处
        local draggingArticleInfo = self.articleInfoList[self.articleTableDraggingItemIndex]
        self.articleInfoList[self.articleTableHoveringItemIndex] = draggingArticleInfo
        self:RequestSetAticleTableItemInfo(self.articleTableHoveringItemIndex, draggingArticleInfo)

        -- 移动原先悬停处的物品到拖拽之前的位置
        self.articleInfoList[self.articleTableDraggingItemIndex] = hoveringArticleInfo
        self:RequestSetAticleTableItemInfo(self.articleTableDraggingItemIndex, hoveringArticleInfo)
    end

    -- 请求界面设置拖拽项为不可见
    self:RequestSetDraggingItemVisibility(false)
end

---
---@param xPos number
---@param yPos number
function UiModel:OnRequestMoveDraggingArticleItem(xPos, yPos)
    self:RequestMoveDraggingItem(xPos, yPos)
end

--- 使用物品
---@param index number
---@param itemInfo ArticleInfo
function UiModel:useConsumable(index, itemInfo)
    print("UiModel:useConsumable(index, itemInfo)", index, itemInfo.name)
    itemInfo.count = itemInfo.count - 1
    if itemInfo.count <= 0 then
        itemInfo.count = 0
        itemInfo.type = Common.ArticleType.Empty
    end
    self:RequestSetAticleTableItemInfo(index, itemInfo)
end

--- 装载装备
---@param articleTableIndex number
---@param itemInfo ArticleInfo
function UiModel:mountEqupment(articleTableIndex, itemInfo)
    print("UiModel:mountEqupment(index, itemInfo)", articleTableIndex, itemInfo.name)

    local lastEquItemInfo = self.mountedEquInfoList[itemInfo.equInfo.type]
    -- 卸载原有装备到物品栏
    self.articleInfoList[articleTableIndex] = lastEquItemInfo
    self:RequestSetAticleTableItemInfo(articleTableIndex, lastEquItemInfo)
    -- 装载新装备
    self.mountedEquInfoList[itemInfo.equInfo.type] = itemInfo
    self:RequestSetEquTableItemInfo(itemInfo.equInfo.type, itemInfo)
end

--- 卸载装备
---@param equTableIndex number
---@param itemInfo ArticleInfo
function UiModel:unmountEqupment(equTableIndex, itemInfo)
    print("UiModel:unmountEqupment(index, itemInfo)", equTableIndex, itemInfo.name)
    -- 找到物品栏中第一个空位置
    local emptyItemIndex = -1
    ---@type ArticleItemInfo
    local emptyItemInfo = nil
    for i, info in pairs(self.articleInfoList) do
        if info.type == Common.ArticleType.Empty then
            emptyItemIndex = i
            emptyItemInfo = info
            break
        end
    end
    if emptyItemInfo == nil then
        print("UiModel:unmountEqupment(index, itemInfo)", "article table has no empty space")
        return
    end

    -- 卸载到物品栏的空位置
    self.articleInfoList[emptyItemIndex] = itemInfo
    self:RequestSetAticleTableItemInfo(emptyItemIndex, itemInfo)
    -- 将装备栏对应位置设置为空
    self.mountedEquInfoList[equTableIndex] = emptyItemInfo
    self:RequestSetEquTableItemInfo(equTableIndex, emptyItemInfo)
end

--- 请求界面设置拖拽项为可见性
---@param info ArticleInfo
function UiModel:RequestSetDraggingItemVisibility(visible)
    print("UiModel:RequestSetDraggingItemVisibility(visible)", visible)
    local receiverList = self.mapOfSignalToReceiverList[self.RequestSetDraggingItemVisibility]
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.OnRequestSetDraggingItemVisibility
        if func == nil then
            goto continue
        end

        func(receiver, self, visible)
        
        ::continue::
    end
end

--- 请求界面设置拖拽项信息
---@param info ArticleInfo
function UiModel:RequestSetDraggingItemInfo(info)
    print("UiModel:RequestSetDraggingItemInfo(info)", info.name)
    local receiverList = self.mapOfSignalToReceiverList[self.RequestSetDraggingItemInfo]
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.OnRequestSetDraggingItemInfo
        if func == nil then
            goto continue
        end

        func(receiver, self, info)
        
        ::continue::
    end
end

--- 请求界面设置移动拖拽项
---@param xPos number
---@param yPos number
function UiModel:RequestMoveDraggingItem(xPos, yPos)
    -- print("UiModel:RequestMoveDraggingItem(xPos, yPos)", xPos, yPos)
    local receiverList = self.mapOfSignalToReceiverList[self.RequestMoveDraggingItem]
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.OnRequestMoveDraggingItem
        if func == nil then
            goto continue
        end

        func(receiver, self, xPos, yPos)
        
        ::continue::
    end
end

--- 请求界面去设置悬停处的物品栏提示窗口可见性
---@param visible boolean
function UiModel:RequestSetHoveringArticleItemTipWindowVisibility(visible)
    -- print("UiModel:RequestSetHoveringArticleItemTipWindowVisibility(visible)", visible)
    local receiverList = self.mapOfSignalToReceiverList[self.RequestSetHoveringArticleItemTipWindowVisibility]
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.OnRequestSetHoveringArticleItemTipWindowVisibility
        if func == nil then
            goto continue
        end

        func(receiver, self, visible)
        
        ::continue::
    end
end

--- 请求界面去设置悬停处的物品栏提示窗口物品信息
---@param xPos number
---@param yPos number
---@param info ArticleInfo
function UiModel:RequestSetHoveringArticleItemTipWindowPosAndInfo(xPos, yPos, info)
    -- print("UiModel:RequestSetHoveringArticleItemTipWindowPosAndInfo(xPos, yPos, info)", xPos, yPos, info.name)
    local receiverList = self.mapOfSignalToReceiverList[self.RequestSetHoveringArticleItemTipWindowPosAndInfo]
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.OnRequestSetHoveringArticleItemTipWindowPosAndInfo
        if func == nil then
            goto continue
        end

        func(receiver, self, xPos, yPos, info)
        
        ::continue::
    end
end

--- 请求界面去设置悬停处的技能项提示窗口可见性
---@param visible boolean
function UiModel:RequestSetHoveringSkillItemTipWindowVisibility(visible)
    -- print("UiModel:RequestSetHoveringSkillItemTipWindowVisibility(visible)", visible)
    local receiverList = self.mapOfSignalToReceiverList[self.RequestSetHoveringSkillItemTipWindowVisibility]
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.OnRequestSetHoveringSkillItemTipWindowVisibility
        if func == nil then
            goto continue
        end

        func(receiver, self, visible)
        
        ::continue::
    end
end

--- 请求界面去设置悬停处的技能项提示窗口物品信息
---@param xPos number
---@param yPos number
---@param info SkillInfo
function UiModel:RequestSetHoveringSkillItemTipWindowPosAndInfo(xPos, yPos, info)
    -- print("UiModel:RequestSetHoveringSkillItemTipWindowPosAndInfo(xPos, yPos, info)", xPos, yPos, info.name)
    local receiverList = self.mapOfSignalToReceiverList[self.RequestSetHoveringSkillItemTipWindowPosAndInfo]
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.OnRequestSetHoveringSkillItemTipWindowPosAndInfo
        if func == nil then
            goto continue
        end

        func(receiver, self, xPos, yPos, info)
        
        ::continue::
    end
end

--- 请求界面去设置悬停处的技能项提示窗口物品信息
---@param xPos number
---@param yPos number
---@param info SkillInfo
function UiModel:RequestSetHoveringSkillItemTipWindowPosAndInfo(xPos, yPos, info)
    -- print("UiModel:RequestSetHoveringSkillItemTipWindowPosAndInfo(xPos, yPos, info)", xPos, yPos, info.name)
    local receiverList = self.mapOfSignalToReceiverList[self.RequestSetHoveringSkillItemTipWindowPosAndInfo]
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.OnRequestSetHoveringSkillItemTipWindowPosAndInfo
        if func == nil then
            goto continue
        end

        func(receiver, self, xPos, yPos, info)
        
        ::continue::
    end
end

--- 请求界面去设置悬停处的技能项提示窗口物品信息
function UiModel:PlayerChanged()
    -- print("UiModel:PlayerChanged()")
    local receiverList = self.mapOfSignalToReceiverList[self.PlayerChanged]
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.OnPlayerChanged
        if func == nil then
            goto continue
        end

        func(receiver, self)
        
        ::continue::
    end
end

---@param player Actor.Entity
function UiModel:SetPlayer(player)
    if self.player == player then
        return
    end
    self.player = player

    -- 设置物品数据
    local articleInfo = self.articleInfoList[1]
    articleInfo.uuid = 1
    articleInfo.type = Common.ArticleType.Consumable
    articleInfo.name = "消耗1"
    articleInfo.desc = "desc 消耗1"
    articleInfo.iconPath = "ui/CharacterPortraits/Swordsman/Normal"
    articleInfo.count = 10
    articleInfo.consumableInfo.hpRecovery = 100
    articleInfo.consumableInfo.hpRecoveryRate = 0.1
    articleInfo.consumableInfo.mpRecovery = 150
    articleInfo.consumableInfo.mpRecoveryRate = 0.1

    local articleInfo = self.articleInfoList[2]
    articleInfo.uuid = 2
    articleInfo.type = Common.ArticleType.Equpment
    articleInfo.name = "装备2"
    articleInfo.desc = "desc 装备2"
    articleInfo.iconPath = "ui/DropDownBtn/Disabled"
    articleInfo.equInfo.type = Common.EquType.Belt
    articleInfo.equInfo.hpExtent = 100

    local articleInfo = self.articleInfoList[3]
    articleInfo.uuid = 3
    articleInfo.type = Common.ArticleType.Consumable
    articleInfo.name = "消耗3"
    articleInfo.desc = "desc 消耗3"
    articleInfo.iconPath = "ui/DropDownBtn/Disabled"
    articleInfo.count = 15
    articleInfo.consumableInfo.hpRecovery = 50

    -- equ
    local resItemData = nil
    local itemDataFromContainer = self.player.equipments.container:Get("belt")
    if itemDataFromContainer then
        ---@type Actor.RESMGR.ItemData
        resItemData = itemDataFromContainer:GetData()
        articleInfo = self.mountedEquInfoList[Common.EquType.Belt]
        articleInfo.uuid = 5
        articleInfo.type = Common.ArticleType.Equpment
        articleInfo.name = resItemData.name or ""
        articleInfo.desc = resItemData.comment or ""
        articleInfo.iconPath = "icon/equipment/" .. resItemData.icon
        articleInfo.equInfo.type = Common.EquType.Belt
    end

    itemDataFromContainer = self.player.equipments.container:Get("cap")
    if itemDataFromContainer then
        ---@type Actor.RESMGR.ItemData
        resItemData = itemDataFromContainer:GetData()
        articleInfo = self.mountedEquInfoList[Common.EquType.Cap]
        articleInfo.uuid = 6
        articleInfo.type = Common.ArticleType.Equpment
        articleInfo.name = resItemData.name
        articleInfo.desc = resItemData.comment or ""
        articleInfo.iconPath = "icon/equipment/" .. resItemData.icon
        articleInfo.equInfo.type = Common.EquType.Cap
    end

    itemDataFromContainer = self.player.equipments.container:Get("coat")
    if itemDataFromContainer then
        ---@type Actor.RESMGR.ItemData
        resItemData = itemDataFromContainer:GetData()
        articleInfo = self.mountedEquInfoList[Common.EquType.Coat]
        articleInfo.uuid = 7
        articleInfo.type = Common.ArticleType.Equpment
        articleInfo.name = resItemData.name
        articleInfo.desc = resItemData.comment or ""
        articleInfo.iconPath = "icon/equipment/" .. resItemData.icon
        articleInfo.equInfo.type = Common.EquType.Coat
    end


    itemDataFromContainer = self.player.equipments.container:Get("face")
    if itemDataFromContainer then
        ---@type Actor.RESMGR.ItemData
        resItemData = itemDataFromContainer:GetData()
        articleInfo = self.mountedEquInfoList[Common.EquType.Face]
        articleInfo.uuid = 7
        articleInfo.type = Common.ArticleType.Equpment
        articleInfo.name = resItemData.name
        articleInfo.desc = resItemData.comment or ""
        articleInfo.iconPath = "icon/equipment/" .. resItemData.icon
        articleInfo.equInfo.type = Common.EquType.Face
    end


    itemDataFromContainer = self.player.equipments.container:Get("hair")
    if itemDataFromContainer then
        ---@type Actor.RESMGR.ItemData
        resItemData = itemDataFromContainer:GetData()
        articleInfo = self.mountedEquInfoList[Common.EquType.Hair]
        articleInfo.uuid = 8
        articleInfo.type = Common.ArticleType.Equpment
        articleInfo.name = resItemData.name
        articleInfo.desc = resItemData.comment or ""
        articleInfo.iconPath = "icon/equipment/" .. resItemData.icon
        articleInfo.equInfo.type = Common.EquType.Hair
    end

    itemDataFromContainer = self.player.equipments.container:Get("neck")
    if itemDataFromContainer then
        ---@type Actor.RESMGR.ItemData
        resItemData = itemDataFromContainer:GetData()
        articleInfo = self.mountedEquInfoList[Common.EquType.Neck]
        articleInfo.uuid = 9
        articleInfo.type = Common.ArticleType.Equpment
        articleInfo.name = resItemData.name
        articleInfo.desc = resItemData.comment or ""
        articleInfo.iconPath = "icon/equipment/" .. resItemData.icon
        articleInfo.equInfo.type = Common.EquType.Neck
    end

    itemDataFromContainer = self.player.equipments.container:Get("pants")
    if itemDataFromContainer then
        ---@type Actor.RESMGR.ItemData
        resItemData = itemDataFromContainer:GetData()
        articleInfo = self.mountedEquInfoList[Common.EquType.Pants]
        articleInfo.uuid = 10
        articleInfo.type = Common.ArticleType.Equpment
        articleInfo.name = resItemData.name
        articleInfo.desc = resItemData.comment or ""
        articleInfo.iconPath = "icon/equipment/" .. resItemData.icon
        articleInfo.equInfo.type = Common.EquType.Pants
    end

    itemDataFromContainer = self.player.equipments.container:Get("shoes")
    if itemDataFromContainer then
        ---@type Actor.RESMGR.ItemData
        resItemData = itemDataFromContainer:GetData()
        articleInfo = self.mountedEquInfoList[Common.EquType.Shoes]
        articleInfo.uuid = 11
        articleInfo.type = Common.ArticleType.Equpment
        articleInfo.name = resItemData.name
        articleInfo.desc = resItemData.comment or ""
        articleInfo.iconPath = "icon/equipment/" .. resItemData.icon
        articleInfo.equInfo.type = Common.EquType.Shoes
    end

    itemDataFromContainer = self.player.equipments.container:Get("weapon")
    if itemDataFromContainer then
        ---@type Actor.RESMGR.ItemData
        resItemData = itemDataFromContainer:GetData()
        articleInfo = self.mountedEquInfoList[Common.EquType.Weapeon]
        articleInfo.uuid = 12
        articleInfo.type = Common.ArticleType.Equpment
        articleInfo.name = resItemData.name
        articleInfo.desc = resItemData.comment or ""
        articleInfo.iconPath = "icon/equipment/" .. resItemData.icon
        articleInfo.equInfo.type = Common.EquType.Weapeon
        -- articleInfo.equInfo.hpExtent = 100
        -- articleInfo.equInfo.hpExtentRate = 0.1
        -- articleInfo.equInfo.mpExtent = 100
        -- articleInfo.equInfo.mpExtentRate = 0.1
    end
    
    self:PlayerChanged()
end

---@return Actor.Skill
function UiModel:GetMapOfTagToSkillObj()
    if self.player == nil then
        print("UiModel:GetMapOfTagToSkillObj()", "player is nil")
        return {}
    end
    return SkillSrv.GetMap(self.player.skills)
end

---@param tag string
---@return string keyStr
function UiModel:GetSkillKeyByTag(tag)
    return _CONFIG.code[tag]
end

---@param mapID number
function UiModel:SelectGameMap(mapID)
    if 1 == mapID then 
        _MAP.Load(_MAP.Make("lorien"))
    elseif 2 == mapID then
        _MAP.Load(_MAP.Make("whitenight"))
    end
end

---@return integer maxHp
function UiModel:GetMaxHp()
    if self.player == nil then
        print("UiModel:GetMaxHp()", "player is nil")
        return -1
    end

    return self.player.attributes.maxHp
end

---@return integer hp
function UiModel:GetHp()
    if self.player == nil then
        print("UiModel:GetHp()", "player is nil")
        return -1
    end

    return self.player.attributes.hp
end

return UiModel
