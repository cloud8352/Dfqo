--[[
	desc: GrabState, a state of ghost.
	author: keke
]]
--

local _SOUND = require("lib.sound")

local _ASPECT = require("actor.service.aspect")
local _STATE = require("actor.service.state")

local _Attack = require("actor.gear.attack")
local _Base = require("actor.state.base")

---@class Actor.State.Duelist.ghost.GrabState : Actor.State
---@field protected _skill Actor.Skill
---@field protected _attack Actor.Gear.Attack
local GrabState = require("core.class")(_Base)

function GrabState:Ctor(data, ...)
    _Base.Ctor(self, data, ...)

    self.tick = data.tick
end

function GrabState:Init(entity)
    _Base.Init(self, entity)
    self._attack = _Attack.New(self._entity)
end

function GrabState:NormalUpdate(dt, rate)
    local main = _ASPECT.GetPart(self._entity.aspect) ---@type Graphics.Drawable.Frameani
    local tick = main:GetTick()

    if tick == self.tick then
        -- sound
        _SOUND.Play(self._soundDataSet.voice)
        _SOUND.Play(self._soundDataSet.swing)

        -- attack
        self._attack:Enter(self._attackDataSet, self._skill.attackValues[1])
        self._attack.collision[_ASPECT.GetPart(self._entity.aspect)] = "attack"
    end
    self._attack:Update(dt)

    _STATE.AutoPlayEnd(self._entity.states, self._entity.aspect, self._nextState)
end

function GrabState:Enter(lastState, skill)
    if (lastState ~= self) then
        _Base.Enter(self)

        self._skill = skill
    end
end

function GrabState:Exit(nextState)
    if (nextState == self) then
        return
    end

    _Base.Exit(self, nextState)
end

return GrabState
