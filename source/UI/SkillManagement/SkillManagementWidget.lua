--[[
	desc: SkillManagementWidget class. 技能管理控件
	author: keke <243768648@qq.com>
]] --

local _CONFIG = require("config")
local _Mouse = require("lib.mouse")
local Timer = require("util.gear.timer")
local _MATH = require("lib.math")

local WindowManager = require("UI.WindowManager")
local Common = require("UI.ui_common")
local Util = require("util.Util")

local UiModel = require("UI.ui_model")
local Window = require("UI.Window")
local Widget = require("UI.Widget")
local ListView = require("UI.ListView")
local SkillManagementItem = require("UI.SkillManagement.SkillManagementItem")
local Label = require("UI.Label")
local PushButton = require("UI.PushButton")
local ScrollArea = require("UI.ScrollArea")
local SkillMountDialog = require("UI.SkillManagement.SkillMountDailog")

---@class SkillManagementWidget
local SkillManagementWidget = require("core.class")(Widget)


local LeftPartWidth = 570
local EachPartSpace = 30
local ItemDataKey = "info"

---@param parentWindow Window
---@param model UiModel
function SkillManagementWidget:Ctor(parentWindow, model)
    -- 父类构造函数
    Widget.Ctor(self, parentWindow)
    
    self.model = model

    self.leftMargin = 6 * Util.GetWindowSizeScale()
    self.leftMargin = math.floor(self.leftMargin)
    self.topMargin = self.leftMargin
    self.rightMargin = self.leftMargin
    self.bottomMargin = self.leftMargin

    LeftPartWidth = _MATH.Round(570 * Util.GetWindowSizeScale())
    EachPartSpace = _MATH.Round(30 * Util.GetWindowSizeScale())

    self.skillItemListView = ListView.New(parentWindow)
    self.skillItemListView:SetItemHeight(50 * Util.GetWindowSizeScale())

    ---@type SkillManagementItem
    self.selectedSkillItem = nil
    ---@type SkillManagementItem
    self.lastSelectedSkillItem = nil

    self.selectedSkillTitleLabel = Label.New(parentWindow)

    self.selectedSkillContentLabel = Label.New(parentWindow)
    self.selectedSkillContentLabel:SetAlignments({ Label.AlignmentFlag.AlignLeft, Label.AlignmentFlag.AlignVCenter })
    self.selectedSkillContentScrollArea = ScrollArea.New(parentWindow)
    self.selectedSkillContentScrollArea:SetContentWidget(self.selectedSkillContentLabel)
    
    self.mountBtn = PushButton.New(parentWindow)
    self.mountBtn:SetText("装备到")

    ---@type SkillMountDialog
    self.skillMountDialog = SkillMountDialog.New(self.model)
    self.skillMountDialog:SetVisible(false)
    
    -- connection
    self.skillItemListView:MocConnectSignal(self.skillItemListView.Signal_SelectedItemChanged, self)
    self.mountBtn:MocConnectSignal(self.mountBtn.Signal_Clicked, self)

    -- post init
    local skillResMgrDataList = self.model:GetSkillResMgrDataList()
    for i, skillResMgrData in pairs(skillResMgrDataList) do
        local info = Common.NewSkillInfoFromData(skillResMgrData)
        print(info.iconPath, info.name)

        local item = SkillManagementItem.New()
        item:SetIconPath("icon/skill/" .. skillResMgrData.icon)
        item:SetTitle(skillResMgrData.name)
        item:SetLevel(1)
        item:SetProgress(50, 100)
        item:SetValue(ItemDataKey, info)
        self.skillItemListView:AppendItem(item)
    end

    --- post init
    self.skillItemListView:SetCurrentIndex(1)
end

function SkillManagementWidget:Update(dt)
    self:MouseEvent()

    if (Widget.IsSizeChanged(self)
        )
    then
        self:updateSelectedSkillContentScrollAreaContentWidget()
    end

    self.skillItemListView:Update(dt)
    
    self.selectedSkillTitleLabel:Update(dt)
    self.selectedSkillContentScrollArea:Update(dt)
    -- 当选择项改变时，更新被选择技能项内容滑动条区域中内容控件数据
    if (self.lastSelectedSkillItem ~= self.selectedSkillItem
        )
    then
        self:updateSelectedSkillContentScrollAreaContentWidget()
    end

    self.mountBtn:Update(dt)

    self.lastSelectedSkillItem = self.selectedSkillItem
    Widget.Update(self, dt)
end

function SkillManagementWidget:Draw()
    Widget.Draw(self)

    self.skillItemListView:Draw()

    self.selectedSkillTitleLabel:Draw()
    self.selectedSkillContentScrollArea:Draw()
    self.mountBtn:Draw()
end

function SkillManagementWidget:MouseEvent()
end

---@param x int
---@param y int
function SkillManagementWidget:SetPosition(x, y)
    Widget.SetPosition(self, x, y)

    self.skillItemListView:SetPosition(x + self.leftMargin, y + self.topMargin)

    self.selectedSkillTitleLabel:SetPosition(x + LeftPartWidth, y)

    local _, selectedSkillTitleLabelHeight = self.selectedSkillTitleLabel:GetSize()
    self.selectedSkillContentScrollArea:SetPosition(x + LeftPartWidth, y + selectedSkillTitleLabelHeight)

    local _, selectedSkillContentScrollAreaHeight = self.selectedSkillContentScrollArea:GetSize()
    self.mountBtn:SetPosition(x + LeftPartWidth, 
        y + selectedSkillTitleLabelHeight + selectedSkillContentScrollAreaHeight)
end

---@param width int
---@param height int
function SkillManagementWidget:SetSize(width, height)
    Widget.SetSize(self, width, height)

    self.skillItemListView:SetSize(LeftPartWidth - self.leftMargin, height - self.topMargin - self.bottomMargin)

    local selectedSkillTitleLabelHeight = 30 * Util.GetWindowSizeScale()
    local mountBtnHeight = 30 * Util.GetWindowSizeScale()
    self.selectedSkillTitleLabel:SetSize(width - LeftPartWidth, selectedSkillTitleLabelHeight)
    self.selectedSkillContentScrollArea:SetSize(width - LeftPartWidth,
        height - selectedSkillTitleLabelHeight - mountBtnHeight)
    self.mountBtn:SetSize(80 * Util.GetWindowSizeScale(), mountBtnHeight)
end

function SkillManagementWidget:SetEnable(enable)
    Widget.SetEnable(self, enable)

    self.skillItemListView:SetEnable(enable)
end

--- slots

---@param sender Obj
---@param item StandardItem
function SkillManagementWidget:Slot_SelectedItemChanged(sender, item)
    print("SkillManagementWidget:Slot_SelectedItemChanged(item)", item:GetIndex())

    self.selectedSkillItem = item
end

---@param sender Obj
function SkillManagementWidget:Slot_BtnClicked(sender)
    if sender == self.mountBtn then
        ---@type SkillInfo
        local skillInfo = self.selectedSkillItem:GetValue(ItemDataKey)
        self.skillMountDialog:SetNeedMountingSkillInfo(skillInfo)
        self.skillMountDialog:SetVisible(true)
        -- 移到程序窗口中央
        Util.MoveWindowToCenter(self.skillMountDialog)
    end
end

--- private function

--- 更新被选择技能项内容滑动条区域中内容控件数据
function SkillManagementWidget:updateSelectedSkillContentScrollAreaContentWidget()
    if self.selectedSkillItem == nil then
        return
    end

    ---@type SkillInfo
    local info = self.selectedSkillItem:GetValue(ItemDataKey)
    self.selectedSkillTitleLabel:SetText(info.name)

    local skillInfoContentStr = 
        "冷却时间：" .. tostring(info.cdTime) .. "s" .. "\n" ..
        "消耗mp：" .. tostring(info.mp) .. "\n" ..
        "物理伤害增幅：" .. tostring(info.physicalDamageEnhanceRate * 100) .. "%" .. "\n" ..
        "魔法伤害增幅：" .. tostring(info.magicDamageEnhanceRate * 100) .. "%" .. "\n" ..
        tostring(info.desc)
    self.selectedSkillContentLabel:SetText(skillInfoContentStr)
    local contentW = self.selectedSkillContentScrollArea:GetDisplayContentWidth()
    self.selectedSkillContentLabel:SetSize(contentW, 1)
    self.selectedSkillContentLabel:AdjustHeightByContent()
    self.selectedSkillContentLabel:Update(0)

    -- 显示控件内容改变，需要更新滑动区域显示内容
    self.selectedSkillContentScrollArea:SetNeedUpdateContentSprite(true)
end

return SkillManagementWidget
