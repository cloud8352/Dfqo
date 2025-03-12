--[[
	desc: ProgressBar class.
	author: keke <243768648@qq.com>
]]
--

local Util = require("util.Util")
local Widget = require("UI.Widget")
local Label = require("UI.Label")
local WindowManager = require("UI.WindowManager")

local _Sprite = require("graphics.drawable.sprite")
local _Graphics = require("lib.graphics")
local MouseLib = require("lib.mouse")
local SysLib = require("lib.system")
local TouchLib = require("lib.touch")

---@class ProgressBar : Widget
local ProgressBar = require("core.class")(Widget)

---@param parentWindow Window
function ProgressBar.Create(parentWindow)
    -- 用于定义构造函数，解释使用，不做实际用途
    -- 使用class模块后，实际会调用Ctor函数
    return ProgressBar.New(parentWindow)
end

---@param parentWindow Window
function ProgressBar:Ctor(parentWindow)
    -- 父类构造函数
    Widget.Ctor(self, parentWindow)

    self.lastProgress = 0.0
    --- 1.0% - 100.0%
    ---@type number
    self.currentProgress = 0.0 
    self.barColor = { r = 100, g = 40, b = 55, a = 255 }
    self.rectSprite = _Sprite.New()

    self.textLabel = Label.New(parentWindow)

    self.canChangeByMouseOrTouch = false
    self.isChangingByMouse = false
    self.pressedTouchId = ""
end

function ProgressBar:Update(dt)
    if (not Widget.IsVisible(self)) then
        return
    end

    if not SysLib.IsMobile() then
        self:MouseEvent()
    else
        self:TouchEvent()
    end

    if (Widget.IsSizeChanged(self)
            or math.abs(self.lastProgress - self.currentProgress) > 0.001
        )
    then
        self:updateSprite()

        local width, height = Widget.GetSize(self)
        self.textLabel:SetSize(width, height)
    end

    self.textLabel:Update(dt)
    Widget.Update(self, dt)
    self.lastProgress = self.currentProgress
end

function ProgressBar:Draw()
    if (not Widget.IsVisible(self)) then
        return
    end

    Widget.Draw(self)
    self.rectSprite:Draw()
    self.textLabel:Draw()
end

function ProgressBar:MouseEvent()
    -- 判断鼠标
    while true do
        if false == self.canChangeByMouseOrTouch then
            break
        end

        -- 检查是否有上层窗口遮挡
        local windowLayerIndex = self.parentWindow:GetWindowLayerIndex()
        if WindowManager.IsMouseCapturedAboveLayer(windowLayerIndex)
            or self.parentWindow:IsInMoving()
            or MouseLib.IsReleased(1)
        then
            self.isChangingByMouse = false
            break
        end

        -- 确保鼠标在按钮上
        local mousePosX, mousePosY = MouseLib.GetPosition(1, 1)
        if false == self:CheckPoint(mousePosX, mousePosY)
            and self.isChangingByMouse == false
        then
            break
        end

        if MouseLib.IsPressed(1) then
            self.isChangingByMouse = true
        end

        if false == self.isChangingByMouse then
            break
        end

        -- 是否处于按压中
        if MouseLib.IsHold(1) then -- 1 is the primary mouse button, 2 is the secondary mouse button and 3 is the middle button
            self:setProgressByX(mousePosX)
            break
        end

        break
    end
end

function ProgressBar:TouchEvent()
    -- 判断鼠标
    while true do
        if false == self.canChangeByMouseOrTouch then
            break
        end

        -- 检查是否有上层窗口遮挡
        local capturedTouchIdList = WindowManager.GetWindowCapturedTouchIdList(self.parentWindow)
        if #capturedTouchIdList == 0
            or self.parentWindow:IsInMoving()
        then
            self.pressedTouchId = ""
            break
        end

        if self.pressedTouchId ~= "" then
            local point = TouchLib.GetPoint(self.pressedTouchId)
            if TouchLib.WhetherPointIsReleased(point) then
                self.pressedTouchId = ""
                break
            end
        end

        local id = self:getPressedTouchId(capturedTouchIdList)
        if id ~= "" then
            self.pressedTouchId = id
        end

        if self.pressedTouchId == "" then
            break
        end

        -- 是否处于按压中
        local point = TouchLib.GetPoint(self.pressedTouchId)
        if TouchLib.WhetherPointIsHold(point) then
            self:setProgressByX(point.x)
            break
        end

        break
    end
end

---@param x int
---@param y int
function ProgressBar:SetPosition(x, y)
    Widget.SetPosition(self, x, y)

    local xPos, yPos = Widget.GetPosition(self)
    self.rectSprite:SetAttri("position", xPos, yPos)
    self.textLabel:SetPosition(x, y)
end

function ProgressBar:GetPosition()
    return Widget.GetPosition(self)
end

function ProgressBar:SetSize(width, height)
    Widget.SetSize(self, width, height)

    self.textLabel:SetSize(width, height)
end

function ProgressBar:SetEnable(enable)
    Widget.SetEnable(self, enable)

    self.textLabel:SetEnable(enable)
end

---@param isVisible boolean
function ProgressBar:SetVisible(isVisible)
    Widget.SetVisible(self, isVisible)

    self.textLabel:SetVisible(isVisible)
end

---@param red integer
---@param green integer
---@param blue integer
---@param alpha integer
function ProgressBar:SetBarColor(red, green, blue, alpha)
    self.barColor.r = red
    self.barColor.g = green
    self.barColor.b = blue
    self.barColor.a = alpha

    self:updateSprite()
end

---@param progress number @0.0 - 1.0
function ProgressBar:SetProgress(progress)
    if (math.abs(self.currentProgress - progress) < 0.001) then
        return
    end
    self.currentProgress = progress

    self:Signal_ProgressChanged(progress)
end

---@param text string
function ProgressBar:SetText(text)
    self.textLabel:SetText(text)
end

---@param enable boolean
function ProgressBar:EnableChangeByMouseOrTouch(enable)
    self.canChangeByMouseOrTouch = enable

    if enable == false then
        self.isChangingByMouse = false
        self.pressedTouchId = ""
    end
end

--- signals

---@param value number @0.0 - 1.0
function ProgressBar:Signal_ProgressChanged(value)
    local receiverList = self.mapOfSignalToReceiverList[self.Signal_ProgressChanged]
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.Slot_ProgressChanged
        if func == nil then
            goto continue
        end

        func(receiver, self, value)

        ::continue::
    end
end

--- private function

function ProgressBar:updateSprite()
    _Graphics.SaveCanvas()
    -- 创建背景画布
    local width, height = Widget.GetSize(self)
    local canvas = _Graphics.NewCanvas(width, height)
    _Graphics.SetCanvas(canvas)

    -- 先画背景
    _Graphics.SetColor(10, 10, 10, 150)
    _Graphics.DrawRect(0, 0, width, height, "fill")

    -- 再画进度条
    _Graphics.SetColor(self.barColor.r, self.barColor.g, self.barColor.b, self.barColor.a)
    local rectWidth = 0
    rectWidth = width * self.currentProgress
    _Graphics.DrawRect(0, 0, rectWidth, height, "fill")

    -- 还原绘图数据
    _Graphics.RestoreCanvas()

    self.rectSprite:SetImage(canvas)
    self.rectSprite:AdjustDimensions()
end

---@param idList table<number, string>
function ProgressBar:getPressedTouchId(idList)
    for _, id in pairs(idList) do
        local point = TouchLib.GetPoint(id)
        if self:CheckPoint(point.x, point.y)
            and TouchLib.WhetherPointIsPressed(point)
        then
            return id
        end
    end

    return ""
end

---@param xPos int
function ProgressBar:setProgressByX(xPos)
    local x, y = self:GetPosition()
    local w, h = self:GetSize()
    local progress = (xPos - x) / w
    if progress < 0.0 then
        progress = 0
    end
    if progress > 1.0 then
        progress = 1.0
    end
    self:SetProgress(progress)
end

return ProgressBar
