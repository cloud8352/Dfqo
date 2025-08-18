--[[
	desc: SpinningSlash, a state of Tsunade.
	author: keke
]]
--

local _SOUND = require("lib.sound")
local _TABLE = require("lib.table")
local Util = require("util.Util")

local _FACTORY = require("actor.factory")
local _RESMGR = require("actor.resmgr")
local _ASPECT = require("actor.service.aspect")
local _STATE = require("actor.service.state")
local _INPUT = require("actor.service.input")
local _EQUIPMENT = require("actor.service.equipment")
local _BUFF = require("actor.service.buff")
local _EFFECT = require("actor.service.effect")
local _MOTION = require("actor.service.motion")

local _Easemove = require("actor.gear.easemove")
local _Attack = require("actor.gear.attack")
local _Base = require("actor.state.base")

---@class Actor.State.Duelist.Tsunade.SpinningSlash : Actor.State
---@field protected _attack Actor.Gear.Attack
---@field protected _skill Actor.Skill
---@field protected _buff Actor.Buff
local SpinningSlash = require("core.class")(_Base)

local HitStop = { 220, 110 }

function SpinningSlash:Ctor(data, ...)
    _Base.Ctor(self, data, ...)
end

function SpinningSlash:Init(entity)
    _Base.Init(self, entity)

    self._attack = _Attack.New(self._entity)
    self._attack.element = _Attack.AttackElementStruct.Light
end

function SpinningSlash:NormalUpdate(dt, rate)
    self._attack:Update(dt)

    local main = _ASPECT.GetPart(self._entity.aspect) ---@type Graphics.Drawable.Frameani
    local tick = main:GetTick()

    if (tick == 12) then
        self._attack:Enter(self._attackDataSet[1], self._skill.attackValues[1])
        table.insert(self._attack.soundDataSet, self._soundDataSet.hitting)

        self._attack.hitstop = HitStop[1]
        self._attack.selfstop = HitStop[2]
        self._attack.shake.time = HitStop[1]

        _SOUND.Play(self._soundDataSet.swing)
    end

    _STATE.AutoPlayEnd(self._entity.states, self._entity.aspect, self._nextState)
end

function SpinningSlash:Enter(laterState, skill)
    if (laterState ~= self) then
        _Base.Enter(self)

        self._skill = skill

        _SOUND.Play(self._soundDataSet.voice)

        self._buff = _BUFF.AddBuff(self._entity, self._buffDatas)
    end
end

function SpinningSlash:Exit(nextState)
    if (nextState == self) then
        return
    end

    _Base.Exit(self, nextState)

    if (self._buff) then
        self._buff:Exit()
    end
end

return SpinningSlash
