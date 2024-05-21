--[[
	desc: SkillDockViewFrame class. 技能托盘显示框架
	author: keke <243768648@qq.com>
	since: 2023-4-15
	alter: 2023-4-15
]] --

local _CONFIG = require("config")
local _Mouse = require("lib.mouse")
local Timer = require("util.gear.timer")
local _MATH = require("lib.math")
local _Graphics = require("lib.graphics")

local Widget = require("UI.Widget")
local WindowManager = require("UI.WindowManager")
local Label = require("UI.Label")
local SkillDockViewItem = require("UI.SkillDockViewItem")
local Window = require("UI.Window")
local Common = require("UI.ui_common")
local UiModel = require("UI.ui_model")

local Util = require("util.Util")

---@class SkillDockViewFrame
local SkillDockViewFrame = require("core.class")(Widget)

local ItemSpace = 1
local TimeOfWaiteToShowItemTip = 1000 * 0.5 -- 显示技能提示信息需要等待的时间，单位：ms

---@param parentWindow Window
---@param model UiModel
function SkillDockViewFrame:Ctor(parentWindow, model)
    Widget.Ctor(self, parentWindow)

    self.model = model

    local defaultItemWidth = 45 * Util.GetWindowSizeScale()
    defaultItemWidth = _MATH.Round(defaultItemWidth)
    local width = defaultItemWidth * 6 + ItemSpace * 5
    local height = ItemSpace + defaultItemWidth * 2
    self:SetSize(width, height)

    ---- skill item background
    local itemBgImgPath = "ui/WindowFrame/CenterBg"
    ---@type table<string, Label>
    self.mapOfTagToSkillViewItemBg = {}
    -- skill1
    local bgLabel = Label.New(parentWindow)
    bgLabel:SetIconSpriteDataPath(itemBgImgPath)
    self.mapOfTagToSkillViewItemBg["skill1"] = bgLabel
    -- skill2
    bgLabel = Label.New(parentWindow)
    bgLabel:SetIconSpriteDataPath(itemBgImgPath)
    self.mapOfTagToSkillViewItemBg["skill2"] = bgLabel
    -- skill3
    bgLabel = Label.New(parentWindow)
    bgLabel:SetIconSpriteDataPath(itemBgImgPath)
    self.mapOfTagToSkillViewItemBg["skill3"] = bgLabel
    -- skill4
    bgLabel = Label.New(parentWindow)
    bgLabel:SetIconSpriteDataPath(itemBgImgPath)
    self.mapOfTagToSkillViewItemBg["skill4"] = bgLabel
    -- skill5
    bgLabel = Label.New(parentWindow)
    bgLabel:SetIconSpriteDataPath(itemBgImgPath)
    self.mapOfTagToSkillViewItemBg["skill5"] = bgLabel
    -- skill6
    bgLabel = Label.New(parentWindow)
    bgLabel:SetIconSpriteDataPath(itemBgImgPath)
    self.mapOfTagToSkillViewItemBg["skill6"] = bgLabel
    -- skill7
    bgLabel = Label.New(parentWindow)
    bgLabel:SetIconSpriteDataPath(itemBgImgPath)
    self.mapOfTagToSkillViewItemBg["skill7"] = bgLabel
    -- skill8
    bgLabel = Label.New(parentWindow)
    bgLabel:SetIconSpriteDataPath(itemBgImgPath)
    self.mapOfTagToSkillViewItemBg["skill8"] = bgLabel
    -- skill9
    bgLabel = Label.New(parentWindow)
    bgLabel:SetIconSpriteDataPath(itemBgImgPath)
    self.mapOfTagToSkillViewItemBg["skill9"] = bgLabel
    -- skill10
    bgLabel = Label.New(parentWindow)
    bgLabel:SetIconSpriteDataPath(itemBgImgPath)
    self.mapOfTagToSkillViewItemBg["skill10"] = bgLabel
    -- skill11
    bgLabel = Label.New(parentWindow)
    bgLabel:SetIconSpriteDataPath(itemBgImgPath)
    self.mapOfTagToSkillViewItemBg["skill11"] = bgLabel
    -- skill12
    bgLabel = Label.New(parentWindow)
    bgLabel:SetIconSpriteDataPath(itemBgImgPath)
    self.mapOfTagToSkillViewItemBg["skill12"] = bgLabel


    -- skill item
    local itemImgPath = ""
    ---@type table<string, SkillDockViewItem>
    self.mapOfTagToSkillViewItem = {}
    -- skill1
    local item = SkillDockViewItem.New(parentWindow)
    item:SetIconSpriteDataPath(itemImgPath)
    self.mapOfTagToSkillViewItem["skill1"] = item
    -- skill2
    item = SkillDockViewItem.New(parentWindow)
    item:SetIconSpriteDataPath(itemImgPath)
    self.mapOfTagToSkillViewItem["skill2"] = item
    -- skill3
    item = SkillDockViewItem.New(parentWindow)
    item:SetIconSpriteDataPath(itemImgPath)
    self.mapOfTagToSkillViewItem["skill3"] = item
    -- skill4
    item = SkillDockViewItem.New(parentWindow)
    item:SetIconSpriteDataPath(itemImgPath)
    self.mapOfTagToSkillViewItem["skill4"] = item
    -- skill5
    item = SkillDockViewItem.New(parentWindow)
    item:SetIconSpriteDataPath(itemImgPath)
    self.mapOfTagToSkillViewItem["skill5"] = item
    -- skill6
    item = SkillDockViewItem.New(parentWindow)
    item:SetIconSpriteDataPath(itemImgPath)
    self.mapOfTagToSkillViewItem["skill6"] = item
    -- skill7
    item = SkillDockViewItem.New(parentWindow)
    item:SetIconSpriteDataPath(itemImgPath)
    self.mapOfTagToSkillViewItem["skill7"] = item
    -- skill8
    item = SkillDockViewItem.New(parentWindow)
    item:SetIconSpriteDataPath(itemImgPath)
    self.mapOfTagToSkillViewItem["skill8"] = item
    -- skill9
    item = SkillDockViewItem.New(parentWindow)
    item:SetIconSpriteDataPath(itemImgPath)
    self.mapOfTagToSkillViewItem["skill9"] = item
    -- skill10
    item = SkillDockViewItem.New(parentWindow)
    item:SetIconSpriteDataPath(itemImgPath)
    self.mapOfTagToSkillViewItem["skill10"] = item
    -- skill11
    item = SkillDockViewItem.New(parentWindow)
    item:SetIconSpriteDataPath(itemImgPath)
    self.mapOfTagToSkillViewItem["skill11"] = item
    -- skill12
    item = SkillDockViewItem.New(parentWindow)
    item:SetIconSpriteDataPath(itemImgPath)
    self.mapOfTagToSkillViewItem["skill12"] = item

    -- hovering item frame Label
    self.hoveringItemTag = ""
    self.lastHoveringItemTag = ""
    self.hoveringItemFrameLabel = Label.New(parentWindow)
    self.hoveringItemFrameLabel:SetIconSpriteDataPath("ui/WindowFrame/HoveringItemFrame")
    self.hoveringItemFrameLabel:SetVisible(false)

    -- item Hovering Timer
    self.itemHoveringTimer = Timer.New()
    self.isShowHoveringItemTip = false -- 是否显示悬浮技能项的提示信息
    self.lastIsShowHoveringItemTip = false

    --- post init
    self:ReloadSkillsViewData()
    self:updateAllItemsPosition()
    self:updateAllItemsSize()
end

function SkillDockViewFrame:Update(dt)
    if (not self:IsVisible()) then
        return
    end
    self:MouseEvent()

    if (self:IsSizeChanged()
        )
    then
        self:updateAllItemsSize()
    end

    if (self.lastHoveringItemTag ~= self.hoveringItemTag) then
        self:updateHoveringItemFrameData()
    end

    -- 判断定时器
    self.itemHoveringTimer:Update(dt)
    if self.itemHoveringTimer.isRunning or "" == self.hoveringItemTag then
        self.isShowHoveringItemTip = false
    elseif self.itemHoveringTimer.isRunning and "" ~= self.hoveringItemTag then
        self.isShowHoveringItemTip = false
    else
        self.isShowHoveringItemTip = true
    end
    -- 更新悬浮提示
    if self.lastIsShowHoveringItemTip ~= self.isShowHoveringItemTip then
        self:updateHoveringItemTipWindowData()
    end

    -- skill item bg
    for k, v in pairs(self.mapOfTagToSkillViewItemBg) do
        v:Update(dt)
    end

    ---- skill item
    -- 更新技能显示项冷却时间
    local mapOfTagToSkillObj = self.model:GetMapOfTagToSkillObj()
    for k, v in pairs(mapOfTagToSkillObj) do
        -- k 为 tag，即配置中的键
        local item = self.mapOfTagToSkillViewItem[k]
        if nil == item then
            goto continue
        end

        local progress = v:GetProcess();
        if 1.0 <= progress then
            goto continue
        end
        item:SetCoolDownProgress(progress)

        ::continue::
    end

    -- 更新技能显示项
    for k, v in pairs(self.mapOfTagToSkillViewItem) do
        v:Update(dt)
    end

    self.hoveringItemFrameLabel:Update(dt)

    --- 更新上次和当前的所有状态
    Widget.Update(self, dt)

    self.lastHoveringItemTag = self.hoveringItemTag
    self.lastIsShowHoveringItemTip = self.isShowHoveringItemTip
end

function SkillDockViewFrame:Draw()
    if (not self:IsVisible()) then
        return
    end
    Widget.Draw(self)

    -- skill item bg
    for k, v in pairs(self.mapOfTagToSkillViewItemBg) do
        v:Draw()
    end
    -- skill item
    for k, v in pairs(self.mapOfTagToSkillViewItem) do
        v:Draw()
    end

    self.hoveringItemFrameLabel:Draw()
end

function SkillDockViewFrame:MouseEvent()
    -- 判断鼠标
    while true do
        -- 检查是否有上层窗口遮挡
        local parentWindow = self:GetParentWindow()
        local windowLayerIndex = parentWindow:GetWindowLayerIndex()
        if WindowManager.IsMouseCapturedAboveLayer(windowLayerIndex) then
            self.hoveringItemTag = ""
            self.itemHoveringTimer:Exit()
            break
        end

        local mousePosX, mousePosY = _Mouse.GetPosition(1, 1)
        -- 寻找鼠标悬停处的显示项标签
        local hoveringItemTag = ""
        for tag, label in pairs(self.mapOfTagToSkillViewItemBg) do
            if label:CheckPoint(mousePosX, mousePosY) then
                hoveringItemTag = tag
                break
            end
        end

        -- 判断是否点击某一个技能项
        if hoveringItemTag ~= "" and _Mouse.IsPressed(1) then
            self:Signal_ItemClicked(hoveringItemTag)
        end

        if hoveringItemTag == self.hoveringItemTag then
            break
        end

        if "" == hoveringItemTag then
            self.hoveringItemTag = ""
            self.itemHoveringTimer:Exit()
        else
            self.hoveringItemTag = hoveringItemTag

            -- 开启计时鼠标悬浮时间
            self.itemHoveringTimer:Enter(TimeOfWaiteToShowItemTip)
        end

        break
    end
end

--- 连接信号
---@param signal function
---@param obj Object
function SkillDockViewFrame:MocConnectSignal(signal, receiver)
    Widget.MocConnectSignal(self, signal, receiver)
end

---@param signal function
function SkillDockViewFrame:GetReceiverListOfSignal(signal)
    return Widget.GetReceiverListOfSignal(self, signal)
end

---@param name string
function SkillDockViewFrame:SetObjectName(name)
    Widget.SetObjectName(self, name)
end

function SkillDockViewFrame:GetObjectName()
    return Widget.GetObjectName(self)
end

function SkillDockViewFrame:GetParentWindow()
    return Widget.GetParentWindow(self)
end

function SkillDockViewFrame:SetPosition(x, y)
    Widget.SetPosition(self, x, y)

    self:updateAllItemsPosition()
end

function SkillDockViewFrame:GetPosition()
    return Widget.GetPosition(self)
end

function SkillDockViewFrame:SetSize(width, height)
    Widget.SetSize(self, width, height)
end

function SkillDockViewFrame:GetSize()
    return Widget.GetSize(self)
end

function SkillDockViewFrame:IsSizeChanged()
    return Widget.IsSizeChanged(self)
end

function SkillDockViewFrame:SetEnable(enable)
    Widget.SetEnable(self, enable)
end

function SkillDockViewFrame:IsVisible()
    return Widget.IsVisible(self)
end

---@param isVisible bool
function SkillDockViewFrame:SetVisible(isVisible)
    Widget.SetVisible(self, isVisible)
end

---@param x int
---@param y int
---@return boolean
function SkillDockViewFrame:CheckPoint(x, y)
    return Widget.CheckPoint(self, x, y)
end

function SkillDockViewFrame:ReloadSkillsViewData()
    local mapOfTagToSkillObj = self.model:GetMapOfTagToSkillObj()
    for k, v in pairs(mapOfTagToSkillObj) do
        -- k 为 tag，即配置中的键
        local item = self.mapOfTagToSkillViewItem[k]
        if nil == item then
            goto continue
        end
        item:SetIconSpriteDataPath("icon/skill/" .. v:GetData().icon)

        local key = self.model:GetSkillKeyByTag(k)
        if nil == key then
            key = ""
        end
        item:SetKey(key)

        ::continue::
    end
end

--- slots

--- signals

---@param skillTag string
function SkillDockViewFrame:Signal_ItemClicked(skillTag)
    print("SkillDockViewFrame:Signal_ItemClicked(skillTag)")
    local receiverList = self:GetReceiverListOfSignal(self.Signal_ItemClicked)
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.Slot_ItemClicked
        if func == nil then
            goto continue
        end

        func(receiver, self, skillTag)

        ::continue::
    end
end

--- private function

function SkillDockViewFrame:updateAllItemsPosition()
    -- item background
    local _, height = self:GetSize()
    local xPos, yPos = self:GetPosition()
    local itemWidth = (height - ItemSpace) / 2
    for k, v in pairs(self.mapOfTagToSkillViewItemBg) do
        if "skill1" == k then
            v:SetPosition(xPos, yPos + itemWidth + ItemSpace)
        end
        if "skill2" == k then
            v:SetPosition(xPos + (ItemSpace + itemWidth) * 1, yPos + itemWidth + ItemSpace)
        end
        if "skill3" == k then
            v:SetPosition(xPos + (ItemSpace + itemWidth) * 2, yPos + itemWidth + ItemSpace)
        end
        if "skill4" == k then
            v:SetPosition(xPos + (ItemSpace + itemWidth) * 3, yPos + itemWidth + ItemSpace)
        end
        if "skill5" == k then
            v:SetPosition(xPos + (ItemSpace + itemWidth) * 4, yPos + itemWidth + ItemSpace)
        end
        if "skill6" == k then
            v:SetPosition(xPos + (ItemSpace + itemWidth) * 5, yPos + itemWidth + ItemSpace)
        end
        if "skill7" == k then
            v:SetPosition(xPos, yPos)
        end
        if "skill8" == k then
            v:SetPosition(xPos + (ItemSpace + itemWidth) * 1, yPos)
        end
        if "skill9" == k then
            v:SetPosition(xPos + (ItemSpace + itemWidth) * 2, yPos)
        end
        if "skill10" == k then
            v:SetPosition(xPos + (ItemSpace + itemWidth) * 3, yPos)
        end
        if "skill11" == k then
            v:SetPosition(xPos + (ItemSpace + itemWidth) * 4, yPos)
        end
        if "skill12" == k then
            v:SetPosition(xPos + (ItemSpace + itemWidth) * 5, yPos)
        end
    end

    -- item
    for k, v in pairs(self.mapOfTagToSkillViewItem) do
        local skillItemBg = self.mapOfTagToSkillViewItemBg[k]
        local x, y = skillItemBg:GetPosition()
        v:SetPosition(x, y)
    end
end

function SkillDockViewFrame:updateAllItemsSize()
    -- item background
    local _, height = self:GetSize()
    local itemWidth = (height - ItemSpace) / 2
    for k, v in pairs(self.mapOfTagToSkillViewItemBg) do
        v:SetSize(itemWidth, itemWidth)
        v:SetIconSize(itemWidth, itemWidth)
    end

    -- item
    for k, v in pairs(self.mapOfTagToSkillViewItem) do
        local skillItemBg = self.mapOfTagToSkillViewItemBg[k]
        local w, h = skillItemBg:GetSize()
        v:SetSize(w, h)
    end

    -- 技能显示项改变,则悬浮框也需要随之改变
    self:updateHoveringItemFrameData()
end


function SkillDockViewFrame:updateHoveringItemFrameData()
    -- hovering item frame label
    local skillItemBgLabel = self.mapOfTagToSkillViewItemBg[self.hoveringItemTag]
    if nil == skillItemBgLabel then
        self.hoveringItemFrameLabel:SetVisible(false)
        return
    end

    local x, y = skillItemBgLabel:GetPosition()
    self.hoveringItemFrameLabel:SetPosition(x, y)

    local w, h = skillItemBgLabel:GetSize()
    self.hoveringItemFrameLabel:SetSize(w, h)
    self.hoveringItemFrameLabel:SetIconSize(w, h)

    self.hoveringItemFrameLabel:SetVisible(true)
end

function SkillDockViewFrame:updateHoveringItemTipWindowData()
    self.model:RequestSetHoveringSkillItemTipWindowVisibility(self.isShowHoveringItemTip)

    local skillItemBgLabel = self.mapOfTagToSkillViewItemBg[self.hoveringItemTag]
    if nil == skillItemBgLabel then
        return
    end

    -- 设置悬浮框位置
    local tipWindowXPos = 0
    local tipWindowYPos = 0
    local bgX, bgY = skillItemBgLabel:GetPosition()
    local bgW, bgH = skillItemBgLabel:GetSize()
    tipWindowXPos = bgX + bgW / 2
    tipWindowYPos = bgY + bgH / 2

    -- info
    ---@type SkillInfo
    local skillInfo = Common.NewSkillInfo()
    skillInfo.id = 1

    -- 获取服务中正在运行的技能对象
    local skillMap = self.model:GetMapOfTagToSkillObj()
    local skill = skillMap[self.hoveringItemTag]
    -- 更新技能信息
    if nil ~= skill then
        local skillData = skill:GetData()
        Common.UpdateSkillInfoFromData(skillInfo, skillData)
    end

    self.model:RequestSetHoveringSkillItemTipWindowPosAndInfo(tipWindowXPos, tipWindowYPos, skillInfo)
end

return SkillDockViewFrame
