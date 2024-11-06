--[[
	desc: JumpSkill, actor's skill.
	author: keke
]]--

local BaseSkill = require("actor.skill.base")

---@class Actor.Skill.JumpSkill : Actor.Skill
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
local JumpSkill = require("core.class")(BaseSkill)

---@return boolean
function JumpSkill:CanUse()
    -- 只有当前状态为 stay 或 move 或 run，才可以使用跳跃技能
    local currentStateName = ""
    if self._entity.states.later then
        currentStateName = self._entity.states.current:GetName()
    end
    local isLastStateNameStayOrMoveOrRun = (currentStateName == "stay") or
        (currentStateName == "move") or (currentStateName == "run")

    return BaseSkill.CanUse(self) and isLastStateNameStayOrMoveOrRun
end

return JumpSkill
