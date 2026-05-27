--[[
	desc: A pathfinding Api for jumper.
	author: keke
]]--

local JumperGrid = require("3rd.jumper.grid")
local JumperPathfinder = require("3rd.jumper.pathfinder")
local _Point = require("graphics.drawunit.point") ---@type Graphics.Drawunit.Point

---@class Util.PathFinderApi
---@field protected width int
---@field protected height int
local PathFinderApi = require("core.class")()

local _rule = {
    { 0,  -1 },
    { 0,  1 },
    { -1, 0 },
    { 1,  0 },
    { -1, -1 },
    { 1,  -1 },
    { -1, 1 },
    { 1,  1 }
}

---@param type string
function PathFinderApi:Ctor(type)

    self.typeStr = type
    self.finder = nil
    ---@type table<int, table<int>>
    self.map = {}

    self.width = 0
    self.height = 0
end

---@param w int
---@param h int
function PathFinderApi:Reset(w, h)
    self.width = w
    self.height = h

    self.map = {}
    for y = 1, h do
        local rowMap = {}
        for x = 1, w do
            rowMap[x] = 0
        end
        self.map[y] = rowMap
    end

    local walkable = 0
    local grid = JumperGrid(self.map)
    self.finder = JumperPathfinder(grid, self.typeStr, walkable)
end

---@param x int
---@param y int
---@param isObs boolean
function PathFinderApi:SetNode(x, y, isObs)
    if isObs then
        self.map[y][x] = 1
    else
        self.map[y][x] = 0
    end
end

---@param x int
---@param y int
---@return boolean @isObs
function PathFinderApi:GetNode(x, y)
    if (not self:InScope(x, y)) then
        return true
    end

    return self.map[y][x] == 1
end

---@param x int
---@param y int
---@return int, int @open node position
function PathFinderApi:GetOpenNode(x, y)
    if (not self:InScope(x, y)) then
        return
    end

    local add = 1
    while true do
        for n = 1, 8 do
            local tmpX = x + _rule[n][1] * add
            local tmpY = y + _rule[n][2] * add
            if (self.map[tmpY] and self.map[tmpY][tmpX] and tmpX ~= x and tmpY ~= y) then
                return tmpX, tmpY
            end
        end

        add = add + 1
    end
end

---@param x1 int
---@param y1 int
---@param x2 int
---@param y2 int
---@return table<int, Graphics.Drawunit.Point> @path
function PathFinderApi:GetPath(x1, y1, x2, y2)
    if (not self:InScope(x1, y1) or not self:InScope(x2, y2)) then
        return nil
    end

    local path = self.finder:getPath(x1, y1, x2, y2)
    if path then
        ---@type table<int, Graphics.Drawunit.Point>
        local retPath = {}
        for node, step in path:nodes() do
            local point = _Point.New(true, node:getX(), node:getY())
            table.insert(retPath, point)
        end
        return retPath
    end

    return nil
end

---@return int
function PathFinderApi:GetWidth()
    return self.width
end

---@return int
function PathFinderApi:GetHeight()
    return self.height
end

---@return boolean
function PathFinderApi:InScope(x, y)
    if (x < 1 or x > self.width or y < 1 or y > self.height) then
        return false
    end

    return true
end

return PathFinderApi
