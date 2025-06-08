--[[
	desc: GuardState, a state of duelist.
	author: keke
]]--

local _SOUND = require("lib.sound")
local _FACTORY = require("actor.factory")
local _INPUT = require("actor.service.input")
local _ASPECT = require("actor.service.aspect")
local _STATE = require("actor.service.state")
local AttributeSrv = require("actor.service.attribute")

local _Color = require("graphics.drawunit.color")
local _Timer = require( "util.gear.timer")
local _Easemove = require("actor.gear.easemove")
local _Base = require("actor.state.base")

---@class Actor.State.Duelist.GuardState : Actor.State
---@field skill Actor.Skill
local GuardState = require("core.class")(_Base)

function GuardState:Ctor(data, ...)
    _Base.Ctor(self, data, ...)

    ---@param entity Actor.Entity
    self._OnGuard = function(entity)
        local attack = entity.battle.beatenConfig.attack
        
        if (attack:IsVoid()) then
            return
        end

        local t = entity.transform
        local param = {
            x = t.position.x,
            y = t.position.y,
            z = t.position.z,
            direction = t.direction,
            entity = self._entity,
            attackValue = self.skill.attackValues[1]
        }

        _FACTORY.New(self._actorDataSet.bullet, param)
        param.z = t.position.z - math.floor(entity.aspect.height * 0.5)
        _FACTORY.New(self._actorDataSet.effect, param)
    end

    ---@param entity Actor.Entity
    ---@param attacker Actor.Entity
    self.funBeforeAttacked = function(entity, attacker)
        local attack = entity.battle.beforeBeatenConfig.attack
        
        if (attack:IsVoid()) then
            return
        end

        local attackedDir = self._entity.battle.beforeBeatenConfig.direction
        if self._entity.transform.direction == attackedDir then
            self:reduceBattleBan()
            return
        end

        -- 减少伤害
        self._entity.battle.beforeBeatenConfig.damageReduceRate = 0.9
    end
end

function GuardState:Init(entity)
    _Base.Init(self, entity)

    self.whetherBattleBanHasAdded = false
end

function GuardState:NormalUpdate(dt, rate)
    if false == _INPUT.IsPressed(self._entity.input, self.skill:GetKey())
        and false == _INPUT.IsHold(self._entity.input, self.skill:GetKey()) then
        _STATE.Play(self._entity.states, self._nextState)
    end
end

function GuardState:Enter(lastState, skill)
    _Base.Enter(self)
    self.skill = skill

    _SOUND.Play(self._soundDataSet[1])
    self:addBattleBan()

    local t = self._entity.transform
    local data = self._frameaniDataSets.body ---@type Lib.RESOURCE.FrameaniData
    local param = {
        x = t.position.x,
        y = t.position.y,
        z = t.position.z,
        direction = t.direction,
        entity = self._entity,
        camp = self._entity.battle.camp,
        spriteData = data.list[1].spriteData
    }

    local figure = _FACTORY.New(self._actorDataSet.article, param)
    figure.aspect.color:Set(_Color.blue:Get())
    figure.aspect.colorTick = true
    figure.battle.beatenCaller:AddListener(figure, self._OnGuard)

    self._entity.battle.beforeBeatenCaller:AddListener(self._entity, self.funBeforeAttacked)
end

---@param nextState Actor.State
function GuardState:Exit(nextState)
    _Base.Exit(self, nextState)

    self:reduceBattleBan()
    self._entity.battle.beforeBeatenCaller:DelListener(self._entity, self.funBeforeAttacked)
end

function GuardState:addBattleBan()
    if self.whetherBattleBanHasAdded then
        return
    end
    self.whetherBattleBanHasAdded = true
    local banCountMap = self._entity.battle.banCountMap
    banCountMap.stun = banCountMap.stun + 1
    banCountMap.flight = banCountMap.flight + 1
    banCountMap.overturn = banCountMap.overturn + 1
end

function GuardState:reduceBattleBan()
    if self.whetherBattleBanHasAdded == false then
        return
    end
    self.whetherBattleBanHasAdded = false

    local banCountMap = self._entity.battle.banCountMap
    banCountMap.stun = banCountMap.stun - 1
    banCountMap.flight = banCountMap.flight - 1
    banCountMap.overturn = banCountMap.overturn - 1
end

return GuardState

