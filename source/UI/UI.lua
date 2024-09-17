--[[
	desc: UI, game's user interface.
	author: keke <243768648@qq.com>
	since: 2022-10-25
	alter: 2022-10-25
]]
--

local WindowManager = require("UI.WindowManager")
local PushButton = require("UI.PushButton")
local Window = require("UI.Window")
local StartGameWindow = require("UI.StartGame.StartGameWindow")
local Label = require("UI.Label")
local ComboBox = require("UI.ComboBox")
local SkillDockViewFrame = require("UI.SkillDockViewFrame")
local HoveringSkillItemTipWidget = require("UI.hovering_skill_item_tip_widget")
local RoleInfoWidget = require("UI.role_info.role_info_widget")
local SkillManagementWidget = require("UI.SkillManagement.SkillManagementWidget")
local SettingsWidget = require("UI.Settings.SettingsWidget")
local Widget = require("UI.Widget")
local ArticleViewItem = require("UI.role_info.article_view_item")
local HoveringArticleItemTipWidget = require("UI.role_info.hovering_article_item_tip_widget")
local Common = require("UI.ui_common")
local UiModel = require("UI.ui_model")
local HpRectBar = require("UI.hp_rect_bar")
local DirKeyGroupWidget = require("UI.TouchComponents.DirKeyGroupWidget")
local ItemKeyGroup = require("UI.TouchComponents.ItemKeyGroup")
local ArticleDockFrame = require("UI.ArticleDockFrame")

local Map = require("map.init")

local _Sprite = require("graphics.drawable.sprite")
local _Graphics = require("lib.graphics")

local Util = require("util.Util")
local _TIME = require("lib.time")
local System = require("lib.system")
local Keyboard = require("lib.keyboard")
local ResourceLib = require("lib.resource")
local MusicLib = require("lib.music")
local TableLib = require("lib.table")

local IsShowFps = true

---@class UI
local UI = {}

---@param director DIRECTOR
function UI.Init(director)
    WindowManager.Init()

    -- 统一显示对象
    UI.totalSprite = _Sprite.New()
    UI.totalSpriteCanvas = _Graphics.NewCanvas(Util.GetWindowWidth(), Util.GetWindowHeight())

    UI.gameState = Common.GameState.ActorSelect
    -- model
    UI.model = UiModel.New(director)

    -- 创建悬浮提示窗口
    local toolTipWindow = Window.New()
    toolTipWindow:SetIsTipToolWindow(true)

    ---@type StartGameWindow
    UI.startGameWindow = StartGameWindow.New(UI.model)
    UI.appendWindowWidget(UI.startGameWindow, UI.startGameWindow)

    -- 角色概况
    local bottomWindow = Window.New()
    UI.bottomWindow = bottomWindow
    bottomWindow:SetSize(Util.GetWindowWidth(), Util.GetWindowHeight())
    UI.characterTopBtn = PushButton.New(bottomWindow)
    UI.characterTopBtn:SetSize(60 * Util.GetWindowSizeScale(), 60 * Util.GetWindowSizeScale())
    UI.characterTopBtn:SetContentsMargins(5, 5, 5, 5)
    UI.characterTopBtn:SetPosition(10, 10)
    UI.characterTopBtn:SetBgSpriteDataPath("ui/WindowFrame/charactor_top_window")
    UI.characterTopBtn:SetNormalSpriteDataPath("ui/CharacterPortraits/Swordsman/Normal")
    UI.characterTopBtn:SetHoveringSpriteDataPath("ui/CharacterPortraits/Swordsman/Hovering")
    UI.characterTopBtn:SetPressingSpriteDataPath("ui/CharacterPortraits/Swordsman/Pressing")
    UI.characterTopBtn:SetDisabledSpriteDataPath("ui/CharacterPortraits/Swordsman/Normal")
    -- 将组件添加到窗口组件列表
    UI.appendWindowWidget(bottomWindow, UI.characterTopBtn)

    --- 右下角 按钮区
    local rightDownBtnAreaSpace = 5 * Util.GetWindowSizeScale()
    local rightDownBtnAreaBtnWidth = 25 * Util.GetWindowSizeScale()
    -- 设置窗口按钮
    UI.settingsBtn = PushButton.New(bottomWindow)
    UI.settingsBtn:SetSize(rightDownBtnAreaBtnWidth, rightDownBtnAreaBtnWidth)
    UI.settingsBtn:SetPosition(Util.GetWindowWidth() - 10 * Util.GetWindowSizeScale() - rightDownBtnAreaBtnWidth,
        Util.GetWindowHeight() - 10 * Util.GetWindowSizeScale() - rightDownBtnAreaBtnWidth)
    UI.settingsBtn:SetNormalSpriteDataPath("ui/PushButton/Settings/Normal")
    UI.settingsBtn:SetHoveringSpriteDataPath("ui/PushButton/Settings/Hovering")
    UI.settingsBtn:SetPressingSpriteDataPath("ui/PushButton/Settings/Pressing")
    UI.settingsBtn:SetDisabledSpriteDataPath("ui/PushButton/Settings/Disabled")
    -- 将组件添加到窗口组件列表
    UI.appendWindowWidget(bottomWindow, UI.settingsBtn)

    -- 技能管理窗口按钮
    UI.skillManagementBtn = PushButton.New(bottomWindow)
    UI.skillManagementBtn:SetSize(rightDownBtnAreaBtnWidth, rightDownBtnAreaBtnWidth)
    local settingsBtnXPos, settingsBtnYPos = UI.settingsBtn:GetPosition()
    UI.skillManagementBtn:SetPosition(settingsBtnXPos - rightDownBtnAreaSpace * Util.GetWindowSizeScale() - rightDownBtnAreaBtnWidth,
        settingsBtnYPos)
    UI.skillManagementBtn:SetNormalSpriteDataPath("ui/PushButton/SkillManagement/Normal")
    UI.skillManagementBtn:SetHoveringSpriteDataPath("ui/PushButton/SkillManagement/Hovering")
    UI.skillManagementBtn:SetPressingSpriteDataPath("ui/PushButton/SkillManagement/Pressing")
    UI.skillManagementBtn:SetDisabledSpriteDataPath("ui/PushButton/SkillManagement/Disabled")
    -- 将组件添加到窗口组件列表
    UI.appendWindowWidget(bottomWindow, UI.skillManagementBtn)


    -- characterInfoWindow
    UI.characterInfoWindow = Window.New()
    UI.characterInfoWindow:SetSize(977 * Util.GetWindowSizeScale(),
        622 * Util.GetWindowSizeScale())
    local characterInfoWindowWidth, characterInfoWindowHeight = UI.characterInfoWindow:GetSize()
    local characterInfoWindowOriginXPos = (Util.GetWindowWidth() - characterInfoWindowWidth) / 2
    local characterInfoWindowOriginYPos = (Util.GetWindowHeight() - characterInfoWindowHeight) / 2
    UI.characterInfoWindow:SetPosition(characterInfoWindowOriginXPos, characterInfoWindowOriginYPos)
    UI.characterInfoWindow:SetVisible(false)

    UI.roleInfoWidget = RoleInfoWidget.New(UI.characterInfoWindow, UI.model)
    UI.characterInfoWindow:SetContentWidget(UI.roleInfoWidget)
    -- 将组件添加到窗口组件列表
    UI.appendWindowWidget(UI.characterInfoWindow, UI.characterInfoWindow)

    -- skillManagementWindow
    UI.skillManagementWindow = Window.New()
    UI.skillManagementWindow:SetSize(977 * Util.GetWindowSizeScale(),
        622 * Util.GetWindowSizeScale())
    UI.skillManagementWindow:SetPosition(characterInfoWindowOriginXPos + 10, characterInfoWindowOriginYPos + 10)
    UI.skillManagementWindow:SetVisible(false)

    UI.skillManagementWidget = SkillManagementWidget.New(UI.skillManagementWindow, UI.model)
    UI.skillManagementWindow:SetContentWidget(UI.skillManagementWidget)
    -- 将组件添加到窗口组件列表
    UI.appendWindowWidget(UI.skillManagementWindow, UI.skillManagementWindow)

    -- settingsWindow
    UI.settingsWindow = Window.New()
    UI.settingsWindow:SetSize(977 * Util.GetWindowSizeScale(),
        622 * Util.GetWindowSizeScale())
    UI.settingsWindow:SetPosition(characterInfoWindowOriginXPos + 20, characterInfoWindowOriginYPos + 20)
    UI.settingsWindow:SetVisible(false)
    UI.settingsWindow:SetTitleBarIsBackgroundVisible(false)

    UI.settingWidget = SettingsWidget.New(UI.settingsWindow, UI.model)
    UI.settingsWindow:SetContentWidget(UI.settingWidget)
    UI.appendWindowWidget(UI.settingsWindow, UI.settingsWindow)

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
    UI.hpRectBar:SetSize(400 * Util.GetWindowSizeScale(), 15 * Util.GetWindowSizeScale())
    UI.hpRectBar:SetPosition(Util.GetWindowWidth() / 2 - 130 * Util.GetWindowSizeScale(), 10 * Util.GetWindowSizeScale())
    UI.appendWindowWidget(bottomWindow, UI.hpRectBar)

    -- hit enemy hp bar
    UI.hitEnemyHpRectBar = HpRectBar.New(bottomWindow)
    UI.hitEnemyHpRectBar:SetRightLabelVisible(false)
    UI.hitEnemyHpRectBar:SetSize(500 * Util.GetWindowSizeScale(), 22 * Util.GetWindowSizeScale())
    UI.hitEnemyHpRectBar:SetPosition(Util.GetWindowWidth() / 2 - 220 * Util.GetWindowSizeScale(),
        35 * Util.GetWindowSizeScale())
    UI.appendWindowWidget(bottomWindow, UI.hitEnemyHpRectBar)
    UI.hitEnemyHpRectBar:SetVisible(false)

    -- partner hp bar
    ---@type table<number, HpRectBar>
    UI.partnerHpRectBarList = {}
    local partnerHpRectBarHeight = 15 * Util.GetWindowSizeScale()
    local partnerHpRectBarSpace = 8 * Util.GetWindowSizeScale()
    local partnerHpRectBarYPos = 200 * Util.GetWindowSizeScale()
    for i = 1, UI.model:GetPartnerCount() do
        local hpRectBar = HpRectBar.New(bottomWindow)
        hpRectBar:SetRightLabelVisible(false)
        hpRectBar:SetSize(150 * Util.GetWindowSizeScale(), partnerHpRectBarHeight)
        hpRectBar:SetPosition(15 * Util.GetWindowSizeScale(),
            partnerHpRectBarYPos + (i - 1) * (partnerHpRectBarHeight + partnerHpRectBarSpace))
        hpRectBar:SetText("伙伴" .. tostring(i))
        hpRectBar:SetMaxHp(UI.model:GetOnePartnerAttribute(i, Common.ActorAttributeType.MaxHp))

        UI.appendWindowWidget(bottomWindow, hpRectBar)

        UI.partnerHpRectBarList[i] = hpRectBar
    end

    -- mapSelectComboBox
    UI.mapSelectComboBox = ComboBox.New(bottomWindow)
    UI.mapSelectComboBox:SetSize(200, 45)
    UI.mapSelectComboBox:SetPosition(Util.GetWindowWidth() - 210, 10)
    -- 将组件添加到窗口组件列表
    UI.appendWindowWidget(bottomWindow, UI.mapSelectComboBox)

    -- load Map Simple Path List
    for _, simplePath in pairs(UI.model:GetMapSimplePathList()) do
        UI.mapSelectComboBox:AppendItemWithText(simplePath)
    end

    -- article dock
    UI.articleDockFrame = ArticleDockFrame.New(bottomWindow, UI.model)
    -- 将组件添加到窗口组件列表
    UI.appendWindowWidget(bottomWindow, UI.articleDockFrame)

    -- skill dock
    UI.skillDockViewFrame = SkillDockViewFrame.New(bottomWindow, UI.model)
    -- 将组件添加到窗口组件列表
    UI.appendWindowWidget(bottomWindow, UI.skillDockViewFrame)

    -- 将 物品托盘 和 技能托盘 水平居中放到窗口底部
    local articleDockFrameWidth, articleDockFrameHeight = UI.articleDockFrame:GetSize()
    local skillDockViewFrameWidth, skillDockViewFrameHeight = UI.skillDockViewFrame:GetSize()
    local adfSdfSpace = 10 * Util.GetWindowSizeScale()
    UI.articleDockFrame:SetPosition((Util.GetWindowWidth() - articleDockFrameWidth - skillDockViewFrameWidth - adfSdfSpace) / 2,
        Util.GetWindowHeight() - articleDockFrameHeight - 10)
    UI.skillDockViewFrame:SetPosition((Util.GetWindowWidth() + articleDockFrameWidth + adfSdfSpace - skillDockViewFrameWidth) / 2,
        Util.GetWindowHeight() - skillDockViewFrameHeight - 10)

    --
    UI.bossDirectionTipLabel = Label.New(bottomWindow)
    UI.bossDirectionTipLabel:SetSize(300 * Util.GetWindowSizeScale(), 70 * Util.GetWindowSizeScale())
    local bossDirectionTipLabelWidth, bossDirectionTipLabelHeight = UI.bossDirectionTipLabel:GetSize()
    local bossDirectionTipLabelOriginXPos = Util.GetWindowWidth() - bossDirectionTipLabelWidth - 50 * Util.GetWindowSizeScale()
    local bossDirectionTipLabelOriginYPos = (Util.GetWindowHeight() - bossDirectionTipLabelHeight) / 2 - 150 * Util.GetWindowSizeScale()
    UI.bossDirectionTipLabel:SetPosition(bossDirectionTipLabelOriginXPos, bossDirectionTipLabelOriginYPos)
    UI.appendWindowWidget(bottomWindow, UI.bossDirectionTipLabel)

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
    UI.itemKeyGroup = ItemKeyGroup.New(bottomWindow, UI.model)
    UI.appendWindowWidget(bottomWindow, UI.itemKeyGroup)

    -- 玩家角色复活对话框
    UI.playerRebornDialog = Window.New()
    UI.playerRebornDialog:SetSize(350, 200)
    UI.playerRebornDialog:SetIsTipToolWindow(true)
    UI.playerRebornDialog:SetTitleBarVisible(false)
    UI.playerRebornDialog:SetPosition(Util.GetWindowWidth() / 2 - 175, Util.GetWindowHeight() / 2 - 100)
    UI.playerRebornDialog:SetVisible(false)

    UI.playerRebornDialogContent = Label.New(UI.playerRebornDialog)
    UI.playerRebornDialog:SetContentWidget(UI.playerRebornDialogContent)
    UI.appendWindowWidget(UI.playerRebornDialog, UI.playerRebornDialog)

    ---- connect
    -- StartGameWindow
    UI.startGameWindow:MocConnectSignal(StartGameWindow.Signal_GameStarted, UI)
    -- characterTopBtn
    UI.characterTopBtn:MocConnectSignal(UI.characterTopBtn.Signal_BtnClicked, UI)
    -- skillManagementBtn
    UI.skillManagementBtn:MocConnectSignal(UI.skillManagementBtn.Signal_BtnClicked, UI)
    -- settingsBtn
    UI.settingsBtn:MocConnectSignal(UI.settingsBtn.Signal_BtnClicked, UI)
    -- mapSelectComboBox
    UI.mapSelectComboBox:MocConnectSignal(UI.mapSelectComboBox.Signal_SelectedItemChanged, UI)
    -- model
    UI.model:MocConnectSignal(UI.model.RequestSetArticleTableItemInfo, UI)
    UI.model:MocConnectSignal(UI.model.Signal_requestSetArticleDockItemInfo, UI)
    UI.model:MocConnectSignal(UI.model.RequestSetEquTableItemInfo, UI)
    UI.model:MocConnectSignal(UI.model.RequestSetDraggingItemVisibility, UI)
    UI.model:MocConnectSignal(UI.model.RequestSetDraggingItemInfo, UI)
    UI.model:MocConnectSignal(UI.model.RequestMoveDraggingItem, UI)
    UI.model:MocConnectSignal(UI.model.Signal_EnemyCleared, UI)
    UI.model:MocConnectSignal(UI.model.Signal_EnemyAppeared, UI)
    UI.model:MocConnectSignal(UI.model.Signal_PlayerHitEnemy, UI)
    -- model - hoveringArticleItemTipWindow
    UI.model:MocConnectSignal(UI.model.RequestSetHoveringArticleItemTipWindowVisibility, UI)
    UI.model:MocConnectSignal(UI.model.RequestSetHoveringArticleItemTipWindowPosAndInfo, UI)
    -- model - hoveringSkillItemTipWindow
    UI.model:MocConnectSignal(UI.model.RequestSetHoveringSkillItemTipWindowVisibility, UI)
    UI.model:MocConnectSignal(UI.model.RequestSetHoveringSkillItemTipWindowPosAndInfo, UI)
    
    UI.model:MocConnectSignal(UI.model.Signal_PlayerDestroyed, UI)
    UI.model:MocConnectSignal(UI.model.Signal_PlayerReborn, UI)

    --- post init
    UI.updateWindowVisibilityByGameState()

    -- 首次显示前，排序所有窗口
    WindowManager.SortWindowList()
end

function UI.Update(dt)
    UI.keyboardEvent()

    if IsShowFps then
        UI.fpsLabel:SetText("fps: " .. tostring(_TIME.GetFPS()))
    end

    UI.updateAllHpRectBar()

    -- 更新所有控件
    local windowWidgetList = WindowManager.GetWindowWidgetList()
    -- 使用浅拷贝的原因：在窗口更新的过程中，可能会重新排序窗管的窗口控件列表（windowWidgetList），
    -- 此时使用窗管的窗口控件列表进行更新，会使更新紊乱（更新过的，排序到列表后面，造成重复更新）
    windowWidgetList = TableLib.LightClone(windowWidgetList)
    for _, windowWidget in pairs(windowWidgetList) do
        if windowWidget.Window:IsVisible() then
            windowWidget.Widget:Update(dt)
        end
    end

    -- UI.mergeTotalSprite()
end

function UI.Draw()
    -- UI.totalSprite:Draw()
    local windowWidgetList = WindowManager.GetWindowWidgetList()
    for _, windowWidget in pairs(windowWidgetList) do
        if windowWidget.Window:IsVisible() then
            windowWidget.Widget:Draw()
        end
    end
end

--- public function

--- 获取玩家实例配置简化路径
function UI.GetPlayerInstanceCfgSimplePath()
    return UI.model:GetPlayerInstanceCfgSimplePath()
end

--- slots

---@param my Obj 对象自身，这里指UI自身
---@param sender Obj 被电击的按钮对象
function UI.Slot_GameStarted(my, sender)
    if UI.startGameWindow == sender then
        UI.gameState = Common.GameState.Started
        UI.updateWindowVisibilityByGameState()
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
    if (UI.skillManagementBtn == sender) then
        local isVisible = UI.skillManagementWindow:IsVisible()
        UI.skillManagementWindow:SetVisible(not isVisible)
        WindowManager.SetWindowToTopLayer(UI.skillManagementWindow)
    end
    if (UI.settingsBtn == sender) then
        local isVisible = UI.settingsWindow:IsVisible()
        UI.settingsWindow:SetVisible(not isVisible)
        WindowManager.SetWindowToTopLayer(UI.settingsWindow)
    end
end

---@param my Obj 对象自身，这里指UI自身
---@param sender Obj 调用者
---@param item StandardItem
function UI.Slot_SelectedItemChanged(my, sender, item)
    if UI.mapSelectComboBox == sender then
        print("UI.Slot_SelectedItemChanged()", item:GetIndex(), item:GetText())
        UI.model:SelectGameMap(item:GetIndex())
    end
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

--- 当请求去设置物品托盘某一显示项的信息
---@param my Object
---@param sender Object
---@param index number
---@param itemInfo ArticleInfo
function UI.Slot_requestSetArticleDockItemInfo(my, sender, index, itemInfo)
    if sender == UI.model then
        print("UI.Slot_requestSetArticleDockItemInfo(my, sender, index, itemInfo)", index, itemInfo.name)
        UI.articleDockFrame:SetIndexItemInfo(index, itemInfo)
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

function UI.Slot_EnemyCleared()
    local dirStr = UI.model:GetBossRoomDirection()
    local dirTranStr = ""
    if dirStr == Map.DirectionStruct.Up then
        dirTranStr = "上"
    elseif dirStr == Map.DirectionStruct.Down then
        dirTranStr = "下"
    elseif dirStr == Map.DirectionStruct.Left then
        dirTranStr = "左"
    elseif dirStr == Map.DirectionStruct.Right then
        dirTranStr = "右"
    end
    UI.bossDirectionTipLabel:SetVisible(true)
    UI.bossDirectionTipLabel:SetText("感受到来自于 " .. dirTranStr .. " 方的领主气息...")
end

function UI.Slot_EnemyAppeared()
    UI.bossDirectionTipLabel:SetVisible(false)
end

---@param my obj
---@param sender obj
---@param attack Actor.Gear.Attack | Core.Gear
---@param hitEntity Actor.Entity
function UI.Slot_PlayerHitEnemy(my, sender, attack, hitEntity)
    if sender ~= UI.model then
        return
    end

    UI.hitEnemyHpRectBar:SetText(UI.model:GetHitEnemyName())
    UI.hitEnemyHpRectBar:SetMaxHp(UI.model:GetHitEnemyMaxHp())
    UI.hitEnemyHpRectBar:SetVisible(true)
end

---@param my obj
---@param sender obj
function UI.Slot_PlayerDestroyed(my, sender)
    if sender ~= UI.model then
        return
    end

    local rebornCoinCount = UI.model:GetPlayerRebornCoinCount()
    local rebornCoinCountStr = tostring(rebornCoinCount)
    UI.playerRebornDialogContent:SetText("剩余复活次数：" .. rebornCoinCountStr .. "\n\n" .. "请按下【攻击键】复活角色")
    UI.playerRebornDialog:SetVisible(true)
end

---@param my obj
---@param sender obj
function UI.Slot_PlayerReborn(my, sender)
    if sender ~= UI.model then
        return
    end

    UI.playerRebornDialog:SetVisible(false)
end

--- private function

---
---@param window Window
---@param widget Widget
function UI.appendWindowWidget(window, widget)
    -- 将组件添加到窗口组件列表
    WindowManager.AppendWindowWidget(window, widget)
end

function UI.mergeTotalSprite()
    _Graphics.SaveCanvas()
    _Graphics.SetCanvas(UI.totalSpriteCanvas)
    _Graphics.Clear()
    
    local txtR, txtG, txtB, txtA
    txtR = 255; txtG = 255; txtB = 255; txtA = 255
    _Graphics.SetColor(txtR, txtG, txtB, txtA)

    local windowWidgetList = WindowManager.GetWindowWidgetList()
    for _, windowWidget in pairs(windowWidgetList) do
        windowWidget.Widget:Draw()
    end
    UI.totalSprite:SetImage(UI.totalSpriteCanvas)
    
    -- 还原绘图数据
    _Graphics.RestoreCanvas()
end

function UI.keyboardEvent()
    --- esc
    if (Keyboard.IsPressed("escape")) then
        UI.characterInfoWindow:SetVisible(false)
        UI.skillManagementWindow:SetVisible(false)
        UI.settingsWindow:SetVisible(false)
    end

    --- 判断物品托盘快捷键
    local rightKeyClickedArticleDockIndex = -1
    if (Keyboard.IsPressed("1")) then
        rightKeyClickedArticleDockIndex = 1
    end
    if (Keyboard.IsPressed("2")) then
        rightKeyClickedArticleDockIndex = 2
    end
    if (Keyboard.IsPressed("3")) then
        rightKeyClickedArticleDockIndex = 3
    end
    if (Keyboard.IsPressed("4")) then
        rightKeyClickedArticleDockIndex = 4
    end
    if (Keyboard.IsPressed("5")) then
        rightKeyClickedArticleDockIndex = 5
    end
    if (Keyboard.IsPressed("6")) then
        rightKeyClickedArticleDockIndex = 6
    end
    if (-1 ~= rightKeyClickedArticleDockIndex) then
        UI.model:OnRightKeyClickedArticleDockItem(rightKeyClickedArticleDockIndex)
    end

    -- 复活
    if (not UI.model:IsPlayerAlive() and
            UI.model:IsPressedPlayerKey(Common.InputKeyValueStruct.NormalAttack)
        ) then
        UI.model:RebornPlayer()
    end
end

function UI.updateWindowVisibilityByGameState()
    UI.startGameWindow:SetVisible(false)
    UI.bottomWindow:SetVisible(false)
    UI.characterInfoWindow:SetVisible(false)
    UI.skillManagementWindow:SetVisible(false)

    if UI.gameState == Common.GameState.ActorSelect then
        UI.startGameWindow:SetVisible(true)
    end
    if UI.gameState == Common.GameState.Started then
        UI.bottomWindow:SetVisible(true)

        if (System.IsMobile()) then
            UI.skillDockViewFrame:SetVisible(false)
            UI.articleDockFrame:SetVisible(false)
        else
            UI.dirKeyGroupWidget:SetVisible(false)
            UI.itemKeyGroup:SetVisible(false)
        end
    end
end

function UI.updateAllHpRectBar()
    if nil == UI.model:GetPlayer() then
        return
    end

    UI.hpRectBar:SetHp(UI.model:GetPlayerAttribute(Common.ActorAttributeType.Hp))
    UI.hpRectBar:SetMaxHp(UI.model:GetPlayerAttribute(Common.ActorAttributeType.MaxHp))

    local hitEnemyHp = UI.model:GetHitEnemyHp()
    if hitEnemyHp > 0 then
        UI.hitEnemyHpRectBar:SetHp(hitEnemyHp)
    else
        UI.hitEnemyHpRectBar:SetVisible(false)
    end

    -- partner
    for i, rectBar in pairs(UI.partnerHpRectBarList) do
        rectBar:SetHp(UI.model:GetOnePartnerAttribute(i, Common.ActorAttributeType.Hp))
    end
end

return UI
