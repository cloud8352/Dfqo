--[[
	desc: Util, A common utility.
	author: keke
	since: 20122-12-10
	alter: 20122-12-10
]] --

local Util = {}

-- 获取窗口缩放比例
function Util.GetWindowSizeScale()
    local sizeScale = 1
    local _, _, flags = love.window.getMode()

    -- The window's flags contain the index of the monitor it's currently in.
    local screenW, _ = love.window.getDesktopDimensions(flags.display)

    if 0 < screenW then
        sizeScale = screenW / 1920 --以1920x1080为基准缩放窗口尺寸
    end

    return sizeScale
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
