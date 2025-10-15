--[[
	desc: MultiStepMove, a Ai of move which have multi step.
	author: keke
]]--

local _ECSMGR = require("actor.ecsmgr")
local _BATTLE = require("actor.service.battle")
local _INPUT = require("actor.service.input")
local _STATE = require("actor.service.state")
local Map = require("map.init")

local _Timer = require("util.gear.timer")
local _Point = require("graphics.drawunit.point")
local _Range = require("graphics.drawunit.range")
local _Move = require("actor.ai.move")
local _Base = require("actor.ai.base")

local _list = _ECSMGR.NewComboList({
    battle = true,
    transform = true
})

---@class Actor.Ai.MultiStepMove : Actor.Ai
---@field public searchRange Graphics.Drawunit.Range
---@field public moveRange Graphics.Drawunit.Range
---@field public intervalSection Graphics.Drawunit.Point
---@field public lockOn boolean
---@field public campType string
---@field public navigating boolean
---@field public camp int
---@field protected _target Graphics.Drawunit.Point
---@field protected _timer Util.Gear.Timer
---@field protected _moveAi Actor.Ai.Move
---@field protected _hasTarget boolean
local MultiStepMove = require("core.class")(_Base)

---@param entity Actor.Entity
---@param data table
function MultiStepMove.NewWithConfig(entity, data)
    return MultiStepMove.New(entity, data)
end

---@param entity Actor.Entity
---@param data table
---@param searchRange Graphics.Drawunit.Range
---@param moveRange Graphics.Drawunit.Range
---@param lockOn boolean
---@param intervalSection Graphics.Drawunit.Point
---@param campType string @all, same, enemy, else. default=enemy
function MultiStepMove:Ctor(entity, data)
    _Base.Ctor(self, entity)

    local searchRange = data.searchRange
    self.searchRange = _Range.New(searchRange.xa, searchRange.xb, searchRange.ya, searchRange.yb)
    local moveRange = data.moveRange
    self.moveRange = _Range.New(moveRange.xa, moveRange.xb, moveRange.ya, moveRange.yb)
    local intervalSection = data.interval
    self.intervalSection = _Point.New(true, intervalSection.x, intervalSection.y)
    self._timer = _Timer.New()
    self._target = _Point.New(true)
    self._moveAi = _Move.New(entity)
    self.lockOn = data.lockOn or false
    self.campType = data.campType or "enemy"
    self.camp = data.camp
    self._hasTarget = false
    self.navigating = false

    ---@type table<int, Graphics.Drawunit.Point>
    self.Steps = {
    }
    if data.Steps then
        for _, v in pairs(data.Steps) do
            local point = _Point.New(true, v[1], v[2])
            table.insert(self.Steps, point)
        end
    end 
    self.goingToNextStep = false
    self.nextStepIndex = 1
end

function MultiStepMove:Update(dt)
    if (not self:CanRun()) then
        return
    end

    self._timer:Update(dt)

    if (not self.navigating and not self._timer.isRunning) then
        self._timer:Enter(math.random(self.intervalSection.x, self.intervalSection.y))

        local hasTarget, x, y = self:Select()
        if hasTarget then
            local entityXPos, entityYPos = self._entity.transform.position:Get()
            if math.abs(entityXPos - x) > 50 or math.abs(entityYPos - y) > 20 then
                self.goingToNextStep = false
                self._hasTarget = hasTarget
                self._target:Set(x, y)
                self._moveAi:Tick(x, y)
            end
        else
            if self.nextStepIndex <= #self.Steps then
                self.goingToNextStep = true
                local point = self.Steps[self.nextStepIndex]

                y = point.y + math.random(self.moveRange.ya, self.moveRange.yb) - (self.moveRange.ya + self.moveRange.yb) / 2
                self:MoveTo(point.x, y)
            end
        end
    end

    self:LockOn()
    self._moveAi:Update(dt)

    if (self.navigating and not self._moveAi:IsRunning()) then
        self.navigating = false
    end

    if self.goingToNextStep and not self._moveAi:IsRunning() then
        self.nextStepIndex = self.nextStepIndex + 1
        self.goingToNextStep = false
    end
end

function MultiStepMove:LockOn()
    if (not self:CanRun() or not self._hasTarget or not self.lockOn) then
        return
    end

    local transform = self._entity.transform
    local direction = transform.position.x < self._target.x and 1 or -1

    if (direction == transform.direction) then
        _INPUT.Press(self._entity.input, "lockOn") -- Press the key to lock direction, see also: actor/controlMove.lua
    end
end

function MultiStepMove:Select()
    local camp = self.camp or self._entity.battle.camp
    local x, y = self._entity.transform.position:Get()

    ---@type Graphics.Drawunit.Point
    local enemyPos = nil
    if (self.campType ~= "") then
        for n = _list:GetLength(), 1, -1 do
            local e = _list:Get(n) ---@type Actor.Entity

            if (e.battle and self._entity ~= e and e.battle.banCountMap.hide == 0 and _BATTLE.CondCamp(camp, e.battle.camp, self.campType)) then
                local pos = e.transform.position

                if (self.searchRange:Collide(x, y, pos.x, pos.y)) then
                    enemyPos = pos
                    break
                end
            end
        end
    end
    if enemyPos == nil then
        return false, x, y
    end

    local targetX = -1
    local targetY = enemyPos.y + math.random(self.moveRange.ya, self.moveRange.yb) - (self.moveRange.ya + self.moveRange.yb) / 2
    local dir = 1
    if enemyPos.x < x then
        dir = -1
    end
    local matrix = Map.GetMatrix()
    if matrix:GetNode(enemyPos.x, enemyPos.y, false) then
        local xTmp = enemyPos.x
        while (1) do
            xTmp = xTmp - 40 * dir
            -- 超出搜索范围，则获取目标点失败
            if false == self.searchRange:Collide(x, y, xTmp, enemyPos.y) then
                break
            end

            if false == matrix:GetNode(xTmp, enemyPos.y) then
                targetX = xTmp
                break
            end
        end
    else
        targetX = enemyPos.x - 40 * dir
    end
    if targetX < 0 or targetY < 0 then
        return false, x, y
    end
    if matrix:GetNode(targetX, targetY) then
        return false, x, y
    end

    return true, targetX, targetY
end

---@param x int
---@param y int
---@param isOnly boolean
---@param lockOn boolean
function MultiStepMove:MoveTo(x, y, isOnly, lockOn)
    self._target:Set(x, y)
    self._moveAi:Tick(x, y)

    if (isOnly) then
        self._timer:Exit()
        self.navigating = true
    end

    self._hasTarget = lockOn or false
end

---@return boolean
function MultiStepMove:IsMoving()
    return self._moveAi:IsRunning()
end

---@param isReal boolean @moveAi's target
---@return int, int
function MultiStepMove:GetTarget(isReal)
    if (isReal) then
        return self._moveAi:GetTarget()
    end

    return self._target:Get()
end

---@return boolean
function MultiStepMove:CanRun()
    local free = (self._entity.states and _STATE.HasTag(self._entity.states, "moveable")) or not self._entity.states
    return _Base.CanRun(self) and free
end

function MultiStepMove:Reset()
    self.navigating = false
    self._timer:Exit()
end

return MultiStepMove
