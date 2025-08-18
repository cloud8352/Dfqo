--[[
	desc: ArticleTableWidget class. 物品表格控件
	author: keke <243768648@qq.com>
]] --

local _CONFIG = require("config")
local _Mouse = require("lib.mouse")
local Timer = require("util.gear.timer")
local _MATH = require("lib.math")
local TableLib = require("lib.table")
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

local ItemSpace = 1
local TimeOfWaitToShowItemTip = 1000 * 0.5 -- 显示技能提示信息需要等待的时间，单位：ms

---@class ArticleTableWidget : Widget
local ArticleTableWidget = require("core.class")(Widget)

---@param parentWindow Window
---@param model UiModel
function ArticleTableWidget.Create(parentWindow, model)
    -- 用于定义构造函数，解释使用，不做实际用途
    -- 使用class模块后，实际会调用Ctor函数
    return ArticleTableWidget.New(parentWindow, model)
end

---@param parentWindow Window
---@param model UiModel
function ArticleTableWidget:Ctor(parentWindow, model)
    Widget.Ctor(self, parentWindow)

    self.itemWidth = Common.ArticleItemWidth * Util.GetWindowSizeScale()
    self.itemWidth = math.floor(self.itemWidth)

    self.colCount = Common.ArticleTableColCount
    self.rowCount = Common.ArticleTableRowCount

    self.model = model

    --- item
    ---@type table<number, ArticleViewItem>
    self.viewItemList = {}

    ---@type table<int, ArticleInfo>
    self.articleInfoList = {}

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
    
    --- post init
    self:updateData()
end

function ArticleTableWidget:Update(dt)
    if not self:IsVisible() then
        return
    end
    if not SysLib.IsMobile() then
        self:MouseEvent()
    else
        self:TouchEvent()
    end

    if (self:IsSizeChanged()
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

    for i, item in pairs(self.viewItemList) do
        item:Update(dt)
    end

    self.hoveringItemFrameLabel:Update(dt)

    --- 更新上次和当前的所有状态
    Widget.Update(self, dt)
    self.lastHoveringItemIndex = self.hoveringItemIndex
    self.lastIsShowHoveringItemTip = self.isShowHoveringItemTip
end

function ArticleTableWidget:Draw()
    if not self:IsVisible() then
        return
    end

    for i, item in pairs(self.viewItemList) do
        item:Draw()
    end

    self.hoveringItemFrameLabel:Draw()
end

function ArticleTableWidget:MouseEvent()
    -- 判断鼠标
    while true do
        -- 检查是否有上层窗口遮挡
        local parentWindow = self:GetParentWindow()
        local windowLayerIndex = parentWindow:GetWindowLayerIndex()
        if WindowManager.IsMouseCapturedAboveLayer(windowLayerIndex)
            or parentWindow:IsInMoving() then
            self:setHoveringItemIndex(-1)
            -- self.hoveringItemInfo = nil
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
                self:rightKeyClickedItem(hoveringItemIndex)
            end
        end

        if hoveringItemIndex == self.hoveringItemIndex then
            break
        end

        if -1 == hoveringItemIndex then
            self:setHoveringItemIndex(-1)
            self.itemHoveringTimer:Exit()
        else
            self:setHoveringItemIndex(hoveringItemIndex)

            -- 开启计时鼠标悬浮时间
            self.itemHoveringTimer:Enter(TimeOfWaitToShowItemTip)
        end

        break
    end

    self:judgeAndExecRequestDragItem()
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

function ArticleTableWidget:TouchEvent()
    -- 判断鼠标
    while true do
        -- 检查是否点击了其他窗口
        local parentWindow = self:GetParentWindow()
        local capturedTouchIdList = WindowManager.GetWindowCapturedTouchIdList(parentWindow)
        if #capturedTouchIdList == 0 and
            TouchLib.WhetherExistHoldPoint()
        then
            self:setHoveringItemIndex(-1)
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
            self:setHoveringItemIndex(-1)
            self.itemHoveringTimer:Exit()
            break
        end

        local point = TouchLib.GetPoint(touchedId)
        if self.timeMsToLastPressed < 500
            and hoveringItemIndex == self.hoveringItemIndex
            and TouchLib.WhetherPointIsPressed(point)
        then
            -- 使用物品（模拟右键点击）
            self:rightKeyClickedItem(hoveringItemIndex)
        end

        if TouchLib.WhetherPointIsPressed(point) then
            self.timeMsToLastPressed = 0
        end

        if hoveringItemIndex == self.hoveringItemIndex then
            break
        end

        self.touchedId = touchedId
        self:setHoveringItemIndex(hoveringItemIndex)

        -- 开启计时鼠标悬浮时间
        self.itemHoveringTimer:Enter(TimeOfWaitToShowItemTip)
        break
    end

    self:judgeAndExecRequestDragItemUnderTouch()
end

function ArticleTableWidget:SetPosition(x, y)
    Widget.SetPosition(self, x, y)

    for i, item in pairs(self.viewItemList) do
        local col = math.fmod(i - 1, self.colCount) 
        local itemXPos = x + (self.itemWidth + ItemSpace) * col
        local row = math.floor((i - 1) / self.colCount)
        local itemYPos = y + (self.itemWidth + ItemSpace) * row

        item:SetPosition(itemXPos, itemYPos)
    end
end

---@return number, number w, h
function ArticleTableWidget:GetSize()
    return Widget.GetSize(self)
end

function ArticleTableWidget:SetEnable(enable)
    Widget.SetEnable(self, enable)
end

---@param rowCount int
---@param colCount int
function ArticleTableWidget:SetRowColCount(rowCount, colCount)
    self.rowCount = rowCount
    self.colCount = colCount

    self.viewItemList = {}
    self.articleInfoList = {}
    local parentWindow = self:GetParentWindow()
    for i = 1, colCount * rowCount do
        local item = ArticleViewItem.New(parentWindow)
        item:SetIconSpriteDataPath("")
        self.viewItemList[i] = item

        local info = Common.NewArticleInfo()
        self.articleInfoList[i] = info
    end

    -- update size
    local width = self.itemWidth * colCount + ItemSpace * (colCount - 1)
    local height = self.itemWidth * colCount + ItemSpace * (rowCount - 1)
    self:SetSize(width, height)

    self:updateData()
end

function ArticleTableWidget:GetItemList()
    return self.viewItemList
end

--- 设置某一显示项的信息
---@param index number
---@param itemInfo ArticleInfo
function ArticleTableWidget:SetIndexItemInfo(index, itemInfo)
    local item = self.viewItemList[index]
    assert(item, "ArticleTableWidget:SetIndexItemInfo(index, itemInfo), not exit item")
    local iconPath = itemInfo.iconPath
    local count = itemInfo.count
    if itemInfo.type == Common.ArticleType.Empty then
        iconPath = ""
        count = 0
    end
    item:SetIconSpriteDataPath(iconPath)
    item:SetCount(count)

    -- info
    self.articleInfoList[index] = TableLib.DeepClone(itemInfo)
end

--- protect func

--- can override
---@param index int
function ArticleTableWidget:setHoveringItemIndex(index)
    self.hoveringItemIndex = index
    if index < 1 then
        self.hoveringItemInfo = nil
    else
        self.hoveringItemInfo = self.articleInfoList[index]
    end
end

--- can override
---@param index int
function ArticleTableWidget:rightKeyClickedItem(index)
end

--- can override
function ArticleTableWidget:dropItem()
end

--- can override
--- 设置拖拽中的物品索引
---@param index int
function ArticleTableWidget:dragItem(index)
end

--- can override
---@param xPos int
---@param yPos int
function ArticleTableWidget:moveDraggingItem(xPos, yPos)
end

--- private func

function ArticleTableWidget:updateData()
    local xPos, yPos = self:GetPosition()
    for i, item in pairs(self.viewItemList) do
        local col = math.fmod(i - 1, self.colCount) 
        local itemXPos = xPos + (self.itemWidth + ItemSpace) * col
        local row = math.floor((i - 1) / self.colCount)
        local itemYPos = yPos + (self.itemWidth + ItemSpace) * row

        item:SetPosition(itemXPos, itemYPos)
        item:SetSize(self.itemWidth, self.itemWidth)
    end

    -- 技能显示项改变,则悬浮框也需要随之改变
    self:updateHoveringItemFrameData()
end

function ArticleTableWidget:updateHoveringItemFrameData()
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

function ArticleTableWidget:updateHoveringItemTipWindowData()
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

function ArticleTableWidget:judgeAndExecRequestDragItem()
    local currentMouseXPos = 0
    local currentMouseYPos = 0
    -- 判断鼠标
    while true do
        -- 是否处于按压中
        if false == _Mouse.IsHold(1) then -- 1 is the primary mouse button, 2 is the secondary mouse button and 3 is the middle button
            if self.isReqDragItem == true then
                self:dropItem()
                self:setHoveringItemIndex(-1)
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
        self.originXPosWhenDragItem = currentMouseXPos - self.itemWidth / 2
        self.originYPosWhenDragItem = currentMouseYPos - self.itemWidth / 2

        -- 设置拖拽中的物品索引
        self:dragItem(self.hoveringItemIndex)
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
        self:moveDraggingItem(destXPos, destYPos)
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
                self:dropItem()
                self:setHoveringItemIndex(-1)
                self.touchedId = -1
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
        self.originXPosWhenDragItem = touchedPoint.x - self.itemWidth / 2
        self.originYPosWhenDragItem = touchedPoint.y - self.itemWidth / 2

        -- 设置拖拽中的物品索引
        self:dragItem(self.hoveringItemIndex)
        break
    end

    if self.isReqDragItem then
        local destXPos = self.originXPosWhenDragItem + touchedPoint.x - self.originMouseXPosWhenDragItem
        local destYPos = self.originYPosWhenDragItem + touchedPoint.y - self.originMouseYPosWhenDragItem
        self:moveDraggingItem(destXPos, destYPos)
    end
end

return ArticleTableWidget
