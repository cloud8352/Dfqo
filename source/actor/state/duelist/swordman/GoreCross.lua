--[[
	desc: GoreCrossState, a state of Swordman.
	author: keke
]]--

local _SOUND = require("lib.sound")
local _FACTORY = require("actor.factory")
local _ASPECT = require("actor.service.aspect")
local _STATE = require("actor.service.state")

local _Attack = require("actor.gear.attack")
local _Easemove = require("actor.gear.easemove")
local _Base = require("actor.state.base")

---@class Actor.State.Duelist.Swordman.GoreCross:Actor.State
---@field protected _attack Actor.Gear.Attack
---@field protected _skill Actor.Skill
---@field protected _ticks table
---@field protected effectList table<int, Actor.Entity>
local GoreCrossState = require("core.class")(_Base)

function GoreCrossState:Ctor(data, ...)
    _Base.Ctor(self, data, ...)

    self._ticks = data.ticks

    self.process = 1
    ---@type table<int, Actor.Entity>
    self.effectList = {}

    self.attackTimeMs = 0
end

function GoreCrossState:Init(entity, ...)
    _Base.Init(self, entity, ...)

    self._attack = _Attack.New(self._entity)
    self._attack.element = _Attack.AttackElementStruct.Fire
end

function GoreCrossState:NormalUpdate(dt, rate)
    local main = _ASPECT.GetPart(self._entity.aspect) ---@type Graphics.Drawable.Frameani
    local tick = main:GetTick()

    self._attack:Update()

    self.attackTimeMs = self.attackTimeMs + dt
    if self.attackTimeMs > 500
        and #self.effectList > 1
    then
        self.attackTimeMs = 0

        self._attack:Enter(self._attackDataSet[2], self._skill.attackValues[1], _, _, true)
        self._attack.collision[_ASPECT.GetPart(self.effectList[2].aspect)] = "attack"
    end

    if (tick == self._ticks[2]) then
        self:setProcess(2)
    elseif (tick == self._ticks[3]) then
        self:setProcess(3)
    end

    _STATE.AutoPlayEnd(self._entity.states, self._entity.aspect, self._nextState)
end

function GoreCrossState:Enter(laterState, skill)
    _Base.Enter(self)

    self._skill = skill
    self._attack:Exit()

    if self._entity.identity.gender == 1 then
        _SOUND.Play(self._soundDataSet.voice)
    end

    self:setProcess(1)

    self.attackTimeMs = 0
end

---@param nextState Actor.State
function GoreCrossState:Exit(nextState)
    _Base.Exit(self, nextState)

    self:destroyEffectList()
    if self.process == 2 then
        self:newBullet()
    end
end

---@param process int
function GoreCrossState:setProcess(process)
    self.process = process
    if process == 1 then
        local effect = _FACTORY.New(self._actorDataSet[1], { entity = self._entity })
        self.effectList[1] = effect
    
        local slashEffect = _FACTORY.New(self._actorDataSet[2], {entity = self._entity})
        self.effectList[2] = slashEffect
    
        self._attack:Enter(self._attackDataSet[1], self._skill.attackValues[1], _, _, true)
        self._attack.collision[_ASPECT.GetPart(slashEffect.aspect)] = "attack"

        _SOUND.Play(self._soundDataSet.swing)
    elseif process == 2 then
        _SOUND.Play(self._soundDataSet.swing)
    elseif process == 3 then
        self:destroyEffectList()

        self:newBullet()
    end
end

function GoreCrossState:destroyEffectList()
    for _, effect in pairs(self.effectList) do
        if effect.identity.destroyProcess == 0 then
            effect.effect.state = nil
            effect.effect.lockStop = false
            effect.identity.destroyProcess = 1
            effect = nil
        end
    end
    self.effectList = {}
end

function GoreCrossState:newBullet()
    local t = self._entity.transform
    local param = {
        x = t.position.x,
        y = t.position.y,
        z = t.position.z,
        direction = t.direction,
        entity = self._entity,
        attackValue = self._skill.attackValues[2]
    }

    _FACTORY.New(self._actorDataSet[3], param)
end

return GoreCrossState
