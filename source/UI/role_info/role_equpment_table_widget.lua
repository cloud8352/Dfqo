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

local WindowManager = require("UI.WindowManager")
local Widget = require("UI.Widget")
local Label = require("UI.Label")
local ArticleViewItem = require("UI.role_info.article_view_item")
local Window = require("UI.Window")
local Common = require("UI.ui_common")
local UiModel = require("UI.ui_model")

local Util = require("source.util.Util")

---@class RoleEquTableWidget
local RoleEquTableWidget = require("core.class")(Widget)


local ItemWidth = Common.ArticleItemWidth
local ItemSpace = 1
local TimeOfWaitToShowItemTip = 1000 * 0.5 -- 显示技能提示信息需要等待的时间，单位：ms

local ColCount = Common.EquTableColCount
local RowCount = Common.EquTableRowCount

---@param parentWindow Window
---@param model UiModel
function RoleEquTableWidget:Ctor(parentWindow, model)
    assert(parentWindow, "must assign parent window")
    -- 父类构造函数
    Widget.Ctor(self, parentWindow)

    self.model = model

    self.width = ItemWidth * ColCount + ItemSpace * (ColCount - 1)
    self.height = ItemWidth * ColCount + ItemSpace * (RowCount - 1)

    --- item background
    local itemBgImgPath = "ui/article_view_item/article_view_item_bg"
    ---@type talble<number, Label>
    self.viewItemBgList = {}
    --- item
    local itemImgPath = ""
    ---@type talble<number, ArticleViewItem>
    self.viewItemList = {}
    for i = 1, ColCount*RowCount do
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

    --- post init
    self:initArticleData()
    self:updateData()
end

function RoleEquTableWidget:Update(dt)
    self:MouseEvent()

    if (self.lastXPos ~= self.xPos
        or self.lastYPos ~= self.yPos
        or self.lastWidth ~= self.width
        or self.lastHeight ~= self.height
        or self.lastHeight ~= self.height
        )
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


    for i, label in pairs(self.viewItemBgList) do
        local col = math.fmod(i - 1, ColCount) 
        local itemXpos = self.xPos + (ItemWidth + ItemSpace) * col
        local row = math.floor((i - 1) / ColCount)
        local itemYPos = self.yPos + (ItemWidth + ItemSpace) * row

        -- item background
        label:SetPosition(itemXpos, itemYPos)

        -- item
        local item = self.viewItemList[i]
        item:SetPosition(itemXpos, itemYPos)
    end
end

function RoleEquTableWidget:SetSize(width, height)
    self.width = width
    self.height = height
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

function RoleEquTableWidget:initArticleData()
    for i, info in pairs(self.model:GetMountedEquInfoList()) do
        self:SetIndexItemInfo(i, info)
    end
end

function RoleEquTableWidget:updateData()
    for i, label in pairs(self.viewItemBgList) do
        local col = math.fmod(i - 1, ColCount) 
        local itemXpos = self.xPos + (ItemWidth + ItemSpace) * col
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
    tipWindowXPos = bgX + bgW/2
    tipWindowYPos = bgY + bgH/2

    self.model:RequestSetHoveringArticleItemTipWindowPosAndInfo(tipWindowXPos, tipWindowYPos, self.hoveringItemInfo)
end

return RoleEquTableWidget
