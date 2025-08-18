--[[
	desc: PlayerArticleTableWidget class. 玩家物品表格控件
	author: keke <243768648@qq.com>
]] --

local ArticleTableWidget = require("UI.ArticleTableWidget")
local Common = require("UI.ui_common")

--- item background
local DockedItemBgImgPath = "ui/article_view_item/article_view_item_bg"

---@class PlayerArticleTableWidget : ArticleTableWidget
local PlayerArticleTableWidget = require("core.class")(ArticleTableWidget)

---@param parentWindow Window
---@param model UiModel
function PlayerArticleTableWidget.Create(parentWindow, model)
    -- 用于定义构造函数，解释使用，不做实际用途
    -- 使用class模块后，实际会调用Ctor函数
    return PlayerArticleTableWidget.New(parentWindow, model)
end

---@param parentWindow Window
---@param model UiModel
function PlayerArticleTableWidget:Ctor(parentWindow, model)
    ArticleTableWidget.Ctor(self, parentWindow, model)

    self:SetRowColCount(Common.ArticleTableRowCount, Common.ArticleTableColCount)

    -- connect
    self.model:MocConnectSignal(self.model.Signal_PlayerChanged, self)
end

---@param rowCount int
---@param colCount int
function PlayerArticleTableWidget:SetRowColCount(rowCount, colCount)
    ArticleTableWidget.SetRowColCount(self, rowCount, colCount)

    local viewItemList = self:GetItemList()
    for i = 1, #viewItemList do
        local item = viewItemList[i]
        if i <= Common.ArticleDockColCount then
            item:SetBgSpriteDataPath(DockedItemBgImgPath)
            item:SetBgSpriteColor(255, 255, 255, 255)
        end
    end
end

--- 当玩家改变后
---@param sender Object
function PlayerArticleTableWidget:Slot_PlayerChanged(sender)
    for i, info in pairs(self.model:GetArticleInfoList()) do
        self:SetIndexItemInfo(i, info)
    end
end

--- protect func

--- can override
---@param index int
function PlayerArticleTableWidget:setHoveringItemIndex(index)
    ArticleTableWidget.setHoveringItemIndex(self, index)
    self.model:SetArticleTableHoveringItemIndex(index)
end

--- can override
---@param index int
function PlayerArticleTableWidget:rightKeyClickedItem(index)
    self.model:OnRightKeyClickedArticleTableItem(index)
end

--- can override
function PlayerArticleTableWidget:dropItem()
    self.model:DropArticleItem()
end

--- can override
--- 设置拖拽中的物品索引
---@param index int
function PlayerArticleTableWidget:dragItem(index)
    self.model:DragArticleItem(index)
end

--- can override
---@param xPos int
---@param yPos int
function PlayerArticleTableWidget:moveDraggingItem(xPos, yPos)
    self.model:OnRequestMoveDraggingArticleItem(xPos, yPos)
end

return PlayerArticleTableWidget
