--[[
	desc: NpcSrv, a service for Npc.
	author: keke
]]--

local Caller = require("core.caller")

local NpcClickedCaller = Caller.New()

---@class Actor.Service.NpcSrv
local NpcSrv = {}

---@param obj table
---@param func function
function NpcSrv.AddListenerToNpcClickedCaller(obj, func)
    NpcClickedCaller:AddListener(obj, func)
end

---@param obj table
---@param func function
function NpcSrv.DelListenerFromNpcClickedCaller(obj, func)
    NpcClickedCaller:DelListener(obj, func)
end

---@param entity Actor.Entity
function NpcSrv.NpcClickedCallerCall(entity)
    NpcClickedCaller:Call(entity)
end

return NpcSrv
