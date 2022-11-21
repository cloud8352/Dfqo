--[[
	desc: WindowManager, window manager.
	author: keke <243768648@qq.com>
	since: 2022-10-25
	alter: 2022-10-25
]] --

local _Mouse = require("lib.mouse")

local WindowManager = {}

---@type table<int, Window>
WindowManager.windowList = {}

---@param obj Window
function WindowManager.AppendToWindowList(obj)
    table.insert(WindowManager.windowList, obj)
end

---@param obj Window
function WindowManager.removeFromWindowList(obj)
    local removeIndex = -1
    for i, window in pairs(WindowManager.windowList) do
        if obj == window then
            removeIndex = i
            break
        end
    end

    if -1 == removeIndex then
        return
    end

    table.remove(WindowManager.windowList, removeIndex)
end

function WindowManager.GetMaxLayerIndex()
    local maxLayerIndex = 0
    for _, window in pairs(WindowManager.windowList) do
        if nil == window.GetWindowLayerIndex then
            goto continue
        end

        local layerIndexTmp = window.GetWindowLayerIndex(window)
        if maxLayerIndex < layerIndexTmp then
            maxLayerIndex = layerIndexTmp
        end

        ::continue::
    end

    return maxLayerIndex
end

--- 当前正被抓取的窗口层数
---@type int
local grabbingWindowLayerIndex = -1

--- 鼠标是否被上层窗口捕获
--- @param layerIndex int
function WindowManager.IsMouseCapturedAboveLayer(layerIndex)
    if false == _Mouse.IsHold(1) then 
        grabbingWindowLayerIndex = -1
    end
    if layerIndex < grabbingWindowLayerIndex then
        return true
    end

    for _, window in pairs(WindowManager.windowList) do
        if nil == window.GetWindowLayerIndex then
            goto continue
        end

        local layerIndexTmp = window.GetWindowLayerIndex(window)
        if layerIndex >= layerIndexTmp then
            goto continue
        end

        local mouseX, mouseY = _Mouse.GetPosition(1, 1)
        if window:CheckPoint(mouseX, mouseY) then
            -- 如果当前窗口被抓取
            if _Mouse.IsHold(1) then
                grabbingWindowLayerIndex = layerIndexTmp
			end

            return true
        end

        ::continue::
    end

    return false
end

return WindowManager
