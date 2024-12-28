--[[
	desc: DirPadWidget class.
	author: keke <243768648@qq.com>
]] --

local Widget = require("UI.Widget")
local _CONFIG = require("config")
local WindowManager = require("UI.WindowManager")
local Label = require("UI.Label")
local ArticleViewItem = require("UI.role_info.article_view_item")
local Window = require("UI.Window")
local Common = require("UI.ui_common")
local UiModel = require("UI.ui_model")
local PushButton = require("UI.PushButton")
local DirPadItemWidget = require("UI.TouchComponents.DirPadItemWidget")

local _Mouse = require("lib.mouse")
local Timer = require("util.gear.timer")
local _MATH = require("lib.math")
local Util = require("util.Util")
local TouchLib = require("lib.touch")

---@class DirPadWidget : Widget
local DirPadWidget = require("core.class")(Widget)

local MainKeyBtnWidth = 70
local MainKeyBtnHeight = 80

---@param parentWindow Window
---@param model UiModel
function DirPadWidget:Ctor(parentWindow, model)
    Widget.Ctor(self, parentWindow)

    MainKeyBtnWidth = _MATH.Round(90 * Util.GetWindowSizeScale())
    MainKeyBtnHeight = _MATH.Round(110 * Util.GetWindowSizeScale())

    self.model = model

    self.width = MainKeyBtnWidth + MainKeyBtnHeight * 2
    self.height = self.width

    ---@type table<int, DirPadItemWidget>
    self.mapOfDirToItem = {}
    self.lastPressingDir = Common.DirEnum.Center
    self.pressingDir = Common.DirEnum.Center

    -- 上
    local upKeyItem = DirPadItemWidget.New(parentWindow)
    upKeyItem:SetSize(MainKeyBtnWidth, MainKeyBtnHeight)
    upKeyItem:SetObjectName("up")
    self.mapOfDirToItem[Common.DirEnum.Up] = upKeyItem

    -- 上右
    local upRightKeyItem = DirPadItemWidget.New(parentWindow)
    upRightKeyItem:SetTransparent(true)
    upRightKeyItem:SetSize(MainKeyBtnHeight, MainKeyBtnHeight)
    self.mapOfDirToItem[Common.DirEnum.UpRight] = upRightKeyItem

    -- 右
    local rightKeyItem = DirPadItemWidget.New(parentWindow)
    rightKeyItem:SetSize(MainKeyBtnHeight, MainKeyBtnWidth)
    self.mapOfDirToItem[Common.DirEnum.Right] = rightKeyItem

    -- 右下
    local rightDownKeyItem = DirPadItemWidget.New(parentWindow)
    rightDownKeyItem:SetTransparent(true)
    rightDownKeyItem:SetSize(MainKeyBtnHeight, MainKeyBtnHeight)
    self.mapOfDirToItem[Common.DirEnum.RightDown] = rightDownKeyItem

    -- 下
    local downKeyItem = DirPadItemWidget.New(parentWindow)
    downKeyItem:SetSize(MainKeyBtnWidth, MainKeyBtnHeight)
    self.mapOfDirToItem[Common.DirEnum.Down] = downKeyItem

    -- 下左
    local downLeftKeyItem = DirPadItemWidget.New(parentWindow)
    downLeftKeyItem:SetTransparent(true)
    downLeftKeyItem:SetSize(MainKeyBtnHeight, MainKeyBtnHeight)
    self.mapOfDirToItem[Common.DirEnum.DownLeft] = downLeftKeyItem

    -- 左
    local leftKeyItem = DirPadItemWidget.New(parentWindow)
    leftKeyItem:SetSize(MainKeyBtnHeight, MainKeyBtnWidth)
    self.mapOfDirToItem[Common.DirEnum.Left] = leftKeyItem

    -- 左上
    local leftUpKeyItem = DirPadItemWidget.New(parentWindow)
    leftUpKeyItem:SetTransparent(true)
    leftUpKeyItem:SetSize(MainKeyBtnHeight, MainKeyBtnHeight)
    self.mapOfDirToItem[Common.DirEnum.LeftUp] = leftUpKeyItem

    -- 中心
    local centerItem = DirPadItemWidget.New(parentWindow)
    centerItem:SetSize(MainKeyBtnWidth, MainKeyBtnWidth)
    self.mapOfDirToItem[Common.DirEnum.Center] = centerItem
end

function DirPadWidget:Update(dt)
    if (not self:IsVisible()) then
        return
    end

    self:TouchEvent()

    if (self:IsSizeChanged()
        ) then
        
    end

    for _, item in pairs(self.mapOfDirToItem) do
        item:Update(dt)
    end

    Widget.Update(self, dt)
end

function DirPadWidget:Draw()
    if (not self:IsVisible()) then
        return
    end
    Widget.Draw(self)

    for _, item in pairs(self.mapOfDirToItem) do
        item:Draw()
    end
end

function DirPadWidget:TouchEvent()
    -- 判断鼠标
    while true do
        -- 检查是否有上层窗口遮挡
        local capturedTouchIdList = WindowManager.GetWindowCapturedTouchIdList(self.parentWindow)
        if #capturedTouchIdList == 0
            or self.parentWindow:IsInMoving()
        then
            self:setNoPressing()
            break
        end

        self:updatePressingDir(capturedTouchIdList)
        break
    end
end

function DirPadWidget:SetPosition(x, y)
    Widget.SetPosition(self, x, y)

    -- 上
    local item = self.mapOfDirToItem[Common.DirEnum.Up]
    item:SetPosition(x + MainKeyBtnHeight, y)

    -- 上右
    item = self.mapOfDirToItem[Common.DirEnum.UpRight]
    item:SetPosition(x + MainKeyBtnHeight + MainKeyBtnWidth, y)

    -- 右
    item = self.mapOfDirToItem[Common.DirEnum.Right]
    item:SetPosition(x + MainKeyBtnHeight + MainKeyBtnWidth,
        y + MainKeyBtnHeight)

    -- 右下
    item = self.mapOfDirToItem[Common.DirEnum.RightDown]
    item:SetPosition(x + MainKeyBtnHeight + MainKeyBtnWidth,
        y + MainKeyBtnHeight + MainKeyBtnWidth)

    -- 下
    item = self.mapOfDirToItem[Common.DirEnum.Down]
    item:SetPosition(x + MainKeyBtnHeight,
        y + MainKeyBtnHeight + MainKeyBtnWidth)

    -- 下左
    item = self.mapOfDirToItem[Common.DirEnum.DownLeft]
    item:SetPosition(x, y + MainKeyBtnHeight + MainKeyBtnWidth)

    -- 左
    item = self.mapOfDirToItem[Common.DirEnum.Left]
    item:SetPosition(x, y + MainKeyBtnHeight)

    -- 左上
    item = self.mapOfDirToItem[Common.DirEnum.LeftUp]
    item:SetPosition(x, y)
    
    -- 中心
    item = self.mapOfDirToItem[Common.DirEnum.Center]
    item:SetPosition(x + MainKeyBtnHeight,
        y + MainKeyBtnHeight)
end

---@param dir int
function DirPadWidget:controlMoveByDir(dir)
    self.model:ReleasePlayerKey(Common.InputKeyValueStruct.Up)
    self.model:ReleasePlayerKey(Common.InputKeyValueStruct.Down)
    self.model:ReleasePlayerKey(Common.InputKeyValueStruct.Left)
    self.model:ReleasePlayerKey(Common.InputKeyValueStruct.Right)

    for _, item in pairs(self.mapOfDirToItem) do
        item:SetIsPressing(false)
    end

    local item = nil
    if dir ~= Common.DirEnum.Center then
        item = self.mapOfDirToItem[Common.DirEnum.Center]
        item:SetIsPressing(true)
    end

    if dir == Common.DirEnum.LeftUp
        or dir == Common.DirEnum.Up
        or dir == Common.DirEnum.UpRight
    then
        self.model:PressPlayerKey(Common.InputKeyValueStruct.Up)
        
        item = self.mapOfDirToItem[Common.DirEnum.Up]
        item:SetIsPressing(true)
    end

    if dir == Common.DirEnum.RightDown
        or dir == Common.DirEnum.Down
        or dir == Common.DirEnum.DownLeft
    then
        self.model:PressPlayerKey(Common.InputKeyValueStruct.Down)
        
        item = self.mapOfDirToItem[Common.DirEnum.Down]
        item:SetIsPressing(true)
    end

    if dir == Common.DirEnum.DownLeft
        or dir == Common.DirEnum.Left
        or dir == Common.DirEnum.LeftUp
    then
        self.model:PressPlayerKey(Common.InputKeyValueStruct.Left)
        
        item = self.mapOfDirToItem[Common.DirEnum.Left]
        item:SetIsPressing(true)
    end

    if dir == Common.DirEnum.UpRight
        or dir == Common.DirEnum.Right
        or dir == Common.DirEnum.RightDown
    then
        self.model:PressPlayerKey(Common.InputKeyValueStruct.Right)
        
        item = self.mapOfDirToItem[Common.DirEnum.Right]
        item:SetIsPressing(true)
    end
end

--- 更新移动逻辑
function DirPadWidget:updateMoveLogic()
    local dir = Common.DirEnum.Center
    if self.pressingDir ~= Common.DirEnum.Center then
        dir = self.pressingDir
    end
    if self.pressingDir == Common.DirEnum.Center
        and self.lastPressingDir ~= Common.DirEnum.Center
    then
        dir = self.lastPressingDir
    end

    self:controlMoveByDir(dir)
end

---@param item DirPadItemWidget
---@param idList table<number, string>
---@return string id
function DirPadWidget:getItemTouchedId(item, idList)
    for _, id in pairs(idList) do
        local point = TouchLib.GetPoint(id)
        if (item:CheckPoint(point.x, point.y)) then
            return id
        end
    end

    return ""
end

---@param touchIdList table<number, string>
function DirPadWidget:updatePressingDir(touchIdList)
    local dir = Common.DirEnum.Center
    for dirTmp, item in pairs(self.mapOfDirToItem) do
        local touchedId = self:getItemTouchedId(item, touchIdList)
        if touchedId ~= "" then
            dir = dirTmp
            break
        end
    end

    self:setPressingDir(dir)
end

function DirPadWidget:setPressingDir(dir)
    if dir ~= self.pressingDir then
        self.lastPressingDir = self.pressingDir
        self.pressingDir = dir

        self:updateMoveLogic()
    end
end

function DirPadWidget:setNoPressing()
    if self.pressingDir == Common.DirEnum.Center
        and self.lastPressingDir == Common.DirEnum.Center
    then
        return
    end

    self.lastPressingDir = Common.DirEnum.Center
    self.pressingDir = Common.DirEnum.Center
    self:updateMoveLogic()
end

return DirPadWidget
