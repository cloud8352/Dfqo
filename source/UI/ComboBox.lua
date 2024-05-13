--[[
	desc: ComboBox class.
	author: keke <243768648@qq.com>
	since: 2022-11-25
	alter: 2022-11-25
]] --

local _CONFIG = require("config")
local _RESOURCE = require("lib.resource")
local _Sprite = require("graphics.drawable.sprite")
local _Graphics = require("lib.graphics")
local _Mouse = require("lib.mouse")

local WindowManager = require("UI.WindowManager")

local Widget = require("UI.Widget")
local PushButton = require("UI.PushButton")
local Window = require("UI.Window")
local ListView = require("UI.ListView")
local Label = require("UI.Label")

---@class ComboBox
local ComboBox = require("core.class")(Widget)

local DisplayState = {
    Unknown = 0,
    Normal = 1,
    Hovering = 2,
    Pressing = 3,
    Disable = 4,
}

---@param parentWindow Window
function ComboBox:Ctor(parentWindow)
    Widget.Ctor(self, parentWindow)

    -- clicked sound
    self.clickedSoundSource = _RESOURCE.NewSource("asset/sound/ui/btn_clicked.wav")

    self.text = ""
    self.lastDisplayState = DisplayState.Unknown
    self.displayState = DisplayState.Normal

    -- 背景图片数据
    self.frameSprite = _Sprite.New()
    self.frameSprite:SwitchRect(true) -- 使用矩形
    self.leftFrameImgData = _RESOURCE.GetSpriteData("ui/TitleBar/LeftFrame")
    self.centerFrameImgData = _RESOURCE.GetSpriteData("ui/TitleBar/CenterFrame")
    self.rightFrameImgData = _RESOURCE.GetSpriteData("ui/TitleBar/RightFrame")

    self.textLabel = Label.New(self.parentWindow)
    self.textLabel:SetAlignments({ Label.AlignmentFlag.AlignVCenter, Label.AlignmentFlag.AlignLeft })

    -- 下拉按钮
    self.dropDownBtn = PushButton.New(parentWindow)
    self.dropDownBtn:SetNormalSpriteDataPath("ui/DropDownBtn/Normal")
    self.dropDownBtn:SetHoveringSpriteDataPath("ui/DropDownBtn/Hovering")
    self.dropDownBtn:SetPressingSpriteDataPath("ui/DropDownBtn/Pressing")
    self.dropDownBtn:SetDisabledSpriteDataPath("ui/DropDownBtn/Disabled")

    self.dropDownBtnLeftMargin = 9
    self.dropDownBtnTopMargin = 7
    self.dropDownBtnRightMargin = 6
    self.dropDownBtnBottomMargin = 10

    -- 下拉窗口
    self.dropDownListView = ListView.New(self.parentWindow)
    self.dropDownListView:SetVisible(false)

    ---@type StandardItem
    self.currentItem = nil
    self.isCurrentItemUpdated = true

    -- connect
    self.dropDownListView:MocConnectSignal(self.dropDownListView.Signal_SelectedItemChanged, self)
end

function ComboBox:Update(dt)
    if false == self.isVisible then
        return
    end
    self:MouseEvent()

    self.textLabel:Update(dt)

    self.dropDownBtn:Update(dt)

    self.dropDownListView:Update(dt)

    -- 检查是否需要更新当前显示项
    if self.isCurrentItemUpdated then
        local currentText = ""
        if nil == self.currentItem then
            local itemList = self.dropDownListView:GetItemList()
            if 0 < #itemList then
                self.currentItem = itemList[1]
                currentText = self.currentItem:GetText()
            end
        else
            currentText = self.currentItem:GetText()
        end
        self.textLabel:SetText(currentText)
    end

    self.isCurrentItemUpdated = false

    Widget.Update(self, dt)
end

function ComboBox:Draw()
    Widget.Draw(self)
    if false == Widget.IsVisible(self) then
        return
    end
    self.frameSprite:Draw()
    self.textLabel:Draw()
    self.dropDownBtn:Draw()
    self.dropDownListView:Draw()
end

function ComboBox:MouseEvent()
    -- 检查是否有上层窗口遮挡
    local windowLayerIndex = self.parentWindow:GetWindowLayerIndex()
    if WindowManager.IsMouseCapturedAboveLayer(windowLayerIndex) then
        return
    end

    while true do
        if false == _Mouse.IsPressed(1) then
            break
        end

        local mouseX, mouseY = _Mouse.GetPosition(1, 1)
        if false == self.frameSprite:CheckPoint(mouseX, mouseY) then
            break
        end

        -- 如果点击了框架，则显示或隐藏下拉列表
        self.dropDownListView:SetVisible(not self.dropDownListView:IsVisible())
        break
    end
end

--- 连接信号
---@param signal function
---@param obj Object
function ComboBox:MocConnectSignal(signal, receiver)
    Widget.MocConnectSignal(self, signal, receiver)
end

---@param signal function
function ComboBox:GetReceiverListOfSignal(signal)
    return Widget.GetReceiverListOfSignal(self, signal)
end

---@param name string
function ComboBox:SetObjectName(name)
    Widget.SetObjectName(self, name)
end

function ComboBox:GetObjectName()
    return Widget.GetObjectName(self)
end

function ComboBox:SetPosition(x, y)
    Widget.SetPosition(self, x, y)

    self.frameSprite:SetAttri("position", x, y)
    self.textLabel:SetPosition(x + 15, y)
    self.dropDownBtn:SetPosition(x + self.width - self.dropDownBtnRightMargin - self.dropDownBtn:GetWidth(),
        y + self.dropDownBtnTopMargin)
    self.dropDownListView:SetPosition(x, y + self.height - 5)
end

---@param width int
---@param height int
function ComboBox:SetSize(width, height)
    Widget.SetSize(self, width, height)

    local frameCanvas = self:createFrameCanvasBySize(self.width, self.height)
    self.frameSprite:SetImage(frameCanvas)
    self.frameSprite:AdjustDimensions() -- 设置图片后调整精灵维度

    self.textLabel:SetSize(self.width - 15, self.height)

    -- 下拉按钮
    self.dropDownBtn:SetSize(self.height - self.dropDownBtnTopMargin - self.dropDownBtnBottomMargin, 
        self.height - self.dropDownBtnLeftMargin - self.dropDownBtnRightMargin)

    self.dropDownListView:SetSize(width, 300)
end

function ComboBox:SetEnable(enable)
    Widget.SetEnable(self, enable)

    self.textLabel:SetEnable(enable)
    self.dropDownBtn:SetEnable(enable)
end

function ComboBox:SetVisible(isVisible)
    Widget.SetVisible(self, isVisible)

    self.dropDownBtn:SetVisible(isVisible)
    self.dropDownListView:SetVisible(isVisible)
end

function ComboBox:InsertItemWithText(i, text)
    self.dropDownListView:InsertItemWithText(i, text)
end

function ComboBox:AppendItemWithText(text)
    self.dropDownListView:AppendItemWithText(text)
end

function ComboBox:SetCurrentIndex(index)
    local item = self.dropDownListView:GetItemList()[index]
    self:SetCurrentItem(item)
end

---@param item StandardItem
function ComboBox:SetCurrentItem(item)
    self.dropDownListView:SetVisible(false)
    self.currentItem = item
    self.isCurrentItemUpdated = true

    -- 执行选择项改变回调函数
    self:Signal_SelectedItemChanged(item)
end

--- signals

---@param selectedItem StandardItem
function ComboBox:Signal_SelectedItemChanged(selectedItem)
    print("ComboBox:Signal_SelectedItemChanged()")
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

--- slots

---@param sender Obj
---@param selectedItem StandardItem
function ComboBox:Slot_SelectedItemChanged(sender, selectedItem)
    self:SetCurrentItem(selectedItem)
end

--- private function

function ComboBox:createFrameCanvasBySize(width, height)
    _Graphics.SaveCanvas()
    -- 创建背景画布
    local canvas = _Graphics.NewCanvas(width, height)
    _Graphics.SetCanvas(canvas)

    local allYScale = height / self.centerFrameImgData.h

    -- 创建临时绘图精灵
    local painterSprite = _Sprite.New()
    -- 画左侧图片
    painterSprite:SetData(self.leftFrameImgData)
    painterSprite:SetAttri("position", 0, 0)
    painterSprite:SetAttri("scale", 1, allYScale)
    painterSprite:Draw()
    -- 画中间图片
    painterSprite:SetData(self.centerFrameImgData)
    painterSprite:SetAttri("position", self.leftFrameImgData.w, 0)
    local centerXScale = (width - self.leftFrameImgData.w - self.rightFrameImgData.w) / self.centerFrameImgData.w
    painterSprite:SetAttri("scale", centerXScale, allYScale)
    painterSprite:Draw()

    -- 画右侧图片
    painterSprite:SetData(self.rightFrameImgData)
    painterSprite:SetAttri("position", width - self.rightFrameImgData.w, 0)
    painterSprite:SetAttri("scale", 1, allYScale)
    painterSprite:Draw()

    _Graphics.RestoreCanvas()
    return canvas
end

return ComboBox
