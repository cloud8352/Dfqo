--[[
	desc: UI, game's user interface.
	author: keke <243768648@qq.com>
	since: 2022-10-25
	alter: 2022-10-25
]]--

local _Sprite = require("graphics.drawable.sprite")
local _GRAPHICS = require("lib.graphics")
local _RESOURCE = require("lib.resource")
local _Mouse= require("lib.mouse")
local _Input = require("actor.service.input")

local PushButton = require("ui/pushbutton")
local Window = require("ui/window")

local CharactorTopWindowPosX = 10
local CharactorTopWindowPosY = 10

local UI = {}

UI.charactorTopPortrait = _Sprite.New() -- 角色概况画像
-- UI.charactorTopPortraitPressed = _Sprite.New() -- 角色概况画像(点击中)
UI.charactorTopWindow = _Sprite.New() -- 角色概况窗口
UI.toolBar = _Sprite.New() -- 工具栏，包括...

function UI.Init()
    -- 角色概况画像
    local spriteData = _RESOURCE.GetSpriteData("ui/CharacterPortraits/swordman")
    UI.charactorTopPortrait:SetData(spriteData)
    UI.charactorTopPortrait:SetAttri("position", CharactorTopWindowPosX, CharactorTopWindowPosY)

    -- 角色概况
    UI.charactorTopWindow:SwitchRect(true) -- 使用矩形
    spriteData = _RESOURCE.GetSpriteData("ui/WindowFrame/charactor_top_window")
    UI.charactorTopWindow:SetData(spriteData)
    UI.charactorTopWindow:SetAttri("position", CharactorTopWindowPosX, CharactorTopWindowPosY)
    local sx, sy = UI.charactorTopWindow:GetAttri("scale")
    UI.charactorTopWindow:SetAttri("scale", sx, sy)
    -- UI.charactorTopWindow:Draw()

    -- post init
    local windowWidth, windowHeight = UI.charactorTopWindow:GetImageDimensions()
    local portraitWidth, portraitHeight = UI.charactorTopPortrait:GetImageDimensions()
    -- 画像自适应与角色概况窗口
    local portraitXScale, portraitYScale = UI.charactorTopPortrait:GetAttri("scale")
    portraitXScale = (windowWidth / portraitWidth) * portraitXScale
    portraitYScale = (windowHeight / portraitHeight) * portraitYScale
    UI.charactorTopPortrait:SetAttri("scale", portraitXScale, portraitYScale)

    -- button test
    UI.pushBtn = PushButton.New()
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
    local isCharactorTopPortraitHold = false
    if _Mouse.IsHold(1) then -- 1 is the primary mouse button, 2 is the secondary mouse button and 3 is the middle button
        local mousePosX, mousePosY = _Mouse.GetPosition(1, 1)
        if UI.charactorTopWindow:CheckPoint(mousePosX, mousePosY) then
            isCharactorTopPortraitHold = true
        end
    end

    if isCharactorTopPortraitHold then
        UI.charactorTopPortrait:SetAttri("position", CharactorTopWindowPosX + 1, CharactorTopWindowPosY + 1)
    else
        UI.charactorTopPortrait:SetAttri("position", CharactorTopWindowPosX, CharactorTopWindowPosY)
    end

    -- button test
    UI.pushBtn:Update(dt)

    -- window test
    if UI.window then
        UI.window:Update(dt)
    end
end

function UI.Draw()
    UI.charactorTopPortrait:Draw()
    UI.charactorTopWindow:Draw()
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