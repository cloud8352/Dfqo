--[[
	desc: AttackState, a state of bogus.
	author: keke
]]--

local _TABLE = require("lib.table")
local _SOUND = require("lib.sound")
local Util = require("util.Util")

local _ASPECT = require("actor.service.aspect")
local _STATE = require("actor.service.state")
local _INPUT = require("actor.service.input")
local _MOTION = require("actor.service.motion")
local _EQUIPMENT = require("actor.service.equipment")
local _ATTRIBUTE = require("actor.service.attribute")
local _INPUT = require("actor.service.input")

local _Easemove = require("actor.gear.easemove")
local _Attack = require("actor.gear.attack")
local _BattleJudge = require("actor.ai.battleJudge")
local Timer = require("util.gear.timer")

local _Base = require("actor.state.base")

-- const

---@class Actor.State.Duelist.bogus.AttackState : Actor.State
---@field protected _ticks table
---@field protected skill Actor.Skill
---@field protected attack Actor.Gear.Attack
local AttackState = require("core.class")(_Base)

function AttackState:Ctor(data, ...)
    _Base.Ctor(self, data, ...)

    self._ticks = data.ticks
end

function AttackState:Init(entity)
    _Base.Init(self, entity)
    
    self.attack = _Attack.New(self._entity)
end

function AttackState:NormalUpdate(dt, rate)
    local main = _ASPECT.GetPart(self._entity.aspect) ---@type Graphics.Drawable.Frameani
    local frame = main:GetFrame()
    local tick = main:GetTick()

    if tick == self._ticks[1]
        or tick == self._ticks[2]
    then
        self.attack:Enter(self._attackDataSet, self.skill.attackValues[1], _)
    end

    self.attack:Update(dt)

    _STATE.AutoPlayEnd(self._entity.states, self._entity.aspect, self._nextState)
end

function AttackState:Enter(lateState, skill)
    if (lateState ~= self) then
        _Base.Enter(self)

        self.skill = skill

        -- sound
        _SOUND.Play(self._soundDataSet.voice[1])
        _SOUND.Play(self._soundDataSet.swing)
    end
end

function AttackState:Exit(nextState)
    if (nextState == self) then
        return
    else
        _Base.Exit(self, nextState)
    end
end

return AttackState
