--[[
	desc: WindowManager, window manager.
	author: keke <243768648@qq.com>
	since: 2022-10-25
	alter: 2022-10-25
]] --

local _Mouse = require("lib.mouse")
local Touch = require("lib.touch")
local _TABLE = require("lib.table")

local WindowManager = {}
-- 默认窗口
---@type Window
WindowManager.DefaultWindow = nil

---@type table<number, Window>
WindowManager.windowList = {}

---@class WindowWidgetStruct
local WindowWidgetStruct = {
    ---@type Window
    Window = nil,
    ---@type Widget
    Widget = nil
}

---@type table<number, WindowWidgetStruct>
local windowWidgetList = {}

---
---@param windowWidgetA WindowWidgetStruct
---@param windowWidgetB WindowWidgetStruct
---@return boolean
local function windowWidgetListSortFuc(windowWidgetA, windowWidgetB)
    return windowWidgetA.Window:GetWindowLayerIndex() < windowWidgetB.Window:GetWindowLayerIndex()
end

function WindowManager.Init()
    local Window = require("UI.Window")
    WindowManager.DefaultWindow = Window.New()
end

---@param obj Window
function WindowManager.AppendToWindowList(obj)
    table.insert(WindowManager.windowList, obj)
end

---@param obj Window
function WindowManager.RemoveFromWindowList(obj)
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

    -- 从 windowWidgetList 中移除
    for i = #windowWidgetList, 1, -1 do
        local windowWidget = windowWidgetList[i]
        if windowWidget.Window == obj then
            table.remove(windowWidgetList, i)
        end
    end
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
---@type number
local grabbingWindowLayerIndex = -1

--- 鼠标是否被上层窗口捕获
--- @param layerIndex number
function WindowManager.IsMouseCapturedAboveLayer(layerIndex)
    if false == _Mouse.IsHold(1) then 
        grabbingWindowLayerIndex = -1
    end
    if layerIndex < grabbingWindowLayerIndex then
        return true
    end

    for _, window in pairs(WindowManager.windowList) do
        if window:IsVisible() == false then
            goto continue
        end

        local layerIndexTmp = window:GetWindowLayerIndex()
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

--- 触控是否被上层窗口捕获
---@param w Window
---@return idList table<number, string>
function WindowManager.GetWindowCapturedTouchIdList(w)
    ---@type table<number, string>
    local idList = {} -- 处于待获取窗口内且没有被上层窗口捕获的触控点
    ---@type table<number, string>
    local idListTmp = {} -- 初步过滤出处于待获取窗口内的触控点
    for id, point in pairs(Touch.GetPoints()) do
        if (point) then
            if w:CheckPoint(point.x, point.y) then
                table.insert(idListTmp, id)
            end
        end
    end

    local layerIndex = w:GetWindowLayerIndex()
    -- 过滤出处于待获取窗口内且没有被上层窗口捕获的触控点
    for _, id in pairs(idListTmp) do
        local whetherPointIsCapturedByUpperWindow = false
        local point = Touch.GetPoint(id)
        for _, window in pairs(WindowManager.windowList) do
            if window:IsVisible() == false then
                goto continue
            end
            if nil == window.GetWindowLayerIndex then
                goto continue
            end
    
            local layerIndexTmp = window.GetWindowLayerIndex(window)
            if layerIndex >= layerIndexTmp then
                goto continue
            end
            if window:CheckPoint(point.x, point.y) then
                whetherPointIsCapturedByUpperWindow = true
                break
            end

            ::continue::
        end

        if not whetherPointIsCapturedByUpperWindow then
            table.insert(idList, id)
        end
    end

    return idList
end

---
---@param window Window
function WindowManager.SetWindowToTopLayer(window)
    -- 排序
    ---@type table<number, Window>
    local bottomToTopWindowList = {}
    ---@type table<number, Window>
    local topHintWindowList = {}
    ---@type table<number, Window>
    local toolTipWindowList = {}
    for i, windowTmp in pairs(WindowManager.windowList) do
        -- 拆分出 置顶窗口
        if windowTmp:IsWindowStayOnTopHint() then
            table.insert(topHintWindowList, windowTmp)
            goto dispatchLoopContinue
        end
        -- 拆分出 提示工具窗口
        if windowTmp:IsTipToolWindow() then
            table.insert(toolTipWindowList, windowTmp)
            goto dispatchLoopContinue
        end

        -- 拆分出 普通窗口
        table.insert(bottomToTopWindowList, windowTmp)

        ::dispatchLoopContinue::
    end

    -- 重新设置层索引，使入参window的索引为最大值
    WindowManager.windowList = {}
    local layerIndex = 1
    for i, windowTmp in pairs(bottomToTopWindowList) do
        if windowTmp ~= window then
            windowTmp:SetWindowLayerIndex(layerIndex)
            table.insert(WindowManager.windowList, windowTmp)

            layerIndex = layerIndex + 1
        end
    end

    if window ~= nil and window:IsWindowStayOnTopHint() == false and
        window:IsTipToolWindow() == false
    then
        window:SetWindowLayerIndex(layerIndex)
        table.insert(WindowManager.windowList, window)
        layerIndex = layerIndex + 1
    end

    -- 将悬置顶窗口放到最顶层
    for i, windowTmp in pairs(topHintWindowList) do
        if windowTmp ~= window then
            windowTmp:SetWindowLayerIndex(layerIndex)
            table.insert(WindowManager.windowList, windowTmp)

            layerIndex = layerIndex + 1
        end
    end

    -- 将悬浮提示窗口放到最顶层
    for i, windowTmp in pairs(toolTipWindowList) do
        if windowTmp ~= window then
            windowTmp:SetWindowLayerIndex(layerIndex)
            table.insert(WindowManager.windowList, windowTmp)

            layerIndex = layerIndex + 1
        end
    end

    -- 整理 windowWidgetList
    table.sort(windowWidgetList, windowWidgetListSortFuc)
end

--- 重新排序窗口列表
function WindowManager.SortWindowList()
    WindowManager.SetWindowToTopLayer(nil)
end

---
---@param window Window
---@param widget Widget
function WindowManager.AppendWindowWidget(window, widget)
    -- 将组件添加到窗口组件列表
    ---@type WindowWidgetStruct
    local windowWidget = _TABLE.DeepClone(WindowWidgetStruct)
    windowWidget.Window = window
    windowWidget.Widget = widget
    table.insert(windowWidgetList, windowWidget)
end

function WindowManager.GetWindowWidgetList()
    return windowWidgetList
end

return WindowManager
