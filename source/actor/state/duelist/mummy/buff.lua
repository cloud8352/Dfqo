--[[
	desc: BuffState, a state of mummy.
	author: keke
]]
--

local _SOUND = require("lib.sound")

local _FACTORY = require("actor.factory")
local _ASPECT = require("actor.service.aspect")
local _STATE = require("actor.service.state")
local BuffSrv = require("actor.service.buff")

local _Attack = require("actor.gear.attack")
local _Base = require("actor.state.base")

---@class Actor.State.Duelist.Mummy.BuffState : Actor.State
---@field protected _skill Actor.Skill
local BuffState = require("core.class")(_Base)

function BuffState:Ctor(data, ...)
    _Base.Ctor(self, data, ...)
    self.tick = data.tick
end

function BuffState:Init(entity)
    _Base.Init(self, entity)
end

function BuffState:NormalUpdate(dt, rate)
    local main = _ASPECT.GetPart(self._entity.aspect) ---@type Graphics.Drawable.Frameani
    local tick = main:GetTick()

    if tick == self.tick then
        -- sound
        _SOUND.Play(self._soundDataSet[1])
    end

    _STATE.AutoPlayEnd(self._entity.states, self._entity.aspect, self._nextState)
end

function BuffState:Enter(lastState, skill)
    if (lastState ~= self) then
        _Base.Enter(self)

        self._skill = skill

        BuffSrv.AddBuff(self._entity, self._buffDatas[1])
        BuffSrv.AddBuff(self._entity, self._buffDatas[2])
    end
end

function BuffState:Exit(nextState)
    if (nextState == self) then
        return
    end

    _Base.Exit(self, nextState)
end

return BuffState
