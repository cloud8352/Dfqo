--[[
	desc: Jump, a state of Tsunade.
	author: keke
]]--

local _SOUND = require("lib.sound")
local Util = require("util.Util")

local _ASPECT = require("actor.service.aspect")
local _STATE = require("actor.service.state")
local _INPUT = require("actor.service.input")
local _FACTORY = require("actor.factory")
local SkillSrv = require("actor.service.skill")

local _Easemove = require("actor.gear.easemove")
local GearJump = require("actor.gear.jump")
local JumpBase = require("actor.state.duelist.jump")

---@class Actor.State.Duelist.Tsunade.Jump : Actor.State
---@field protected _skill Actor.Skill
---@field protected _effect Actor.Entity
local TsunadeJump = require("core.class")(JumpBase)

function TsunadeJump:NormalUpdate(dt, rate)
    JumpBase.NormalUpdate(self, dt, rate)
end

---@param currentFrameAni Graphics.Drawable.Frameani
function TsunadeJump:UpdateJumpAttackLogic(currentFrameAni)    -- jump attack
    local canJumpAttack = false
    if self.isOnGround == false and self.isJumpAttack == false then
        canJumpAttack = true
    elseif self.isJumpAttack and currentFrameAni:GetTick() > 3 then
        canJumpAttack = true
    end
    if canJumpAttack then
        if _INPUT.IsPressed(self._entity.input, "normalAttack") then
            self.isJumpAttack = true
            -- print("JumpAttack")
            _ASPECT.Play(self._entity.aspect, self._frameaniDataSets[5])

            if self._entity.identity.gender == 1 then
                _SOUND.Play(self._soundDataSet.voice[2])
            end
            _SOUND.Play(self._soundDataSet.voice[2])

            local skillAttackValues = {
                {
                    damageRate = 0.5,
                    isPhysical = true
                }
            }
            self.jumpAttack:Enter(self._attackDataSet[1], skillAttackValues[1], _)
        end
    end
end

function TsunadeJump:Enter(lastState, skill)
    JumpBase.Enter(self, lastState, skill)

    
    if self.jumpAttackEffectEntity then
        self.jumpAttackEffectEntity.identity.destroyProcess = 1
        ---@type Actor.Entity
        self.jumpAttackEffectEntity = nil
    end
end

---@param nextState Actor.State
function TsunadeJump:Exit(nextState)
    JumpBase.Exit(self, nextState)

    if self.jumpAttackEffectEntity then
        self.jumpAttackEffectEntity.identity.destroyProcess = 1
        ---@type Actor.Entity
        self.jumpAttackEffectEntity = nil
    end
end

return TsunadeJump
