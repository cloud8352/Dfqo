--[[
	desc: SkillManagementItem class. 技能管理控件单项
	author: keke <243768648@qq.com>
]] --

local _Sprite = require("graphics.drawable.sprite")
local _Graphics = require("lib.graphics")
local _CONFIG = require("config")
local _Mouse = require("lib.mouse")
local Timer = require("util.gear.timer")
local _MATH = require("lib.math")

local WindowManager = require("UI.WindowManager")
local Common = require("UI.ui_common")
local Util = require("util.Util")

local StandardItem = require("UI.StandardItem")
local Label = require("UI.Label")
local ProgressBar = require("UI.ProgressBar")

---@class SkillManagementItem
local SkillManagementItem = require("core.class")(StandardItem)


local IconLabelMarginSpace = 0

---@param parentWindow Window
function SkillManagementItem:Ctor(parentWindow)
    -- 父类构造函数
    StandardItem.Ctor(self, parentWindow)

    local windowSizeScale = Util.GetWindowSizeScale()
    IconLabelMarginSpace = 5 * windowSizeScale

    self.iconLabel = Label.New(WindowManager.DefaultWindow)
    self.textLabel = Label.New(WindowManager.DefaultWindow)
    self.textLabel:SetAlignments({ Label.AlignmentFlag.AlignLeft, Label.AlignmentFlag.AlignVCenter })
    self.levelLabel = Label.New(WindowManager.DefaultWindow)
    self.levelLabel:SetAlignments({ Label.AlignmentFlag.AlignLeft, Label.AlignmentFlag.AlignVCenter })
    self.progressBar = ProgressBar.New(WindowManager.DefaultWindow)
end

function SkillManagementItem:Update(dt)
    if not self:IsVisible() then
        return
    end
    StandardItem.Update(self, dt)
end

function SkillManagementItem:Draw()
    if not self:IsVisible() then
        return
    end
    StandardItem.Draw(self)
end

--- 连接信号
---@param signal function
---@param obj Object
function SkillManagementItem:MocConnectSignal(signal, receiver)
    StandardItem.MocConnectSignal(self, signal, receiver)
end

---@param signal function
function SkillManagementItem:GetReceiverListOfSignal(signal)
    return StandardItem.GetReceiverListOfSignal(self, signal)
end

---@param name string
function SkillManagementItem:SetObjectName(name)
    StandardItem.SetObjectName(self, name)
end

function SkillManagementItem:GetObjectName()
    return StandardItem.GetObjectName(self)
end

function SkillManagementItem:SetPosition(x, y)
    StandardItem.SetPosition(self, x, y)
end

function SkillManagementItem:GetPosition()
    return StandardItem.GetPosition(self)
end

---@param width int
---@param height int
function SkillManagementItem:SetSize(width, height)
    if ((width <= 0) or (height <= 0)) then
        return
    end

    local windowSizeScale = Util.GetWindowSizeScale()

    self.iconLabel:SetSize(height - 2 * IconLabelMarginSpace, height - 2 * IconLabelMarginSpace)
    self.iconLabel:SetIconSize(height - 2 * IconLabelMarginSpace, height - 2 * IconLabelMarginSpace)
    -- 根据尺寸重绘控件
    self.iconLabel:Update(0)

    -- text
    local iconLabelTextLabelSpace = 5 * windowSizeScale
    local iconLabelW, _ = self.iconLabel:GetSize()
    local levelLabelW = 100 * windowSizeScale
    local textLabelLevelLabelSpace = 5 * windowSizeScale
    self.textLabel:SetSize(width - iconLabelW - IconLabelMarginSpace - iconLabelTextLabelSpace - textLabelLevelLabelSpace - levelLabelW,
        height / 2)
    -- 根据尺寸重绘控件
    self.textLabel:Update(0)

    -- level
    self.levelLabel:SetSize(levelLabelW, height / 2)
    -- 根据尺寸重绘控件
    self.levelLabel:Update(0)

    -- progress
    self.progressBar:SetSize(width - iconLabelW - IconLabelMarginSpace - iconLabelTextLabelSpace - 5 * windowSizeScale,
        height / 2 - 5 * windowSizeScale)
    -- 根据尺寸重绘控件
    self.progressBar:Update(0)

    -- 调用父类函数，更新显示画板
    StandardItem.SetSize(self, width, height)
end

function SkillManagementItem:GetSize()
    return StandardItem.GetSize(self)
end


function SkillManagementItem:SetEnable(enable)
    StandardItem.SetEnable(self, enable)
end

---@param isVisible bool
function SkillManagementItem:SetVisible(isVisible)
    StandardItem.SetVisible(self, isVisible)
end

function SkillManagementItem:IsVisible()
    return StandardItem.IsVisible(self)
end

---@return changed boolean
function SkillManagementItem:IsSizeChanged()
    return StandardItem.IsSizeChanged(self)
end

---@param sprite Graphics.Drawable.Sprite
function SkillManagementItem:SetBgSprite(sprite)
    StandardItem.SetBgSprite(self, sprite)
end

function SkillManagementItem:GetBgSprite()
    return StandardItem.GetBgSprite(self)
end

---@param x int
---@param y int
function SkillManagementItem:CheckPoint(x, y)
    return StandardItem.CheckPoint(self, x, y)
end

---@return canvas
function SkillManagementItem:GetCurrentImgCanvas()
    return StandardItem.GetCurrentImgCanvas(self)
end

---@return state StandardItem.DisplayState
function SkillManagementItem:GetCurrentDisplayState()
    return StandardItem.GetCurrentDisplayState(self)
end

---@param state StandardItem.DisplayState
function SkillManagementItem:SetDisplayState(state)
    StandardItem.SetDisplayState(self, state)
end

---@return index int
function SkillManagementItem:GetIndex()
    return StandardItem.GetIndex(self)
end

---@param index int
function SkillManagementItem:SetIndex(index)
    StandardItem.SetIndex(self, index)
end

---@param key string
---@param value obj
function SkillManagementItem:SetValue(key, value)
    StandardItem.SetValue(self, key, value)
end

---@param key string
---@return obj value
function SkillManagementItem:GetValue(key)
    return StandardItem.GetValue(self, key)
end

---@param str string
function SkillManagementItem:SetSortingStr(str)
    StandardItem.SetSortingStr(self, str)
end

function SkillManagementItem:GetSortingStr()
    return StandardItem.GetSortingStr(self)
end

---@param num number
function SkillManagementItem:SetSortingNum(num)
    StandardItem.SetSortingNum(self, num)
end

function SkillManagementItem:GetSortingNum()
    return StandardItem.GetSortingNum(self)
end

---@param need boolean
function SkillManagementItem:SetNeedUpdateAllStateCanvas(need)
    StandardItem.SetNeedUpdateAllStateCanvas(self, need)
end

---@param path string
function SkillManagementItem:SetIconPath(path)
    self.iconLabel:SetIconSpriteDataPath(path)
end

---@param title string
function SkillManagementItem:SetTitle(title)
    self.textLabel:SetText(title)
end

---@param level int
function SkillManagementItem:SetLevel(level)
    self.levelLabel:SetText("Lv." .. tostring(level))
end

---@param value int
---@param maxValue int
function SkillManagementItem:SetProgress(value, maxValue)
    self.progressBar:SetProgress(value / maxValue)
    self.progressBar:SetText(tostring(value) .. "/" .. tostring(maxValue))
end

---@param red integer
---@param green integer
---@param blue integer
---@param alpha integer
function SkillManagementItem:SetBarColor(red, green, blue, alpha)
    self.progressBar:SetBarColor(red, green, blue, alpha)
end

--- signals

function SkillManagementItem:Signal_ItemDisplayChanged()
    StandardItem.Signal_ItemDisplayChanged(self)
end

--- overrride
---@param state StandardItem.DisplayState
function SkillManagementItem:createDisplayStateCanvas(state)
    local windowSizeScale = Util.GetWindowSizeScale()
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

    -- icon
    self.iconLabel:SetPosition(IconLabelMarginSpace, IconLabelMarginSpace)
    self.iconLabel:Draw()

    -- text
    local iconLabelTextLabelSpace = 5 * windowSizeScale
    local iconLabelW, _ = self.iconLabel:GetSize()
    local textLabelLevelLabelSpace = 5 * windowSizeScale
    self.textLabel:SetPosition(iconLabelW + IconLabelMarginSpace + iconLabelTextLabelSpace, 0)
    self.textLabel:Draw()

    -- level
    local textLabelW, _ = self.textLabel:GetSize()
    self.levelLabel:SetPosition(iconLabelW + IconLabelMarginSpace + iconLabelTextLabelSpace + textLabelW + textLabelLevelLabelSpace, 0)
    self.levelLabel:Draw()

    -- progress
    self.progressBar:SetPosition(iconLabelW + IconLabelMarginSpace + iconLabelTextLabelSpace, height / 2)
    self.progressBar:Draw()

    -- 还原绘图数据
    _Graphics.RestoreCanvas()
    return canvas
end

return SkillManagementItem
