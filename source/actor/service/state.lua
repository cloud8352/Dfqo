--[[
	desc: STATE, a service for state.
	author: Musoucrow
	since: 2018-5-24
	alter: 2018-12-9
]]--

local _ASPECT = require("actor.service.aspect")
local _RESMGR = require("actor.resmgr")

---@class Actor.Service.STATE
local _STATE = {}

---@param states Actor.Component.States
---@param name string
---@param isOnly boolean
---@param ... params
---@return boolean
function _STATE.Play(states, name, isOnly, ...)
    local lateState = states.current
    local nextState = states.map[name]

    if (not nextState) then
        return false
    elseif (isOnly and lateState == nextState) then
        return false
    end

    if (nextState.Tick and nextState:Tick(lateState, ...)) then
        return false
    end

    if (lateState) then
        if (lateState:Exit(nextState) == false) then
            return false
        end
    end

    states.later = lateState
    states.current = nextState
    states.current:Enter(lateState, ...)
    states.caller:Call()

    return true
end

---@param states Actor.Component.States
function _STATE.HasTag(states, key)
    return states.current:HasTag(key)
end

---@param entity Actor.Entity
---@param name string
---@param stateResMgrDataPath string
function _STATE.SetState(entity, name, stateResMgrDataPath)
    local stateResMgrData = _RESMGR.GetStateData(stateResMgrDataPath)
    ---@type Actor.State
    local state = stateResMgrData.class.New(stateResMgrData)
    state:Init(entity)
    entity.states.map[name] = state
end

---@param states Actor.Component.States
---@param name string
function _STATE.HasState(states, name)
    return states.map[name] ~= nil
end

---@param states Actor.Component.States
---@param isForce boolean
---@return boolean
function _STATE.Reset(states, isForce)
    return _STATE.Play(states, "stay", not isForce)
end

---@param states Actor.Component.States
---@param aspect Actor.Component.Aspect
---@param nextState string
function _STATE.AutoPlayEnd(states, aspect, nextState)
    if (_ASPECT.GetPart(aspect):TickEnd()) then
        _STATE.Play(states, nextState)
    end
end

---@param states Actor.Component.States
function _STATE.ReloadFrameaniData(states)
    for k, v in pairs(states.map) do
        v:InitFrameaniDataSets()
    end
end

return _STATE