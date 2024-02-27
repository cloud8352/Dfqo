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
local PushButton = require("UI.PushButton")
local Window = require("UI.Window")
local ListView = require("UI.ListView")
local Label = require("UI.Label")

---@class ComboBox
local ComboBox = require("core.class")()

local DisplayState = {
    Unknown = 0,
    Normal = 1,
    Hovering = 2,
    Pressing = 3,
    Disable = 4,
}

---@param parentWindow Window
function ComboBox:Ctor(parentWindow)
    assert(parentWindow, "must assign parent window")
    ---@type Window
    self.parentWindow = parentWindow

    -- clicked sound
    self.clickedSoundSource = _RESOURCE.NewSource("asset/sound/ui/btn_clicked.wav")

    self.text = ""
    self.width = 30
    self.height = 10
    self.posX = 0
    self.posY = 0
    self.lastDisplayState = DisplayState.Unknown
    self.displayState = DisplayState.Normal
    self.enable = true
    self.isVisible = true

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
    self.iscurrentItemUpdated = true

    -- signals
    -- 选中项信号的接收者
    self.receiverOfSelectedItemChanged = nil

    -- connect
    self.dropDownListView:SetReceiverOfSelectedItemChanged(self)
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
    if self.iscurrentItemUpdated then
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

    self.iscurrentItemUpdated = false
end

function ComboBox:Draw()
    if false == self.isVisible then
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

function ComboBox:SetPosition(x, y)
    self.frameSprite:SetAttri("position", x, y)
    self.textLabel:SetPosition(x + 15, y)
    self.dropDownBtn:SetPosition(x + self.width - self.dropDownBtnRightMargin - self.dropDownBtn:GetWidth(),
        y + self.dropDownBtnTopMargin)
    self.dropDownListView:SetPosition(x, y + self.height - 5)
    self.posX = x
    self.posY = y
end

function ComboBox:SetSize(width, height)
    self.width = width
    self.height = height

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
    self.enable = enable

    self.textLabel:SetEnable(enable)
    self.dropDownBtn:SetEnable(enable)
end

function ComboBox:SetVisible(isVisible)
    self.isVisible = isVisible
    self.dropDownBtn:SetVisible(isVisible)
    self.dropDownListView:SetVisible(isVisible)
end

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

function ComboBox:SetReceiverOfSelectedItemChanged(obj)
    self.receiverOfSelectedItemChanged = obj
end

---@param selectedItem StandardItem
function ComboBox:judgeAndExecSelectedItemChanged(selectedItem)
    if nil == self.receiverOfSelectedItemChanged then
        return
    end

    if nil == self.receiverOfSelectedItemChanged.OnSelectedItemChanged then
        return
    end

    self.receiverOfSelectedItemChanged.OnSelectedItemChanged(self.receiverOfSelectedItemChanged, self, selectedItem)
end

---@param selectedItem StandardItem
function ComboBox:OnSelectedItemChanged(selectedItem)
    self.dropDownListView:SetVisible(false)
    self.currentItem = selectedItem
    self.iscurrentItemUpdated = true

    -- 执行选择项改变回调函数
    self:judgeAndExecSelectedItemChanged(selectedItem)
end

function ComboBox:InsertItem(i, text)
    self.dropDownListView:InsertItem(i, text)
end

function ComboBox:AppendItem(text)
    self.dropDownListView:AppendItem(text)
end

return ComboBox
