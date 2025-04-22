--[[
	desc: LineEdit class.
	author: keke <243768648@qq.com>
]]--

local Widget = require("UI.Widget")
local WindowManager = require("UI.WindowManager")

local GraphicsLib = require("lib.graphics")
local _Mouse = require("lib.mouse")
local Touch = require("lib.touch")
local KeyboardLib = require("lib.keyboard")
local StringLib = require("lib.string")
local TextInputLib = require("lib.TextInput")

---@class LineEdit : Widget
local LineEdit = require("core.class")(Widget)

---@param parentWindow Window
function LineEdit.Create(parentWindow)
    -- 用于定义构造函数，解释使用，不做实际用途
    -- 使用class模块后，实际会调用Ctor函数
    return LineEdit.New(parentWindow)
end

---@param parentWindow Window
function LineEdit:Ctor(parentWindow)
    Widget.Ctor(self, parentWindow)
    self:SetBgSpriteColor(0, 0, 0, 0)

    self.text = ""
    self.cursorPos = 1       -- 光标位置（基于字符数）
    self.isCursorPosChanged = false
    self.cursorBlinkTimeMs = 0      -- 光标闪烁计时
    self.cursorBlinkIntervalMs = 500     -- 光标闪烁速度（ms）
    self.xOffset = 0          -- 文本水平偏移（用于长文本滚动）
    self.focused = false
    self.backgroundColor = { 0, 0, 0, 255 }
    self.textColor = { 255, 255, 255, 255 }
    self.cursorColor = { 255, 255, 255, 220 }
    self.borderColor = { 100, 100, 100, 255 }

    self.textCanvas = nil
end

function LineEdit:Update(dt)
    if false == self.isVisible then
        return
    end

    self:mouseEvent()
    self:keyboardEvent()
    self:textInputEvent()

    if self:IsSizeChanged()
        or self.isCursorPosChanged
    then
        self:updateDataByCursorPos()
        self:updateTextCanvas()
    end

    -- 更新光标闪烁效果
    self.cursorBlinkTimeMs = self.cursorBlinkTimeMs + dt
    if self.cursorBlinkTimeMs > 2 * self.cursorBlinkIntervalMs then
        self.cursorBlinkTimeMs = 0
    end

    self.isCursorPosChanged = false
    Widget.Update(self, dt)
end

function LineEdit:Draw()
    if false == self.isVisible then
        return
    end
    Widget.Draw(self)

    -- 绘制背景
    GraphicsLib.SetColor(self.backgroundColor)
    GraphicsLib.DrawRect(self.xPos, self.yPos, self.width, self.height, "fill")
    
    -- 绘制边框
    GraphicsLib.SetColor(self.borderColor)
    GraphicsLib.DrawRect(self.xPos, self.yPos, self.width, self.height, "line")
    
    -- 绘制文本
    if self.textCanvas then
        GraphicsLib.SetColor(255, 255, 255, 255)
        GraphicsLib.DrawObj(self.textCanvas, self.xPos + 5, self.yPos)
    end
    
    -- 绘制光标（当获得焦点时）
    if self.focused and self.cursorBlinkTimeMs < self.cursorBlinkIntervalMs then
        GraphicsLib.SetColor(self.cursorColor)
        GraphicsLib.DrawLine(self.cursorX, self.yPos + 5, self.cursorX, self.yPos + self.height - 5)
    end
end

--- 连接信号
---@param signal function
---@param obj Object
function LineEdit:MocConnectSignal(signal, receiver)
    Widget.MocConnectSignal(self, signal, receiver)
end

---@param signal function
function LineEdit:GetReceiverListOfSignal(signal)
    return Widget.GetReceiverListOfSignal(self, signal)
end

---@param name string
function LineEdit:SetObjectName(name)
    Widget.SetObjectName(self, name)
end

function LineEdit:GetObjectName()
    return Widget.GetObjectName(self)
end

---@param x int
---@param y int
function LineEdit:SetPosition(x, y)
    Widget.SetPosition(self, x, y)
end

---@return int, int 横坐标， 纵坐标
function LineEdit:GetPosition()
    return Widget.GetPosition(self)
end

---@return int, int @宽，高
function LineEdit:GetSize()
    return Widget.GetSize(self)
end

function LineEdit:GetWidth()
    return self.width
end

function LineEdit:GetHeight()
    return self.height
end

function LineEdit:SetSize(width, height)
    Widget.SetSize(self, width, height)
end

function LineEdit:SetEnable(enable)
    Widget.SetEnable(self, enable)
end

function LineEdit:IsVisible()
    return Widget.IsVisible(self)
end

---@param isVisible bool
function LineEdit:SetVisible(isVisible)
    Widget.SetVisible(self, isVisible)
end

function LineEdit:CheckPoint(x, y)
    return Widget.CheckPoint(self, x, y)
end

---@param text string
function LineEdit:SetText(text)
    self.text = text
    self.cursorPos = 0
    self:setCursorPos(StringLib.Len(self.text) + 1)
end

function LineEdit:GetText()
    return self.text
end

--- private func

function LineEdit:mouseEvent()
    -- 判断鼠标
    while true do
        -- 检查是否有上层窗口遮挡
        local windowLayerIndex = self.parentWindow:GetWindowLayerIndex()
        if WindowManager.IsMouseCapturedAboveLayer(windowLayerIndex)
            or self.parentWindow:IsInMoving() then
            self:setFocused(false)
            break
        end

        -- 确保鼠标在控件上
        local mousePosX, mousePosY = _Mouse.GetPosition(1, 1)
        if false == self:CheckPoint(mousePosX, mousePosY) then
            -- 是否点击了鼠标左键
            if _Mouse.IsPressed(1) then -- 1 is the primary mouse button, 2 is the secondary mouse button and 3 is the middle button
                self:setFocused(false)
            end
            break
        end

        -- 是否点击了鼠标左键
        if _Mouse.IsPressed(1) then -- 1 is the primary mouse button, 2 is the secondary mouse button and 3 is the middle button
            self:setFocused(true)
            break
        end

        break
    end
end

function LineEdit:textInputEvent()
    local text = TextInputLib.GetText()
    if text == "" then
        return
    end
    if false == self.focused then
        return
    end
    
    self.text = StringLib.Offset(self.text, self.cursorPos) .. text
        .. StringLib.Offset(self.text, self.cursorPos, true)
    self:setCursorPos(self.cursorPos + StringLib.Len(text))
end

function LineEdit:keyboardEvent()
    if self.focused then
        if KeyboardLib.IsPressed("backspace") then
            if self.cursorPos > 1 then
                local leftText = StringLib.Offset(self.text, self.cursorPos - 1)
                local rightText = StringLib.Offset(self.text, self.cursorPos, true)
                self.text = leftText .. rightText
                self:setCursorPos(self.cursorPos - 1)
            end
        elseif KeyboardLib.IsPressed("left") then
            local cursorPos = math.max(1, self.cursorPos - 1)
            self:setCursorPos(cursorPos)
        elseif KeyboardLib.IsPressed("right") then
            local cursorPos = math.min(StringLib.Len(self.text) + 1, self.cursorPos + 1)
            self:setCursorPos(cursorPos)
        end
    end
end

function LineEdit:setFocused(focused)
    if self.focused == focused then
        return
    end

    self.focused = focused
    TextInputLib.EnableTextInput(focused)
end

function LineEdit:setCursorPos(pos)
    if self.cursorPos == pos then
        return
    end
    
    self.cursorPos = pos
    self.isCursorPosChanged = true
end

function LineEdit:updateDataByCursorPos()
    local textMaxWidth = self.width - 10

    local leftToCursorText = StringLib.Offset(self.text, self.cursorPos)
    local leftToCursorTextWidth = GraphicsLib.GetFontWidth(leftToCursorText)
    if leftToCursorTextWidth > textMaxWidth then
        self.xOffset = leftToCursorTextWidth - textMaxWidth
    end
    if self.xOffset > leftToCursorTextWidth then
        self.xOffset = leftToCursorTextWidth       
    end

    self.cursorX = self.xPos + 5 + leftToCursorTextWidth - self.xOffset

    self.needUpdateTextCanvas = true
end

function LineEdit:updateTextCanvas()
    local width = self.width - 10
    local height = self.height

    GraphicsLib.SaveCanvas()
    local canvas = GraphicsLib.NewCanvas(width, height)
    GraphicsLib.SetCanvas(canvas)
    
    -- 绘制文本
    GraphicsLib.SetColor(self.textColor)
    GraphicsLib.Print(self.text, -self.xOffset, (height - GraphicsLib.GetFontHeight()) / 2, 
        0, 1, 1, 0, 0)

    GraphicsLib.RestoreCanvas()
    self.textCanvas = canvas
end

return LineEdit
