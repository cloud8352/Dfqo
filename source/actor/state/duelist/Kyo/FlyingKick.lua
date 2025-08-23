--[[
	desc: FlyingKick, a state of Kyo.
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

---@class Actor.State.Duelist.Kyo.FlyingKick : Actor.State
---@field protected _attack Actor.Gear.Attack
---@field protected _skill Actor.Skill
---@field protected easeMoveX Actor.Gear.Easemove
---@field protected easeMoveZ Actor.Gear.Easemove
---@field protected _buff Actor.Buff
local FlyingKick = require("core.class")(_Base)

local HitStop = { 140, 140 }

function FlyingKick:Ctor(data, ...)
    _Base.Ctor(self, data, ...)
end

function FlyingKick:Init(entity)
    _Base.Init(self, entity)

    self.easeMoveX = _Easemove.New(self._entity.transform, self._entity.aspect)
    self.easeMoveZ = _Easemove.New(self._entity.transform, self._entity.aspect)
    self._attack = _Attack.New(self._entity)
    self._attack.element = _Attack.AttackElementStruct.Light
end

function FlyingKick:NormalUpdate(dt, rate)
    self.easeMoveX:Update(rate)
    self.easeMoveZ:Update(rate)
    self._attack:Update(dt)

    local main = _ASPECT.GetPart(self._entity.aspect) ---@type Graphics.Drawable.Frameani
    local tick = main:GetTick()
    if tick == 4 then
        self:attack()
    end

    if tick == 5 then
        self.easeMoveZ:Enter("z", 12, 0, 1)
    end

    if self.easeMoveZ.isRunning and self._entity.transform.position.z >= 0 then
        self.easeMoveX:Exit()
        self.easeMoveZ:Exit()
        self._entity.transform.position.z = 0
        self._entity.transform.positionTick = 1
    end

    _STATE.AutoPlayEnd(self._entity.states, self._entity.aspect, self._nextState)
end

function FlyingKick:Enter(laterState, skill)
    if (laterState ~= self) then
        _Base.Enter(self)

        self.easeMoveX:Exit()
        self.easeMoveZ:Exit()
        self._skill = skill

        local direction = self._entity.transform.direction
        self.easeMoveX:Enter("x", 6.5, 0, direction)
        self.easeMoveZ:Enter("z", 2.5, 0, -1)

        self:attack()
        _SOUND.Play(self._soundDataSet.voice)
        _SOUND.Play(self._soundDataSet.swing)

        self._buff = _BUFF.AddBuff(self._entity, self._buffDatas)
    end
end

function FlyingKick:Exit(nextState)
    if (nextState == self) then
        return
    end

    _Base.Exit(self, nextState)

    if (self._buff) then
        self._buff:Exit()
    end
end

function FlyingKick:attack()
    -- attack
    self._attack:Enter(self._attackDataSet[1], self._skill.attackValues[1], _)
    self._attack.soundDataSet = {}
    table.insert(self._attack.soundDataSet, self._soundDataSet.hitting)
    self._attack.hitstop = HitStop[1]
    self._attack.selfstop = HitStop[2]
    self._attack.shake.time = HitStop[1]
end

return FlyingKick
