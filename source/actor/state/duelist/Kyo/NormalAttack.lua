--[[
	desc: NormalAttack, a state of Kyo.
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

local _Base = require("actor.state.base")

-- const
local SkillKeyPressCheckIntervalMs = 150

---@class Actor.State.Duelist.Kyo.NormalAttack : Actor.State
---@field protected _process int
---@field protected _easemove Actor.Gear.Easemove
---@field protected _attack Actor.Gear.Attack
---@field protected _hasPressed boolean
---@field protected _skill Actor.Skill
---@field protected easeMoveParams table
---@field protected _frames table
---@field protected _ticks table
---@field protected hitStop table
local _NormalAttack = require("core.class")(_Base)

function _NormalAttack:Ctor(data, ...)
    _Base.Ctor(self, data, ...)

    self.easeMoveParams = data.EaseMove
    self._frames = data.frames
    self._ticks = data.ticks
    self.hitStop = { 160, 100 }

    self.skillKeyPressCheckTimer = Timer.New()
end

function _NormalAttack:Init(entity)
    _Base.Init(self, entity)

    self._easemove = _Easemove.New(self._entity.transform, self._entity.aspect)
    self._attack = _Attack.New(self._entity)

    ---@param attack Actor.Gear.Attack
    self._OnHit = function(attack)
    end
end

function _NormalAttack:NormalUpdate(dt, rate)
    local main = _ASPECT.GetPart(self._entity.aspect) ---@type Graphics.Drawable.Frameani
    local frame = main:GetFrame()
    local tick = main:GetTick()

    self.skillKeyPressCheckTimer:Update(dt)
    self._easemove:Update(rate)

    if (self:HasTick()) then
        self:EnterAttack()
    end

    self._attack:Update()

    if (tick == self.easeMoveParams[self._process].tick) then
        local direction = self._entity.transform.direction
        local arrowDirection = _INPUT.GetArrowDirection(self._entity.input, direction)

        if (arrowDirection >= 0) then
            local easeMoveParam = self.easeMoveParams[self._process][arrowDirection + 1]
            self._easemove:Enter("x", easeMoveParam.power, easeMoveParam.speed, direction)
        end
    end

    local isEnd = self._process > #self._frames
    local keyFrame = not isEnd and self._frames[self._process] - 1 or 0

    if _INPUT.IsPressed(self._entity.input, self._skill:GetKey()) then
        self._hasPressed = true
        self.skillKeyPressCheckTimer:Enter(SkillKeyPressCheckIntervalMs)
    end
    if self._hasPressed and not self.skillKeyPressCheckTimer.isRunning then
        self._hasPressed = false
    end

    if (not isEnd and self._hasPressed and frame > keyFrame) then
        self:SetProcess(self._process + 1)
    elseif (main:TickEnd()) then
        _STATE.Play(self._entity.states, self._nextState)
    end
end

function _NormalAttack:Enter(lateState, skill)
    if (lateState ~= self) then
        _Base.Enter(self)

        self._skill = skill

        self._easemove:Exit()
        self:SetProcess(1)
    end
end

function _NormalAttack:Exit(nextState)
    if (nextState == self) then
        return
    else
        _Base.Exit(self, nextState)
    end
end

---@param process int
function _NormalAttack:SetProcess(process)
    self._process = process
    self._skill:Reset()
    _MOTION.TurnDirection(self._entity.transform, self._entity.input)

    _SOUND.Play(self._soundDataSet.voice[process])

    local soundDataList = self._soundDataSet.swing
    local n = math.random(1, _TABLE.Len(soundDataList))
    _SOUND.Play(soundDataList[n])

    _ASPECT.Play(self._entity.aspect, self._frameaniDataSets[process])
end

function _NormalAttack:EnterAttack()
    self._attack:Enter(self._attackDataSet[self._process], self._skill.attackValues[1], self._OnHit)

    local hitStop = self.hitStop
    self._attack.hitstop = hitStop[1]
    self._attack.selfstop = hitStop[2]
    self._attack.shake.time = hitStop[1]

    local soundData = self._soundDataSet.hitting
    self._attack.soundDataSet[#self._attack.soundDataSet + 1] = soundData
end

---@return boolean
function _NormalAttack:HasTick()
    return _ASPECT.GetPart(self._entity.aspect):GetTick() == self._ticks[self._process]
end

---@return int
function _NormalAttack:GetProcess()
    return self._process
end

return _NormalAttack
