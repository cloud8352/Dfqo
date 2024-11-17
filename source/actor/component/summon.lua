--[[
	desc: SummonCmpt, a component.
	author: Musoucrow
    since: 2019-6-26
]]--

local _RESMGR = require("actor.resmgr")

---@class Actor.Component.Summon
---@field SummonInfoList table<int, SummonInfo>
local SummonCmpt = require("core.class")()

function SummonCmpt.HandleData(data)
end

function SummonCmpt:Ctor(data)
    self.SummonInfoList = {}
    for n = 1, #data do
        ---@class SummonInfo
        local summonInfo = {
            Path = "",
            SummonWhenEntityDestroy = false;
        }
        summonInfo.Path = data[n].path or ""
        summonInfo.SummonWhenEntityDestroy = data[n].inDestroy or false
        table.insert(self.SummonInfoList, summonInfo)
    end
end

return SummonCmpt
