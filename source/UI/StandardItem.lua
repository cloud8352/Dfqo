--[[
    desc: StandardItem class. 用于存储表格或列表的单元数据
    author: keke <243768648@qq.com>
    since: 2022-12-09
    alter: 2022-12-09
]] --

local _Sprite = require("graphics.drawable.sprite")
local _Graphics = require("lib.graphics")

--- 滑动区域
---@class StandardItem
local StandardItem = require("core.class")()

---@enum StandardItem.DisplayState
StandardItem.DisplayState = {
    Unknown = 0,
    Normal = 1,
    Hovering = 2,
    Selected = 3,
    Disable = 4,
}

function StandardItem:Ctor()
    self.xPos = 0
    self.yPos = 0
    ---@type int
    self.width = 0
    ---@type int
    self.height = 0
    self.enable = true
    self.lastDisplayState = StandardItem.DisplayState.Unknown
    self.displayState = StandardItem.DisplayState.Normal

    ---@type Graphics.Drawable | Graphics.Drawable.IRect | Graphics.Drawable.IPath | Graphics.Drawable.Sprite
    self.sprite = _Sprite.New()
    self.sprite:SwitchRect(true)
    self.text = ""

    self.normalImgCanvas = nil
    self.hoveringImgCanvas = nil
    self.selectedImgCanvas = nil
    self.disableImgCanvas = nil
    self.currentImgCanvas = nil

    self.index = 1 -- 显示项检索值
end

function StandardItem:Update(dt)
    if nil == self.normalImgCanvas then
        self.normalImgCanvas = _Graphics.NewCanvas(self.width, self.height)
    end
    if nil == self.hoveringImgCanvas then
        self.hoveringImgCanvas = _Graphics.NewCanvas(self.width, self.height)
    end
    if nil == self.selectedImgCanvas then
        self.selectedImgCanvas = _Graphics.NewCanvas(self.width, self.height)
    end
    if nil == self.disableImgCanvas then
        self.disableImgCanvas = _Graphics.NewCanvas(self.width, self.height)
    end

    -- 根据状态设置按钮图片
    if self.lastDisplayState ~= self.displayState then
        if StandardItem.DisplayState.Normal == self.displayState then
            self.currentImgCanvas = self.normalImgCanvas
        elseif StandardItem.DisplayState.Hovering == self.displayState then
            self.currentImgCanvas = self.hoveringImgCanvas
        elseif StandardItem.DisplayState.Selected == self.displayState then
            self.currentImgCanvas = self.selectedImgCanvas
        elseif StandardItem.DisplayState.Disable == self.displayState then
            self.currentImgCanvas = self.disableImgCanvas
        end
        self.sprite:SetImage(self.currentImgCanvas)
        -- 设置图片后调整精灵维度
        self.sprite:AdjustDimensions()
    end

    self.lastDisplayState = self.displayState
end

function StandardItem:Draw()
    self.sprite:Draw()
end

function StandardItem:SetPosition(x, y)
    self.sprite:SetAttri("position", x, y)
    self.xPos = x
    self.yPos = y
end

function StandardItem:SetSize(w, h)
    self.width = w
    self.height = h

    self.normalImgCanvas = self:createDisplayStateCanvas(StandardItem.DisplayState.Normal)
    self.hoveringImgCanvas = self:createDisplayStateCanvas(StandardItem.DisplayState.Hovering)
    self.selectedImgCanvas = self:createDisplayStateCanvas(StandardItem.DisplayState.Selected)
    self.disableImgCanvas = self:createDisplayStateCanvas(StandardItem.DisplayState.Disable)
end

---@param text string
function StandardItem:SetText(text)
    self.text = text
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
    self.displayState = state
end

function StandardItem:IsDisplayStateChanged()
    -- 判断显示模式是否改变
    return self.lastDisplayState ~= self.displayState
end

---@param state StandardItem.DisplayState
function StandardItem:createDisplayStateCanvas(state)
    -- 创建背景画布
    local canvas = _Graphics.NewCanvas(self.width, self.height)
    _Graphics.SetCanvas(canvas)

    local originColorR, originColorG, originColorB, originColorA = _Graphics.GetColor()
    ---@type int
    local r, g, b, a
    ---@type int
    local txtR, txtG, txtB, txtA
    if StandardItem.DisplayState.Normal == state then
        r = 255; g = 255; b = 255; a = 0
        txtR = 255; txtG = 255; txtB = 255; txtA = 255
    elseif StandardItem.DisplayState.Hovering == state then
        r = 160; g = 160; b = 160; a = 160
        txtR = 255; txtG = 255; txtB = 255; txtA = 255
    elseif StandardItem.DisplayState.Selected == state then
        r = 30; g = 144; b = 255; a = 255
        txtR = 255; txtG = 255; txtB = 255; txtA = 255
    elseif StandardItem.DisplayState.Disable == state then
        r = 100; g = 100; b = 100; a = 255
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
    _Graphics.SetCanvas()
    _Graphics.SetColor(originColorR, originColorG, originColorB, originColorA)
    return canvas
end

---@param x int
---@param y int
function StandardItem:CheckPoint(x, y)
    return self.sprite:CheckPoint(x, y)
end

---@return index int
function StandardItem:GetIndex()
    return self.index
end
---@param index int
function StandardItem:SetIndex(index)
    self.index = index
end

return StandardItem
