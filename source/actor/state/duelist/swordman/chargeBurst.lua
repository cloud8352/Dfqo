--[[
	desc: ChargeBurstState, a state of Swordman.
]]--

local SoundLib = require("lib.sound")
local BuffSrv = require("actor.service.buff")
local InputSrv = require("actor.service.input")
local StateSrv = require("actor.service.state")
local AspectSrv = require("actor.service.aspect")
local EffectSrv = require("actor.service.effect")
local BattleSrv = require("actor.service.battle")
local GraphicsDrawUnitPoint = require("graphics.drawunit.point")
local GraphicsDrawUnitColor = require("graphics.drawunit.color")
local EaseMove = require("actor.gear.easemove")
local Attack = require("actor.gear.attack")
local Class = require("core.class")
local BaseState = require("actor.state.base")

local AttackIntervalMs = 500

---@class Actor.State.Duelist.Swordman.ChargeBurstState : Actor.State
local ChargeBurstState = Class(BaseState)

function ChargeBurstState:Ctor(data, ...)
    BaseState.Ctor(self, data, ...)
    self._easemoveParam = data.easemove
    self._keyTick = data.keyTick
    self._stopTime = data.stopTime
    self._overturn = data.overturn
    self._target = GraphicsDrawUnitPoint.New(true)

    self.attackTimeMsCount = 0
end

function ChargeBurstState:Init(entity)
    BaseState.Init(self, entity)
    self._attack = Attack.New(entity)
    self._easemove = EaseMove.New(entity.transform, entity.aspect)
    self.yEaseMove = EaseMove.New(entity.transform, entity.aspect)
end

function ChargeBurstState:_OnHit(targetEntity)
    if not targetEntity.states or not self._overturn then
        return
    end

    BattleSrv.Overturn(targetEntity.battle, targetEntity.states, self._target.x, self._target.y, 0,
        self._overturn.movingTime, self._overturn.delayTime)
end

function ChargeBurstState:NormalUpdate(dt, rate)
    local main = AspectSrv.GetPart(self._entity.aspect) ---@type Graphics.Drawable.Frameani
    local tick = main:GetTick()
    local frame = main:GetFrame()

    self._attack:Update(dt)
    self._easemove:Update(rate)
    self.yEaseMove:Update(rate)

    self.attackTimeMsCount = self.attackTimeMsCount + dt

    if frame > 3 and frame < 6 then
        if InputSrv.IsHold(self._entity.input, "up") then
            self.yEaseMove:Enter("y", 12, 1, -1)
        end
        if InputSrv.IsHold(self._entity.input, "down") then
            self.yEaseMove:Enter("y", 12, 1, 1)
        end
    end

    if frame > 5 and frame < 8 then
        if InputSrv.IsHold(self._entity.input, "up") then
            self.yEaseMove:Enter("y", 6, 1, -1)
        end
        if InputSrv.IsHold(self._entity.input, "down") then
            self.yEaseMove:Enter("y", 6, 1, 1)
        end
    end

    if tick == 3 or tick == 5 or tick == 7 or tick == 9 then
        self:NewFigure()
    end

    if self.attackTimeMsCount > AttackIntervalMs then
        self.attackTimeMsCount = 0

        self._attack:Enter(self._attackDataSet, self._skill.attackValues[1], self._OnHit, nil, true)
        self._attack.collision[main] = "attack"
    end

    if tick == self._keyTick then
        self._easemove:Enter("x", self._easemoveParam.power, self._easemoveParam.speed, self._entity.transform.direction)


        self._buff = BuffSrv.AddBuff(self._entity, self._buffDatas)

        self._attack:Enter(self._attackDataSet, self._skill.attackValues[1], self._OnHit, nil, true)
        self._attack.collision[main] = "attack"

        SoundLib.Play(self._soundDataSet.swing)
        SoundLib.Play(self._soundDataSet.voice)
        self:NewFigure()
    end

    StateSrv.AutoPlayEnd(self._entity.states, self._entity.aspect, self._nextState)
end

function ChargeBurstState:Enter(lastState, skill)
    if (lastState ~= self) then
        BaseState.Enter(self)
        self._skill = skill
        self._attack:Exit()
        self._easemove:Exit()
        self.yEaseMove:Exit()

        self.attackTimeMsCount = 0

        self._tagMap.cancel = false

        if self._target then
            local transform = self._entity.transform
            self._target:Set(transform.position.x + self._overturn.x * transform.direction, transform.position.y)
        end
    end
end

function ChargeBurstState:Exit()
    BaseState.Exit(self)
    if self._buff then
        self._buff:Exit()
        self._buff = nil
    end
end

function ChargeBurstState:NewFigure()
    ---@type Graphics.Drawable.Frameani
    local main = AspectSrv.GetPart(self._entity.aspect)
    local figure = EffectSrv.NewFigure(self._entity.transform, self._entity.aspect, main:GetData())
    figure.aspect.order = -1
    figure.aspect.color:Set(GraphicsDrawUnitColor.red:Get())
    figure.aspect.colorTick = true
end

return ChargeBurstState
