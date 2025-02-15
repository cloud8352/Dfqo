--[[
	desc: ItemKeyGroup class.
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

---@class ItemKeyGroup
local ItemKeyGroup = require("core.class")()

local SmallBtnWidth = 40
local NormalBtnWidth = 90
local LargeBtnWidth = 180

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

    btn:SetOpacity(0.7)
end

---@param parentWindow Window
---@param model UiModel
function ItemKeyGroup:Ctor(parentWindow, model)
    assert(parentWindow, "must assign parent window")

    SmallBtnWidth = 40 * Util.GetWindowSizeScale()
    NormalBtnWidth = 90 * Util.GetWindowSizeScale()
    LargeBtnWidth = 180 * Util.GetWindowSizeScale()

    self.isVisible = true

    self.model = model
    ---@type Actor.Entity
    self.player = nil
    ---@type table<string, PushButton>
    self.mapOfTagToSkillBtn = {}

    ---@type table<string, PushButton>
    self.mapOfTagToDockItemBtn = {}

    -- normal attack
    self.normalAttackBtn = PushButton.New(parentWindow)
    initBtnImgPaths(self.normalAttackBtn)
    self.normalAttackBtn:EnableClickedSound(false)
    self.normalAttackBtn:SetSize(LargeBtnWidth, LargeBtnWidth)
    self.mapOfTagToSkillBtn[Common.InputKeyValueStruct.NormalAttack] = self.normalAttackBtn

    self.getItemBtn = PushButton.New(parentWindow)
    initBtnImgPaths(self.getItemBtn)
    self.getItemBtn:EnableClickedSound(false)
    self.getItemBtn:SetSize(SmallBtnWidth, SmallBtnWidth)
    self.getItemBtn:SetNormalSpriteDataPath("icon/skill/GetItem")

    -- jump
    self.jumpBtn = PushButton.New(parentWindow)
    initBtnImgPaths(self.jumpBtn)
    self.jumpBtn:EnableClickedSound(false)
    self.jumpBtn:SetSize(NormalBtnWidth, NormalBtnWidth)
    self.mapOfTagToSkillBtn[Common.InputKeyValueStruct.Jump] = self.jumpBtn

    -- counter Attack
    self.counterAttackBtn = PushButton.New(parentWindow)
    initBtnImgPaths(self.counterAttackBtn)
    self.counterAttackBtn:EnableClickedSound(false)
    self.counterAttackBtn:SetSize(NormalBtnWidth, NormalBtnWidth)
    self.mapOfTagToSkillBtn[Common.InputKeyValueStruct.CounterAttack] = self.counterAttackBtn

    -- skill1
    self.skill1Btn = PushButton.New(parentWindow)
    initBtnImgPaths(self.skill1Btn)
    self.skill1Btn:EnableClickedSound(false)
    self.skill1Btn:SetSize(NormalBtnWidth, NormalBtnWidth)
    self.mapOfTagToSkillBtn[Common.InputKeyValueStruct.Skill1] = self.skill1Btn

    -- skill2
    self.skill2Btn = PushButton.New(parentWindow)
    initBtnImgPaths(self.skill2Btn)
    self.skill2Btn:EnableClickedSound(false)
    self.skill2Btn:SetSize(NormalBtnWidth, NormalBtnWidth)
    self.mapOfTagToSkillBtn[Common.InputKeyValueStruct.Skill2] = self.skill2Btn

    -- skill3
    self.skill3Btn = PushButton.New(parentWindow)
    initBtnImgPaths(self.skill3Btn)
    self.skill3Btn:EnableClickedSound(false)
    self.skill3Btn:SetSize(NormalBtnWidth, NormalBtnWidth)
    self.mapOfTagToSkillBtn[Common.InputKeyValueStruct.Skill3] = self.skill3Btn

    -- skill4
    self.skill4Btn = PushButton.New(parentWindow)
    initBtnImgPaths(self.skill4Btn)
    self.skill4Btn:EnableClickedSound(false)
    self.skill4Btn:SetSize(NormalBtnWidth, NormalBtnWidth)
    self.mapOfTagToSkillBtn[Common.InputKeyValueStruct.Skill4] = self.skill4Btn

    -- skill5
    self.skill5Btn = PushButton.New(parentWindow)
    initBtnImgPaths(self.skill5Btn)
    self.skill5Btn:EnableClickedSound(false)
    self.skill5Btn:SetSize(NormalBtnWidth, NormalBtnWidth)
    self.mapOfTagToSkillBtn[Common.InputKeyValueStruct.Skill5] = self.skill5Btn

    -- skill6
    self.skill6Btn = PushButton.New(parentWindow)
    initBtnImgPaths(self.skill6Btn)
    self.skill6Btn:EnableClickedSound(false)
    self.skill6Btn:SetSize(NormalBtnWidth, NormalBtnWidth)
    self.mapOfTagToSkillBtn[Common.InputKeyValueStruct.Skill6] = self.skill6Btn

    -- skill7
    self.skill7Btn = PushButton.New(parentWindow)
    initBtnImgPaths(self.skill7Btn)
    self.skill7Btn:EnableClickedSound(false)
    self.skill7Btn:SetSize(NormalBtnWidth, NormalBtnWidth)
    self.mapOfTagToSkillBtn[Common.InputKeyValueStruct.Skill7] = self.skill7Btn

    -- dock item
    self.dockItem1Btn = PushButton.New(parentWindow)
    initBtnImgPaths(self.dockItem1Btn)
    self.dockItem1Btn:EnableClickedSound(false)
    self.dockItem1Btn:SetSize(NormalBtnWidth, NormalBtnWidth)
    self.mapOfTagToDockItemBtn[Common.InputKeyValueStruct.DockItem1] = self.dockItem1Btn

    self.dockItem2Btn = PushButton.New(parentWindow)
    initBtnImgPaths(self.dockItem2Btn)
    self.dockItem2Btn:EnableClickedSound(false)
    self.dockItem2Btn:SetSize(NormalBtnWidth, NormalBtnWidth)
    self.mapOfTagToDockItemBtn[Common.InputKeyValueStruct.DockItem2] = self.dockItem2Btn


    -- connection
    self.model:MocConnectSignal(self.model.Signal_PlayerChanged, self)
    self.model:MocConnectSignal(self.model.Signal_PlayerMountedSkillsChanged, self)

    self.normalAttackBtn:MocConnectSignal(self.normalAttackBtn.Signal_BtnClicked, self)
    self.getItemBtn:MocConnectSignal(self.getItemBtn.Signal_BtnClicked, self)
    self.jumpBtn:MocConnectSignal(self.jumpBtn.Signal_BtnClicked, self)
    self.counterAttackBtn:MocConnectSignal(self.counterAttackBtn.Signal_BtnClicked, self)
    self.skill1Btn:MocConnectSignal(self.skill1Btn.Signal_BtnClicked, self)
    self.skill2Btn:MocConnectSignal(self.skill2Btn.Signal_BtnClicked, self)
    self.skill3Btn:MocConnectSignal(self.skill3Btn.Signal_BtnClicked, self)
    self.skill4Btn:MocConnectSignal(self.skill4Btn.Signal_BtnClicked, self)
    self.skill5Btn:MocConnectSignal(self.skill5Btn.Signal_BtnClicked, self)
    self.skill6Btn:MocConnectSignal(self.skill6Btn.Signal_BtnClicked, self)
    self.skill7Btn:MocConnectSignal(self.skill7Btn.Signal_BtnClicked, self)
    self.dockItem1Btn:MocConnectSignal(self.dockItem1Btn.Signal_BtnClicked, self)
    self.dockItem2Btn:MocConnectSignal(self.dockItem2Btn.Signal_BtnClicked, self)

    -- post init
    self:updatePosition()
    self:reloadSkillBtnsIcon()
end

function ItemKeyGroup:Update(dt)
    if (not self.isVisible) then
        return
    end

    ---- skill item
    -- 更新技能显示项冷却时间
    for k, v in pairs(self.mapOfTagToSkillBtn) do
        local progress = 1.0
        local actorSkillObj = self.model:GetPlayerActorSkillObj(k)
        if actorSkillObj then
            progress = actorSkillObj:GetProcess()
        end
        v:SetMaskPercent(progress)
    end

    -- normal attack
    self.normalAttackBtn:Update(dt)

    self.getItemBtn:Update(dt)

    -- jump
    self.jumpBtn:Update(dt)

    -- counter Attack
    self.counterAttackBtn:Update(dt)

    -- skill1
    self.skill1Btn:Update(dt)

    -- skill2
    self.skill2Btn:Update(dt)

    -- skill3
    self.skill3Btn:Update(dt)

    -- skill4
    self.skill4Btn:Update(dt)

    -- skill5
    self.skill5Btn:Update(dt)

    -- skill6
    self.skill6Btn:Update(dt)

    -- skill7
    self.skill7Btn:Update(dt)

    -- dock item
    self.dockItem1Btn:Update(dt)
    self.dockItem2Btn:Update(dt)

    -- 更新使用逻辑
    self:updateUseLogic()
end

function ItemKeyGroup:Draw()
    if (not self.isVisible) then
        return
    end
    -- normal attack
    self.normalAttackBtn:Draw()

    self.getItemBtn:Draw()

    -- jump
    self.jumpBtn:Draw()

    -- counter Attack
    self.counterAttackBtn:Draw()

    -- skill1
    self.skill1Btn:Draw()

    -- skill2
    self.skill2Btn:Draw()

    -- skill3
    self.skill3Btn:Draw()

    -- skill4
    self.skill4Btn:Draw()

    -- skill5
    self.skill5Btn:Draw()

    -- skill6
    self.skill6Btn:Draw()

    -- skill7
    self.skill7Btn:Draw()

    -- dock item
    self.dockItem1Btn:Draw()
    self.dockItem2Btn:Draw()
end

function ItemKeyGroup:SetVisible(visible)
    self.isVisible = visible
end

---@param index int
---@param articleInfo ArticleInfo
function ItemKeyGroup:SetDockItemInfo(index, articleInfo)
    local countStr = ""
    if articleInfo.count > 1 then
        countStr = tostring(articleInfo.count)
    end
    local iconPath = articleInfo.iconPath
    if iconPath == "" then
        iconPath = NormalImgPath
    end
    if index == 1 then
        self.dockItem1Btn:SetNormalSpriteDataPath(iconPath)
        self.dockItem1Btn:SetText(countStr)
    end

    if index == 2 then
        self.dockItem2Btn:SetNormalSpriteDataPath(iconPath)
        self.dockItem2Btn:SetText(countStr)
    end
end

--- slots

---@param sender Obj
function ItemKeyGroup:Slot_PlayerChanged(sender)
    self:reloadSkillBtnsIcon()

    self:updateDockItemBtnsUi()
end

---@param sender Obj
function ItemKeyGroup:Slot_PlayerMountedSkillsChanged(sender)
    self:reloadSkillBtnsIcon()

    self:updateDockItemBtnsUi()
end

--- 信号槽 - 当有按钮被点击时
---@param btn PushButton
function ItemKeyGroup:Slot_BtnClicked(btn)
    print("ItemKeyGroup:Slot_BtnClicked", btn)
    -- normal attack
    if (btn == self.normalAttackBtn) then
        self.model:ReleasePlayerKey(Common.InputKeyValueStruct.NormalAttack)
    end

    if btn == self.getItemBtn then
        self.model:ReleasePlayerKey(Common.InputKeyValueStruct.GetItem)
    end

    -- jump
    if (btn == self.jumpBtn) then
        self.model:ReleasePlayerKey(Common.InputKeyValueStruct.Jump)
    end

    -- counter Attack
    if (btn == self.counterAttackBtn) then
        self.model:ReleasePlayerKey(Common.InputKeyValueStruct.CounterAttack)
    end

    -- skill1
    if (btn == self.skill1Btn) then
        self.model:ReleasePlayerKey(Common.InputKeyValueStruct.Skill1)
    end

    -- skill2
    if (btn == self.skill2Btn) then
        self.model:ReleasePlayerKey(Common.InputKeyValueStruct.Skill2)
    end

    -- skill3
    if (btn == self.skill3Btn) then
        self.model:ReleasePlayerKey(Common.InputKeyValueStruct.Skill3)
    end

    -- skill4
    if (btn == self.skill4Btn) then
        self.model:ReleasePlayerKey(Common.InputKeyValueStruct.Skill4)
    end

    -- skill5
    if (btn == self.skill5Btn) then
        self.model:ReleasePlayerKey(Common.InputKeyValueStruct.Skill5)
    end

    -- skill6
    if (btn == self.skill6Btn) then
        self.model:ReleasePlayerKey(Common.InputKeyValueStruct.Skill6)
    end

    -- skill7
    if (btn == self.skill7Btn) then
        self.model:ReleasePlayerKey(Common.InputKeyValueStruct.Skill7)
    end

    -- dock item, 物品的使用逻辑还在UI中，没有放到esc框架中，所以目前直接调用model方法
    if (btn == self.dockItem1Btn) then
        self.model:OnRightKeyClickedArticleDockItem(1)
    end
    if (btn == self.dockItem2Btn) then
        self.model:OnRightKeyClickedArticleDockItem(2)
    end
end

--- private function

function ItemKeyGroup:reloadSkillBtnsIcon()
    for k, v in pairs(self.mapOfTagToSkillBtn) do
        local actorSkillObj = self.model:GetPlayerActorSkillObj(k)
        if actorSkillObj then
            ---@type Actor.RESMGR.SkillData
            local skillData = actorSkillObj:GetData()
            local iconPath = "icon/skill/NormalAttack"
            if skillData.icon then
                iconPath = "icon/skill/" .. skillData.icon
            end
            v:SetNormalSpriteDataPath(iconPath)
            v:SetHoveringSpriteDataPath(iconPath)
            v:SetDisabledSpriteDataPath(iconPath)
        else
            v:SetNormalSpriteDataPath(NormalImgPath)
            v:SetHoveringSpriteDataPath(HoveringImgPath)
            v:SetDisabledSpriteDataPath(DisabledImgPath)
        end

    end
end

function ItemKeyGroup:updateDockItemBtnsUi()
    local articleInfoList = self.model:GetArticleInfoList()

    local articleInfo = articleInfoList[1]
    self:SetDockItemInfo(1, articleInfo)

    articleInfo = articleInfoList[2]
    self:SetDockItemInfo(2, articleInfo)
end

function ItemKeyGroup:updatePosition()
    local windowWidth = Util.GetWindowWidth()
    local windowHeight = Util.GetWindowHeight()
    local scale = Util.GetWindowSizeScale()

    -- normal attack
    self.normalAttackBtn:SetPosition(windowWidth - 40 * scale - LargeBtnWidth,
        windowHeight - 40 * scale - LargeBtnWidth)


    self.getItemBtn:SetPosition(windowWidth - 40 * scale - LargeBtnWidth - 15 * scale,
        windowHeight - 20 * scale - SmallBtnWidth + 15 * scale)

    -- jump
    self.jumpBtn:SetPosition(windowWidth - 20 * scale - NormalBtnWidth,
        windowHeight - 40 * scale - LargeBtnWidth - 20 * scale - NormalBtnWidth)

    -- counter Attack
    self.counterAttackBtn:SetPosition(windowWidth - 20 * scale - NormalBtnWidth - 20 * scale - NormalBtnWidth,
        windowHeight - 40 * scale - LargeBtnWidth - 20 * scale - NormalBtnWidth)

    -- skill1
    self.skill1Btn:SetPosition(windowWidth - 40 * scale - LargeBtnWidth - 20 * scale - NormalBtnWidth,
        windowHeight - 20 * scale - NormalBtnWidth)

    -- skill2
    self.skill2Btn:SetPosition(windowWidth - 40 * scale - LargeBtnWidth - 20 * scale - NormalBtnWidth,
        windowHeight - 20 * scale - NormalBtnWidth - 20 * scale - NormalBtnWidth)

    -- skill3
    self.skill3Btn:SetPosition(windowWidth - 40 * scale - LargeBtnWidth - 20 * scale - NormalBtnWidth,
        windowHeight - 20 * scale - NormalBtnWidth - 20 * scale - NormalBtnWidth - 20 * scale - NormalBtnWidth)

    -- skill4
    self.skill4Btn:SetPosition(windowWidth - 40 * scale - LargeBtnWidth - 20 * scale - NormalBtnWidth - 20 * scale - NormalBtnWidth,
        windowHeight - 20 * scale - NormalBtnWidth)

    -- skill5
    self.skill5Btn:SetPosition(windowWidth - 40 * scale - LargeBtnWidth - 20 * scale - NormalBtnWidth - 20 * scale - NormalBtnWidth,
        windowHeight - 20 * scale - NormalBtnWidth - 20 * scale - NormalBtnWidth)

    -- skill6
    self.skill6Btn:SetPosition(windowWidth - 20 * scale - NormalBtnWidth - 20 * scale - NormalBtnWidth,
        windowHeight - 40 * scale - LargeBtnWidth - 20 * scale - NormalBtnWidth - 20 * scale - NormalBtnWidth)

    -- skill7
    self.skill7Btn:SetPosition(windowWidth - 20 * scale - NormalBtnWidth,
        windowHeight - 40 * scale - LargeBtnWidth - 20 * scale - NormalBtnWidth - 20 * scale - NormalBtnWidth)

    -- dock item
    self.dockItem2Btn:SetPosition(windowWidth - 40 * scale - LargeBtnWidth - 20 * scale - NormalBtnWidth
        - 20 * scale - NormalBtnWidth - 80 * scale - NormalBtnWidth,
        windowHeight - 20 * scale - NormalBtnWidth)
    self.dockItem1Btn:SetPosition(windowWidth - 40 * scale - LargeBtnWidth - 20 * scale - NormalBtnWidth
        - 20 * scale - NormalBtnWidth - 80 * scale - NormalBtnWidth - 40 * scale - NormalBtnWidth,
        windowHeight - 20 * scale - NormalBtnWidth)
end

--- 更新使用逻辑
function ItemKeyGroup:updateUseLogic()
    -- normal attack
    if (self.normalAttackBtn:IsPressing()) then
        self.model:PressPlayerKey(Common.InputKeyValueStruct.NormalAttack)
    end

    if (self.getItemBtn:IsPressing()) then
        self.model:PressPlayerKey(Common.InputKeyValueStruct.GetItem)
    end

    -- jump
    if (self.jumpBtn:IsPressing()) then
        self.model:PressPlayerKey(Common.InputKeyValueStruct.Jump)
    end

    -- counter Attack
    if (self.counterAttackBtn:IsPressing()) then
        self.model:PressPlayerKey(Common.InputKeyValueStruct.CounterAttack)
    end

    -- skill1
    if (self.skill1Btn:IsPressing()) then
        self.model:PressPlayerKey(Common.InputKeyValueStruct.Skill1)
    end

    -- skill2
    if (self.skill2Btn:IsPressing()) then
        self.model:PressPlayerKey(Common.InputKeyValueStruct.Skill2)
    end

    -- skill3
    if (self.skill3Btn:IsPressing()) then
        self.model:PressPlayerKey(Common.InputKeyValueStruct.Skill3)
    end

    -- skill4
    if (self.skill4Btn:IsPressing()) then
        self.model:PressPlayerKey(Common.InputKeyValueStruct.Skill4)
    end

    -- skill5
    if (self.skill5Btn:IsPressing()) then
        self.model:PressPlayerKey(Common.InputKeyValueStruct.Skill5)
    end

    -- skill6
    if (self.skill6Btn:IsPressing()) then
        self.model:PressPlayerKey(Common.InputKeyValueStruct.Skill6)
    end

    -- skill7
    if (self.skill7Btn:IsPressing()) then
        self.model:PressPlayerKey(Common.InputKeyValueStruct.Skill7)
    end
end

return ItemKeyGroup
