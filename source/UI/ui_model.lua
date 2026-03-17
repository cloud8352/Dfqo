--[[
	desc: UiModel class, ui数据处理类
	author: keke <243768648@qq.com>
]]
--

local Common = require("UI.ui_common")

-- service
local SkillSrv = require("actor.service.skill")
local _CONFIG = require("config")
local _MAP = require("map.init")
local ResMgr = require("actor.resmgr")
local EcsMgr = require("actor.ecsmgr")
local EquSrv = require("actor.service.equipment")
local AspectSrv = require("actor.service.aspect")
local InputSrv = require("actor.service.input")
local InputLib = require("lib.input")
local AttributeSrv = require("actor.service.attribute")
local Factory = require("actor.factory")
local InventoryItemsSrv = require("actor.service.InventoryItemsSrv")
local MasteredSkillsSrv = require("actor.service.MasteredSkillsSrv")
local LifeSrv = require("actor.service.LifeSrv")
local StateSrv = require("actor.service.state")
local BuffSrv = require("actor.service.buff")
local NpcSrv = require("actor.service.NpcSrv")

local ResLib = require("lib.resource")
local SoundLib = require("lib.sound")
local MusicLib = require("lib.music")

local Table = require("lib.table")
local _RESOURCE = require("lib.resource")
local File = require("lib.file")
local String = require("lib.string")
local GraphicsLib = require("lib.graphics")
local KeyboardLib = require("lib.keyboard")
local SystemLib = require("lib.system")

---@class UiModel
local UiModel = require("core.class")()

local RebornEffectInstanceData = ResMgr.GetInstanceData("effect/death/normal")
local CounterattackEffectInstanceData = ResMgr.GetInstanceData("effect/battle/counterattack2")
local DotAreaBulletInstanceData = ResMgr.GetInstanceData("bullet/swordman/dotarea")

local PlayerCfgSavedFileSuffix = ".cfg"

-- SoundData
local NotFitAlertSoundData = ResLib.GetSoundData("ui/Alert1")
local SkillConsumableUsedSoundData = ResLib.GetSoundData("ui/AbilityUpItem")

local InvincibilityBuffData = ResMgr.NewBuffData("invincibility")

---@param director DIRECTOR
function UiModel:Ctor(director)
    --- 信号到接收者的映射表
    ---@type table<function, table<number, Object>>
    self.mapOfSignalToReceiverList = {}

    self.director = director

    ---@type Actor.Entity
    self.player = nil
    self.playerRebornCoinCount = 3
    self.partnerList = _CONFIG.user:GetPartnerList()

    --- 携带的物品列表
    ---@type table<number, ArticleInfo>
    self.articleInfoList = {}
    
    self.articleTableHoveringItemIndex = -1
    self.articleTableDraggingItemIndex = -1
    
    self.articleDockHoveringItemIndex = -1
    self.articleDockDraggingItemIndex = -1

    --- 已装配的装备列表
    ---@type table<number, ArticleInfo>
    self.mountedEquInfoList = {}

    -- 已掌握的技能信息列表
    ---@type table<int, SkillInfo>
    self.masteredSkillInfoList = {}

    -- 被攻击的敌人
    ---@type Actor.Entity
    self.hitEnemyOfPlayer = nil

    self.isInRougelikeMode = false
    self.isInMobaMode = false

    self.mapLoadProcess = _MAP.GetLoadProcess()
    self.lastMapLoadProcess = self.mapLoadProcess

    --- Npc
    self.interactingNpcInfo = Common.NewNpcInfo()

    -- connect signals
    _CONFIG.user.setPlayerCaller:AddListener(self, function(sender, lastPlayer, player) 
        self:Slot_PlayerChanged(player)
    end)

    local _DUELIST = require("actor.service.duelist")
    _DUELIST.AddListener("clear", _, function()
        self:Signal_EnemyCleared()
    end)
    _DUELIST.AddListener("appeared", _, function()
        self:Signal_EnemyAppeared()
    end)
    _DUELIST.AddListener("del", self, function(receiver, entity)
        self:Slot_EnemyDeleted(entity)
    end)

    NpcSrv.AddListenerToCallerNpcClicked(self, self.Slot_NpcClicked)
    NpcSrv.AddListenerToCallerNpcCanInteractChanged(self, self.Slot_NpcCanInteractChanged)

    --- post init
    for i = 1, Common.ArticleTableColCount * Common.ArticleTableRowCount do
        local articleInfo = Common.NewArticleInfo()
        articleInfo.Index = i
        self.articleInfoList[i] = articleInfo
    end

    -- equ
    for i = 1, Common.EquTypeCount do
        local articleInfo = Common.NewArticleInfo()
        self.mountedEquInfoList[i] = articleInfo
    end

    -- sound of changing article position
    self.changedArticlePosSoundSource = _RESOURCE.NewSource("asset/sound/ui/changed_article_pos.ogg")
    -- 复活音效
    self.playerRebornSoundSource = _RESOURCE.NewSource("asset/sound/actor/reborn.wav")

    ---@type table<int, UserActorInfoStruct>
    self.userActorInfoList = {}
    self.currentUserActorId = 0
    self:loadUserActorInfoList()

    ---@type table<int, Actor.Entity>
    self.jobActorList = {}
    self:loadJobActorList()

    ---@type table<int, Love.Video>
    self.mapOfJobToIntroVideo = {}
    self:loadMapOfJobToIntroVideo()

    -- map simple path list
    ---@type table<int, string>
    self.mapSimplePathList = {}
    self:loadMapSimplePathList()
end

--- public function

---@param dt number
function UiModel:Update(dt)
    self.mapLoadProcess = _MAP.GetLoadProcess()
    if self.mapLoadProcess == 0 and self.lastMapLoadProcess ~= 0 then
        local rect = _MAP.GetMatrix("normal"):GetRect()
        rect = Table.DeepClone(rect)
        self:Signal_MapLoaded(rect)
    end

    self.lastMapLoadProcess = self.mapLoadProcess
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

---@param player Actor.Entity
function UiModel:SetPlayer(player)
    if self.player == player then
        return
    end
    if self.player then
        -- disconnection
        local inventoryItemsComponent = self.player.InventoryItems
        self.player.attacker.hitCaller:DelListener(self, self.Slot_onRecvSignalOfPlayerHitEnemy)
        self.player.identity.destroyCaller:DelListener(self, self.Slot_onRecvSignalOfPlayerDestroyed)
        if inventoryItemsComponent then
            inventoryItemsComponent:DelListenerToItemInsertedCaller(self,
                self.Slot_InventoryItemOfPlayerInserted)
        end
        local masteredSkills = self.player.MasteredSkills
        if masteredSkills then
            MasteredSkillsSrv.DelListenerFromSkillAddedCaller(masteredSkills,
                self, self.Slot_MasteredSkillOfPlayerAdded)
            MasteredSkillsSrv.DelListenerFromSkillChangedCaller(masteredSkills,
                self, self.Slot_MasteredSkillOfPlayerChanged)
        end
    end
    self.player = player

    -- 设置物品数据
    for _, articleInfo in pairs(self.articleInfoList) do
        articleInfo.type = Common.ArticleType.Empty
    end
    local inventoryItemsComponent = self.player.InventoryItems
    if inventoryItemsComponent then
        for i, item in pairs(inventoryItemsComponent:GetList()) do
            self.articleInfoList[item.Index] = item
        end
    end

    -- equ
    for _, articleInfo in pairs(self.mountedEquInfoList) do
        articleInfo.type = Common.ArticleType.Empty
    end
    if self.player.equipments then
        ---@type Actor.RESMGR.EquipmentData
        local resMgrEquData
        ---@type ArticleInfo
        local articleInfo
        local itemDataFromContainer = self.player.equipments.container:Get("belt")
        if itemDataFromContainer then
            resMgrEquData = itemDataFromContainer:GetData()
            articleInfo = self.mountedEquInfoList[Common.EquType.Belt]
            Common.UpdateArticleInfoFromData(articleInfo, resMgrEquData)
        end

        itemDataFromContainer = self.player.equipments.container:Get("cap")
        if itemDataFromContainer then
            resMgrEquData = itemDataFromContainer:GetData()
            articleInfo = self.mountedEquInfoList[Common.EquType.Cap]
            Common.UpdateArticleInfoFromData(articleInfo, resMgrEquData)
        end

        itemDataFromContainer = self.player.equipments.container:Get("coat")
        if itemDataFromContainer then
            resMgrEquData = itemDataFromContainer:GetData()
            articleInfo = self.mountedEquInfoList[Common.EquType.Coat]
            Common.UpdateArticleInfoFromData(articleInfo, resMgrEquData)
        end

        itemDataFromContainer = self.player.equipments.container:Get("face")
        if itemDataFromContainer then
            resMgrEquData = itemDataFromContainer:GetData()
            articleInfo = self.mountedEquInfoList[Common.EquType.Face]
            Common.UpdateArticleInfoFromData(articleInfo, resMgrEquData)
        end

        itemDataFromContainer = self.player.equipments.container:Get("hair")
        if itemDataFromContainer then
            resMgrEquData = itemDataFromContainer:GetData()
            articleInfo = self.mountedEquInfoList[Common.EquType.Hair]
            Common.UpdateArticleInfoFromData(articleInfo, resMgrEquData)
        end

        itemDataFromContainer = self.player.equipments.container:Get("neck")
        if itemDataFromContainer then
            resMgrEquData = itemDataFromContainer:GetData()
            articleInfo = self.mountedEquInfoList[Common.EquType.Neck]
            Common.UpdateArticleInfoFromData(articleInfo, resMgrEquData)
        end

        itemDataFromContainer = self.player.equipments.container:Get("pants")
        if itemDataFromContainer then
            resMgrEquData = itemDataFromContainer:GetData()
            articleInfo = self.mountedEquInfoList[Common.EquType.Pants]
            Common.UpdateArticleInfoFromData(articleInfo, resMgrEquData)
        end

        itemDataFromContainer = self.player.equipments.container:Get("shoes")
        if itemDataFromContainer then
            resMgrEquData = itemDataFromContainer:GetData()
            articleInfo = self.mountedEquInfoList[Common.EquType.Shoes]
            Common.UpdateArticleInfoFromData(articleInfo, resMgrEquData)
        end

        itemDataFromContainer = self.player.equipments.container:Get("weapon")
        if itemDataFromContainer then
            resMgrEquData = itemDataFromContainer:GetData()
            articleInfo = self.mountedEquInfoList[Common.EquType.Weapon]
            Common.UpdateArticleInfoFromData(articleInfo, resMgrEquData)
        end

        itemDataFromContainer = self.player.equipments.container:Get("Suit")
        if itemDataFromContainer then
            resMgrEquData = itemDataFromContainer:GetData()
            articleInfo = self.mountedEquInfoList[Common.EquType.Suit]
            Common.UpdateArticleInfoFromData(articleInfo, resMgrEquData)
        end
    end

    -- 技能资源数据列表
    local masteredSkills = self.player.MasteredSkills
    self.masteredSkillInfoList = {}
    if masteredSkills then
        self.masteredSkillInfoList = self.player.MasteredSkills:GetList()
    end

    -- connection
    self.player.attacker.hitCaller:AddListener(self, self.Slot_onRecvSignalOfPlayerHitEnemy)
    self.player.identity.destroyCaller:AddListener(self, self.Slot_onRecvSignalOfPlayerDestroyed)
    if inventoryItemsComponent then
        inventoryItemsComponent:AddListenerToItemInsertedCaller(self,
            self.Slot_InventoryItemOfPlayerInserted)
    end
    if masteredSkills then
        MasteredSkillsSrv.AddListenerToSkillAddedCaller(masteredSkills,
            self, self.Slot_MasteredSkillOfPlayerAdded)
        MasteredSkillsSrv.AddListenerToSkillChangedCaller(masteredSkills,
            self, self.Slot_MasteredSkillOfPlayerChanged)
    end

    -- post init
    self:Signal_PlayerChanged()
end

function UiModel:GetPlayer()
    return self.player
end

---@return Actor.Skill
function UiModel:GetPlayerActorSkillObj(tag)
    if self.player == nil then
        print("UiModel:GetPlayerActorSkillObj(tag)", "player is nil")
        return nil
    end
    local mapOfTagToActorSkillObj = SkillSrv.GetMap(self.player.skills)

    return mapOfTagToActorSkillObj[tag]
end

function UiModel:GetPlayerMasteredSkillInfoList()
    return self.masteredSkillInfoList
end

---@param tag string
---@return string keyStr
function UiModel:GetSkillKeyByTag(tag)
    return _CONFIG.code[tag]
end

---@param tag string
---@param skillInfo SkillInfo
function UiModel:MountPlayerSkill(tag, skillInfo)
    -- 如果已经装配了相同技能，则先卸载
    -- self:unloadPlayerSkill(skillInfo)

    ---@type Actor.RESMGR.SkillData
    local skillResMgrData = ResMgr.GetSkillData(skillInfo.resDataPath)

    -- adjuset cd time
    skillResMgrData = Table.DeepClone(skillResMgrData)
    skillResMgrData.time = skillInfo.cdTime
    skillResMgrData.inCoolDown = true

    SkillSrv.Set(self.player, tag, skillResMgrData)

    self:SavePlayerData()

    self:Signal_PlayerMountedSkillsChanged()
end

---@param skillInfo SkillInfo
function UiModel:UnloadPlayerSkill(skillInfo)
    self:unloadPlayerSkill(skillInfo)

    self:SavePlayerData()
    self:Signal_PlayerMountedSkillsChanged()
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

function UiModel:SetArticleTableHoveringItemIndex(index)
    self.articleTableHoveringItemIndex = index
end

function UiModel:SetArticleDockHoveringItemIndex(index)
    self.articleDockHoveringItemIndex = index
end

--- 拖拽物品项
---@param index number 物品项检索
function UiModel:DragArticleItem(index)
    self.articleTableDraggingItemIndex = index
    self:RequestSetDraggingItemVisibility(true)
    local info = self.articleInfoList[index]
    self:RequestSetDraggingItemInfo(info)
end

--- 拖拽物品托盘物品项
---@param index number 物品项检索
function UiModel:DragArticleDockItem(index)
    self.articleDockDraggingItemIndex = index
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
        InventoryItemsSrv.InsertItemToEntity(self.player, self.articleTableHoveringItemIndex,
            draggingArticleInfo.count, draggingArticleInfo.path)

        -- 移动原先悬停处的物品到拖拽之前的位置
        InventoryItemsSrv.InsertItemToEntity(self.player, self.articleTableDraggingItemIndex,
            hoveringArticleInfo.count, hoveringArticleInfo.path)

        -- 播放物品移动音效
        self:playChangedArticlePosSound()
    else
        local draggingArticleInfo = self.articleInfoList[self.articleTableDraggingItemIndex]
        InventoryItemsSrv.DropItemFromEntity(self.player, draggingArticleInfo.Index,
            draggingArticleInfo.count)
    end

    -- 请求界面设置拖拽项为不可见
    self:RequestSetDraggingItemVisibility(false)
end

--- 放下物品托盘物品项
function UiModel:DropArticleDockItem()
    -- 拖拽项放到了何处
    if self.articleDockHoveringItemIndex ~= -1 then
        local hoveringArticleInfo = self.articleInfoList[self.articleDockHoveringItemIndex]

        -- 移动拖拽项到当前悬停处
        local draggingArticleInfo = self.articleInfoList[self.articleDockDraggingItemIndex]
        InventoryItemsSrv.InsertItemToEntity(self.player, self.articleDockHoveringItemIndex,
            draggingArticleInfo.count, draggingArticleInfo.path)

        -- 移动原先悬停处的物品到拖拽之前的位置
        InventoryItemsSrv.InsertItemToEntity(self.player, self.articleDockDraggingItemIndex,
            hoveringArticleInfo.count, hoveringArticleInfo.path)

        -- 播放物品移动音效
        self:playChangedArticlePosSound()
    end

    -- 请求界面设置拖拽项为不可见
    self:RequestSetDraggingItemVisibility(false)
end

---@param userActorId int
function UiModel:StartGame(userActorId)
    local actorInfo = self:findUserActorInfoById(userActorId)
    if actorInfo == nil then
        return
    end
    self.currentUserActorId = userActorId
    ---@type Actor.RESMGR.InstanceData
    local dataTmp = Table.DeepClone(actorInfo.Data)
    self.director.StartGame(dataTmp)

    self.partnerList = _CONFIG.user:GetPartnerList()

    -- 重置复活次数
    self.playerRebornCoinCount = 3
end

---@param mapId number
function UiModel:SelectGameMap(mapId)
    local simplePath = self.mapSimplePathList[mapId]
    _MAP.Load(simplePath)
end

function UiModel:LoadMobaMap()
    self.isInMobaMode = true

    -- reset OnceGameTaiSuCount
    _CONFIG.user.OnceGameTaiSuCount = 10000

    self:loadUserActorInfoList()

    local actorInfo = self:findUserActorInfoById(self.currentUserActorId)
    if actorInfo == nil then
        return
    end
    self.currentUserActorId = 2
    ---@type Actor.RESMGR.InstanceData
    local dataTmp = Table.DeepClone(actorInfo.Data)

    -- clear inventoryItems
    local classTmp = dataTmp.InventoryItems.class
    dataTmp.InventoryItems = {}
    dataTmp.InventoryItems.class = classTmp

    -- reset skills
    for k, v in pairs(dataTmp.skills) do
        if (k ~= "class" and type(v) ~= "boolean") then
            ---@type Actor.RESMGR.SkillData
            local skillResDataTmp = Table.DeepClone(v)
            skillResDataTmp.time = skillResDataTmp.time * Common.MobaSkillCdScale
            dataTmp.skills[k] = skillResDataTmp
        end
    end

    -- reset mastered skills
    local actorEntity = actorInfo.Entity
    ---@type table<int, MasteredSkillData>
    local masteredSkillDataList = {}
    dataTmp.MasteredSkills.List = masteredSkillDataList
    for i, skillInfo in pairs(actorEntity.MasteredSkills.List) do
        ---@type MasteredSkillData
        local masteredSkillData = {}
        masteredSkillData.Path = skillInfo.resDataPath
        masteredSkillData.Exp = skillInfo.Exp
        masteredSkillData.CdTime = skillInfo.cdTime * Common.MobaSkillCdScale
        table.insert(masteredSkillDataList, masteredSkillData)
    end

    -- reset HpRecovery
    dataTmp.attributes.maxHp = actorEntity.attributes.maxHp * 2
    dataTmp.attributes.hp = actorEntity.attributes.maxHp
    dataTmp.attributes.hpRecovery = 30

    -- create player
    local player = Factory.New(dataTmp, {
        x = 700,
        y = 500,
        direction = 1,
        camp = 1
    })


    self.director.firstUpdate() -- Flush player.

    _CONFIG.user:ClearPartnerList()
    _CONFIG.user:SetPlayer(player)

    self.partnerList = _CONFIG.user:GetPartnerList()

    -- moba enemy hero
    _CONFIG.user:ClearEnemyHeroList()
    local enemy = Factory.New("duelist/Moba/Hero", {
        x = 1610,
        y = 400,
        direction = -1,
        camp = 2
    })
    _CONFIG.user:AddEnemyHero(enemy)
    
    enemy = Factory.New("duelist/Moba/Hero", {
        x = 1610,
        y = 450,
        direction = -1,
        camp = 2
    })
    _CONFIG.user:AddEnemyHero(enemy)

    -- load map
    local simplePath = "Moba/Moba1"
    _MAP.Load(simplePath)

    self:Signal_LoadMobaMapFinished()
end

---@param type ActorAttributeType
function UiModel:GetPlayerAttribute(type)
    if self.player == nil then
        print("UiModel:GetPlayerAttribute(type)", "player is nil")
        return 0
    end

    return self:getActorAttribute(self.player, type)
end

---@param key string
function UiModel:PressPlayerKey(key)
    if (not self.player) then
        return
    end

    InputSrv.Press(self.player.input, key)
end

function UiModel:IsPressedPlayerKey(key)
    if (not self.player) then
        return
    end

    local KeyboardKey = _CONFIG.code[key]
    return KeyboardLib.IsPressed(KeyboardKey)
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

function UiModel:GetPartnerCount()
    return #self.partnerList
end

---@param index number
---@param type ActorAttributeType
function UiModel:GetOnePartnerAttribute(index, type)
    local entity = self.partnerList[index]
    if not entity then
        print("UiModel:GetOnePartnerAttribute(index, type)", "entity is nil")
        return 0
    end

    return self:getActorAttribute(entity, type)
end

---@param entity Actor.Entity
---@param value int
function UiModel:AddHpWithEffect(entity, value)
    AttributeSrv.AddHpWithEffect(entity, value)
end

function UiModel:IsPlayerAlive()
    if self.player == nil then
        return false
    end

    return self.player.identity.destroyProcess == 0
end

function UiModel:RebornPlayer()
    if (self:IsPlayerAlive()) then
        print("UiModel:RebornPlayer()", "player is alive, no need reborn!")
        return
    end

    if (self.playerRebornCoinCount < 1) then
        print("UiModel:RebornPlayer()", "player have not enough reborn coins!")
        return
    end

    print("UiModel:RebornPlayer()", "LifeSrv.RebornEntity(self.player)")
    LifeSrv.RebornEntity(self.player)

    local buff = BuffSrv.AddBuff(self.player, InvincibilityBuffData)
    buff:SetTime(3000)

    local pos = self.player.transform.position
    local direction = self.player.transform.direction
    local param = {
        x = pos.x,
        y = pos.y,
        z = pos.z,
        direction = direction,
        entity = self.player
    }
    Factory.New(RebornEffectInstanceData, param)

    -- 产生震动波
    Factory.New(CounterattackEffectInstanceData, param)
    Factory.New(DotAreaBulletInstanceData, param)

    -- 减少复活次数
    self.playerRebornCoinCount = self.playerRebornCoinCount - 1

    -- 播放复活音效
    self:playPlayerRebornSound()
    
    -- emit signal
    self:Signal_PlayerReborn()
end

function UiModel:GetPlayerRebornCoinCount()
    return self.playerRebornCoinCount
end

function UiModel:SavePlayerData()
    -- 1. 获取原始实例配置
    local actorInfo = self:findUserActorInfoById(self.currentUserActorId)
    if nil == actorInfo then
        print("UiModel:SavePlayerData()", "can not find User Actor Info By Id!", self.currentUserActorId)
        return
    end
    
    local oriInstanceData = actorInfo.Data
    if oriInstanceData == nil then
        print("UiModel:SavePlayerData()", "origin instance cfg read failed!")
        return
    end
    if oriInstanceData.skills == nil then
        print("UiModel:SavePlayerData()", "origin instance cfg data have nor skills data")
        return
    end
    if oriInstanceData.equipments == nil then
        print("UiModel:SavePlayerData()", "origin instance cfg data have nor equipments data")
        return
    end

    local data = Common.NewUserActorData()
    data.OriCfgSimplePath = actorInfo.OriCfgSimplePath
    local content = data.Content

    -- 2.1 identity
    content.Identity = oriInstanceData.identity
    content.Identity.name = self.player.identity.name

    -- 2.2 更新技能配置
    local skills = {}
    local mapOfTagToActorSkillObj = SkillSrv.GetMap(self.player.skills)
    for tag, obj in pairs(mapOfTagToActorSkillObj) do
        if obj then
            skills[tag] = obj:GetData().path
        end
    end
    content.Skills = skills

    -- 3. 更新装备
    local equipments = {}
    local mapOfTagToActorEquObj = EquSrv.GetMap(self.player.equipments)
    for tag, obj in pairs(mapOfTagToActorEquObj) do
        if obj then
            equipments[tag] = obj:GetData().path
        end
    end
    content.Equipments = equipments

    -- 4. 装载物品项数据
    local inventoryItems = { List = {} }
    local articleInfoList = self.player.InventoryItems:GetList()
    for _, info in pairs(articleInfoList) do
        if info ~= nil and info.type ~= Common.ArticleType.Empty then
            local item = {
                Index = info.Index,
                Count = info.count,
                Path = info.path
            }
            table.insert(inventoryItems.List, item)
        end
    end
    content.InventoryItems = inventoryItems

    -- 5. 装载已掌握技能列表数据
    local masteredSkills = { List = {} }
    local masteredSkillInfoList = self.player.MasteredSkills:GetList()
    for _, info in pairs(masteredSkillInfoList) do
        local skillData = { Path = "", Exp = 0 };
        skillData.Path = info.resDataPath
        skillData.Exp = info.Exp
        table.insert(masteredSkills.List, skillData)
    end
    content.MasteredSkills = masteredSkills

    -- 6. 序列化数据
    local dataStr = Table.Deserialize(data)

    -- 7. 保存数据
    local filePath = Common.UserActorCfgDirPath .. "/Actor" .. tostring(actorInfo.Id) .. PlayerCfgSavedFileSuffix
    if self.isInMobaMode then
        filePath = Common.UserActorCfgDirPath .. "/MobaActor" .. PlayerCfgSavedFileSuffix
    end
    local ok, errMsg = File.WriteFile(filePath, dataStr)
    if not ok then
        print("UiModel:SavePlayerData()", errMsg, filePath, "file write failed！")
        return
    end
end

---@return table<string, string>
function UiModel:GetConfigMapOfFunNameToKey()
    return _CONFIG.code
end

---@param map table<string, string>
function UiModel:SaveConfigMapOfFunNameToKey(map)
    for funName, key in pairs(map) do
        InputLib.SetKey(funName, key)
    end

    self:SaveConfig()

    self:Signal_PlayerMountedSkillsChanged()
end

function UiModel:SaveConfig()
    -- 1、获取设置文件路径
    local settingsFilePath = _CONFIG.ConfigDirPath .. _CONFIG.SettingsFileName
    if not File.Exists(settingsFilePath) then
        settingsFilePath = _CONFIG.ConfigDirPath .. _CONFIG.DefaultSettingsFileName
    end

    -- 2、读取原设置数据
    local content = File.ReadFile(settingsFilePath)
    ---@type CONFIG
    local configData = loadstring(content)()

    -- 3.1、更新按键数据
    configData.code = _CONFIG.code

    -- 3.2 更新音量数据
    configData.setting.music = _CONFIG.setting.music
    configData.setting.sound = _CONFIG.setting.sound
    
    -- 3.3 更新窗口尺寸比例
    configData.setting.WindowSizePercentage = _CONFIG.setting.WindowSizePercentage

    -- 4. 序列化数据
    local dataStr = Table.Deserialize(configData)

    -- 5. 保存数据
    local filePath = _CONFIG.ConfigDirPath .. _CONFIG.SettingsFileName
    local ok, errMsg = File.WriteFile(filePath, dataStr)
    if not ok then
        print("UiModel:SaveConfig()", errMsg, dirPath .. fileName, "file write failed！")
        return
    end
end

function UiModel:GetUserActorInfoList()
    return self.userActorInfoList
end

function UiModel:NewAUserActorConfigNoSuffixFileName()
    for i = 1, Common.UserActorPageTotalCount do
        local noSuffixFileName = "Actor" .. tostring(i)
        local userActorCfgFilePath = Common.UserActorCfgDirPath .. "/" .. noSuffixFileName .. PlayerCfgSavedFileSuffix
        if false == File.Exists(userActorCfgFilePath) then
            return noSuffixFileName
        end
    end

    return ""
end

function UiModel:GetJobActorList()
    return self.jobActorList
end

---@param job int JobEnum
function UiModel:GetJobIntroVideo(job)
    return self.mapOfJobToIntroVideo[job]
end

function UiModel:GetMapSimplePathList()
    return self.mapSimplePathList
end

---@param jobActorSimplePath string
---@param name string
function UiModel:CreateUserActor(jobActorSimplePath, name)
    -- 1. 读取职业实例配置
    local instanceData, path = _RESOURCE.ReadConfig(jobActorSimplePath, "config/actor/instance/%s.cfg", nil)
    if instanceData == nil then
        print("UiModel:CreateUserActor()", "job actor instance cfg read failed!")
        return
    end

    local data = Common.NewUserActorData()
    data.OriCfgSimplePath = jobActorSimplePath

    local identityData = Table.DeepClone(instanceData.identity)
    identityData.name = name
    data.Content.Identity = identityData

    -- 2. 序列化数据
    local dataStr = Table.Deserialize(data)

    -- 3. 保存数据
    local fileName = self:NewAUserActorConfigNoSuffixFileName() .. PlayerCfgSavedFileSuffix
    local filePath = Common.UserActorCfgDirPath .. "/" .. fileName
    local ok, errMsg = File.WriteFile(filePath, dataStr)
    if not ok then
        print("UiModel:CreateUserActor()", errMsg, dirPath .. fileName, "file write failed！")
        return
    end

    -- 重新加载用户角色列表
    self:loadUserActorInfoList()
end

---@param userActorId int
function UiModel:DeleteUserActor(userActorId)
    local playerCfgFilePath = Common.UserActorCfgDirPath .. "/Actor" .. tostring(userActorId) .. PlayerCfgSavedFileSuffix
    local succeed, errMsg = File.Delete(playerCfgFilePath)
    if not succeed then
        print("UiModel:DeleteUserActor(userActorId)", errMsg)
        return
    end

    -- 重新加载用户角色列表
    self:loadUserActorInfoList()
end

---@param timeMs int
---@param text string
function UiModel:RequestUiToShowNotification(timeMs, text)
    self:Signal_RequestShowNotification(timeMs, text)
end

function UiModel:GoToGameStartPage()
    _CONFIG.user:ClearPartnerList()
    _MAP.Load("NoMap", true)
    LifeSrv.KillAllEntity()

    self:loadUserActorInfoList()
    self:loadJobActorList()
    self:Signal_RequestSetUiGameState(Common.GameState.ActorSelect)
end

---@param value number
function UiModel:SetMusicVol(value)
    if math.abs(_CONFIG.setting.music - value) < 0.001 then
        return
    end

    _CONFIG.setting.music = value
    MusicLib.AdjustVolume()

    self:SaveConfig()
end

function UiModel:GetMusicVol()
    return _CONFIG.setting.music
end

function UiModel:PauseMusic()
    MusicLib.Pause()
end

function UiModel:ResumeMusic()
    MusicLib.Resume()
end

---@param value number
function UiModel:SetSoundVol(value)
    if math.abs(_CONFIG.setting.sound - value) < 0.001 then
        return
    end

    _CONFIG.setting.sound = value

    self:SaveConfig()
end

function UiModel:GetSoundVol()
    return _CONFIG.setting.sound
end

---@param value number
function UiModel:SetWindowSizePercentage(value)
    if math.abs(_CONFIG.setting.WindowSizePercentage - value) < 0.001 then
        return
    end

    _CONFIG.setting.WindowSizePercentage = value

    self:SaveConfig()
end

function UiModel:GetWindowSizePercentage()
    return _CONFIG.setting.WindowSizePercentage
end

function UiModel:IsInRougelikeMode()
    return self.isInRougelikeMode
end

function UiModel:IsInMobaMode()
    return self.isInMobaMode
end

function UiModel:CreatePlaneMapSprite()
    local m = _MAP.GetMatrix("normal")
    local s = m:CreatePlaneMapSprite()
    return s
end

function UiModel:GetMapInfo()
    return _MAP.info
end

function UiModel:ExitGame()
    SystemLib.Exit()
end

function UiModel:GetInteractingNpcInfo()
    return self.interactingNpcInfo
end

function UiModel:PlayNpcWelcomeVoice()
    if self.interactingNpcInfo.Entity == nil then
        return
    end

    NpcSrv.PlayWelcomeVoice(self.interactingNpcInfo.Entity.Npc)
end

function UiModel:PlayNpcLeaveVoice()
    if self.interactingNpcInfo.Entity == nil then
        return
    end

    NpcSrv.PlayLeaveVoice(self.interactingNpcInfo.Entity.Npc)
end

function UiModel:GetOnceGameTaiSuCount()
    return _CONFIG.user.OnceGameTaiSuCount
end

---@param skillConfigPath string
function UiModel:PayForReduceCdTime(skillConfigPath)
    if _CONFIG.user.OnceGameTaiSuCount < 100 then
        print("UiModel:PayForReduceCdTime()", "TaiSu is not enough!")
        SoundLib.Play(NotFitAlertSoundData)
        return
    end

    SoundLib.Play(SkillConsumableUsedSoundData)
    self:addTaiSuCount(-100)
    MasteredSkillsSrv.ReduceSkillCdTimePercent(self.player.MasteredSkills, skillConfigPath, 0.05)
end

--- signals

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

--- 请求去设置物品托盘某一显示项的信息
---@param index number
---@param itemInfo ArticleInfo
function UiModel:Signal_requestSetArticleDockItemInfo(index, itemInfo)
    print("UiModel:Signal_requestSetArticleDockItemInfo(index, itemInfo)", index, itemInfo.name)
    local receiverList = self.mapOfSignalToReceiverList[self.Signal_requestSetArticleDockItemInfo]
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.Slot_requestSetArticleDockItemInfo
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
function UiModel:Signal_PlayerChanged()
    -- print("UiModel:Signal_PlayerChanged()")
    local receiverList = self.mapOfSignalToReceiverList[self.Signal_PlayerChanged]
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.Slot_PlayerChanged
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

function UiModel:Signal_PlayerDestroyed()
    local receiverList = self.mapOfSignalToReceiverList[self.Signal_PlayerDestroyed]
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.Slot_PlayerDestroyed
        if func == nil then
            goto continue
        end

        func(receiver, self)

        ::continue::
    end
end

function UiModel:Signal_PlayerReborn()
    local receiverList = self.mapOfSignalToReceiverList[self.Signal_PlayerReborn]
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.Slot_PlayerReborn
        if func == nil then
            goto continue
        end

        func(receiver, self)

        ::continue::
    end
end

function UiModel:Signal_PlayerMountedSkillsChanged()
    local receiverList = self.mapOfSignalToReceiverList[self.Signal_PlayerMountedSkillsChanged]
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.Slot_PlayerMountedSkillsChanged
        if func == nil then
            goto continue
        end

        func(receiver, self)

        ::continue::
    end
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

---@param info SkillInfo
function UiModel:Signal_PlayerMasteredSkillAdded(info)
    local receiverList = self.mapOfSignalToReceiverList[self.Signal_PlayerMasteredSkillAdded]
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.Slot_PlayerMasteredSkillAdded
        if func == nil then
            goto continue
        end

        func(receiver, self, info)

        ::continue::
    end
end

---@param info SkillInfo
function UiModel:Signal_PlayerMasteredSkillChanged(info)
    local receiverList = self.mapOfSignalToReceiverList[self.Signal_PlayerMasteredSkillChanged]
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.Slot_PlayerMasteredSkillChanged
        if func == nil then
            goto continue
        end

        func(receiver, self, info)

        ::continue::
    end
end

---@param timeMs int
---@param text string
function UiModel:Signal_RequestShowNotification(timeMs, text)
    local receiverList = self.mapOfSignalToReceiverList[self.Signal_RequestShowNotification]
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.Slot_RequestShowNotification
        if func == nil then
            goto continue
        end

        func(receiver, self, timeMs, text)

        ::continue::
    end
end

---@param state GameState
function UiModel:Signal_RequestSetUiGameState(state)
    local receiverList = self.mapOfSignalToReceiverList[self.Signal_RequestSetUiGameState]
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.Slot_RequestSetUiGameState
        if func == nil then
            goto continue
        end

        func(receiver, self, state)

        ::continue::
    end
end

---@param scopeRect Graphics.Drawunit.Rect
function UiModel:Signal_MapLoaded(scopeRect)
    local receiverList = self.mapOfSignalToReceiverList[self.Signal_MapLoaded]
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.Slot_MapLoaded
        if func == nil then
            goto continue
        end

        func(receiver, self, scopeRect)

        ::continue::
    end
end

function UiModel:Signal_ReqShowNpcDlg()
    local receiverList = self.mapOfSignalToReceiverList[self.Signal_ReqShowNpcDlg]
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.Slot_ReqShowNpcDlg
        if func == nil then
            goto continue
        end

        func(receiver, self)

        ::continue::
    end
end

---@param isVisible boolean
function UiModel:Signal_ReqSetVisibilityNpcInteractBtn(isVisible)
    local receiverList = self.mapOfSignalToReceiverList[self.Signal_ReqSetVisibilityNpcInteractBtn]
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.Slot_ReqSetVisibilityNpcInteractBtn
        if func == nil then
            goto continue
        end

        func(receiver, self, isVisible)

        ::continue::
    end
end

function UiModel:Signal_LoadMobaMapFinished()
    local receiverList = self.mapOfSignalToReceiverList[self.Signal_LoadMobaMapFinished]
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.Slot_LoadMobaMapFinished
        if func == nil then
            goto continue
        end

        func(receiver, self)

        ::continue::
    end
end

---@param count int
function UiModel:Signal_OnceGameTaiSuCountChanged(count)
    local receiverList = self.mapOfSignalToReceiverList[self.Signal_OnceGameTaiSuCountChanged]
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.Slot_OnceGameTaiSuCountChanged
        if func == nil then
            goto continue
        end

        func(receiver, self, count)

        ::continue::
    end
end

---@param count int
function UiModel:Signal_TaiSuCountChanged(count)
    local receiverList = self.mapOfSignalToReceiverList[self.Signal_TaiSuCountChanged]
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.Slot_TaiSuCountChanged
        if func == nil then
            goto continue
        end

        func(receiver, self, count)

        ::continue::
    end
end

--- slots

---@param player Actor.Entity
function UiModel:Slot_PlayerChanged(player)
    self:SetPlayer(player)
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
function UiModel:OnRightKeyClickedArticleDockItem(index)
    local clickedItemInfo = self.articleInfoList[index]
    if clickedItemInfo == nil then
        print("UiModel:OnRightKeyClickedArticleDockItem(index)", "err: can not find itemInfo")
        return
    end

    if clickedItemInfo.type == Common.ArticleType.Consumable then
        self:useConsumable(clickedItemInfo.Index, clickedItemInfo)
    elseif clickedItemInfo.type == Common.ArticleType.Equipment then
        self:mountEquipment(clickedItemInfo.Index, clickedItemInfo)
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

---@param xPos number
---@param yPos number
function UiModel:OnRequestMoveDraggingArticleItem(xPos, yPos)
    self:RequestMoveDraggingItem(xPos, yPos)
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

function UiModel:Slot_onRecvSignalOfPlayerDestroyed()
    self:Signal_PlayerDestroyed()
end

---@param articleInfo ArticleInfo
function UiModel:Slot_InventoryItemOfPlayerInserted(articleInfo)
    self.articleInfoList[articleInfo.Index] = articleInfo
    self:RequestSetArticleTableItemInfo(articleInfo.Index, articleInfo)

    -- 更新物品托盘
    if articleInfo.Index <= Common.ArticleDockColCount then
        self:Signal_requestSetArticleDockItemInfo(articleInfo.Index, articleInfo)
    end
    self:SavePlayerData()
end

---@param info SkillInfo
function UiModel:Slot_MasteredSkillOfPlayerAdded(info)
    self:SavePlayerData()

    self:Signal_PlayerMasteredSkillAdded(info)

    local text = "习得：[" .. info.name .. "]"
    self:RequestUiToShowNotification(5000, text)
end

---@param info SkillInfo
function UiModel:Slot_MasteredSkillOfPlayerChanged(info)
    self:SavePlayerData()

    self:Signal_PlayerMasteredSkillChanged(info)

    -- 更新玩家角色装备的技能数据（cd）
    local skillMap = SkillSrv.GetMap(self.player.skills)
    for tag, skill in pairs(skillMap) do
        if skill:GetData().path == info.resDataPath 
            and skill.time ~= info.cdTime
        then
            skill.time = info.cdTime
            self:Signal_PlayerMountedSkillsChanged()
            break
        end
    end
end

---@param entity Actor.Entity
function UiModel:Slot_NpcClicked(entity)
    self.interactingNpcInfo.Name = entity.identity.name
    self.interactingNpcInfo.Intro = entity.Npc.Intro
    self.interactingNpcInfo.Entity = entity

    self:Signal_ReqShowNpcDlg()
end

---@param entity Actor.Entity
function UiModel:Slot_NpcCanInteractChanged(entity)
    if SystemLib.IsMobile() == false then
        return
    end

    if nil == entity then
        self:Signal_ReqSetVisibilityNpcInteractBtn(false)
        return
    end

    self.interactingNpcInfo.Name = entity.identity.name
    self.interactingNpcInfo.Intro = entity.Npc.Intro
    self.interactingNpcInfo.Entity = entity
    self:Signal_ReqSetVisibilityNpcInteractBtn(true)
end

---@param entity Actor.Entity
function UiModel:Slot_EnemyDeleted(entity)

    if entity.battle.beatenConfig.entity == nil then
        return
    end
    if entity.battle.beatenConfig.entity ~= self.player and
        entity.battle.beatenConfig.entity.identity.superior ~= self.player
    then
        return
    end

    local taiSuCountGot = 0
    if entity.duelist.rank == 0 then
        taiSuCountGot = 1
    elseif entity.duelist.rank == 1 then
        taiSuCountGot = 3
    elseif entity.duelist.rank == 2 then
        taiSuCountGot = 10
    end

    self:addTaiSuCount(taiSuCountGot)
end


--========== private function ============

--- 使用物品
---@param index number
---@param itemInfo ArticleInfo
function UiModel:useConsumable(index, itemInfo)
    print("UiModel:useConsumable(index, itemInfo)", index, itemInfo.name)
    local job = self.player.identity.Job
    if not Common.IsArticleInfoFitForJob(itemInfo, job) then
        SoundLib.Play(NotFitAlertSoundData)
        print("UiModel:useConsumable(index, itemInfo)", "This consumable is not fit for job:", job)
        return
    end
    local gender = self.player.identity.gender
    if not Common.IsArticleInfoFitForGender(itemInfo, gender) then
        SoundLib.Play(NotFitAlertSoundData)
        print("UiModel:useConsumable(index, itemInfo)",
            "This consumable is not fit for gender:", gender)
        return
    end

    -- Revive
    local StateName = itemInfo.consumableInfo.StateName
    if StateName == "Revive" and self.player.states.current:GetName() == "stay" then
        if not StateSrv.HasState(self.player.states, StateName)
        then
            local jobPath = Common.MapOfJobToPath[self.player.identity.Job]
            local stateResMgrDataPath = jobPath .. "/" .. StateName
            StateSrv.SetState(self.player, StateName, stateResMgrDataPath)
        end
        StateSrv.Play(self.player.states, StateName)
        return
    end

    local hpRecovery = itemInfo.consumableInfo.hpRecovery
    local playerCurrentHp = self:GetPlayerAttribute(Common.ActorAttributeType.Hp)
    hpRecovery = hpRecovery + playerCurrentHp * itemInfo.consumableInfo.hpRecoveryRate
    if (hpRecovery > 0) then
        self:AddHpWithEffect(self.player, hpRecovery)
    end

    if itemInfo.consumableInfo.SkillPath ~= "" then
        SoundLib.Play(SkillConsumableUsedSoundData)
        MasteredSkillsSrv.AddSkillToMasteredSkillsCmpt(self.player.MasteredSkills,
            itemInfo.consumableInfo.SkillPath)
    end

    itemInfo.count = itemInfo.count - 1
    if itemInfo.count <= 0 then
        itemInfo.count = 0
        itemInfo.type = Common.ArticleType.Empty
        itemInfo.path = ""
    end
    InventoryItemsSrv.InsertItemToEntity(self.player, index, itemInfo.count, itemInfo.path)
end

--- 装载装备
---@param articleTableIndex number
---@param itemInfo ArticleInfo
function UiModel:mountEquipment(articleTableIndex, itemInfo)
    print("UiModel:mountEquipment(index, itemInfo)", articleTableIndex, itemInfo.name)
    local job = self.player.identity.Job
    if not Common.IsArticleInfoFitForJob(itemInfo, job) then
        SoundLib.Play(NotFitAlertSoundData)
        print("UiModel:mountEquipment(index, itemInfo)", "equ is not fit for job:", job)
        return
    end
    local gender = self.player.identity.gender
    if not Common.IsArticleInfoFitForGender(itemInfo, gender) then
        SoundLib.Play(NotFitAlertSoundData)
        print("UiModel:mountEquipment(index, itemInfo)",
            "equ is not fit for gender:", gender)
        return
    end
    local stateName = self.player.states.current:GetName()
    if stateName ~= "stay" then
        SoundLib.Play(NotFitAlertSoundData)
        print("UiModel:mountEquipment(index, itemInfo)",
            "can not mount equ, until player is in stay state:", stateName)
        return
    end

    local lastEquItemInfo = self.mountedEquInfoList[itemInfo.equInfo.type]
    -- 在ui上卸载原有装备到物品栏
    InventoryItemsSrv.InsertItemToEntity(self.player, articleTableIndex,
        lastEquItemInfo.count, lastEquItemInfo.path)

    -- 在服务上装载新装备
    local keyTag = Common.MapOfEquTypeToTag[itemInfo.equInfo.type]
    EquSrv.Equip(self.player, keyTag, itemInfo.equInfo.resMgrEquData)
    -- 在服务上调整实体装扮
    AspectSrv.AdjustAvatar(self.player.aspect, self.player.states)

    -- 在ui上装载新装备
    self.mountedEquInfoList[itemInfo.equInfo.type] = itemInfo
    self:RequestSetEquTableItemInfo(itemInfo.equInfo.type, itemInfo)

    -- save
    self:SavePlayerData()

    -- 播放物品移动音效
    self:playChangedArticlePosSound()
end

--- 卸载装备
---@param equTableIndex number
---@param itemInfo ArticleInfo
function UiModel:unloadEquipment(equTableIndex, itemInfo)
    print("UiModel:unloadEquipment(index, itemInfo)", equTableIndex, itemInfo.name)
    if false == InventoryItemsSrv.WhetherEntityCanAddItem(self.player, itemInfo.type, 
            itemInfo.count, itemInfo.path)
    then
        print("UiModel:unloadEquipment(index, itemInfo)", "has no empty space!")
        SoundLib.Play(NotFitAlertSoundData)
        return
    end

    -- 在ui上卸载到物品栏的空位置
    InventoryItemsSrv.AddItemToEntity(self.player,
        itemInfo.count, itemInfo.path)

    -- 在ui上将装备栏对应位置设置为空
    local emptyItemInfo = Common.NewArticleInfo()
    self.mountedEquInfoList[equTableIndex] = emptyItemInfo
    self:RequestSetEquTableItemInfo(equTableIndex, emptyItemInfo)

    -- 在服务上卸载装备
    local keyTag = Common.MapOfEquTypeToTag[itemInfo.equInfo.type]
    EquSrv.Del(self.player, keyTag)
    -- 在服务上调整实体装扮
    AspectSrv.AdjustAvatar(self.player.aspect, self.player.states)

    -- save
    self:SavePlayerData()

    -- 播放物品移动音效
    self:playChangedArticlePosSound()
end

function UiModel:playChangedArticlePosSound()
    -- 播放物品移动音效
    self.changedArticlePosSoundSource:stop()
    self.changedArticlePosSoundSource:setVolume(_CONFIG.setting.sound)
    self.changedArticlePosSoundSource:play()
end

---@param entity Actor.Entity
---@param type ActorAttributeType
function UiModel:getActorAttribute(entity, type)
    if type == Common.ActorAttributeType.Hp then
        return entity.attributes.hp
    elseif type == Common.ActorAttributeType.MaxHp then
        return entity.attributes.maxHp
    elseif type == Common.ActorAttributeType.HpRecovery then
        return entity.attributes.hpRecovery
    elseif type == Common.ActorAttributeType.Mp then
        return entity.attributes.mp
    elseif type == Common.ActorAttributeType.MaxMp then
        return entity.attributes.maxMp
    elseif type == Common.ActorAttributeType.PhyAtk then
        return entity.attributes.phyAtk
    elseif type == Common.ActorAttributeType.MagAtk then
        return entity.attributes.magAtk
    elseif type == Common.ActorAttributeType.PhyDef then
        return entity.attributes.phyDef
    elseif type == Common.ActorAttributeType.MagDef then
        return entity.attributes.magDef
    elseif type == Common.ActorAttributeType.MoveSpeed then
        return entity.attributes.moveRate
    elseif type == Common.ActorAttributeType.AttackSpeed then
        return entity.attributes.attackRate
    elseif type == Common.ActorAttributeType.PhyAtkRate then
        return entity.attributes.phyAtkRate
    elseif type == Common.ActorAttributeType.MagAtkRate then
        return entity.attributes.magAtkRate
    end
end

function UiModel:playPlayerRebornSound()
    self.playerRebornSoundSource:stop()
    self.playerRebornSoundSource:setVolume(_CONFIG.setting.sound)
    self.playerRebornSoundSource:play()
end

---@param skillInfo SkillInfo
function UiModel:unloadPlayerSkill(skillInfo)
    local mapOfTagToActorSkillObj = SkillSrv.GetMap(self.player.skills)
    for tagTmp, actorSkillObj in pairs(mapOfTagToActorSkillObj) do
        if actorSkillObj ~= nil and
            actorSkillObj:GetData().path == skillInfo.resDataPath
        then
            SkillSrv.Set(self.player, tagTmp, nil)
        end
    end
end

function UiModel:loadUserActorInfoList()
    self.userActorInfoList = {}

    for i = 1, Common.UserActorPageTotalCount do
        local fileName = "Actor" .. tostring(i) .. PlayerCfgSavedFileSuffix
        local userActorCfgFilePath = Common.UserActorCfgDirPath .. "/" .. fileName
        if File.Exists(userActorCfgFilePath) then
            local actorInfo = Common.NewUserActorInfo()
            actorInfo.Id = i

            ---@type UserActorDataStruct
            local userActorData = ResLib.ReadConfig(userActorCfgFilePath, "%s")
            actorInfo.OriCfgSimplePath = userActorData.OriCfgSimplePath
            
            local instanceData, _ = _RESOURCE.ReadConfig(userActorData.OriCfgSimplePath, "config/actor/instance/%s.cfg", nil)
            instanceData.identity = userActorData.Content.Identity or instanceData.identity
            instanceData.skills = userActorData.Content.Skills or instanceData.skills
            instanceData.equipments = userActorData.Content.Equipments or instanceData.equipments
            instanceData.InventoryItems = userActorData.Content.InventoryItems or instanceData.InventoryItems
            instanceData.MasteredSkills = userActorData.Content.MasteredSkills or instanceData.MasteredSkills
            
            -- 序列化数据
            local dataStr = Table.Deserialize(instanceData)
            -- 保存临时数据
            local instanceCfgSimplePathTmp = "duelist/UserActorTmp"
            local filePath = "config/actor/instance/" .. instanceCfgSimplePathTmp .. PlayerCfgSavedFileSuffix
            local ok, errMsg = File.WriteFile(filePath, dataStr)
            if not ok then
                print("UiModel:loadUserActorInfoList()", errMsg, filePath, "file write failed！")
                return
            end
            -- 使用资源管理器读取临时实例数据
            local resMgrInstanceData = ResMgr.GetInstanceDataWithNoPool(instanceCfgSimplePathTmp)
            actorInfo.Data = resMgrInstanceData
            
            local e = Factory.New(resMgrInstanceData, {})
            e.ais.enable = false
            actorInfo.Entity = e
            table.insert(self.userActorInfoList, actorInfo)
        end
    end
end

function UiModel:loadJobActorList()
    self.jobActorList = {}

    local actorSimplePathList = {
        "duelist/swordman",
        "duelist/atswordman",
        "duelist/Fighter",
        "duelist/Kyo",
        "duelist/Tsunade",
        "duelist/Iori",
    }
    assert(#actorSimplePathList < Common.JobActorPageTotalCount, "Exceeding the max job count")
    for _, actorSimplePath in pairs(actorSimplePathList) do
        local e = Factory.NewWithNoDataPool(actorSimplePath, {})
        e.ais.enable = false
        table.insert(self.jobActorList, e)
    end
end

function UiModel:loadMapOfJobToIntroVideo()
    for i, job in pairs(Common.JobEnum) do
        local videoFilePath = Common.MapOfJobToIntroVideoPath[job]
        if videoFilePath ~= "" then
            self.mapOfJobToIntroVideo[job] = GraphicsLib.NewVideo(videoFilePath)
        end
    end
end

function UiModel:loadMapSimplePathList()
    local fileNameList = File.ListDirectoryItems("config/map/instance")
    for _, fileName in pairs(fileNameList) do
        local fileNameWithoutSuffix = String.RmExtSuffix(fileName)
        table.insert(self.mapSimplePathList, fileNameWithoutSuffix)
    end
end

function UiModel:findUserActorInfoById(id)
    for i, info in pairs(self.userActorInfoList) do
        if id == info.Id then
            return info
        end
    end

    return nil
end

---@param count int
function UiModel:addTaiSuCount(count)
    if self.isInMobaMode then
        _CONFIG.user.OnceGameTaiSuCount = _CONFIG.user.OnceGameTaiSuCount + count
        self:Signal_OnceGameTaiSuCountChanged(_CONFIG.user.OnceGameTaiSuCount)
    else
        _CONFIG.user.TaiSuCount = _CONFIG.user.TaiSuCount + count
        self:Signal_TaiSuCountChanged(_CONFIG.user.TaiSuCount)
    end
end

return UiModel
