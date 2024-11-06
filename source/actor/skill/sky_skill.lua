--[[
	desc: SkySkill, actor's skill.
	author: keke
]]--

local BaseSkill = require("actor.skill.base")

---@class Actor.Skill.SkySkill : Actor.Skill
---@field protected _timer Util.Gear.Timer
---@field protected _entity Actor.Entity
---@field protected _judgeAi Actor.Ai.BattleJudge
---@field protected _data Actor.RESMGR.SkillData
---@field protected _key string
---@field public mp int
---@field public time milli
---@field public state string
---@field public coolDown boolean
---@field public order int
---@field public attackValues table<int, Actor.Gear.Attack.AttackValue>
---@field public dura int
---@field public duraMax int
---@field public isCombo boolean
---@field public hpRate number
---@field public isUltimate boolean
local SkySkill = require("core.class")(BaseSkill)

---@return boolean
function SkySkill:Cond()
    local isSame = self._entity.states.current:GetName() == self.state
    
    return (self.isCombo and isSame) or (self._entity.transform.position.z < 0) and (not isSame)
end

return SkySkill
