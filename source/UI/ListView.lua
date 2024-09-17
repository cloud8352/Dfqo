--[[
	desc: ListView class.
	author: keke <243768648@qq.com>
	since: 2022-11-15
	alter: 2022-11-15
]] --

local _CONFIG = require("config")
local _RESOURCE = require("lib.resource")
local _Sprite = require("graphics.drawable.sprite")
local _Graphics = require("lib.graphics")
local _Mouse = require("lib.mouse")
local _TABLE = require("lib.table")

local WindowManager = require("UI.WindowManager")
local StandardItem = require("UI.StandardItem")
local ScrollArea = require("UI.ScrollArea")
local ScrollBar = require("UI.ScrollBar")
local Widget = require("UI.Widget")

---@class ListView
---@type ScrollArea
local ListView = require("core.class")(ScrollArea)

---@param parentWindow Window
function ListView:Ctor(parentWindow)
    ScrollArea.Ctor(self, parentWindow)
    assert(parentWindow, "must assign parent window")
    ---@type Window
    self.parentWindow = parentWindow

    -- 列表项内容控件（相当于全图，但滑动区域只显示列表项内容控件的部分区域）
    self.itemListContentWidget = Widget.New(parentWindow)
    -- 绑定到滑动区域
    ScrollArea.SetContentWidget(self, self.itemListContentWidget)

    self.itemHeight = 40
    ---@type table<int, StandardItem>
    self.itemList = {}

    ---@type StandardItem
    self.currentItem = nil

    self.needUpdateItemListContentWidgetSprite = false
end

function ListView:Update(dt)
    if false == self.isVisible then
        return
    end
    self:MouseEvent()

    self.itemListContentWidget:Update(dt)

    -- item
    for _, item in pairs(self.itemList) do
        item:Update(dt)
    end

    if self.needUpdateItemListContentWidgetSprite then
        self:updateItemListContentWidgetSprite()
        ScrollArea.SetNeedUpdateContentSprite(self, true)
        self.needUpdateItemListContentWidgetSprite = false
    end

    ScrollArea.Update(self, dt)
end

function ListView:Draw()
    ScrollArea.Draw(self)
    if false == self.isVisible then
        return
    end
end

function ListView:MouseEvent()
    -- 判断鼠标
    while true do
        -- 是否处于禁用状态
        if false == self.enable then
            for _, item in pairs(self.itemList) do
                item:SetDisplayState(StandardItem.DisplayState.Disable)
            end
            break
        end

        -- 检查是否有上层窗口遮挡
        local windowLayerIndex = self.parentWindow:GetWindowLayerIndex()
        if WindowManager.IsMouseCapturedAboveLayer(windowLayerIndex) then
            for _, item in pairs(self.itemList) do
                if StandardItem.DisplayState.Hovering == item:GetCurrentDisplayState() then
                    item:SetDisplayState(StandardItem.DisplayState.Normal)
                end
            end
            break
        end

        -- 如果鼠标不在显示项列区域中
        local mousePosX, mousePosY = _Mouse.GetPosition(1, 1)
        if false == self:CheckPoint(mousePosX, mousePosY) then
            for _, item in pairs(self.itemList) do
                if StandardItem.DisplayState.Hovering == item:GetCurrentDisplayState() then
                    item:SetDisplayState(StandardItem.DisplayState.Normal)
                end
            end
            break
        end

        -- 寻找鼠标悬停处的显示项
        ---@type StandardItem
        local hoveringItem = nil
        for i, item in pairs(self.itemList) do
            if false == item:CheckPoint(mousePosX, mousePosY) then
                if StandardItem.DisplayState.Hovering == item:GetCurrentDisplayState() then
                    item:SetDisplayState(StandardItem.DisplayState.Normal)
                end
            else
                hoveringItem = item
            end
        end
        if nil == hoveringItem then
            break
        end

        -- 是否点击
        if _Mouse.IsReleased(1) then -- 1 is the primary mouse button, 2 is the secondary mouse button and 3 is the middle button
            self:SetCurrentItem(hoveringItem)
            break
        end

        if StandardItem.DisplayState.Selected == hoveringItem:GetCurrentDisplayState() then
            break
        end
        hoveringItem:SetDisplayState(StandardItem.DisplayState.Hovering)
        break
    end
end

--- 连接信号
---@param signal function
---@param obj Object
function ListView:MocConnectSignal(signal, receiver)
    ScrollArea.MocConnectSignal(self, signal, receiver)
end

---@param signal function
function ListView:GetReceiverListOfSignal(signal)
    return ScrollArea.GetReceiverListOfSignal(self, signal)
end

---@param name string
function ListView:SetObjectName(name)
    ScrollArea.SetObjectName(self, name)
end

function ListView:GetObjectName()
    return ScrollArea.GetObjectName(self)
end

function ListView:SetPosition(x, y)
    ScrollArea.SetPosition(self, x, y)

    -- item
    self:updateAllItemsPosition()
end

---@return int, int x, y
function ListView:GetPosition()
    return ScrollArea.GetPosition(self)
end

function ListView:SetSize(width, height)
    if (width <= 0 or height <= 0) then
        return
    end
    ScrollArea.SetSize(self, width, height)

    local displayContentWidth = ScrollArea.GetDisplayContentWidth(self)

    -- item
    for i, item in pairs(self.itemList) do
        item:SetSize(displayContentWidth, self.itemHeight)
    end

    -- 设置 列表项内容控件 尺寸
    local itemListContentWidgetHeight = self.itemHeight * #self.itemList
    self.itemListContentWidget:SetSize(displayContentWidth, itemListContentWidgetHeight)
end

function ListView:GetSize()
    return ScrollArea.GetSize(self)
end

function ListView:SetEnable(enable)
    ScrollArea.SetEnable(self, enable)

    self.itemListContentWidget:SetEnable(enable)
end

function ListView:IsVisible()
    return ScrollArea.IsVisible(self)
end

---@param isVisible bool
function ListView:SetVisible(isVisible)
    ScrollArea.SetVisible(self, isVisible)

    self.itemListContentWidget:SetVisible(isVisible)
end

---@param x int
---@param y int
function ListView:CheckPoint(x, y)
    return ScrollArea.CheckPoint(self, x, y)
end

function ListView:ClearAllItems()
    self.itemList = {}
end

---@param item StandardItem
function ListView:InsertItem(i, item)
    table.insert(self.itemList, i, item)

    -- connection
    item:MocConnectSignal(item.Signal_ItemDisplayChanged, self)

    -- 更新index
    for i, item in pairs(self.itemList) do
        item:SetIndex(i)
    end

    -- 更新尺寸
    local displayContentWidth = ScrollArea.GetDisplayContentWidth(self)
    -- item
    for i, item in pairs(self.itemList) do
        item:SetSize(displayContentWidth, self.itemHeight)
    end

    -- 更新坐标
    self:updateAllItemsPosition()
    
    -- 设置 列表项内容控件 尺寸
    local itemListContentWidgetHeight = self.itemHeight * #self.itemList
    self.itemListContentWidget:SetSize(displayContentWidth, itemListContentWidgetHeight)

    self.needUpdateItemListContentWidgetSprite = true
end

function ListView:InsertItemWithText(i, text)
    local item = StandardItem.New()
    item:SetText(text)

    self:InsertItem(i, item)
end

---@param item StandardItem
function ListView:AppendItem(item)
    self:InsertItem(#self.itemList + 1, item)
end

function ListView:AppendItemWithText(text)
    self:InsertItemWithText(#self.itemList + 1, text)
end

---@return table<int, StandardItem> itemList 
function ListView:GetItemList()
    return self.itemList
end

---@param itemHeight int
function ListView:SetItemHeight(itemHeight)
    self.itemHeight = itemHeight

    self.needUpdateItemListContentWidgetSprite = true
end

---@param item StandardItem
function ListView:SetCurrentItem(item)
    if item == nil then
        return
    end
    self.currentItem = item

    for _, itemTmp in pairs(self.itemList) do
        itemTmp:SetDisplayState(StandardItem.DisplayState.Normal)
    end
    item:SetDisplayState(StandardItem.DisplayState.Selected)
    -- -- 判断和执行选中项改变事件
    self:Signal_SelectedItemChanged(item)
end

function ListView:GetCurrentItem()
    return self.currentItem
end

---@param index int
function ListView:SetCurrentIndex(index)
    local item = self.itemList[index]
    self:SetCurrentItem(item)
end

function ListView:SortByStr()
    ---@param a StandardItem
    ---@param b StandardItem
    local function compare(a, b)
        return a:GetSortingStr() < b:GetSortingStr()
    end

    table.sort(self.itemList, compare)

    self.needUpdateItemListContentWidgetSprite = true
end

function ListView:SortByNum()
    ---@param a StandardItem
    ---@param b StandardItem
    local function compare(a, b)
        return a:GetSortingNum() < b:GetSortingNum()
    end

    table.sort(self.itemList, compare)

    self.needUpdateItemListContentWidgetSprite = true
end

--- signals
---
---@param selectedItem StandardItem
function ListView:Signal_SelectedItemChanged(selectedItem)
    print("ListView:Signal_SelectedItemChanged()")
    local receiverList = self:GetReceiverListOfSignal(self.Signal_SelectedItemChanged)
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.Slot_SelectedItemChanged
        if func == nil then
            goto continue
        end

        func(receiver, self, selectedItem)

        ::continue::
    end
end

--- slot
---
---@param sender Obj
---@param xOffset int
---@param yOffset int
function ListView:Slot_RequestMoveContent(sender, xOffset, yOffset)
    ScrollArea.Slot_RequestMoveContent(self, sender, xOffset, yOffset)
    print("ListView:Slot_RequestMoveContent()", sender, xOffset, yOffset)
    self.needUpdateItemListContentWidgetSprite = true

    -- item
    self:updateAllItemsPosition()
end

---@param sender Obj
function ListView:Slot_ItemDisplayChanged(sender)
    self.needUpdateItemListContentWidgetSprite = true
end

--- private function

function ListView:updateItemListContentWidgetSprite()
    local contentWidth, contentHeight = self.itemListContentWidget:GetSize()
    if contentWidth <= 0 or contentHeight <= 0 then
        return
    end

    _Graphics.SaveCanvas()
    -- 创建背景画布
    
    local canvas = _Graphics.NewCanvas(contentWidth, contentHeight)
    _Graphics.SetCanvas(canvas)

    -- 注意：不可用深度克隆方法，因为StandardItem中的sprite成员初始化时绑定了信号槽，克隆后也会继承之前的信号槽，导致调用SetAttri后使被克隆对象属性改变
    -- 创建临时绘图精灵
    local painterSprite = _Sprite.New()

    -- 更新内容显示板中显示精灵
    for i, item in pairs(self.itemList) do
        painterSprite:SetImage(item:GetCurrentImgCanvas())
        painterSprite:SetAttri("position", 0, self.itemHeight * (i - 1))
        painterSprite:Draw()
    end
    _Graphics.RestoreCanvas()

    painterSprite:SetImage(canvas)
    painterSprite:AdjustDimensions()
    self.itemListContentWidget:SetBgSprite(painterSprite)
end

function ListView:updateAllItemsPosition()
    local leftMargin, topMargin, _, _ = ScrollArea.GetMargins(self)
    local xPos, yPos = ScrollArea.GetPosition(self)
    local contentYOffset = ScrollArea.GetContentYOffset(self)

    -- item
    for i, item in pairs(self.itemList) do
        item:SetPosition(xPos + leftMargin, yPos + contentYOffset + topMargin + self.itemHeight * (i - 1))
    end
end

return ListView
