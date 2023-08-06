--[[
	desc: Widget class.
	author: keke <243768648@qq.com>
	since: 2023-4-21
	alter: 2023-4-21
]] --

---@class Widget
local Widget = require("core.class")()

---@param parentWindow Window
function Widget:Ctor(parentWindow)
    assert(parentWindow, "must assign parent window")
    ---@type Window
    self.parentWindow = parentWindow

    self.width = 10
    self.lastWidth = 0
    self.height = 10
    self.lastHeight = 0
    self.xPos = 0
    self.lastXPos = 0
    self.yPos = 0
    self.lastYPos = 0
    self.enable = true

    self.isVisible = true
end

function Widget:Update(dt)
    self.lastXPos = self.xPos
    self.lastYPos = self.yPos
    self.lastWidth = self.width
    self.lastHeight = self.height
end

function Widget:Draw()
end

function Widget:PaintEvent()
end

function Widget:SetPosition(x, y)
    self.xPos = x
    self.yPos = y
end

---@return int, int
function Widget:GetPosition()
    return self.xPos, self.yPos
end

function Widget:SetSize(width, height)
    self.width = width
    self.height = height
end

---@return int, int
function Widget:GetSize()
    return self.width, self.height
end

function Widget:SetEnable(enable)
    self.enable = enable
end

---@param isVisible boolean
function Widget:SetVisible(isVisible)
    self.isVisible = isVisible
end

---@return isVisible boolean
function Widget:IsVisible()
    return self.isVisible
end

---@return changed boolean
function Widget:IsBaseDataChanged()
    return (self.lastXPos ~= self.xPos
            or self.lastYPos ~= self.yPos
            or self.lastWidth ~= self.width
            or self.lastHeight ~= self.height)
end

return Widget
