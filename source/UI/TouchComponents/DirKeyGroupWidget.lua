--[[
	desc: DirKeyGroupWidget class.
	author: keke <243768648@qq.com>
]] --

local _CONFIG = require("config")
local _Mouse = require("lib.mouse")
local Timer = require("util.gear.timer")
local _MATH = require("lib.math")

local WindowManager = require("UI.WindowManager")
local Widget = require("UI.Widget")
local Label = require("UI.Label")
local ArticleViewItem = require("UI.role_info.article_view_item")
local Window = require("UI.Window")
local Common = require("UI.ui_common")
local UiModel = require("UI.ui_model")
local PushButton = require("UI.PushButton")

local Util = require("util.Util")

---@class DirKeyGroupWidget
local DirKeyGroupWidget = require("core.class")()

local MainKeyBtnWidth = 70
local MainKeyBtnHeight = 80

local DisabledImgPath = "ui/PushButton/Rectangle/Disabled"
local HoveringImgPath = "ui/PushButton/Rectangle/Hovering"
local NormalImgPath = "ui/PushButton/Rectangle/Normal"
local PressingImgPath = "ui/PushButton/Rectangle/Pressing"

---@param btn PushButton
local function initBtnImgPaths(btn)
    btn:SetDisabledSpriteDataPath(DisabledImgPath)
    btn:SetHoveringSpriteDataPath(HoveringImgPath)
    btn:SetNormalSpriteDataPath(NormalImgPath)
    btn:SetPressingSpriteDataPath(PressingImgPath)
end

---@param parentWindow Window
---@param model UiModel
function DirKeyGroupWidget:Ctor(parentWindow, model)
    assert(parentWindow, "must assign parent window")
    -- 父类构造函数
    self.baseWidget = Widget.New(parentWindow)

    MainKeyBtnWidth = _MATH.Round(80 * Util.GetWindowSizeScale())
    MainKeyBtnHeight = _MATH.Round(120 * Util.GetWindowSizeScale())

    self.model = model

    self.baseWidget.width = MainKeyBtnWidth + MainKeyBtnHeight * 2
    self.baseWidget.height = self.baseWidget.width

    -- 上
    self.upKeyBtn = PushButton.New(parentWindow)
    initBtnImgPaths(self.upKeyBtn)
    self.upKeyBtn:EnableClickedSound(false)
    self.upKeyBtn:SetText("up")
    self.upKeyBtn:SetSize(MainKeyBtnWidth, MainKeyBtnHeight)
    self.upKeyBtn:SetObjectName("up")

    -- 上右
    self.upRightKeyBtn = PushButton.New(parentWindow)
    initBtnImgPaths(self.upRightKeyBtn)
    self.upRightKeyBtn:EnableClickedSound(false)
    self.upRightKeyBtn:SetSize(MainKeyBtnHeight, MainKeyBtnHeight)

    -- 右
    self.rightKeyBtn = PushButton.New(parentWindow)
    initBtnImgPaths(self.rightKeyBtn)
    self.rightKeyBtn:EnableClickedSound(false)
    self.rightKeyBtn:SetText("right")
    self.rightKeyBtn:SetSize(MainKeyBtnHeight, MainKeyBtnWidth)

    -- 右下
    self.rightDownKeyBtn = PushButton.New(parentWindow)
    initBtnImgPaths(self.rightDownKeyBtn)
    self.rightDownKeyBtn:EnableClickedSound(false)
    self.rightDownKeyBtn:SetSize(MainKeyBtnHeight, MainKeyBtnHeight)

    -- 下
    self.downKeyBtn = PushButton.New(parentWindow)
    initBtnImgPaths(self.downKeyBtn)
    self.downKeyBtn:EnableClickedSound(false)
    self.downKeyBtn:SetText("down")
    self.downKeyBtn:SetSize(MainKeyBtnWidth, MainKeyBtnHeight)

    -- 下左
    self.downLeftKeyBtn = PushButton.New(parentWindow)
    initBtnImgPaths(self.downLeftKeyBtn)
    self.downLeftKeyBtn:EnableClickedSound(false)
    self.downLeftKeyBtn:SetSize(MainKeyBtnHeight, MainKeyBtnHeight)

    -- 左
    self.leftKeyBtn = PushButton.New(parentWindow)
    initBtnImgPaths(self.leftKeyBtn)
    self.leftKeyBtn:EnableClickedSound(false)
    self.leftKeyBtn:SetText("left")
    self.leftKeyBtn:SetSize(MainKeyBtnHeight, MainKeyBtnWidth)

    -- 左上
    self.leftUpKeyBtn = PushButton.New(parentWindow)
    initBtnImgPaths(self.leftUpKeyBtn)
    self.leftUpKeyBtn:EnableClickedSound(false)
    self.leftUpKeyBtn:SetSize(MainKeyBtnHeight, MainKeyBtnHeight)

    -- connect
    self.upKeyBtn:MocConnectSignal(self.upKeyBtn.Signal_Clicked, self)
    self.upRightKeyBtn:MocConnectSignal(self.upRightKeyBtn.Signal_Clicked, self)
    self.rightKeyBtn:MocConnectSignal(self.rightKeyBtn.Signal_Clicked, self)
    self.rightDownKeyBtn:MocConnectSignal(self.rightDownKeyBtn.Signal_Clicked, self)
    self.downKeyBtn:MocConnectSignal(self.downKeyBtn.Signal_Clicked, self)
    self.downLeftKeyBtn:MocConnectSignal(self.downLeftKeyBtn.Signal_Clicked, self)
    self.leftKeyBtn:MocConnectSignal(self.leftKeyBtn.Signal_Clicked, self)
    self.leftUpKeyBtn:MocConnectSignal(self.leftUpKeyBtn.Signal_Clicked, self)

end

function DirKeyGroupWidget:Update(dt)
    if (not self.baseWidget:IsVisible()) then
        return
    end

    self.baseWidget:Update(dt)
    self:MouseEvent()

    if (self.baseWidget:IsSizeChanged()
        ) then
        
    end

    -- 上
    self.upKeyBtn:Update(dt)

    -- 上右
    self.upRightKeyBtn:Update(dt)

    -- 右
    self.rightKeyBtn:Update(dt)

    -- 右下
    self.rightDownKeyBtn:Update(dt)

    -- 下
    self.downKeyBtn:Update(dt)

    -- 下左
    self.downLeftKeyBtn:Update(dt)

    -- 左
    self.leftKeyBtn:Update(dt)

    -- 左上
    self.leftUpKeyBtn:Update(dt)

    -- 更新移动逻辑
    self:updateMoveLogic()
end

function DirKeyGroupWidget:Draw()
    if (not self.baseWidget:IsVisible()) then
        return
    end
    self.baseWidget:Draw()

    -- 上
    self.upKeyBtn:Draw()

    -- 上右
    self.upRightKeyBtn:Draw()

    -- 右
    self.rightKeyBtn:Draw()

    -- 右下
    self.rightDownKeyBtn:Draw()

    -- 下
    self.downKeyBtn:Draw()

    -- 下左
    self.downLeftKeyBtn:Draw()

    -- 左
    self.leftKeyBtn:Draw()

    -- 左上
    self.leftUpKeyBtn:Draw()
end

function DirKeyGroupWidget:MouseEvent()
    -- 判断鼠标
    while true do
        -- 检查是否有上层窗口遮挡
        local windowLayerIndex = self.baseWidget.parentWindow:GetWindowLayerIndex()
        if WindowManager.IsMouseCapturedAboveLayer(windowLayerIndex)
            or self.baseWidget.parentWindow:IsInMoving() then

            break
        end

        local mousePosX, mousePosY = _Mouse.GetPosition(1, 1)

        -- 是否点击了鼠标右键
        if _Mouse.IsPressed(2) then
        end

        break
    end
end

function DirKeyGroupWidget:SetPosition(x, y)
    self.baseWidget:SetPosition(x, y)

    -- 上
    self.upKeyBtn:SetPosition(self.baseWidget.xPos + MainKeyBtnHeight, self.baseWidget.yPos)

    -- 上右
    self.upRightKeyBtn:SetPosition(self.baseWidget.xPos + MainKeyBtnHeight + MainKeyBtnWidth, self.baseWidget.yPos)

    -- 右
    self.rightKeyBtn:SetPosition(self.baseWidget.xPos + MainKeyBtnHeight + MainKeyBtnWidth,
        self.baseWidget.yPos + MainKeyBtnHeight)

    -- 右下
    self.rightDownKeyBtn:SetPosition(self.baseWidget.xPos + MainKeyBtnHeight + MainKeyBtnWidth,
        self.baseWidget.yPos + MainKeyBtnHeight + MainKeyBtnWidth)

    -- 下
    self.downKeyBtn:SetPosition(self.baseWidget.xPos + MainKeyBtnHeight,
        self.baseWidget.yPos + MainKeyBtnHeight + MainKeyBtnWidth)

    -- 下左
    self.downLeftKeyBtn:SetPosition(self.baseWidget.xPos, self.baseWidget.yPos + MainKeyBtnHeight + MainKeyBtnWidth)

    -- 左
    self.leftKeyBtn:SetPosition(self.baseWidget.xPos, self.baseWidget.yPos + MainKeyBtnHeight)

    -- 左上
    self.leftUpKeyBtn:SetPosition(self.baseWidget.xPos, self.baseWidget.yPos)
end

function DirKeyGroupWidget:SetSize(width, height)
    self.baseWidget:SetSize(width, height)
end

function DirKeyGroupWidget:SetEnable(enable)
    self.baseWidget:SetEnable(enable)
end

function DirKeyGroupWidget:SetVisible(visible)
    self.baseWidget:SetVisible(visible)
end

--- 信号槽 - 当有按钮被点击时
---@param btn PushButton
function DirKeyGroupWidget:Slot_BtnClicked(btn)
    print(btn)

    -- up
    if (
            (self.upKeyBtn == btn and
                not self.upRightKeyBtn:IsPressing() and
                not self.leftUpKeyBtn:IsPressing()
            ) or
            (not self.upKeyBtn:IsPressing() and
                self.upRightKeyBtn == btn and
                not self.leftUpKeyBtn:IsPressing()
            ) or
            (not self.upKeyBtn:IsPressing() and
                not self.upRightKeyBtn:IsPressing() and
                self.leftUpKeyBtn == btn
            )
        ) then
        self.model:ReleasePlayerKey(Common.InputKeyValueStruct.Up)
    end

    -- down
    if (
            (self.rightDownKeyBtn == btn and
                not self.downKeyBtn:IsPressing() and
                not self.downLeftKeyBtn:IsPressing()
            ) or
            (not self.rightDownKeyBtn:IsPressing() and
                self.downKeyBtn == btn and
                not self.downLeftKeyBtn:IsPressing()
            ) or
            (not self.rightDownKeyBtn:IsPressing() and
                not self.downKeyBtn:IsPressing() and
                self.downLeftKeyBtn == btn
            )
        ) then
        self.model:ReleasePlayerKey(Common.InputKeyValueStruct.Down)
    end

    -- left
    if (
            (self.downLeftKeyBtn == btn and
                not self.leftKeyBtn:IsPressing() and
                not self.leftUpKeyBtn:IsPressing()
            ) or
            (not self.downLeftKeyBtn:IsPressing() and
                self.leftKeyBtn == btn and
                not self.leftUpKeyBtn:IsPressing()
            ) or
            (not self.downLeftKeyBtn:IsPressing() and
                not self.leftKeyBtn:IsPressing() and
                self.leftUpKeyBtn == btn
            )
        ) then
        self.model:ReleasePlayerKey(Common.InputKeyValueStruct.Left)
    end

    -- right
    if (
            (self.upRightKeyBtn == btn and
                not self.rightKeyBtn:IsPressing() and
                not self.rightDownKeyBtn:IsPressing()
            ) or
            (not self.upRightKeyBtn:IsPressing() and
                self.rightKeyBtn == btn and
                not self.rightDownKeyBtn:IsPressing()
            ) or
            (not self.upRightKeyBtn:IsPressing() and
                not self.rightKeyBtn:IsPressing() and
                self.rightDownKeyBtn == btn
            )
        ) then
        self.model:ReleasePlayerKey(Common.InputKeyValueStruct.Right)
    end
end

--- 更新移动逻辑
function DirKeyGroupWidget:updateMoveLogic()
    if (self.upKeyBtn:IsPressing() or
            self.upRightKeyBtn:IsPressing() or
            self.leftUpKeyBtn:IsPressing()
        ) then
        self.model:PressPlayerKey(Common.InputKeyValueStruct.Up)
    end

    if (self.rightDownKeyBtn:IsPressing() or
            self.downKeyBtn:IsPressing() or
            self.downLeftKeyBtn:IsPressing()
        ) then
        self.model:PressPlayerKey(Common.InputKeyValueStruct.Down)
    end

    if (self.downLeftKeyBtn:IsPressing() or
            self.leftKeyBtn:IsPressing() or
            self.leftUpKeyBtn:IsPressing()
        ) then
        self.model:PressPlayerKey(Common.InputKeyValueStruct.Left)
    end

    if (self.upRightKeyBtn:IsPressing() or
            self.rightKeyBtn:IsPressing() or
            self.rightDownKeyBtn:IsPressing()
        ) then
        self.model:PressPlayerKey(Common.InputKeyValueStruct.Right)
    end
end

return DirKeyGroupWidget
