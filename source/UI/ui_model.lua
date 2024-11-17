--[[
	desc: UiModel class, ui数据处理类
	author: keke <243768648@qq.com>
	since: 2023-7-19
	alter: 2023-7-19
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

local ResLib = require("lib.resource")
local SoundLib = require("lib.sound")

local Table = require("lib.table")
local _RESOURCE = require("lib.resource")
local File = require("lib.file")
local String = require("lib.string")

---@class UiModel
local UiModel = require("core.class")()

local RebornEffectInstanceData = ResMgr.GetInstanceData("effect/death/normal")
local CounterattackEffectInstanceData = ResMgr.GetInstanceData("effect/battle/counterattack2")
local DotAreaBulletInstanceData = ResMgr.GetInstanceData("bullet/swordman/dotarea")

local PlayerCfgSavedFileName = "player"
local PlayerCfgSavedFileSuffix = ".cfg"

-- SoundData
local NotFitAlertSoundData = ResLib.GetSoundData("ui/Alert1")

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

    --- 物品托盘的物品列表
    ---@type table<number, ArticleInfo>
    self.articleDockInfoList = {}
    
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

    --- post init
    for i = 1, Common.ArticleTableColCount * Common.ArticleTableRowCount do
        local articleInfo = Common.NewArticleInfo()
        self.articleInfoList[i] = articleInfo
    end

    for i = 1, Common.ArticleDockColCount do
        local articleInfo = Common.NewArticleInfo()
        self.articleDockInfoList[i] = articleInfo
    end

    -- equ
    for i = 1, Common.EquTableColCount * Common.EquTableRowCount do
        local articleInfo = Common.NewArticleInfo()
        self.mountedEquInfoList[i] = articleInfo
    end

    -- sound of changing article position
    self.changedArticlePosSoundSource = _RESOURCE.NewSource("asset/sound/ui/changed_article_pos.ogg")
    -- 复活音效
    self.playerRebornSoundSource = _RESOURCE.NewSource("asset/sound/actor/reborn.wav")

    -- actor simple path list
    ---@type table<int, string>
    self.actorSimplePathList = {}
    self:loadActorSimplePathList()

    -- map simple path list
    ---@type table<int, string>
    self.mapSimplePathList = {}
    self:loadMapSimplePathList()
end

--- public function

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
    self.player = player

    -- 设置物品数据
    local inventoryItemsComponent = self.player.InventoryItems
    if inventoryItemsComponent then
        for i, item in pairs(inventoryItemsComponent:GetList()) do
            self.articleInfoList[item.Index] = item
        end
    end

    -- equ
    if self.player.equipments then
        ---@type Actor.RESMGR.EquipmentData
        local resMgrEquData
        ---@type ArticleInfo
        local articleInfo
        local itemDataFromContainer = self.player.equipments.container:Get("belt")
        if itemDataFromContainer then
            resMgrEquData = itemDataFromContainer:GetData()
            articleInfo = self.mountedEquInfoList[Common.EquType.Belt]
            articleInfo.id = 5
            articleInfo.path = "equipment/" .. resMgrEquData.path
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
            articleInfo.path = "equipment/" .. resMgrEquData.path
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
            articleInfo.path = "equipment/" .. resMgrEquData.path
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
            articleInfo.path = "equipment/" .. resMgrEquData.path
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
            articleInfo.path = "equipment/" .. resMgrEquData.path
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
            articleInfo.path = "equipment/" .. resMgrEquData.path
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
            articleInfo.path = "equipment/" .. resMgrEquData.path
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
            articleInfo.path = "equipment/" .. resMgrEquData.path
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
            articleInfo.path = "equipment/" .. resMgrEquData.path
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
    end

    -- aricle dock
    self.articleDockInfoList[1] = self.articleInfoList[1]
    self.articleDockInfoList[2] = self.articleInfoList[2]
    self.articleDockInfoList[3] = self.articleInfoList[3]
    self.articleDockInfoList[4] = self.articleInfoList[4]
    self.articleDockInfoList[5] = self.articleInfoList[5]

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
    self:unloadPlayerSkill(skillInfo)

    ---@type Actor.RESMGR.SkillData
    local skillResMgrData = ResMgr.GetSkillData(skillInfo.resDataPath)
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

--- 获取物品托盘的物品列表
---@return table<number, ArticleInfo>
function UiModel:GetArticleDockInfoList()
    return self.articleDockInfoList
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
    local info = self.articleDockInfoList[index]
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
        local hoveringArticleInfo = self.articleDockInfoList[self.articleDockHoveringItemIndex]

        -- 移动拖拽项到当前悬停处
        local draggingArticleInfo = self.articleDockInfoList[self.articleDockDraggingItemIndex]
        self.articleDockInfoList[self.articleDockHoveringItemIndex] = draggingArticleInfo
        self:Signal_requestSetArticleDockItemInfo(self.articleDockHoveringItemIndex, draggingArticleInfo)

        -- 移动原先悬停处的物品到拖拽之前的位置
        self.articleDockInfoList[self.articleDockDraggingItemIndex] = hoveringArticleInfo
        self:Signal_requestSetArticleDockItemInfo(self.articleDockDraggingItemIndex, hoveringArticleInfo)

        -- 播放物品移动音效
        self:playChangedArticlePosSound()
    end

    -- 请求界面设置拖拽项为不可见
    self:RequestSetDraggingItemVisibility(false)
end

---@param actorIndex int
function UiModel:StartGame(actorIndex)
    if actorIndex <= 0 then
        return
    end
    local actorSimplePath = self.actorSimplePathList[actorIndex]
    self.director.StartGame(actorSimplePath)
end

---@param mapId number
function UiModel:SelectGameMap(mapId)
    local simplePath = self.mapSimplePathList[mapId]
    _MAP.Load(simplePath)
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

    return InputSrv.IsPressed(self.player.input, key)
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
    local LifeSrv = require("actor.service.LifeSrv")
    LifeSrv.RebornEntity(self.player)

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
    -- 1. 读取原始实例配置
    local playerInstanceCfgSimplePath = self.player.Data.path
    local data, path = _RESOURCE.ReadConfig(playerInstanceCfgSimplePath, "config/actor/instance/%s.cfg", nil)
    if data == nil then
        print("UiModel:SavePlayerData()", "origin instance cfg read failed!")
        return
    end
    if data.skills == nil then
        print("UiModel:SavePlayerData()", "origin instance cfg data have nor skills data")
        return
    end
    if data.equipments == nil then
        print("UiModel:SavePlayerData()", "origin instance cfg data have nor equipments data")
        return
    end

    -- 2. 更新技能配置
    data.skills = {}
    local mapOfTagToActorSkillObj = SkillSrv.GetMap(self.player.skills)
    for tag, obj in pairs(mapOfTagToActorSkillObj) do
        if obj then
            data.skills[tag] = obj:GetData().path
        end
    end

    -- 3. 更新装备
    data.equipments = {}
    local mapOfTagToActorEquObj = EquSrv.GetMap(self.player.equipments)
    for tag, obj in pairs(mapOfTagToActorEquObj) do
        if obj then
            data.equipments[tag] = obj:GetData().path
        end
    end

    -- 4. 装载物品项数据
    data.InventoryItems = { List = {} }
    local articleInfoList = self.player.InventoryItems:GetList()
    for _, info in pairs(articleInfoList) do
        if info ~= nil and info.type ~= Common.ArticleType.Empty then
            local item = { Index = info.Index, Count = info.count, Path = info.path }
            table.insert(data.InventoryItems.List, item)
        end
    end

    -- 5. 装载已掌握技能列表数据
    data.MasteredSkills = { List = {} }
    local masteredSkillInfoList = self.player.MasteredSkills:GetList()
    for _, info in pairs(masteredSkillInfoList) do
        local skillData = { Path = "", Exp = 0 };
        skillData.Path = info.resDataPath
        skillData.Exp = info.Exp
        table.insert(data.MasteredSkills.List, skillData)
    end

    -- 6. 序列化数据
    local dataStr = Table.Deserialize(data)

    -- 7. 保存数据
    local dirPath = "config/actor/instance/duelist/"
    local fileName = PlayerCfgSavedFileName .. PlayerCfgSavedFileSuffix
    -- local ok, errMsg = File.WriteFile(dirPath, fileName, dataStr)
    -- if not ok then
    --     print("UiModel:SavePlayerData()", errMsg, dirPath .. fileName, "file write failed！")
    --     return
    -- end
end

function UiModel:GetPlayerInstanceCfgSimplePath()
    local simplePath = "duelist/" .. PlayerCfgSavedFileName
    local pathPrefix = "config/actor/instance/"
    local path = pathPrefix .. simplePath .. ".cfg"

    if not File.Exists(path) then
        simplePath = "duelist/swordman"
    end 
    return simplePath
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

    -- 1、获取设置文件路径
    local settingsFilePath = _CONFIG.ConfigDirPath .. _CONFIG.SettingsFileName
    if not File.Exists(settingsFilePath) then
        settingsFilePath = _CONFIG.ConfigDirPath .. _CONFIG.DefaultSettingsFileName
    end

    -- 2、读取原设置数据
    local content = File.ReadFile(settingsFilePath)
    ---@type CONFIG
    local configData = loadstring(content)()

    -- 3、更新设置数据
    configData.code = _CONFIG.code

    -- 4. 序列化数据
    local dataStr = Table.Deserialize(configData)

    -- 5. 保存数据
    local dirPath = _CONFIG.ConfigDirPath
    local fileName = _CONFIG.SettingsFileName
    local ok, errMsg = File.WriteFile(dirPath, fileName, dataStr)
    if not ok then
        print("UiModel:SaveConfigMapOfFunNameToKey(map)", errMsg, dirPath .. fileName, "file write failed！")
        return
    end

    self:Signal_PlayerMountedSkillsChanged()
end

function UiModel:GetActorSimplePathList()
    return self.actorSimplePathList
end

function UiModel:GetMapSimplePathList()
    return self.mapSimplePathList
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
    local clickedItemInfo = self.articleDockInfoList[index]
    if clickedItemInfo == nil then
        print("UiModel:OnRightKeyClickedArticleDockItem(index)", "err: can not find itemInfo")
        return
    end

    local articleTableIndex = self:findInArticleInfoList(clickedItemInfo)
    if (articleTableIndex.Index == -1) then
        print("UiModel:OnRightKeyClickedArticleDockItem(index)", 
            "err: can not find itemInfo in article table")
        return
    end

    if clickedItemInfo.type == Common.ArticleType.Consumable then
        self:useConsumable(articleTableIndex.Index, clickedItemInfo)
    elseif clickedItemInfo.type == Common.ArticleType.Equipment then
        self:mountEquipment(articleTableIndex.Index, clickedItemInfo)
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
    self:SavePlayerData()

    self:RequestSetArticleTableItemInfo(articleInfo.Index, articleInfo)
end

----------todo
---@param info SkillInfo
function UiModel:Slot_MasteredSkillOfPlayerAdded(info)
    self:SavePlayerData()

    self:Signal_PlayerMasteredSkillAdded(info)
end

---@param info SkillInfo
function UiModel:Slot_MasteredSkillOfPlayerChanged(info)
    self:SavePlayerData()

    self:Signal_PlayerMasteredSkillChanged(info)
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

    local hpRecovery = itemInfo.consumableInfo.hpRecovery
    local playerCurrentHp = self:GetPlayerAttribute(Common.ActorAttributeType.Hp)
    hpRecovery = hpRecovery + playerCurrentHp * itemInfo.consumableInfo.hpRecoveryRate
    if (hpRecovery > 0) then
        self:AddHpWithEffect(self.player, hpRecovery)
    end

    if itemInfo.consumableInfo.SkillPath ~= "" then
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
    -- self:RequestSetArticleTableItemInfo(index, itemInfo)

    -- 更新物品托盘
    local articleDockIndex = self:findInArticleDockInfoList(itemInfo)
    if (articleDockIndex.Index > 0) then
        self:Signal_requestSetArticleDockItemInfo(articleDockIndex.Index, itemInfo)
    end
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

    local lastEquItemInfo = self.mountedEquInfoList[itemInfo.equInfo.type]
    -- 在ui上卸载原有装备到物品栏
    InventoryItemsSrv.InsertItemToEntity(self.player, articleTableIndex,
        lastEquItemInfo.count, lastEquItemInfo.path)

    -- 待装备的物品是否存在于物品托盘，如存在，则更新物品托盘
    local articleDockIndex = self:findInArticleDockInfoList(itemInfo)
    if (articleDockIndex.Index > 0) then
        self.articleDockInfoList[articleDockIndex.Index] = lastEquItemInfo
        self:Signal_requestSetArticleDockItemInfo(articleDockIndex.Index, lastEquItemInfo)
    end

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

--- 在物品列表里查找
---@param findingInfo ArticleInfo
function UiModel:findInArticleInfoList(findingInfo)
    local index = Common.NewArticleInfoItemIndex()
    for i, info in pairs(self.articleInfoList) do
        if (info == findingInfo) then
            index.Index = i
            index.Info = info
            break
        end
    end

    return index
end

--- 在物品托盘的物品列表里查找
---@param findingInfo ArticleInfo
function UiModel:findInArticleDockInfoList(findingInfo)
    local index = Common.NewArticleInfoItemIndex()
    for i, info in pairs(self.articleDockInfoList) do
        if (info == findingInfo) then
            index.Index = i
            index.Info = info
            break
        end
    end

    return index
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

function UiModel:loadActorSimplePathList()
    local actorSimplePathList = {
        "duelist/militia",
        "duelist/Kyo",
        "duelist/atswordman",
        "duelist/Fighter",
        "duelist/goblin",
        "duelist/goblinThrower",
        "duelist/lugaru",
        "duelist/swordman",
        "duelist/tauArmy",
    }
    local playerCfgFilePath = "config/actor/instance/duelist/player.cfg"
    if File.Exists(playerCfgFilePath) then
        table.insert(self.actorSimplePathList, "duelist/player")
    end
    for _, path in pairs(actorSimplePathList) do
        table.insert(self.actorSimplePathList, path)
    end
end

function UiModel:loadMapSimplePathList()
    local fileNameList = File.ListDirectoryItems("config/map/instance")
    for _, fileName in pairs(fileNameList) do
        local fileNameWithoutSuffix = String.RmExtSuffix(fileName)
        table.insert(self.mapSimplePathList, fileNameWithoutSuffix)
    end
end

return UiModel
