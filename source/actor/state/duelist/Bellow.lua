--[[
	desc: BellowState, 吼叫， a state of base attack.
	author: keke
]]--

local _Base = require("actor.state.base")

local _ASPECT = require("actor.service.aspect")
local _STATE = require("actor.service.state")
local BuffSrv = require("actor.service.buff")
local SoundLib = require("lib.sound")

---@class Actor.State.Duelist.BellowState:Actor.State
---@field protected _skill Actor.Skill
local BellowState = require("core.class")(_Base)

function BellowState:Ctor(data, ...)
    _Base.Ctor(self, data, ...)
end

function BellowState:NormalUpdate()
    local main = _ASPECT.GetPart(self._entity.aspect) ---@type Graphics.Drawable.Frameani
    local tick = main:GetTick()

    _STATE.Play(self._entity.states, self._nextState)
end

function BellowState:Enter(lastState, skill)
    if lastState ~= self then
        _Base.Enter(self)
        self._skill = skill

        local n = math.random(1, #self._soundDataSet)
        SoundLib.Play(self._soundDataSet[n])

        BuffSrv.AddBuff(self._entity, self._buffDatas)
    end
end

return BellowState
