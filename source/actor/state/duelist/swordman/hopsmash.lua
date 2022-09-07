--[[
	desc: HopSmash, a state of Swordman.
	author: keke
	since: 2022-9-3
]]--

local _SOUND = require("lib.sound")
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

    -- 攻击子弹实例
    self.bulletEntity = nil
end

function _HopSmash:Init(entity, ...)
    _Base.Init(self, entity, ...)

    self.entityFrameaniOriDelayList = {} -- 实体动作原始延时列表

    self._attack = _Attack.New(self._entity)
    self._easemove = _Easemove.New(self._entity.transform, self._entity.aspect)
    -- 跳跃动作
    self._jump = _Jump.New(self._entity.transform, self._entity.aspect, function (caller, param)
        print("_UpperSlash state jump action func excuted! param: "..param)
        if 3 == param then
            print("ground attack")
            -- 落到地面后攻击
            local param = {
                x = self._entity.transform.position.x,
                y = self._entity.transform.position.y,
                z = self._entity.transform.position.z,
                direction = self._entity.transform.direction,
                entity = self._entity
            }
            
            local effect1 = _FACTORY.New(self._actorDataSet[1], param)
            local effect2 = _FACTORY.New(self._actorDataSet[2], param)
            local effect3 = _FACTORY.New(self._actorDataSet[3], param)
            local effect4 = _FACTORY.New(self._actorDataSet[4], param)

            -- 先销毁原来的攻击子弹实例
            if (self.bulletEntity) then
                self.bulletEntity.identity.destroyProcess = 1
            end
            self.bulletEntity = _FACTORY.New(self._actorDataSet[5], param)

            self._attack:Enter(self._attackDataSet[2], self._skill.attackValues[2], _, _, true)
            self._attack.collision[_ASPECT.GetPart(self.bulletEntity.aspect)] = "attack"

            _SOUND.Play(self._soundDataSet.swing)
        end
    end)

    ---@param effect Actor.Entity
    self._NewBullet = function(effect)
        local t = effect.transform
        local param = {
            x = t.position.x,
            y = t.position.y,
            z = t.position.z,
            direction = t.direction,
            entity = self._entity,
            attackValue = self._skill.attackValues[2]
        }

        _FACTORY.New(self._actorDataSet[2], param)
        _FACTORY.New(self._actorDataSet[3], param)
    end
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
    elseif (tick == self._ticks[3]) then
    end

    -- 多段攻击
    if (self.bulletEntity) then
        local bulletFrameani = _ASPECT.GetPart(self.bulletEntity.aspect) ---@type Graphics.Drawable.Frameani
        local bulletTick = bulletFrameani:GetTick()
        if (3 == bulletTick) then
            self._attack:Enter(self._attackDataSet[2], self._skill.attackValues[1], _, _, true)
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

    local main = _ASPECT.GetPart(self._entity.aspect) ---@type Graphics.Drawable.Frameani
    local frameaniDate = main:GetFrameaniData()
    for n = 1, #frameaniDate.list do
        self.entityFrameaniOriDelayList[n] = frameaniDate.list[n].time
    end

    -- 获取技能准备的时间（注意：单位不是ms）
    local skillPrepareTime = self._skill:GetPrepareTime()
    local enhanceRate = skillPrepareTime / 500
    if 1 < enhanceRate then
        enhanceRate = 1 -- 跳跃和移动最大增幅
    end
    local enhanceBaseRate = 0.7 -- 基准增幅率（用来确保增幅率始终不超过此值）
    enhanceRate = enhanceRate * enhanceBaseRate

    local easemoveParam = self._easemoveParam
    self._easemove:Enter("x", easemoveParam.power * (1 + enhanceRate), easemoveParam.speed, self._entity.transform.direction)

    local jumpParam = self._jumpParam
    self._jump:Enter(jumpParam.power * (1 + enhanceRate), jumpParam.speed, jumpParam.speed * 0.3)

    -- 增加动画播放时间
    for n = 1, #frameaniDate.list do
        frameaniDate.list[n].time = self.entityFrameaniOriDelayList[n] * (0.5 + enhanceRate)
    end

    _SOUND.Play(self._soundDataSet.voice)
end

function _HopSmash:Exit(nextState)
    if (nextState == self) then
        return
    end
    
    _Base.Exit(self, nextState)

    if (self._effect) then
        self._effect.identity.destroyProcess = 1
        self._effect = nil
    end

    if (self._buff) then
        self._buff:Exit()
    end

    -- 还原动画延时
    local main = _ASPECT.GetPart(self._entity.aspect) ---@type Graphics.Drawable.Frameani
    local frameaniDate = main:GetFrameaniData()
    for n = 1, #frameaniDate.list do
        frameaniDate.list[n].time = self.entityFrameaniOriDelayList[n]
    end
end

return _HopSmash