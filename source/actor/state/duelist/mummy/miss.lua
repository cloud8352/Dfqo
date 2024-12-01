--[[
	desc: MissState, a state of mummy.
	author: keke
]]
--

local _SOUND = require("lib.sound")

local _FACTORY = require("actor.factory")
local _ASPECT = require("actor.service.aspect")
local _STATE = require("actor.service.state")

local _Base = require("actor.state.base")

---@class Actor.State.Duelist.Mummy.MissState : Actor.State
---@field protected _skill Actor.Skill
local MissState = require("core.class")(_Base)

function MissState:Ctor(data, ...)
    _Base.Ctor(self, data, ...)

    self.tick = data.tick
end

function MissState:Init(entity)
    _Base.Init(self, entity)
end

function MissState:NormalUpdate(dt, rate)
    local main = _ASPECT.GetPart(self._entity.aspect) ---@type Graphics.Drawable.Frameani
    local tick = main:GetTick()

    if tick == self.tick then
        local transform = self._entity.transform
        local position = transform.position
        local param = {
            x = position.x,
            y = position.y,
            z = position.z,
            direction = transform.direction,
            entity = self._entity
        }
        _FACTORY.New(self._actorDataSet[1], param)
        _FACTORY.New(self._actorDataSet[2], param)

        -- sound
        _SOUND.Play(self._soundDataSet[1][1])
        _SOUND.Play(self._soundDataSet[2][1])
    end

    _STATE.AutoPlayEnd(self._entity.states, self._entity.aspect, self._nextState)
end

function MissState:Enter(lastState, skill)
    if (lastState ~= self) then
        _Base.Enter(self)

        self._skill = skill
    end
end

function MissState:Exit(nextState)
    if (nextState == self) then
        return
    end

    _Base.Exit(self, nextState)
end

return MissState
