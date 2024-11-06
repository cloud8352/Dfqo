--[[
	desc: MasteredSkills, a component.
	author: keke
]]--
local Common = require("UI.ui_common")

local ResMgr = require("actor.resmgr")
local _SKILL = require("actor.service.skill")

local _Caller = require("core.caller")
local _Container = require("core.container")

---@class Actor.Component.MasteredSkills
---@field public container Core.Container
---@field public SkillAddedCaller Core.Caller
---@field public SkillChangedCaller Core.Caller
---@field public List table<int, SkillInfo>
local MasteredSkills = require("core.class")()

function MasteredSkills.HandleData(data)
    for k, v in pairs(data) do
        if (k ~= "class" and type(v) ~= "boolean") then
            -- data[k] = _RESMGR.GetSkillData(v)
        end
    end
end

function MasteredSkills:Ctor(data)
    self.container = _Container.New()
    self.SkillAddedCaller = _Caller.New()
    self.SkillChangedCaller = _Caller.New()
    self.data = data

    ---@type table<int, SkillInfo>
    self.List = {}
    local masteredSkills = data.List or {}
    for i, skillData in pairs(masteredSkills) do
        local skillResMgrData = ResMgr.GetSkillData(skillData.Path)
        local info = Common.NewSkillInfoFromData(skillResMgrData)
        Common.SetExpToSkillInfo(info, skillData.Exp)

        table.insert(self.List, info)
    end
end

function MasteredSkills:GetList()
    return self.List
end

return MasteredSkills
