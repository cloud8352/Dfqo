--[[
	desc: DarkFlame, a state of Iori.
]]--

local _SOUND = require("lib.sound")
local _TABLE = require("lib.table")
local _FACTORY = require("actor.factory")
local _RESMGR = require("actor.resmgr")
local _ASPECT = require("actor.service.aspect")
local _STATE = require("actor.service.state")
local _INPUT = require("actor.service.input")
local _EQUIPMENT = require("actor.service.equipment")
local _BUFF = require("actor.service.buff")
local _EFFECT = require("actor.service.effect")
local _MOTION = require("actor.service.motion")
local _TIME = require("lib.time")

local _Easemove = require("actor.gear.easemove")
local _Attack = require("actor.gear.attack")
local _Base = require("actor.state.base")
local Timer = require("util.gear.timer")

---@class Actor.State.Duelist.Iori.DarkFlame : Actor.State
---@field protected attack Actor.Gear.Attack
---@field protected _skill Actor.Skill
---@field protected _effect Actor.Entity
---@field protected buff Actor.Buff
local DarkFlame = require("core.class")(_Base)

function DarkFlame:Ctor(data, ...)
    _Base.Ctor(self, data, ...)
end

function DarkFlame:Init(entity)
    _Base.Init(self, entity)

    self.buff = nil

    self.attack = _Attack.New(self._entity)
    self.attack.element = _Attack.AttackElementStruct.Fire
end

function DarkFlame:NormalUpdate(dt, rate)
    local main = _ASPECT.GetPart(self._entity.aspect) ---@type Graphics.Drawable.Frameani
    local tick = main:GetTick()

    self.attack:Update(dt)

    if tick == 4 then
        self:EnterAttack()

        -- buff
        if self.buff == nil then
            self.buff = _BUFF.AddBuff(self._entity, self._buffDatas)
        end
        
        -- 震荡波
        local t = self._entity.transform
        local param = {
            x = t.position.x + 75 * t.direction,
            y = t.position.y,
            z = t.position.z,
            direction = t.direction,
            entity = self._entity
        }

        local endOnGroundBulletEntity = _FACTORY.New(self._actorDataSet[1], param)
    end

    _STATE.AutoPlayEnd(self._entity.states, self._entity.aspect, self._nextState)
end

function DarkFlame:Enter(laterState, skill)
    _Base.Enter(self)

    _SOUND.Play(self._soundDataSet.voice)
end

function DarkFlame:Exit(nextState)
    if (nextState == self) then
        return
    end
    
    _Base.Exit(self, nextState)

    if (self.buff) then
        self.buff:Exit()
    end
end

function DarkFlame:EnterAttack()
    local skillAttackValues = {
        {
            damageRate = 0.5,
            isPhysical = true
        }
    }

    self.attack:Enter(self._attackDataSet[1], skillAttackValues[1], _)
end

return DarkFlame
