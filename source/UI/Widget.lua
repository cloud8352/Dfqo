--[[
	desc: Widget class.
	author: keke <243768648@qq.com>
	since: 2023-4-21
	alter: 2023-4-21
]] --

local Sprite = require("graphics.drawable.sprite")
local Rect = require("graphics.drawunit.rect")

---@class Widget
local Widget = require("core.class")()

---@param parentWindow Window
function Widget:Ctor(parentWindow)
    --- 信号到接收者的映射表
    ---@type table<function, table<int, Object>>
    self.mapOfSignalToReceiverList = {}

    self.objectName = ""

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

    self.bgSprite = Sprite.New()
    self.lastBgSprite = nil

    self.checkRect = Rect.New()
end

function Widget:Update(dt)
    if self:IsSizeChanged() or
        self.lastBgSprite ~= self.bgSprite
    then
        -- bg sprite
        local spriteWidth, spriteHeight = self.bgSprite:GetImageDimensions()
        if spriteWidth ~= 0 and spriteHeight ~= 0 then
            local spriteXScale = self.width / spriteWidth
            local spriteYScale = self.height / spriteHeight
            self.bgSprite:SetAttri("scale", spriteXScale, spriteYScale)
        end

        self.checkRect:Set(self.xPos, self.yPos, self.width, self.height, 0, 0, 0)
    end


    self.lastXPos = self.xPos
    self.lastYPos = self.yPos
    self.lastWidth = self.width
    self.lastHeight = self.height
    self.lastBgSprite = self.bgSprite
end

function Widget:Draw()
    self.bgSprite:Draw()
end

function Widget:PaintEvent()
end

--- 连接信号
---@param signal function
---@param obj Object
function Widget:MocConnectSignal(signal, receiver)
    local receiverList = self.mapOfSignalToReceiverList[signal]
    if receiverList == nil then
        receiverList = {}
        self.mapOfSignalToReceiverList[signal] = receiverList
    end
    table.insert(receiverList, receiver)
end

---@param signal function
function Widget:GetReceiverListOfSignal(signal)
    local receiverList = self.mapOfSignalToReceiverList[signal]
    if receiverList ~= nil and 
        #receiverList == 0
    then
        receiverList = nil
    end

    return receiverList
end

---@param name string
function Widget:SetObjectName(name)
    self.objectName = name
end

function Widget:GetObjectName()
    return self.objectName
end

---@param x int
---@param y int
function Widget:SetPosition(x, y)
    self.xPos = x
    self.yPos = y

    self.bgSprite:SetAttri("position", x, y)
    self.checkRect:Set(self.xPos, self.yPos, self.width, self.height, 0, 0, 0)
end

---@return int, int
function Widget:GetPosition()
    return self.xPos, self.yPos
end

---@param width int
---@param height int
function Widget:SetSize(width, height)
    if self.width == width and self.height == height then
        return
    end
    self.width = width
    self.height = height
end

---@return number, number w, h
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

---@return boolean isVisible
function Widget:IsVisible()
    return self.isVisible
end

---@return changed boolean
function Widget:IsSizeChanged()
    return (self.lastWidth ~= self.width
        or self.lastHeight ~= self.height)
end

---@param sprite Graphics.Drawable.Sprite
function Widget:SetBgSprite(sprite)
    self.bgSprite = sprite

    self.bgSprite:SetAttri("position", self.xPos, self.yPos)
end

---@param x int
---@param y int
function Widget:CheckPoint(x, y)
    return self.checkRect:CheckPoint(x, y)
end

return Widget
