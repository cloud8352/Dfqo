--[[
	desc: BlastBloodBullet, a bullet of swordman.
	author: keke
]]--

local _RESOURCE = require("lib.resource")
local _RESMGR = require("actor.resmgr")

---@class Actor.Component.Bullet.Swordman.BlastBloodBullet
---@field SoundData SoundData
---@field Tick int
---@field Interval int
---@field HitCount int
---@field EffectDataMap table<string, Actor.RESMGR.InstanceData>
local BlastBloodBullet = require("core.class")()

function BlastBloodBullet.HandleData(data)
    data.SoundData = _RESOURCE.Recur(_RESMGR.GetSoundData, data.sound)
    data.EffectDataMap = _RESOURCE.Recur(_RESMGR.GetInstanceData, data.effect, "aspect")
end

function BlastBloodBullet:Ctor(data, param)
    self.SoundData = data.SoundData
    self.Tick = data.tick
    self.Interval = data.interval or 100
    self.HitCount = data.HitCount or 1
    self.EffectDataMap = data.EffectDataMap
end

return BlastBloodBullet
