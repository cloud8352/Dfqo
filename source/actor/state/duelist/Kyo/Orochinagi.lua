--[[
	desc: Orochinagi, a state of Kyo.
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

---@class Actor.State.Duelist.Kyo.Orochinagi : Actor.State
---@field protected _attack Actor.Gear.Attack
---@field protected _skill Actor.Skill
---@field protected easeMoveX Actor.Gear.Easemove
---@field protected _buff Actor.Buff
local Orochinagi = require("core.class")(_Base)

local HitStop = { 220, 110 }
local MovePower = 13
local MoveSpeed = 0.7

function Orochinagi:Ctor(data, ...)
    _Base.Ctor(self, data, ...)
end

function Orochinagi:Init(entity)
    _Base.Init(self, entity)

    self.easeMoveX = _Easemove.New(self._entity.transform, self._entity.aspect)
    self._attack = _Attack.New(self._entity)
    self._attack.element = _Attack.AttackElementStruct.Light
end

function Orochinagi:NormalUpdate(dt, rate)
    self.easeMoveX:Update(rate)
    self._attack:Update(dt)

    local main = _ASPECT.GetPart(self._entity.aspect) ---@type Graphics.Drawable.Frameani
    local tick = main:GetTick()

    if (tick == 1) then
        self._attack:Enter(self._attackDataSet[1], self._skill.attackValues[1])

        -- move
        local direction = self._entity.transform.direction
        self.easeMoveX:Enter("x", MovePower, MoveSpeed, direction)
    end
    if tick == 2 then
        local t = self._entity.transform
        local param = {
            x = t.position.x + 120 * t.direction,
            y = t.position.y,
            z = t.position.z - 10,
            direction = t.direction,
            entity = self._entity,
            attackValue = self._skill.attackValues[1]
        }
        _FACTORY.New(self._actorDataSet.Front, param)
    end

    _STATE.AutoPlayEnd(self._entity.states, self._entity.aspect, self._nextState)
end

function Orochinagi:Enter(laterState, skill)
    if (laterState ~= self) then
        _Base.Enter(self)

        self.easeMoveX:Exit()
        self._skill = skill

        self._attack.soundDataSet = {}
        table.insert(self._attack.soundDataSet, self._soundDataSet.hitting)

        self._attack.hitstop = HitStop[1]
        self._attack.selfstop = HitStop[2]
        self._attack.shake.time = HitStop[1]

        _SOUND.Play(self._soundDataSet.voice)
        _SOUND.Play(self._soundDataSet.swing)

        self._buff = _BUFF.AddBuff(self._entity, self._buffDatas)
    end
end

function Orochinagi:Exit(nextState)
    if (nextState == self) then
        return
    end

    _Base.Exit(self, nextState)

    if (self._buff) then
        self._buff:Exit()
    end
end

return Orochinagi
