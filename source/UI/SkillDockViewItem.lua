--[[
	desc: SkillDockViewItem class.
	author: keke <243768648@qq.com>
	since: 2023-3-19
	alter: 2023-3-19
]] --

local _Sprite = require("graphics.drawable.sprite")
local _Graphics = require("lib.graphics")
local Label = require("UI.Label")

---@class SkillDockViewItem
local SkillDockViewItem = require("core.class")()

---@param parentWindow Window
function SkillDockViewItem:Ctor(parentWindow)
    assert(parentWindow, "must assign parent window")
    ---@type Window
    self.parentWindow = parentWindow

    self.iconLabel = Label.New(parentWindow)
    self.coolDownShadowSprite = _Sprite.New()
    self.leftBottomKeyLabel = Label.New(parentWindow)
    self.leftBottomKeyLabel:SetAlignments({Label.AlignmentFlag.AlignLeft, Label.AlignmentFlag.AlignBottom})

    self.width = 30
    self.lastWidth = 0
    self.height = 10
    self.lastHeight = 0
    self.xPos = 0
    self.lastXPos = 0
    self.yPos = 0
    self.lastYPos = 0
    self.enable = true
    self.coolDownProgress = 1
    self.lastCoolDownProgress = 1
end

function SkillDockViewItem:Update(dt)
    if (self.lastWidth ~= self.width
        or self.lastHeight ~= self.height
        or self.lastHeight ~= self.height
        or self.lastCoolDownProgress ~= self.coolDownProgress
        )
        then
        self:updateSprite()


        self.iconLabel:SetPosition(self.xPos, self.yPos)
        self.iconLabel:SetSize(self.width, self.height)
        self.iconLabel:SetIconSize(self.width, self.height)

        self.leftBottomKeyLabel:SetPosition(self.xPos + 2, self.yPos + self.height - 30)
        self.leftBottomKeyLabel:SetSize(self.width - 2, 30)
    end


    self.iconLabel:Update(dt)

    self.leftBottomKeyLabel:Update(dt)

    self.lastXPos = self.xPos
    self.lastYPos = self.yPos
    self.lastWidth = self.width
    self.lastHeight = self.height
    self.lastIconSpriteDataPath = self.iconSpriteDataPath
    self.lastCoolDownProgress = self.coolDownProgress
end

function SkillDockViewItem:Draw()
    self.iconLabel:Draw()

    self.coolDownShadowSprite:Draw()

    self.leftBottomKeyLabel:Draw()
end

function SkillDockViewItem:SetPosition(x, y)
    self.xPos = x
    self.yPos = y
end

function SkillDockViewItem:SetSize(width, height)
    self.width = width
    self.height = height

end

function SkillDockViewItem:SetEnable(enable)
    self.enable = enable
    self.iconLabel:SetEnable(enable)
    self.leftBottomKeyLabel:SetEnable(enable)
end

---@param path string
function SkillDockViewItem:SetIconSpriteDataPath(path)
    self.iconSpriteDataPath = path
    
    if "" ~= path then
        self.iconLabel:SetIconSpriteDataPath(path)
    end
end

function SkillDockViewItem:SetCoolDownProgress(progress)
    self.coolDownProgress = progress
end

---@param key string
function SkillDockViewItem:SetKey(key)
    self.leftBottomKeyLabel:SetText(key)
end

function SkillDockViewItem:updateSprite()
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
    self.coolDownShadowSprite:SetAttri("position", self.xPos, self.yPos)
end

return SkillDockViewItem
