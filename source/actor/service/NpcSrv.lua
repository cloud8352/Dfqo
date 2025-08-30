--[[
	desc: NpcSrv, a service for Npc.
	author: keke
]]--

local Caller = require("core.caller")

local SoundLib = require("lib.sound")

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

---@param npc Actor.Component.Npc
function NpcSrv.PlayWelcomeVoice(npc)
    if #npc.WelcomeVoiceDataList < 1 then
        return
    end

    if npc.TalkingSource then
        SoundLib.StopSource(npc.TalkingSource)
    end

    local index = math.random(1, #npc.WelcomeVoiceDataList)
    local soundData = npc.WelcomeVoiceDataList[index]
    npc.TalkingSource = SoundLib.Play(soundData)
end

---@param npc Actor.Component.Npc
function NpcSrv.PlayLeaveVoice(npc)
    if #npc.LeaveVoiceDataList < 1 then
        return
    end

    if npc.TalkingSource then
        SoundLib.StopSource(npc.TalkingSource)
    end

    local index = math.random(1, #npc.LeaveVoiceDataList)
    local soundData = npc.LeaveVoiceDataList[index]
    npc.TalkingSource = SoundLib.Play(soundData)
end

return NpcSrv
