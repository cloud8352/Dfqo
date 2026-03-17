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
---@field public TaiSuCount int 太素个数
---@field public MobaTaiSuCount int 一次性游戏中的太素个数
---@field private partnerList table<int, Actor.Entity>
---@field private enemyHeroList table<int, Actor.Entity>
local _User = require("core.class")()

function _User:Ctor()
    self.setPlayerCaller = _Caller.New()

    self.TaiSuCount = 0
    self.OnceGameTaiSuCount = 0

    self.partnerList = {}
    self.enemyHeroList = {}
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
        _DUELIST.SetAura(partner, "partner")
    end

    table.insert(self.partnerList, partner)
end

---@param partner Actor.Entity
function _User:RemovePartner(partner)
    table.remove(self.partnerList, partner)
end

function _User:ClearPartnerList()
    for _, e in pairs(self.partnerList) do
        e.identity.canCross = false
        if e.identity.destroyProcess == 0 then
            e.identity.destroyProcess = 1
        end
    end

    self.partnerList = {}
end

function _User:GetPartnerList()
    return self.partnerList
end

---@param hero Actor.Entity
function _User:AddEnemyHero(hero)
    -- 是否已在列表中
    local sameHero = nil
    for i, heroTmp in pairs(self.enemyHeroList) do
        if heroTmp == hero then
            sameHero = heroTmp
            break
        end
    end
    if (sameHero) then
        return
    end

    if (hero) then
        hero.ais.enable = true
        -- 设置伙伴可以过地图，否则到达下一个地图就会被销毁，原理见 source\actor\system\life.lua 的 OnClean 函数
        hero.identity.canCross = true
        _DUELIST.SetAura(hero, "boss")
    end

    table.insert(self.enemyHeroList, hero)
end

---@param hero Actor.Entity
function _User:RemoveHero(hero)
    table.remove(self.enemyHeroList, hero)
end

function _User:ClearEnemyHeroList()
    for _, e in pairs(self.enemyHeroList) do
        e.identity.canCross = false
        if e.identity.destroyProcess == 0 then
            e.identity.destroyProcess = 1
        end
    end

    self.enemyHeroList = {}
end

function _User:GetEnemyHeroList()
    return self.enemyHeroList
end

return _User
