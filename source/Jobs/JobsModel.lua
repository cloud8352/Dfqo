--[[
	desc: JobsModel.
	author: keke
]]--

local JobsCommon = require("Jobs.JobsCommon")
local Table = require("lib.table")

local JobsModel = {}

---@class JobsModel.MoveInfoStruct
---@field MoveTaskInfo MoveTaskInfoStruct
---@field Transform Actor.Component.Transform
local MoveInfoStruct = {
    moveTaskInfo = JobsCommon.NewMoveTaskInfo(),
    Transform = nil
}

---@return JobsModel.MoveInfoStruct
local function newMoveInfo()
    return Table.DeepClone(MoveInfoStruct)
end

---@type table<int, JobsModel.MoveInfoStruct>
local MapOfRunningTaskIdToMoveInfo = {}

function JobsModel.Init()
    -- thread init
    local thread = love.thread.newThread("source/Jobs/MotionMoveJob.lua")
    thread:start()
end

function JobsModel.Update()
    while true do
        ---@type MoveTaskInfoStruct
        local finishedTaskInfo = JobsCommon.MotionMoveJobFinishedTaskChannel:pop()
        if finishedTaskInfo == nil then
            break
        end

        -- 更新坐标
        local moveInfo = MapOfRunningTaskIdToMoveInfo[finishedTaskInfo.Id]
        local transform = moveInfo.Transform
        if finishedTaskInfo.Type == JobsCommon.AxisType.X then
            transform.position.x = finishedTaskInfo.DestXPos
        elseif finishedTaskInfo.Type == JobsCommon.AxisType.Y then
            transform.position.y = finishedTaskInfo.DestYPos
        elseif finishedTaskInfo.Type == JobsCommon.AxisType.Z then
            transform.position.z = finishedTaskInfo.DestZPos
        end
        transform.positionTick = 1

        MapOfRunningTaskIdToMoveInfo[finishedTaskInfo.Id] = nil
    end
end

---@param name string
---@param x int
---@param y int
---@param w int
---@param h int
---@param gridSize int
---@param posList table<int, PosStruct>
function JobsModel.InitThreadMapMatrix(name, x, y, w, h, gridSize, posList)
    local funcChannelData = JobsCommon.NewFuncChannelData()
    funcChannelData.FuncName = JobsCommon.MotionMoveJobFunNameInit

    local mapInfo = JobsCommon.NewMapInfo()
    mapInfo.Name = name
    mapInfo.X = x
    mapInfo.Y = y
    mapInfo.Width = w
    mapInfo.Height = h

    mapInfo.GridSize = gridSize

    mapInfo.ObstaclePosList = posList
    funcChannelData.MapInfo = mapInfo

    JobsCommon.MotionMoveJobFuncChannel:push(funcChannelData)
end

---@param x int
---@param y int
---@param isObs boolean
function JobsModel.SetThreadObstacle(x, y, isObs)
    local pos = JobsCommon.NewPos()
    pos.X = x
    pos.Y = y

    local obs = JobsCommon.NewObstacleInfo()
    obs.Pos = pos
    obs.IsObs = isObs

    local funcChannelData = JobsCommon.NewFuncChannelData()
    funcChannelData.FuncName = JobsCommon.MotionMoveJobFunNameSetObstacle
    funcChannelData.ObstacleInfo = obs

    JobsCommon.MotionMoveJobFuncChannel:push(funcChannelData)
end

---@param transform Actor.Component.Transform
---@param aspect Actor.Component.Aspect
---@param type int
---@param value number
function JobsModel.AddMoveTask(transform, type, value)
    for _, info in pairs(MapOfRunningTaskIdToMoveInfo) do
        local typeTmp = info.MoveTaskInfo.Type
        if info.Transform == transform
            and type == typeTmp
        then
            return
        end
    end

    local funcChannelData = JobsCommon.NewFuncChannelData()
    funcChannelData.FuncName = JobsCommon.MotionMoveJobFunNameAddMoveTask

    local taskInfo = JobsCommon.NewMoveTaskInfo()
    taskInfo.Id = JobsModel.createTaskId()
    taskInfo.Type = type

    taskInfo.SrcXPos = transform.position.x
    taskInfo.SrcYPos = transform.position.y
    taskInfo.SrcZPos = transform.position.z

    taskInfo.Value = value

    funcChannelData.MoveTaskInfo = taskInfo

    -- 发送到线程
    JobsCommon.MotionMoveJobFuncChannel:push(funcChannelData)

    -- 添加到 map
    local moveInfo = newMoveInfo()
    moveInfo.MoveTaskInfo = taskInfo
    moveInfo.Transform = transform
    MapOfRunningTaskIdToMoveInfo[taskInfo.Id] = moveInfo
end

--=== private functions

function JobsModel.createTaskId()
    local id = 1
    local idExisted = false
    while id < 999999 do
        idExisted = false
        for idTmp, _ in pairs(MapOfRunningTaskIdToMoveInfo) do
            if id == idTmp then
                idExisted = true
                id = id + 1
                break
            end
        end
        if not idExisted then
            return id
        end
    end

    print("JobsModel.CreateTaskId()", "Running Task count more than 999999!!!")
    return 0
end

return JobsModel
