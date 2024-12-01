--[[
	desc: DashState, a state of direzie.
	author: keke
]]
--

local _SOUND = require("lib.sound")

local _FACTORY = require("actor.factory")
local _ASPECT = require("actor.service.aspect")
local _STATE = require("actor.service.state")

local _Attack = require("actor.gear.attack")
local _Base = require("actor.state.base")
local EaseMove = require("actor.gear.easemove")
local BuffSrv = require("actor.service.buff")
local JumpGear = require("actor.gear.jump")

---@class Actor.State.Duelist.Direzie.DashState : Actor.State
---@field protected _skill Actor.Skill
---@field protected _attack Actor.Gear.Attack
---@field protected xEaseMove Actor.Gear.Easemove
---@field protected jumpGear Actor.Gear.Jump
---@field protected buff Actor.Buff
local DashState = require("core.class")(_Base)

local function jumpStatusChangedCallBack(param)
end

function DashState:Ctor(data, ...)
    _Base.Ctor(self, data, ...)
    self.easeMoveParamsList = data.easemoves
    self.tick = data.tick
end

function DashState:Init(entity)
    _Base.Init(self, entity)
    self.xEaseMove = EaseMove.New(self._entity.transform, self._entity.aspect)
    self.jumpGear = JumpGear.New(self._entity.transform, self._entity.aspect, jumpStatusChangedCallBack)
    self._attack = _Attack.New(self._entity)
end

function DashState:NormalUpdate(dt, rate)
    local main = _ASPECT.GetPart(self._entity.aspect) ---@type Graphics.Drawable.Frameani
    local tick = main:GetTick()

    self.xEaseMove:Update(rate)
    self.jumpGear:Update(rate)

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
        local bullet = _FACTORY.New(self._actorDataSet, param)

        local xEaseMoveParams = self.easeMoveParamsList[1]
        self.xEaseMove:Enter("x", xEaseMoveParams.power, xEaseMoveParams.speed, transform.direction)
        local jumpEaseMoveParams = self.easeMoveParamsList[2]
        self.jumpGear:Enter(jumpEaseMoveParams.power, jumpEaseMoveParams.upSpeed,
            jumpEaseMoveParams.downSpeed)

        -- sound
        _SOUND.Play(self._soundDataSet.voice[1])
        _SOUND.Play(self._soundDataSet.ready[1])
        _SOUND.Play(self._soundDataSet.swing)

        -- attack
        self._attack:Enter(self._attackDataSet, self._skill.attackValues[1])
        self._attack.collision[_ASPECT.GetPart(bullet.aspect)] = "attack"
        self._attack.collision[_ASPECT.GetPart(self._entity.aspect)] = "attack"
    end

    self._attack:Update(dt)

    _STATE.AutoPlayEnd(self._entity.states, self._entity.aspect, self._nextState)
end

function DashState:Enter(lastState, skill)
    if (lastState ~= self) then
        _Base.Enter(self)

        self._skill = skill
        self.xEaseMove:Exit()
        self.jumpGear:Exit()

        self.buff = BuffSrv.AddBuff(self._entity, self._buffDatas)
    end
end

function DashState:Exit(nextState)
    if (nextState == self) then
        return
    end

    _Base.Exit(self, nextState)
    if self.buff then
        self.buff:Exit()
    end
end

return DashState
