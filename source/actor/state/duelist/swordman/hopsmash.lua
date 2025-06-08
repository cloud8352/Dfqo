--[[
	desc: HopSmash, a state of Swordman.
	author: keke
	since: 2022-9-3
]]--

local _Base = require("actor.state.base")

local _SOUND = require("lib.sound")
local Util = require("util.Util")
local _FACTORY = require("actor.factory")
local _ASPECT = require("actor.service.aspect")
local _STATE = require("actor.service.state")
local _BUFF = require("actor.service.buff")
local _Attack = require("actor.gear.attack")
local EaseMove = require("actor.gear.easemove")
local InputSrv = require("actor.service.input")

---@class Actor.State.Duelist.Swordman.HopSmash : Actor.State
---@field protected _attack Actor.Gear.Attack
---@field protected _skill Actor.Skill
---@field protected _ticks table
---@field protected _effect Actor.Entity
local _HopSmash = require("core.class")(_Base)

---@enum HopSmashStateProcessEnum
local ProcessEnum = {
    Up = 1,
    HoldUp = 2,
    Down = 3,
    HoldDown = 4,
    End = 5
}

local OriTimeMsNeedUp = 40
local OriTimeMsNeedHoldUp = 40

function _HopSmash:Ctor(data, ...)
    _Base.Ctor(self, data, ...)
end

function _HopSmash:Init(entity, ...)
    _Base.Init(self, entity, ...)

    -- 技能结束时段子弹动作
    self.endBulletEntity = nil

    self._attack = _Attack.New(self._entity)
    self._attack.element = _Attack.AttackElementStruct.Water
    self.easeMoveX = EaseMove.New(self._entity.transform, self._entity.aspect)
    self.easeMoveZ = EaseMove.New(self._entity.transform, self._entity.aspect)

    self.canMoveXWhenKeyPressing = true

    ---@type int
    self.process = ProcessEnum.Up
    self.timeMsNeedUp = OriTimeMsNeedUp
    self.timeMsNeedHoldUp = OriTimeMsNeedHoldUp
end

function _HopSmash:NormalUpdate(dt, rate)
    local main = _ASPECT.GetPart(self._entity.aspect) ---@type Graphics.Drawable.Frameani

    self._attack:Update()
    self.easeMoveX:Update(rate)
    self.easeMoveZ:Update(rate)

    -- 持续播放空中攻击效果
    if (self.endBulletEntity and self.endBulletEntity.identity.destroyProcess == 1) then
        self.endBulletEntity.identity.destroyProcess = 0
    end

    if InputSrv.IsReleased(self._entity.input, self._skill:GetKey()) then
        self.canMoveXWhenKeyPressing = false
        if self.process == ProcessEnum.Up
            or self.process == ProcessEnum.HoldUp
        then
            local xPower = self.easeMoveX:GetPower()
            self.easeMoveX:Enter("x", xPower, 1, self._entity.transform.direction)
        end
    end

    if self.process == ProcessEnum.Up then
        _ASPECT.Play(self._entity.aspect, self._frameaniDataSets.Up)
        if self.timeMsNeedUp < 0 then
            self.process = ProcessEnum.HoldUp
        end
        self.timeMsNeedUp = self.timeMsNeedUp - dt
    end
    if self.process == ProcessEnum.HoldUp then
        _ASPECT.Play(self._entity.aspect, self._frameaniDataSets.HoldUp)
        if self.timeMsNeedHoldUp < 0 then
            self.process = ProcessEnum.Down
            self._buff = _BUFF.AddBuff(self._entity, self._buffDatas)
            _ASPECT.Play(self._entity.aspect, self._frameaniDataSets.Down)

            self.easeMoveZ:Enter("z", 0, -1.3, 1)
        end
        self.timeMsNeedHoldUp = self.timeMsNeedHoldUp - dt
    end

    if self.process == ProcessEnum.Down
        and main:TickEnd()
    then
        self.process = ProcessEnum.HoldDown
        self.easeMoveX:SetPower(1)
    end

    if self.process == ProcessEnum.HoldDown
    then
        _ASPECT.Play(self._entity.aspect, self._frameaniDataSets.HoldDown)
        if self.endBulletEntity == nil then
            local param = {
                x = self._entity.transform.position.x,
                y = self._entity.transform.position.y,
                z = self._entity.transform.position.z,
                direction = self._entity.transform.direction,
                entity = self._entity
            }
            self.endBulletEntity = _FACTORY.New(self._actorDataSet[1], param)
    
            -- 攻击
            self:startAttack(self._attackDataSet[1], self._skill.attackValues[1]
            , main)
        end
    end

    if self.process == ProcessEnum.HoldDown 
        and self._entity.transform.position.z >= 0
    then
        self._entity.transform.position.z = 0
        self._entity.transform.positionTick = 1
        self.easeMoveX:Exit()
        self.easeMoveZ:Exit()

        self.process = ProcessEnum.End

        -- 先销毁原来的攻击子弹实例
        if (self.endBulletEntity) then
            self.endBulletEntity.identity.destroyProcess = 1
            self.endBulletEntity = nil
        end
        _ASPECT.Play(self._entity.aspect, self._frameaniDataSets.End)
        self:createEndEffect()
    end

    if self.process == ProcessEnum.Up
        or self.process == ProcessEnum.HoldUp
    then
        if InputSrv.IsHold(self._entity.input, self._skill:GetKey())
            and self.canMoveXWhenKeyPressing
        then
            self.timeMsNeedHoldUp = self.timeMsNeedHoldUp + 11
        end
    end

    if self.process == ProcessEnum.End then
        _STATE.AutoPlayEnd(self._entity.states, self._entity.aspect, self._nextState)
    end
end

function _HopSmash:Enter(lastState, skill)
    _Base.Enter(self)

    self._skill = skill
    self._attack:Exit()
    self.easeMoveX:Exit()
    self.easeMoveZ:Exit()
    self._attack:Exit()

    self.canMoveXWhenKeyPressing = true
    self.timeMsNeedUp = 40
    self.timeMsNeedHoldUp = 40

    self.process = ProcessEnum.Up
    _ASPECT.Play(self._entity.aspect, self._frameaniDataSets.Up)

    self.easeMoveX:Enter("x", 11, 0, self._entity.transform.direction)
    self.easeMoveZ:Enter("z", 10, 0, -1)
    Util.PlaySoundByGender(self._soundDataSet, 1, self._entity.identity.gender)
end

function _HopSmash:Exit(nextState)
    if (nextState == self) then
        return
    end
    
    _Base.Exit(self, nextState)

    if (self._buff) then
        self._buff:Exit()
    end

    if (self.endBulletEntity) then
        self.endBulletEntity.identity.destroyProcess = 1
        self.endBulletEntity = nil
    end
end

---@param attackData table
---@param attackValue Actor.Gear.Attack.AttackValue
---@param attackFrameAni Graphics.Drawable.Frameani
function _HopSmash:startAttack(attackData, attackValue, attackFrameAni)
    self._attack:Enter(attackData, attackValue, _, _, true)
    self._attack.collision[attackFrameAni] = "attack"
end

function _HopSmash:createEndEffect()
    -- 落到地面后攻击
    local param = {
        x = self._entity.transform.position.x,
        y = self._entity.transform.position.y,
        z = self._entity.transform.position.z,
        direction = self._entity.transform.direction,
        entity = self._entity,
        attackValue = {
            damageRate = 2.01,
            isPhysical = false
        }
    }

    -- 武器刚接触地面子弹实例
    local endOnGroundBulletEntity = _FACTORY.New(self._actorDataSet[2], param)
    -- 攻击
    self:startAttack(self._attackDataSet[2], self._skill.attackValues[2]
    , _ASPECT.GetPart(endOnGroundBulletEntity.aspect))

    -- 创建的地面血气波动攻击子弹实例
    local bottomBulletEntity = _FACTORY.New(self._actorDataSet[7], param)

    local bottomBulletEffectList = {}
    -- 创建地面血气波动特效
    bottomBulletEffectList[1] = _FACTORY.New(self._actorDataSet[3], param)
    bottomBulletEffectList[2] = _FACTORY.New(self._actorDataSet[4], param)
    bottomBulletEffectList[3] = _FACTORY.New(self._actorDataSet[5], param)
    bottomBulletEffectList[4] = _FACTORY.New(self._actorDataSet[6], param)

    _SOUND.Play(self._soundDataSet.swing)
end

return _HopSmash
