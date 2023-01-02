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

---@class ListView
---@type ScrollArea
local ListView = require("core.class")(ScrollArea)

---@param parentWindow Window
function ListView:Ctor(parentWindow)
    ScrollArea.Ctor(self)
    assert(parentWindow, "must assign parent window")
    ---@type Window
    self.parentWindow = parentWindow

    self.bgSprite = _Sprite.New()
    self.bgSprite:SwitchRect(true) -- 使用矩形
    self.width = 30
    self.height = 10
    self.posX = 0
    self.posY = 0
    self.enable = true
    self.isVisible = true

    -- 背景图片数据
    self.leftTopBgImgDate = _RESOURCE.GetSpriteData("ui/WindowFrame/LeftTopBg")
    self.topBgImgDate = _RESOURCE.GetSpriteData("ui/WindowFrame/TopBg")
    self.rightTopBgImgDate = _RESOURCE.GetSpriteData("ui/WindowFrame/RightTopBg")
    self.leftBgImgDate = _RESOURCE.GetSpriteData("ui/WindowFrame/LeftBg")
    self.centerBgImgDate = _RESOURCE.GetSpriteData("ui/WindowFrame/CenterBg")
    self.rightBgImgDate = _RESOURCE.GetSpriteData("ui/WindowFrame/RightBg")
    self.leftBottomBgImgDate = _RESOURCE.GetSpriteData("ui/WindowFrame/LeftBottomBg")
    self.bottomBgImgDate = _RESOURCE.GetSpriteData("ui/WindowFrame/BottomBg")
    self.rightBottomBgImgDate = _RESOURCE.GetSpriteData("ui/WindowFrame/RightBottomBg")

    -- 列表项
    ---@type Graphics.Drawable | Graphics.Drawable.IRect | Graphics.Drawable.IPath | Graphics.Drawable.Sprite
    self.itemListContentSprite = _Sprite.New()
    self.itemListContentSprite:SwitchRect(true)
    self.itemListContentYOffset = 0
    self.itemHeight = 40
    ---@type table<int, StandardItem>
    self.itemList = {}

    -- 滑动条
    self.scrollBar = ScrollBar.New(self.parentWindow)
    self.scrollBar:SetReceiverOfRequestMoveContent(self)
    self.scrollBar:SetSlideLength(self.height)
    self.scrollBar:SetCtrlledContentLength(self.itemHeight * #self.itemList)

    self.needUpdateItemListContentSprite = true

    -- content margins
    self.leftMargin = 5
    self.topMargin = 5
    self.rightMargin = 5
    self.bottomMargin = 5

    -- signals
    -- 选中项信号的接收者
    self.receiverOfSelectedItemChanged = nil
end

function ListView:Update(dt)
    if false == self.isVisible then
        return
    end
    self:MouseEvent()

    -- item
    for _, item in pairs(self.itemList) do
        item:Update(dt)
    end

    if self.needUpdateItemListContentSprite then
        -- 创建背景画布
        local canvas = _Graphics.NewCanvas(self.width - self.leftMargin - self.rightMargin,
                                            self.height - self.topMargin - self.bottomMargin)
        _Graphics.SetCanvas(canvas)

        -- 注意：不可用深度克隆方法，因为StandardItem中的sprite成员初始化时绑定了信号槽，克隆后也会继承之前的信号槽，导致调用SetAttri后使被克隆对象属性改变
        -- 创建临时绘图精灵
        local painterSprite = _Sprite.New()

        -- 更新内容显示板中显示精灵
        for i, item in pairs(self.itemList) do
            painterSprite:SetImage(item:GetCurrentImgCanvas())
            painterSprite:SetAttri("position", 0, self.itemListContentYOffset + self.itemHeight * (i - 1))
            painterSprite:Draw()
        end
        _Graphics.SetCanvas()

        self.itemListContentSprite:SetImage(canvas)
        self.itemListContentSprite:AdjustDimensions()
        self.itemListContentSprite:SetAttri("position", self.posX + self.leftMargin,
                                            self.posY + self.topMargin)
        self.needUpdateItemListContentSprite = false
    end

    self.scrollBar:Update(dt)
end

function ListView:Draw()
    if false == self.isVisible then
        return
    end
    self.bgSprite:Draw()

    -- item list content sprite
    self.itemListContentSprite:Draw()

    self.scrollBar:Draw()
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
        if false == self.itemListContentSprite:CheckPoint(mousePosX, mousePosY) then
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
        if _Mouse.IsPressed(1) then -- 1 is the primary mouse button, 2 is the secondary mouse button and 3 is the middle button
            for _, item in pairs(self.itemList) do
                item:SetDisplayState(StandardItem.DisplayState.Normal)
            end
            hoveringItem:SetDisplayState(StandardItem.DisplayState.Selected)
            -- -- 判断和执行选中项改变事件
            self:judgeAndExecSelectedItemChanged(hoveringItem)
            break
        end

        if StandardItem.DisplayState.Selected == hoveringItem:GetCurrentDisplayState() then
            break
        end
        hoveringItem:SetDisplayState(StandardItem.DisplayState.Hovering)
        break
    end

    -- 判断显示内容是否改变
    for _, item in pairs(self.itemList) do
        if item:IsDisplayStateChanged() then
            self.needUpdateItemListContentSprite = true
            break
        end
    end
end

function ListView:SetPosition(x, y)
    self.bgSprite:SetAttri("position", x, y)
    self.posX = x
    self.posY = y

    -- item
    for i, item in pairs(self.itemList) do
        item:SetPosition(self.posX + self.leftMargin, self.posY + self.topMargin + self.itemHeight * (i - 1))
    end

    self.scrollBar:SetPosition(self.posX + self.width - self.scrollBar:GetWidth() - self.rightMargin,
                            self.posY + self.topMargin)
end

function ListView:SetSize(width, height)
    self.width = width
    self.height = height

    -- 创建背景画布
    local canvas = _Graphics.NewCanvas(self.width, self.height)
    _Graphics.SetCanvas(canvas)

    -- 创建临时绘图精灵
    local painterSprite = _Sprite.New()
    -- 画左上角背景
    painterSprite:SetData(self.leftTopBgImgDate)
    painterSprite:SetAttri("position", 0, 0)
    painterSprite:Draw()
    -- 画上中段背景
    painterSprite:SetData(self.topBgImgDate)
    painterSprite:SetAttri("position", self.leftTopBgImgDate.w, 0)
    local topCenterBgXScale = (self.width - self.leftTopBgImgDate.w - self.rightTopBgImgDate.w) / self.topBgImgDate.w
    painterSprite:SetAttri("scale", topCenterBgXScale, 1)
    painterSprite:Draw()

    -- 画右上角背景
    painterSprite:SetData(self.rightTopBgImgDate)
    painterSprite:SetAttri("position", self.width - self.rightTopBgImgDate.w, 0)
    painterSprite:Draw()

    -- 画左中段背景
    painterSprite:SetData(self.leftBgImgDate)
    painterSprite:SetAttri("position", 0, self.leftTopBgImgDate.h)
    local centerBgYScale = (self.height - self.leftTopBgImgDate.h - self.leftBottomBgImgDate.h) / self.leftBgImgDate.h
    painterSprite:SetAttri("scale", 1, centerBgYScale)
    painterSprite:Draw()
    -- 画中间部分的背景
    painterSprite:SetData(self.centerBgImgDate)
    painterSprite:SetAttri("position", self.leftBgImgDate.w, self.leftTopBgImgDate.h)
    painterSprite:SetAttri("scale", topCenterBgXScale, centerBgYScale)
    painterSprite:Draw()
    -- 画右中段背景
    painterSprite:SetData(self.rightBgImgDate)
    painterSprite:SetAttri("position", self.width - self.rightBgImgDate.w, self.leftTopBgImgDate.h)
    painterSprite:SetAttri("scale", 1, centerBgYScale)
    painterSprite:Draw()

    -- 画左下角背景
    painterSprite:SetData(self.leftBottomBgImgDate)
    painterSprite:SetAttri("position", 0, self.height - self.leftBottomBgImgDate.h)
    painterSprite:Draw()
    -- 画下中段背景
    painterSprite:SetData(self.bottomBgImgDate)
    painterSprite:SetAttri("position", self.leftBottomBgImgDate.w, self.height - self.leftBottomBgImgDate.h)
    painterSprite:SetAttri("scale", topCenterBgXScale, 1)
    painterSprite:Draw()
    -- 画右下角背景
    painterSprite:SetData(self.rightBottomBgImgDate)
    painterSprite:SetAttri("position", self.width - self.rightBottomBgImgDate.w, self.height - self.leftBottomBgImgDate.h)
    painterSprite:Draw()

    _Graphics.SetCanvas()
    self.bgSprite:SetImage(canvas)
    self.bgSprite:AdjustDimensions()

    -- item
    for i, item in pairs(self.itemList) do
        item:SetSize(self.width - self.scrollBar:GetWidth() - self.leftMargin - self.rightMargin, self.itemHeight)
    end

    -- scroll bar
    self.scrollBar:SetSlideLength(self.height - self.topMargin - self.bottomMargin)
    self.scrollBar:SetCtrlledContentLength(self.itemHeight * #self.itemList - self.topMargin - self.bottomMargin)
end

function ListView:SetEnable(enable)
    self.enable = enable
end

function ListView:IsVisible()
    return self.isVisible
end

---@param isVisible bool
function ListView:SetVisible(isVisible)
    self.isVisible = isVisible
end

function ListView:OnRequestMoveContent(xOffset, yOffset)
    print("ListView:OnRequestMoveContent()", xOffset, yOffset)
    self.itemListContentYOffset = yOffset
    self.needUpdateItemListContentSprite = true

    -- item
    for i, item in pairs(self.itemList) do
        item:SetPosition(self.posX + self.leftMargin, self.posY + yOffset + self.topMargin + self.itemHeight * (i - 1))
    end
end

function ListView:SetReceiverOfSelectedItemChanged(obj)
    self.receiverOfSelectedItemChanged = obj
end

---@param selectedItem StandardItem
function ListView:judgeAndExecSelectedItemChanged(selectedItem)
    if nil == self.receiverOfSelectedItemChanged then
        return
    end

    if nil == self.receiverOfSelectedItemChanged.OnSelectedItemChanged then
        return
    end

    self.receiverOfSelectedItemChanged:OnSelectedItemChanged(selectedItem)
end

function ListView:InsertItem(i, text)
    local item = StandardItem.New()
    item:SetText(text)
    table.insert(self.itemList, i, item)

    -- item size
    for i, item in pairs(self.itemList) do
        item:SetSize(self.width - self.scrollBar:GetWidth() - self.leftMargin - self.rightMargin, self.itemHeight)
    end
    -- item position
    for i, item in pairs(self.itemList) do
        item:SetPosition(self.posX + self.leftMargin, self.posY + self.topMargin + self.itemHeight * (i - 1))
    end

    -- scroll bar
    self.scrollBar:SetSlideLength(self.height - self.topMargin - self.bottomMargin)
    self.scrollBar:SetCtrlledContentLength(self.itemHeight * #self.itemList - self.topMargin - self.bottomMargin)
    -- scroll bar position
    self.scrollBar:SetPosition(self.posX + self.width - self.scrollBar:GetWidth() - self.rightMargin,
    self.posY + self.topMargin)

    self.needUpdateItemListContentSprite = true
end

function ListView:AppendItem(text)
    self:InsertItem(#self.itemList + 1, text)
end

---@return itemList table<int, StandardItem>
function ListView:GetItemList()
    return self.itemList
end

return ListView
