--[[
	desc: DamageLowKickState, a state of Kyo.
	author: keke
]]
--

local _SOUND = require("lib.sound")
local Util = require("util.Util")

local _ASPECT = require("actor.service.aspect")
local _STATE = require("actor.service.state")

local _Attack = require("actor.gear.attack")
local _Base = require("actor.state.base")

---@class Actor.State.Duelist.Kyo.DamageLowKickState : Actor.State
---@field protected _attack Actor.Gear.Attack
---@field protected _skill Actor.Skill
local DamageLowKickState = require("core.class")(_Base)

local HitStop = { 220, 210 }
local AttackShakeTimeMs = 0

function DamageLowKickState:Ctor(data, ...)
    _Base.Ctor(self, data, ...)
end

function DamageLowKickState:Init(entity)
    _Base.Init(self, entity)

    self._attack = _Attack.New(self._entity)
    self._attack.element = _Attack.AttackElementStruct.Light
end

function DamageLowKickState:NormalUpdate(dt, rate)
    self._attack:Update(dt)

    local main = _ASPECT.GetPart(self._entity.aspect) ---@type Graphics.Drawable.Frameani
    local tick = main:GetTick()
    if (tick == 2) then
        self._attack:Enter(self._attackDataSet[1], self._skill.attackValues[1])

        table.insert(self._attack.soundDataSet, self._soundDataSet.hitting)
        self._attack.hitstop = HitStop[1]
        self._attack.selfstop = HitStop[2]
        self._attack.shake.time = AttackShakeTimeMs
    end

    _STATE.AutoPlayEnd(self._entity.states, self._entity.aspect, self._nextState)
end

function DamageLowKickState:Enter(lastState, skill)
    if (lastState ~= self) then
        _Base.Enter(self)

        self._skill = skill
        self._attack:Exit()

        _SOUND.Play(self._soundDataSet.voice)
        _SOUND.Play(self._soundDataSet.swing)
    end
end

function DamageLowKickState:Exit(nextState)
    if (nextState == self) then
        return
    end

    _Base.Exit(self, nextState)
end

return DamageLowKickState
