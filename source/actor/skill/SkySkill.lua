--[[
	desc: SkySkill, actor's skill in sky.
	author: keke
]]--

local BaseSkill = require("actor.skill.base")

---@class Actor.Skill.SkySkill : Actor.Skill
local SkySkill = require("core.class")(BaseSkill)

---@return boolean
function SkySkill:Cond()
    local isJumping = self._entity.states.current:GetName() == "jump"
    return isJumping and (self._entity.transform.position.z < 0)
end

return SkySkill
