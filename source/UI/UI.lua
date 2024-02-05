--[[
	desc: UI, game's user interface.
	author: keke <243768648@qq.com>
	since: 2022-10-25
	alter: 2022-10-25
]]
--

local PushButton = require("UI.PushButton")
local Window = require("UI.Window")
local ScrollBar = require("UI.ScrollBar")
local ScrollArea = require("UI.ScrollArea")
local ListView = require("UI.ListView")
local Label = require("UI.Label")
local ComboBox = require("UI.ComboBox")
local SkillDockViewFrame = require("UI.SkillDockViewFrame")
local HoveringSkillItemTipWidget = require("UI.hovering_skill_item_tip_widget")
local RoleInfoWidget = require("UI.role_info.role_info_widget")
local Widget = require("UI.Widget")
local ArticleViewItem = require("UI.role_info.article_view_item")
local HoveringArticleItemTipWidget = require("UI.role_info.hovering_article_item_tip_widget")
local Common = require("UI.ui_common")
local UiModel = require("UI.ui_model")
local WindowManager = require("UI.WindowManager")
local HpRectBar = require("UI.hp_rect_bar")
local DirKeyGroupWidget = require("UI.TouchComponents.DirKeyGroupWidget")
local ItemKeyGroup = require("UI.TouchComponents.ItemKeyGroup")

local _TABLE = require("lib.table")
local Util = require("util.Util")
local _TIME = require("lib.time")
local System = require("lib.system")

local IsShowFps = true

---@class WindowWidgetStruct
local WindowWidgetStruct = {
    ---@type Window
    window = nil,
    ---@type Widget
    widget = nil
}

---
---@param windowWidgetA WindowWidgetStruct
---@param windowWidgetB WindowWidgetStruct
---@return boolean
local function windowWidgetListSortFuc(windowWidgetA, windowWidgetB)
    return windowWidgetA.window:GetWindowLayerIndex() < windowWidgetB.window:GetWindowLayerIndex()
end

---@class UI
local UI = {}

function UI.Init()
    UI.model = UiModel.New()

    ---@type table<number, WindowWidgetStruct>
    UI.windowWidgetList = {}

    -- 创建悬浮提示窗口
    local toolTipWindow = Window.New()
    toolTipWindow:SetIsTipToolWindow(true)

    -- 角色概况
    local bottomWindow = Window.New()
    UI.bottomWindow = bottomWindow
    bottomWindow:SetSize(Util.GetWindowWidth(), Util.GetWindowHeight())
    UI.characterTopBtn = PushButton.New(bottomWindow)
    UI.characterTopBtn:SetPosition(10, 10)
    UI.characterTopBtn:SetSize(80 * Util.GetWindowSizeScale(), 80 * Util.GetWindowSizeScale())
    UI.characterTopBtn:SetContentsMargins(5, 5, 5, 5)
    UI.characterTopBtn:SetBgSpriteDataPath("ui/WindowFrame/charactor_top_window")
    UI.characterTopBtn:SetNormalSpriteDataPath("ui/CharacterPortraits/Swordsman/Normal")
    UI.characterTopBtn:SetHoveringSpriteDataPath("ui/CharacterPortraits/Swordsman/Hovering")
    UI.characterTopBtn:SetPressingSpriteDataPath("ui/CharacterPortraits/Swordsman/Pressing")
    UI.characterTopBtn:SetDisabledSpriteDataPath("ui/CharacterPortraits/Swordsman/Normal")
    -- 将组件添加到窗口组件列表
    UI.appendWindowWidget(bottomWindow, UI.characterTopBtn)

    -- characterInfoWindow
    UI.characterInfoWindow = Window.New()
    UI.characterInfoWindow:SetSize(1040 * Util.GetWindowSizeScale(),
        670 * Util.GetWindowSizeScale())
    local characterInfoWindowWidth, _ = UI.characterInfoWindow:GetSize()
    local characterInfoWindowOriginXPos = (Util.GetWindowWidth() - characterInfoWindowWidth) / 2
    UI.characterInfoWindow:SetPosition(characterInfoWindowOriginXPos, 90)
    UI.characterInfoWindow:SetVisible(false)

    UI.roleInfoWidget = RoleInfoWidget.New(UI.characterInfoWindow, UI.model)
    UI.characterInfoWindow:SetContentWidget(UI.roleInfoWidget)
    -- 将组件添加到窗口组件列表
    UI.appendWindowWidget(UI.characterInfoWindow, UI.characterInfoWindow)

    --==== test
    -- skillManagerWindow
    -- UI.skillManagerWindow = Window.New()
    -- UI.skillManagerWindow:SetSize(1040, 670)
    -- UI.skillManagerWindow:SetPosition(200, 60)
    -- UI.skillManagerWindow:SetVisible(true)

    -- UI.skillManagerWidget = Widget.New(UI.skillManagerWindow, UI.model)
    -- UI.skillManagerWindow:SetContentWidget(UI.skillManagerWidget)
    -- 将组件添加到窗口组件列表
    -- UI.appendWindowWidget(UI.skillManagerWindow, UI.skillManagerWindow)
    --=== end - test

    -- 悬停处的物品栏提示窗口
    UI.hoveringArticleItemTipWindow = Window.New()
    UI.hoveringArticleItemTipWindow:SetSize(350, 500)
    UI.hoveringArticleItemTipWindow:SetIsTipToolWindow(true)
    UI.hoveringArticleItemTipWindow:SetTitleBarVisible(false)
    UI.hoveringArticleItemTipWindow:SetVisible(false) -- 初始时不显示提示窗口

    UI.hoveringArticleItemTipWidget = HoveringArticleItemTipWidget.New(UI.hoveringArticleItemTipWindow)
    UI.hoveringArticleItemTipWindow:SetContentWidget(UI.hoveringArticleItemTipWidget)
    UI.appendWindowWidget(UI.hoveringArticleItemTipWindow, UI.hoveringArticleItemTipWindow)

    -- 拖拽中的物品项
    UI.draggingArticleItem = ArticleViewItem.New(toolTipWindow)
    UI.draggingArticleItem:SetSize(Common.ArticleItemWidth, Common.ArticleItemWidth)
    UI.draggingArticleItem:SetVisible(false)
    -- 将组件添加到窗口组件列表
    UI.appendWindowWidget(toolTipWindow, UI.draggingArticleItem)

    if IsShowFps then
        -- fps Label
        UI.fpsLabel = Label.New(bottomWindow)
        UI.fpsLabel:SetPosition(120 * Util.GetWindowSizeScale(), 20 * Util.GetWindowSizeScale())
        UI.fpsLabel:SetSize(80 * Util.GetWindowSizeScale(), 30 * Util.GetWindowSizeScale())
        -- UI.fpsLabel:SetText(_TIME.GetFPS())
        UI.appendWindowWidget(bottomWindow, UI.fpsLabel)
    end

    -- hp bar
    UI.hpRectBar = HpRectBar.New(bottomWindow)
    UI.hpRectBar:SetSize(500 * Util.GetWindowSizeScale(), 20 * Util.GetWindowSizeScale())
    UI.hpRectBar:SetPosition(Util.GetWindowWidth() / 2 - 220 * Util.GetWindowSizeScale(), 20 * Util.GetWindowSizeScale())
    UI.appendWindowWidget(bottomWindow, UI.hpRectBar)

    -- comboBox test
    UI.mapSelectComboBox = ComboBox.New(bottomWindow)
    UI.mapSelectComboBox:SetSize(200, 45)
    UI.mapSelectComboBox:SetPosition(Util.GetWindowWidth() - 210, 10)
    -- 将组件添加到窗口组件列表
    UI.appendWindowWidget(bottomWindow, UI.mapSelectComboBox)

    UI.mapSelectComboBox:AppendItem("格兰")
    UI.mapSelectComboBox:AppendItem("极昼")

    -- skill dock
    UI.skillDockViewFrame = SkillDockViewFrame.New(bottomWindow, UI.model)
    local _, skillDockViewFrameHeight = UI.skillDockViewFrame:GetSize()
    UI.skillDockViewFrame:SetPosition(Util.GetWindowWidth() / 2 + 100,
        Util.GetWindowHeight() - skillDockViewFrameHeight - 10)
    -- 将组件添加到窗口组件列表
    UI.appendWindowWidget(bottomWindow, UI.skillDockViewFrame)

    -- skill item tip window
    UI.hoveringSkillItemTipWindow = Window.New()
    UI.hoveringSkillItemTipWindow:SetSize(350, 500)
    UI.hoveringSkillItemTipWindow:SetIsTipToolWindow(true)
    UI.hoveringSkillItemTipWindow:SetTitleBarVisible(false)
    UI.hoveringSkillItemTipWindow:SetVisible(false)

    UI.hoveringSkillItemTipWidget = HoveringSkillItemTipWidget.New(UI.hoveringSkillItemTipWindow)
    UI.hoveringSkillItemTipWindow:SetContentWidget(UI.hoveringSkillItemTipWidget)
    UI.appendWindowWidget(UI.hoveringSkillItemTipWindow, UI.hoveringSkillItemTipWindow)

    -- DirKeyGroupWidget
    UI.dirKeyGroupWidget = DirKeyGroupWidget.New(bottomWindow, UI.model)
    UI.dirKeyGroupWidget:SetPosition(150 * Util.GetWindowSizeScale(),
        Util.GetWindowHeight() - UI.dirKeyGroupWidget.baseWidget.height - 50 * Util.GetWindowSizeScale())
    UI.appendWindowWidget(bottomWindow, UI.dirKeyGroupWidget)

    -- itemKeyGroup
    UI.itemKeyGroup = ItemKeyGroup.New(bottomWindow, UI, UI.model)

    ---- connect
    -- characterTopBtn
    UI.characterTopBtn:MocConnectSignal(UI.characterTopBtn.Signal_Clicked, UI)
    -- characterInfoWindow
    UI.characterInfoWindow:SetReceiverOfRequestMoveWindow(UI)
    UI.characterInfoWindow:SetReceiverOfRequestCloseWindow(UI)
    -- mapSelectComboBox
    UI.mapSelectComboBox:SetReceiverOfSelectedItemChanged(UI)
    -- model
    UI.model:MocConnectSignal(UI.model.RequestSetArticleTableItemInfo, UI)
    UI.model:MocConnectSignal(UI.model.RequestSetEquTableItemInfo, UI)
    UI.model:MocConnectSignal(UI.model.RequestSetDraggingItemVisibility, UI)
    UI.model:MocConnectSignal(UI.model.RequestSetDraggingItemInfo, UI)
    UI.model:MocConnectSignal(UI.model.RequestMoveDraggingItem, UI)
    -- model - hoveringArticleItemTipWindow
    UI.model:MocConnectSignal(UI.model.RequestSetHoveringArticleItemTipWindowVisibility, UI)
    UI.model:MocConnectSignal(UI.model.RequestSetHoveringArticleItemTipWindowPosAndInfo, UI)
    -- model - hoveringSkillItemTipWindow
    UI.model:MocConnectSignal(UI.model.RequestSetHoveringSkillItemTipWindowVisibility, UI)
    UI.model:MocConnectSignal(UI.model.RequestSetHoveringSkillItemTipWindowPosAndInfo, UI)

    -- post init
    if (System.IsMobile()) then
        UI.skillDockViewFrame:SetVisible(false)
    else
        UI.dirKeyGroupWidget:SetVisible(false)
        UI.itemKeyGroup:SetVisible(false)
    end
end

function UI.Update(dt)
    UI.characterTopBtn:Update(dt)

    -- characterInfoWindow
    UI.characterInfoWindow:Update(dt)

    -- UI.skillManagerWindow:Update(dt)

    if IsShowFps then
        UI.fpsLabel:Update(dt)
        UI.fpsLabel:SetText("fps: " .. tostring(_TIME.GetFPS()))
    end

    UI.hpRectBar:SetHp(UI.model:GetHp())
    UI.hpRectBar:Update(dt)

    -- mapSelectComboBox
    UI.mapSelectComboBox:Update(dt)

    UI.skillDockViewFrame:Update(dt)

    UI.dirKeyGroupWidget:Update(dt)
    UI.itemKeyGroup:Update(dt)

    UI.hoveringSkillItemTipWindow:Update(dt)

    UI.hoveringArticleItemTipWindow:Update(dt)

    UI.draggingArticleItem:Update(dt)

    WindowManager.SortWindowList()
end

function UI.Draw()
    table.sort(UI.windowWidgetList, windowWidgetListSortFuc)
    for _, windowWidget in pairs(UI.windowWidgetList) do
        windowWidget.widget:Draw()
    end
end

---@param my Obj 对象自身，这里指UI自身
---@param sender PushButton 被电击的按钮对象
function UI.Slot_BtnClicked(my, sender)
    if UI.characterTopBtn == sender then
        local isVisible = UI.characterInfoWindow:IsVisible()
        UI.characterInfoWindow:SetVisible(not isVisible)
        WindowManager.SetWindowToTopLayer(UI.characterInfoWindow)
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
        UI.model:SelectGameMap(item:GetIndex())
    end
end

---@param player Actor.Entity
function UI.SetPlayer(player)
    UI.model:SetPlayer(player)

    UI.hpRectBar:SetMaxHp(UI.model:GetMaxHp())
    UI.skillDockViewFrame:ReloadSkillsViewData()

    UI.itemKeyGroup:SetPlayer(player)
end

--- 当请求去设置物品栏某一显示项的信息
---@param my Object
---@param sender Object
---@param index number
---@param itemInfo ArticleInfo
function UI.OnRequestSetArticleTableItemInfo(my, sender, index, itemInfo)
    if sender == UI.model then
        print("UI.OnRequestSetArticleTableItemInfo(my, sender, index, itemInfo)", index, itemInfo.name)
        UI.roleInfoWidget:SetArticleTableItemInfo(index, itemInfo)
    end
end

--- 当请求去设置装备栏某一显示项的信息
---@param my Object
---@param sender Object
---@param index number
---@param itemInfo ArticleInfo
function UI.OnRequestSetEquTableItemInfo(my, sender, index, itemInfo)
    if sender == UI.model then
        print("UI.OnRequestSetEquTableItemInfo(my, sender, index, itemInfo)", index, itemInfo.name)
        UI.roleInfoWidget:SetEquTableItemInfo(index, itemInfo)
    end
end

--- 当被请求去设置拖拽项为可见性
---@param my Object
---@param sender Object
---@param visible boolean
function UI.OnRequestSetDraggingItemVisibility(my, sender, visible)
    if sender == UI.model then
        UI.draggingArticleItem:SetVisible(visible)
    end
end

--- 当被请求去设置拖拽项信息
---@param my Object
---@param sender Object
---@param info ArticleInfo
function UI.OnRequestSetDraggingItemInfo(my, sender, info)
    if sender == UI.model then
        UI.draggingArticleItem:SetIconSpriteDataPath(info.iconPath)
        UI.draggingArticleItem:SetCount(info.count)
    end
end

--- 当被请求去设置移动拖拽项
---@param my Object
---@param sender Object
---@param xPos number
---@param yPos number
function UI.OnRequestMoveDraggingItem(my, sender, xPos, yPos)
    if sender == UI.model then
        UI.draggingArticleItem:SetPosition(xPos, yPos)
    end
end

function UI.OnRequestSetHoveringArticleItemTipWindowVisibility(my, sender, visible)
    if sender == UI.model then
        UI.hoveringArticleItemTipWindow:SetVisible(visible)
    end
end

function UI.OnRequestSetHoveringArticleItemTipWindowPosAndInfo(my, sender, xPos, yPos, info)
    if sender == UI.model then
        local gameWindowSizeW = Util.GetWindowWidth()
        local gameWindowSizeH = Util.GetWindowHeight()
        local hoveringItemTipWindowSizeW, hoveringItemTipWindowSizeH = UI.hoveringArticleItemTipWindow:GetSize()

        -- 如果悬浮框待设置的位置会使悬浮窗超出主程序窗口，则调整位置
        if gameWindowSizeW < xPos + hoveringItemTipWindowSizeW then
            xPos = gameWindowSizeW - hoveringItemTipWindowSizeW
        end
        if gameWindowSizeH < yPos + hoveringItemTipWindowSizeH then
            yPos = gameWindowSizeH - hoveringItemTipWindowSizeH
        end

        UI.hoveringArticleItemTipWindow:SetPosition(xPos, yPos)

        -- info
        UI.hoveringArticleItemTipWidget:SetArticleInfo(info)
    end
end

function UI.OnRequestSetHoveringSkillItemTipWindowVisibility(my, sender, visible)
    if sender == UI.model then
        UI.hoveringSkillItemTipWindow:SetVisible(visible)
    end
end

function UI.OnRequestSetHoveringSkillItemTipWindowPosAndInfo(my, sender, xPos, yPos, info)
    if sender == UI.model then
        local gameWindowSizeW = Util.GetWindowWidth()
        local gameWindowSizeH = Util.GetWindowHeight()
        local hoveringItemTipWindowSizeW, hoveringItemTipWindowSizeH = UI.hoveringSkillItemTipWindow:GetSize()

        -- 如果悬浮框待设置的位置会使悬浮窗超出主程序窗口，则调整位置
        if gameWindowSizeW < xPos + hoveringItemTipWindowSizeW then
            xPos = gameWindowSizeW - hoveringItemTipWindowSizeW
        end
        if gameWindowSizeH < yPos + hoveringItemTipWindowSizeH then
            yPos = gameWindowSizeH - hoveringItemTipWindowSizeH
        end

        UI.hoveringSkillItemTipWindow:SetPosition(xPos, yPos)

        -- info
        UI.hoveringSkillItemTipWidget:SetSkillInfo(info)
    end
end

---@param w number
---@param h number
function UI.OnWindowResize(w, h)
    UI.bottomWindow:SetSize(w, h)
end

---
---@param window Window
---@param widget Widget
function UI.appendWindowWidget(window, widget)
    -- 将组件添加到窗口组件列表
    ---@type WindowWidgetStruct
    local windowWidget = _TABLE.DeepClone(WindowWidgetStruct)
    windowWidget.window = window
    windowWidget.widget = widget
    table.insert(UI.windowWidgetList, windowWidget)
end

return UI
