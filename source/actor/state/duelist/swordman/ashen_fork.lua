--[[
	desc: AshenFork, a state of Swordman.
]]--

local _SOUND = require("lib.sound")
local _TABLE = require("lib.table")
local _FACTORY = require("actor.factory")
local _RESMGR = require("actor.resmgr")
local _ASPECT = require("actor.service.aspect")
local _STATE = require("actor.service.state")
local _INPUT = require("actor.service.input")
local _EQUIPMENT = require("actor.service.equipment")
local _BUFF = require("actor.service.buff")
local _EFFECT = require("actor.service.effect")
local _MOTION = require("actor.service.motion")
local _TIME = require("lib.time")

local _Easemove = require("actor.gear.easemove")
local _Attack = require("actor.gear.attack")
local _Base = require("actor.state.base")

---@class Actor.State.Duelist.Swordman.UpperSlash:Actor.State
---@field protected attack Actor.Gear.Attack
---@field protected _skill Actor.Skill
---@field protected _effect Actor.Entity
---@field protected _easemoveTick int
---@field protected _easemoveParams table
---@field protected _easemove Actor.Gear.Easemove
---@field protected hitstopMap table
---@field protected _effectTick int
---@field protected _cutTime int
---@field protected _line int
---@field protected buff Actor.Buff
---@field protected _ascend boolean
---@field protected _breaking boolean
---@field protected _process int
---@field protected _figureData Lib.RESOURCE.SpriteData
local AshenFork = require("core.class")(_Base)

local AttackJudgeIntervalS = 0.7

---@param attack Actor.Gear.Attack
---@param entity Actor.Entity
local function _Collide(attack, entity)
    local isdone, x, y, z = _Attack.DefaultCollide(attack, entity)

    if (isdone) then
        return isdone, x, y, z, _, _, entity.battle.banCountMap.flight > 0
    end

    return false
end

function AshenFork:Ctor(data, ...)
    _Base.Ctor(self, data, ...)

    self.hitstopMap = data.hitstop
end

function AshenFork:Init(entity)
    _Base.Init(self, entity)


    self.originTImeS = 0
    self.nextAttackTimeS = 0
    self.originZ = 0
    self.buff = nil

    self.attack = _Attack.New(self._entity)
    self.xEasemove = _Easemove.New(self._entity.transform, self._entity.aspect)
    self.zEasemove = _Easemove.New(self._entity.transform, self._entity.aspect)
end

function AshenFork:NormalUpdate(dt, rate)
    self.attack:Update(dt)
    self.xEasemove:Update(rate)
    self.zEasemove:Update(rate)

    if self._entity.transform.position.z - self.originZ > 120 then
        -- buff
        if self.buff == nil then
            self.buff = _BUFF.AddBuff(self._entity, self._buffDatas)
        end
    end

    if self._entity.transform.position.z < 0 then
        _ASPECT.Play(self._entity.aspect, self._frameaniDataSets[1])
    elseif self._entity.transform.position.z > 0 then
        self.xEasemove:Exit()
        self.zEasemove:Exit()

        self._entity.transform.position.z = 0
        self._entity.transform.positionTick = true

        -- 震荡波
        local param = {
            x = self._entity.transform.position.x,
            y = self._entity.transform.position.y,
            z = self._entity.transform.position.z,
            direction = self._entity.transform.direction,
            entity = self._entity
        }

        local skillAttackValues = {
            {
                damageRate = 0.5,
                isPhysical = true
            }
        }

        local endOnGroundBulletEntity = _FACTORY.New(self._actorDataSet[1], param)
        self.attack:Enter(self._attackDataSet[1], skillAttackValues[1], _, _, true)
        self.attack.collision[_ASPECT.GetPart(endOnGroundBulletEntity.aspect)] = "attack"

        _SOUND.Play(self._soundDataSet.effect)
    end

    -- 每隔 AttackJudgeIntervalS 时间 攻击一次
    if _TIME.GetTime() - self.originTImeS > self.nextAttackTimeS and
       self.attack.isRunning == false then
        self:EnterAttack()
        self.nextAttackTimeS = self.nextAttackTimeS + AttackJudgeIntervalS
    end

    _STATE.AutoPlayEnd(self._entity.states, self._entity.aspect, self._nextState)
end

function AshenFork:Enter(laterState, skill)
    -- print("AshenFork:Enter()")
    self.originTImeS = _TIME.GetTime()
    self.nextAttackTimeS = 0
    self.originZ = self._entity.transform.position.z
    self.buff = nil

    self.attack:Exit()
    self.xEasemove:Exit()
    self.zEasemove:Exit()


    _ASPECT.Play(self._entity.aspect, self._frameaniDataSets[1])
    self.xEasemove:Enter("x", 6, 0, self._entity.transform.direction)
    self.zEasemove:Enter("z", 0, -2.5, 1)
end

function AshenFork:Exit(nextState)
    if (nextState == self) then
        return
    end
    
    _Base.Exit(self, nextState)

    if (self.buff) then
        self.buff:Exit()
    end

    self.attack:Exit()
    self.xEasemove:Exit()
    self.zEasemove:Exit()
end

function AshenFork:EnterAttack()
    local skillAttackValues = {
        {
            damageRate = 0.5,
            isPhysical = true
        }
    }

    self.attack:Enter(self._attackDataSet[1], skillAttackValues[1], _)

    local kind = _EQUIPMENT.GetSubKind(self._entity.equipments, "weapon")
    local hitstop = self.hitstopMap[kind]
    self.attack.hitstop = hitstop[1]
    self.attack.selfstop = hitstop[2]
    self.attack.shake.time = hitstop[1]

    -- local soundDatas = self._soundDataSet.hitting[kind]
    -- self._attack.soundDataSet[#self._attack.soundDataSet + 1] = soundDatas
end

return AshenFork

