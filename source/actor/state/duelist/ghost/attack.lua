--[[
	desc: AttackState, a state of ghost.
	author: keke
]]
--

local _SOUND = require("lib.sound")

local _FACTORY = require("actor.factory")
local _ASPECT = require("actor.service.aspect")
local _STATE = require("actor.service.state")

local _Attack = require("actor.gear.attack")
local _Base = require("actor.state.base")

---@class Actor.State.Duelist.ghost.AttackState : Actor.State
---@field protected _attack Actor.Gear.Attack
---@field protected _skill Actor.Skill
local AttackState = require("core.class")(_Base)

function AttackState:Ctor(data, ...)
    _Base.Ctor(self, data, ...)
    self.tick = data.tick
end

function AttackState:Init(entity)
    _Base.Init(self, entity)

    self._attack = _Attack.New(self._entity)
end

function AttackState:NormalUpdate(dt, rate)
    local main = _ASPECT.GetPart(self._entity.aspect) ---@type Graphics.Drawable.Frameani
    local tick = main:GetTick()

    if tick == self.tick then
        -- sound
        _SOUND.Play(self._soundDataSet.voice[1])
        _SOUND.Play(self._soundDataSet.swing)

        -- attack
        self._attack:Enter(self._attackDataSet, self._skill.attackValues[1])
        self._attack.collision[_ASPECT.GetPart(self._entity.aspect)] = "attack"
    end

    self._attack:Update(dt)

    _STATE.AutoPlayEnd(self._entity.states, self._entity.aspect, self._nextState)
end

function AttackState:Enter(lastState, skill)
    if (lastState ~= self) then
        _Base.Enter(self)

        self._skill = skill
    end
end

function AttackState:Exit(nextState)
    if (nextState == self) then
        return
    end

    _Base.Exit(self, nextState)
end

return AttackState
