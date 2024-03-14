--[[
	desc: User, a player manager.
	author: Musoucrow
	since: 2018-6-26
	alter: 2019-9-21
]]--

local _MAP = require("map.init")
local _DUELIST = require("actor.service.duelist")

local _Caller = require("core.caller")

---@class User
---@field public player Actor.Entity
---@field public setPlayerCaller Core.Caller
---@field private partnerList table<Actor.Entity>
local _User = require("core.class")()

function _User:Ctor()
    self.setPlayerCaller = _Caller.New()
    self.partnerList = {}
end

---@param player Actor.Entity
function _User:SetPlayer(player)
    if (self.player == player) then
        return
    end

    if (player) then
        player.ais.enable = false
        player.identity.canCross = true

        _DUELIST.SetAura(player, "player")
        _MAP.camera:SetTarget(player.transform.position)
    end

    if (self.player) then
        self.player.ais.enable = true
        self.player.identity.canCross = false

        if (self.player.identity.destroyProcess == 0) then
            local type = _DUELIST.IsPartner(self.player.battle, self.player.duelist) and "partner" or nil
            _DUELIST.SetAura(self.player, type)
        end
    end

    self.setPlayerCaller:Call(self.player, player)
    self.player = player
end

---@param partner Actor.Entity
function _User:AddPartner(partner)
    -- 是否已在列表中
    local samePartner = nil
    for i, partnerTmp in pairs(self.partnerList) do
        if partnerTmp == partner then
            samePartner = partnerTmp
            break
        end
    end
    if (samePartner) then
        return
    end

    if (partner) then
        partner.ais.enable = true
        -- 设置伙伴可以过地图，否则到达下一个地图就会被销毁，原理见 source\actor\system\life.lua 的 OnClean 函数
        partner.identity.canCross = true 
        _DUELIST.SetAura(partner, "player")
    end

    table.insert(self.partnerList, partner)
end


---@param partner Actor.Entity
function _User:RemovePartner(partner)
    table.remove(self.partnerList, partner)
end

function _User:GetPartnerList()
    return self.partnerList
end

return _User
