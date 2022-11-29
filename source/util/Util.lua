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

    local file = io.open("currentResolutionW.tmp", "r")
    if nil == file then
        print("getWindowSizeScale()" .. "open currentResolutionW.tmp failed!")
        return sizeScale
    end

    local currentResolutionWStr = file:read("*a") -- 读取的数据字符
    file:close()
    local currentResolutionW = tonumber(currentResolutionWStr)
    if 0 < currentResolutionW then
        sizeScale = currentResolutionW / 1920 --以1920x1080为基准缩放窗口尺寸
    end

    return sizeScale
end

return Util
