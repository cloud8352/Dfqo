--[[
	desc: Life, a system of life management.
	author: Musoucrow
	since: 2018-4-23
	alter: 2019-5-11
]]--

local _MAP = require("map.init")
local _ECSMGR = require("actor.ecsmgr")

local _Base = require("actor.system.base")

local Config = require("config")

---@class Actor.System.Life : Actor.System
local _Life = require("core.class")(_Base)

---@param e Actor.Entity
local function addDieCmptForEntity(e)
    _ECSMGR.AddComponent(e, "aspect", e.aspect)
    e.aspect.isPaused = true
    e.aspect.pureColor:Set(0, 0, 0, 0)
    e.aspect.layer:SetAttri("color", 255, 255, 255, 120)
    
    _ECSMGR.AddComponent(e, "duelist", e.duelist)
end

---@param e Actor.Entity
local function IsPartner(e)
    for _, partner in pairs(Config.user:GetPartnerList()) do
        if e == partner then
            return true
        end
    end
    return false
end

function _Life:Ctor(upperEvent)
    _Base.Ctor(self, upperEvent, {
        identity = true
    }, "life")

    _MAP.AddLoadListener(self, self.OnClean)
end

---@param entity Actor.Entity
function _Life:OnInit(entity)
    entity.identity.initCaller:Call(entity)
end

function _Life:OnClean()
    for n=1, self._list:GetLength() do
        local e = self._list:Get(n) ---@type Actor.Entity

        if (not e.identity.canCross) then
            e.identity.destroyProcess = 1
        end
    end
end

function _Life:LateUpdate()
    for n = 1, self._list:GetLength() do
        local e = self._list:Get(n) ---@type Actor.Entity

        if (e.identity.destroyProcess > 0) then
            e.identity.destroyProcess = 2
            e.identity.destroyCaller:Call(e)

            for k in pairs(e) do
                _ECSMGR.DelComponent(e, k)
            end

            if IsPartner(e) then
                addDieCmptForEntity(e)
            end
        end
    end
end

return _Life
