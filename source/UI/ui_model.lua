--[[
	desc: UiModel class, ui数据处理类
	author: keke <243768648@qq.com>
	since: 2023-7-19
	alter: 2023-7-19
]]
--

local Common = require("UI.ui_common")

local _TABLE = require("lib.table")
local _RESOURCE = require("lib.resource")

-- service
local SkillSrv = require("actor.service.skill")
local _CONFIG = require("config")
local _MAP = require("map.init")
local ResMgr = require("actor.resmgr")
local EquSrv = require("actor.service.equipment")
local AspectSrv = require("actor.service.aspect")
local InputSrv = require("actor.service.input")

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

    -- 被攻击的敌人
    ---@type Actor.Entity
    self.hitEnemyOfPlayer = nil

    -- post init
    for i = 1, Common.ArticleTableColCount * Common.ArticleTableRowCount do
        local articleInfo = Common.NewArticleInfo()
        self.articleInfoList[i] = articleInfo
    end

    -- equ
    for i = 1, Common.EquTableColCount * Common.EquTableRowCount do
        local articleInfo = Common.NewArticleInfo()
        self.mountedEquInfoList[i] = articleInfo
    end

    -- sound of changing article position
    self.changedArticlePosSoundSource = _RESOURCE.NewSource("asset/sound/ui/changed_article_pos.ogg")

    -- send signals
    local _DUELIST = require("actor.service.duelist")
    _DUELIST.AddListener("clear", _, function ()
        self:Signal_EnemyCleared()
    end)
    _DUELIST.AddListener("appeared", _, function ()
        self:Signal_EnemyAppeared()
    end)
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
    elseif clickedItemInfo.type == Common.ArticleType.Equipment then
        self:mountEquipment(index, clickedItemInfo)
    end
end

---@param index number
function UiModel:OnRightKeyClickedEquTableItem(index)
    local clickedItemInfo = self.mountedEquInfoList[index]
    if clickedItemInfo == nil then
        print("UiModel:OnRightKeyClickedEquTableItem(index)", "err: can not find itemInfo")
        return
    end

    if clickedItemInfo.type == Common.ArticleType.Equipment then
        self:unloadEquipment(index, clickedItemInfo)
    else
        print("UiModel:OnRightKeyClickedEquTableItem(index)", "err: item info type is not Equipment")
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
function UiModel:RequestSetArticleTableItemInfo(index, itemInfo)
    print("UiModel:RequestSetArticleTableItemInfo(index, itemInfo)", index, itemInfo.name)
    local receiverList = self.mapOfSignalToReceiverList[self.RequestSetArticleTableItemInfo]
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.OnRequestSetArticleTableItemInfo
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
    local receiverList = self.mapOfSignalToReceiverList[self.RequestSetArticleTableItemInfo]
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
        self:RequestSetArticleTableItemInfo(self.articleTableHoveringItemIndex, draggingArticleInfo)

        -- 移动原先悬停处的物品到拖拽之前的位置
        self.articleInfoList[self.articleTableDraggingItemIndex] = hoveringArticleInfo
        self:RequestSetArticleTableItemInfo(self.articleTableDraggingItemIndex, hoveringArticleInfo)

        -- 播放物品移动音效
        self:playChangedArticlePosSound()
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
    self:RequestSetArticleTableItemInfo(index, itemInfo)
end

--- 装载装备
---@param articleTableIndex number
---@param itemInfo ArticleInfo
function UiModel:mountEquipment(articleTableIndex, itemInfo)
    print("UiModel:mountEquipment(index, itemInfo)", articleTableIndex, itemInfo.name)

    local lastEquItemInfo = self.mountedEquInfoList[itemInfo.equInfo.type]
    -- 在ui上卸载原有装备到物品栏
    self.articleInfoList[articleTableIndex] = lastEquItemInfo
    self:RequestSetArticleTableItemInfo(articleTableIndex, lastEquItemInfo)
    -- 在服务上装载新装备
    local keyTag = Common.MapOfEquTypeToTag[itemInfo.equInfo.type]
    EquSrv.Equip(self.player, keyTag, itemInfo.equInfo.resMgrEquData)
    -- 在服务上调整实体装扮
    AspectSrv.AdjustAvatar(self.player.aspect, self.player.states)

    -- 在ui上装载新装备
    self.mountedEquInfoList[itemInfo.equInfo.type] = itemInfo
    self:RequestSetEquTableItemInfo(itemInfo.equInfo.type, itemInfo)

    -- 播放物品移动音效
    self:playChangedArticlePosSound()
end

--- 卸载装备
---@param equTableIndex number
---@param itemInfo ArticleInfo
function UiModel:unloadEquipment(equTableIndex, itemInfo)
    print("UiModel:unloadEquipment(index, itemInfo)", equTableIndex, itemInfo.name)
    -- 在ui上找到物品栏中第一个空位置
    local emptyItemIndex = -1
    ---@type ArticleInfo
    local emptyItemInfo = nil
    for i, info in pairs(self.articleInfoList) do
        if info.type == Common.ArticleType.Empty then
            emptyItemIndex = i
            emptyItemInfo = info
            break
        end
    end
    if emptyItemInfo == nil then
        print("UiModel:unloadEquipment(index, itemInfo)", "article table has no empty space")
        return
    end

    -- 在ui上卸载到物品栏的空位置
    self.articleInfoList[emptyItemIndex] = itemInfo
    self:RequestSetArticleTableItemInfo(emptyItemIndex, itemInfo)

    -- 在ui上将装备栏对应位置设置为空
    self.mountedEquInfoList[equTableIndex] = emptyItemInfo
    self:RequestSetEquTableItemInfo(equTableIndex, emptyItemInfo)

    -- 在服务上卸载装备
    local keyTag = Common.MapOfEquTypeToTag[itemInfo.equInfo.type]
    EquSrv.Del(self.player, keyTag)
    -- 在服务上调整实体装扮
    AspectSrv.AdjustAvatar(self.player.aspect, self.player.states)

    -- 播放物品移动音效
    self:playChangedArticlePosSound()
end

--- 请求界面设置拖拽项为可见性
---@param visible boolean
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

function UiModel:Signal_EnemyCleared()
    local receiverList = self.mapOfSignalToReceiverList[self.Signal_EnemyCleared]
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.Slot_EnemyCleared
        if func == nil then
            goto continue
        end

        func(receiver, self)

        ::continue::
    end
end

function UiModel:Signal_EnemyAppeared()
    local receiverList = self.mapOfSignalToReceiverList[self.Signal_EnemyAppeared]
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.Slot_EnemyAppeared
        if func == nil then
            goto continue
        end

        func(receiver, self)

        ::continue::
    end
end

---@param attack Actor.Gear.Attack | Core.Gear
---@param hitEntity Actor.Entity
function UiModel:Slot_onRecvSignalOfPlayerHitEnemy(attack, hitEntity)
    if not hitEntity then
        return
    end
    if not hitEntity.identity then
        return
    end
    if hitEntity.attributes.hp <= 0 then
        return
    end

    self.hitEnemyOfPlayer = hitEntity
    self:Signal_PlayerHitEnemy(attack, hitEntity)
end

---@param attack Actor.Gear.Attack | Core.Gear
---@param hitEntity Actor.Entity
function UiModel:Signal_PlayerHitEnemy(attack, hitEntity)
    local receiverList = self.mapOfSignalToReceiverList[self.Signal_PlayerHitEnemy]
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.Slot_PlayerHitEnemy
        if func == nil then
            goto continue
        end

        func(receiver, self, attack, hitEntity)

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
    articleInfo.id = 1
    articleInfo.type = Common.ArticleType.Consumable
    articleInfo.name = "消耗1"
    articleInfo.desc = "desc 消耗1"
    articleInfo.iconPath = "ui/CharacterPortraits/Swordsman/Normal"
    articleInfo.count = 10
    articleInfo.consumableInfo.hpRecovery = 100
    articleInfo.consumableInfo.hpRecoveryRate = 0.1
    articleInfo.consumableInfo.mpRecovery = 150
    articleInfo.consumableInfo.mpRecoveryRate = 0.1


    -- 创建裤子装备资源
    local resMgrEquData = ResMgr.NewEquipmentData("clothes/swordman/pants/renewal",
        {}, {}, nil)

    articleInfo = self.articleInfoList[2]
    articleInfo.equInfo.resMgrEquData = resMgrEquData
    articleInfo.id = 2
    articleInfo.type = Common.ArticleType.Equipment
    articleInfo.name = resMgrEquData.name
    articleInfo.desc = resMgrEquData.comment or ""
    articleInfo.iconPath = "icon/equipment/" .. resMgrEquData.icon
    articleInfo.equInfo.type = Common.EquType.Pants
    articleInfo.equInfo.resMgrEquData = resMgrEquData
    -- articleInfo.equInfo.hpExtent = 100

    articleInfo = self.articleInfoList[3]
    articleInfo.id = 3
    articleInfo.type = Common.ArticleType.Consumable
    articleInfo.name = "消耗3"
    articleInfo.desc = "desc 消耗3"
    articleInfo.iconPath = "ui/DropDownBtn/Disabled"
    articleInfo.count = 15
    articleInfo.consumableInfo.hpRecovery = 50

    resMgrEquData = ResMgr.NewEquipmentData("weapon/swordman/lswd9600",
        {}, {}, nil)
    articleInfo = self.articleInfoList[4]
    articleInfo.equInfo.resMgrEquData = resMgrEquData
    articleInfo.id = 4
    articleInfo.type = Common.ArticleType.Equipment
    articleInfo.name = resMgrEquData.name
    articleInfo.desc = resMgrEquData.comment or ""
    articleInfo.iconPath = "icon/equipment/" .. resMgrEquData.icon
    articleInfo.equInfo.type = Common.EquType.Weapon
    articleInfo.equInfo.resMgrEquData = resMgrEquData

    resMgrEquData = ResMgr.NewEquipmentData("weapon/swordman/lswd5700",
        {}, {}, nil)
    articleInfo = self.articleInfoList[5]
    articleInfo.equInfo.resMgrEquData = resMgrEquData
    articleInfo.id = 5
    articleInfo.type = Common.ArticleType.Equipment
    articleInfo.name = resMgrEquData.name
    articleInfo.desc = resMgrEquData.comment or ""
    articleInfo.iconPath = "icon/equipment/" .. resMgrEquData.icon
    articleInfo.equInfo.type = Common.EquType.Weapon
    articleInfo.equInfo.resMgrEquData = resMgrEquData

    resMgrEquData = ResMgr.NewEquipmentData("weapon/swordman/beamswd0200",
        {}, {}, nil)
    articleInfo = self.articleInfoList[6]
    articleInfo.equInfo.resMgrEquData = resMgrEquData
    articleInfo.id = 6
    articleInfo.type = Common.ArticleType.Equipment
    articleInfo.name = resMgrEquData.name
    articleInfo.desc = resMgrEquData.comment or ""
    articleInfo.iconPath = "icon/equipment/" .. resMgrEquData.icon
    articleInfo.equInfo.type = Common.EquType.Weapon
    articleInfo.equInfo.resMgrEquData = resMgrEquData

    resMgrEquData = ResMgr.NewEquipmentData("weapon/swordman/beamswd2800",
        {}, {}, nil)
    articleInfo = self.articleInfoList[7]
    articleInfo.equInfo.resMgrEquData = resMgrEquData
    articleInfo.id = 7
    articleInfo.type = Common.ArticleType.Equipment
    articleInfo.name = resMgrEquData.name
    articleInfo.desc = resMgrEquData.comment or ""
    articleInfo.iconPath = "icon/equipment/" .. resMgrEquData.icon
    articleInfo.equInfo.type = Common.EquType.Weapon
    articleInfo.equInfo.resMgrEquData = resMgrEquData

    resMgrEquData = ResMgr.NewEquipmentData("weapon/swordman/katana",
        {}, {}, nil)
    articleInfo = self.articleInfoList[8]
    articleInfo.equInfo.resMgrEquData = resMgrEquData
    articleInfo.id = 8
    articleInfo.type = Common.ArticleType.Equipment
    articleInfo.name = resMgrEquData.name
    articleInfo.desc = resMgrEquData.comment or ""
    articleInfo.iconPath = "icon/equipment/" .. resMgrEquData.icon
    articleInfo.equInfo.type = Common.EquType.Weapon
    articleInfo.equInfo.resMgrEquData = resMgrEquData

    -- equ
    local itemDataFromContainer = self.player.equipments.container:Get("belt")
    if itemDataFromContainer then
        resMgrEquData = itemDataFromContainer:GetData()
        articleInfo = self.mountedEquInfoList[Common.EquType.Belt]
        articleInfo.id = 5
        articleInfo.type = Common.ArticleType.Equipment
        articleInfo.name = resMgrEquData.name or ""
        articleInfo.desc = resMgrEquData.comment or ""
        articleInfo.iconPath = "icon/equipment/" .. resMgrEquData.icon
        articleInfo.equInfo.type = Common.EquType.Belt
        articleInfo.equInfo.resMgrEquData = resMgrEquData
    end

    itemDataFromContainer = self.player.equipments.container:Get("cap")
    if itemDataFromContainer then
        resMgrEquData = itemDataFromContainer:GetData()
        articleInfo = self.mountedEquInfoList[Common.EquType.Cap]
        articleInfo.id = 6
        articleInfo.type = Common.ArticleType.Equipment
        articleInfo.name = resMgrEquData.name
        articleInfo.desc = resMgrEquData.comment or ""
        articleInfo.iconPath = "icon/equipment/" .. resMgrEquData.icon
        articleInfo.equInfo.type = Common.EquType.Cap
        articleInfo.equInfo.resMgrEquData = resMgrEquData
    end

    itemDataFromContainer = self.player.equipments.container:Get("coat")
    if itemDataFromContainer then
        resMgrEquData = itemDataFromContainer:GetData()
        articleInfo = self.mountedEquInfoList[Common.EquType.Coat]
        articleInfo.id = 7
        articleInfo.type = Common.ArticleType.Equipment
        articleInfo.name = resMgrEquData.name
        articleInfo.desc = resMgrEquData.comment or ""
        articleInfo.iconPath = "icon/equipment/" .. resMgrEquData.icon
        articleInfo.equInfo.type = Common.EquType.Coat
        articleInfo.equInfo.resMgrEquData = resMgrEquData
    end


    itemDataFromContainer = self.player.equipments.container:Get("face")
    if itemDataFromContainer then
        resMgrEquData = itemDataFromContainer:GetData()
        articleInfo = self.mountedEquInfoList[Common.EquType.Face]
        articleInfo.id = 7
        articleInfo.type = Common.ArticleType.Equipment
        articleInfo.name = resMgrEquData.name
        articleInfo.desc = resMgrEquData.comment or ""
        articleInfo.iconPath = "icon/equipment/" .. resMgrEquData.icon
        articleInfo.equInfo.type = Common.EquType.Face
        articleInfo.equInfo.resMgrEquData = resMgrEquData
    end


    itemDataFromContainer = self.player.equipments.container:Get("hair")
    if itemDataFromContainer then
        resMgrEquData = itemDataFromContainer:GetData()
        articleInfo = self.mountedEquInfoList[Common.EquType.Hair]
        articleInfo.id = 8
        articleInfo.type = Common.ArticleType.Equipment
        articleInfo.name = resMgrEquData.name
        articleInfo.desc = resMgrEquData.comment or ""
        articleInfo.iconPath = "icon/equipment/" .. resMgrEquData.icon
        articleInfo.equInfo.type = Common.EquType.Hair
        articleInfo.equInfo.resMgrEquData = resMgrEquData
    end

    itemDataFromContainer = self.player.equipments.container:Get("neck")
    if itemDataFromContainer then
        resMgrEquData = itemDataFromContainer:GetData()
        articleInfo = self.mountedEquInfoList[Common.EquType.Neck]
        articleInfo.id = 9
        articleInfo.type = Common.ArticleType.Equipment
        articleInfo.name = resMgrEquData.name
        articleInfo.desc = resMgrEquData.comment or ""
        articleInfo.iconPath = "icon/equipment/" .. resMgrEquData.icon
        articleInfo.equInfo.type = Common.EquType.Neck
        articleInfo.equInfo.resMgrEquData = resMgrEquData
    end

    itemDataFromContainer = self.player.equipments.container:Get("pants")
    if itemDataFromContainer then
        resMgrEquData = itemDataFromContainer:GetData()
        articleInfo = self.mountedEquInfoList[Common.EquType.Pants]
        articleInfo.id = 10
        articleInfo.type = Common.ArticleType.Equipment
        articleInfo.name = resMgrEquData.name
        articleInfo.desc = resMgrEquData.comment or ""
        articleInfo.iconPath = "icon/equipment/" .. resMgrEquData.icon
        articleInfo.equInfo.type = Common.EquType.Pants
        articleInfo.equInfo.resMgrEquData = resMgrEquData
    end

    itemDataFromContainer = self.player.equipments.container:Get("shoes")
    if itemDataFromContainer then
        resMgrEquData = itemDataFromContainer:GetData()
        articleInfo = self.mountedEquInfoList[Common.EquType.Shoes]
        articleInfo.id = 11
        articleInfo.type = Common.ArticleType.Equipment
        articleInfo.name = resMgrEquData.name
        articleInfo.desc = resMgrEquData.comment or ""
        articleInfo.iconPath = "icon/equipment/" .. resMgrEquData.icon
        articleInfo.equInfo.type = Common.EquType.Shoes
        articleInfo.equInfo.resMgrEquData = resMgrEquData
    end

    itemDataFromContainer = self.player.equipments.container:Get("weapon")
    if itemDataFromContainer then
        resMgrEquData = itemDataFromContainer:GetData()
        articleInfo = self.mountedEquInfoList[Common.EquType.Weapon]
        articleInfo.id = 12
        articleInfo.type = Common.ArticleType.Equipment
        articleInfo.name = resMgrEquData.name
        articleInfo.desc = resMgrEquData.comment or ""
        articleInfo.iconPath = "icon/equipment/" .. resMgrEquData.icon
        articleInfo.equInfo.type = Common.EquType.Weapon
        articleInfo.equInfo.resMgrEquData = resMgrEquData
        -- articleInfo.equInfo.hpExtent = 100
        -- articleInfo.equInfo.hpExtentRate = 0.1
        -- articleInfo.equInfo.mpExtent = 100
        -- articleInfo.equInfo.mpExtentRate = 0.1
    end

    -- connection
    self.player.attacker.hitCaller:AddListener(self, self.Slot_onRecvSignalOfPlayerHitEnemy)

    -- post init
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

---@param type ActorAttributeType
function UiModel:GetActorAttribute(type)
    if self.player == nil then
        print("UiModel:GetActorAttribute(type)", "player is nil")
        return 0
    end

    if type == Common.ActorAttributeType.Hp then
        return self.player.attributes.hp
    elseif type == Common.ActorAttributeType.MaxHp then
        return self.player.attributes.maxHp
    elseif type == Common.ActorAttributeType.HpRecovery then
        return self.player.attributes.hpRecovery
    elseif type == Common.ActorAttributeType.Mp then
        return self.player.attributes.mp
    elseif type == Common.ActorAttributeType.MaxMp then
        return self.player.attributes.maxMp
    elseif type == Common.ActorAttributeType.PhyAtk then
        return self.player.attributes.phyAtk
    elseif type == Common.ActorAttributeType.MagAtk then
        return self.player.attributes.magAtk
    elseif type == Common.ActorAttributeType.PhyDef then
        return self.player.attributes.phyDef
    elseif type == Common.ActorAttributeType.MagDef then
        return self.player.attributes.magDef
    elseif type == Common.ActorAttributeType.MoveSpeed then
        return self.player.attributes.moveRate
    elseif type == Common.ActorAttributeType.AttackSpeed then
        return self.player.attributes.attackRate
    elseif type == Common.ActorAttributeType.PhyAtkRate then
        return self.player.attributes.phyAtkRate
    elseif type == Common.ActorAttributeType.MagAtkRate then
        return self.player.attributes.magAtkRate
    end
end

---@param key string
function UiModel:PressPlayerKey(key)
    if (not self.player) then
        return
    end

    InputSrv.Press(self.player.input, key)
end

---@param key string
function UiModel:ReleasePlayerKey(key)
    if (not self.player) then
        return
    end
    InputSrv.Release(self.player.input, key)
end

function UiModel:GetBossRoomDirection()
    return _MAP.GetBossRoomDirection()
end

function UiModel:GetHitEnemyName()
    if not self.hitEnemyOfPlayer then
        return ""
    end
    return self.hitEnemyOfPlayer.identity.name or ""
end

function UiModel:GetHitEnemyHp()
    if not self.hitEnemyOfPlayer then
        return 0
    end
    return self.hitEnemyOfPlayer.attributes.hp or 0
end

function UiModel:GetHitEnemyMaxHp()
    if not self.hitEnemyOfPlayer then
        return 0
    end
    return self.hitEnemyOfPlayer.attributes.maxHp or 0
end

function UiModel:playChangedArticlePosSound()
    -- 播放物品移动音效
    self.changedArticlePosSoundSource:stop()
    self.changedArticlePosSoundSource:setVolume(_CONFIG.setting.sound)
    self.changedArticlePosSoundSource:play()
end

return UiModel
