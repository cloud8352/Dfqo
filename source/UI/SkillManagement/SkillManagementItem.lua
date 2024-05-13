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

function SkillManagementItem:Ctor()
    -- 父类构造函数
    StandardItem.Ctor(self)

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
    StandardItem.Update(self, dt)
end

function SkillManagementItem:Draw()
    StandardItem.Draw(self)
end

function SkillManagementItem:SetPosition(x, y)
    StandardItem.SetPosition(self, x, y)
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

function SkillManagementItem:IsDisplayStateChanged()
    return StandardItem.IsDisplayStateChanged(self)
end

---@param x int
---@param y int
function SkillManagementItem:CheckPoint(x, y)
    return StandardItem.CheckPoint(self, x, y)
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
