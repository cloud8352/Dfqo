--[[
	desc: LightBarrierBuff, A buff of LightBarrier.
	author: keke
]]--

local _SOUND = require("lib.sound")
local _RESMGR = require("actor.resmgr")
local _FACTORY = require("actor.factory")
local _ASPECT = require("actor.service.aspect")

local _Timer = require("util.gear.timer")
local _Gear_Attack = require("actor.gear.attack")
local _Color = require("graphics.drawunit.color")
local _Base = require("actor.buff.base")

local SoundLib = require("lib.sound")

---@class Actor.Buff.LightBarrierBuff : Actor.Buff
local LightBarrierBuff = require("core.class")(_Base)

---@param data Actor.RESMGR.BuffData
function LightBarrierBuff.HandleData(data)
    ---@type table<int, Actor.RESMGR.InstanceData>
    local effectInstanceDataList = {}
    for i, path in pairs(data.effect) do
        print(path)
        effectInstanceDataList[i] = _RESMGR.GetInstanceData(path)
    end
    data.EffectInstanceDataList = effectInstanceDataList

    ---@type table<int, Actor.RESMGR.SoundData>
    local soundDataList = {}
    for i, path in pairs(data.sound) do
        soundDataList[i] = _RESMGR.GetSoundData(path)
    end
    data.SoundDataList = soundDataList
end

---@param attack Actor.Gear.Attack
---@param entity Actor.Entity
local function _Collide(attack, entity)
    if (attack._entity == entity) then
        local x, y, z = entity.transform.position:Get()

        return true, x, y, z - _ASPECT.GetPart(entity.aspect):GetHeight(true) * 0.5
    end

    return false
end

function LightBarrierBuff:Ctor(entity, data)
    _Base.Ctor(self, entity, data)


    self.EffectInstanceDataList = data.EffectInstanceDataList
    self.SoundDataList = data.SoundDataList

    self.startEffect = _FACTORY.New(self.EffectInstanceDataList[1], { entity = entity })
    SoundLib.Play(self.SoundDataList[1])


    -- self._attackTimer = _Timer.New(data.interval)
    -- self._attackData = data.attack
    -- self._attackValue = data.attackValue
    -- self._attack = _Gear_Attack.New(entity)

    -- self._effect = _FACTORY.New(data.effect, {entity = entity})
end

function LightBarrierBuff:OnUpdate(dt)
    if self.startEffect and self.startEffect.identity.destroyProcess == 2 then
        self.loopEffect = _FACTORY.New(self.EffectInstanceDataList[2], { entity = self._entity })
        self.startEffect = nil
    end

    if self.loopEffect and self.loopEffect.identity.destroyProcess == 2 then
        self.loopEffect = _FACTORY.New(self.EffectInstanceDataList[2], { entity = self._entity })
    end
    -- self._attackTimer:Update(dt)

    -- if (not self._attackTimer.isRunning) then
    --     self._attack:Enter(self._attackData, self._attackValue, _, _Collide)
    --     self._attack:Update()
    --     self._attackTimer:Enter()
    -- end
end

function LightBarrierBuff:Exit()
    if (_Base.Exit(self)) then
        -- self._attackTimer:Exit()
        self.loopEffect.identity.destroyProcess = 1

        _FACTORY.New(self.EffectInstanceDataList[3], { entity = self._entity })
        return true
    end

    return false
end

return LightBarrierBuff
