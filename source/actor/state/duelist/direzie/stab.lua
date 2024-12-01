--[[
	desc: StabState, a state of direzie.
	author: keke
]]
--

local _SOUND = require("lib.sound")

local _FACTORY = require("actor.factory")
local _ASPECT = require("actor.service.aspect")
local _STATE = require("actor.service.state")

local _Attack = require("actor.gear.attack")
local _Base = require("actor.state.base")
local EaseMove = require("actor.gear.easemove")

---@class Actor.State.Duelist.Direzie.StabState : Actor.State
---@field protected _skill Actor.Skill
---@field protected _attack Actor.Gear.Attack
---@field protected easeMove Actor.Gear.Easemove
local StabState = require("core.class")(_Base)

function StabState:Ctor(data, ...)
    _Base.Ctor(self, data, ...)
    self.easeMoveParams = data.easemove
    self.tick = data.tick
end

function StabState:Init(entity)
    _Base.Init(self, entity)
    self.easeMove = EaseMove.New(self._entity.transform, self._entity.aspect)
    self._attack = _Attack.New(self._entity)
end

function StabState:NormalUpdate(dt, rate)
    local main = _ASPECT.GetPart(self._entity.aspect) ---@type Graphics.Drawable.Frameani
    local tick = main:GetTick()

    self.easeMove:Update(rate)

    if tick == self.tick then
        local transform = self._entity.transform

        local easeMoveParams = self.easeMoveParams
        self.easeMove:Enter("x", easeMoveParams.power, easeMoveParams.speed, transform.direction)

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

function StabState:Enter(lastState, skill)
    if (lastState ~= self) then
        _Base.Enter(self)

        self._skill = skill
        self.easeMove:Exit()
    end
end

function StabState:Exit(nextState)
    if (nextState == self) then
        return
    end

    _Base.Exit(self, nextState)
end

return StabState
