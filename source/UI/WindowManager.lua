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

---
---@param window Window
function WindowManager.SetWindowToTopLayer(window)
    -- 排序
    ---@type table<number, Window>
    local bottomToTopWindowList = {}
    ---@type table<number, Window>
    local toolTipWindowList = {}
    while(#WindowManager.windowList > 0) do
        local bottomLayerWindowIndex = 1
        ---@type Window
        local bottomLayerWindow = WindowManager.windowList[1]
        if bottomLayerWindow:IsTipToolWindow() then
            table.insert(toolTipWindowList, bottomLayerWindow)
            table.remove(WindowManager.windowList, bottomLayerWindowIndex)
            goto dispathLoopContinue
        end

        for i, windowTmp in pairs(WindowManager.windowList) do
            if bottomLayerWindow:GetWindowLayerIndex() > windowTmp:GetWindowLayerIndex() then
                bottomLayerWindowIndex = i
                bottomLayerWindow = windowTmp
            end
        end

        table.insert(bottomToTopWindowList, bottomLayerWindow)
        table.remove(WindowManager.windowList, bottomLayerWindowIndex)

        ::dispathLoopContinue::
    end

    -- 重新设置层索引，使入参window的索引为最大值
    local layerIndex = 1
    for i, windowTmp in pairs(bottomToTopWindowList) do
        if windowTmp ~= window then
            windowTmp:SetWindowLayerIndex(layerIndex)
            table.insert(WindowManager.windowList, windowTmp)

            layerIndex = layerIndex + 1
        end
    end

    if window ~= nil then
        window:SetWindowLayerIndex(layerIndex)
        table.insert(WindowManager.windowList, window)
        layerIndex = layerIndex + 1
    end

    -- 将悬浮提示窗口放到最顶层
    for i, windowTmp in pairs(toolTipWindowList) do
        if windowTmp ~= window then
            windowTmp:SetWindowLayerIndex(layerIndex)
            table.insert(WindowManager.windowList, windowTmp)

            layerIndex = layerIndex + 1
        end
    end
end

--- 重新排序窗口列表
function WindowManager.SortWindowList()
    WindowManager.SetWindowToTopLayer(nil)
end

return WindowManager
