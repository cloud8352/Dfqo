--[[
	desc: Transport, a component for transportation of map.
	author: Musoucrow
    since: 2019-5-7
]]--

local _RESMGR = require("actor.resmgr")

local _Collider = require("actor.collider")

---@class Actor.Component.Transport
---@field public collider Actor.Collider
---@field public enable boolean
---@field public type string
---@field public direction string
---@field public map string
---@field public ToPos table
local _Transport = require("core.class")()

function _Transport.HandleData(data)
    data.collider = _RESMGR.GetColliderData(data.collider)
end

function _Transport:Ctor(data, param)
    local myParam = param.Transport
    if nil == myParam then
        myParam = {}
    end

    self.enable = true
    self.type = myParam.Type or data.type
    self.direction = data.direction
    self.map = myParam.Map or data.map
    self.collider = _Collider.New(data.collider)

    self.ToPos = myParam.ToPos or data.ToPos or { X = 0, Y = 0 }
end

return _Transport
