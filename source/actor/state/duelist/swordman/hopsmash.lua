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

    self.enhanceRate = 0.0

    self.endBulletEntity = nil  -- 技能结束时段子弹动作

    -- 攻击子弹实例
    self.bottomBulletEntity = nil
    self.bottomBulletEffectList = {}

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
            self._attack:Enter(self._attackDataSet[2], self._skill.attackValues[2], _, _, true)
            self._attack.collision[_ASPECT.GetPart(endOnGroundBulletEntity.aspect)] = "attack"

            -- 先销毁原来的地面血气波动攻击子弹实例
            if (self.bottomBulletEntity) then
                self.bottomBulletEntity.identity.destroyProcess = 1
            end
            -- 创建的地面血气波动攻击子弹实例
            self.bottomBulletEntity = _FACTORY.New(self._actorDataSet[7], param)

            -- 销毁地面血气波动特效
            for i, entity in pairs(self.bottomBulletEffectList) do
                if (entity) then
                    entity.identity.destroyProcess = 1
                end
            end
            self.bottomBulletEffectList = {}
            -- 创建地面血气波动特效
            self.bottomBulletEffectList[1] = _FACTORY.New(self._actorDataSet[3], param)
            self.bottomBulletEffectList[2] = _FACTORY.New(self._actorDataSet[4], param)
            self.bottomBulletEffectList[3] = _FACTORY.New(self._actorDataSet[5], param)
            self.bottomBulletEffectList[4] = _FACTORY.New(self._actorDataSet[6], param)

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
        self._attack:Enter(self._attackDataSet[1], self._skill.attackValues[1], _, _, true)
        self._attack.collision[_ASPECT.GetPart(self.endBulletEntity.aspect)] = "attack"
    elseif (tick == self._ticks[3]) then
    end

    -- 第三段攻击
    if (self.bottomBulletEntity) then
        local bulletFrameani = _ASPECT.GetPart(self.bottomBulletEntity.aspect) ---@type Graphics.Drawable.Frameani
        local bulletTick = bulletFrameani:GetTick()
        if (3 == bulletTick) then
            self._attack:Enter(self._attackDataSet[2], self._skill.attackValues[2], _, _, true)
            self._attack.collision[bulletFrameani] = "attack"
        end
    end

    _STATE.AutoPlayEnd(self._entity.states, self._entity.aspect, self._nextState)
end

function _HopSmash:Enter(laterState, skill)
    _Base.Enter(self)

    self._skill = skill
    self._attack:Exit()
    self._easemove:Exit()
    self._jump:Exit()

    -- 获取技能准备的时间（注意：单位不是ms）
    local skillPrepareTime = self._skill:GetPrepareTime()
    if (60 > skillPrepareTime) then
        self.enhanceRate = 0
    else
        self.enhanceRate = skillPrepareTime / 150
    end
    
    if 1 < self.enhanceRate then
        self.enhanceRate = 1 -- 跳跃和移动最大增幅
    end
    local enhanceBaseRate = 0.7 -- 基准增幅率（用来确保增幅率始终不超过此值）
    self.enhanceRate = self.enhanceRate * enhanceBaseRate

    local easemoveParam = self._easemoveParam
    self._easemove:Enter("x", easemoveParam.power * (1 + self.enhanceRate), easemoveParam.speed, self._entity.transform.direction)

    local jumpParam = self._jumpParam
    self._jump:Enter(jumpParam.power * (1 + self.enhanceRate), jumpParam.speed, jumpParam.speed * 0.3)

    Util.PlaySoundByGender(self._soundDataSet, 1, self._entity.identity.gender)
end

function _HopSmash:Exit(nextState)
    if (nextState == self) then
        return
    end
    
    _Base.Exit(self, nextState)

    if (self.bottomBulletEntity) then
        self.bottomBulletEntity.identity.destroyProcess = 1
        self.bottomBulletEntity = nil
    end

    -- 销毁地面血气波动特效
    for i, entity in pairs(self.bottomBulletEffectList) do
        if (entity) then
            entity.identity.destroyProcess = 1
        end
    end
    self.bottomBulletEffectList = {}

    if (self._buff) then
        self._buff:Exit()
    end

    if (self.endBulletEntity) then
        self.endBulletEntity.identity.destroyProcess = 1
        self.endBulletEntity = nil
    end

end

return _HopSmash
