--[[
	desc: LifeSrv, a service for life.
	author: keke
]]--

local Color = require("graphics.drawunit.color")
local AttributeSrv = require("actor.service.attribute")
local EcsMgr = require("actor.ecsmgr")

---@class Actor.Service.LifeSrv
local LifeSrv = {}


local List = EcsMgr.NewComboList({ identity = true })

---@param entity Actor.Entity
function LifeSrv.RebornEntity(entity)
    entity.battle.deadProcess = 0
    entity.identity.destroyProcess = 0
    entity.aspect.pureColor = Color.New(_, _, _, 0)
    AttributeSrv.AddHp(entity.attributes, entity.attributes.maxHp)

    for k, component in pairs(entity) do
        EcsMgr.AddComponent(entity, k, component)
    end
end

---@param entity Actor.Entity
function LifeSrv.Kill(entity)
    if entity.identity.destroyProcess == 0 then
        entity.identity.destroyProcess = 1
    end
end

function LifeSrv.KillAllEntity()
    for n = 1, List:GetLength() do
        local e = List:Get(n) ---@type Actor.Entity
        LifeSrv.Kill(e)
    end
end

return LifeSrv
