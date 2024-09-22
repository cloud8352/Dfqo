--[[
	desc: MasteredSkills, a component.
	author: keke
]]--

local ResMgr = require("actor.resmgr")
local _SKILL = require("actor.service.skill")

local _Caller = require("core.caller")
local _Container = require("core.container")

---@class Actor.Component.MasteredSkills
---@field public container Core.Container
---@field public caller Core.Caller
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
    self.caller = _Caller.New()
    self.data = data

    ---@type table<int, Actor.RESMGR.SkillData>
    self.list = {}
    local masteredSkills = data.List
    for i, path in pairs(masteredSkills) do
        local skillResMgrData = ResMgr.GetSkillData(path)

        table.insert(self.list, skillResMgrData)
    end
end

function MasteredSkills:GetList()
    return self.list
end

return MasteredSkills
