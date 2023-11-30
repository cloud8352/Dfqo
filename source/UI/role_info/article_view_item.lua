--[[
	desc: ArticleViewItem class.
	author: keke <243768648@qq.com>
	since: 2023-3-19
	alter: 2023-7-19
]] --

local _Sprite = require("graphics.drawable.sprite")
local _Graphics = require("lib.graphics")

local Widget = require("UI.Widget")
local Label = require("UI.Label")

---@class ArticleViewItem
local ArticleViewItem = require("core.class")(Widget)

---@param parentWindow Window
function ArticleViewItem:Ctor(parentWindow)
    assert(parentWindow, "must assign parent window")
    -- 父类构造函数
    Widget.Ctor(self, parentWindow)

    self.iconLabel = Label.New(parentWindow)
    self.coolDownShadowSprite = _Sprite.New()
    self.leftBottomCountLabel = Label.New(parentWindow)
    self.leftBottomCountLabel:SetAlignments({Label.AlignmentFlag.AlignLeft, Label.AlignmentFlag.AlignBottom})

    self.coolDownProgress = 1
    self.lastCoolDownProgress = 1
end

function ArticleViewItem:Update(dt)
    if (Widget.IsSizeChanged(self)
        or self.lastCoolDownProgress ~= self.coolDownProgress
        )
        then
        self:updateSprite()


        self.iconLabel:SetPosition(self.xPos, self.yPos)
        self.iconLabel:SetSize(self.width, self.height)
        self.iconLabel:SetIconSize(self.width, self.height)

        self.leftBottomCountLabel:SetPosition(self.xPos + 2, self.yPos + self.height - 30)
        self.leftBottomCountLabel:SetSize(self.width - 2, 30)
    end


    self.iconLabel:Update(dt)

    self.leftBottomCountLabel:Update(dt)

    self.lastIconSpriteDataPath = self.iconSpriteDataPath
    self.lastCoolDownProgress = self.coolDownProgress

    Widget.Update(self, dt)
end

function ArticleViewItem:Draw()
    self.iconLabel:Draw()

    if self.isVisible then
        self.coolDownShadowSprite:Draw()
    end

    self.leftBottomCountLabel:Draw()

    Widget.Draw(self)
end

function ArticleViewItem:SetPosition(x, y)
    Widget.SetPosition(self, x, y)

    self.iconLabel:SetPosition(self.xPos, self.yPos)
    self.leftBottomCountLabel:SetPosition(self.xPos + 2, self.yPos + self.height - 30)

    self.coolDownShadowSprite:SetAttri("position", self.xPos, self.yPos)
end

function ArticleViewItem:SetSize(width, height)
    Widget.SetSize(self, width, height)
end

function ArticleViewItem:SetEnable(enable)
    self.iconLabel:SetEnable(enable)
    self.leftBottomCountLabel:SetEnable(enable)

    Widget.SetEnable(self, enable)
end

---@param isVisible boolean
function ArticleViewItem:SetVisible(isVisible)
    self.iconLabel:SetVisible(isVisible)
    self.leftBottomCountLabel:SetVisible(isVisible)

    Widget.SetVisible(self, isVisible)
end

---@param path string
function ArticleViewItem:SetIconSpriteDataPath(path)
    self.iconSpriteDataPath = path
    self.iconLabel:SetIconSpriteDataPath(path)
end

function ArticleViewItem:SetCoolDownProgress(progress)
    self.coolDownProgress = progress
end

---@param count number
function ArticleViewItem:SetCount(count)
    local countStr = ""
    if count > 1 then
        countStr = tostring(count)
    end
    self.leftBottomCountLabel:SetText(countStr)
end

function ArticleViewItem:updateSprite()
    -- 创建背景画布
    local canvas = _Graphics.NewCanvas(self.width, self.height)
    _Graphics.SetCanvas(canvas)
    local originColorR, originColorG, originColorB, originColorA = _Graphics.GetColor()

    ---@type int
    local r, g, b, a
    _Graphics.SetColor(0, 0, 0, 200)
    local shadowHeight = self.height * (1 - self.coolDownProgress)
    _Graphics.DrawRect(0, self.height * self.coolDownProgress, self.width, shadowHeight, "fill")

    -- 还原绘图数据
    _Graphics.SetCanvas()
    _Graphics.SetColor(originColorR, originColorG, originColorB, originColorA)

    self.coolDownShadowSprite:SetImage(canvas)
    self.coolDownShadowSprite:AdjustDimensions()
end

return ArticleViewItem
