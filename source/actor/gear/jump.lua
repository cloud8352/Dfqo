--[[
	desc: Jump, a gear for jump business.
	author: Musoucrow
	since: 2018-11-13
]]--

local _Gear = require("core.gear")
local _Easemove = require("actor.gear.easemove")

local _MATH = require("lib.math")

---@class Actor.Gear.Jump : Core.Gear
---@field protected _transform Actor.Component.Transform
---@field protected _process int
---@field protected _easemove Actor.Gear.Easemove
---@field protected _Func function
---@field protected _downSpeed number
---@field protected _originZ int
local _Jump = require("core.class")(_Gear)

local ProcessEnum = {Up1 = 1, Up2 = 2, Up3 = 3, Down1 = 4, Down2 = 5, Ground = 6}
_Jump.ProcessEnum = ProcessEnum

---@param transform Actor.Component.Transform
---@param aspect Actor.Component.Aspect
function _Jump:Ctor(transform, aspect, Func)
    _Gear.Ctor(self)

    self._transform = transform
    self._easemove = _Easemove.New(transform, aspect)
    self._Func = Func
end

function _Jump:Update(rate)
    if (not self.isRunning) then
        return
    end

    self._easemove:Update(rate)
    
    if (self._process == ProcessEnum.Up1 and self._easemove:GetPower() <= self._nextProcessUpPower) then
        self._process = ProcessEnum.Up2
        self._nextProcessUpPower = _MATH.GetFixedDecimal(self._upPower * 0.3)

        self:_Func(self._process)
    elseif (self._process == ProcessEnum.Up2 and self._easemove:GetPower() <= self._nextProcessUpPower) then
        self._process = ProcessEnum.Up3
        self:_Func(self._process)
    elseif (self._process == ProcessEnum.Up3 and not self._easemove.isRunning) then
        self._process = ProcessEnum.Down1
        self._easemove:Enter("z", 0, -self._downSpeed, 1)
        self._topZPosValue = self._transform.position.z
        self:_Func(self._process)
    elseif (self._process == ProcessEnum.Down1 and
            self._transform.position.z >= self._topZPosValue * 0.7
        ) then
        self._process = ProcessEnum.Down2
        self:_Func(self._process)
    elseif (self._process == ProcessEnum.Down2 and self._transform.position.z > 0) then
        self._process = ProcessEnum.Ground
        self._transform.position.z = 0
        self._transform.positionTick = true
        self:_Func(self._process)
        self:Exit()
    end
end

---@param upPower number
---@param upSpeed number
---@param downSpeed number
---@param Func function
function _Jump:Enter(upPower, upSpeed, downSpeed)
    _Gear.Enter(self)

    self._easemove:Enter("z", upPower, upSpeed, -1)
    self._upPower = upPower
    self._nextProcessUpPower = _MATH.GetFixedDecimal(self._upPower * 0.75)
    self._topZPosValue = 0
    self._downSpeed = downSpeed
    self._process = ProcessEnum.Up1
    self._originZ = self._transform.position.z
    self:_Func(self._process)
end

---@return int
function _Jump:GetProcess()
    return self._process
end

---@return number
function _Jump:GetPower()
    return self._easemove:GetPower()
end

---@return number
function _Jump:GetZRate()
    return self._transform.position.z / self._originZ
end

return _Jump