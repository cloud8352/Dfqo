--[[
	desc: HopSmash, a state of Swordman.
	author: keke
	since: 2022-9-3
]]--

local _SOUND = require("lib.sound")
local Util = require("util.Util")

local _FACTORY = require("actor.factory")
local _ASPECT = require("actor.service.aspect")
local _STATE = require("actor.service.state")
local _BUFF = require("actor.service.buff")

local _Attack = require("actor.gear.attack")
local _Easemove = require("actor.gear.easemove")
local _Jump = require("actor.gear.jump")
local _Base = require("actor.state.base")

---@class Actor.State.Duelist.Swordman.HopSmash:Actor.State
---@field protected _attack Actor.Gear.Attack
---@field protected _skill Actor.Skill
---@field protected _ticks table
---@field protected _effect Actor.Entity
local _HopSmash = require("core.class")(_Base)

function _HopSmash:Ctor(data, ...)
    _Base.Ctor(self, data, ...)

    self._ticks = data.ticks
    self._easemoveParam = data.easemove
    self._jumpParam = data.jump
end

function _HopSmash:Init(entity, ...)
    _Base.Init(self, entity, ...)

    -- 技能结束时段子弹动作
    self.endBulletEntity = nil

    self._attack = _Attack.New(self._entity)
    self._attack.element = _Attack.AttackElementStruct.Water
    self._easemove = _Easemove.New(self._entity.transform, self._entity.aspect)
    -- 跳跃动作
    self._jump = _Jump.New(self._entity.transform, self._entity.aspect, function(caller, param)
        print("_HopSmash state jump action func excuted! param: " .. param)
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
        end
    end)
end

function _HopSmash:NormalUpdate(dt, rate)
    local main = _ASPECT.GetPart(self._entity.aspect) ---@type Graphics.Drawable.Frameani
    local tick = main:GetTick()

    self._attack:Update()
    self._easemove:Update(rate)
    self._jump:Update(rate)

    if (tick == self._ticks[1]) then
        -- buff
        self._buff = _BUFF.AddBuff(self._entity, self._buffDatas)
    elseif (tick == self._ticks[2]) then
        local param = {
            x = self._entity.transform.position.x,
            y = self._entity.transform.position.y,
            z = self._entity.transform.position.z,
            direction = self._entity.transform.direction,
            entity = self._entity
        }

        if (self.endBulletEntity) then
            self.endBulletEntity.identity.destroyProcess = 1
            self.endBulletEntity = nil
        end
        self.endBulletEntity = _FACTORY.New(self._actorDataSet[1], param)

        -- 攻击
        self:startAttack(self._attackDataSet[1], self._skill.attackValues[1]
        , main)
    elseif (tick == self._ticks[3]) then
    end

    -- 持续播放空中攻击效果
    if (self.endBulletEntity and self.endBulletEntity.identity.destroyProcess == 1) then
        self.endBulletEntity.identity.destroyProcess = 0
    end

    _STATE.AutoPlayEnd(self._entity.states, self._entity.aspect, self._nextState)
end

function _HopSmash:Enter(laterState, skill)
    _Base.Enter(self)

    self._skill = skill
    self._attack:Exit()
    self._easemove:Exit()
    self._jump:Exit()

    self._attack:Exit()

    local enhanceRate = 0
    -- 获取技能准备的时间（注意：单位不是ms）
    local skillPrepareTime = self._skill:GetPrepareTime()
    if (60 > skillPrepareTime) then
        enhanceRate = 0
    else
        enhanceRate = skillPrepareTime / 330
    end
    
    if 0.5 < enhanceRate then
        enhanceRate = 0.5 -- 跳跃和移动最大增幅
    end

    local easemoveParam = self._easemoveParam
    self._easemove:Enter("x", easemoveParam.power * (1 + enhanceRate), easemoveParam.speed, self._entity.transform.direction)

    local jumpParam = self._jumpParam
    self._jump:Enter(jumpParam.power * (1 + enhanceRate * 0.4), jumpParam.speed, 0.7)

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
