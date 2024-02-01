--[[
	desc: Util, A common utility.
	author: keke
	since: 20122-12-10
	alter: 20122-12-10
]] --

local System = require("lib.system")

local Util = {}

-- 获取窗口缩放比例
function Util.GetWindowSizeScale()
    local sx, _ = System.GetScale()
    return sx
end

---@return number
function Util.GetWindowHeight()
    local width, height, flags = love.window.getMode()
    return height
end

---@return number
function Util.GetWindowWidth()
    local width, height, flags = love.window.getMode()
    return width
end

return Util
