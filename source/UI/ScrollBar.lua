--[[
	desc: Window class.
	author: keke <243768648@qq.com>
	since: 2022-11-15
	alter: 2022-11-15
]] --

local _Sprite = require("graphics.drawable.sprite")
local _Graphics = require("lib.graphics")
local _Mouse = require("lib.mouse")

local WindowManager = require("UI.WindowManager")

local Widget = require("UI.Widget")

---@class ScrollBar
local ScrollBar = require("core.class")(Widget)

---@param parentWindow Window
function ScrollBar:Ctor(parentWindow)
    Widget.Ctor(self, parentWindow)
    
    self.isMovingSlider = false -- 是否请求移动滑动条
    self.originMouseYPosWhenReqMvSlider = 0 -- 当请求移动滑动条时原始鼠标位置，用于计算滑动条移动偏差
    self.originYPosWhenReqMvSlider = 0 -- 当请求移动滑动条时原始自身位置，用于计算滑动条移动偏差

    -- 滑道长度
    self.slideLength = 0
    -- 滑动条长度
    self.sliderLength = 20
    -- 滑动条移动的距离
    self.sliderMovedDistance = 0
    -- 被控制显示内容的长度
    self.ctrlledContentLength = 0

    -- 滑道显示精灵
    self.slideSprite = _Sprite.New()
    self.slideSprite:SwitchRect(true) -- 使用矩形

    -- 滑动条显示精灵
    self.sliderSprite = _Sprite.New()
    self.sliderSprite:SwitchRect(true) -- 使用矩形

    self.leftMargin = 0
    self.topMargin = 0
    self.rightMargin = 0
    self.bottomMargin = 0

    -- post init
    self:SetSize(18, 5)
end

function ScrollBar:Update(dt)
    if false == self.isVisible then
        return
    end

    self:MouseEvent()

    Widget.Update(self, dt)
end

function ScrollBar:Draw()
    Widget.Draw(self)

    if false == Widget.IsVisible(self) then
        return
    end
    
    self.slideSprite:Draw()
    self.sliderSprite:Draw()
end

function ScrollBar:MouseEvent()
    -- 检查是否有上层窗口遮挡
    local windowLayerIndex = self.parentWindow:GetWindowLayerIndex()
    if WindowManager.IsMouseCapturedAboveLayer(windowLayerIndex) then
        return
    end

    self:judgeAndEmitSignalOfRequestMoveContent()
end

--- 连接信号
---@param signal function
---@param obj Object
function ScrollBar:MocConnectSignal(signal, receiver)
    Widget.MocConnectSignal(self, signal, receiver)
end

---@param signal function
function ScrollBar:GetReceiverListOfSignal(signal)
    return Widget.GetReceiverListOfSignal(self, signal)
end

---@param name string
function ScrollBar:SetObjectName(name)
    Widget.SetObjectName(self, name)
end

function ScrollBar:GetObjectName()
    return Widget.GetObjectName(self)
end

function ScrollBar:SetPosition(x, y)
    Widget.SetPosition(self, x, y)

    self.slideSprite:SetAttri("position", x, y)
    self.sliderSprite:SetAttri("position", x, y + self.sliderMovedDistance)
end

function ScrollBar:GetPosition()
    return Widget.GetPosition(self)
end

---@param w int
---@param h int
function ScrollBar:SetSize(w, h)
    Widget.SetSize(self, w, h)
end

function ScrollBar:GetSize()
    return Widget.GetSize(self)
end

function ScrollBar:IsSizeChanged()
    return Widget.IsSizeChanged(self)
end

---@return int
function ScrollBar:GetWidth()
    local w, _ = self:GetSize()
    return w
end

---@param length int
function ScrollBar:SetSlideLength(length)
    self.slideLength = length
    if (self.slideLength == 0) then
        return
    end

    _Graphics.SaveCanvas()
    -- 创建背景画布
    local canvas = _Graphics.NewCanvas(self.width, self.slideLength)
    _Graphics.SetCanvas(canvas)

    -- 还原绘图数据
    _Graphics.RestoreCanvas()
    self.slideSprite:SetImage(canvas)
    self.slideSprite:AdjustDimensions() -- 设置图片后调整精灵维度

    local sliderCanvas = self:createSliderCanvasBySize(self.width, self.sliderLength)
    self.sliderSprite:SetImage(sliderCanvas)
    self.sliderSprite:AdjustDimensions() -- 设置图片后调整精灵维度
end

-- 设置被控制显示内容的长度
---@param length int
function ScrollBar:SetCtrlledContentLength(length)
    self.ctrlledContentLength = length
    -- 当被控制类内容长度小于滑道长度
    if self.ctrlledContentLength <= self.slideLength then
        self.sliderLength = self.slideLength
        self:SetSlideLength(self.slideLength)
        return
    end

    self.sliderLength = self.slideLength * (self.slideLength / self.ctrlledContentLength)
    if 10 > self.sliderLength then
        self.sliderLength = 10
    end

    self:SetSlideLength(self.slideLength)
end

function ScrollBar:GetCtrlledContentLength()
    return self.ctrlledContentLength
end

function ScrollBar:SetEnable(enable)
    Widget.SetEnable(self, enable)
end

--- 设置是否可见
---@param visible boolean
function ScrollBar:SetVisible(visible)
    Widget.SetVisible(self, visible)
end

---===================
--- signals
---===================

--- 信号 - 请求移动滑动区域内容
function ScrollBar:Signal_RequestMoveContent(xOffset, yOffset)
    print("ScrollBar:Signal_RequestMoveContent(xOffset, yOffset)")
    local receiverList = self:GetReceiverListOfSignal(self.Signal_RequestMoveContent)
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.Slot_RequestMoveContent
        if func == nil then
            goto continue
        end

        func(receiver, self, xOffset, yOffset)

        ::continue::
    end
end

---===================
--- private function
---===================

function ScrollBar:createSliderCanvasBySize(width, height)
    _Graphics.SaveCanvas()
    -- 创建背景画布
    local canvas = _Graphics.NewCanvas(width, height)
    _Graphics.SetCanvas(canvas)

    _Graphics.SetColor(150, 150, 150, 180)
    _Graphics.DrawRect(0, 0, width, height, "fill")

    -- 还原绘图数据
    _Graphics.RestoreCanvas()
    return canvas
end

function ScrollBar:judgeAndEmitSignalOfRequestMoveContent()
    if nil == self:GetReceiverListOfSignal(self.Signal_RequestMoveContent) then
        return
    end

    local xPos, yPos = self:GetPosition()
    local currentMouseXPos = 0
    local currentMouseYPos = 0
    -- 判断鼠标
    while true do
        -- 是否处于按压中
        if false == _Mouse.IsHold(1) then -- 1 is the primary mouse button, 2 is the secondary mouse button and 3 is the middle button
            self.isMovingSlider = false
            break
        end

        -- 获取当前鼠标位置
        currentMouseXPos, currentMouseYPos = _Mouse.GetPosition(1, 1)
        -- 如果正处于请求移动窗口中，则直接退出循环执行移动窗口逻辑
        if self.isMovingSlider then
            break
        end

        -- 确保鼠标在按钮上
        if false == self.sliderSprite:CheckPoint(currentMouseXPos, currentMouseYPos) then
            break
        end

        -- 请求移动窗口
        self.isMovingSlider = true
        self.originMouseYPosWhenReqMvSlider = currentMouseYPos
        self.originYPosWhenReqMvSlider = yPos + self.sliderMovedDistance
        break
    end

    if self.isMovingSlider then
        local destYPos = self.originYPosWhenReqMvSlider + currentMouseYPos - self.originMouseYPosWhenReqMvSlider
        -- 滑动条不能移出滑道
        if yPos > destYPos then
            destYPos = yPos
        end
        if (yPos + self.slideLength - self.sliderLength) < destYPos then
            destYPos = yPos + self.slideLength - self.sliderLength
        end
        self.sliderSprite:SetAttri("position", xPos, destYPos)
        self.sliderMovedDistance = destYPos - yPos

        -- 滑动条移动距离 换算成 显示内容移动距离 比率
        ---@type int
        local sliderMoveDistanceToContentMoveDistanceRate = 1
        if 0 ~= (self.slideLength - self.sliderLength) then
            sliderMoveDistanceToContentMoveDistanceRate = (self.ctrlledContentLength - self.slideLength) /
                (self.slideLength - self.sliderLength)
        end
        ---@type int
        local yDistanceContentNeedMove = -sliderMoveDistanceToContentMoveDistanceRate * self.sliderMovedDistance
        self:Signal_RequestMoveContent(0, yDistanceContentNeedMove)
    end
end

return ScrollBar
