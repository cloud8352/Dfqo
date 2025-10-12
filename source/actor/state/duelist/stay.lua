--[[
	desc: Stay, a state of Duelist.
	author: Musoucrow
	since: 2018-8-19
	alter: 2018-8-7
]]--

local _CONFIG = require("config")
local _STATE = require("actor.service.state")
local _INPUT = require("actor.service.input")

local _Base = require("actor.state.base")

local _TIME = require("lib.time")

---@class Actor.State.Duelist.Stay:Actor.State
local _Stay = require("core.class")(_Base)


function _Stay:Ctor(data, param, name)
    _Base.Ctor(self, data, param, name)

    -- 行走结束时间
    self.movingEndTime = 0
    -- 行走到奔跑之间的响应时间
    self.movingReactTimeS = 0.3
    -- 上次的状态名称
    self.lastStateName = ""
end

function _Stay:NormalUpdate(dt, rate)
    -- 判断上次移动状态结束时间
    if self._entity.states.later then
        if self._entity.states.later:GetName() ~= self.lastStateName then
            self.lastStateName = self._entity.states.later:GetName()
            if self.lastStateName == "move" then
                self.movingEndTime = _TIME.GetTime()
            end
        end
    end

    -- 判断是否按下了方向键
    if _INPUT.IsPressed(self._entity.input, "left")
        or _INPUT.IsPressed(self._entity.input, "right")
        or _INPUT.IsPressed(self._entity.input, "up")
        or _INPUT.IsPressed(self._entity.input, "down")
        or _INPUT.IsHold(self._entity.input, "left")
        or _INPUT.IsHold(self._entity.input, "right")
        or _INPUT.IsHold(self._entity.input, "up")
        or _INPUT.IsHold(self._entity.input, "down")
    then
        local nextStateName = self._nextState
        -- 判断是否为 奔跑
        if _TIME.GetTime() - self.movingEndTime < self.movingReactTimeS then
            if self._entity.transform.direction == -1 and
                _INPUT.IsPressed(self._entity.input, "left") then
                nextStateName = "run"
            end
            if self._entity.transform.direction == 1 and
                _INPUT.IsPressed(self._entity.input, "right") then
                nextStateName = "run"
            end
        else
            -- 行走
        end
        
        if false == _STATE.HasState(self._entity.states, "run") then
            nextStateName = self._nextState
        end

        _STATE.Play(self._entity.states, nextStateName)
        self.lastStateName = "stay"
    end
end

return _Stay
