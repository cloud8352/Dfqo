--[[
	desc: Npc, a component.
	author: keke
]]--

local ResMgr = require("actor.resmgr")

local Collider = require("actor.collider")

---@class Actor.Component.Npc
---@field public VoiceDataList table<int, SoundData>
---@field public TalkingSource Source
local Npc = require("core.class")()

function Npc.HandleData(data)
end

function Npc:Ctor(data)
    self.data = data

    self.Intro = data.Intro or ""

    ---@type table<int, SoundData>
    self.NormalVoiceDataList = {}
    
    local voicePathList = data.NormalVoicePathList or {}
    for _, v in pairs(voicePathList) do
        local s = ResMgr.GetSoundData(v)
        table.insert(self.NormalVoiceDataList, s)
    end

    ---@type table<int, SoundData>
    self.WelcomeVoiceDataList = {}
    voicePathList = data.WelcomeVoicePathList or {}
    for _, v in pairs(voicePathList) do
        local s = ResMgr.GetSoundData(v)
        table.insert(self.WelcomeVoiceDataList, s)
    end

    ---@type table<int, SoundData>
    self.LeaveVoiceDataList = {}
    voicePathList = data.LeaveVoicePathList or {}
    for _, v in pairs(voicePathList) do
        local s = ResMgr.GetSoundData(v)
        table.insert(self.LeaveVoiceDataList, s)
    end

    ---@type Source
    self.TalkingSource = nil
    ---@type int
    self.TalkingWaitTimeMs = 0

    -- 交互 检测 碰撞盒
    local colliderData = {
        {
            x = -50,
            y1 = -20,
            z = 0,
            y2 = 30,
            w = 100,
            h = 150
        }
    }
    self.InteractingCollider = Collider.Create(colliderData)
end

return Npc
