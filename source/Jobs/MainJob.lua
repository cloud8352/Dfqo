--[[
	desc: MainJob, a thread job to execute main tasks.
	author: keke
]]--

local _MATH = require("lib.math")

-- map.matrix 需要依赖 love.graphics 模块
require("love.graphics")
local Matrix = require("map.Matrix")
require("love.timer")

local JobsCommon = require("Jobs.JobsCommon")

---@type table<int, TaskInfo>
local MapOfIdToRunningTask = {}

local MapMatrix = Matrix.New()

--------------------------------------------------------------------------
---@param mapInfo MapInfo
local function initMap(mapInfo)
    MapMatrix = Matrix.New(mapInfo.GridSize)
    MapMatrix:Reset(mapInfo.X, mapInfo.Y, mapInfo.Width, mapInfo.Height, true)

    if (mapInfo.ObstaclePosList) then
        for n = 1, #mapInfo.ObstaclePosList do
            local pos = mapInfo.ObstaclePosList[n]
            MapMatrix:SetNode(pos.X, pos.Y, true, true)
        end
    end
end

---@param x int
---@param y int
---@param isObs boolean
local function setObstacle(x, y, isObs)
    MapMatrix:SetNode(x, y, isObs, true)
end

---@param taskInfo TaskInfo
local function addTask(taskInfo)
    -- print("addTask(taskInfo)")
    MapOfIdToRunningTask[taskInfo.Id] = taskInfo
end

---@param moveInfo MoveInfo
local function execMoveTask(moveInfo)
    -- print("execMoveTask(moveInfo)", moveInfo.Value)

    local value = _MATH.GetFixedDecimal(moveInfo.Value)

    if (moveInfo.Type == JobsCommon.AxisType.Z) then
        moveInfo.DestZPos = moveInfo.SrcZPos + value
    else
        local nx = MapMatrix:ToNode(moveInfo.SrcXPos, "x")
        local ny = MapMatrix:ToNode(moveInfo.SrcYPos, "y")
        -- 是否碰到了障碍物
        local isCross = false
        local isX = moveInfo.Type == JobsCommon.AxisType.X
        local direction = _MATH.GetDirection(value)

        local newPos = 0.0
        local typeStr = "x"
        if moveInfo.Type == JobsCommon.AxisType.X then
            newPos = moveInfo.SrcXPos + value
            typeStr = "x"
        elseif moveInfo.Type == JobsCommon.AxisType.Y then
            newPos = moveInfo.SrcYPos + value
            typeStr = "y"
        elseif moveInfo.Type == JobsCommon.AxisType.Z then
            newPos = moveInfo.SrcZPos + value
            typeStr = "z"
        end
        local target = MapMatrix:ToNode(newPos, typeStr)

        local current = isX and nx or ny
        local range = math.abs(current - target)

        for n = 1, range do
            local isObs

            if (isX) then
                isObs = MapMatrix:GetNode(nx + direction * n, ny, true)
            else
                isObs = MapMatrix:GetNode(nx, ny + direction * n, true)
            end

            if (isObs) then
                if (direction > 0) then
                    newPos = MapMatrix:ToPosition(current + n, typeStr) - 1
                else
                    newPos = MapMatrix:ToPosition(current - n + 1, typeStr)
                end

                isCross = true
                break
            end
        end

        if (isCross) then
            -- transform.obstructCaller:Call()
        end

        -- 更新 目的坐标
        moveInfo.DestXPos = moveInfo.SrcXPos
        moveInfo.DestYPos = moveInfo.SrcYPos
        moveInfo.DestZPos = moveInfo.SrcZPos
        if moveInfo.Type == JobsCommon.AxisType.X then
            moveInfo.DestXPos = newPos
        elseif moveInfo.Type == JobsCommon.AxisType.Y then
            moveInfo.DestYPos = newPos
        elseif moveInfo.Type == JobsCommon.AxisType.Z then
            moveInfo.DestZPos = newPos
        end
    end
end

---@param getPathInfo GetPathInfo
local function execGetPathTask(getPathInfo)
    local info = getPathInfo
    local path = MapMatrix:GetPath(info.SrcXPos, info.SrcYPos, info.DestXPos, info.DestYPos)
    if path == nil then
        return
    end

    info.RetPath = {}
    for i, point in pairs(path) do
        local pos = JobsCommon.NewPosInfo()
        pos.X = point.x
        pos.Y = point.y
        table.insert(info.RetPath, pos)
    end
end

---@param taskInfo TaskInfo
local function execTask(taskInfo)
    local mapInfo = taskInfo.MapInfo
    if JobsCommon.IsEmptyMapInfo(mapInfo) == false then
        initMap(mapInfo)
    end

    local obstacleInfo = taskInfo.ObstacleInfo
    if JobsCommon.IsEmptyObstacleInfo(obstacleInfo) == false then
        setObstacle(obstacleInfo.Pos.X, obstacleInfo.Pos.Y, obstacleInfo.IsObs)
    end

    local moveInfo = taskInfo.MoveInfo
    if JobsCommon.IsEmptyMoveInfo(moveInfo) == false then
        execMoveTask(moveInfo)
    end

    local getPathInfo = taskInfo.GetPathInfo
    if JobsCommon.IsEmptyGetPathInfo(getPathInfo) == false then
        execGetPathTask(getPathInfo)
    end
end

local function run()
    while 1 do

        -- 检测是否需要执行函数
        while 1 do
            ---@type TaskInfo
            local taskInfo = JobsCommon.JobChannel:pop()
            if taskInfo == nil then
                break
            end

            addTask(taskInfo)
        end

        -- 执行任务
        ---@type TaskInfo
        local needExecTask = nil
        for id, task in pairs(MapOfIdToRunningTask) do
            if task then
                needExecTask = task
                break
            end
        end

        if needExecTask then
            execTask(needExecTask)
            JobsCommon.JobFinishedChannel:push(needExecTask)
            MapOfIdToRunningTask[needExecTask.Id] = nil
        else
            -- print("run()", "no task, wait little moment!")
            -- love.timer.sleep(0.002)
        end
    end
end

run()
