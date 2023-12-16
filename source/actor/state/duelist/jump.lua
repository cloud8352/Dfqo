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
local _Attack = require("actor.gear.attack")
local _Base = require("actor.state.base")

---@class Actor.State.Duelist.Swordman.HopSmash:Actor.State
---@field protected _skill Actor.Skill
---@field protected _effect Actor.Entity
local _Jump = require("core.class")(_Base)

local AddJumpPowerTimeS = 0.3

function _Jump:Ctor(data, ...)
    _Base.Ctor(self, data, ...)

    self._easemoveParam = data.easemove
    self._jumpParam = data.jump

    self.autoPlayStateToEnd = false
    self.startTime = 0
    self.isOnGround = false
    self.jumpStatus = GearJump.ProcessEnum.Ground
    self.isJumpAttack = false
end

function _Jump:Init(entity, ...)
    _Base.Init(self, entity, ...)

    self._xEasemove = _Easemove.New(self._entity.transform, self._entity.aspect)
    self._yEasemove = _Easemove.New(self._entity.transform, self._entity.aspect)

    self.jumpAttack = _Attack.New(self._entity)

    -- 跳跃动作
    self._jump = GearJump.New(self._entity.transform, self._entity.aspect, function (caller, param)
        -- print("_Jump state jump action func excuted! param: "..param)
        self.jumpStatus = param

        if GearJump.ProcessEnum.Ground == self.jumpStatus then
            _ASPECT.Play(self._entity.aspect, self._frameaniDataSets[4])
            _SOUND.Play(self._soundDataSet.swing)
            self.autoPlayStateToEnd = true
            self.isOnGround = true
            self.isJumpAttack = false
            self._xEasemove:Exit()
            self._yEasemove:Exit()
        end

        if self.isJumpAttack then
            return
        end

        self:updateSkyAspectFrameAni()
    end)
end

function _Jump:NormalUpdate(dt, rate)
    local currentFrameAni = _ASPECT.GetPart(self._entity.aspect) ---@type Graphics.Drawable.Frameani

    self._xEasemove:Update(rate)
    self._yEasemove:Update(rate)
    self._jump:Update(rate)

    self.jumpAttack:Update(dt)

    -- 判断是否常按了跳跃键
    if self.startTime + AddJumpPowerTimeS > _TIME.GetTime() and
        _INPUT.IsHold(self._entity.input, "jump")
        then
        local jumpParam = self._jumpParam
        self._jump:Enter(jumpParam.power, jumpParam.speed, 0.5)
    end
    -- 判断是否常按了方向键
    if not self.isOnGround then
        local needEaseMoveX = false
        local easemoveParam = self._easemoveParam
        if _INPUT.IsHold(self._entity.input, "left")
            then
            self._entity.transform.direction = -1
            self._entity.transform.scaleTick = 1
            needEaseMoveX = true
        elseif _INPUT.IsHold(self._entity.input, "right")
            then
            self._entity.transform.direction = 1
            self._entity.transform.scaleTick = 1
            needEaseMoveX = true
        end
        if needEaseMoveX then
            self._xEasemove:Enter("x", easemoveParam.power, easemoveParam.speed, self._entity.transform.direction)
        end

        local needEaseMoveY = false
        local yPowerDir = -1
        if _INPUT.IsHold(self._entity.input, "up") then
            needEaseMoveY = true
            yPowerDir = -1
        elseif _INPUT.IsHold(self._entity.input, "down") then
            needEaseMoveY = true
            yPowerDir = 1
        end
        if needEaseMoveY then
            yPowerDir = yPowerDir * self._entity.transform.direction
            self._yEasemove:Enter("y", easemoveParam.power * yPowerDir * 0.3,
             easemoveParam.speed * 0.3, self._entity.transform.direction)
        end
    end

    self:UpdateJumpAttackLogic(currentFrameAni)

    if self.isJumpAttack then
        if currentFrameAni:TickEnd() then
            self.isJumpAttack = false
            self:updateSkyAspectFrameAni()
        end
    end

    if self.autoPlayStateToEnd then
        _STATE.AutoPlayEnd(self._entity.states, self._entity.aspect, self._nextState)
    end
end

function _Jump:Enter(laterState, skill)
    _Base.Enter(self)

    self.autoPlayStateToEnd = false
    self.startTime = _TIME.GetTime()
    self.isOnGround = false
    self.jumpStatus = GearJump.ProcessEnum.Ground
    self.isJumpAttack = false

    self._skill = skill
    self._xEasemove:Exit()
    self._yEasemove:Exit()
    self._jump:Exit()
    self.jumpAttack:Exit()

    _SOUND.Play(self._soundDataSet.voice[1])
end

---@param nextState Actor.State
function _Jump:Exit(nextState)
    if (nextState == self) then
        return
    end
    
    _Base.Exit(self, nextState)

    self._xEasemove:Exit()
    self._yEasemove:Exit()
    self._jump:Exit()
    self.jumpAttack:Exit()
end

function _Jump:updateSkyAspectFrameAni()
    local jumpStatus = self.jumpStatus
    if GearJump.ProcessEnum.Up1 == jumpStatus then
        _ASPECT.Play(self._entity.aspect, self._frameaniDataSets[1])
    elseif GearJump.ProcessEnum.Up2 == jumpStatus then
        _ASPECT.Play(self._entity.aspect, self._frameaniDataSets[2])
    elseif GearJump.ProcessEnum.Down1 == jumpStatus then
        _ASPECT.Play(self._entity.aspect, self._frameaniDataSets[2])
    elseif GearJump.ProcessEnum.Down2 == jumpStatus then
        _ASPECT.Play(self._entity.aspect, self._frameaniDataSets[3])
    end
end

---@param currentFrameAni Graphics.Drawable.Frameani
function _Jump:UpdateJumpAttackLogic(currentFrameAni)    -- jump attack
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

return _Jump