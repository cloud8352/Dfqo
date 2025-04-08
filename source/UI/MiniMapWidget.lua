--[[
	desc: MiniMapWidget class.
	author: keke <243768648@qq.com>
]]--

local Util = require("util.Util")

local Widget = require("UI.Widget")
local Label = require("UI.Label")
local PushButton = require("UI.PushButton")

local _Sprite = require("graphics.drawable.sprite")
local GraphicsLib = require("lib.graphics")

---@class MiniMapWidget : Widget
local MiniMapWidget = require("core.class")(Widget)

local MagnifierNormalImgPath = "ui/PushButton/Magnifier/Normal"
local MagnifierHoveringImgPath = "ui/PushButton/Magnifier/Hovering"

---@param parentWindow Window
---@param model UiModel
function MiniMapWidget.Create(parentWindow, model)
    -- 用于定义构造函数，解释使用，不做实际用途
    -- 使用class模块后，实际会调用Ctor函数
    return MiniMapWidget.New(parentWindow, model)
end

---@param parentWindow Window
---@param model UiModel
function MiniMapWidget:Ctor(parentWindow, model)
    Widget.Ctor(self, parentWindow)
    self.model = model
    self:SetBgSpriteColor(0, 0, 0, 0)

    local windowsSizeScale = Util.GetWindowSizeScale()

    local largeMapContent = Widget.Create(parentWindow)
    self.largeMapContent = largeMapContent
    local largeMapContentW = Util.GetWindowWidth() * 0.7
    local largeMapContentH = Util.GetWindowWidth() * 0.7
    largeMapContent:SetSize(largeMapContentW, largeMapContentH)

    ---@type Graphics.Drawable.Frameani
    self.planeMapSprite = nil

    self.realMapScopeX = 10
    self.realMapScopeY = 10
    self.realMapScopeW = 2673
    self.realMapScopeH = 1090
    self.playerXPos = 0
    self.playerYPos = 0
    self.playerLocationCircleX = 0
    self.playerLocationCircleY = 0
    self.scaleOfRealMapToMiniMap = 1.0
    self.miniMapInitX = 0
    self.miniMapInitY = 0

    local widgetW, widgetH, miniMapW, miniMapH = 0
    miniMapW = 0

    local titleLabel = Label.Create(parentWindow)
    self.titleLabel = titleLabel
    titleLabel:SetBgSpriteColor(255, 255, 255, 255)
    widgetW = 150 * windowsSizeScale
    miniMapW = miniMapW + widgetW
    widgetH = 25 * windowsSizeScale
    titleLabel:SetSize(widgetW, widgetH)
    titleLabel:SetText("Test Map")

    local posLabel = Label.Create(parentWindow)
    self.posLabel = posLabel
    posLabel:SetBgSpriteColor(255, 255, 255, 255)
    widgetW = 75 * windowsSizeScale
    miniMapW = miniMapW + widgetW
    widgetH = 25 * windowsSizeScale
    posLabel:SetSize(widgetW, widgetH)

    local enlargeBtn = PushButton.Create(parentWindow)
    self.enlargeBtn = enlargeBtn
    enlargeBtn:SetBgSpriteColor(255, 255, 255, 255)
    widgetW = 25 * windowsSizeScale
    miniMapW = miniMapW + widgetW
    widgetH = 25 * windowsSizeScale
    enlargeBtn:SetSize(widgetW, widgetH)
    enlargeBtn:SetNormalSpriteDataPath(MagnifierNormalImgPath)
    enlargeBtn:SetPressingSpriteDataPath(MagnifierNormalImgPath)
    enlargeBtn:SetHoveringSpriteDataPath(MagnifierHoveringImgPath)
    enlargeBtn:SetDisabledSpriteDataPath(MagnifierNormalImgPath)

    local miniMapContent = Widget.Create(parentWindow)
    self.miniMapContent = miniMapContent
    miniMapH = miniMapW * 0.6
    miniMapContent:SetSize(miniMapW, miniMapH)

    self.miniMapCanvas = GraphicsLib.NewCanvas(miniMapW, miniMapH)
    local miniMapSprite = _Sprite.New()
    miniMapSprite:SetImage(self.miniMapCanvas)
    miniMapContent:SetBgSprite(miniMapSprite)

    --- connect
    self.model:MocConnectSignal(self.model.Signal_MapLoaded, self)

    --- post init
    self:SetSize(miniMapW, miniMapH + widgetH)
end

function MiniMapWidget:Update(dt)
    if false == self.isVisible then
        return
    end

    if self.model:GetPlayer() then
        local player = self.model:GetPlayer()
        self:SetPlayerPos(player.transform.position.x, player.transform.position.y)
    end

    self.titleLabel:Update(dt)
    self.posLabel:Update(dt)
    self.enlargeBtn:Update(dt)
    self.miniMapContent:Update(dt)

    Widget.Update(self, dt)
end

function MiniMapWidget:Draw()
    if false == self.isVisible then
        return
    end
    Widget.Draw(self)
    
    self.titleLabel:Draw()
    self.posLabel:Draw()
    self.enlargeBtn:Draw()
    self.miniMapContent:Draw()

    -- 画玩家位置
    GraphicsLib.SetColor(0, 255, 255, 255)
    GraphicsLib.DrawCircle(self.playerLocationCircleX, self.playerLocationCircleY, 6, "fill")
end

--- 连接信号
---@param signal function
---@param obj Object
function MiniMapWidget:MocConnectSignal(signal, receiver)
    Widget.MocConnectSignal(self, signal, receiver)
end

---@param signal function
function MiniMapWidget:GetReceiverListOfSignal(signal)
    return Widget.GetReceiverListOfSignal(self, signal)
end

---@param name string
function MiniMapWidget:SetObjectName(name)
    Widget.SetObjectName(self, name)
end

function MiniMapWidget:GetObjectName()
    return Widget.GetObjectName(self)
end

---@param x int
---@param y int
function MiniMapWidget:SetPosition(x, y)
    Widget.SetPosition(self, x, y)

    local widgetW, widgetH, widgetX, widgetY = 0

    self.titleLabel:SetPosition(x, y)

    widgetX, widgetY = self.titleLabel:GetPosition()
    widgetW, widgetH = self.titleLabel:GetSize()
    self.posLabel:SetPosition(widgetX + widgetW, y)

    widgetX, widgetY = self.posLabel:GetPosition()
    widgetW, widgetH = self.posLabel:GetSize()
    self.enlargeBtn:SetPosition(widgetX + widgetW, y)

    self.miniMapContent:SetPosition(x, y + widgetH)
end

---@return int, int 横坐标， 纵坐标
function MiniMapWidget:GetPosition()
    return Widget.GetPosition(self)
end

---@return int, int @宽，高
function MiniMapWidget:GetSize()
    return Widget.GetSize(self)
end

function MiniMapWidget:SetSize(width, height)
    Widget.SetSize(self, width, height)
end

function MiniMapWidget:SetEnable(enable)
    Widget.SetEnable(self, enable)
end

function MiniMapWidget:IsVisible()
    return Widget.IsVisible(self)
end

---@param isVisible bool
function MiniMapWidget:SetVisible(isVisible)
    Widget.SetVisible(self, isVisible)
end

function MiniMapWidget:CheckPoint(x, y)
    return Widget.CheckPoint(self, x, y)
end

---@param x int
---@param y int
---@param w int
---@param h int
function MiniMapWidget:SetRealMapScope(x, y, w, h)
    self.realMapScopeX = x
    self.realMapScopeY = y
    self.realMapScopeW = w
    self.realMapScopeH = h
end

function MiniMapWidget:SetPlayerPos(x, y)
    x = math.floor(x)
    y = math.floor(y)
    if self.playerXPos == x and self.playerYPos == y then
        return
    end

    self.playerXPos = x
    self.playerYPos = y

    local displayX = math.floor(x / 10)
    local displayY = math.floor(y / 10)
    self.posLabel:SetText(tostring(displayX) .. ", " .. tostring(displayY))

    -- 玩家角色位置点
    local miniMapContentX, miniMapContentY = self.miniMapContent:GetPosition()

    local playerXPosInScope = self.playerXPos - self.realMapScopeX
    local playerYPosInScope = self.playerYPos - self.realMapScopeY
    self.playerLocationCircleX = miniMapContentX + self.miniMapInitX +
        self.scaleOfRealMapToMiniMap * playerXPosInScope
    self.playerLocationCircleY = miniMapContentY + self.miniMapInitY +
        self.scaleOfRealMapToMiniMap * playerYPosInScope 
end

--- slots

---@param sender Obj
---@param scopeRect Graphics.Drawunit.Rect
function MiniMapWidget:Slot_MapLoaded(sender, scopeRect)
    local x = scopeRect:Get("x")
    local y = scopeRect:Get("y")
    local w = scopeRect:Get("w")
    local h = scopeRect:Get("h")
    self:SetRealMapScope(x, y, w, h)

    self.titleLabel:SetText(self.model:GetMapInfo().name)

    --- 更新小地图参数
    local planeMapSprite = self.model:CreatePlaneMapSprite()
    local miniMapContentW, miniMapContentH = self.miniMapContent:GetSize()
    local scale = 1.0
    local x = 0
    local y = 0
    if self.realMapScopeW > self.realMapScopeH then
        scale = miniMapContentW / self.realMapScopeW
        y = miniMapContentH / 2 - self.realMapScopeH * scale / 2
    else
        scale = miniMapContentH / self.realMapScopeH
        x = miniMapContentW / 2 - self.realMapScopeW * scale / 2
    end
    planeMapSprite:SetAttri("position", x, y)
    planeMapSprite:SetAttri("scale", scale, scale)

    self.scaleOfRealMapToMiniMap = scale
    self.miniMapInitX = x
    self.miniMapInitY = y
    self.planeMapSprite = planeMapSprite
    self:updateMiniMapCanvas()

    self.playerXPos = 0
    self.playerYPos = 0
end

--- private func

function MiniMapWidget:updateMiniMapCanvas()
    GraphicsLib.SaveCanvas()

    GraphicsLib.SetCanvas(self.miniMapCanvas)
    GraphicsLib.Clear()

    local miniMapContentW, miniMapContentH = self.miniMapContent:GetSize()
    GraphicsLib.SetColor(0, 0, 0, 130)
    GraphicsLib.DrawRect(0, 0, miniMapContentW, miniMapContentH, "fill")

    self.planeMapSprite:Draw()

    GraphicsLib.RestoreCanvas()
end

return MiniMapWidget
