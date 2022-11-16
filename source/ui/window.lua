--[[
	desc: Window class.
	author: keke <243768648@qq.com>
	since: 2022-11-15
	alter: 2022-11-15
]]--

local _CONFIG = require("config")
local _RESOURCE = require("lib.resource")
local _Sprite = require("graphics.drawable.sprite")
local _Graphics = require("lib.graphics")
local _Mouse= require("lib.mouse")

local TitleBar = require("ui/titlebar")

local Window = require("core.class")()

local DisplayState = {
    Unkonwn = 0,
    Normal = 1,
    Hovering = 2,
    Pressing = 3,
    Disable = 4,
}

function Window:Ctor()

    self.bgSprite = _Sprite.New()
    -- self.sprite:SwitchRect(true) -- 使用矩形
    self.spriteXScale, self.spriteYScale = self.bgSprite:GetAttri("scale")
    self.width = 30
    self.height = 10
    self.posX = 0
    self.posY = 0
    self.lastDisplayState = DisplayState.Unkonwn
    self.displayState = DisplayState.Normal
    self.enable = true

    -- 背景图片数据
    self.leftTopBgImgDate = _RESOURCE.GetSpriteData("ui/WindowFrame/LeftTopBg")
    self.topBgImgDate = _RESOURCE.GetSpriteData("ui/WindowFrame/TopBg")
    self.rightTopBgImgDate = _RESOURCE.GetSpriteData("ui/WindowFrame/RightTopBg")
    self.leftBgImgDate = _RESOURCE.GetSpriteData("ui/WindowFrame/LeftBg")
    self.centerBgImgDate = _RESOURCE.GetSpriteData("ui/WindowFrame/CenterBg")
    self.rightBgImgDate = _RESOURCE.GetSpriteData("ui/WindowFrame/RightBg")
    self.leftBottomBgImgDate = _RESOURCE.GetSpriteData("ui/WindowFrame/LeftBottomBg")
    self.bottomBgImgDate = _RESOURCE.GetSpriteData("ui/WindowFrame/BottomBg")
    self.rightBottomBgImgDate = _RESOURCE.GetSpriteData("ui/WindowFrame/RightBottomBg")

    -- title bar
    self.titleBar = TitleBar.New()

    self.receiverOfRequestMoveWindow = nil
    self.receiverOfRequestCloseWindow = nil

    -- connect
    self.titleBar:SetReceiverOfRequestMoveWindow(self)
    self.titleBar:SetReceiverOfRequestCloseWindow(self)
end

function Window:Update(dt)
    self.titleBar:Update(dt)
end

function Window:Draw()
    self.bgSprite:Draw()

    self.titleBar:Draw()
end

function Window:SetPosition(x, y)
    self.bgSprite:SetAttri("position", x, y)
    self.posX = x
    self.posY = y

    self.titleBar:SetPosition(x, y)
end

function Window:SetSize(width, height)
    self.width = width
    self.height = height

    -- 创建背景画布
    local canvas = _Graphics.NewCanvas(self.width, self.height)
    _Graphics.SetCanvas(canvas)

    -- 创建临时绘图精灵
    local painterSprite = _Sprite.New()
    -- 画左上角背景
    painterSprite:SetData(self.leftTopBgImgDate)
    painterSprite:SetAttri("position", 0, 0)
    painterSprite:Draw()
    -- 画上中段背景
    painterSprite:SetData(self.topBgImgDate)
    painterSprite:SetAttri("position", self.leftTopBgImgDate.w, 0)
    local topCenterBgXScale = (self.width - self.leftTopBgImgDate.w - self.rightTopBgImgDate.w) / self.topBgImgDate.w
    painterSprite:SetAttri("scale", topCenterBgXScale, 1)
    painterSprite:Draw()

    -- 画右上角背景
    painterSprite:SetData(self.rightTopBgImgDate)
    painterSprite:SetAttri("position", self.width - self.rightTopBgImgDate.w, 0)
    painterSprite:Draw()

    -- 画左中段背景
    painterSprite:SetData(self.leftBgImgDate)
    painterSprite:SetAttri("position", 0, self.leftTopBgImgDate.h)
    local centerBgYScale = (self.height - self.leftTopBgImgDate.h - self.leftBottomBgImgDate.h) / self.leftBgImgDate.h
    painterSprite:SetAttri("scale", 1, centerBgYScale)
    painterSprite:Draw()
    -- 画中间部分的背景
    painterSprite:SetData(self.centerBgImgDate)
    painterSprite:SetAttri("position", self.leftBgImgDate.w, self.leftTopBgImgDate.h)
    painterSprite:SetAttri("scale", topCenterBgXScale, centerBgYScale)
    painterSprite:Draw()
    -- 画右中段背景
    painterSprite:SetData(self.rightBgImgDate)
    painterSprite:SetAttri("position", self.width - self.rightBgImgDate.w, self.leftTopBgImgDate.h)
    painterSprite:SetAttri("scale", 1, centerBgYScale)
    painterSprite:Draw()

    -- 画左下角背景
    painterSprite:SetData(self.leftBottomBgImgDate)
    painterSprite:SetAttri("position", 0, self.height - self.leftBottomBgImgDate.h)
    painterSprite:Draw()
    -- 画下中段背景
    painterSprite:SetData(self.bottomBgImgDate)
    painterSprite:SetAttri("position", self.leftBottomBgImgDate.w, self.height - self.leftBottomBgImgDate.h)
    painterSprite:SetAttri("scale", topCenterBgXScale, 1)
    painterSprite:Draw()
    -- 画右下角背景
    painterSprite:SetData(self.rightBottomBgImgDate)
    painterSprite:SetAttri("position", self.width - self.rightBottomBgImgDate.w, self.height - self.leftBottomBgImgDate.h)
    painterSprite:Draw()

    _Graphics.SetCanvas()
    self.bgSprite:SetImage(canvas)

    -- 设置标题栏尺寸
    self.titleBar:SetSize(self.width, 50)
end

function Window:SetEnable(enable)
    self.enable = enable
end

function Window:SetScale(xScale, yScale)
    self.spriteXScale = xScale
    self.spriteYScale = yScale
end

function Window:OnRequestMoveWindow(x, y)
    self:judgeAndExecRequestMoveWindow(x, y)
end

function Window:OnRequestCloseWindow()
    self:judgeAndExecRequestCloseWindow()
end

function Window:SetReceiverOfRequestMoveWindow(receiver)
    self.receiverOfRequestMoveWindow = receiver
end

function Window:judgeAndExecRequestMoveWindow(x, y)
    if nil == self.receiverOfRequestMoveWindow then
        return
    end
    if nil == self.receiverOfRequestMoveWindow.OnRequestMoveWindow then
        return
    end

    self.receiverOfRequestMoveWindow.OnRequestMoveWindow(self, x, y)
end

function Window:SetReceiverOfRequestCloseWindow(receiver)
    self.receiverOfRequestCloseWindow = receiver
end

function Window:judgeAndExecRequestCloseWindow(x, y)
    if nil == self.receiverOfRequestCloseWindow then
        return
    end
    if nil == self.receiverOfRequestCloseWindow.OnRequestCloseWindow then
        return
    end

    self.receiverOfRequestCloseWindow.OnRequestCloseWindow(self)
end

return Window