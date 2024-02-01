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

---@class ItemKeyGroup
local ItemKeyGroup = require("core.class")()

local NormalBtnWidth = 90
local LargeBtnWidth = 180

local DisabledImgPath = "ui/PushButton/Rectangle/Disabled"
local HoveringImgPath = "ui/PushButton/Rectangle/Hovering"
local NormalImgPath = "ui/PushButton/Rectangle/Normal"
local PressingImgPath = "ui/PushButton/Rectangle/Pressing"

--- 输入键值结构体
---@class ItemKeyGroup.InputKeyValueStruct
---@field NormalAttack string
---@field CounterAttack string
---@field Skill1 string
---@field Skill2 string
---@field Skill3 string
---@field Skill4 string
---@field Skill5 string
---@field Skill6 string
---@field Skill7 string
local InputKeyValueStruct = {
    NormalAttack = "normalAttack",
    Jump = "jump",
    CounterAttack = "counterAttack",
    Skill1 = "skill1",
    Skill2 = "skill2",
    Skill3 = "skill3",
    Skill4 = "skill4",
    Skill5 = "skill5",
    Skill6 = "skill6",
    Skill7 = "skill7"
}

---@param btn PushButton
local function initBtnImgPaths(btn)
    btn:SetDisabledSpriteDataPath(DisabledImgPath)
    btn:SetHoveringSpriteDataPath(HoveringImgPath)
    btn:SetNormalSpriteDataPath(NormalImgPath)
    btn:SetPressingSpriteDataPath(PressingImgPath)
end

---@param parentWindow Window
---@param ui UI
---@param model UiModel
function ItemKeyGroup:Ctor(parentWindow, ui, model)
    assert(parentWindow, "must assign parent window")

    NormalBtnWidth = NormalBtnWidth * Util.GetWindowSizeScale()
    LargeBtnWidth = LargeBtnWidth * Util.GetWindowSizeScale()

    self.isVisible = true

    self.model = model
    ---@type Actor.Entity
    self.player = nil
    ---@type table<string, PushButton>
    self.mapOfTagToSkillBtn = {}

    -- normal attack
    self.normalAttackBtn = PushButton.New(parentWindow)
    initBtnImgPaths(self.normalAttackBtn)
    self.normalAttackBtn:SetSize(LargeBtnWidth, LargeBtnWidth)
    ui.appendWindowWidget(parentWindow, self.normalAttackBtn)
    self.mapOfTagToSkillBtn[InputKeyValueStruct.NormalAttack] = self.normalAttackBtn

    -- jump
    self.jumpBtn = PushButton.New(parentWindow)
    initBtnImgPaths(self.jumpBtn)
    self.jumpBtn:SetSize(NormalBtnWidth, NormalBtnWidth)
    ui.appendWindowWidget(parentWindow, self.jumpBtn)
    self.mapOfTagToSkillBtn[InputKeyValueStruct.Jump] = self.jumpBtn

    -- counter Attack
    self.counterAttackBtn = PushButton.New(parentWindow)
    initBtnImgPaths(self.counterAttackBtn)
    self.counterAttackBtn:SetSize(NormalBtnWidth, NormalBtnWidth)
    ui.appendWindowWidget(parentWindow, self.counterAttackBtn)
    self.mapOfTagToSkillBtn[InputKeyValueStruct.CounterAttack] = self.counterAttackBtn

    -- skill1
    self.skill1Btn = PushButton.New(parentWindow)
    initBtnImgPaths(self.skill1Btn)
    self.skill1Btn:SetSize(NormalBtnWidth, NormalBtnWidth)
    ui.appendWindowWidget(parentWindow, self.skill1Btn)
    self.mapOfTagToSkillBtn[InputKeyValueStruct.Skill1] = self.skill1Btn

    -- skill2
    self.skill2Btn = PushButton.New(parentWindow)
    initBtnImgPaths(self.skill2Btn)
    self.skill2Btn:SetSize(NormalBtnWidth, NormalBtnWidth)
    ui.appendWindowWidget(parentWindow, self.skill2Btn)
    self.mapOfTagToSkillBtn[InputKeyValueStruct.Skill2] = self.skill2Btn

    -- skill3
    self.skill3Btn = PushButton.New(parentWindow)
    initBtnImgPaths(self.skill3Btn)
    self.skill3Btn:SetSize(NormalBtnWidth, NormalBtnWidth)
    ui.appendWindowWidget(parentWindow, self.skill3Btn)
    self.mapOfTagToSkillBtn[InputKeyValueStruct.Skill3] = self.skill3Btn

    -- skill4
    self.skill4Btn = PushButton.New(parentWindow)
    initBtnImgPaths(self.skill4Btn)
    self.skill4Btn:SetSize(NormalBtnWidth, NormalBtnWidth)
    ui.appendWindowWidget(parentWindow, self.skill4Btn)
    self.mapOfTagToSkillBtn[InputKeyValueStruct.Skill4] = self.skill4Btn

    -- skill5
    self.skill5Btn = PushButton.New(parentWindow)
    initBtnImgPaths(self.skill5Btn)
    self.skill5Btn:SetSize(NormalBtnWidth, NormalBtnWidth)
    ui.appendWindowWidget(parentWindow, self.skill5Btn)
    self.mapOfTagToSkillBtn[InputKeyValueStruct.Skill5] = self.skill5Btn

    -- skill6
    self.skill6Btn = PushButton.New(parentWindow)
    initBtnImgPaths(self.skill6Btn)
    self.skill6Btn:SetSize(NormalBtnWidth, NormalBtnWidth)
    ui.appendWindowWidget(parentWindow, self.skill6Btn)
    self.mapOfTagToSkillBtn[InputKeyValueStruct.Skill6] = self.skill6Btn

    -- skill7
    self.skill7Btn = PushButton.New(parentWindow)
    initBtnImgPaths(self.skill7Btn)
    self.skill7Btn:SetSize(NormalBtnWidth, NormalBtnWidth)
    ui.appendWindowWidget(parentWindow, self.skill7Btn)
    self.mapOfTagToSkillBtn[InputKeyValueStruct.Skill7] = self.skill7Btn

    -- connect
    self.normalAttackBtn:MocConnectSignal(self.normalAttackBtn.Signal_Clicked, self)
    self.jumpBtn:MocConnectSignal(self.jumpBtn.Signal_Clicked, self)
    self.counterAttackBtn:MocConnectSignal(self.counterAttackBtn.Signal_Clicked, self)
    self.skill1Btn:MocConnectSignal(self.skill1Btn.Signal_Clicked, self)
    self.skill2Btn:MocConnectSignal(self.skill2Btn.Signal_Clicked, self)
    self.skill3Btn:MocConnectSignal(self.skill3Btn.Signal_Clicked, self)
    self.skill4Btn:MocConnectSignal(self.skill4Btn.Signal_Clicked, self)
    self.skill5Btn:MocConnectSignal(self.skill5Btn.Signal_Clicked, self)
    self.skill6Btn:MocConnectSignal(self.skill6Btn.Signal_Clicked, self)
    self.skill7Btn:MocConnectSignal(self.skill7Btn.Signal_Clicked, self)

    -- post init
    self:UpdatePosition()
end

function ItemKeyGroup:Update(dt)
    if (not self.isVisible) then
        return
    end

    ---- skill item
    -- 更新技能显示项冷却时间
    local mapOfTagToSkillObj = self.model:GetMapOfTagToSkillObj()
    for k, v in pairs(mapOfTagToSkillObj) do
        -- k 为 tag，即配置中的键
        local btn = self.mapOfTagToSkillBtn[k]
        if nil == btn then
            goto continue
        end

        local progress = v:GetProcess();
        if 1.0 <= progress then
            goto continue
        end
        btn:SetMaskPercent(progress)

        ::continue::
    end

    -- normal attack
    self.normalAttackBtn:Update(dt)

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

    -- 更新使用逻辑
    self:updateUseLogic()
end

function ItemKeyGroup:Draw()
    if (not self.isVisible) then
        return
    end
    -- normal attack
    self.normalAttackBtn:Draw()

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
end

function ItemKeyGroup:SetVisible(visible)
    self.isVisible = visible
end

---@param player Actor.Entity
function ItemKeyGroup:SetPlayer(player)
    local mapOfTagToSkillObj = self.model:GetMapOfTagToSkillObj()
    for k, v in pairs(mapOfTagToSkillObj) do
        -- k 为 tag，即配置中的键
        local btn = self.mapOfTagToSkillBtn[k]
        if nil == btn then
            goto continue
        end
        btn:SetNormalSpriteDataPath("icon/skill/" .. v:GetData().icon)
        btn:SetHoveringSpriteDataPath("icon/skill/" .. v:GetData().icon)
        btn:SetDisabledSpriteDataPath("icon/skill/" .. v:GetData().icon)

        ::continue::
    end
end

function ItemKeyGroup:UpdatePosition()
    local windowWidth = Util.GetWindowWidth()
    local windowHeight = Util.GetWindowHeight()
    local scale = Util.GetWindowSizeScale()

    -- normal attack
    self.normalAttackBtn:SetPosition(windowWidth - 40 * scale - LargeBtnWidth,
        windowHeight - 40 * scale - LargeBtnWidth)


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
end

--- 信号槽 - 当有按钮被点击时
---@param btn PushButton
function ItemKeyGroup:Slot_BtnClicked(btn)
    print("ItemKeyGroup:Slot_BtnClicked", btn)
    -- normal attack
    if (btn == self.normalAttackBtn) then
        self.model:ReleasePlayerKey(InputKeyValueStruct.NormalAttack)
    end

    -- jump
    if (btn == self.jumpBtn) then
        self.model:ReleasePlayerKey(InputKeyValueStruct.Jump)
    end

    -- counter Attack
    if (btn == self.counterAttackBtn) then
        self.model:ReleasePlayerKey(InputKeyValueStruct.CounterAttack)
    end

    -- skill1
    if (btn == self.skill1Btn) then
        self.model:ReleasePlayerKey(InputKeyValueStruct.Skill1)
    end

    -- skill2
    if (btn == self.skill2Btn) then
        self.model:ReleasePlayerKey(InputKeyValueStruct.Skill2)
    end

    -- skill3
    if (btn == self.skill3Btn) then
        self.model:ReleasePlayerKey(InputKeyValueStruct.Skill3)
    end

    -- skill4
    if (btn == self.skill4Btn) then
        self.model:ReleasePlayerKey(InputKeyValueStruct.Skill4)
    end

    -- skill5
    if (btn == self.skill5Btn) then
        self.model:ReleasePlayerKey(InputKeyValueStruct.Skill5)
    end

    -- skill6
    if (btn == self.skill6Btn) then
        self.model:ReleasePlayerKey(InputKeyValueStruct.Skill6)
    end

    -- skill7
    if (btn == self.skill7Btn) then
        self.model:ReleasePlayerKey(InputKeyValueStruct.Skill7)
    end
end

--- 更新使用逻辑
function ItemKeyGroup:updateUseLogic()
    -- normal attack
    if (self.normalAttackBtn:IsPressing()) then
        self.model:PressPlayerKey(InputKeyValueStruct.NormalAttack)
    end

    -- jump
    if (self.jumpBtn:IsPressing()) then
        self.model:PressPlayerKey(InputKeyValueStruct.Jump)
    end

    -- counter Attack
    if (self.counterAttackBtn:IsPressing()) then
        self.model:PressPlayerKey(InputKeyValueStruct.CounterAttack)
    end

    -- skill1
    if (self.skill1Btn:IsPressing()) then
        self.model:PressPlayerKey(InputKeyValueStruct.Skill1)
    end

    -- skill2
    if (self.skill2Btn:IsPressing()) then
        self.model:PressPlayerKey(InputKeyValueStruct.Skill2)
    end

    -- skill3
    if (self.skill3Btn:IsPressing()) then
        self.model:PressPlayerKey(InputKeyValueStruct.Skill3)
    end

    -- skill4
    if (self.skill4Btn:IsPressing()) then
        self.model:PressPlayerKey(InputKeyValueStruct.Skill4)
    end

    -- skill5
    if (self.skill5Btn:IsPressing()) then
        self.model:PressPlayerKey(InputKeyValueStruct.Skill5)
    end

    -- skill6
    if (self.skill6Btn:IsPressing()) then
        self.model:PressPlayerKey(InputKeyValueStruct.Skill6)
    end

    -- skill7
    if (self.skill7Btn:IsPressing()) then
        self.model:PressPlayerKey(InputKeyValueStruct.Skill7)
    end
end

return ItemKeyGroup
