--[[
	desc: BlastBloodBulletSys, a system of bullet.
	author: keke
]]--

local _Base = require("actor.system.base")

local _MAP = require("map.init")
local AspectSrv = require("actor.service.aspect")
local Factory = require("actor.factory")
local SoundLib = require("lib.sound")

---@class Actor.System.Swordman.BlastBloodBulletSys : Actor.System
local BlastBloodBulletSys = require("core.class")(_Base)

function BlastBloodBulletSys:Ctor(upperEvent)
    _Base.Ctor(self, upperEvent, {
        aspect = true,
        transform = true,
        bullet_swordman_blastBlood = true
    }, "bullet_swordman_blastBlood")
end

---@param entity Actor.Entity
function BlastBloodBulletSys:OnEnter(entity)
end

---@param entity Actor.Entity
function BlastBloodBulletSys:OnExit(entity)
end

function BlastBloodBulletSys:Update(dt)
    if (_MAP.GetLoadProcess() > 0) then
        return
    end

    for n = 1, self._list:GetLength() do
        local e = self._list:Get(n) ---@type Actor.Entity
        local bullet = e.bullet_swordman_blastBlood

        local main = AspectSrv.GetPart(e.aspect) ---@type Graphics.Drawable.Frameani
        local tick = main:GetTick()
        if tick == bullet.Tick then
            local transform = e.transform
            local position = transform.position
            local param = {
                x = position.x,
                y = position.y,
                z = position.z,
                direction = transform.direction
            }
        
            Factory.New(bullet.EffectDataMap[1], param)
            Factory.New(bullet.EffectDataMap[2], param)
            SoundLib.Play(bullet.SoundData)
        end
    end
end

return BlastBloodBulletSys
