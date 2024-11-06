--[[
	desc: Can Prepare Skill, actor's action.
	author: keke
	since: 2022-9-4
	alter: 2022-9-4
]]--

local BaseSkill = require("actor.skill.base")

local _TABLE = require("lib.table")
local _INPUT = require("actor.service.input")
local _STATE = require("actor.service.state")

local _Timer = require("util.gear.timer")

---@class Actor.Skill.CanPrepareSkill : Actor.Skill
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
local _CanPrepareSkill = require("core.class")(BaseSkill)

local MaxPrepareTime = 150 -- 最大准备时间，500相当于实际1ms

---@param entity Actor.Entity
---@param key string
---@param data Actor.RESMGR.SkillData
function _CanPrepareSkill:Ctor(entity, key, data)
    BaseSkill.Ctor(self, entity, key, data)

    -- 准备时间
    self.prepareTime = 0
    -- 是否可被键盘触发
    self.canUseByKey = false
end

function _CanPrepareSkill:GetPrepareTime()
    return self.prepareTime
end

function _CanPrepareSkill:Update(dt)
    -- 计算技能冷却时间
    if (self._timer.isRunning) then
        self._timer:Update(dt)

        if (not self._timer.isRunning and self.duraMax) then
            self.dura = self.dura + 1

            if (self.dura < self.duraMax) then
                self._timer:Enter(self.time)
            end
        end
    end

    if (self:CanUse() and _INPUT.IsPressed(self._entity.input, self._key)) then
        -- 开始计算准备时间
        self.prepareTime = 0
        self.canUseByKey = true
    end

    if (self:CanUse() and _INPUT.IsHold(self._entity.input, self._key)) then
        -- 计算准备时间
        self.prepareTime = self.prepareTime + dt

        if (MaxPrepareTime <= self.prepareTime
                and self.canUseByKey) then
            self:Use()
            self.canUseByKey = false
        end
    end

    if (self:CanUse() and _INPUT.IsReleased(self._entity.input, self._key)
            and self.canUseByKey) then
        self:Use()
        self.canUseByKey = false
    end
end

return _CanPrepareSkill
