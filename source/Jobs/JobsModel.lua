--[[
	desc: JobsModel.
	author: keke
]]--

local JobsCommon = require("Jobs.JobsCommon")
local Table = require("lib.table")

local JobsModel = {}

---@class JobsModel.MainThreadTaskInfo
---@field MoveInfo MoveInfo
---@field Transform Actor.Component.Transform
---@field GetPathInfo GetPathInfo
---@field MoveAi Actor.Ai.Move
local MainThreadTaskInfo = {
    MoveInfo = JobsCommon.NewMoveInfo(),
    Transform = nil,
    GetPathInfo = JobsCommon.NewGetPathInfo(),
    MoveAi = nil
}

---@return JobsModel.MainThreadTaskInfo
local function newMainThreadTaskInfo()
    return Table.DeepClone(MainThreadTaskInfo)
end

---@type table<int, JobsModel.MainThreadTaskInfo>
local MapOfRunningTaskIdToMainThreadTaskInfo = {}

function JobsModel.Init()
    -- thread init
    local thread = love.thread.newThread("source/Jobs/MainJob.lua")
    thread:start()
end

function JobsModel.Update()
    while true do
        ---@type TaskInfo
        local finishedTaskInfo = JobsCommon.JobFinishedChannel:pop()
        if finishedTaskInfo == nil then
            break
        end

        -- 更新坐标
        local mainThreadTaskInfo = MapOfRunningTaskIdToMainThreadTaskInfo[finishedTaskInfo.Id]
        local transform = mainThreadTaskInfo.Transform
        if transform then
            local moveInfo = finishedTaskInfo.MoveInfo
            if moveInfo.Type == JobsCommon.AxisType.X then
                transform.position.x = moveInfo.DestXPos
            elseif moveInfo.Type == JobsCommon.AxisType.Y then
                transform.position.y = moveInfo.DestYPos
            elseif moveInfo.Type == JobsCommon.AxisType.Z then
                transform.position.z = moveInfo.DestZPos
            end
            transform.positionTick = 1
        end

        -- 获取路径
        local moveAi = mainThreadTaskInfo.MoveAi
        if moveAi then
            local getPathInfo = finishedTaskInfo.GetPathInfo
            moveAi:Slot_GetPathFinished(getPathInfo.RetPath)
        end

        MapOfRunningTaskIdToMainThreadTaskInfo[finishedTaskInfo.Id] = nil
    end
end

---@param name string
---@param x int
---@param y int
---@param w int
---@param h int
---@param gridSize int
---@param posList table<int, PosInfo>
function JobsModel.InitThreadMapMatrix(name, x, y, w, h, gridSize, posList)
    local mapInfo = JobsCommon.NewMapInfo()
    mapInfo.Name = name
    mapInfo.X = x
    mapInfo.Y = y
    mapInfo.Width = w
    mapInfo.Height = h

    mapInfo.GridSize = gridSize
    mapInfo.ObstaclePosList = posList

    local taskInfo = JobsCommon.NewTaskInfo()
    taskInfo.Id = JobsModel.createTaskId()
    taskInfo.MapInfo = mapInfo
    JobsCommon.JobChannel:push(taskInfo)

    -- 添加到 主进程map
    local mainThreadTaskInfo = newMainThreadTaskInfo()
    MapOfRunningTaskIdToMainThreadTaskInfo[taskInfo.Id] = mainThreadTaskInfo
end

---@param x int
---@param y int
---@param isObs boolean
function JobsModel.SetThreadObstacle(x, y, isObs)
    local taskInfo = JobsCommon.NewTaskInfo()
    taskInfo.Id = JobsModel.createTaskId()

    local obs = taskInfo.ObstacleInfo
    obs.IsObs = isObs
    obs.Pos.X = x
    obs.Pos.Y = y

    JobsCommon.JobChannel:push(taskInfo)

    -- 添加到 主进程map
    local mainThreadTaskInfo = newMainThreadTaskInfo()
    MapOfRunningTaskIdToMainThreadTaskInfo[taskInfo.Id] = mainThreadTaskInfo
end

---@param transform Actor.Component.Transform
---@param aspect Actor.Component.Aspect
---@param type int
---@param value number
function JobsModel.AddMoveTask(transform, type, value)
    for _, info in pairs(MapOfRunningTaskIdToMainThreadTaskInfo) do
        local typeTmp = info.MoveInfo.Type
        if info.Transform == transform
            and type == typeTmp
        then
            return
        end
    end

    local moveInfo = JobsCommon.NewMoveInfo()
    moveInfo.Type = type

    moveInfo.SrcXPos = transform.position.x
    moveInfo.SrcYPos = transform.position.y
    moveInfo.SrcZPos = transform.position.z
    moveInfo.Value = value

    -- 发送到线程
    local taskInfo = JobsCommon.NewTaskInfo()
    taskInfo.Id = JobsModel.createTaskId()
    taskInfo.MoveInfo = moveInfo
    JobsCommon.JobChannel:push(taskInfo)

    -- 添加到 主进程map
    local mainThreadTaskInfo = newMainThreadTaskInfo()
    mainThreadTaskInfo.MoveInfo = moveInfo
    mainThreadTaskInfo.Transform = transform
    MapOfRunningTaskIdToMainThreadTaskInfo[taskInfo.Id] = mainThreadTaskInfo
end

---@param moveAi Actor.Ai.Move
---@param srcX int
---@param srcY int
---@param destX int
---@param destY int
function JobsModel.AddGetPathTask(moveAi, srcX, srcY, destX, destY)
    local getPathInfo = JobsCommon.NewGetPathInfo()
    getPathInfo.SrcXPos = srcX
    getPathInfo.SrcYPos = srcY
    getPathInfo.DestXPos = destX
    getPathInfo.DestYPos = destY

    -- 发送到线程
    local taskInfo = JobsCommon.NewTaskInfo()
    taskInfo.Id = JobsModel.createTaskId()
    taskInfo.GetPathInfo = getPathInfo
    JobsCommon.JobChannel:push(taskInfo)

    -- 添加到 主进程map
    local mainThreadTaskInfo = newMainThreadTaskInfo()
    mainThreadTaskInfo.GetPathInfo = getPathInfo
    mainThreadTaskInfo.MoveAi = moveAi
    MapOfRunningTaskIdToMainThreadTaskInfo[taskInfo.Id] = mainThreadTaskInfo
end

--=== private functions

function JobsModel.createTaskId()
    local id = 1
    while id < 999999 do
        if MapOfRunningTaskIdToMainThreadTaskInfo[id] == nil then
            return id
        end

        id = id + 1
    end

    print("JobsModel.CreateTaskId()", "Running Task count more than 999999!!!")
    return 0
end

return JobsModel
