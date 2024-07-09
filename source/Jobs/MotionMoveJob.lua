--[[
	desc: MotionMoveJob, a thread job to execute motion move.
	author: keke
]]--

local _MATH = require("lib.math")

-- map.matrix 需要依赖 love.graphics 模块
require("love.graphics")
local Matrix = require("map.matrix")
require("love.timer")

local JobsCommon = require("Jobs.JobsCommon")

---@type table<int, MoveTaskInfoStruct>
local MapOfIdToRunningTask = {}

local MapMatrix = Matrix.New()

--------------------------------------------------------------------------
---@param mapInfo MapInfoStruct
local function init(mapInfo)
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
    -- body
    MapMatrix:SetNode(x, y, isObs, true)
end

---@param taskInfo MoveTaskInfoStruct
local function addMoveTask(taskInfo)
    -- print("addMoveTask(taskInfo)")
    MapOfIdToRunningTask[taskInfo.Id] = taskInfo
end

---@param taskInfo MoveTaskInfoStruct
---@return MoveTaskInfoStruct
local function execAMoveTask(taskInfo)
    -- print("execAMoveTask(taskInfo)", taskInfo.Id, taskInfo.Value)

    local value = _MATH.GetFixedDecimal(taskInfo.Value)

    if (taskInfo.Type == JobsCommon.AxisType.Z) then
        taskInfo.DestZPos = taskInfo.SrcZPos + value
    else
        local nx = MapMatrix:ToNode(taskInfo.SrcXPos, "x")
        local ny = MapMatrix:ToNode(taskInfo.SrcYPos, "y")
        -- 是否碰到了障碍物
        local isCross = false
        local isX = taskInfo.Type == JobsCommon.AxisType.X
        local direction = _MATH.GetDirection(value)

        local newPos = 0.0
        local typeStr = "x"
        if taskInfo.Type == JobsCommon.AxisType.X then
            newPos = taskInfo.SrcXPos + value
            typeStr = "x"
        elseif taskInfo.Type == JobsCommon.AxisType.Y then
            newPos = taskInfo.SrcYPos + value
            typeStr = "y"
        elseif taskInfo.Type == JobsCommon.AxisType.Z then
            newPos = taskInfo.SrcZPos + value
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
        taskInfo.DestXPos = taskInfo.SrcXPos
        taskInfo.DestYPos = taskInfo.SrcYPos
        taskInfo.DestZPos = taskInfo.SrcZPos
        if taskInfo.Type == JobsCommon.AxisType.X then
            taskInfo.DestXPos = newPos
        elseif taskInfo.Type == JobsCommon.AxisType.Y then
            taskInfo.DestYPos = newPos
        elseif taskInfo.Type == JobsCommon.AxisType.Z then
            taskInfo.DestZPos = newPos
        end
    end

    return taskInfo
end

local function run()
    while 1 do

        -- 检测是否需要执行函数
        while 1 do
            ---@type FuncChannelDataStruct
            local funcChannelData = JobsCommon.MotionMoveJobFuncChannel:pop()
            if funcChannelData == nil then
                break
            end

            local funcName = funcChannelData.FuncName
            if funcName == JobsCommon.MotionMoveJobFunNameInit then
                local mapInfo = funcChannelData.MapInfo
                init(mapInfo)

            elseif funcName == JobsCommon.MotionMoveJobFunNameAddMoveTask then
                addMoveTask(funcChannelData.MoveTaskInfo)
            elseif funcName == JobsCommon.MotionMoveJobFunNameSetObstacle then
                local obstacleInfo = funcChannelData.ObstacleInfo
                local pos = obstacleInfo.Pos
                setObstacle(pos.X, pos.Y, obstacleInfo.IsObs)
            end
        end

        -- 执行任务
        ---@type MoveTaskInfoStruct
        local needExecTask = nil
        for id, task in pairs(MapOfIdToRunningTask) do
            if task then
                needExecTask = task
                break
            end
        end

        if needExecTask then
            local finishedTaskInfo = execAMoveTask(needExecTask)
            JobsCommon.MotionMoveJobFinishedTaskChannel:push(finishedTaskInfo)
            MapOfIdToRunningTask[needExecTask.Id] = nil
        else
            -- print("run()", "no task, wait little moment!")
            love.timer.sleep(0.002)
        end
    end
end

run()
