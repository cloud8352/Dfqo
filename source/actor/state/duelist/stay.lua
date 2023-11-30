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

    -- 之前是否是 行走
    self.isMovingAFewTimeAgo = false
    -- 行走结束时间
    self.movingEndTime = 0
    -- 行走到奔跑之间的响应时间
    self.movingReactTimeS = 0.7
    -- 上次的状态名称
    self.lastStateName = ""
end

function _Stay:NormalUpdate(dt, rate)
    -- 判断上次移动状态结束时间
    if self._entity.states.later then
        if self._entity.states.later:GetName() ~= self.lastStateName then
            self.lastStateName = self._entity.states.later:GetName()
            -- print(lastStateName)
            if self.lastStateName == "move" then
                -- print("last frame move")
                self.movingEndTime = _TIME.GetTime()
            end
        end
    end

    -- 判断是否为 奔跑
    if _TIME.GetTime() - self.movingEndTime > self.movingReactTimeS then
        self.isMovingAFewTimeAgo = false
    else
        self.isMovingAFewTimeAgo = true
    end
    if self.isMovingAFewTimeAgo then
        if self._entity.transform.direction == -1 and
            _INPUT.IsHold(self._entity.input, "left") then
            _STATE.Play(self._entity.states, "run")
            self.lastStateName = "run"
            return
        end
        if self._entity.transform.direction == 1 and
            _INPUT.IsHold(self._entity.input, "right") then
            _STATE.Play(self._entity.states, "run")
            self.lastStateName = "run"
            return
        end
    end

    -- 判断是否为 行走
    for n=1, #_CONFIG.arrow do
        if (_INPUT.IsHold(self._entity.input, _CONFIG.arrow[n])) then
            _STATE.Play(self._entity.states, self._nextState)
            self.lastStateName = "stay"
            return
        end
    end
end

return _Stay