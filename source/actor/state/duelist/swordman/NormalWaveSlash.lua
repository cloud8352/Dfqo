--[[
	desc: NormalWaveSlash, a state of Swordman.
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
local _EFFECT = require("actor.service.effect")
local _MOTION = require("actor.service.motion")

local _Easemove = require("actor.gear.easemove")
local _Attack = require("actor.gear.attack")
local _Base = require("actor.state.base")

---@class Actor.State.Duelist.Swordman.NormalWaveSlash:Actor.State
---@field protected _attack Actor.Gear.Attack
---@field protected _skill Actor.Skill
---@field protected _effect Actor.Entity
---@field protected _easemoveTick int
---@field protected _easemoveParams table
---@field protected _easemove Actor.Gear.Easemove
---@field protected _hitstopMap table
---@field protected _effectTick int
local NormalWaveSlashState = require("core.class")(_Base)

function NormalWaveSlashState:Ctor(data, ...)
    _Base.Ctor(self, data, ...)

    self._easemoveTick = data.easemoveTick
    self._easemoveParams = data.easemove
    self._hitstopMap = data.hitstop
    self._effectTick = data.effectTick
end

function NormalWaveSlashState:Init(entity)
    _Base.Init(self, entity)

    self._easemove = _Easemove.New(self._entity.transform, self._entity.aspect)
    self._attack = _Attack.New(self._entity)
    self._attack.element = _Attack.AttackElementStruct.Fire
end

function NormalWaveSlashState:NormalUpdate(dt, rate)
    self._easemove:Update(rate)

    local main = _ASPECT.GetPart(self._entity.aspect) ---@type Graphics.Drawable.Frameani
    local tick = main:GetTick()

    if (tick == self._effectTick) then
        local t = self._entity.transform
        local param = {
            x = t.x,
            y = t.y,
            z = t.z,
            direction = t.direction,
            entity = self._entity
        }

        self._effect = _FACTORY.New(self._actorDataSet[1], param)

        self._attack:Enter(self._attackDataSet[1], self._skill.attackValues[1])
        self._attack.collision[_ASPECT.GetPart(self._effect.aspect)] = "attack"
    elseif (tick == self._easemoveTick) then
        local direction = self._entity.transform.direction
        local arrowDirection = _INPUT.GetArrowDirection(self._entity.input, direction)

        if (arrowDirection >= 0) then
            local easemoveParam = self._easemoveParams[arrowDirection + 1]
            self._easemove:Enter("x", easemoveParam.power, easemoveParam.speed, direction)
        end
    end

    self._attack:Update()

    _STATE.AutoPlayEnd(self._entity.states, self._entity.aspect, self._nextState)
end

function NormalWaveSlashState:Enter(laterState, skill)
    if (laterState ~= self) then
        _Base.Enter(self)

        self._easemove:Exit()
        self._skill = skill

        local kind = _EQUIPMENT.GetSubKind(self._entity.equipments, "weapon")
        table.insert(self._attack.soundDataSet, self._soundDataSet.hitting[kind])

        local hitstop = self._hitstopMap[kind]
        self._attack.hitstop = hitstop[1]
        self._attack.selfstop = hitstop[2]
        self._attack.shake.time = hitstop[1]

        _SOUND.Play(self._soundDataSet.effect[1])
    end
end

function NormalWaveSlashState:Exit(nextState)
    if (nextState == self) then
        return
    end

    _Base.Exit(self, nextState)

    if (self._effect) then
        self._effect.identity.destroyProcess = 1
        self._effect = nil
    end
end

return NormalWaveSlashState
