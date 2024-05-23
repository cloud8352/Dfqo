--[[
	desc: SkillDockViewItem class.
	author: keke <243768648@qq.com>
	since: 2023-3-19
	alter: 2023-3-19
]] --

local _Sprite = require("graphics.drawable.sprite")
local _Graphics = require("lib.graphics")
local _Mouse = require("lib.mouse")

local Widget = require("UI.Widget")
local Label = require("UI.Label")
local WindowManager = require("UI.WindowManager")

---@class SkillDockViewItem
local SkillDockViewItem = require("core.class")(Widget)

---@param parentWindow Window
function SkillDockViewItem:Ctor(parentWindow)
    Widget.Ctor(self, parentWindow)

    self.iconLabel = Label.New(parentWindow)
    self.coolDownShadowSprite = _Sprite.New()
    self.rightTopKeyLabel = Label.New(parentWindow)
    self.rightTopKeyLabel:SetAlignments({ Label.AlignmentFlag.AlignRight, Label.AlignmentFlag.AlignTop })

    self.coolDownProgress = 1.0
    self.lastCoolDownProgress = 1.0
end

function SkillDockViewItem:Update(dt)
    if not self:IsVisible() then
        return
    end

    if (self:IsSizeChanged()
            or self.lastCoolDownProgress ~= self.coolDownProgress
        )
    then
        self:updateSprite()
    end

    self.iconLabel:Update(dt)

    self.rightTopKeyLabel:Update(dt)

    self.lastCoolDownProgress = self.coolDownProgress
    Widget.Update(self, dt)
end

function SkillDockViewItem:Draw()
    if not self:IsVisible() then
        return
    end
    Widget.Draw(self)

    self.iconLabel:Draw()

    self.coolDownShadowSprite:Draw()

    self.rightTopKeyLabel:Draw()
end

--- 连接信号
---@param signal function
---@param obj Object
function SkillDockViewItem:MocConnectSignal(signal, receiver)
    Widget.MocConnectSignal(self, signal, receiver)
end

---@param signal function
function SkillDockViewItem:GetReceiverListOfSignal(signal)
    return Widget.GetReceiverListOfSignal(self, signal)
end

---@param name string
function SkillDockViewItem:SetObjectName(name)
    Widget.SetObjectName(self, name)
end

function SkillDockViewItem:GetObjectName()
    return Widget.GetObjectName(self)
end

function SkillDockViewItem:GetParentWindow()
    return Widget.GetParentWindow(self)
end

---@param x int
---@param y int
function SkillDockViewItem:SetPosition(x, y)
    Widget.SetPosition(self, x, y)
    
    self.iconLabel:SetPosition(x, y)
    self.coolDownShadowSprite:SetAttri("position", x, y)
    self.rightTopKeyLabel:SetPosition(x, y)
end

function SkillDockViewItem:GetPosition()
    return Widget.GetPosition(self)
end

function SkillDockViewItem:SetSize(width, height)
    Widget.SetSize(self, width, height)

    self.iconLabel:SetSize(width, height)
    self.iconLabel:SetIconSize(width, height)

    self.rightTopKeyLabel:SetSize(width - 4, 30)
end

function SkillDockViewItem:GetSize()
    return Widget.GetSize(self)
end

function SkillDockViewItem:IsSizeChanged()
    return Widget.IsSizeChanged(self)
end

function SkillDockViewItem:SetEnable(enable)
    Widget.SetEnable(self, enable)
    
    self.iconLabel:SetEnable(enable)
    self.rightTopKeyLabel:SetEnable(enable)
end

function SkillDockViewItem:IsVisible()
    return Widget.IsVisible(self)
end

---@param isVisible bool
function SkillDockViewItem:SetVisible(isVisible)
    Widget.SetVisible(self, isVisible)
end

---@param sprite Graphics.Drawable.Sprite
function SkillDockViewItem:SetBgSprite(sprite)
    Widget.SetBgSprite(self, sprite)
end

function SkillDockViewItem:GetBgSprite()
    return Widget.GetBgSprite(self)
end

---@param x int
---@param y int
---@return boolean
function SkillDockViewItem:CheckPoint(x, y)
    return Widget.CheckPoint(self, x, y)
end

---@param path string
function SkillDockViewItem:SetIconSpriteDataPath(path)
    self.iconLabel:SetIconSpriteDataPath(path)
end

---@param progress number
function SkillDockViewItem:SetCoolDownProgress(progress)
    self.coolDownProgress = progress
end

---@param key string
function SkillDockViewItem:SetKey(key)
    self.rightTopKeyLabel:SetText(key)
end


--- private function

function SkillDockViewItem:updateSprite()
    local width, height = self:GetSize()


    _Graphics.SaveCanvas()
    -- 画背景
    local canvas = _Graphics.NewCanvas(width, height)
    _Graphics.SetCanvas(canvas)

    _Graphics.SetColor(0, 0, 0, 130)
    _Graphics.DrawRect(0, 0, width, height, "fill")

    local bgSprite = self:GetBgSprite()
    bgSprite:SetImage(canvas)

    -- 画冷却阴影
    -- 创建背景画布
    canvas = _Graphics.NewCanvas(width, height)
    _Graphics.SetCanvas(canvas)

    _Graphics.SetColor(0, 0, 0, 200)
    local shadowHeight = height * (1 - self.coolDownProgress)
    _Graphics.DrawRect(0, height * self.coolDownProgress, width, shadowHeight, "fill")

    -- 还原绘图数据
    _Graphics.RestoreCanvas()

    self.coolDownShadowSprite:SetImage(canvas)
    self.coolDownShadowSprite:AdjustDimensions()
end

return SkillDockViewItem
