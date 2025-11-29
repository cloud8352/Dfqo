--[[
	desc: ShootBomb, a state of Turret.
	author: keke
]]--

local _Base = require("actor.state.base")
local _FACTORY = require("actor.factory")
local AspectSrv = require("actor.service.aspect")
local StateSrv = require("actor.service.state")

---@class Actor.State.Duelist.Turret.ShootBomb : Actor.State
local ShootBomb = require("core.class")(_Base)

function ShootBomb:Ctor(data, ...)
    _Base.Ctor(self, data, ...)
    
    ---@type Actor.Skill
    self.skill = nil
end

function ShootBomb:NormalUpdate()
    local main = AspectSrv.GetPart(self._entity.aspect) ---@type Graphics.Drawable.Frameani
    local tick = main:GetTick()

    if (tick == 1) then
        local t = self._entity.transform
        local target = self.skill:GetAITarget()

        local param = {
            x = t.position.x + 0 * t.scale.x * t.direction,
            y = t.position.y + 0,
            z = t.position.z - 50 * t.scale.y,
            direction = t.direction,
            entity = self._entity,
            attackValue = self.skill.attackValues[1],
            IsMissile = true,
            TargetEntity = target
        }

        local a = _FACTORY.New(self._actorDataSet[1], param)

    end
    
    StateSrv.AutoPlayEnd(self._entity.states, self._entity.aspect, self._nextState)
end

function ShootBomb:Enter(lastState, skill)
    _Base.Enter(self)

    self.skill = skill
end

function ShootBomb:Exit()
    _Base.Exit(self)
end

return ShootBomb
