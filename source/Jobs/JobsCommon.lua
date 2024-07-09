--[[
	desc: JobsCommon,
	author: keke
]]--

local Table = require("lib.table")

local JobsCommon = {}

---@class PosStruct
---@field X int
---@field Y int
local PosStruct = {
    X = 0,
    Y = 0
}

---@return PosStruct
function JobsCommon.NewPos()
    return Table.DeepClone(PosStruct)
end

---@class MapInfoStruct
local MapInfoStruct = {
    Name = "",
    X = 0,
    Y = 0,
    Width = 0,
    Height = 0,
    GridSize = 16,
    ---@type table<int, PosStruct>
    ObstaclePosList = {}
}

---@return MapInfoStruct
function JobsCommon.NewMapInfo()
    return Table.DeepClone(MapInfoStruct)
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

---@class MoveTaskInfoStruct
---@field Id int
---@field Type int
---@field Value number
---@field SrcXPos int
---@field SrcYPos int
---@field SrcZPos int
---@field DestXPos int
---@field DestYPos int
---@field DestZPos int
local MoveTaskInfoStruct = {
    Id = 0,
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

---@return MoveTaskInfoStruct
function JobsCommon.NewMoveTaskInfo()
    return Table.DeepClone(MoveTaskInfoStruct)
end

---@class ObstacleInfoStruct
---@field Pos PosStruct
---@field IsObs boolean
local ObstacleInfoStruct = {
    Pos = PosStruct,
    IsObs = false
}

---@return ObstacleInfoStruct
function JobsCommon.NewObstacleInfo()
    return Table.DeepClone(ObstacleInfoStruct)
end

-- 数据通道
---@class FuncChannelDataStruct
---@field FuncName string
---@field MapInfo MapInfoStruct
---@field MoveTaskInfo MoveTaskInfoStruct
---@field ObstacleInfo ObstacleInfoStruct
local FuncChannelDataStruct = {
    FuncName = "",
    MapInfo = MapInfoStruct,
    MoveTaskInfo = MoveTaskInfoStruct,
    ObstacleInfo = ObstacleInfoStruct
}

---@return FuncChannelDataStruct
function JobsCommon.NewFuncChannelData()
    return Table.DeepClone(FuncChannelDataStruct)
end

-- 线程管道 执行函数相关
local FuncChannelKey = "MotionMoveJob_Function"
JobsCommon.MotionMoveJobFuncChannel = love.thread.getChannel(FuncChannelKey)
JobsCommon.MotionMoveJobFunNameInit = "init"
JobsCommon.MotionMoveJobFunNameAddMoveTask = "addMoveTask"
JobsCommon.MotionMoveJobFunNameSetObstacle = "setObstacle"


local FinishedTaskChannelKey = "MotionMoveJob_FinishedTask"
JobsCommon.MotionMoveJobFinishedTaskChannel = love.thread.getChannel(FinishedTaskChannelKey)

return JobsCommon
