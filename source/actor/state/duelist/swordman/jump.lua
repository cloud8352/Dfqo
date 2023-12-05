--[[
	desc: Jump, a state of Swordman.
	author: keke
]]--

local _SOUND = require("lib.sound")
local _ASPECT = require("actor.service.aspect")
local _STATE = require("actor.service.state")
local _INPUT = require("actor.service.input")
local _TIME = require("lib.time")

local _Easemove = require("actor.gear.easemove")
local GearJump = require("actor.gear.jump")
local JumpBase = require("actor.state.duelist.jump")

---@class Actor.State.Duelist.Swordman.HopSmash:Actor.State
---@field protected _skill Actor.Skill
---@field protected _effect Actor.Entity
local SwordmanJump = require("core.class")(JumpBase)

function SwordmanJump:NormalUpdate(dt, rate)
    JumpBase.NormalUpdate(self, dt, rate)

    -- 空中技能逻辑
    if _INPUT.IsPressed(self._entity.input, "counterAttack") then
        print("SwordmanJump:NormalUpdate(): jump -> ashenFork")
        _STATE.Play(self._entity.states, "ashenFork")
    end
end

return SwordmanJump