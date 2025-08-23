--[[
	desc: LiftUpper, a state of Fighter.
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

---@class Actor.State.Duelist.Fighter.LiftUpper : Actor.State
---@field protected _attack Actor.Gear.Attack
---@field protected _skill Actor.Skill
---@field protected _easemove Actor.Gear.Easemove
---@field protected _buff Actor.Buff
local LiftUpper = require("core.class")(_Base)

local HitStop = { 220, 110 }
local MovePower = 7
local MoveSpeed = 0.5

function LiftUpper:Ctor(data, ...)
    _Base.Ctor(self, data, ...)
end

function LiftUpper:Init(entity)
    _Base.Init(self, entity)

    self._easemove = _Easemove.New(self._entity.transform, self._entity.aspect)
    self._attack = _Attack.New(self._entity)
    self._attack.element = _Attack.AttackElementStruct.Light
end

function LiftUpper:NormalUpdate(dt, rate)
    self._easemove:Update(rate)
    self._attack:Update()

    local main = _ASPECT.GetPart(self._entity.aspect) ---@type Graphics.Drawable.Frameani
    local tick = main:GetTick()
    if (tick == 2) then
        self._attack:Enter(self._attackDataSet[1], self._skill.attackValues[1])
        self._attack.soundDataSet = {}
        table.insert(self._attack.soundDataSet, self._soundDataSet.hitting)

        self._attack.hitstop = HitStop[1]
        self._attack.selfstop = HitStop[2]
        self._attack.shake.time = HitStop[1]

        -- move
        local direction = self._entity.transform.direction
        local arrowDirection = _INPUT.GetArrowDirection(self._entity.input, direction)
        if (arrowDirection > 0) then
            self._easemove:Enter("x", MovePower * 1.4, MoveSpeed, direction)
        else
            self._easemove:Enter("x", MovePower, MoveSpeed, direction)
        end
    end

    _STATE.AutoPlayEnd(self._entity.states, self._entity.aspect, self._nextState)
end

function LiftUpper:Enter(laterState, skill)
    if (laterState ~= self) then
        _Base.Enter(self)

        self._easemove:Exit()
        self._skill = skill
        self._attack:Exit()

        Util.PlaySoundByGender(self._soundDataSet, 1, self._entity.identity.gender)
        _SOUND.Play(self._soundDataSet.swing)

        self._buff = _BUFF.AddBuff(self._entity, self._buffDatas)
    end
end

function LiftUpper:Exit(nextState)
    if (nextState == self) then
        return
    end

    _Base.Exit(self, nextState)

    if (self._buff) then
        self._buff:Exit()
    end
end

return LiftUpper
