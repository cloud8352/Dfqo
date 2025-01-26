--[[
	desc: GuardState, a state of bogus.
	author: keke
]]--

local _Base = require("actor.state.base")

local Factory = require("actor.factory")
local _ASPECT = require("actor.service.aspect")
local _STATE = require("actor.service.state")
local _EaseMove = require("actor.gear.easemove")
local _Attack = require("actor.gear.attack")
local _BUFF = require("actor.service.buff")

local _TABLE = require("lib.table")
local _SOUND = require("lib.sound")

-- const

---@class Actor.State.Duelist.bogus.GuardState : Actor.State
---@field protected skill Actor.Skill
---@field protected buffList table<int, Actor.Buff>
local GuardState = require("core.class")(_Base)

function GuardState:Ctor(data, ...)
    _Base.Ctor(self, data, ...)

    self.stopTime = data.stopTime
end

function GuardState:Init(entity)
    _Base.Init(self, entity)
    
    self.buffList = {}
    self.execTime = 0
end

function GuardState:NormalUpdate(dt, rate)
    local main = _ASPECT.GetPart(self._entity.aspect) ---@type Graphics.Drawable.Frameani
    local frame = main:GetFrame()
    local tick = main:GetTick()

    if self.execTime > self.stopTime then
        _STATE.AutoPlayEnd(self._entity.states, self._entity.aspect, self._nextState)
    end

    self.execTime = self.execTime + dt
end

function GuardState:Enter(lateState, skill)
    if (lateState ~= self) then
        _Base.Enter(self)

        self.skill = skill

        self.execTime = 0

        local param = {
            direction = self._entity.transform.direction,
            entity = self._entity
        }
        Factory.New(self._actorDataSet, param)

        -- sound
        _SOUND.Play(self._soundDataSet)
        
        for _, buff in pairs(self.buffList) do
            buff:Exit()
        end
        self.buffList = {}
        for _, buffData in pairs(self._buffDatas) do
            local buff = _BUFF.AddBuff(self._entity, buffData)
            table.insert(self.buffList, buff)
        end
    end
end

function GuardState:Exit(nextState)
    if (nextState == self) then
        return
    else
        _Base.Exit(self, nextState)
    end
end

return GuardState
