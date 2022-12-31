--[[
	desc: UI, game's user interface.
	author: keke <243768648@qq.com>
	since: 2022-10-25
	alter: 2022-10-25
]] --

local PushButton = require("UI.PushButton")
local Window = require("UI.Window")
local ScrollBar = require("UI.ScrollBar")
local ScrollArea = require("UI.ScrollArea")
local ListView = require("UI.ListView")
local Label = require("UI.Label")
local ComboBox = require("UI.ComboBox")

local UI = {}

function UI.Init()
    -- 角色概况
    local pushBtnWindow = Window.New()
    UI.characterTopBtn = PushButton.New(pushBtnWindow)
    UI.characterTopBtn:SetPosition(10, 10)
    UI.characterTopBtn:SetSize(80, 80)
    UI.characterTopBtn:SetContentsMargins(5, 5, 5, 5)
    UI.characterTopBtn:SetBgSpriteDataPath("ui/WindowFrame/charactor_top_window")
    UI.characterTopBtn:SetNormalSpriteDataPath("ui/CharacterPortraits/swordsman")
    UI.characterTopBtn:SetHoveringSpriteDataPath("ui/CharacterPortraits/swordsman")
    UI.characterTopBtn:SetPressingSpriteDataPath("ui/CharacterPortraits/swordsman")
    UI.characterTopBtn:SetDisabledSpriteDataPath("ui/CharacterPortraits/swordsman")

    -- button test
    UI.pushBtn = PushButton.New(pushBtnWindow)
    UI.pushBtn:SetPosition(200, 50)
    UI.pushBtn:SetText("切换qqqq地图")
    UI.pushBtn:SetSize(200, 60)

    -- window test
    UI.window = Window.New()
    UI.window:SetSize(600, 1050)
    UI.window:SetPosition(300, 150)

    -- scroll bar test
    UI.scrollBar = ScrollBar.New(pushBtnWindow)
    UI.scrollBar:SetSlideLength(200)
    UI.scrollBar:SetPosition(1000, 50)
    UI.scrollBar:SetCtrlledContentLength(700)
    UI.scrollBar:SetReceiverOfRequestMoveContent(ScrollArea.New())

    -- ListView test
    UI.listView = ListView.New(pushBtnWindow)
    UI.listView:SetSize(300, 200)
    UI.listView:SetPosition(1100, 150)

    -- Label test
    UI.label = Label.New(pushBtnWindow)
    UI.label:SetSize(100, 30)
    UI.label:SetPosition(1100, 370)
    UI.label:SetText("dfasas")

    -- comboBox test
    UI.comboBox = ComboBox.New(pushBtnWindow)
    UI.comboBox:SetSize(300, 45)
    UI.comboBox:SetPosition(1100, 400)

    -- connect
    UI.window:SetReceiverOfRequestMoveWindow(UI)
    UI.window:SetReceiverOfRequestCloseWindow(UI)
end

function UI.Update(dt)
    UI.characterTopBtn:Update(dt)

    -- button test
    UI.pushBtn:Update(dt)

    -- window test
    if UI.window then
        UI.window:Update(dt)
    end

    UI.scrollBar:Update(dt)

    -- ListView test
    UI.listView:Update(dt)

    -- Label test
    UI.label:Update(dt)

    -- comboBox test
    UI.comboBox:Update(dt)
end

function UI.Draw()
    UI.characterTopBtn:Draw()

    -- button test
    UI.pushBtn:Draw()

    -- window test
    if UI.window then
        UI.window:Draw()
    end

    UI.scrollBar:Draw()

    -- ListView test
    UI.listView:Draw()

    -- Label test
    UI.label:Draw()

    -- comboBox test
    UI.comboBox:Draw()
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
