--[[
	desc: KeySettingsItem class. 键位设置显示项
	author: keke <243768648@qq.com>
]] --

local _Graphics = require("lib.graphics")

local WindowManager = require("UI.WindowManager")
local Util = require("util.Util")

local StandardItem = require("UI.StandardItem")
local Label = require("UI.Label")

---@class KeySettingsItem
local KeySettingsItem = require("core.class")(StandardItem)

local keyLabelWidth = 120

---@param parentWindow Window
function KeySettingsItem:Ctor(parentWindow)
    -- 父类构造函数
    StandardItem.Ctor(self, parentWindow)

    local windowSizeScale = Util.GetWindowSizeScale()
    self.keyLabelWidth = keyLabelWidth * windowSizeScale

    self.leftMargin = 7 * windowSizeScale
    self.rightMargin = 7 * windowSizeScale

    self.leftLabel = Label.New(WindowManager.DefaultWindow)
    self.leftLabel:SetAlignments({ Label.AlignmentFlag.AlignLeft, Label.AlignmentFlag.AlignVCenter })
    self.rightLabel = Label.New(WindowManager.DefaultWindow)
end

function KeySettingsItem:Update(dt)
    if not self:IsVisible() then
        return
    end

    self.leftLabel:Update(dt)
    self.rightLabel:Update(dt)

    StandardItem.Update(self, dt)
end

function KeySettingsItem:Draw()
    if not self:IsVisible() then
        return
    end
    StandardItem.Draw(self)
end

--- 连接信号
---@param signal function
---@param obj Object
function KeySettingsItem:MocConnectSignal(signal, receiver)
    StandardItem.MocConnectSignal(self, signal, receiver)
end

---@param signal function
function KeySettingsItem:GetReceiverListOfSignal(signal)
    return StandardItem.GetReceiverListOfSignal(self, signal)
end

---@param name string
function KeySettingsItem:SetObjectName(name)
    StandardItem.SetObjectName(self, name)
end

function KeySettingsItem:GetObjectName()
    return StandardItem.GetObjectName(self)
end

function KeySettingsItem:SetPosition(x, y)
    StandardItem.SetPosition(self, x, y)
end

function KeySettingsItem:GetPosition()
    return StandardItem.GetPosition(self)
end

---@param width int
---@param height int
function KeySettingsItem:SetSize(width, height)
    if ((width <= 0) or (height <= 0)) then
        return
    end
    -- 调用父类函数，更新显示画板
    StandardItem.SetSize(self, width, height)

    self.leftLabel:SetSize(width - self.keyLabelWidth - self.leftMargin - self.rightMargin, height)
    self.rightLabel:SetSize(self.keyLabelWidth, height)
end

function KeySettingsItem:GetSize()
    return StandardItem.GetSize(self)
end

function KeySettingsItem:SetEnable(enable)
    StandardItem.SetEnable(self, enable)
end

---@param isVisible bool
function KeySettingsItem:SetVisible(isVisible)
    StandardItem.SetVisible(self, isVisible)
end

function KeySettingsItem:IsVisible()
    return StandardItem.IsVisible(self)
end

---@return changed boolean
function KeySettingsItem:IsSizeChanged()
    return StandardItem.IsSizeChanged(self)
end

---@param sprite Graphics.Drawable.Sprite
function KeySettingsItem:SetBgSprite(sprite)
    StandardItem.SetBgSprite(self, sprite)
end

function KeySettingsItem:GetBgSprite()
    return StandardItem.GetBgSprite(self)
end

---@param x int
---@param y int
function KeySettingsItem:CheckPoint(x, y)
    return StandardItem.CheckPoint(self, x, y)
end

---@return canvas
function KeySettingsItem:GetCurrentImgCanvas()
    return StandardItem.GetCurrentImgCanvas(self)
end

---@return state StandardItem.DisplayState
function KeySettingsItem:GetCurrentDisplayState()
    return StandardItem.GetCurrentDisplayState(self)
end

---@param state StandardItem.DisplayState
function KeySettingsItem:SetDisplayState(state)
    StandardItem.SetDisplayState(self, state)
end

---@return index int
function KeySettingsItem:GetIndex()
    return StandardItem.GetIndex(self)
end

---@param index int
function KeySettingsItem:SetIndex(index)
    StandardItem.SetIndex(self, index)
end

---@param key string
---@param value obj
function KeySettingsItem:SetValue(key, value)
    StandardItem.SetValue(self, key, value)
end

---@param key string
---@return obj value
function KeySettingsItem:GetValue(key)
    return StandardItem.GetValue(self, key)
end

---@param str string
function KeySettingsItem:SetSortingStr(str)
    StandardItem.SetSortingStr(self, str)
end

function KeySettingsItem:GetSortingStr()
    return StandardItem.GetSortingStr(self)
end

---@param num number
function KeySettingsItem:SetSortingNum(num)
    StandardItem.SetSortingNum(self, num)
end

function KeySettingsItem:GetSortingNum()
    return StandardItem.GetSortingNum(self)
end

---@param need boolean
function KeySettingsItem:SetNeedUpdateAllStateCanvas(need)
    StandardItem.SetNeedUpdateAllStateCanvas(self, need)
end

---@param text string
function KeySettingsItem:SetLeftLabelText(text)
    self.leftLabel:SetText(text)
    

    self:SetNeedUpdateAllStateCanvas(true)
end

---@param text string
function KeySettingsItem:SetRightLabelText(text)
    self.rightLabel:SetText(text)

    self:SetNeedUpdateAllStateCanvas(true)
end

--- signals

function KeySettingsItem:Signal_ItemDisplayChanged()
    StandardItem.Signal_ItemDisplayChanged(self)
end

--- overrride
---@param state StandardItem.DisplayState
function KeySettingsItem:createDisplayStateCanvas(state)
    _Graphics.SaveCanvas()
    -- 创建背景画布
    local width, height = StandardItem.GetSize(self)
    local canvas = _Graphics.NewCanvas(width, height)
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
    _Graphics.DrawRect(0, 0, width, height, "fill")

    -- leftLabel
    self.leftLabel:SetPosition(self.leftMargin, 0)
    self.leftLabel:Draw()

    -- rightLabel
    local leftLabelWidth, _ = self.leftLabel:GetSize()
    self.rightLabel:SetPosition(self.leftMargin + leftLabelWidth, 0)
    self.rightLabel:Draw()

    -- 还原绘图数据
    _Graphics.RestoreCanvas()
    return canvas
end

return KeySettingsItem

