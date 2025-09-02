--[[
	desc: RoleEquTableWidget class. 角色装备表格展示类
	author: keke <243768648@qq.com>
	since: 2023-6-11
	alter: 2023-6-11
]] --

local _CONFIG = require("config")
local _Mouse = require("lib.mouse")
local Timer = require("util.gear.timer")
local _TABLE = require("lib.table")
local _MATH = require("lib.math")
local _Graphics = require("lib.graphics")
local SysLib = require("lib.system")
local TouchLib = require("lib.touch")

local WindowManager = require("UI.WindowManager")
local Widget = require("UI.Widget")
local Label = require("UI.Label")
local ArticleViewItem = require("UI.role_info.article_view_item")
local Window = require("UI.Window")
local Common = require("UI.ui_common")
local UiModel = require("UI.ui_model")

local Util = require("util.Util")

---@class RoleEquTableWidget : Widget
local RoleEquTableWidget = require("core.class")(Widget)


local ItemWidth = 0
local ItemSpace = 1
local TimeOfWaitToShowItemTip = 1000 * 0.5 -- 显示技能提示信息需要等待的时间，单位：ms

---@param parentWindow Window
---@param model UiModel
function RoleEquTableWidget:Ctor(parentWindow, model)
    -- 父类构造函数
    Widget.Ctor(self, parentWindow)
    self:SetBgSpriteColor(0, 0, 0, 0)
    
    ItemWidth = Common.ArticleItemWidth * Util.GetWindowSizeScale()
    ItemWidth = math.floor(ItemWidth)

    self.model = model

    self.width = 100
    self.height = 100

    self.nameLabel = Label.New(parentWindow)
    self.nameLabel:SetText("剑士")

    self.portraitBgLabel = Label.New(parentWindow)
    self.portraitBgLabel:SetIconSpriteDataPath("ui/CharacterPortraits/chivalrousMan")

    --- item background
    local itemBgImgPath = "ui/article_view_item/article_view_item_bg"
    --- item
    local itemImgPath = ""
    ---@type talble<number, ArticleViewItem>
    self.viewItemList = {}
    for i = 1, Common.EquTypeCount do
        local item = ArticleViewItem.New(parentWindow)
        item:SetBgSpriteDataPath(itemBgImgPath)
        item:SetBgSpriteColor(255, 255, 255, 255)
        item:SetIconSpriteDataPath(itemImgPath)
        self.viewItemList[i] = item
    end

    -- hovering item frame Label
    self.hoveringItemIndex = -1
    self.lastHoveringItemIndex = -1
    self.hoveringItemFrameLabel = Label.New(parentWindow)
    self.hoveringItemFrameLabel:SetIconSpriteDataPath("ui/WindowFrame/HoveringItemFrame")
    self.hoveringItemFrameLabel:SetVisible(false)

    -- item Hovering Timer
    self.itemHoveringTimer = Timer.New()
    self.isShowHoveringItemTip = false -- 是否显示悬浮技能项的提示信息
    self.lastIsShowHoveringItemTip = false
    ---@type ArticleInfo
    self.hoveringItemInfo = nil

    -- touch
    self.timeMsToLastPressed = 0

    -- connect
    self.model:MocConnectSignal(self.model.Signal_PlayerChanged, self)

    --- post init
    self:updateData()
end

function RoleEquTableWidget:Update(dt)
    if false == self:IsVisible() then
        return
    end

    if not SysLib.IsMobile() then
        self:MouseEvent()
    else
        self:TouchEvent()
    end

    if (Widget.IsSizeChanged(self))
    then
        self:updateData()
    end

    if (self.lastHoveringItemIndex ~= self.hoveringItemIndex) then
        self:updateHoveringItemFrameData()
    end

    -- 判断定时器
    self.itemHoveringTimer:Update(dt)
    if self.itemHoveringTimer.isRunning or -1 == self.hoveringItemIndex then
        self.isShowHoveringItemTip = false
    elseif self.itemHoveringTimer.isRunning and -1 ~= self.hoveringItemIndex then
        self.isShowHoveringItemTip = false
    else
        self.isShowHoveringItemTip = true
    end
    -- 空物品不显示悬浮提示
    if self.hoveringItemInfo == nil or
        self.hoveringItemInfo.type == Common.ArticleType.Empty
    then
        self.isShowHoveringItemTip = false
    end
    -- 更新悬浮提示
    if self.lastIsShowHoveringItemTip ~= self.isShowHoveringItemTip then
        self:updateHoveringItemTipWindowData()
    end

    -- 更新到上次点击的时间
    if self.hoveringItemInfo ~= nil then
        self.timeMsToLastPressed = self.timeMsToLastPressed + dt
    end

    self.nameLabel:Update(dt)
    self.portraitBgLabel:Update(dt)

    for i, item in pairs(self.viewItemList) do
        item:Update(dt)
    end

    self.hoveringItemFrameLabel:Update(dt)


    Widget.Update(self, dt)
    --- 更新上次和当前的所有状态
    self.lastXPos = self.xPos
    self.lastYPos = self.yPos
    self.lastWidth = self.width
    self.lastHeight = self.height

    self.lastHoveringItemIndex = self.hoveringItemIndex
    self.lastIsShowHoveringItemTip = self.isShowHoveringItemTip
end

function RoleEquTableWidget:Draw()
    self.nameLabel:Draw()
    self.portraitBgLabel:Draw()

    for i, item in pairs(self.viewItemList) do
        item:Draw()
    end

    self.hoveringItemFrameLabel:Draw()
end

function RoleEquTableWidget:MouseEvent()
    -- 判断鼠标
    while true do
        -- 检查是否有上层窗口遮挡
        local windowLayerIndex = self.parentWindow:GetWindowLayerIndex()
        if WindowManager.IsMouseCapturedAboveLayer(windowLayerIndex) then
            self.hoveringItemIndex = -1
            self.hoveringItemInfo = nil
            self.itemHoveringTimer:Exit()
            break
        end

        local mousePosX, mousePosY = _Mouse.GetPosition(1, 1)
        -- 寻找鼠标悬停处的显示项标签
        local hoveringItemIndex = -1
        for i, item in pairs(self.viewItemList) do
            if item:CheckPoint(mousePosX, mousePosY) then
                hoveringItemIndex = i
                break
            end
        end

        -- 是否点击了鼠标右键
        if _Mouse.IsPressed(2) then
            if (hoveringItemIndex ~= -1) then
                self.model:OnRightKeyClickedEquTableItem(hoveringItemIndex)
            end
        end

        if hoveringItemIndex == self.hoveringItemIndex then
            break
        end

        if -1 == hoveringItemIndex then
            self.hoveringItemIndex = -1
            self.hoveringItemInfo = nil
            self.itemHoveringTimer:Exit()
        else
            self.hoveringItemIndex = hoveringItemIndex
            self.hoveringItemInfo = self.model:GetMountedEquInfoList()[hoveringItemIndex]

            -- 开启计时鼠标悬浮时间
            self.itemHoveringTimer:Enter(TimeOfWaitToShowItemTip)
        end

        break
    end
end

---@param item ArticleViewItem
---@param idList table<number, string>
---@return string id
local function getItemTouchedId(item, idList)
    for _, id in pairs(idList) do
        local point = TouchLib.GetPoint(id)
        if (item:CheckPoint(point.x, point.y)) then
            return id
        end
    end

    return ""
end

function RoleEquTableWidget:TouchEvent()
    -- 判断鼠标
    while true do
        -- 检查是否点击了其他窗口
        local capturedTouchIdList = WindowManager.GetWindowCapturedTouchIdList(self.parentWindow)
        if #capturedTouchIdList == 0 and
            TouchLib.WhetherExistHoldPoint()
        then
            self.hoveringItemIndex = -1
            self.hoveringItemInfo = nil
            self.itemHoveringTimer:Exit()
            break
        end
        if #capturedTouchIdList == 0 then
            break
        end

        -- 判断点击的显示项标签
        local hoveringItemIndex = -1
        local touchedId = ""
        for i, item in pairs(self.viewItemList) do
            touchedId = getItemTouchedId(item, capturedTouchIdList)
            if touchedId ~= "" then
                hoveringItemIndex = i
                break
            end
        end

        if hoveringItemIndex == -1 then
            self.hoveringItemIndex = -1
            self.hoveringItemInfo = nil
            self.itemHoveringTimer:Exit()
            break
        end

        local point = TouchLib.GetPoint(touchedId)
        if self.timeMsToLastPressed < 500
            and hoveringItemIndex == self.hoveringItemIndex
            and TouchLib.WhetherPointIsPressed(point)
        then
            -- 使用物品（模拟右键点击）
            self.model:OnRightKeyClickedEquTableItem(hoveringItemIndex)
        end

        if TouchLib.WhetherPointIsPressed(point) then
            self.timeMsToLastPressed = 0
        end

        if hoveringItemIndex == self.hoveringItemIndex then
            break
        end

        self.hoveringItemIndex = hoveringItemIndex
        self.hoveringItemInfo = self.model:GetMountedEquInfoList()[hoveringItemIndex]

        -- 开启计时鼠标悬浮时间
        self.itemHoveringTimer:Enter(TimeOfWaitToShowItemTip)
        break
    end
end

function RoleEquTableWidget:SetPosition(x, y)
    self.xPos = x
    self.yPos = y

    self.nameLabel:SetPosition(x, y)

    local portraitBgLabelWidth, _ = self.portraitBgLabel:GetSize()
    local portraitBgLabelXPos = x + (self.width - portraitBgLabelWidth) / 2
    self.portraitBgLabel:SetPosition(portraitBgLabelXPos, y + 0 * Util.GetWindowSizeScale())

    local suitItem = self.viewItemList[Common.EquType.Suit]
    local suitItemWidth, _ = suitItem:GetSize()
    local suitItemXPos = x + 30 * Util.GetWindowSizeScale()
    local suitItemYPos = y + 45 * Util.GetWindowSizeScale()
    suitItem:SetPosition(suitItemXPos, suitItemYPos)

    local titleItem = self.viewItemList[Common.EquType.Title]
    local titleItemWidth, _ = titleItem:GetSize()
    local titleItemXPos = suitItemXPos
    local titleItemYPos = suitItemYPos + suitItemWidth + 20 * Util.GetWindowSizeScale()
    titleItem:SetPosition(titleItemXPos, titleItemYPos)

    local capItem = self.viewItemList[Common.EquType.Cap]
    local capItemWidth, _ = capItem:GetSize()
    local capItemXPos = x + (self.width - capItemWidth) / 2 - 41 * Util.GetWindowSizeScale()
    local capItemYPos = y + 45 * Util.GetWindowSizeScale()
    capItem:SetPosition(capItemXPos, capItemYPos)

    local hairItem = self.viewItemList[Common.EquType.Hair]
    local hairItemWidth, _ = hairItem:GetSize()
    local hairItemXPos = x + (self.width - hairItemWidth) / 2 + 7 * Util.GetWindowSizeScale()
    local hairItemYPos = y + 37 * Util.GetWindowSizeScale()
    hairItem:SetPosition(hairItemXPos, hairItemYPos)

    local faceItem = self.viewItemList[Common.EquType.Face]
    local faceItemWidth, _ = faceItem:GetSize()
    local faceItemXPos = x + (self.width - faceItemWidth) / 2 + 55 * Util.GetWindowSizeScale()
    local faceItemYPos = y + 45 * Util.GetWindowSizeScale()
    faceItem:SetPosition(faceItemXPos, faceItemYPos)

    local neckItem = self.viewItemList[Common.EquType.Neck]
    local neckItemWidth, _ = neckItem:GetSize()
    local neckItemXPos = x + (self.width - neckItemWidth) / 2 + 7 * Util.GetWindowSizeScale()
    local neckItemYPos = y + 83 * Util.GetWindowSizeScale()
    neckItem:SetPosition(neckItemXPos, neckItemYPos)

    local coatItem = self.viewItemList[Common.EquType.Coat]
    local coatItemWidth, _ = coatItem:GetSize()
    local coatItemXPos = x + (self.width - coatItemWidth) / 2 + 7 * Util.GetWindowSizeScale()
    local coatItemYPos = y + 130 * Util.GetWindowSizeScale()
    coatItem:SetPosition(coatItemXPos, coatItemYPos)

    local skinItem = self.viewItemList[Common.EquType.Skin]
    local skinItemWidth, _ = skinItem:GetSize()
    local skinItemXPos = x + (self.width - skinItemWidth) / 2 + 55 * Util.GetWindowSizeScale()
    local skinItemYPos = y + 130 * Util.GetWindowSizeScale()
    skinItem:SetPosition(skinItemXPos, skinItemYPos)

    local beltItem = self.viewItemList[Common.EquType.Belt]
    local beltItemWidth, _ = beltItem:GetSize()
    local beltItemXPos = x + (self.width - beltItemWidth) / 2 + 7 * Util.GetWindowSizeScale()
    local beltItemYPos = y + 178 * Util.GetWindowSizeScale()
    beltItem:SetPosition(beltItemXPos, beltItemYPos)

    local weaponItem = self.viewItemList[Common.EquType.Weapon]
    local weaponItemWidth, _ = weaponItem:GetSize()
    local weaponItemXPos = x + (self.width - weaponItemWidth) / 2 - 69 * Util.GetWindowSizeScale()
    local weaponItemYPos = y + 250 * Util.GetWindowSizeScale()
    weaponItem:SetPosition(weaponItemXPos, weaponItemYPos)

    local pantsItem = self.viewItemList[Common.EquType.Pants]
    local pantsItemWidth, _ = pantsItem:GetSize()
    local pantsItemXPos = x + (self.width - pantsItemWidth) / 2 + 41 * Util.GetWindowSizeScale()
    local pantsItemYPos = y + 250 * Util.GetWindowSizeScale()
    pantsItem:SetPosition(pantsItemXPos, pantsItemYPos)

    local shoesItem = self.viewItemList[Common.EquType.Shoes]
    local shoesItemWidth, _ = shoesItem:GetSize()
    local shoesItemXPos = x + (self.width - shoesItemWidth) / 2 + 51 * Util.GetWindowSizeScale()
    local shoesItemYPos = y + 420 * Util.GetWindowSizeScale()
    shoesItem:SetPosition(shoesItemXPos, shoesItemYPos)
end

function RoleEquTableWidget:SetSize(width, height)
    self.width = width
    self.height = height

    self.nameLabel:SetSize(width, 30 * Util.GetWindowSizeScale())

    local portraitBgLabelXPos = 500 * 555 / 893 * Util.GetWindowSizeScale()
    local portraitBgLabelYPos = 500 * Util.GetWindowSizeScale()
    self.portraitBgLabel:SetSize(portraitBgLabelXPos, portraitBgLabelYPos)
    self.portraitBgLabel:SetIconSize(portraitBgLabelXPos, portraitBgLabelYPos)
end

function RoleEquTableWidget:SetEnable(enable)
    self.enable = enable
end

--- 设置某一显示项的信息
---@param index number
---@param itemInfo ArticleInfo
function RoleEquTableWidget:SetIndexItemInfo(index, itemInfo)
    local item = self.viewItemList[index]
    assert(item, "RoleEquTableWidget:SetIndexItemInfo(index, itemInfo), not exit item")
    local iconPath = itemInfo.iconPath
    if itemInfo.type == Common.ArticleType.Empty then
        iconPath = ""
    end
    item:SetIconSpriteDataPath(iconPath)
end

--- 当玩家改变后
---@type sender Object
function RoleEquTableWidget:Slot_PlayerChanged(sender)
    self:initArticleData()

    local player = self.model:GetPlayer()
    self.nameLabel:SetText(player.identity.name)
end

function RoleEquTableWidget:initArticleData()
    for i, info in pairs(self.model:GetMountedEquInfoList()) do
        self:SetIndexItemInfo(i, info)
    end
end

function RoleEquTableWidget:updateData()
    for i, item in pairs(self.viewItemList) do
        item:SetSize(ItemWidth, ItemWidth)
    end

    -- 技能显示项改变,则悬浮框也需要随之改变
    self:updateHoveringItemFrameData()
end

function RoleEquTableWidget:updateHoveringItemFrameData()
    -- hovering item frame label
    local item = self.viewItemList[self.hoveringItemIndex]
    if nil == item then
        self.hoveringItemFrameLabel:SetVisible(false)
        return
    end

    local x, y = item:GetPosition()
    self.hoveringItemFrameLabel:SetPosition(x, y)

    local w, h = item:GetSize()
    self.hoveringItemFrameLabel:SetSize(w, h)
    self.hoveringItemFrameLabel:SetIconSize(w, h)

    self.hoveringItemFrameLabel:SetVisible(true)
end

function RoleEquTableWidget:updateHoveringItemTipWindowData()
    self.model:RequestSetHoveringArticleItemTipWindowVisibility(self.isShowHoveringItemTip)

    local item = self.viewItemList[self.hoveringItemIndex]
    if nil == item then
        return
    end

    -- 设置悬浮框位置
    local tipWindowXPos = 0
    local tipWindowYPos = 0
    local bgX, bgY = item:GetPosition()
    local bgW, bgH = item:GetSize()
    tipWindowXPos = bgX + bgW / 2
    tipWindowYPos = bgY + bgH / 2

    self.model:RequestSetHoveringArticleItemTipWindowPosAndInfo(tipWindowXPos, tipWindowYPos, self.hoveringItemInfo)
end

return RoleEquTableWidget
