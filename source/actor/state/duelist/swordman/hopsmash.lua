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
local _Jump = require("actor.gear.jump")
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
    UpHold = 2,
    Down = 3,
    DownHold = 4,
    End = 5
}

function _HopSmash:Ctor(data, ...)
    _Base.Ctor(self, data, ...)
end

function _HopSmash:Init(entity, ...)
    _Base.Init(self, entity, ...)

    -- 技能结束时段子弹动作
    self.endBulletEntity = nil

    self._attack = _Attack.New(self._entity)
    self._attack.element = _Attack.AttackElementStruct.Water
    self.oriEaseMoveX = EaseMove.New(self._entity.transform, self._entity.aspect)
    self.easeMoveX = EaseMove.New(self._entity.transform, self._entity.aspect)
    self.easeMoveZ = EaseMove.New(self._entity.transform, self._entity.aspect)

    self.canMoveXWhenKeyPressing = true

    ---@type int
    self.process = ProcessEnum.Up
    -- 跳跃动作
    self._jump = _Jump.New(self._entity.transform, self._entity.aspect, function(caller, param)
        print("_HopSmash state jump action func excuted! param: " .. param)
        if _Jump.ProcessEnum.Up2 == param then
            self.process = ProcessEnum.UpHold
        end
        if _Jump.ProcessEnum.Down1 == param then
            self.process = ProcessEnum.Down
            self._buff = _BUFF.AddBuff(self._entity, self._buffDatas)
            _ASPECT.Play(self._entity.aspect, self._frameaniDataSets.Down)
        end


        if _Jump.ProcessEnum.Ground == param then
            print("ground attack")

            -- 先销毁原来的攻击子弹实例
            if (self.endBulletEntity) then
                self.endBulletEntity.identity.destroyProcess = 1
                self.endBulletEntity = nil
            end

            -- 落到地面后攻击
            local param = {
                x = self._entity.transform.position.x,
                y = self._entity.transform.position.y,
                z = self._entity.transform.position.z,
                direction = self._entity.transform.direction,
                entity = self._entity
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

            self.process = ProcessEnum.End
            _ASPECT.Play(self._entity.aspect, self._frameaniDataSets.End)

            self.oriEaseMoveX:Exit()
            self.easeMoveX:Exit()
        end
    end)
end

function _HopSmash:NormalUpdate(dt, rate)
    local main = _ASPECT.GetPart(self._entity.aspect) ---@type Graphics.Drawable.Frameani

    self._attack:Update()
    self.oriEaseMoveX:Update(rate)
    self.easeMoveX:Update(rate)
    self.easeMoveZ:Update(rate)
    self._jump:Update(rate)

    -- 持续播放空中攻击效果
    if (self.endBulletEntity and self.endBulletEntity.identity.destroyProcess == 1) then
        self.endBulletEntity.identity.destroyProcess = 0
    end

    if InputSrv.IsReleased(self._entity.input, self._skill:GetKey()) then
        self.canMoveXWhenKeyPressing = false
    end

    if self.process == ProcessEnum.Up then
        _ASPECT.Play(self._entity.aspect, self._frameaniDataSets.Up)
    end
    if self.process == ProcessEnum.UpHold then
        _ASPECT.Play(self._entity.aspect, self._frameaniDataSets.UpHold)
    end

    if self.process == ProcessEnum.Down
        and main:TickEnd()
    then
        self.process = ProcessEnum.DownHold
        -- self.oriEaseMoveX:Exit()
        -- self.easeMoveX:Exit()
    end

    if self.process == ProcessEnum.DownHold
    then
        _ASPECT.Play(self._entity.aspect, self._frameaniDataSets.DownHold)
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

    if self.process == ProcessEnum.Up
        or self.process == ProcessEnum.UpHold
    then
        if InputSrv.IsHold(self._entity.input, self._skill:GetKey())
            and self.canMoveXWhenKeyPressing
        then
            self.easeMoveZ:Enter("z", 5, 0.8, -1)
            self.easeMoveX:Enter("x", 7, 0.8, self._entity.transform.direction)
    
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
    self.oriEaseMoveX:Exit()
    self.easeMoveX:Exit()
    self.easeMoveZ:Exit()
    self._jump:Exit()
    self._attack:Exit()

    self.canMoveXWhenKeyPressing = true

    self.process = ProcessEnum.Start
    _ASPECT.Play(self._entity.aspect, self._frameaniDataSets.Up)

    self.oriEaseMoveX:Enter("x", 4, 0.1, self._entity.transform.direction)
    self._jump:Enter(11.5, 1, 1)
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

return _HopSmash
