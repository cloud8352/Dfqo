--[[
	desc: StandardItem class. 用于存储表格或列表的单元数据
	author: keke <243768648@qq.com>
]] --

local _Graphics = require("lib.graphics")
local Sprite = require("graphics.drawable.sprite")

local Widget = require("UI.Widget")

---@class StandardItem
local StandardItem = require("core.class")(Widget)

---@enum StandardItem.DisplayState
StandardItem.DisplayState = {
    Unknown = 0,
    Normal = 1,
    Hovering = 2,
    Selected = 3,
    Disable = 4,
}

---@param parentWindow Window
function StandardItem:Ctor(parentWindow)
    Widget.Ctor(self, parentWindow)

    self.displayState = StandardItem.DisplayState.Normal
    self.text = ""

    self.normalImgCanvas = nil
    self.hoveringImgCanvas = nil
    self.selectedImgCanvas = nil
    self.disableImgCanvas = nil
    self.currentImgCanvas = nil

    self.needUpdateAllStateCanvas = true
    self.needUpdateSpriteImg = false

    self.index = 1 -- 显示项检索值

    self.sortingStr = ""
    self.sortingNum = 0

    ---@type table<string, obj>
    self.mapOfKeyToValue = {}
end

function StandardItem:Update(dt)
    if false == self:IsVisible() then
        return
    end
    if self.needUpdateAllStateCanvas then
        self.needUpdateAllStateCanvas = false
        self:updateAllStateCanvas()

        self.needUpdateSpriteImg = true
    end

    if self.needUpdateSpriteImg then
        self.needUpdateSpriteImg = false
        -- 根据状态设置按钮图片
        if StandardItem.DisplayState.Normal == self.displayState then
            self.currentImgCanvas = self.normalImgCanvas
        elseif StandardItem.DisplayState.Hovering == self.displayState then
            self.currentImgCanvas = self.hoveringImgCanvas
        elseif StandardItem.DisplayState.Selected == self.displayState then
            self.currentImgCanvas = self.selectedImgCanvas
        elseif StandardItem.DisplayState.Disable == self.displayState then
            self.currentImgCanvas = self.disableImgCanvas
        end

        local sprite = Sprite.New()
        sprite:SetImage(self.currentImgCanvas)
        -- 设置图片后调整精灵维度
        sprite:AdjustDimensions()
        self:SetBgSprite(sprite)

        self:Signal_ItemDisplayChanged()
    end

    Widget.Update(self, dt)
end

function StandardItem:Draw()
    if false == self.isVisible then
        return
    end
    Widget.Draw(self)
end

--- 连接信号
---@param signal function
---@param obj Object
function StandardItem:MocConnectSignal(signal, receiver)
    Widget.MocConnectSignal(self, signal, receiver)
end

---@param signal function
function StandardItem:GetReceiverListOfSignal(signal)
    return Widget.GetReceiverListOfSignal(self, signal)
end

---@param name string
function StandardItem:SetObjectName(name)
    Widget.SetObjectName(self, name)
end

function StandardItem:GetObjectName()
    return Widget.GetObjectName(self)
end

function StandardItem:SetPosition(x, y)
    Widget.SetPosition(self, x, y)
end

function StandardItem:GetPosition()
    return Widget.GetPosition(self)
end

function StandardItem:SetSize(width, height)
    Widget.SetSize(self, width, height)

    self.needUpdateAllStateCanvas = true
end

function StandardItem:GetSize()
    return Widget.GetSize(self)
end

function StandardItem:SetEnable(enable)
    Widget.SetEnable(self, enable)
end

---@param isVisible bool
function StandardItem:SetVisible(isVisible)
    Widget.SetVisible(self, isVisible)
end

function StandardItem:IsVisible()
    return Widget.IsVisible(self)
end

---@return changed boolean
function StandardItem:IsSizeChanged()
    return Widget.IsSizeChanged(self)
end

---@param sprite Graphics.Drawable.Sprite
function StandardItem:SetBgSprite(sprite)
    Widget.SetBgSprite(self, sprite)
end

function StandardItem:GetBgSprite()
    return Widget.GetBgSprite(self)
end

---@param x int
---@param y int
function StandardItem:CheckPoint(x, y)
    return Widget.CheckPoint(self, x, y)
end

---@param text string
function StandardItem:SetText(text)
    if self.text == text then
        return
    end

    self.text = text

    self.needUpdateAllStateCanvas = false
end

function StandardItem:GetText()
    return self.text
end

---@return canvas
function StandardItem:GetCurrentImgCanvas()
    return self.currentImgCanvas
end

---@return state StandardItem.DisplayState
function StandardItem:GetCurrentDisplayState()
    return self.displayState
end

---@param state StandardItem.DisplayState
function StandardItem:SetDisplayState(state)
    if self.displayState == state then
        return
    end
    self.displayState = state

    self.needUpdateSpriteImg = true
end

---@return index int
function StandardItem:GetIndex()
    return self.index
end

---@param index int
function StandardItem:SetIndex(index)
    self.index = index
end

---@param key string
---@param value obj
function StandardItem:SetValue(key, value)
    self.mapOfKeyToValue[key] = value
end

---@param key string
---@return obj
function StandardItem:GetValue(key)
    return self.mapOfKeyToValue[key]
end

---@param str string
function StandardItem:SetSortingStr(str)
    self.sortingStr = str
end

function StandardItem:GetSortingStr()
    return self.sortingStr
end

---@param num number
function StandardItem:SetSortingNum(num)
    self.sortingNum = num
end

function StandardItem:GetSortingNum()
    return self.sortingNum
end

---@param need boolean
function StandardItem:SetNeedUpdateAllStateCanvas(need)
    self.needUpdateAllStateCanvas = need
end

--- signals

---
function StandardItem:Signal_ItemDisplayChanged()
    print("StandardItem:Signal_ItemDisplayChanged()")
    local receiverList = self:GetReceiverListOfSignal(self.Signal_ItemDisplayChanged)
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.Slot_ItemDisplayChanged
        if func == nil then
            goto continue
        end

        func(receiver, self)

        ::continue::
    end
end

--- slot


--- private function

---@param state StandardItem.DisplayState
function StandardItem:createDisplayStateCanvas(state)
    _Graphics.SaveCanvas()
    -- 创建背景画布
    local canvas = _Graphics.NewCanvas(self.width, self.height)
    _Graphics.SetCanvas(canvas)

    ---@type int
    local r, g, b, a
    ---@type int
    local txtR, txtG, txtB, txtA
    if StandardItem.DisplayState.Normal == state then
        r = 255; g = 255; b = 255; a = 0
        txtR = 255; txtG = 255; txtB = 255; txtA = 255
    elseif StandardItem.DisplayState.Hovering == state then
        r = 160; g = 160; b = 160; a = 180
        txtR = 255; txtG = 255; txtB = 255; txtA = 255
    elseif StandardItem.DisplayState.Selected == state then
        r = 200; g = 200; b = 200; a = 180
        txtR = 255; txtG = 255; txtB = 255; txtA = 255
    elseif StandardItem.DisplayState.Disable == state then
        r = 100; g = 100; b = 100; a = 200
        txtR = 180; txtG = 180; txtB = 180; txtA = 180
    end
    _Graphics.SetColor(r, g, b, a)
    _Graphics.DrawRect(0, 0, self.width, self.height, "fill")

    -- 计算文字垂直居中显示时所处坐标
    local textXPos = 10
    local textYPos = self.height / 2 - _Graphics.GetFontHeight() / 2
    _Graphics.SetColor(txtR, txtG, txtB, txtA)
    local textObj = _Graphics.NewNormalText(self.text)
    _Graphics.DrawObj(textObj, textXPos, textYPos, 0, 1, 1, 0, 0)

    -- 还原绘图数据
    _Graphics.RestoreCanvas()
    return canvas
end

function StandardItem:updateAllStateCanvas()
    self.normalImgCanvas = self:createDisplayStateCanvas(StandardItem.DisplayState.Normal)
    self.hoveringImgCanvas = self:createDisplayStateCanvas(StandardItem.DisplayState.Hovering)
    self.selectedImgCanvas = self:createDisplayStateCanvas(StandardItem.DisplayState.Selected)
    self.disableImgCanvas = self:createDisplayStateCanvas(StandardItem.DisplayState.Disable)
end

return StandardItem
