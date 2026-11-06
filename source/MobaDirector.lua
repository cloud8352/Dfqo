--[[
	desc: Moba director, the game manager for moba mode.
	author: Keke
]]--

local Common = require("UI.ui_common")
local Ui = require("UI.UI")
local Config = require("config")
local Factory = require("actor.factory")
local Map = require("map.init")

local TableLib = require("lib.table")

local MobaDirector = {}

local Starting = false
---@type DIRECTOR
local Director = nil

---@param director DIRECTOR
function MobaDirector.Init(director)
    Starting = false
    Director = director
end

function MobaDirector.Update(dt)
    if not Starting then
        return
    end
end


---@param actorInfo UserActorInfoStruct
function MobaDirector.Start(actorInfo)
    Starting = true
    if actorInfo == nil then
        return
    end

    -- reset OnceGameTaiSuCount
    Config.user.OnceGameTaiSuCount = 10000

    ---@type Actor.RESMGR.InstanceData
    local dataTmp = TableLib.DeepClone(actorInfo.Data)

    -- clear inventoryItems
    local classTmp = dataTmp.InventoryItems.class
    dataTmp.InventoryItems = {}
    dataTmp.InventoryItems.class = classTmp

    -- reset skills
    for k, v in pairs(dataTmp.skills) do
        if (k ~= "class" and type(v) ~= "boolean") then
            ---@type Actor.RESMGR.SkillData
            local skillResDataTmp = TableLib.DeepClone(v)
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
        x = 200,
        y = 1680,
        direction = 1,
        camp = 1
    })
    Director.FirstUpdate() -- Flush player.

    Config.user:ClearPartnerList()
    Config.user:SetPlayer(player)

    -- self.partnerList = Config.user:GetPartnerList()

    -- moba enemy hero
    Config.user:ClearEnemyHeroList()
    local enemy = Factory.New("duelist/Moba/Hero", {
        x = 8400,
        y = 1660,
        direction = -1,
        camp = 2
    })
    Config.user:AddEnemyHero(enemy)
    
    enemy = Factory.New("duelist/Moba/Hero", {
        x = 8400,
        y = 1700,
        direction = -1,
        camp = 2
    })
    Config.user:AddEnemyHero(enemy)

    -- load map
    local simplePath = "Moba/Moba1"
    Map.Load(simplePath)
end

function MobaDirector.Stop()
    Starting = false
end

return MobaDirector
