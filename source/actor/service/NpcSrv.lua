--[[
	desc: NpcSrv, a service for Npc.
	author: keke
]]--

local Caller = require("core.caller")

local CallerNpcClicked = Caller.New()
local CallerNpcCanInteractChanged = Caller.New()

---@class Actor.Service.NpcSrv
local NpcSrv = {}

---@param obj table
---@param func function
function NpcSrv.AddListenerToCallerNpcClicked(obj, func)
    CallerNpcClicked:AddListener(obj, func)
end

---@param obj table
---@param func function
function NpcSrv.DelListenerFromCallerNpcClicked(obj, func)
    CallerNpcClicked:DelListener(obj, func)
end

---@param entity Actor.Entity
function NpcSrv.CallerNpcClickedCall(entity)
    CallerNpcClicked:Call(entity)
end

---@param obj table
---@param func function
function NpcSrv.AddListenerToCallerNpcCanInteractChanged(obj, func)
    CallerNpcCanInteractChanged:AddListener(obj, func)
end

---@param obj table
---@param func function
function NpcSrv.DelListenerFromCallerNpcCanInteractChanged(obj, func)
    CallerNpcCanInteractChanged:DelListener(obj, func)
end

---@param entity Actor.Entity
function NpcSrv.CallerNpcCanInteractChangedCall(entity)
    CallerNpcCanInteractChanged:Call(entity)
end

return NpcSrv
