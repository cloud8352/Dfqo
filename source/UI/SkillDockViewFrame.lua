--[[
	desc: SkillDockViewFrame class. 技能托盘显示框架
	author: keke <243768648@qq.com>
	since: 2023-4-15
	alter: 2023-4-15
]] --

local _CONFIG = require("config")
local _Mouse = require("lib.mouse")
-- service
local SkillSrv = require("actor.service.skill")

local WindowManager = require("UI.WindowManager")
local Label = require("UI.Label")
local SkillDockViewItem = require("UI.SkillDockViewItem")

---@class SkillDockViewFrame
local SkillDockViewFrame = require("core.class")()

local ItemSpace = 1

---@param parentWindow Window
function SkillDockViewFrame:Ctor(parentWindow)
    assert(parentWindow, "must assign parent window")
    ---@type Window
    self.parentWindow = parentWindow

    local defaultItemWidth = 80
    self.width = defaultItemWidth * 6 + ItemSpace * 5
    self.lastWidth = 0
    self.height = ItemSpace + defaultItemWidth * 2
    self.lastHeight = 0
    self.xPos = 0
    self.lastXPos = 0
    self.yPos = 0
    self.lastYPos = 0
    self.enable = true

    ---@type Actor.Entity
    self.player = nil
    self.lastPlayer = nil

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

    --- post init
    self:updateData()
end

function SkillDockViewFrame:Update(dt)
    self:MouseEvent()

    if (self.lastXPos ~= self.xPos
        or self.lastYPos ~= self.yPos
        or self.lastWidth ~= self.width
        or self.lastHeight ~= self.height
        or self.lastHeight ~= self.height
        or self.lastPlayer ~= self.player
        )
        then
        self:updateData()
    end

    if (self.lastHoveringItemTag ~= self.hoveringItemTag) then
        self:updateHoveringItemFrameData()
    end

    -- skill item bg
    for k, v in pairs(self.mapOfTagToSkillViewItemBg) do
        v:Update(dt)
    end

    ---- skill item
    -- 更新技能显示项冷却时间
    if self.player then
        local skillList = SkillSrv.GetMap(self.player.skills)
        for k, v in pairs(skillList) do
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
    end

    self.hoveringItemFrameLabel:Update(dt)

    --- 更新上次和当前的所有状态
    self.lastXPos = self.xPos
    self.lastYPos = self.yPos
    self.lastWidth = self.width
    self.lastHeight = self.height

    self.lastPlayer = self.player
    self.lastHoveringItemTag = self.hoveringItemTag
end

function SkillDockViewFrame:Draw()
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
        local windowLayerIndex = self.parentWindow:GetWindowLayerIndex()
        if WindowManager.IsMouseCapturedAboveLayer(windowLayerIndex) then
            self.hoveringItemTag = ""
            self.hoveringItemFrameLabel:SetVisible(false)
            break
        end

        local mousePosX, mousePosY = _Mouse.GetPosition(1, 1)
        -- 寻找鼠标悬停处的显示项
        ---@type Label
        local hoveringItemFrameLabel = nil
        for tag, label in pairs(self.mapOfTagToSkillViewItemBg) do
            if label:CheckPoint(mousePosX, mousePosY) then
                hoveringItemFrameLabel = label
                self.hoveringItemTag = tag
                self.hoveringItemFrameLabel:SetVisible(true)
                break
            end
        end
        if nil == hoveringItemFrameLabel then
            self.hoveringItemTag = ""
            self.hoveringItemFrameLabel:SetVisible(false)
            break
        end

        break
    end
end

function SkillDockViewFrame:SetPosition(x, y)
    self.xPos = x
    self.yPos = y
end

function SkillDockViewFrame:SetSize(width, height)
    self.width = width
    self.height = height
end

function SkillDockViewFrame:SetEnable(enable)
    self.enable = enable
end

---@param player Actor.Entity
function SkillDockViewFrame:SetPlayer(player)
    self.player = player

    local skillList = SkillSrv.GetMap(player.skills)
    for k, v in pairs(skillList) do
        -- k 为 tag，即配置中的键
        local item = self.mapOfTagToSkillViewItem[k]
        if nil == item then
            goto continue
        end
        item:SetIconSpriteDataPath("icon/skill/" .. v:GetData().icon)

        local key = _CONFIG.code[k]
        if nil == key then
            key = ""
        end
        item:SetKey(key)

        ::continue::
    end
end

function SkillDockViewFrame:updateData()
    -- item background
    local itemWidth = (self.height - ItemSpace) / 2
    for k, v in pairs(self.mapOfTagToSkillViewItemBg) do
        if "skill1" == k then
            v:SetPosition(self.xPos, self.yPos + itemWidth + ItemSpace)
        end
        if "skill2" == k then
            v:SetPosition(self.xPos + (ItemSpace + itemWidth) * 1, self.yPos + itemWidth + ItemSpace)
        end
        if "skill3" == k then
            v:SetPosition(self.xPos + (ItemSpace + itemWidth) * 2, self.yPos + itemWidth + ItemSpace)
        end
        if "skill4" == k then
            v:SetPosition(self.xPos + (ItemSpace + itemWidth) * 3, self.yPos + itemWidth + ItemSpace)
            v:SetSize(self.height, self.height)
        end
        if "skill5" == k then
            v:SetPosition(self.xPos + (ItemSpace + itemWidth) * 4, self.yPos + itemWidth + ItemSpace)
        end
        if "skill6" == k then
            v:SetPosition(self.xPos + (ItemSpace + itemWidth) * 5, self.yPos + itemWidth + ItemSpace)
        end
        if "skill7" == k then
            v:SetPosition(self.xPos, self.yPos)
        end
        if "skill8" == k then
            v:SetPosition(self.xPos + (ItemSpace + itemWidth) * 1, self.yPos)
        end
        if "skill9" == k then
            v:SetPosition(self.xPos + (ItemSpace + itemWidth) * 2, self.yPos)
        end
        if "skill10" == k then
            v:SetPosition(self.xPos + (ItemSpace + itemWidth) * 3, self.yPos)
        end
        if "skill11" == k then
            v:SetPosition(self.xPos + (ItemSpace + itemWidth) * 4, self.yPos)
        end
        if "skill12" == k then
            v:SetPosition(self.xPos + (ItemSpace + itemWidth) * 5, self.yPos)
        end

        v:SetSize(itemWidth, itemWidth)
    end

    -- item
    for k, v in pairs(self.mapOfTagToSkillViewItem) do
        local skillItemBg = self.mapOfTagToSkillViewItemBg[k]
        local x, y = skillItemBg:GetPosition()
        v:SetPosition(x, y)

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
        return
    end

    local x, y = skillItemBgLabel:GetPosition()
    self.hoveringItemFrameLabel:SetPosition(x, y)

    local w, h = skillItemBgLabel:GetSize()
    self.hoveringItemFrameLabel:SetSize(w, h)
end

return SkillDockViewFrame
