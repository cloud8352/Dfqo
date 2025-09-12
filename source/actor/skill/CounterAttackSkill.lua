--[[
	desc: CounterAttackSkill, a skill for CounterAttack.
	author: keke
]]--

local InputSrv = require("actor.service.input")

local BeatenSkill = require("actor.skill.beaten")

---@class Actor.Skill.CounterAttack : Actor.Skill.Beaten
local CounterAttackSkill = require("core.class")(BeatenSkill)

---@param entity Actor.Entity
---@param key string
---@param data Actor.RESMGR.SkillData
function CounterAttackSkill:Ctor(entity, key, data)
    BeatenSkill.Ctor(self, entity, key, data)
end

function CounterAttackSkill:Update(dt)
    BeatenSkill.Update(self, dt)

    if (self:CanUse() and InputSrv.IsPressed(self._entity.input, "jump")) then
        self:Use()
    end
end

return CounterAttackSkill
