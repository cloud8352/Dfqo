--[[
	desc: TripleSlash, a state of Swordman.
	author: Musoucrow
	since: 2018-12-18
	alter: 2019-5-30
]]--

local _TABLE = require("lib.table")
local _SOUND = require("lib.sound")
local Util = require("util.Util")

local _ASPECT = require("actor.service.aspect")
local _STATE = require("actor.service.state")
local _INPUT = require("actor.service.input")
local _MOTION = require("actor.service.motion")
local _EQUIPMENT = require("actor.service.equipment")
local _ATTRIBUTE = require("actor.service.attribute")
local _INPUT = require("actor.service.input")

local _Easemove = require("actor.gear.easemove")
local _Attack = require("actor.gear.attack")
local _BattleJudge = require("actor.ai.battleJudge")
local Timer = require("util.gear.timer")
local Factory = require("actor.factory")

local _Base = require("actor.state.base")

-- const
local SkillKeyPressCheckIntervalMs = 150

---@class Actor.State.Duelist.Swordman.TripleSlash:Actor.State
---@field protected _process int
---@field protected _easemove Actor.Gear.Easemove
---@field protected _attack Actor.Gear.Attack
---@field protected _hasPressed boolean
---@field protected _skill Actor.Skill
---@field protected _colliderDatas table<number, Actor.RESMGR.ColliderData>
---@field protected _easemoveParams table
local TripleSlash = require("core.class")(_Base)

function TripleSlash:Ctor(data, ...)
    _Base.Ctor(self, data, ...)

    self._easemoveParams = data.easemove

    self.skillKeyPressCheckTimer = Timer.New()
end

function TripleSlash:Init(entity)
    _Base.Init(self, entity)

    self._easemove = _Easemove.New(self._entity.transform, self._entity.aspect)
    self._attack = _Attack.New(self._entity)

    ---@param attack Actor.Gear.Attack
    self._OnHit = function(attack)
        if (not attack:HasAttacked()) then
        end
    end
end

function TripleSlash:NormalUpdate(dt, rate)
    local main = _ASPECT.GetPart(self._entity.aspect) ---@type Graphics.Drawable.Frameani
    local frame = main:GetFrame()
    local tick = main:GetTick()

    self.skillKeyPressCheckTimer:Update(dt)
    self._easemove:Update(rate)

    self._attack:Update()

    if (tick == 1) then
        local direction = self._entity.transform.direction
        local easeMoveParams = self._easemoveParams
        self._easemove:Enter("x", easeMoveParams.power, easeMoveParams.speed, direction)
    end

    if _INPUT.IsPressed(self._entity.input, self._skill:GetKey()) then
        self._hasPressed = true
        self.skillKeyPressCheckTimer:Enter(SkillKeyPressCheckIntervalMs)
    end
    if self._hasPressed and not self.skillKeyPressCheckTimer.isRunning then
        self._hasPressed = false
    end

    local keyFrame = 4
    if (self._hasPressed and frame > keyFrame and self._process < #self._frameaniDataSets) then
        self:SetProcess(self._process + 1)
    elseif (main:TickEnd()) then
        _STATE.Play(self._entity.states, self._nextState)
    end
end

function TripleSlash:Enter(lastState, skill)
    if (lastState ~= self) then
        _Base.Enter(self)

        self._skill = skill

        self._easemove:Exit()
        self:SetProcess(1)
    end
end

function TripleSlash:Exit(nextState)
    if (nextState == self) then
        return
    else
        _Base.Exit(self, nextState)
        self._attack:Exit()
    end
end

---@param process int
function TripleSlash:SetProcess(process)
    self._process = process
    self._skill:Reset()
    _MOTION.TurnDirection(self._entity.transform, self._entity.input)

    Util.PlaySoundByGender(self._soundDataSet, self._process, self._entity.identity.gender)

    local soundDatas = self._soundDataSet.swing
    _SOUND.Play(soundDatas[self._process])

    _ASPECT.Play(self._entity.aspect, self._frameaniDataSets[process])


    local t = self._entity.transform
    local param = {
        x = t.x,
        y = t.y,
        z = t.z,
        direction = t.direction,
        entity = self._entity
    }

    self._effect = Factory.New(self._actorDataSet.slash[self._process], param)
    if self._process > 1 then
        self._effect = Factory.New(self._actorDataSet.move[self._process - 1], param)
    end

    self:EnterAttack()
end

function TripleSlash:EnterAttack()
    self._attack:Enter(self._attackDataSet[self._process], self._skill.attackValues[1], self._OnHit)
end

---@return int
function TripleSlash:GetProcess()
    return self._process
end

return TripleSlash
