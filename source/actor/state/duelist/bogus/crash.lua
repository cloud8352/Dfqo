--[[
	desc: CrashState, a state of bogus.
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

---@class Actor.State.Duelist.bogus.CrashState : Actor.State
---@field protected skill Actor.Skill
---@field protected attack Actor.Gear.Attack
---@field protected buff Actor.Buff
local CrashState = require("core.class")(_Base)

function CrashState:Ctor(data, ...)
    _Base.Ctor(self, data, ...)

    self.easeMoveParams = data.easemove
end

function CrashState:Init(entity)
    _Base.Init(self, entity)
    
    self.easeMove = _EaseMove.New(self._entity.transform, self._entity.aspect)
    self.attack = _Attack.New(self._entity)
    self.buff = nil
end

function CrashState:NormalUpdate(dt, rate)
    local main = _ASPECT.GetPart(self._entity.aspect) ---@type Graphics.Drawable.Frameani
    local frame = main:GetFrame()
    local tick = main:GetTick()

    self.easeMove:Update(rate)
    self.attack:Update(dt)

    _STATE.AutoPlayEnd(self._entity.states, self._entity.aspect, self._nextState)
end

function CrashState:Enter(lateState, skill)
    if (lateState ~= self) then
        _Base.Enter(self)

        self.easeMove:Exit()

        self.skill = skill

        local direction = self._entity.transform.direction
        local easeMoveParams = self.easeMoveParams
        self.easeMove:Enter("x", easeMoveParams.power, easeMoveParams.speed, direction)

        self.attack:Enter(self._attackDataSet, self.skill.attackValues[1], _)

        local param = {
            direction = self._entity.transform.direction,
            entity = self._entity
        }
        Factory.New(self._actorDataSet, param)

        -- sound
        _SOUND.Play(self._soundDataSet.voice[1])
        _SOUND.Play(self._soundDataSet.swing)
        
        self.buff = _BUFF.AddBuff(self._entity, self._buffDatas)
    end
end

function CrashState:Exit(nextState)
    if (nextState == self) then
        return
    else
        _Base.Exit(self, nextState)
    end

    self.buff:Exit()
end

return CrashState
