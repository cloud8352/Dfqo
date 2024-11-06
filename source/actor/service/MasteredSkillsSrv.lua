--[[
	desc: MasteredSkillsSrv, a service for MasteredSkills.
	author: keke
]]--

local Common = require("UI.ui_common")

local ResMgr = require("actor.resmgr")

---@class Actor.Service.MasteredSkillsSrv
local MasteredSkillsSrv = {}

---@param masteredSkillsCmpt Actor.Component.MasteredSkills
---@param obj table
---@param func function
function MasteredSkillsSrv.AddListenerToSkillAddedCaller(masteredSkillsCmpt, obj, func)
    masteredSkillsCmpt.SkillAddedCaller:AddListener(obj, func)
end

---@param masteredSkillsCmpt Actor.Component.MasteredSkills
---@param obj table
---@param func function
function MasteredSkillsSrv.DelListenerFromSkillAddedCaller(masteredSkillsCmpt, obj, func)
    masteredSkillsCmpt.SkillAddedCaller:DelListener(obj, func)
end

---@param masteredSkillsCmpt Actor.Component.MasteredSkills
---@param obj table
---@param func function
function MasteredSkillsSrv.AddListenerToSkillChangedCaller(masteredSkillsCmpt, obj, func)
    masteredSkillsCmpt.SkillChangedCaller:AddListener(obj, func)
end

---@param masteredSkillsCmpt Actor.Component.MasteredSkills
---@param obj table
---@param func function
function MasteredSkillsSrv.DelListenerFromSkillChangedCaller(masteredSkillsCmpt, obj, func)
    masteredSkillsCmpt.SkillChangedCaller:DelListener(obj, func)
end

---@param masteredSkillsCmpt Actor.Component.MasteredSkills
---@param skillConfigPath string
function MasteredSkillsSrv.AddSkillToMasteredSkillsCmpt(masteredSkillsCmpt, skillConfigPath)
    local list = masteredSkillsCmpt:GetList()
    ---@type SkillInfo
    local sameSkillInfo = MasteredSkillsSrv.GetSkillInfoFromMasteredSkillsCmptByPath(masteredSkillsCmpt,
        skillConfigPath)
    if sameSkillInfo.resDataPath ~= "" then
        Common.AddExpOfSkillInfo(sameSkillInfo, 100)
        masteredSkillsCmpt.SkillChangedCaller:Call(sameSkillInfo)
    else
        local skillResMgrData = ResMgr.GetSkillData(skillConfigPath)
        local skillInfo = Common.NewSkillInfoFromData(skillResMgrData)
        table.insert(list, skillInfo)

        masteredSkillsCmpt.SkillAddedCaller:Call(skillInfo)
    end
end

---@param masteredSkillsCmpt Actor.Component.MasteredSkills
---@param skillConfigPath string
---@param exp int
function MasteredSkillsSrv.AddSkillExp(masteredSkillsCmpt, skillConfigPath, exp)
    local info = MasteredSkillsSrv.GetSkillInfoFromMasteredSkillsCmptByPath(masteredSkillsCmpt,
        skillConfigPath)
    if info.resDataPath ~= "" then
        Common.AddExpOfSkillInfo(info, exp)
        masteredSkillsCmpt.SkillChangedCaller:Call(info)
    end
end

---@param masteredSkillsCmpt Actor.Component.MasteredSkills
---@param skillConfigPath string
---@return SkillInfo
function MasteredSkillsSrv.GetSkillInfoFromMasteredSkillsCmptByPath(masteredSkillsCmpt, skillConfigPath)
    local list = masteredSkillsCmpt:GetList()
    ---@type SkillInfo
    local sameSkillInfo = Common.NewSkillInfo()
    for _, info in pairs(list) do
        if info.resDataPath == skillConfigPath then
            sameSkillInfo = info
            break
        end
    end

    return sameSkillInfo
end

return MasteredSkillsSrv
