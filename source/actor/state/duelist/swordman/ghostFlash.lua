--[[
	desc: GhostFlashState, a state of Swordman.
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

---@class Actor.State.Duelist.Swordman.UpperSlash:Actor.State
---@field protected _attack Actor.Gear.Attack
---@field protected _skill Actor.Skill
---@field protected _buff Actor.Buff
local GhostFlashState = require("core.class")(_Base)

function GhostFlashState:Ctor(data, ...)
    _Base.Ctor(self, data, ...)

    self.moveValue = data.moveValue
    self.tick = data.tick
    self.lightEffectPos = {
        x = data.lightPos.x or 0,
        y = data.lightPos.y or 0,
        z = data.lightPos.z or 0
    }
end

function GhostFlashState:Init(entity)
    _Base.Init(self, entity)

    self._attack = _Attack.New(self._entity)
end

function GhostFlashState:NormalUpdate(dt, rate)
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
        self._effect = _FACTORY.New(self._actorDataSet[1], param)

        local param = {
            x = position.x + self.lightEffectPos.x,
            y = position.y + self.lightEffectPos.y,
            z = position.z + self.lightEffectPos.z,
            direction = transform.direction,
            entity = self._entity
        }
        _FACTORY.New(self._actorDataSet[2], param)

        -- sound
        _SOUND.Play(self._soundDataSet.voice[1])
        _SOUND.Play(self._soundDataSet.swing)

        -- move
        local moveValue = transform.direction * self.moveValue
        _MOTION.Move(transform, self._entity.aspect, "x", moveValue)

        -- attack
        self._attack:Enter(self._attackDataSet, self._skill.attackValues[1])
        self._attack.collision[_ASPECT.GetPart(self._effect.aspect)] = "attack"
        self._attack.collision[_ASPECT.GetPart(self._entity.aspect)] = "attack"
    end

    self._attack:Update(dt)

    _STATE.AutoPlayEnd(self._entity.states, self._entity.aspect, self._nextState)
end

function GhostFlashState:Enter(laterState, skill)
    if (laterState ~= self) then
        _Base.Enter(self)

        self._skill = skill
    end
end

function GhostFlashState:Exit(nextState)
    if (nextState == self) then
        return
    end

    _Base.Exit(self, nextState)

    if (self._buff) then
        self._buff:Exit()
    end
end

return GhostFlashState
