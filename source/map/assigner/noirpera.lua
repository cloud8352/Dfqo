local _PATHGATE = require("map.assigner.pathgate")

---@param matrixGroup table<string, Map.Matrix>
---@param entry Actor.Entity
local function makePathGatesAndWalls(config, data, matrixGroup, entry, bossProcess)
    local laterGate = entry and entry.transport.direction
    local gateMap, bossRoom = _PATHGATE.NewGateMap(data, laterGate, bossProcess)
    local mid = math.floor(matrixGroup.up:GetWidth() * 0.5)
    local horizontalY = math.floor(data.info.height * 0.5) + math.floor(data.info.height * 0.25)
    local theme = data.info.theme

    if (gateMap.up) then
        local x, y = data.scope.x + math.random(mid - 1, mid + 1) * 100 + 50, data.scope.y - 5
        _PATHGATE.MakeUp(x, y, bossRoom, data, matrixGroup, laterGate, bossProcess)
    end

    if (gateMap.down) then
        local x, y = data.scope.x + math.random(mid - 1, mid + 1) * 100 + 50, data.info.height - 5
        _PATHGATE.MakeDown(x, y, bossRoom, data, matrixGroup, laterGate, bossProcess)
    end

    if (gateMap.left) then
        local x, y = data.scope.x - 64, horizontalY
        _PATHGATE.MakeLeft(x, y, bossRoom, data, matrixGroup, laterGate, bossProcess)

        table.insert(data.actor, {
            path = "article/" .. theme .. "/pathgate/rock1",
            x = x,
            y = y - 50
        })
    end

    if (gateMap.right) then
        local x, y = data.scope.x + data.scope.w + 80, horizontalY
        _PATHGATE.MakeRight(x, y, bossRoom, data, matrixGroup, laterGate, bossProcess)

        table.insert(data.actor, {
            path = "article/" .. theme .. "/pathgate/rock2",
            x = x - 100,
            y = y - 60
        })
    end
end

return makePathGatesAndWalls


