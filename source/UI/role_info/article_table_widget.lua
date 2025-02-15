--[[
	desc: SkillDockViewFrame class. 技能托盘显示框架
	author: keke <243768648@qq.com>
	since: 2023-4-15
	alter: 2023-4-15
]] --

local _CONFIG = require("config")
local _Mouse = require("lib.mouse")
local Timer = require("util.gear.timer")
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


--- item background
local DockedItemBgImgPath = "ui/article_view_item/article_view_item_bg"
local ItemBgImgPath = "ui/WindowFrame/CenterBg"

local ItemWidth = Common.ArticleItemWidth
ItemWidth = _MATH.Round(ItemWidth)
local ItemSpace = 1
local TimeOfWaitToShowItemTip = 1000 * 0.5 -- 显示技能提示信息需要等待的时间，单位：ms

local ColCount = Common.ArticleTableColCount
local RowCount = Common.ArticleTableRowCount

---@class ArticleTableWidget
local ArticleTableWidget = require("core.class")(Widget)

---@param parentWindow Window
---@param model UiModel
function ArticleTableWidget:Ctor(parentWindow, model)
    assert(parentWindow, "must assign parent window")
    ItemWidth = Common.ArticleItemWidth * Util.GetWindowSizeScale()
    ItemWidth = math.floor(ItemWidth)

    -- 父类构造函数
    self.baseWidget = Widget.New(parentWindow)

    self.model = model

    self.baseWidget.width = ItemWidth * ColCount + ItemSpace * (ColCount - 1)
    self.baseWidget.height = ItemWidth * ColCount + ItemSpace * (RowCount - 1)

    ---@type table<number, Label>
    self.viewItemBgList = {}
    --- item
    ---@type table<number, ArticleViewItem>
    self.viewItemList = {}
    for i = 1, ColCount * RowCount do
        local bgImgPath = ItemBgImgPath
        if i <= Common.ArticleDockColCount then
            bgImgPath = DockedItemBgImgPath
        end
        local bgLabel = Label.New(parentWindow)
        bgLabel:SetIconSpriteDataPath(bgImgPath)
        self.viewItemBgList[i] = bgLabel

        local item = ArticleViewItem.New(parentWindow)
        item:SetIconSpriteDataPath("")
        self.viewItemList[i] = item
    end

    -- 上一帧时是否被按压
    self.lastIsPressed = false

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

    -- 拖拽相关属性
    self.isReqDragItem = false
    self.originMouseXPosWhenDragItem = 0
    self.originMouseYPosWhenDragItem = 0
    self.originXPosWhenDragItem = 0
    self.originYPosWhenDragItem = 0

    -- touch
    self.touchedId = -1
    self.timeMsToLastPressed = 0

    -- connect
    self.model:MocConnectSignal(self.model.Signal_PlayerChanged, self)
    
    --- post init
    self:updateData()
end

function ArticleTableWidget:Update(dt)
    if not self.baseWidget.isVisible then
        return
    end
    if not SysLib.IsMobile() then
        self:MouseEvent()
    else
        self:TouchEvent()
    end

    if (self.baseWidget:IsSizeChanged()
        ) then
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

    for i, label in pairs(self.viewItemBgList) do
        -- item background
        label:Update(dt)

        -- item
        local item = self.viewItemList[i]
        item:Update(dt)
    end

    self.hoveringItemFrameLabel:Update(dt)

    --- 更新上次和当前的所有状态
    self.baseWidget:Update(dt)
    self.lastHoveringItemIndex = self.hoveringItemIndex
    self.lastIsShowHoveringItemTip = self.isShowHoveringItemTip
end

function ArticleTableWidget:Draw()
    for i, label in pairs(self.viewItemBgList) do
        -- item background
        label:Draw()

        -- item
        local item = self.viewItemList[i]
        item:Draw()
    end

    self.hoveringItemFrameLabel:Draw()
end

function ArticleTableWidget:MouseEvent()
    -- 判断鼠标
    while true do
        -- 检查是否有上层窗口遮挡
        local windowLayerIndex = self.baseWidget.parentWindow:GetWindowLayerIndex()
        if WindowManager.IsMouseCapturedAboveLayer(windowLayerIndex)
            or self.baseWidget.parentWindow:IsInMoving() then
            self.hoveringItemIndex = -1
            self.model:SetArticleTableHoveringItemIndex(-1)
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
                self.model:OnRightKeyClickedArticleTableItem(hoveringItemIndex)
            end
        end

        if hoveringItemIndex == self.hoveringItemIndex then
            break
        end

        if -1 == hoveringItemIndex then
            self.hoveringItemIndex = -1
            self.model:SetArticleTableHoveringItemIndex(-1)
            self.hoveringItemInfo = nil
            self.itemHoveringTimer:Exit()
        else
            self.hoveringItemIndex = hoveringItemIndex
            self.model:SetArticleTableHoveringItemIndex(hoveringItemIndex)
            self.hoveringItemInfo = self.model:GetArticleInfoList()[hoveringItemIndex]

            -- 开启计时鼠标悬浮时间
            self.itemHoveringTimer:Enter(TimeOfWaitToShowItemTip)
        end

        break
    end

    self:judgeAndExecRequestDragItem()
end

---@param label Label
---@param idList table<number, string>
---@return string id
local function getLabelTouchedId(label, idList)
    for _, id in pairs(idList) do
        local point = TouchLib.GetPoint(id)
        if (label:CheckPoint(point.x, point.y)) then
            return id
        end
    end

    return ""
end

function ArticleTableWidget:TouchEvent()
    -- 判断鼠标
    while true do
        -- 检查是否点击了其他窗口
        local capturedTouchIdList = WindowManager.GetWindowCapturedTouchIdList(self.baseWidget.parentWindow)
        if #capturedTouchIdList == 0 and
            TouchLib.WhetherExistHoldPoint()
        then
            self.hoveringItemIndex = -1
            self.model:SetArticleTableHoveringItemIndex(-1)
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
        for i, label in pairs(self.viewItemBgList) do
            touchedId = getLabelTouchedId(label, capturedTouchIdList)
            if touchedId ~= "" then
                hoveringItemIndex = i
                break
            end
        end

        if hoveringItemIndex == -1 then
            self.hoveringItemIndex = -1
            self.model:SetArticleTableHoveringItemIndex(-1)
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
            self.model:OnRightKeyClickedArticleTableItem(hoveringItemIndex)
        end

        if TouchLib.WhetherPointIsPressed(point) then
            self.timeMsToLastPressed = 0
        end

        if hoveringItemIndex == self.hoveringItemIndex then
            break
        end

        self.touchedId = touchedId
        self.hoveringItemIndex = hoveringItemIndex
        self.model:SetArticleTableHoveringItemIndex(hoveringItemIndex)
        self.hoveringItemInfo = self.model:GetArticleInfoList()[hoveringItemIndex]

        -- 开启计时鼠标悬浮时间
        self.itemHoveringTimer:Enter(TimeOfWaitToShowItemTip)
        break
    end

    self:judgeAndExecRequestDragItemUnderTouch()
end

function ArticleTableWidget:SetPosition(x, y)
    self.baseWidget:SetPosition(x, y)

    for i, label in pairs(self.viewItemBgList) do
        local col = math.fmod(i - 1, ColCount) 
        local itemXPos = self.baseWidget.xPos + (ItemWidth + ItemSpace) * col
        local row = math.floor((i - 1) / ColCount)
        local itemYPos = self.baseWidget.yPos + (ItemWidth + ItemSpace) * row

        -- item background
        label:SetPosition(itemXPos, itemYPos)

        -- item
        local item = self.viewItemList[i]
        item:SetPosition(itemXPos, itemYPos)
    end
end

---@return number, number w, h
function ArticleTableWidget:GetSize()
    return self.baseWidget:GetSize()
end

function ArticleTableWidget:SetEnable(enable)
    self.baseWidget:SetEnable(enable)
end

--- 设置某一显示项的信息
---@param index number
---@param itemInfo ArticleInfo
function ArticleTableWidget:SetIndexItemInfo(index, itemInfo)
    local item = self.viewItemList[index]
    assert(item, "ArticleTableWidget:SetIndexItemInfo(index, itemInfo), not exit item")
    local iconPath = itemInfo.iconPath
    if itemInfo.type == Common.ArticleType.Empty then
        iconPath = ""
    end
    item:SetIconSpriteDataPath(iconPath)
    item:SetCount(itemInfo.count)
end

--- 当玩家改变后
---@param sender Object
function ArticleTableWidget:Slot_PlayerChanged(sender)
    self:initArticleData()
end

function ArticleTableWidget:initArticleData()
    for i, info in pairs(self.model:GetArticleInfoList()) do
        self:SetIndexItemInfo(i, info)
    end
end

function ArticleTableWidget:updateData()
    for i, label in pairs(self.viewItemBgList) do
        local col = math.fmod(i - 1, ColCount) 
        local itemXPos = self.baseWidget.xPos + (ItemWidth + ItemSpace) * col
        local row = math.floor((i - 1) / ColCount)
        local itemYPos = self.baseWidget.yPos + (ItemWidth + ItemSpace) * row

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

function ArticleTableWidget:updateHoveringItemFrameData()
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

function ArticleTableWidget:updateHoveringItemTipWindowData()
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

function ArticleTableWidget:judgeAndExecRequestDragItem()
    local currentMouseXPos = 0
    local currentMouseYPos = 0
    -- 判断鼠标
    while true do
        -- 是否处于按压中
        if false == _Mouse.IsHold(1) then -- 1 is the primary mouse button, 2 is the secondary mouse button and 3 is the middle button
            if self.isReqDragItem == true then
                self.model:DropArticleItem()
                self.hoveringItemIndex = -1
                self.model:SetArticleTableHoveringItemIndex(-1)
            end
            
            self.isReqDragItem = false
            break
        end

        -- 获取当前鼠标位置
        currentMouseXPos, currentMouseYPos = _Mouse.GetPosition(1, 1)
        -- 如果正处于请求移动窗口中，则直接退出循环执行移动窗口逻辑
        if self.isReqDragItem then
            break
        end

        if not self.lastIsPressed then
            break
        end

        -- 确保鼠标停靠在物品上
        if self.hoveringItemIndex == -1 or self.hoveringItemInfo.type == Common.ArticleType.Empty then
            break
        end

        -- 请求移动窗口
        self.isReqDragItem = true
        self.originMouseXPosWhenDragItem = currentMouseXPos
        self.originMouseYPosWhenDragItem = currentMouseYPos
        self.originXPosWhenDragItem = currentMouseXPos - ItemWidth / 2
        self.originYPosWhenDragItem = currentMouseYPos - ItemWidth / 2

        -- 设置拖拽中的物品索引
        self.model:DragArticleItem(self.hoveringItemIndex)
        break
    end

    if _Mouse.IsPressed(1) then
        self.lastIsPressed = true
    else
        self.lastIsPressed = false
    end

    if self.isReqDragItem then
        local destXPos = self.originXPosWhenDragItem + currentMouseXPos - self.originMouseXPosWhenDragItem
        local destYPos = self.originYPosWhenDragItem + currentMouseYPos - self.originMouseYPosWhenDragItem
        self.model:OnRequestMoveDraggingArticleItem(destXPos, destYPos)
    end
end

function ArticleTableWidget:judgeAndExecRequestDragItemUnderTouch()
    if self.timeMsToLastPressed < 800 then
        return
    end
    local touchedPoint = TouchLib.GetPoint(self.touchedId)
    if touchedPoint == nil then
        return
    end

    -- 判断鼠标
    while true do
        -- 是否处于按压中
        if false == TouchLib.WhetherPointIsHold(touchedPoint) then
            if self.isReqDragItem == true then
                self.model:DropArticleItem()
                self.hoveringItemIndex = -1
                self.touchedId = -1
                self.model:SetArticleTableHoveringItemIndex(-1)
            end
            
            self.isReqDragItem = false
            break
        end

        -- 如果正处于请求移动窗口中，则直接退出循环执行移动窗口逻辑
        if self.isReqDragItem then
            break
        end

        -- 确保鼠标停靠在物品上
        if self.hoveringItemIndex == -1 or self.hoveringItemInfo.type == Common.ArticleType.Empty then
            break
        end

        -- 请求移动窗口
        self.isReqDragItem = true
        self.originMouseXPosWhenDragItem = touchedPoint.x
        self.originMouseYPosWhenDragItem = touchedPoint.y
        self.originXPosWhenDragItem = touchedPoint.x - ItemWidth / 2
        self.originYPosWhenDragItem = touchedPoint.y - ItemWidth / 2

        -- 设置拖拽中的物品索引
        self.model:DragArticleItem(self.hoveringItemIndex)
        break
    end

    if self.isReqDragItem then
        local destXPos = self.originXPosWhenDragItem + touchedPoint.x - self.originMouseXPosWhenDragItem
        local destYPos = self.originYPosWhenDragItem + touchedPoint.y - self.originMouseYPosWhenDragItem
        self.model:OnRequestMoveDraggingArticleItem(destXPos, destYPos)
    end
end

return ArticleTableWidget
