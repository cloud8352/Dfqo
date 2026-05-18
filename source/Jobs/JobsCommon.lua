--[[
	desc: JobsCommon,
	author: keke
]]--

local Table = require("lib.table")

local JobsCommon = {}

---@class PosInfo
---@field X int
---@field Y int
local PosInfo = {
    X = -1,
    Y = -1
}

---@return PosInfo
function JobsCommon.NewPosInfo()
    return Table.DeepClone(PosInfo)
end

---@class MapInfo
local MapInfo = {
    Name = "",
    X = 0,
    Y = 0,
    Width = 0,
    Height = 0,
    GridSize = 16,
    ---@type table<int, PosInfo>
    ObstaclePosList = {}
}

---@param info MapInfo
function JobsCommon.IsEmptyMapInfo(info)
    return info.Width == 0 or info.Height == 0
end

---@return MapInfo
function JobsCommon.NewMapInfo()
    return Table.DeepClone(MapInfo)
end

---@enum AxisType
---@field X int
---@field Y int
---@field Z int
local AxisType = {
    X = 1,
    Y = 2,
    Z = 3
}
JobsCommon.AxisType = AxisType

---@class MoveInfo
---@field Type int
---@field Value number
---@field SrcXPos int
---@field SrcYPos int
---@field SrcZPos int
---@field DestXPos int
---@field DestYPos int
---@field DestZPos int
local MoveInfo = {
    ---@type int
    Type = AxisType.X,
    Value = 0,
    SrcXPos = 0,
    SrcYPos = 0,
    SrcZPos = 0,
    DestXPos = 0,
    DestYPos = 0,
    DestZPos = 0
}

---@param info MoveInfo
function JobsCommon.IsEmptyMoveInfo(info)
    return info.Value == 0
end

---@return MoveInfo
function JobsCommon.NewMoveInfo()
    return Table.DeepClone(MoveInfo)
end

---@class GetPathInfo
---@field SrcXPos int
---@field SrcYPos int
---@field DestXPos int
---@field DestYPos int
---@field RetPath table<int, PosInfo>
local GetPathInfo = {
    SrcXPos = 0,
    SrcYPos = 0,
    DestXPos = 0,
    DestYPos = 0,
    RetPath = {}
}

---@param info GetPathInfo
function JobsCommon.IsEmptyGetPathInfo(info)
    return info.SrcXPos == 0 and info.SrcYPos == 0
        and info.DestXPos == 0 and info.DestYPos == 0
end

---@return GetPathInfo
function JobsCommon.NewGetPathInfo()
    return Table.DeepClone(GetPathInfo)
end

---@class ObstacleInfo
---@field Pos PosInfo
---@field IsObs boolean
local ObstacleInfo = {
    Pos = PosInfo,
    IsObs = false
}

---@param info ObstacleInfo
function JobsCommon.IsEmptyObstacleInfo(info)
    return info.Pos.X == -1 or info.Pos.Y == -1
end

---@return ObstacleInfo
function JobsCommon.NewObstacleInfo()
    return Table.DeepClone(ObstacleInfo)
end

---@class TaskInfo 任务信息，也用于数据通道
---@field Id int
---@field MapInfo MapInfo
---@field MoveInfo MoveTaskInfo
---@field ObstacleInfo ObstacleInfo
---@field GetPathInfo GetPathInfo
local TaskInfo = {
    Id = 0,
    MapInfo = MapInfo,
    MoveInfo = MoveInfo,
    ObstacleInfo = ObstacleInfo,
    GetPathInfo = GetPathInfo
}

---@return TaskInfo
function JobsCommon.NewTaskInfo()
    return Table.DeepClone(TaskInfo)
end

-- 线程管道 执行函数相关
local ChannelKey = "Job"
JobsCommon.JobChannel = love.thread.getChannel(ChannelKey)

local JobFinishedChannelKey = "JobFinished"
JobsCommon.JobFinishedChannel = love.thread.getChannel(JobFinishedChannelKey)

return JobsCommon
