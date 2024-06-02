--[[
	desc: KeySettingsWidget class. 按键设置控件
	author: keke <243768648@qq.com>
]] --

local Keyboard = require("lib.keyboard")
local Table = require("lib.table")

local Util = require("util.Util")

local Widget = require("UI.Widget")
local ListView = require("UI.ListView")
local KeySettingsItem = require("UI.Settings.KeySettingsItem")
local PushButton = require("UI.PushButton")

---@class KeySettingsWidget
local KeySettingsWidget = require("core.class")(Widget)

local MapOfFunNameToTransStr = {
    up = "向上",
    down = "向下",
    left = "向左",
    right = "向右",
    getItem = "拾取",
    goNext = "goNext",
    talk = "对话",
    normalAttack = "普通攻击",
    jump = "跳跃",
    counterAttack = "基础技能",
    skill1 = "技能1",
    skill2 = "技能2",
    skill3 = "技能3",
    skill4 = "技能4",
    skill5 = "技能5",
    skill6 = "技能6",
    skill7 = "技能7",
    skill8 = "技能8",
    skill9 = "技能9",
    skill10 = "技能10",
    skill11 = "技能11",
    skill12 = "技能12",
    suptool1 = "suptool1",
    suptool2 = "suptool2",
    dash = "dash"
}

-- 按照此功能键列表 排序显示列表
local SortedFunNameList = {
    "up",
    "down",
    "left",
    "right",
    "getItem",
    "goNext",
    "talk",
    "normalAttack",
    "jump",
    "counterAttack",
    "skill1",
    "skill2",
    "skill3",
    "skill4",
    "skill5",
    "skill6",
    "skill7",
    "skill8",
    "skill9",
    "skill10",
    "skill11",
    "skill12",
    "suptool1",
    "suptool2",
    "dash"
}

local ItemDataKey = "FunName"

---@param parentWindow Window
---@param model UiModel
function KeySettingsWidget:Ctor(parentWindow, model)
    -- 父类构造函数
    Widget.Ctor(self, parentWindow)
    
    self.model = model

    self.bottomMargin = 8 * Util.GetWindowSizeScale()

    self.listView = ListView.New(parentWindow)
    self.listView:SetItemHeight(45 * Util.GetWindowSizeScale())

    self.listViewSaveBtnVSpace = 9 * Util.GetWindowSizeScale()
    self.saveBtn = PushButton.New(parentWindow)
    self.saveBtn:SetText("保存")

    self.cancelBtn = PushButton.New(parentWindow)
    self.cancelBtn:SetText("取消")

    ---@type KeySettingsItem
    self.lastSelectedItem = nil

    self.needUpdateKey = false
    ---@type table<string, string>
    self.tmpConfigMapOfFunNameToKey = {}
    
    -- connection
    self.listView:MocConnectSignal(self.listView.Signal_SelectedItemChanged, self)
    Keyboard.AddListener("onPressed", self, function(my, key)
        self:Slot_KeyboardKeyPressed(key)
    end)

    self.saveBtn:MocConnectSignal(self.saveBtn.Signal_BtnClicked, self)
    self.cancelBtn:MocConnectSignal(self.cancelBtn.Signal_BtnClicked, self)

    -- post init
    self:reloadFunKeyConfig()
end

function KeySettingsWidget:Update(dt)
    if not self:IsVisible() then
        return
    end
    if (Widget.IsSizeChanged(self)
        )
    then
    end

    self.listView:Update(dt)
    self.saveBtn:Update(dt)
    self.cancelBtn:Update(dt)

    Widget.Update(self, dt)
end

function KeySettingsWidget:Draw()
    if not self:IsVisible() then
        return
    end
    Widget.Draw(self)

    self.listView:Draw()
    self.saveBtn:Draw()
    self.cancelBtn:Draw()
end

--- 连接信号
---@param signal function
---@param obj Object
function KeySettingsWidget:MocConnectSignal(signal, receiver)
    Widget.MocConnectSignal(self, signal, receiver)
end

---@param signal function
function KeySettingsWidget:GetReceiverListOfSignal(signal)
    return Widget.GetReceiverListOfSignal(self, signal)
end

---@param name string
function KeySettingsWidget:SetObjectName(name)
    Widget.SetObjectName(self, name)
end

function KeySettingsWidget:GetObjectName()
    return Widget.GetObjectName(self)
end

function KeySettingsWidget:GetParentWindow()
    return Widget.GetParentWindow(self)
end

---@param x int
---@param y int
function KeySettingsWidget:SetPosition(x, y)
    Widget.SetPosition(self, x, y)
    local windowSizeScale = Util.GetWindowSizeScale()
    local width, _ = self:GetSize()

    self.listView:SetPosition(x, y)

    local _, listViewHeight = self.listView:GetSize()
    local saveBtnWidth, _ = self.saveBtn:GetSize()
    self.saveBtn:SetPosition(x + width / 2 - saveBtnWidth - 20 * windowSizeScale,
        y + listViewHeight + self.listViewSaveBtnVSpace)

    self.cancelBtn:SetPosition(x + width / 2 + 20 * windowSizeScale,
        y + listViewHeight + self.listViewSaveBtnVSpace)
end

function KeySettingsWidget:GetPosition()
    return Widget.GetPosition(self)
end

---@param width int
---@param height int
function KeySettingsWidget:SetSize(width, height)
    Widget.SetSize(self, width, height)
    local windowSizeScale = Util.GetWindowSizeScale()

    local saveBtnHeight = 30 * windowSizeScale
    self.listView:SetSize(width, height - saveBtnHeight - self.listViewSaveBtnVSpace - self.bottomMargin)
    self.saveBtn:SetSize(80 * windowSizeScale, saveBtnHeight)
    self.cancelBtn:SetSize(80 * windowSizeScale, saveBtnHeight)
end

function KeySettingsWidget:GetSize()
    return Widget.GetSize(self)
end

function KeySettingsWidget:IsSizeChanged()
    return Widget.IsSizeChanged(self)
end

function KeySettingsWidget:SetEnable(enable)
    Widget.SetEnable(self, enable)

    self.listView:SetEnable(enable)
    self.saveBtn:SetEnable(enable)
    self.cancelBtn:SetEnable(enable)
end

function KeySettingsWidget:IsVisible()
    return Widget.IsVisible(self)
end

---@param isVisible bool
function KeySettingsWidget:SetVisible(isVisible)
    Widget.SetVisible(self, isVisible)
end

---@param sprite Graphics.Drawable.Sprite
function KeySettingsWidget:SetBgSprite(sprite)
    Widget.SetBgSprite(self, sprite)
end

function KeySettingsWidget:GetBgSprite()
    return Widget.GetBgSprite(self)
end

---@param x int
---@param y int
---@return boolean
function KeySettingsWidget:CheckPoint(x, y)
    return Widget.CheckPoint(self, x, y)
end

--- slots

---@param sender Obj
---@param item StandardItem
function KeySettingsWidget:Slot_SelectedItemChanged(sender, item)
    if self.lastSelectedItem == item then
        self.needUpdateKey = not self.needUpdateKey
    else
        self.needUpdateKey = true
    end
    ---@type KeySettingsItem
    local itemTmp = item
    if self.needUpdateKey then
        itemTmp:SetRightLabelText("【请按下按键】")
    else
        self:restoreItemRightLabelText(itemTmp)
    end

    -- 刷新上个选中的显示项数据
    if self.lastSelectedItem and self.lastSelectedItem ~= item then
        self:restoreItemRightLabelText(self.lastSelectedItem)
    end

    self.lastSelectedItem = item
end

---@param key string
function KeySettingsWidget:Slot_KeyboardKeyPressed(key)
    if not self:IsVisible() then
        return
    end

    if self.needUpdateKey then
        self.needUpdateKey = false

        -- 置空已经设置了相同按键的功能键
        for i, item in pairs(self.listView:GetItemList()) do
            ---@type KeySettingsItem
            local itemTmp = item
            ---@type string
            local funNameTmp = itemTmp:GetValue(ItemDataKey)
            local keyTmp = self.tmpConfigMapOfFunNameToKey[funNameTmp]
            if keyTmp == key then
                self.tmpConfigMapOfFunNameToKey[funNameTmp] = ""
                itemTmp:SetRightLabelText("")
            end
        end

        -- save config tmp
        ---@type KeySettingsItem
        local currentItem = self.listView:GetCurrentItem()
        ---@type string
        local currentItemFunName = currentItem:GetValue(ItemDataKey)
        self.tmpConfigMapOfFunNameToKey[currentItemFunName] = key

        currentItem:SetRightLabelText(key)
    end
end


---@param sender Obj
function KeySettingsWidget:Slot_BtnClicked(sender)
    if sender == self.saveBtn then
        self.model:SaveConfigMapOfFunNameToKey(self.tmpConfigMapOfFunNameToKey)

        self.needUpdateKey = false
        ---@type KeySettingsItem
        local currentItem = self.listView:GetCurrentItem()
        self:restoreItemRightLabelText(currentItem)
    end

    if sender == self.cancelBtn then
        self.needUpdateKey = false
        self:reloadFunKeyConfig()
    end
end

--- private function

function KeySettingsWidget:reloadFunKeyConfig()
    self.listView:ClearAllItems()
    local configMapOfFunNameToKey = self.model:GetConfigMapOfFunNameToKey()
    for _, funName in pairs(SortedFunNameList) do    
        local item = KeySettingsItem.New()
        item:SetValue(ItemDataKey, funName)
        local name = MapOfFunNameToTransStr[funName]
        item:SetLeftLabelText(name)
        local key = configMapOfFunNameToKey[funName]
        item:SetRightLabelText(key)
        self.listView:AppendItem(item)
    end

    -- 拷贝一份按键配置
    self.tmpConfigMapOfFunNameToKey = Table.DeepClone(configMapOfFunNameToKey)
end

---@param item KeySettingsItem
function KeySettingsWidget:restoreItemRightLabelText(item)
    if item == nil then
        return
    end

    local lastSelectedItemIndex = item:GetIndex()
    local funName = SortedFunNameList[lastSelectedItemIndex]
    local key = self.tmpConfigMapOfFunNameToKey[funName]
    item:SetRightLabelText(key)
end

return KeySettingsWidget
