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

local WindowManager = require("UI.WindowManager")
local Widget = require("UI.Widget")
local Label = require("UI.Label")
local ArticleViewItem = require("UI.role_info.article_view_item")
local Window = require("UI.Window")
local Common = require("UI.ui_common")
local UiModel = require("UI.ui_model")

local Util = require("util.Util")

---@class RoleEquTableWidget
local RoleEquTableWidget = require("core.class")(Widget)


local ItemWidth = 0
local ItemSpace = 1
local TimeOfWaitToShowItemTip = 1000 * 0.5 -- 显示技能提示信息需要等待的时间，单位：ms

local ColCount = Common.EquTableColCount
local RowCount = Common.EquTableRowCount

---@param parentWindow Window
---@param model UiModel
function RoleEquTableWidget:Ctor(parentWindow, model)
    assert(parentWindow, "must assign parent window")
    ItemWidth = Common.ArticleItemWidth * Util.GetWindowSizeScale()
    ItemWidth = math.floor(ItemWidth)

    -- 父类构造函数
    Widget.Ctor(self, parentWindow)

    self.model = model

    self.width = ItemWidth * ColCount + ItemSpace * (ColCount - 1)
    self.height = ItemWidth * ColCount + ItemSpace * (RowCount - 1)

    self.nameLabel = Label.New(parentWindow)
    self.nameLabel:SetText("剑士")

    self.portraitBgLabel = Label.New(parentWindow)
    self.portraitBgLabel:SetIconSpriteDataPath("ui/CharacterPortraits/chivalrousMan")

    --- item background
    local itemBgImgPath = "ui/article_view_item/article_view_item_bg"
    ---@type talble<number, Label>
    self.viewItemBgList = {}
    --- item
    local itemImgPath = ""
    ---@type talble<number, ArticleViewItem>
    self.viewItemList = {}
    for i = 1, ColCount * RowCount do
        local bgLabel = Label.New(parentWindow)
        bgLabel:SetIconSpriteDataPath(itemBgImgPath)
        self.viewItemBgList[i] = bgLabel

        local item = ArticleViewItem.New(parentWindow)
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

    -- connect
    self.model:MocConnectSignal(self.model.Signal_PlayerChanged, self)

    --- post init
    self:updateData()
end

function RoleEquTableWidget:Update(dt)
    self:MouseEvent()

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

    self.nameLabel:Update(dt)
    self.portraitBgLabel:Update(dt)

    for i, label in pairs(self.viewItemBgList) do
        -- item background
        label:Update(dt)

        -- item
        local item = self.viewItemList[i]
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

    for i, label in pairs(self.viewItemBgList) do
        -- item background
        label:Draw()

        -- item
        local item = self.viewItemList[i]
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
        for i, label in pairs(self.viewItemBgList) do
            if label:CheckPoint(mousePosX, mousePosY) then
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

function RoleEquTableWidget:SetPosition(x, y)
    self.xPos = x
    self.yPos = y

    self.nameLabel:SetPosition(x, y)

    local portraitBgLabelWidth, _ = self.portraitBgLabel:GetSize()
    local portraitBgLabelXPos = x + (self.width - portraitBgLabelWidth) / 2
    self.portraitBgLabel:SetPosition(portraitBgLabelXPos, y + 0 * Util.GetWindowSizeScale())

    local capItemBgLabel = self.viewItemBgList[Common.EquType.Cap]
    local capItem = self.viewItemList[Common.EquType.Cap]
    local capItemBgLabelWidth, _ = capItemBgLabel:GetSize()
    local capItemXPos = x + (self.width - capItemBgLabelWidth) / 2 - 41 * Util.GetWindowSizeScale()
    local capItemYPos = y + 45 * Util.GetWindowSizeScale()
    capItemBgLabel:SetPosition(capItemXPos, capItemYPos)
    capItem:SetPosition(capItemXPos, capItemYPos)

    local hairItemBgLabel = self.viewItemBgList[Common.EquType.Hair]
    local hairItem = self.viewItemList[Common.EquType.Hair]
    local hairItemBgLabelWidth, _ = hairItemBgLabel:GetSize()
    local hairItemXPos = x + (self.width - hairItemBgLabelWidth) / 2 + 7 * Util.GetWindowSizeScale()
    local hairItemYPos = y + 37 * Util.GetWindowSizeScale()
    hairItemBgLabel:SetPosition(hairItemXPos, hairItemYPos)
    hairItem:SetPosition(hairItemXPos, hairItemYPos)

    local faceItemBgLabel = self.viewItemBgList[Common.EquType.Face]
    local faceItem = self.viewItemList[Common.EquType.Face]
    local faceItemBgLabelWidth, _ = faceItemBgLabel:GetSize()
    local faceItemXPos = x + (self.width - faceItemBgLabelWidth) / 2 + 55 * Util.GetWindowSizeScale()
    local faceItemYPos = y + 45 * Util.GetWindowSizeScale()
    faceItemBgLabel:SetPosition(faceItemXPos, faceItemYPos)
    faceItem:SetPosition(faceItemXPos, faceItemYPos)

    local neckItemBgLabel = self.viewItemBgList[Common.EquType.Neck]
    local neckItem = self.viewItemList[Common.EquType.Neck]
    local neckItemBgLabelWidth, _ = neckItemBgLabel:GetSize()
    local neckItemXPos = x + (self.width - neckItemBgLabelWidth) / 2 + 7 * Util.GetWindowSizeScale()
    local neckItemYPos = y + 83 * Util.GetWindowSizeScale()
    neckItemBgLabel:SetPosition(neckItemXPos, neckItemYPos)
    neckItem:SetPosition(neckItemXPos, neckItemYPos)

    local coatItemBgLabel = self.viewItemBgList[Common.EquType.Coat]
    local coatItem = self.viewItemList[Common.EquType.Coat]
    local coatItemBgLabelWidth, _ = coatItemBgLabel:GetSize()
    local coatItemXPos = x + (self.width - coatItemBgLabelWidth) / 2 + 7 * Util.GetWindowSizeScale()
    local coatItemYPos = y + 130 * Util.GetWindowSizeScale()
    coatItemBgLabel:SetPosition(coatItemXPos, coatItemYPos)
    coatItem:SetPosition(coatItemXPos, coatItemYPos)

    local skinItemBgLabel = self.viewItemBgList[Common.EquType.Skin]
    local skinItem = self.viewItemList[Common.EquType.Skin]
    local skinItemBgLabelWidth, _ = skinItemBgLabel:GetSize()
    local skinItemXPos = x + (self.width - skinItemBgLabelWidth) / 2 + 55 * Util.GetWindowSizeScale()
    local skinItemYPos = y + 130 * Util.GetWindowSizeScale()
    skinItemBgLabel:SetPosition(skinItemXPos, skinItemYPos)
    skinItem:SetPosition(skinItemXPos, skinItemYPos)

    local beltItemBgLabel = self.viewItemBgList[Common.EquType.Belt]
    local beltItem = self.viewItemList[Common.EquType.Belt]
    local beltItemBgLabelWidth, _ = beltItemBgLabel:GetSize()
    local beltItemXPos = x + (self.width - beltItemBgLabelWidth) / 2 + 7 * Util.GetWindowSizeScale()
    local beltItemYPos = y + 178 * Util.GetWindowSizeScale()
    beltItemBgLabel:SetPosition(beltItemXPos, beltItemYPos)
    beltItem:SetPosition(beltItemXPos, beltItemYPos)

    local weaponItemBgLabel = self.viewItemBgList[Common.EquType.Weapon]
    local weaponItem = self.viewItemList[Common.EquType.Weapon]
    local weaponItemBgLabelWidth, _ = weaponItemBgLabel:GetSize()
    local weaponItemXPos = x + (self.width - weaponItemBgLabelWidth) / 2 - 69 * Util.GetWindowSizeScale()
    local weaponItemYPos = y + 250 * Util.GetWindowSizeScale()
    weaponItemBgLabel:SetPosition(weaponItemXPos, weaponItemYPos)
    weaponItem:SetPosition(weaponItemXPos, weaponItemYPos)

    local pantsItemBgLabel = self.viewItemBgList[Common.EquType.Pants]
    local pantsItem = self.viewItemList[Common.EquType.Pants]
    local pantsItemBgLabelWidth, _ = pantsItemBgLabel:GetSize()
    local pantsItemXPos = x + (self.width - pantsItemBgLabelWidth) / 2 + 41 * Util.GetWindowSizeScale()
    local pantsItemYPos = y + 250 * Util.GetWindowSizeScale()
    pantsItemBgLabel:SetPosition(pantsItemXPos, pantsItemYPos)
    pantsItem:SetPosition(pantsItemXPos, pantsItemYPos)

    local shoesItemBgLabel = self.viewItemBgList[Common.EquType.Shoes]
    local shoesItem = self.viewItemList[Common.EquType.Shoes]
    local shoesItemBgLabelWidth, _ = shoesItemBgLabel:GetSize()
    local shoesItemXPos = x + (self.width - shoesItemBgLabelWidth) / 2 + 51 * Util.GetWindowSizeScale()
    local shoesItemYPos = y + 420 * Util.GetWindowSizeScale()
    shoesItemBgLabel:SetPosition(shoesItemXPos, shoesItemYPos)
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
end

function RoleEquTableWidget:initArticleData()
    for i, info in pairs(self.model:GetMountedEquInfoList()) do
        self:SetIndexItemInfo(i, info)
    end
end

function RoleEquTableWidget:updateData()
    for i, label in pairs(self.viewItemBgList) do
        local col = math.fmod(i - 1, ColCount) 
        local itemXPos = self.xPos + (ItemWidth + ItemSpace) * col
        local row = math.floor((i - 1) / ColCount)
        local itemYPos = self.yPos + (ItemWidth + ItemSpace) * row

        -- item background
        label:SetSize(ItemWidth, ItemWidth)
        label:SetIconSize(ItemWidth, ItemWidth)

        -- item
        local item = self.viewItemList[i]
        item:SetSize(ItemWidth, ItemWidth)
    end

    -- 技能显示项改变,则悬浮框也需要随之改变
    self:updateHoveringItemFrameData()
end

function RoleEquTableWidget:updateHoveringItemFrameData()
    -- hovering item frame label
    local skillItemBgLabel = self.viewItemBgList[self.hoveringItemIndex]
    if nil == skillItemBgLabel then
        self.hoveringItemFrameLabel:SetVisible(false)
        return
    end

    local x, y = skillItemBgLabel:GetPosition()
    self.hoveringItemFrameLabel:SetPosition(x, y)

    local w, h = skillItemBgLabel:GetSize()
    self.hoveringItemFrameLabel:SetSize(w, h)
    self.hoveringItemFrameLabel:SetIconSize(w, h)

    self.hoveringItemFrameLabel:SetVisible(true)
end

function RoleEquTableWidget:updateHoveringItemTipWindowData()
    self.model:RequestSetHoveringArticleItemTipWindowVisibility(self.isShowHoveringItemTip)

    local skillItemBgLabel = self.viewItemBgList[self.hoveringItemIndex]
    if nil == skillItemBgLabel then
        return
    end

    -- 设置悬浮框位置
    local tipWindowXPos = 0
    local tipWindowYPos = 0
    local bgX, bgY = skillItemBgLabel:GetPosition()
    local bgW, bgH = skillItemBgLabel:GetSize()
    tipWindowXPos = bgX + bgW / 2
    tipWindowYPos = bgY + bgH / 2

    self.model:RequestSetHoveringArticleItemTipWindowPosAndInfo(tipWindowXPos, tipWindowYPos, self.hoveringItemInfo)
end

return RoleEquTableWidget
