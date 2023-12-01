--[[
	desc: HopSmash, a state of Swordman.
	author: keke
	since: 2022-9-3
]]--

local _SOUND = require("lib.sound")
local _ASPECT = require("actor.service.aspect")
local _STATE = require("actor.service.state")
local _INPUT = require("actor.service.input")
local _TIME = require("lib.time")

local _Easemove = require("actor.gear.easemove")
local GearJump = require("actor.gear.jump")
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
end

function _Jump:Init(entity, ...)
    _Base.Init(self, entity, ...)

    self._xEasemove = _Easemove.New(self._entity.transform, self._entity.aspect)
    self._yEasemove = _Easemove.New(self._entity.transform, self._entity.aspect)

    -- 跳跃动作
    self._jump = GearJump.New(self._entity.transform, self._entity.aspect, function (caller, param)
        -- print("_Jump state jump action func excuted! param: "..param)
        if GearJump.ProcessEnum.Up1 == param then
            _ASPECT.Play(self._entity.aspect, self._frameaniDataSets[1])
        elseif GearJump.ProcessEnum.Up2 == param then
            _ASPECT.Play(self._entity.aspect, self._frameaniDataSets[2])
        elseif GearJump.ProcessEnum.Down2 == param then
            _ASPECT.Play(self._entity.aspect, self._frameaniDataSets[3])
        elseif GearJump.ProcessEnum.Ground == param then
            _ASPECT.Play(self._entity.aspect, self._frameaniDataSets[4])
            _SOUND.Play(self._soundDataSet.swing)
            self.autoPlayStateToEnd = true
            self.isOnGround = true
            self._xEasemove:Exit()
            self._yEasemove:Exit()
        end
    end)
end

function _Jump:NormalUpdate(dt, rate)
    -- 判断是否常按了跳跃键
    if self.startTime + AddJumpPowerTimeS > _TIME.GetTime() and
        _INPUT.IsHold(self._entity.input, "jump")
        then
        local jumpParam = self._jumpParam
        self._jump:Enter(jumpParam.power, jumpParam.speed, jumpParam.speed * 0.3)
    end
    -- 判断是否常按了方向键
    if not self.isOnGround then
        local needEaseMoveX = false
        local easemoveParam = self._easemoveParam
        if _INPUT.IsHold(self._entity.input, "left") and
            self._entity.transform.direction == -1
            then
            needEaseMoveX = true
        elseif _INPUT.IsHold(self._entity.input, "right") and
            self._entity.transform.direction == 1
            then
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

    self._xEasemove:Update(rate)
    self._yEasemove:Update(rate)
    self._jump:Update(rate)

    if self.autoPlayStateToEnd then
        _STATE.AutoPlayEnd(self._entity.states, self._entity.aspect, self._nextState)
    end
end

function _Jump:Enter(laterState, skill)
    _Base.Enter(self)

    self.autoPlayStateToEnd = false
    self.startTime = _TIME.GetTime()
    self.isOnGround = false

    self._skill = skill
    self._xEasemove:Exit()
    self._yEasemove:Exit()
    self._jump:Exit()

    _SOUND.Play(self._soundDataSet.voice)
end

function _Jump:Exit(nextState)
    if (nextState == self) then
        return
    end
    
    _Base.Exit(self, nextState)

    self._xEasemove:Exit()
    self._yEasemove:Exit()
end

return _Jump