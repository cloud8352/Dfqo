--[[
	desc: BasicSettingsWidget class. 基础设置控件
	author: keke <243768648@qq.com>
]] --

local Util = require("util.Util")
local Common = require("UI.ui_common")

local Widget = require("UI.Widget")
local ComboBox = require("UI.ComboBox")
local PushButton = require("UI.PushButton")
local ProgressBar = require("UI.ProgressBar")
local Label = require("UI.Label")

local Keyboard = require("lib.keyboard")
local Table = require("lib.table")

---@class KeySettingsWidget : Widget
local BasicSettingsWidget = require("core.class")(Widget)

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
function BasicSettingsWidget.Create(parentWindow, model)
    -- 用于定义构造函数，解释使用，不做实际用途
    -- 使用class模块后，实际会调用Ctor函数
    return BasicSettingsWidget.New(parentWindow, model)
end

---@param parentWindow Window
---@param model UiModel
function BasicSettingsWidget:Ctor(parentWindow, model)
    -- 父类构造函数
    Widget.Ctor(self, parentWindow)
    
    self.model = model
    local windowSizeScale = Util.GetWindowSizeScale()

    self.goToTitleLabel = Label.Create(parentWindow)
    self.goToTitleLabel:SetSize(300 * windowSizeScale, 35 * windowSizeScale)
    self.goToTitleLabel:SetAlignments({ Label.AlignmentFlag.AlignLeft, Label.AlignmentFlag.AlignVCenter })
    self.goToTitleLabel:SetText("前往：")

    self.retStartGamePageBtn = PushButton.Create(parentWindow)
    initBtnImgPaths(self.retStartGamePageBtn)
    self.retStartGamePageBtn:SetText("开始\n界面")
    self.retStartGamePageBtn:SetSize(60 * windowSizeScale, 60 * windowSizeScale)

    --- music vol bar
    self.musicVolTitleLabel = Label.Create(parentWindow)
    self.musicVolTitleLabel:SetSize(300 * windowSizeScale, 35 * windowSizeScale)
    self.musicVolTitleLabel:SetAlignments({ Label.AlignmentFlag.AlignLeft, Label.AlignmentFlag.AlignVCenter })
    self.musicVolTitleLabel:SetText("背景音量大小：")

    self.musicVolBar = ProgressBar.Create(parentWindow)
    self.musicVolBar:SetSize(500 * windowSizeScale, 15 * windowSizeScale)
    self.musicVolBar:SetBarColor(255, 255, 255, 255)
    self.musicVolBar:SetProgress(0.7)
    self.musicVolBar:EnableChangeByMouseOrTouch(true)

    self.musicVolBarValueLabel = Label.Create(parentWindow)
    self.musicVolBarValueLabel:SetSize(80 * windowSizeScale, 35 * windowSizeScale)
    self.musicVolBarValueLabel:SetText("100%")

    --- sound vol bar
    self.soundVolTitleLabel = Label.Create(parentWindow)
    self.soundVolTitleLabel:SetSize(300 * windowSizeScale, 35 * windowSizeScale)
    self.soundVolTitleLabel:SetAlignments({ Label.AlignmentFlag.AlignLeft, Label.AlignmentFlag.AlignVCenter })
    self.soundVolTitleLabel:SetText("音效音量大小：")

    self.soundVolBar = ProgressBar.Create(parentWindow)
    self.soundVolBar:SetSize(500 * windowSizeScale, 15 * windowSizeScale)
    self.soundVolBar:SetBarColor(255, 255, 255, 255)
    self.soundVolBar:SetProgress(0.7)
    self.soundVolBar:EnableChangeByMouseOrTouch(true)

    self.soundVolBarValueLabel = Label.Create(parentWindow)
    self.soundVolBarValueLabel:SetSize(80 * windowSizeScale, 35 * windowSizeScale)
    self.soundVolBarValueLabel:SetText("100%")

    --- window size percentage
    self.windowSizePercentageTitleLabel = Label.Create(parentWindow)
    self.windowSizePercentageTitleLabel:SetSize(300 * windowSizeScale, 35 * windowSizeScale)
    self.windowSizePercentageTitleLabel:SetAlignments({ Label.AlignmentFlag.AlignLeft, Label.AlignmentFlag.AlignVCenter })
    self.windowSizePercentageTitleLabel:SetText("窗口尺寸比例（重启生效）：")

    self.windowSizePercentageComboBox = ComboBox.Create(parentWindow)
    self.windowSizePercentageComboBox:SetSize(120 * windowSizeScale, 35 * windowSizeScale)
    
    -- connection
    self.retStartGamePageBtn:MocConnectSignal(self.retStartGamePageBtn.Signal_BtnClicked, self)
    self.musicVolBar:MocConnectSignal(self.musicVolBar.Signal_ProgressChanged, self)
    self.soundVolBar:MocConnectSignal(self.soundVolBar.Signal_ProgressChanged, self)
    self.windowSizePercentageComboBox:MocConnectSignal(self.windowSizePercentageComboBox.Signal_SelectedItemChanged, self)

    -- post init
    self.musicVolBar:SetProgress(self.model:GetMusicVol())
    self.soundVolBar:SetProgress(self.model:GetSoundVol())

    for sizeType, percentage in pairs(Common.MapOfWindowSizeEnumToPercentage) do
        local percent = math.floor(percentage * 100)
        local text = tostring(percent) .. "%"
        self.windowSizePercentageComboBox:AppendItemWithText(text)

        if math.abs(self.model:GetWindowSizePercentage() - percentage) < 0.001 then
            self.windowSizePercentageComboBox:SetCurrentIndex(sizeType)
        end
    end
end

function BasicSettingsWidget:Update(dt)
    if not self:IsVisible() then
        return
    end
    if (Widget.IsSizeChanged(self)
        )
    then
    end

    self.goToTitleLabel:Update(dt)
    self.retStartGamePageBtn:Update(dt)
    self.musicVolTitleLabel:Update(dt)
    self.musicVolBar:Update(dt)
    self.musicVolBarValueLabel:Update(dt)
    self.soundVolTitleLabel:Update(dt)
    self.soundVolBar:Update(dt)
    self.soundVolBarValueLabel:Update(dt)
    self.windowSizePercentageTitleLabel:Update(dt)
    self.windowSizePercentageComboBox:Update(dt)

    Widget.Update(self, dt)
end

function BasicSettingsWidget:Draw()
    if not self:IsVisible() then
        return
    end
    Widget.Draw(self)

    self.goToTitleLabel:Draw()
    self.retStartGamePageBtn:Draw()
    self.musicVolTitleLabel:Draw()
    self.musicVolBar:Draw()
    self.musicVolBarValueLabel:Draw()
    self.soundVolTitleLabel:Draw()
    self.soundVolBar:Draw()
    self.soundVolBarValueLabel:Draw()
    self.windowSizePercentageTitleLabel:Draw()
    self.windowSizePercentageComboBox:Draw()
end

--- 连接信号
---@param signal function
---@param obj Object
function BasicSettingsWidget:MocConnectSignal(signal, receiver)
    Widget.MocConnectSignal(self, signal, receiver)
end

---@param signal function
function BasicSettingsWidget:GetReceiverListOfSignal(signal)
    return Widget.GetReceiverListOfSignal(self, signal)
end

---@param name string
function BasicSettingsWidget:SetObjectName(name)
    Widget.SetObjectName(self, name)
end

function BasicSettingsWidget:GetObjectName()
    return Widget.GetObjectName(self)
end

function BasicSettingsWidget:GetParentWindow()
    return Widget.GetParentWindow(self)
end

---@param x int
---@param y int
function BasicSettingsWidget:SetPosition(x, y)
    Widget.SetPosition(self, x, y)
    local windowSizeScale = Util.GetWindowSizeScale()
    local width, _ = self:GetSize()

    local leftMargin = 10 * windowSizeScale
    local topMargin = 0 * windowSizeScale
    local itemMargin = 10 * windowSizeScale

    self.goToTitleLabel:SetPosition(x + leftMargin, y + topMargin)

    local widgetX, widgetY, widgetW, widgetH

    widgetX, widgetY = self.goToTitleLabel:GetPosition()
    widgetW, widgetH = self.goToTitleLabel:GetSize()
    self.retStartGamePageBtn:SetPosition(x + leftMargin, widgetY + widgetH)

    widgetX, widgetY = self.retStartGamePageBtn:GetPosition()
    widgetW, widgetH = self.retStartGamePageBtn:GetSize()
    self.musicVolTitleLabel:SetPosition(x + leftMargin, widgetY + widgetH + itemMargin)

    widgetX, widgetY = self.musicVolTitleLabel:GetPosition()
    widgetW, widgetH = self.musicVolTitleLabel:GetSize()
    local musicVolBarValueLabelW, musicVolBarValueLabelH = self.musicVolBarValueLabel:GetSize()
    local musicVolBarW, musicVolBarH = self.musicVolBar:GetSize()
    self.musicVolBar:SetPosition(x + leftMargin, 
        widgetY + widgetH + musicVolBarValueLabelH / 2 - musicVolBarH / 2)

    self.musicVolBarValueLabel:SetPosition(widgetX + musicVolBarW, widgetY + widgetH)

    --- sound vol bar
    widgetX, widgetY = self.musicVolBarValueLabel:GetPosition()
    widgetW, widgetH = self.musicVolBarValueLabel:GetSize()
    self.soundVolTitleLabel:SetPosition(x + leftMargin, widgetY + widgetH)

    widgetX, widgetY = self.soundVolTitleLabel:GetPosition()
    widgetW, widgetH = self.soundVolTitleLabel:GetSize()
    local soundVolBarValueLabelW, soundVolBarValueLabelH = self.soundVolBarValueLabel:GetSize()
    local soundVolBarW, soundVolBarH = self.soundVolBar:GetSize()
    self.soundVolBar:SetPosition(x + leftMargin, 
        widgetY + widgetH + soundVolBarValueLabelH / 2 - soundVolBarH / 2)

    self.soundVolBarValueLabel:SetPosition(widgetX + soundVolBarW, widgetY + widgetH)

    --- window size percentage
    widgetX, widgetY = self.soundVolBarValueLabel:GetPosition()
    widgetW, widgetH = self.soundVolBarValueLabel:GetSize()
    self.windowSizePercentageTitleLabel:SetPosition(x + leftMargin, widgetY + widgetH)
    
    widgetX, widgetY = self.windowSizePercentageTitleLabel:GetPosition()
    widgetW, widgetH = self.windowSizePercentageTitleLabel:GetSize()
    self.windowSizePercentageComboBox:SetPosition(x + leftMargin, widgetY + widgetH)
end

function BasicSettingsWidget:GetPosition()
    return Widget.GetPosition(self)
end

---@param width int
---@param height int
function BasicSettingsWidget:SetSize(width, height)
    Widget.SetSize(self, width, height)
    local windowSizeScale = Util.GetWindowSizeScale()

end

function BasicSettingsWidget:GetSize()
    return Widget.GetSize(self)
end

function BasicSettingsWidget:IsSizeChanged()
    return Widget.IsSizeChanged(self)
end

function BasicSettingsWidget:SetEnable(enable)
    Widget.SetEnable(self, enable)

    self.goToTitleLabel:SetEnable(enable)
    self.retStartGamePageBtn:SetEnable(enable)
    self.musicVolTitleLabel:SetEnable(enable)
    self.musicVolBar:SetEnable(enable)
    self.musicVolBarValueLabel:SetEnable(enable)
    self.soundVolTitleLabel:SetEnable(enable)
    self.soundVolBar:SetEnable(enable)
    self.soundVolBarValueLabel:SetEnable(enable)
    self.windowSizePercentageTitleLabel:SetEnable(enable)
    self.windowSizePercentageComboBox:SetEnable(enable)
end

function BasicSettingsWidget:IsVisible()
    return Widget.IsVisible(self)
end

---@param isVisible bool
function BasicSettingsWidget:SetVisible(isVisible)
    Widget.SetVisible(self, isVisible)

    self.goToTitleLabel:SetVisible(isVisible)
    self.retStartGamePageBtn:SetVisible(isVisible)
    self.musicVolTitleLabel:SetVisible(isVisible)
    self.musicVolBar:SetVisible(isVisible)
    self.musicVolBarValueLabel:SetVisible(isVisible)
    self.soundVolTitleLabel:SetVisible(isVisible)
    self.soundVolBar:SetVisible(isVisible)
    self.soundVolBarValueLabel:SetVisible(isVisible)
    self.windowSizePercentageTitleLabel:SetVisible(isVisible)
    self.windowSizePercentageComboBox:SetVisible(isVisible)
end

---@param sprite Graphics.Drawable.Sprite
function BasicSettingsWidget:SetBgSprite(sprite)
    Widget.SetBgSprite(self, sprite)
end

function BasicSettingsWidget:GetBgSprite()
    return Widget.GetBgSprite(self)
end

---@param x int
---@param y int
---@return boolean
function BasicSettingsWidget:CheckPoint(x, y)
    return Widget.CheckPoint(self, x, y)
end

--- slots

---@param sender Obj
function BasicSettingsWidget:Slot_BtnClicked(sender)
    if sender == self.retStartGamePageBtn then
        self.model:GoToGameStartPage()
    end
end

---@param sender Obj
---@param value number @0.0 - 1.0
function BasicSettingsWidget:Slot_ProgressChanged(sender, value)
    local percent = math.floor(value * 100)
    local text = tostring(percent) .. "%"
    if sender == self.musicVolBar then
        self.musicVolBarValueLabel:SetText(text)
        self.model:SetMusicVol(value)
    elseif sender == self.soundVolBar then
        self.soundVolBarValueLabel:SetText(text)
        self.model:SetSoundVol(value)
    end
end

---@param sender Obj
---@param item StandardItem
function BasicSettingsWidget:Slot_SelectedItemChanged(sender, item)
    if sender == self.windowSizePercentageComboBox then
        local sizeType = item:GetIndex()
        local percentage = Common.MapOfWindowSizeEnumToPercentage[sizeType]
        self.model:SetWindowSizePercentage(percentage)
    end
end

--- private function


return BasicSettingsWidget
