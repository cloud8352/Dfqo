--[[
	desc: ReviveState, a state of Swordman.
	author: keke
]]--

local Common = require("UI.ui_common")
local Config = require("config")
local _ASPECT = require("actor.service.aspect")
local LifeSrv = require("actor.service.LifeSrv")
local InventoryItemsSrv = require("actor.service.InventoryItemsSrv")

local _Timer = require("util.gear.timer")
local _Base = require("actor.state.base")

local SoundLib = require("lib.sound")

---@class Actor.State.Duelist.Swordman.ReviveState : Actor.State
local ReviveState = require("core.class")(_Base)

local Range = 100

function ReviveState:Ctor(data, ...)
    _Base.Ctor(self, data, ...)

    self.keyTick = data.keyTick or 16
end

function ReviveState:NormalUpdate(dt, rate)
    _Base.NormalUpdate(self)


    local main = _ASPECT.GetPart(self._entity.aspect) ---@type Graphics.Drawable.Frameani
    if main:GetTick() == self.keyTick then
        self:rebornPartner()
    end
end

function ReviveState:Enter(lateState, skill)
    _Base.Enter(self)

    SoundLib.Play(self._soundDataSet)
end

function ReviveState:rebornPartner()
    local itemInfo = InventoryItemsSrv.GetItemByPath(self._entity, "Attribute/ResurrectionFeather")
    if itemInfo.type == Common.ArticleType.Empty then
        return
    end

    local x = self._entity.transform.position.x
    local y = self._entity.transform.position.y
    local partnerList = Config.user:GetPartnerList()
    for _, partner in pairs(partnerList) do
        local partnerX = partner.transform.position.x
        local partnerY = partner.transform.position.y
        if partner.identity.destroyProcess > 0
            and partnerX > x - Range
            and partnerX < x + Range
            and partnerY > y - Range
            and partnerY < y + Range
        then
            LifeSrv.RebornEntity(partner)

            itemInfo.count = itemInfo.count - 1
            if itemInfo.count <= 0 then
                itemInfo.count = 0
                itemInfo.type = Common.ArticleType.Empty
                itemInfo.path = ""
            end
            InventoryItemsSrv.InsertItemToEntity(self._entity, itemInfo.Index,
                itemInfo.count, itemInfo.path)
            break
        end
    end
end

return ReviveState
