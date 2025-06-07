--[[
	desc: ArticleWithBuff, a component of ArticleWithBuff.
	author: keke
]]
--

local _RESMGR = require("actor.resmgr")
local Collider = require("actor.collider")

---@class Actor.Component.Article.ArticleWithBuff
local ArticleWithBuff = require("core.class")()

function ArticleWithBuff.HandleData(data)
end

function ArticleWithBuff:Ctor(data)
    self.Collider = Collider.Create(data.collider)
    self.Camp = data.camp or 1
    self.CampType = data.campType or "we"
    self.Interval = data.interval or 500

    ---@type table<int, Actor.RESMGR.BuffData>
    self.BuffDataList = {}
    local buffs = data.buffs
    for n = 1, #buffs do
        if (type(buffs[n]) == "string") then
            self.BuffDataList[n] = _RESMGR.NewBuffData(buffs[n])
        else
            self.BuffDataList[n] = _RESMGR.NewBuffData(buffs[n].path, buffs[n])
        end
    end

    self.AttackData = _RESMGR.GetAttackData(data.attack)
    self.AttackData.camp = self.Camp
    self.AttackData.interval = self.Interval
    self.AttackValue = data.attackValue or {
        damageRate = 1,
        isPhysical = true
    }

    ---@type Actor.Gear.Attack
    self.Attack = nil
end

return ArticleWithBuff
