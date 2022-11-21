--[[
	desc: UI, game's user interface.
	author: keke <243768648@qq.com>
	since: 2022-10-25
	alter: 2022-10-25
]] --

local _Sprite = require("graphics.drawable.sprite")
local _GRAPHICS = require("lib.graphics")
local _RESOURCE = require("lib.resource")
local _Mouse = require("lib.mouse")
local _Input = require("actor.service.input")

local PushButton = require("UI/PushButton")
local Window = require("UI/Window")

local CharacterTopWindowPosX = 10
local CharacterTopWindowPosY = 10

local UI = {}

UI.characterTopPortrait = _Sprite.New() -- 角色概况画像
UI.characterTopWindow = _Sprite.New() -- 角色概况窗口
UI.toolBar = _Sprite.New() -- 工具栏，包括...

function UI.Init()
    -- 角色概况画像
    local spriteData = _RESOURCE.GetSpriteData("ui/CharacterPortraits/swordsman")
    UI.characterTopPortrait:SetData(spriteData)
    UI.characterTopPortrait:SetAttri("position", CharacterTopWindowPosX, CharacterTopWindowPosY)

    -- 角色概况
    UI.characterTopWindow:SwitchRect(true) -- 使用矩形
    spriteData = _RESOURCE.GetSpriteData("ui/WindowFrame/charactor_top_window")
    UI.characterTopWindow:SetData(spriteData)
    UI.characterTopWindow:SetAttri("position", CharacterTopWindowPosX, CharacterTopWindowPosY)
    local sx, sy = UI.characterTopWindow:GetAttri("scale")
    UI.characterTopWindow:SetAttri("scale", sx, sy)

    -- post init
    local windowWidth, windowHeight = UI.characterTopWindow:GetImageDimensions()
    local portraitWidth, portraitHeight = UI.characterTopPortrait:GetImageDimensions()
    -- 画像自适应与角色概况窗口
    local portraitXScale, portraitYScale = UI.characterTopPortrait:GetAttri("scale")
    portraitXScale = (windowWidth / portraitWidth) * portraitXScale
    portraitYScale = (windowHeight / portraitHeight) * portraitYScale
    UI.characterTopPortrait:SetAttri("scale", portraitXScale, portraitYScale)

    -- button test
    local pushBtnWindow = Window.New()
    UI.pushBtn = PushButton.New(pushBtnWindow)
    UI.pushBtn:SetPosition(200, 50)
    UI.pushBtn:SetText("切换qqqq地图")
    UI.pushBtn:SetSize(100, 30)
    UI.pushBtn:SetScale(2, 2)

    -- window test
    UI.window = Window.New()
    UI.window:SetSize(600, 1050)
    UI.window:SetPosition(300, 150)

    -- connect
    UI.window:SetReceiverOfRequestMoveWindow(UI)
    UI.window:SetReceiverOfRequestCloseWindow(UI)
end

function UI.Update(dt)
    local isCharacterTopPortraitHold = false
    if _Mouse.IsHold(1) then -- 1 is the primary mouse button, 2 is the secondary mouse button and 3 is the middle button
        local mousePosX, mousePosY = _Mouse.GetPosition(1, 1)
        if UI.characterTopWindow:CheckPoint(mousePosX, mousePosY) then
            isCharacterTopPortraitHold = true
        end
    end

    if isCharacterTopPortraitHold then
        UI.characterTopPortrait:SetAttri("position", CharacterTopWindowPosX + 1, CharacterTopWindowPosY + 1)
    else
        UI.characterTopPortrait:SetAttri("position", CharacterTopWindowPosX, CharacterTopWindowPosY)
    end

    -- button test
    UI.pushBtn:Update(dt)

    -- window test
    if UI.window then
        UI.window:Update(dt)
    end
end

function UI.Draw()
    UI.characterTopPortrait:Draw()
    UI.characterTopWindow:Draw()
    UI.toolBar:Draw()

    -- button test
    UI.pushBtn:Draw()

    -- window test
    if UI.window then
        UI.window:Draw()
    end
end

function UI.OnRequestMoveWindow(sender, x, y)
    if UI.window == sender then
        UI.window:SetPosition(x, y)
    end
end

function UI.OnRequestCloseWindow(sender)
    if UI.window == sender then
        UI.window = nil
    end
end

return UI
