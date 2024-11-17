--[[
	desc: Summon, a system for summon business.
	author: Musoucrow
    since: 2019-5-4
    alter: 2019-6-15
]]--

local _FACTORY = require("actor.factory")

local _Base = require("actor.system.base")

---@class Actor.System.Summon : Actor.System
local _Summon = require("core.class")(_Base)

---@param entity Actor.Entity
---@param summonInfo SummonInfo
local function _NewActor(entity, summonInfo)
    local t = entity.transform
    local p = {}
    setmetatable(p, { __index = summonInfo })
    
    p.x = t.position.x
    p.y = t.position.y
    p.z = p.z or t.position.z
    p.direction = p.direction or t.direction
    p.entity = p.isSuperior and entity.identity.superior or entity
    _FACTORY.New(summonInfo.Path, p)
end

function _Summon:Ctor(upperEvent)
    _Base.Ctor(self, upperEvent, {
        summon = true
    }, "summon")
end

---@param entity Actor.Entity
function _Summon:OnEnter(entity)
    local summonInfoList = entity.summon.SummonInfoList

    for n = 1, #summonInfoList do
        if (not summonInfoList[n].SummonWhenEntityDestroy) then
            _NewActor(entity, summonInfoList[n])
        end
    end
end

---@param entity Actor.Entity
function _Summon:OnExit(entity)
    local summonInfoList = entity.summon.SummonInfoList

    for n = 1, #summonInfoList do
        if (summonInfoList[n].inDestroy) then
            _NewActor(entity, summonInfoList[n])
        end
    end
end

return _Summon
