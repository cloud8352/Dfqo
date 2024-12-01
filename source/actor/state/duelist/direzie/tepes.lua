--[[
	desc: TepesState, a state of direzie.
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

---@class Actor.State.Duelist.Direzie.TepesState : Actor.State
---@field protected _skill Actor.Skill
local TepesState = require("core.class")(_Base)

function TepesState:Ctor(data, ...)
    _Base.Ctor(self, data, ...)

    self.maxCount = data.count or 1
    self.count = 0
    self.readyTimeMs = data.readyTime
    self.intervalMs = math.random(data.interval[1], data.interval[2])
    self.rangeX = data.range.x
    self.rangeY = data.range.y
end

function TepesState:Init(entity)
    _Base.Init(self, entity)

    self.timer = Timer.New()
end

function TepesState:NormalUpdate(dt, rate)
    local main = _ASPECT.GetPart(self._entity.aspect) ---@type Graphics.Drawable.Frameani

    self.timer:Update(dt)
    if false == self.timer.isRunning then
        local transform = self._entity.transform
        local position = transform.position
        local param = {
            x = position.x + math.random(0, 2 * self.rangeX) - self.rangeX,
            y = position.y + math.random(0, 2 * self.rangeY) - self.rangeY,
            z = position.z,
            direction = transform.direction,
            entity = self._entity
        }
        _FACTORY.New(self._actorDataSet[1], param)
        _FACTORY.New(self._actorDataSet[2], param)

        _SOUND.Play(self._soundDataSet.voice)

        self.timer:Enter(self.intervalMs)
        self.count = self.count + 1
    end

    -- 攻击结束
    if self.count > self.maxCount then
        _STATE.Play(self._entity.states, self._nextState)
    end

    _STATE.AutoPlayEnd(self._entity.states, self._entity.aspect, self._nextState)
end

function TepesState:Enter(lastState, skill)
    if (lastState ~= self) then
        _Base.Enter(self)

        self._skill = skill

        self.count = 0
        self.timer:Enter(self.readyTimeMs)
        _SOUND.Play(self._soundDataSet.ready)
    end
end

function TepesState:Exit(nextState)
    if (nextState == self) then
        return
    end

    _Base.Exit(self, nextState)
    self.timer:Exit()
end

return TepesState
