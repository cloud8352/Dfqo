--[[
	desc: GrabUpState, a state of Fighter.
	author: keke
]]--

local ResMgr = require("actor.resmgr")
local _Attack = require("actor.gear.attack")
local _Easemove = require("actor.gear.easemove")
local _Base = require("actor.state.base")

local BattleSrv = require("actor.service.battle")
local StateSrv = require("actor.service.state")
local BuffSrv = require("actor.service.buff")
local _FACTORY = require("actor.factory")
local _ASPECT = require("actor.service.aspect")
local _STATE = require("actor.service.state")

local _SOUND = require("lib.sound")

---@class Actor.State.Duelist.Fighter.GrabUpState : Actor.State
---@field protected _attack Actor.Gear.Attack
---@field protected _skill Actor.Skill
---@field protected _ticks table
local GrabUpState = require("core.class")(_Base)

function GrabUpState:Ctor(data, ...)
    _Base.Ctor(self, data, ...)

    self._ticks = data.ticks

    self.process = 1

    self.attackTimeMs = 0

    ---@type Actor.Buff
    self.buff = nil

    ---@type Actor.Entity
    self.controlledEntity = nil
end

function GrabUpState:Init(entity, ...)
    _Base.Init(self, entity, ...)

    self._attack = _Attack.New(self._entity)
    self._attack.element = _Attack.AttackElementStruct.Fire
end

function GrabUpState:NormalUpdate(dt, rate)
    local main = _ASPECT.GetPart(self._entity.aspect) ---@type Graphics.Drawable.Frameani
    local tick = main:GetTick()

    self._attack:Update()

    self.attackTimeMs = self.attackTimeMs + dt
    if self.attackTimeMs > 400
        and self.controlledEntity
    then
        self.attackTimeMs = 0

        self._attack:Enter(self._attackDataSet[1], self._skill.attackValues[1], _, _, false)
    end

    if self.process == 1 and main:TickEnd() and self.controlledEntity then
        self:setProcess(2)
    end

    if self.process == 2 and main:TickEnd() then
        self:setProcess(3)
    end

    _STATE.AutoPlayEnd(self._entity.states, self._entity.aspect, self._nextState)
end

function GrabUpState:Enter(lastState, skill)
    _Base.Enter(self)

    self._skill = skill
    self._attack:Exit()

    self.buff = nil
    self.controlledEntity = nil

    if self._entity.identity.gender == 1 then
        _SOUND.Play(self._soundDataSet.voice)
    end

    self:setProcess(1)

    self.attackTimeMs = 0
end

---@param nextState Actor.State
function GrabUpState:Exit(nextState)
    _Base.Exit(self, nextState)

    if self.buff then
        self.buff:Exit()
    end

    if nil == self.controlledEntity then
        return
    end
    local e = self.controlledEntity
    local banCountMap = e.battle.banCountMap
    -- banCountMap.stun = banCountMap.stun - 1
    banCountMap.flight = banCountMap.flight - 1
    local lastFlightBanCount = banCountMap.flight
    banCountMap.flight = 0
    banCountMap.overturn = banCountMap.overturn - 1
    banCountMap.dmgSound = banCountMap.dmgSound - 1
    -- banCountMap.turn = banCountMap.turn - 1

    BattleSrv.Flight(e.battle, e.states, 8.5, nil,
        nil, 6, 0, self._entity.transform.direction)
    banCountMap.flight = lastFlightBanCount
end

---@param process int
function GrabUpState:setProcess(process)
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
        _ASPECT.Play(self._entity.aspect, self._frameaniDataSets[2])

        _SOUND.Play(self._soundDataSet.swing)

        local dir = self._entity.transform.direction
        local e = self.controlledEntity
        e.transform.position.x = self._entity.transform.position.x + dir * 60
        e.transform.position.z = self._entity.transform.position.z - 45
        e.transform.positionTick = 1
    elseif process == 3 then
        _STATE.Play(self._entity.states, self._nextState)
    end
end

---@param attack Actor.Gear.Attack
---@param e Actor.Entity
function GrabUpState:onHitFunc(attack, e)
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
    banCountMap.stun = lastStunBanCount

    e.transform.position.x = self._entity.transform.position.x + dir * 40
    e.transform.position.y = self._entity.transform.position.y - 1
    e.transform.position.z = self._entity.transform.position.z
    e.transform.positionTick = 1

    -- add buff
    local a = ResMgr.NewBuffData("invincibility")
    self.buff = BuffSrv.AddBuff(self._entity, a)
end

return GrabUpState
