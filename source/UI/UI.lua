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
local DockSkillViewItem = require("UI.DockSkillViewItem")

local _MAP = require("map.init")

local Util = require("source.util.Util")

local UI = {}

function UI.Init()
    -- 角色概况
    local pushBtnWindow = Window.New()
    UI.characterTopBtn = PushButton.New(pushBtnWindow)
    UI.characterTopBtn:SetPosition(10, 10)
    UI.characterTopBtn:SetSize(80, 80)
    UI.characterTopBtn:SetContentsMargins(5, 5, 5, 5)
    UI.characterTopBtn:SetBgSpriteDataPath("ui/WindowFrame/charactor_top_window")
    UI.characterTopBtn:SetNormalSpriteDataPath("ui/CharacterPortraits/Swordsman/Normal")
    UI.characterTopBtn:SetHoveringSpriteDataPath("ui/CharacterPortraits/Swordsman/Hovering")
    UI.characterTopBtn:SetPressingSpriteDataPath("ui/CharacterPortraits/Swordsman/Pressing")
    UI.characterTopBtn:SetDisabledSpriteDataPath("ui/CharacterPortraits/Swordsman/Normal")

    -- characterInfoWindow
    UI.characterInfoWindow = Window.New()
    UI.characterInfoWindow:SetSize(450, 700)
    UI.characterInfoWindow:SetPosition(520, 70)
    UI.characterInfoWindow:SetVisible(false)

    -- comboBox test
    UI.mapSelectComboBox = ComboBox.New(pushBtnWindow)
    UI.mapSelectComboBox:SetSize(300, 45)
    UI.mapSelectComboBox:SetPosition(1100, 70)

    UI.mapSelectComboBox:AppendItem("格兰")
    UI.mapSelectComboBox:AppendItem("极昼")

    -- skill icon
    ---@type table<string, DockSkillViewItem>
    UI.mapOfTagToSkillIconLabel = {}
    local skillIconLabel = DockSkillViewItem:New(pushBtnWindow)
    skillIconLabel:SetSize(50, 50)
    skillIconLabel:SetPosition(100, Util.GetWindowHeight() - 70)
    -- skillIconLabel:SetIconSpriteDataPath("ui/CharacterPortraits/Swordsman/Normal")
    UI.mapOfTagToSkillIconLabel["skill1"] = skillIconLabel

    skillIconLabel = DockSkillViewItem:New(pushBtnWindow)
    skillIconLabel:SetSize(50, 50)
    skillIconLabel:SetPosition(100 + 60, Util.GetWindowHeight() - 70)
    -- skillIconLabel:SetIconSpriteDataPath("ui/CharacterPortraits/Swordsman/Normal")
    UI.mapOfTagToSkillIconLabel["skill2"] = skillIconLabel

    skillIconLabel = DockSkillViewItem:New(pushBtnWindow)
    skillIconLabel:SetSize(50, 50)
    skillIconLabel:SetPosition(100 + 120, Util.GetWindowHeight() - 70)
    -- skillIconLabel:SetIconSpriteDataPath("ui/CharacterPortraits/Swordsman/Normal")
    UI.mapOfTagToSkillIconLabel["skill3"] = skillIconLabel

    skillIconLabel = DockSkillViewItem:New(pushBtnWindow)
    skillIconLabel:SetSize(50, 50)
    skillIconLabel:SetPosition(100 + 180, Util.GetWindowHeight() - 70)
    -- skillIconLabel:SetIconSpriteDataPath("ui/CharacterPortraits/Swordsman/Normal")
    UI.mapOfTagToSkillIconLabel["skill4"] = skillIconLabel

    skillIconLabel = DockSkillViewItem:New(pushBtnWindow)
    skillIconLabel:SetSize(50, 50)
    skillIconLabel:SetPosition(100 + 240, Util.GetWindowHeight() - 70)
    -- skillIconLabel:SetIconSpriteDataPath("ui/CharacterPortraits/Swordsman/Normal")
    UI.mapOfTagToSkillIconLabel["skill5"] = skillIconLabel

    skillIconLabel = DockSkillViewItem:New(pushBtnWindow)
    skillIconLabel:SetSize(50, 50)
    skillIconLabel:SetPosition(100 + 300, Util.GetWindowHeight() - 70)
    -- skillIconLabel:SetIconSpriteDataPath("ui/CharacterPortraits/Swordsman/Normal")
    UI.mapOfTagToSkillIconLabel["skill6"] = skillIconLabel

    ---- connect
    -- characterTopBtn
    UI.characterTopBtn:SetReceiverOfBtnClicked(UI)
    -- characterInfoWindow
    UI.characterInfoWindow:SetReceiverOfRequestMoveWindow(UI)
    UI.characterInfoWindow:SetReceiverOfRequestCloseWindow(UI)
    -- mapSelectComboBox
    UI.mapSelectComboBox:SetReceiverOfSelectedItemChanged(UI)
end

function UI.Update(dt)
    UI.characterTopBtn:Update(dt)

    -- characterInfoWindow
    UI.characterInfoWindow:Update(dt)

    -- mapSelectComboBox
    UI.mapSelectComboBox:Update(dt)

    -- skill icon
    for k, v in pairs(UI.mapOfTagToSkillIconLabel) do
        v:Update(dt)
    end
end

function UI.Draw()
    UI.characterTopBtn:Draw()

    -- characterInfoWindow
    UI.characterInfoWindow:Draw()

    -- mapSelectComboBox
    UI.mapSelectComboBox:Draw()

    -- skill icon
    for k, v in pairs(UI.mapOfTagToSkillIconLabel) do
        v:Draw()
    end
end

---@param my Obj 对象自身，这里指UI自身
---@param sender Obj 调用者
function UI.OnBtnsClicked(my, sender)
    if UI.characterTopBtn == sender then
        local isVisible = UI.characterInfoWindow:IsVisible()
        UI.characterInfoWindow:SetVisible(not isVisible)
    end
end

function UI.OnRequestMoveWindow(sender, x, y)
    if UI.characterInfoWindow == sender then
        UI.characterInfoWindow:SetPosition(x, y)
    end
end

function UI.OnRequestCloseWindow(sender)
    if UI.characterInfoWindow == sender then
        UI.characterInfoWindow:SetVisible(false)
    end
end

---@param my Obj 对象自身，这里指UI自身
---@param sender Obj 调用者
---@param item StandardItem
function UI.OnSelectedItemChanged(my, sender, item)
    if UI.mapSelectComboBox == sender then
        print("OnSelectedItemChanged", item:GetIndex(), item:GetText())
        if 1 == item:GetIndex() then 
            _MAP.Load(_MAP.Make("lorien"))
        elseif 2 == item:GetIndex() then
            _MAP.Load(_MAP.Make("whitenight"))
        end
    end
end

---@param skillTag string
---@param iconName string
function UI.SetSkillIconName(skillTag, iconName)
    -- print("UI.SetSkillIconName", skillTag, iconName)
    local label = UI.mapOfTagToSkillIconLabel[skillTag]
    if nil == label then
        -- print("UI has not label of tag: ", skillTag)
        return
    end

    label:SetIconSpriteDataPath("icon/skill/" .. iconName)
end

---@param skillTag string
---@param progress number
function UI.SetSkillCoolDownProgress(skillTag, progress)
    local label = UI.mapOfTagToSkillIconLabel[skillTag]
    if nil == label then
        -- print("UI has not label of tag: ", skillTag)
        return
    end

    label:SetCoolDownProgress(progress)
end

return UI
