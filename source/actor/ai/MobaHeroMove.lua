--[[
	desc: MobaHeroMove, a moving Ai of Moba hero.
	author: keke
    1、存有上中下路各塔坐标；
    2、从基地出发时，去没有队友的那条路；
    3、战斗力评分：技能总级数*血量
    4、血量低于50%时回城恢复；
    5、自身战斗力高于附近敌方所有英雄战斗力之和的20%，则向附近敌方英雄发起攻击；
    6、需加点技能的列表，只使用资源列表中技能进行升级；
    7、附近有己方单位，血量大于50%时都可进攻，否则退回附近安全区；

]]--


local _ECSMGR = require("actor.ecsmgr")
local _BATTLE = require("actor.service.battle")
local _INPUT = require("actor.service.input")
local _STATE = require("actor.service.state")
local Map = require("map.init")
local MasteredSkillsSrv = require("actor.service.MasteredSkillsSrv")

local _Timer = require("util.gear.timer")
local _Point = require("graphics.drawunit.point")
local _Range = require("graphics.drawunit.range")
local _Move = require("actor.ai.move")
local _Base = require("actor.ai.base")

local TimeLib = require("lib.time")

local _list = _ECSMGR.NewComboList({
    battle = true,
    transform = true
})

---@class Actor.Ai.MobaHeroMove : Actor.Ai
---@field public searchRange Graphics.Drawunit.Range
---@field public moveRange Graphics.Drawunit.Range
---@field public intervalSection Graphics.Drawunit.Point
---@field public lockOn boolean
---@field public navigating boolean
---@field public camp int
---@field protected _target Graphics.Drawunit.Point
---@field protected _timer Util.Gear.Timer
---@field protected _moveAi Actor.Ai.Move
---@field protected _hasTarget boolean
local MobaHeroMove = require("core.class")(_Base)

---@param entity Actor.Entity
---@param data table
function MobaHeroMove.NewWithConfig(entity, data)
    return MobaHeroMove.New(entity, data)
end

---@param entity Actor.Entity
---@param data table
function MobaHeroMove:Ctor(entity, data)
    _Base.Ctor(self, entity)

    self.timer = _Timer.New()
    self.targetPoint = _Point.New(true)
    self.moveAi = _Move.New(entity)
    self.camp = data.camp

    ---@type table<int, Graphics.Drawunit.Point>
    self.UpperRoadSteps = {}
    if data.UpperRoadSteps then
        for _, v in pairs(data.UpperRoadSteps) do
            local point = _Point.New(true, v[1], v[2])
            table.insert(self.UpperRoadSteps, point)
        end
    end
    ---@type table<int, Graphics.Drawunit.Point>
    self.MiddleRoadSteps = {}
    if data.MiddleRoadSteps then
        for _, v in pairs(data.MiddleRoadSteps) do
            local point = _Point.New(true, v[1], v[2])
            table.insert(self.MiddleRoadSteps, point)
        end
    end
    ---@type table<int, Graphics.Drawunit.Point>
    self.LowerRoadSteps = {}
    if data.LowerRoadSteps then
        for _, v in pairs(data.LowerRoadSteps) do
            local point = _Point.New(true, v[1], v[2])
            table.insert(self.LowerRoadSteps, point)
        end
    end
    -- self.currentRoadLine = 0 -- 0 - 上；1 - 中；2 - 下
    ---@type table<int, Graphics.Drawunit.Point>
    self.currentRoadSteps = {}
    self.goingForward = false
    ---@type Graphics.Drawunit.Point
    self.nextStepPoint = nil

    -- self.mainHall
    -- self.birthplacePos = _Point.New(true, 150, 330)

    ---@type table<int, Actor.Entity>
    self.partnerList = {}

    ---@type table<int, string>
    self.canBeEnhancedSkillConfigPathList = {}

    self.backingToHome = false

    ----- test
    self.currentRoadSteps = self.UpperRoadSteps
    self.nextStepIndex = 2
end

function MobaHeroMove:Update(dt)
    if (not self:CanRun()) then
        return
    end

    self.timer:Update(dt)

    while (not self.timer.isRunning) do
        self.timer:Enter(1000)

        self.goingForward = false

        -- 回城中，血量低于80%时，继续回城
        if self.backingToHome and self._entity.attributes.hp / self._entity.attributes.maxHp < 0.8 then
            if self:haveMeArriveAtNextStepPoint() and self.nextStepIndex > 1 then
                self.nextStepIndex = self.nextStepIndex - 1
            end
            break
        end

        self.backingToHome = false

        -- -- 如果被敌方塔攻击，则停止攻击并逃离敌方塔
        local beatenRecently = TimeLib.GetTime() - self._entity.battle.beatenConfig.time < 2
        local entityAttackingMe = self._entity.battle.beatenConfig.entity
        local turretEntity = self:getNearbyTurret()
        if beatenRecently and entityAttackingMe and entityAttackingMe.duelist 
            and entityAttackingMe.duelist.category == "TurretBullet"
            and turretEntity
        then
            self:escapeFromTurret(turretEntity)
            break
        end

        -- 当附近存在敌方塔，但无友方单位时，则逃离敌方塔
        if turretEntity and false == self:areThereFriendlyUnitsAroundTurret(turretEntity) then
            self:escapeFromTurret(turretEntity)
            break
        end

        -- 血量低于50%时回城恢复
        if self._entity.attributes.hp / self._entity.attributes.maxHp < 0.5 then
            self.backingToHome = true
        end

        if self.backingToHome then
            if self:haveMeArriveAtNextStepPoint() and self.nextStepIndex > 1 then
                self.nextStepIndex = self.nextStepIndex - 1
            end
            break
        end

        ---@type Actor.Entity
        local target = self:searchAttackTarget()
        if target then
            self._hasTarget = true
            local targetX, targetY = target.transform.position:Get()
            local entityXPos, entityYPos = self._entity.transform.position:Get()
            if math.abs(entityXPos - targetX) > 50 or math.abs(entityYPos - targetY) > 20 then
                self.targetPoint:Set(targetX + 100, targetY)
                self.moveAi:Tick(targetX + 100, targetY)
            end
            break
        end
        
        self.goingForward = true
        if self:haveMeArriveAtNextStepPoint() and self.nextStepIndex < #self.currentRoadSteps then
            self.nextStepIndex = self.nextStepIndex + 1
        end

        break
    end

    self.moveAi:Update(dt)

    if self.goingForward and not self.moveAi:IsRunning() then
        local point = self.currentRoadSteps[self.nextStepIndex]
        self:MoveTo(point.x, point.y)
    end

    if self.backingToHome and not self.moveAi:IsRunning() then
        local point = self.currentRoadSteps[self.nextStepIndex]
        self:MoveTo(point.x, point.y)
    end
end

---@param x int
---@param y int
---@param isOnly boolean
---@param lockOn boolean
function MobaHeroMove:MoveTo(x, y, isOnly, lockOn)
    self.targetPoint:Set(x, y)
    if self:haveMeArriveAtNextStepPoint() then
        return
    end

    self.moveAi:Tick(x, y)

    if (isOnly) then
        self.timer:Exit()
        self.navigating = true
    end

    self._hasTarget = lockOn or false
end

---@return boolean
function MobaHeroMove:IsMoving()
    return self.moveAi:IsRunning()
end

---@param isReal boolean @moveAi's target
---@return int, int
function MobaHeroMove:GetTarget(isReal)
    if (isReal) then
        return self.moveAi:GetTarget()
    end

    return self.targetPoint:Get()
end

---@return boolean
function MobaHeroMove:CanRun()
    local free = (self._entity.states and _STATE.HasTag(self._entity.states, "moveable")) or not self._entity.states
    return _Base.CanRun(self) and free
end

---@return Actor.Entity
function MobaHeroMove:searchAttackTarget()
    local camp = self.camp or self._entity.battle.camp

    -- 自身战斗力高于附近敌方所有英雄战斗力之和的20%，则向附近敌方战力最小的英雄发起攻击
    -- 判断是否存在可以攻击的英雄
    -- 战斗力评分：技能总级数*血量
    local myStrength = MasteredSkillsSrv.GetTotalLevels(self._entity.MasteredSkills) * self._entity.attributes.hp
    local searchRangeX = 200
    local searchRangeY = 150
    local minStrengthEnemyHero = nil
    local enemyHeroMinStrength = 0
    local enemyHeroTotalStrength = 0
    for n = _list:GetLength(), 1, -1 do
        local e = _list:Get(n) ---@type Actor.Entity
        if nil == e.MasteredSkills then
            goto continue
        end
        if e.battle == nil or self._entity == e or e.battle.banCountMap.hide == 1
            or false == _BATTLE.CondCamp(camp, e.battle.camp, "enemy")
        then
            -- 如果不是敌人，则忽略
            goto continue
        end
        local ePos = e.transform.position
        local myPos = self._entity.transform.position
        if math.abs(ePos.x - myPos.x) > searchRangeX or
            math.abs(ePos.y - myPos.y) > searchRangeY
        then
            goto continue
        end

        local eStrength = MasteredSkillsSrv.GetTotalLevels(e.MasteredSkills) * e.attributes.hp
        if enemyHeroMinStrength == 0 
            or eStrength < enemyHeroMinStrength
        then
            enemyHeroMinStrength = eStrength
            minStrengthEnemyHero = e
        end
        enemyHeroTotalStrength = enemyHeroTotalStrength + eStrength

        ::continue::
    end

    if minStrengthEnemyHero and myStrength > enemyHeroTotalStrength * 1.2 then
        return minStrengthEnemyHero
    end
    ---- end - 判断是否存在可以攻击的英雄

    ---- 判断 是否存在可以攻击的普通敌人
    ---@type Actor.Entity
    local nearestEnemy = nil
    local nearestDistance = 0
    for n = _list:GetLength(), 1, -1 do
        local e = _list:Get(n) ---@type Actor.Entity
        if e.battle == nil or self._entity == e or e.battle.banCountMap.hide == 1
            or false == _BATTLE.CondCamp(camp, e.battle.camp, "enemy")
        then
            -- 如果不是敌人，则忽略
            goto continue
        end

        local ePos = e.transform.position
        local myPos = self._entity.transform.position
        local distance = (ePos.x - myPos.x) ^ 2 + (ePos.y - myPos.y) ^ 2 + (ePos.z - myPos.z) ^ 2
        if 0 == nearestDistance
            or distance < nearestDistance
        then
            nearestDistance = distance
            nearestEnemy = e
        end

        ::continue::
    end
    
    return nearestEnemy
end

function MobaHeroMove:haveMeArriveAtNextStepPoint()
    local myPos = self._entity.transform.position
    local nextStepPoint = self.currentRoadSteps[self.nextStepIndex]

    -- 16为地图矩阵单元长宽
    if math.abs(myPos.x - nextStepPoint.x) > 16 or math.abs(myPos.y - nextStepPoint.y) > 16 then
        return false
    end

    return true
end

function MobaHeroMove:getNearbyTurret()
    local camp = self.camp or self._entity.battle.camp
    local myPos = self._entity.transform.position

    for n = _list:GetLength(), 1, -1 do
        local e = _list:Get(n) ---@type Actor.Entity
        if e.battle == nil or self._entity == e or e.battle.banCountMap.hide == 1
            or false == _BATTLE.CondCamp(camp, e.battle.camp, "enemy")
        then
            -- 如果不是敌人，则忽略
            goto continue
        end

        local ePos = e.transform.position
        if math.abs(ePos.x - myPos.x) < 250 and math.abs(ePos.y - myPos.y) < 250 then
            return e
        end

        ::continue::
    end

    return nil
end

---@param turretEntity Actor.Entity
function MobaHeroMove:escapeFromTurret(turretEntity)
    local myOriPos = self.currentRoadSteps[1]
    local turretEntityPos = turretEntity.transform.position
    local moveToX = 0
    local moveToY = self._entity.transform.position.y
    if myOriPos.x > turretEntityPos.x then
        moveToX = turretEntityPos.x + 240
    else
        moveToX = turretEntityPos.x - 240
    end

    self:MoveTo(moveToX, moveToY)
end

---@param turretEntity Actor.Entity
function MobaHeroMove:areThereFriendlyUnitsAroundTurret(turretEntity)
    local camp = self.camp or self._entity.battle.camp
    local turretEntityPos = turretEntity.transform.position

    for n = _list:GetLength(), 1, -1 do
        local e = _list:Get(n) ---@type Actor.Entity
        if e.battle == nil or self._entity == e or e.battle.banCountMap.hide == 1
            or false == _BATTLE.CondCamp(camp, e.battle.camp, "same")
        then
            -- 如果不是友方单位，则忽略
            goto continue
        end

        local ePos = e.transform.position
        if math.abs(ePos.x - turretEntityPos.x) < 210 and math.abs(ePos.y - turretEntityPos.y) < 210 then
            return true
        end

        ::continue::
    end

    return false
end

return MobaHeroMove
