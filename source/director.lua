--[[
	desc: DIRECTOR, the game manager.
	author: Musoucrow
	since: 2018-12-2
	alter: 2019-9-23
]]--

local _CONFIG = require("config")
local _MAP = require("map.init")
local _WORLD = require("actor.world")
local _FACTORY = require("actor.factory")

local _Tweener = require("util.gear.tweener")
local _Curtain = require("graphics.curtain")
local UI = require("UI.UI")

local _DIRECTOR = { rate = 1 } ---@class DIRECTOR
---@type Graphics.Curtain
local _curtain = nil
local _speedTweener = _Tweener.New(_DIRECTOR, { rate = 1 })

function _DIRECTOR.Init()
    ---@type Graphics.Curtain
    _curtain = _Curtain.New()

    _WORLD.Init()
    _MAP.Init(_WORLD.Draw)

    _DIRECTOR.StartGame()

    -- ui
    UI.Init()
end

function _DIRECTOR.Update(dt)
    _MAP.LoadTick()
    
    _speedTweener:Update(dt)

    _curtain:Update(dt)

    dt = dt * _DIRECTOR.rate
    _WORLD.Update(dt, _DIRECTOR.rate)
    _MAP.Update(dt)

    -- ui
    UI.Update(dt)
end

function _DIRECTOR.firstUpdate()
    local dt = 0
    _MAP.LoadTick()
    
    _speedTweener:Update(dt)

    _curtain:Update(dt)

    dt = dt * _DIRECTOR.rate
    _WORLD.Update(dt, _DIRECTOR.rate)
    _MAP.Update(dt)
end

function _DIRECTOR.Draw()
    _MAP.Draw()

    -- ui
    UI.Draw()

    -- 幕布
    _curtain:Draw()
end

function _DIRECTOR.Curtain(...)
    _curtain:Enter(...)
end

---@return boolean
function _DIRECTOR.InCurtain()
    return _curtain.isRunning
end

---@param rate number
---@param time milli
---@param easing string
function _DIRECTOR.SetRate(rate, time, easing)
    _speedTweener:GetTarget().rate = rate
    _speedTweener:Enter(time, _, easing)
end

---@return boolean
function _DIRECTOR.IsTweening()
    return _speedTweener.isRunning
end

function _DIRECTOR.StartGame()
    local player = _FACTORY.New("duelist/swordman", {
        x = 700,
        y = 500,
        direction = 1,
        camp = 1
    })

    _CONFIG.user:SetPlayer(player)

    -- 创建伙伴
    local partner = _FACTORY.New("duelist/atswordman", {
        x = 400,
        y = 400,
        direction = 1,
        camp = 1,
        dulist = {
            isEnemy = false
        }
    })
    _CONFIG.user:AddPartner(partner)

    _DIRECTOR.firstUpdate() -- Flush player.

    -- 刷新距离boss的房间数
    _MAP.RefreshRoomCountNeedToPassToGetToBossRoom()
    -- 加载地图
    _MAP.Load(_MAP.Make("whitenight")) -- lorien, whitenight
    -- 刷新boss房间方向
    _MAP.RefreshBossRoomDirection()
end

---@param w number
---@param h number
function _DIRECTOR.OnWindowResize(w, h)
    UI.OnWindowResize(w, h)
end

return _DIRECTOR
