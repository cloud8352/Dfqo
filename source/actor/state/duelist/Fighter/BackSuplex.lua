--[[
	desc: BackSuplexState, a state of Fighter.
	author: keke
]]--

local ResMgr = require("actor.resmgr")
local _Attack = require("actor.gear.attack")
local _Base = require("actor.state.base")

local BattleSrv = require("actor.service.battle")
local StateSrv = require("actor.service.state")
local BuffSrv = require("actor.service.buff")
local _FACTORY = require("actor.factory")
local _ASPECT = require("actor.service.aspect")
local _STATE = require("actor.service.state")

local _SOUND = require("lib.sound")

---@class Actor.State.Duelist.Fighter.BackSuplex : Actor.State
---@field protected _attack Actor.Gear.Attack
---@field protected _skill Actor.Skill
---@field protected _ticks table
local BackSuplexState = require("core.class")(_Base)

function BackSuplexState:Ctor(data, ...)
    _Base.Ctor(self, data, ...)

    self._ticks = data.ticks

    self.process = 1

    ---@type Actor.Buff
    self.buff = nil

    ---@type Actor.Entity
    self.controlledEntity = nil
end

function BackSuplexState:Init(entity, ...)
    _Base.Init(self, entity, ...)

    self._attack = _Attack.New(self._entity)
    self._attack.element = _Attack.AttackElementStruct.Fire
end

function BackSuplexState:NormalUpdate(dt, rate)
    local main = _ASPECT.GetPart(self._entity.aspect) ---@type Graphics.Drawable.Frameani
    local tick = main:GetTick()

    self._attack:Update()

    if tick == 2 and self.controlledEntity == nil then
        self:setProcess(2)
    end

    if tick == 2 and self.controlledEntity then
        local dir = self._entity.transform.direction
        local e = self.controlledEntity
        e.transform.position.x = self._entity.transform.position.x + dir * 50
        e.transform.positionTick = 1
    end

    if tick == 6 and self.controlledEntity then
        local dir = self._entity.transform.direction
        local e = self.controlledEntity
        e.transform.position.x = self._entity.transform.position.x - dir * 90
        e.transform.position.z = self._entity.transform.position.z
        e.transform.positionTick = 1

        e.transform.direction = -dir

        -- 震荡波
        local param = {
            x = e.transform.position.x,
            y = e.transform.position.y,
            z = e.transform.position.z,
            direction = e.transform.direction,
            entity = self._entity
        }
        param.attackValue = {
            damageRate = 3.5,
            isPhysical = true
        }

        local endOnGroundBulletEntity = _FACTORY.New(self._actorDataSet[1], param)
    end

    _STATE.AutoPlayEnd(self._entity.states, self._entity.aspect, self._nextState)
end

function BackSuplexState:Enter(lastState, skill)
    _Base.Enter(self)

    self._skill = skill
    self._attack:Exit()

    self.buff = nil
    self.controlledEntity = nil

    if self._entity.identity.gender == 1 then
        _SOUND.Play(self._soundDataSet.voice)
    end

    self:setProcess(1)
end

---@param nextState Actor.State
function BackSuplexState:Exit(nextState)
    _Base.Exit(self, nextState)

    if self.buff then
        self.buff:Exit()
    end

    if nil == self.controlledEntity then
        return
    end
    local e = self.controlledEntity
    local banCountMap = e.battle.banCountMap
    banCountMap.stun = banCountMap.stun - 1
    banCountMap.flight = banCountMap.flight - 1
    local lastFlightBanCount = banCountMap.flight
    banCountMap.flight = 0
    banCountMap.overturn = banCountMap.overturn - 1
    banCountMap.dmgSound = banCountMap.dmgSound - 1
    -- banCountMap.turn = banCountMap.turn - 1

    BattleSrv.Flight(e.battle, e.states, 3, nil,
        nil, 0, 0, self._entity.transform.direction)
    banCountMap.flight = lastFlightBanCount
end

---@param process int
function BackSuplexState:setProcess(process)
    self.process = process
    if process == 1 then
        ---@param attack Actor.Gear.Attack
        ---@param e Actor.Entity
        local function onHitFunc(attack, e)
            self:onHitFunc(attack, e)
        end

        self._attack:Enter(self._attackDataSet[1], self._skill.attackValues[1], onHitFunc, _, false)

        _SOUND.Play(self._soundDataSet.swing)
    elseif process == 2 then
        _STATE.Play(self._entity.states, self._nextState)
    end
end

---@param attack Actor.Gear.Attack
---@param e Actor.Entity
function BackSuplexState:onHitFunc(attack, e)
    if e.states == nil then
        return
    end

    if self.controlledEntity ~= nil then
        return
    end

    self.controlledEntity = e
    StateSrv.Reset(e.states, true)

    local banCountMap = e.battle.banCountMap
    local lastStunBanCount = banCountMap.stun
    banCountMap.stun = 0
    banCountMap.flight = banCountMap.flight + 1
    banCountMap.overturn = banCountMap.overturn + 1
    banCountMap.dmgSound = banCountMap.dmgSound + 1
    -- banCountMap.turn = banCountMap.turn + 1

    local dir = self._entity.transform.direction
    BattleSrv.Stun(e.battle, e.states, 5000, 0, 0, dir)
    banCountMap.stun = lastStunBanCount + 1

    e.transform.position.x = self._entity.transform.position.x + dir * 60
    e.transform.position.y = self._entity.transform.position.y - 1
    e.transform.position.z = self._entity.transform.position.z
    e.transform.positionTick = 1

    -- add buff
    local a = ResMgr.NewBuffData("invincibility")
    self.buff = BuffSrv.AddBuff(self._entity, a)
end

return BackSuplexState
