--[[
	desc: BlastBloodState, a state of swordman.
	author: keke
]]
--

local _SOUND = require("lib.sound")

local _FACTORY = require("actor.factory")
local _ASPECT = require("actor.service.aspect")
local _STATE = require("actor.service.state")

local _Attack = require("actor.gear.attack")
local _Base = require("actor.state.base")

---@class Actor.State.Duelist.swordman.BlastBloodState : Actor.State
---@field protected _attack Actor.Gear.Attack
---@field protected _skill Actor.Skill
local BlastBloodState = require("core.class")(_Base)

function BlastBloodState:Ctor(data, ...)
    _Base.Ctor(self, data, ...)
    self.tick = data.tick

    self.bulletYOffset = data.bulletY
    ---@type Actor.Entity
    self.bullet = nil
end

function BlastBloodState:Init(entity)
    _Base.Init(self, entity)

    self._attack = _Attack.New(self._entity)
end

function BlastBloodState:NormalUpdate(dt, rate)
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
        local effect = _FACTORY.New(self._actorDataSet[1], param)param = {
            x = position.x,
            y = position.y + self.bulletYOffset,
            z = position.z,
            direction = transform.direction,
            entity = self._entity
        }
        self.bullet = _FACTORY.New(self._actorDataSet[2], param)

        -- sound
        _SOUND.Play(self._soundDataSet)

        -- attack
        self._attack:Enter(self._attackDataSet, self._skill.attackValues[1])
        self._attack.collision[_ASPECT.GetPart(effect.aspect)] = "attack"
        self._attack.collision[_ASPECT.GetPart(self.bullet.aspect)] = "attack"
        self._attack.collision[_ASPECT.GetPart(self._entity.aspect)] = "attack"
    elseif tick == self.tick + 3 then
        -- sound
        _SOUND.Play(self._soundDataSet)

        -- attack
        self._attack:Enter(self._attackDataSet, self._skill.attackValues[2])
        self._attack.collision[_ASPECT.GetPart(self.bullet.aspect)] = "attack"
        self._attack.collision[_ASPECT.GetPart(self._entity.aspect)] = "attack"
    end

    self._attack:Update(dt)

    _STATE.AutoPlayEnd(self._entity.states, self._entity.aspect, self._nextState)
end

function BlastBloodState:Enter(lastState, skill)
    if (lastState ~= self) then
        _Base.Enter(self)

        self._skill = skill
    end
end

function BlastBloodState:Exit(nextState)
    if (nextState == self) then
        return
    end

    _Base.Exit(self, nextState)
end

return BlastBloodState
