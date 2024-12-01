--[[
	desc: SummonState, a state of direzie.
	author: keke
]]
--

local _SOUND = require("lib.sound")

local _FACTORY = require("actor.factory")
local _ASPECT = require("actor.service.aspect")
local _STATE = require("actor.service.state")

local _Attack = require("actor.gear.attack")
local _Base = require("actor.state.base")
local BuffSrv = require("actor.service.buff")
local Timer = require("util.gear.timer")

---@class Actor.State.Duelist.Direzie.SummonState : Actor.State
---@field protected _skill Actor.Skill
local SummonState = require("core.class")(_Base)

function SummonState:Ctor(data, ...)
    _Base.Ctor(self, data, ...)

    self.tick = data.tick
    self.maxCount = data.count or 1
    self.count = 0
    self.intervalMs = data.interval
    self.rangeX = 100
    self.rangeY = 70
    if data.range then
        self.rangeX = data.range.x
        self.rangeY = data.range.y
    end
end

function SummonState:Init(entity)
    _Base.Init(self, entity)

    self.timer = Timer.New()
end

function SummonState:NormalUpdate(dt, rate)
    local main = _ASPECT.GetPart(self._entity.aspect) ---@type Graphics.Drawable.Frameani
    local tick = main:GetTick()

    self.timer:Update(dt)
    if tick == self.tick then
        self.timer:Enter(self.intervalMs)
    end

    if false == self.timer.isRunning then
        local transform = self._entity.transform
        local position = transform.position
        local param = {
            x = position.x + math.random(0, 2 * self.rangeX) - self.rangeX,
            y = position.y + math.random(0, 2 * self.rangeY) - self.rangeY,
            z = position.z,
            direction = transform.direction,
            entity = self._entity,
            camp = 2,
        }
        _FACTORY.New(self._actorDataSet, param)

        _SOUND.Play(self._soundDataSet.voice[1])

        self.timer:Enter(self.intervalMs)
        self.count = self.count + 1
    end

    -- 攻击结束
    if self.count > self.maxCount then
        _STATE.Play(self._entity.states, self._nextState)
    end

    _STATE.AutoPlayEnd(self._entity.states, self._entity.aspect, self._nextState)
end

function SummonState:Enter(lastState, skill)
    if (lastState ~= self) then
        _Base.Enter(self)

        self._skill = skill

        self.count = 0
    end
end

function SummonState:Exit(nextState)
    if (nextState == self) then
        return
    end

    _Base.Exit(self, nextState)
    self.timer:Exit()
end

return SummonState
