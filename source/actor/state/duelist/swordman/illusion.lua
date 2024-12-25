--[[
    desc: IllusionState, a state of Swordman.
]]--

local Class = require("core.class")
local BaseState = require("actor.state.base")
local Map = require("map.init")

local SoundLib = require("lib.sound")
local ActorFactory = require("actor.factory")
local AspectSrv = require("actor.service.aspect")
local StateSrv = require("actor.service.state")
local BuffSrv = require("actor.service.buff")
local EffectSrv = require("actor.service.effect")
local MotionSrv = require("actor.service.motion")
local GraphicsDrawUnitColor = require("graphics.drawunit.color")
local Attack = require("actor.gear.attack")
local EaseMove = require("actor.gear.easemove")

---@class Actor.State.Duelist.Swordman.IllusionState : Actor.State
local IllusionState = Class(BaseState)

function IllusionState:Ctor(data, ...)
    BaseState.Ctor(self, data, ...)
    self._shake = data.shake
    self._aniOrder = data.aniOrder
    self._effectOffset = data.effectOffset
    self._moveValue = data.moveValue
    self._ticks = data.ticks
    self._easemoveParam = data.easemove
end

function IllusionState:Init(entity)
    BaseState.Init(self, entity)
    self._attack = Attack.New(entity)
    self._easemove = EaseMove.New(entity.transform, entity.aspect)
end

function IllusionState:NormalUpdate(deltaTime, rate)
    local main = AspectSrv.GetPart(self._entity.aspect)
    local tick = main:GetTick()
    local effectTick = math.random(self._ticks[1], self._ticks[2])

    self._attack:Update(deltaTime)
    self._easemove:Update(rate)

    if tick == effectTick then
        self:addFigure()

        local effectIndex = self._process
        if effectIndex > 4 then
            effectIndex = 4
        end
        self:addEffect(effectIndex, false, 1)
    end

    if main:TickEnd() and self._process and self._process < #self._aniOrder then
        self:setProcess(self._process + 1)
    end

    StateSrv.AutoPlayEnd(self._entity.states, self._entity.aspect, self._nextState)
end

function IllusionState:Enter(lastState, skill)
    BaseState.Enter(self)
    self._hasHit = false
    self._skill = skill
    self._buff = BuffSrv.AddBuff(self._entity, self._buffDatas)
    self:playSound(self._soundDataSet.voice)
    self:setProcess(1)
end

function IllusionState:Exit()
    BaseState.Exit(self)
    self._attack:Exit()
    self._easemove:Exit()
    if self._buff then
        self._buff:Exit()
        self._buff = nil
    end
end

function IllusionState:hitBegin()
    self._hasHit = true
end

function IllusionState:hitEnd()
    self:addShake(2)
end

---@param effectIndex int
---@param whetherRotate boolean
---@param effectOffsetIndex int
function IllusionState:addEffect(effectIndex, whetherRotate, effectOffsetIndex)
    local xOffset, zOffset = 0, 0
    if effectOffsetIndex and self._effectOffset and self._effectOffset[effectOffsetIndex] then
        xOffset = self._effectOffset[effectOffsetIndex].x * self._entity.transform.direction
        zOffset = self._effectOffset[effectOffsetIndex].z
    end
    local effect = ActorFactory.New(self._actorDataSet[effectIndex], {
        x = self._entity.transform.position.x + xOffset,
        y = self._entity.transform.position.y,
        z = self._entity.transform.position.z + zOffset,
        direction = self._entity.transform.direction,
        entity = self._entity
    })
    if whetherRotate and effect and effect.transform then
        effect.transform.radian:Set(-45 * self._entity.transform.direction, true)
        effect.transform.scaleTick = true
    end
    return effect
end

function IllusionState:addShake(level)
    level = level or 1
    local shakeData = self._shake[level]
    Map.camera:Shake(
        shakeData.time,
        shakeData.xa,
        shakeData.xb,
        shakeData.ya,
        shakeData.yb
    )
end

function IllusionState:addFigure()
    local figure = EffectSrv.NewFigure(self._entity.transform, self._entity.aspect, AspectSrv.GetPart(self._entity.aspect):GetData())
    if figure and figure.aspect then
        figure.aspect.order = -1
        figure.aspect.color:Set(GraphicsDrawUnitColor.blue:Get())
        figure.aspect.colorTick = true
    end
end

function IllusionState:playSound(soundData)
    if type(soundData) == "table" then
        local soundResource = self._soundDataSet[soundData]
        if soundResource then
            SoundLib.Play(soundResource)
        else
            print("Invalid sound data key")
        end
    else
        SoundLib.Play(soundData)
    end
end

---@param process int
function IllusionState:setProcess(process)
    local main = AspectSrv.GetPart(self._entity.aspect)
    self._process = process

    local aniIndex = self._aniOrder[process]
    AspectSrv.Play(self._entity.aspect, self._frameaniDataSets[aniIndex])

    if process == 1 then
        self:addShake()
        self:playSound(self._soundDataSet.effect[2])
        local hitBeginFunc = function(caller, enemy)
            self:hitBegin()
        end
        self._attack:Enter(self._attackDataSet[1], self._skill.attackValues[1], hitBeginFunc, nil, true)
        self._attack.collision[main] = "attack"
    elseif process == 2 then
        self:playSound(self._soundDataSet.effect[2])
        self:addShake()
        self._attack:Enter(self._attackDataSet[2], self._skill.attackValues[2], nil, nil, true)
        self._attack.collision[main] = "attack"
    elseif process == 3 then
        self:playSound(self._soundDataSet.effect[3])
        self:addShake()
        self._attack:Enter(self._attackDataSet[3], self._skill.attackValues[3], nil, nil, true)
        self._attack.collision[main] = "attack"
    elseif process == 4 then
        self:playSound(self._soundDataSet.effect[3])
        self:addShake(2)
        local hitEndFunc = function(caller, enemy)
            self:hitEnd()
        end
        self._attack:Enter(self._attackDataSet[3], self._skill.attackValues[3], hitEndFunc, nil, true)
        self._attack.collision[main] = "attack"
    elseif process == 5 then
        self:playSound(self._soundDataSet.effect[5])
        MotionSrv.Move(self._entity.transform, self._entity.aspect, "x", self._moveValue * self._entity.transform.direction)
        self._attack:Enter(self._attackDataSet[3], self._skill.attackValues[3], self._HitEnd, nil, true)
        self._attack.collision[main] = "attack"
        self._entity.transform.direction = -self._entity.transform.direction
        self._entity.transform.scaleTick = true
        self._easemove:Enter("x", self._easemoveParam.power, self._easemoveParam.speed, -self._entity.transform.direction)
    end
end

return IllusionState
