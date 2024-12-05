--[[
	desc: Jump, a state of Swordman.
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

---@class Actor.State.Duelist.Swordman.HopSmash:Actor.State
---@field protected _skill Actor.Skill
---@field protected _effect Actor.Entity
local SwordmanJump = require("core.class")(JumpBase)

function SwordmanJump:NormalUpdate(dt, rate)
    JumpBase.NormalUpdate(self, dt, rate)

    -- 空中技能逻辑
    if _INPUT.IsPressed(self._entity.input, "counterAttack") then
        local skill = SkillSrv.GetSkillWithPath(self._entity.skills, "swordman/ashen_fork")
        if skill then
            if skill:CanUse() then
                print("SwordmanJump:NormalUpdate(): jump -> ashenFork")
                skill:Use()
            end
        end
    end
end

---@param currentFrameAni Graphics.Drawable.Frameani
function SwordmanJump:UpdateJumpAttackLogic(currentFrameAni)    -- jump attack
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
            Util.PlaySoundByGender(self._soundDataSet, 2, self._entity.identity.gender)

            local skillAttackValues = {
                {
                    damageRate = 0.5,
                    isPhysical = true
                }
            }
            self.jumpAttack:Enter(self._attackDataSet[1], skillAttackValues[1], _)

            -- effect
            local effectParam = {
                x = self._entity.transform.position.x,
                y = self._entity.transform.position.y,
                z = self._entity.transform.position.z,
                direction = self._entity.transform.direction,
                entity = self._entity
            }
            self.jumpAttackEffectEntity = _FACTORY.New(self._actorDataSet[1], effectParam)

            -- SwordWind
            effectParam.z = 0
            _FACTORY.New("bullet/SwordWind", effectParam)
        end
    end
end

function SwordmanJump:Enter(lastState, skill)
    JumpBase.Enter(self, lastState, skill)

    
    if self.jumpAttackEffectEntity then
        self.jumpAttackEffectEntity.identity.destroyProcess = 1
        ---@type Actor.Entity
        self.jumpAttackEffectEntity = nil
    end
end

---@param nextState Actor.State
function SwordmanJump:Exit(nextState)
    JumpBase.Exit(self, nextState)

    if self.jumpAttackEffectEntity then
        self.jumpAttackEffectEntity.identity.destroyProcess = 1
        ---@type Actor.Entity
        self.jumpAttackEffectEntity = nil
    end
end

return SwordmanJump
