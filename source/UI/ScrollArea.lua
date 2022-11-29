--[[
	desc: ScrollArea class.
	author: keke <243768648@qq.com>
	since: 2022-12-09
	alter: 2022-12-09
]] --

--- 滑动区域
---@class ScrollArea
local ScrollArea = require("core.class")()

function ScrollArea:Ctor()
end

---@param xOffset int
---@param yOffset int
function ScrollArea:OnRequestMoveContent(xOffset, yOffset)
    print("ScrollArea:OnRequestMoveContent()", xOffset, yOffset)
end

return ScrollArea
