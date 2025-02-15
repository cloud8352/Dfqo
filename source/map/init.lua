--[[
	desc: MAP, game's stage.
	author: Musoucrow
	since: 2018-11-10
	alter: 2019-9-21
]]
--

local _CONFIG = require("config")

local _TIME = require("lib.time")
local _SOUND = require("lib.sound")
local _MUSIC = require("lib.music")
local _SYSTEM = require("lib.system")
local _STRING = require("lib.string")
local _GRAPHICS = require("lib.graphics")
local _RESOURCE = require("lib.resource")
local _FILE = require("lib.file")
local _ACTOR_FACTORY = require("actor.factory")
local _ACTOR_RESMGR = require("actor.resmgr")

local _Caller = require("core.caller")
local _Curtain = require("graphics.curtain")
local _Color = require("graphics.drawunit.color")
local _Layer = require("graphics.drawable.layer")
local _Sprite = require("graphics.drawable.sprite")
local _Frameani = require("graphics.drawable.frameani")
local _Particle = require("graphics.drawable.particle")
local _BackGround = require("map.background")
local _Camera = require("map.camera")
local _Matrix = require("map.matrix")
local JobsCommon = require("Jobs.JobsCommon")
local JobsModel = require("Jobs.JobsModel")

---@class MAP
---@field camera Map.Camera
local _MAP = {
    isPaused = false,
    curtain = _Curtain.New(),
    matrixGroup = {
        normal = _Matrix.New(16),
        object = _Matrix.New(64),
        up = _Matrix.New(100),
        down = _Matrix.New(100)
    },
    info = {
        name = "",
        theme = "",
        isBoss = false,
        isTown = false,
        width = 0,
        height = 0
    },
    values = {
        bgm = {
            enable = true,
            path = nil,
            data = nil
        },
        bgs = {
            path = nil,
            source = nil
        }
    }
}

local _emptyTab = {}
local _const = {
    floorType = { "left", "middle", "right" },
    namedIndex = { 1, 3 },
    namedRange = { 2, 4 },
    normalRange = { 4, 7 },
    floorRange = { 5, 15 },
    upRange = { 0.5, 1 },
    summonRange = { 0, 2 },
    boxRange = { -1, 2 },
    fairyRange = { 0, 1 },
    articleRange = { 4, 7 },
    bossMax = 8,
    runningSoundData = _RESOURCE.GetSoundData("ui/running"),
    scale = 1.4,
    cameraSpeed = 280,
    backgroundRate = {
        far = 0.3,
        near = 0.2
    },
    scope = {
        wv = 0,
        hv = -8,
        uv = -50,
        dv = -40
    },
    wall = {
        left = "effect/weather/wall/left",
        right = "effect/weather/wall/right"
    }
}

local _load = {
    process = 0,
    path = nil,
    caller = _Caller.New(),
    playerInitPos = {}
}

local _layerGroup = {
    far = _BackGround.New(_MAP, _const.backgroundRate.far),
    near = _BackGround.New(_MAP, _const.backgroundRate.near),
    floor = _BackGround.New(_MAP, 0),
    object = _BackGround.New(_MAP, 0),
    effect = _Layer.New()
}

-- ============  boss 方向相关变量 =============
---@class Map.DirectionStruct
local DirectionStruct = {
    None = "none",
    Up = "up",
    Down = "down",
    Left = "left",
    Right = "right"
}
_MAP.DirectionStruct = DirectionStruct

-- 到达领主房间需要经过的房间数
local roomCountNeedToPassToGetToBossRoom = 1
--- 到达领主房间需要经过的房间数范围
_const.roomCountNeedToPassToGetToBossRoomRange = { 1, 7 }
local bossRoomDirection = _MAP.DirectionStruct.None
-- ============ end - boss 方向相关变量 =============

local function _MakeBackground(layer, path, width)
    if (not path) then
        return
    end

    local spriteData = _RESOURCE.GetSpriteData("map/" .. path)
    local count = math.ceil(width / spriteData.w)

    for n = 1, count do
        layer[n] = { sprite = path, x = spriteData.w * (n - 1), y = 0 }
    end
end

---@param layer table
---@param pathList table<number, string>
local function _MakeBackgroundFromPathList(layer, pathList, width)
    if (#pathList < 1) then
        return
    end

    local currentAssignXPos = 0
    while (currentAssignXPos < width) do
        local path = pathList[math.random(1, #pathList)]
        local spriteData = _RESOURCE.GetSpriteData("map/" .. path)

        table.insert(layer, {
            sprite = path,
            x = currentAssignXPos,
            y = 0
        }
        )

        currentAssignXPos = currentAssignXPos + spriteData.w
    end
end

---@param part table|string @floor's part
---@return Map.FloorPart
local function _GetFloor(part)
    if (not part) then
        return
    end

    local path = type(part) == "table" and part[math.random(1, #part)] or part
    local spriteData = _RESOURCE.GetSpriteData("map/" .. path)

    ---@class Map.FloorPart
    return { path = path, spriteData = spriteData }
end

local function _Sorting(a, b)
    local ao = a.sprite.oy or 0
    local bo = b.sprite.oy or 0
    local ad = a.order or 0
    local bd = b.order or 0
    local ai = a.id or 0
    local bi = b.id or 0
    local av = a.y - ao + ad
    local bv = b.y - bo + bd

    if (av == bv) then
        return ai > bi
    end

    return av < bv
end

local function _OnLoadEnd()
    _load.process = 0
end

---@param path string | table
local function _Load(path)
    local data = _RESOURCE.ReadConfig(path, "config/map/instance/%s.cfg")

    if _load.playerInitPos.X or _load.playerInitPos.Y then
        data.init = { x = _load.playerInitPos.X,
            y = _load.playerInitPos.Y
        }
    end

    _MAP.info = data.info
    _load.caller:Call(data)

    local values = _MAP.values

    if (_CONFIG.debug.bgm) then
        if (values.bgm.enable) then
            local musicData

            if (values.bgm.path == data.info.bgm) then
                musicData = values.bgm.data
            else
                musicData = _RESOURCE.NewMusic(data.info.bgm)
                values.bgm.data = musicData
                values.bgm.path = data.info.bgm
            end

            if (musicData) then
                _MUSIC.Play(musicData)
            end
        end

        if (values.bgs.path ~= data.info.bgs) then
            if (values.bgs.source) then
                values.bgs.source:stop()
            end

            values.bgs.path = data.info.bgs

            if (values.bgs.path and values.bgs.path ~= "") then
                local fullBgsPath = "asset/sound/map/" .. values.bgs.path .. ".ogg"
                if false == _FILE.Exists(fullBgsPath) then
                    fullBgsPath = "asset/sound/map/" .. values.bgs.path .. ".mp3"
                end
                values.bgs.source = _RESOURCE.NewSource(fullBgsPath)
                values.bgs.source:play()
                values.bgs.source:setVolume(_CONFIG.setting.music)
                values.bgs.source:setLooping(true)
            end
        end
    end

    local matrix = _MAP.matrixGroup.normal

    _MAP.camera:SetWorld(0, 0, data.info.width, data.info.height)
    _MAP.camera:SetPosition(0, 0, true)
    _MAP.curtain.width, _MAP.curtain.height = data.info.width, data.info.height
    matrix:Reset(data.scope.x, data.scope.y, data.scope.w, data.scope.h, true)

    if (data.obstacle) then
        for n = 1, #data.obstacle do
            matrix:SetNode(data.obstacle[n][1], data.obstacle[n][2], true, true)
        end
    end

    -- 初始化 JobsModel 线程地图矩阵
    -- -@type table<int, PosStruct>
    -- local obstaclePosList = {}
    -- if (data.obstacle) then
    --     for n = 1, #data.obstacle do
    --         local pos = JobsCommon.NewPos()
    --         pos.X = data.obstacle[n][1]
    --         pos.Y = data.obstacle[n][2]

    --         table.insert(obstaclePosList, pos)
    --     end
    -- end

    -- JobsModel.InitThreadMapMatrix(data.info.name, data.scope.x, data.scope.y,
    --     data.scope.w, data.scope.h, 16, obstaclePosList)
    -- JobsModel end --

    local pool = {}

    _layerGroup.far:ClearAllSprite()
    _layerGroup.near:ClearAllSprite()
    _layerGroup.floor:ClearAllSprite()
    _layerGroup.object:ClearAllSprite()
    _layerGroup.effect:DelAll()

    if (data.info.NearBgTranslateRate) then
        _layerGroup.near:SetTranslateRate(data.info.NearBgTranslateRate)
    else
        _layerGroup.near:SetTranslateRate(_const.backgroundRate.near)
    end

    for k, v in pairs(_layerGroup) do
        if (data.layer[k]) then
            if (k == "effect") then
                for n = 1, #data.layer[k] do
                    local i = data.layer[k][n]
                    local obj
                    local resData

                    if (i.type == "sprite") then
                        resData = _ACTOR_RESMGR.GetSpriteData(i.path)
                        obj = _layerGroup.effect:Add(_, _, _Sprite.New, resData)
                    elseif (i.type == "frameani") then
                        resData = _ACTOR_RESMGR.GetFrameaniData(i.path)
                        obj = _layerGroup.effect:Add(_, _, _Frameani.New, resData)
                    elseif (i.type == "particle") then
                        resData = _ACTOR_RESMGR.GetParticleData(i.path)
                        obj = _layerGroup.effect:Add(_, _, _Particle.New, resData)
                    end

                    obj:SetAttri("position", i.x, i.y)
                end
            else
                ---@type Map.Background
                local background = v
                for n = 1, #data.layer[k] do
                    local i = data.layer[k][n]
                    local spriteData = pool[i.sprite]

                    if (not spriteData) then
                        spriteData = _RESOURCE.NewSpriteData("map/" .. i.sprite)
                        pool[i.sprite] = spriteData
                    end

                    i.sprite = spriteData

                    local mapBgItemInfo = _BackGround.NewMapBgItemInfo()
                    mapBgItemInfo.Id = i.id
                    mapBgItemInfo.Order = i.order
                    mapBgItemInfo.SpriteData = spriteData

                    local drawableSprite = _Sprite.New()
                    drawableSprite:SwitchRect(true)
                    drawableSprite:SetAttri("position", i.x, i.y)

                    i.sx = i.sx or 1
                    i.sy = i.sy or 1
                    drawableSprite:SetAttri("scale", i.sx, i.sy)
                    
                    drawableSprite:SetData(spriteData)
                    mapBgItemInfo.DrawableSprite = drawableSprite

                    -- x y w h
                    mapBgItemInfo.X = drawableSprite:GetRectValue("x")
                    mapBgItemInfo.Y = drawableSprite:GetRectValue("y")
                    mapBgItemInfo.W = drawableSprite:GetRectValue("w")
                    mapBgItemInfo.H = drawableSprite:GetRectValue("h")

                    background:AppendItem(mapBgItemInfo)
                end

                if (k ~= "floor") then
                    table.sort(data.layer[k], _Sorting)

                    background:Sort()
                end
            end
        elseif (v.SetImage) then
            v:SetImage()
        end
    end

    _load.process = 1

    for n = 1, #data.actor do
        _ACTOR_FACTORY.New(data.actor[n].path, data.actor[n]) -- 地图中的角色由_ACTOR_FACTORY统一管理
    end

    if (data.movie) then
        require("movie.init").Load(data.movie)
    end
end

function _MAP.Init(OnDraw)
    local sx, _ = _SYSTEM.GetScale()
    _MAP.camera = _Camera.New(_const.cameraSpeed, sx * _const.scale, sx * _const.scale)
    _MAP.camera:SetWorld(0, 0, _SYSTEM.GetStdDimensions())

    _MAP.OnDraw = OnDraw
end

function _MAP.Update(dt)
    if (_MAP.isPaused) then
        return
    end

    if (_load.process == 1) then
        if (_CONFIG.debug.map.obstacle) then
            _MAP.matrixGroup.normal:MakeSprite()
        end

        _SYSTEM.Collect()
        _load.process = 2
    end

    _MAP.camera:Update(dt)
    _MAP.curtain:Update(dt)

    _layerGroup.far:Update(dt)
    _layerGroup.near:Update(dt)
    _layerGroup.floor:Update(dt)
    _layerGroup.object:Update(dt)
    _layerGroup.effect:Update(dt)
end

function _MAP.Draw()
    _MAP.camera:Apply()

    _layerGroup.far:Draw()
    _layerGroup.near:Draw()
    _layerGroup.floor:Draw()
    _layerGroup.object:Draw()
    _layerGroup.effect:Draw()

    _MAP.matrixGroup.normal:Draw()
    _MAP.matrixGroup.object:Draw()
    _MAP.matrixGroup.up:Draw()
    _MAP.matrixGroup.down:Draw()

    _MAP.curtain:Draw()
    _MAP.OnDraw()

    _MAP.camera:Reset()
end

function _MAP.RefreshRoomCountNeedToPassToGetToBossRoom()
    roomCountNeedToPassToGetToBossRoom = math.random(_const.roomCountNeedToPassToGetToBossRoomRange[1],
        _const.roomCountNeedToPassToGetToBossRoomRange[2]
    )
end

---@param entity Actor.Entity
function _MAP.UpdateRoomCountNeedToPassToGetToBossRoom(entity)
    if roomCountNeedToPassToGetToBossRoom == 0 then
        _MAP.RefreshRoomCountNeedToPassToGetToBossRoom()
        return
    end

    if entity.transport.direction == bossRoomDirection then
        roomCountNeedToPassToGetToBossRoom = roomCountNeedToPassToGetToBossRoom - 1
    else 
        _MAP.RefreshRoomCountNeedToPassToGetToBossRoom()
    end
end

function _MAP.RefreshBossRoomDirection()
    local dirStrList = { _MAP.DirectionStruct.Up, _MAP.DirectionStruct.Down, _MAP.DirectionStruct.Left, _MAP.DirectionStruct.Right }
    ---@type table<integer, map.assigner.PathGateInfoStruct>
    local pathGateInfoList = {}
    if type(_load.path) == "table" then
        if type(_load.path.pathGateInfoList) == "table" then
            pathGateInfoList = _load.path.pathGateInfoList 
        end
    end
    if #pathGateInfoList > 0 then
        dirStrList = {}
        for i, pathGateInfo in pairs(pathGateInfoList) do
            if pathGateInfo.IsBossGatePath and not pathGateInfo.IsEntrance then
                dirStrList = {}
                table.insert(dirStrList, pathGateInfo.Direction)
                break
            end

            if not pathGateInfo.IsEntrance then
                table.insert(dirStrList, pathGateInfo.Direction)
            end
        end
    end
        
    bossRoomDirection = dirStrList[math.random(1, #dirStrList)]
end

function _MAP.GetBossRoomDirection()
    return bossRoomDirection
end

function _MAP.ResetBossRoomDirection()
    bossRoomDirection = _MAP.DirectionStruct.None
end

--- Make方法是指采用随机生成的方式，直接 _MAP.Load() 时采取固定生成的方式，如城镇
---@param path string
---@param entry Actor.Entity
---@return table @data
function _MAP.Make(path, entry)
    local config = _RESOURCE.ReadConfig(path, "config/map/making/%s.cfg")
    local pathGate = entry and entry.article_pathgate or _emptyTab
    local data = {
        info = {
            name = _STRING.GetVersion(config.info.name),
            theme = config.info.theme,
            width = config.info.width[math.random(1, #config.info.width)],
            height = config.info.height[math.random(1, #config.info.height)],
            isBoss = pathGate.isBoss,
            isTown = config.info.isTown or false,
            horizon = config.floor.horizon, -- 背景与地图的分界y坐标
            bgm = pathGate.isBoss and config.info.bossBgm or config.info.bgm,
            bgs = config.info.bgs,
            NearBgTranslateRate = config.info.NearBgTranslateRate
        },
        init = {},
        scope = {
            x = config.scope.x,
            y = config.scope.y,
            wv = config.scope.wv or _const.scope.wv, -- width 调整值
            hv = config.scope.hv or _const.scope.hv, -- height 调整值
            uv = config.scope.uv or _const.scope.uv, -- up 调整值
            dv = config.scope.dv or _const.scope.dv  -- down 调整值
        },
        actor = config.actor and config.actor.custom or {},
        layer = {
            far = {},
            near = {},
            floor = {},
            object = {},
            effect = {}
        }
    }

    data.scope.w = data.info.width - data.scope.x + data.scope.wv
    data.scope.h = data.info.height - data.scope.y + data.scope.hv

    local objectMatrix = _MAP.matrixGroup.object
    local upMatrix = _MAP.matrixGroup.up
    local downMatrix = _MAP.matrixGroup.down
    local values = _MAP.values

    objectMatrix:Reset(data.scope.x, data.scope.y, data.scope.w, data.scope.h, true)
    upMatrix:Reset(data.scope.x, data.info.horizon + data.scope.uv, data.scope.w, upMatrix:GetGridSize(), true)
    downMatrix:Reset(data.scope.x, data.scope.y + data.scope.h + data.scope.dv, data.scope.w, downMatrix:GetGridSize(),
        true)

    local bossProcess = 0
    if (roomCountNeedToPassToGetToBossRoom == 1) then
        bossProcess = 1
    end
    require("map.assigner." .. data.info.theme)(config, data, _MAP.matrixGroup, entry, bossProcess)

    table.insert(data.actor, {
        path = _const.wall.left, -- 左侧障碍墙
        x = 0,
        y = data.info.height
    })

    table.insert(data.actor, {
        path = _const.wall.right, -- 右侧障碍墙
        x = data.info.width,
        y = config.floor.horizon
    })

    -- 创建背景
    _MakeBackground(data.layer.far, config.far, data.info.width)

    if (config.near) then
        _MakeBackground(data.layer.near, config.near, data.info.width)
    elseif (config.nearBgPathList) then
        _MakeBackgroundFromPathList(data.layer.near, config.nearBgPathList, data.info.width)
    end

    if (config.floor) then -- 地面，包括：上（首部）、中（中部）、下（尾部）
        local x = 0

        while (x < data.info.width) do
            local top = _GetFloor(config.floor.top)
            local extra = _GetFloor(config.floor.extra)
            local tail = _GetFloor(config.floor.tail)

            local y = config.floor.y or config.floor.horizon
            local height = config.floor.height or top.spriteData.h

            table.insert(data.layer.floor, { sprite = top.path, x = x, y = y })
            y = y + height

            while (y < data.info.height) do
                table.insert(data.layer.floor, { sprite = extra.path, x = x, y = y })
                y = y + extra.spriteData.h
            end

            if (tail) then
                table.insert(data.layer.floor, { sprite = tail.path, x = x, y = data.info.height - tail.spriteData.h })
            end

            x = x + top.spriteData.w
        end
    end

    if (config.object) then -- 地面上物体，包括：普通地面物体（object.floor）、背景与地图的分界线以上的物体（object.up）
        if (config.object.floor) then
            local a = config.object.floorRange and config.object.floorRange[1] or _const.floorRange[1]
            local b = config.object.floorRange and config.object.floorRange[2] or _const.floorRange[2]

            objectMatrix:Assign(function(x, y)
                local path = config.object.floor[math.random(1, #config.object.floor)]
                table.insert(data.layer.floor, { sprite = path, x = x, y = y })
            end, math.random(a, b), true)
        end

        if (config.object.up) then
            -- 使用矩阵算法布置上侧物体
            local w = upMatrix:GetWidth()
            local a = config.object.upRange and config.object.upRange[1] or _const.upRange[1]
            local b = config.object.upRange and config.object.upRange[2] or _const.upRange[2]

            upMatrix:Assign(function(x, y, id)
                local obj = config.object.up[math.random(1, #config.object.up)]
                table.insert(data.layer.object, { sprite = obj.sprite, x = x, y = y + obj.y, order = obj.order, id = id })
            end, math.random(math.floor(w * a), math.floor(w * b)))
        end
    end

    if (config.actor) then -- 角色，包括：敌人（actor.enemy）、物品（actor.article）、地图靠下方的物品（actor.down）
        local isBoss = data.info.isBoss

        if (config.actor.enemy) then
            if config.actor.enemy.normal
                and #config.actor.enemy.normal > 0
            then
                local normalCount = math.random(_const.normalRange[1], _const.normalRange[2])

                objectMatrix:Assign(function(x, y)
                    local path = config.actor.enemy.normal[math.random(1, #config.actor.enemy.normal)]
                    local direction = math.random(1, 2) == 1 and 1 or -1
                    table.insert(data.actor, {
                        path = "duelist/" .. path,
                        x = x, y = y, direction = direction, camp = 2,
                        dulist = {
                            isEnemy = true
                        }
                    })
                end, normalCount)
            end

            if config.actor.enemy.named
                and #config.actor.enemy.named > 0
            then
                local namedCount = math.random(_const.namedRange[1], _const.namedRange[2])

                objectMatrix:Assign(function(x, y)
                    local path = config.actor.enemy.named[math.random(1, #config.actor.enemy.named)]
                    local direction = math.random(1, 2) == 1 and 1 or -1
                    table.insert(data.actor, {
                        path = "duelist/" .. path,
                        x = x, y = y, direction = direction, camp = 2,
                        dulist = {
                            rank = 1, -- 敌人风险为1，意味着该单位为精英怪
                            isEnemy = true
                        }
                    })
                end, namedCount)
            end

            if (isBoss and config.actor.enemy.boss)
                and #config.actor.enemy.boss > 0
            then
                local bossCount = math.random(1, #config.actor.enemy.boss)
    
                local dulistParam = { rank = 2, isEnemy = true } -- 敌人风险为2，意味着该单位为boss
                objectMatrix:Assign(function(x, y)
                    local path = config.actor.enemy.boss[math.random(1, #config.actor.enemy.boss)]
                    local direction = math.random(1, 2) == 1 and 1 or -1
                    table.insert(data.actor,
                        { path = "duelist/" .. path, x = x, y = y, direction = direction, camp = 2, dulist = dulistParam })
                end, bossCount)
            end
        end

        if (config.actor.article) then
            objectMatrix:Assign(function(x, y)
                local path = config.actor.article[math.random(1, #config.actor.article)]
                table.insert(data.actor, { path = "article/" .. path, x = x, y = y })
            end, math.random(_const.articleRange[1], _const.articleRange[2]))
        end

        if (config.actor.down) then
            downMatrix:Assign(function(x, y)
                local path = config.actor.down[math.random(1, #config.actor.down)]
                table.insert(data.actor, { path = "article/" .. path, x = x, y = y, obstacle = false })
            end, math.random(0, math.floor(downMatrix:GetWidth() * 0.5)))
        end
    end

    if (_CONFIG.debug.map.up) then
        upMatrix:MakeSprite() -- 创建调试所需要显示的图像
    end

    if (_CONFIG.debug.map.down) then
        downMatrix:MakeSprite()
    end

    if (_CONFIG.debug.map.object) then
        objectMatrix:MakeSprite()
    end

    -- local table = require("lib.table")
    -- local file = require("lib.file")

    -- file.WriteFile("1", "testMap.cfg", table.Deserialize(data))

    return data
end

---@param path string
---@param adjust boolean
---@param playerInitPos table
function _MAP.Load(path, adjust, playerInitPos)
    _load.path = path
    _load.adjust = adjust

    if (not adjust) then
        local DIRECTOR = require("director")
        _SOUND.Play(_const.runningSoundData)
        DIRECTOR.Curtain(_Color.black, 0, 500, 1000, _, _, _OnLoadEnd)
    end

    if playerInitPos then
        _load.playerInitPos = playerInitPos
    else
        _load.playerInitPos = {}
    end
end

function _MAP.LoadTick()
    if (_load.path) then
        _Load(_load.path)
        _load.path = nil

        if (_load.adjust) then
            _OnLoadEnd()
        end

        _TIME.Calmness()
    end
end

---@return Map.Matrix
function _MAP.GetMatrix(key)
    key = key or "normal"

    return _MAP.matrixGroup[key]
end

function _MAP.AddLoadListener(...)
    _load.caller:AddListener(...)
end

function _MAP.DelLoadListener(...)
    _load.caller:DelListener(...)
end

---@return int @0=none, 1=waitting, 2=loading
function _MAP.GetLoadProcess()
    if (_load.path or _load.process == 1) then
        return 2
    elseif (_load.process == 2) then
        return 1
    end

    return 0
end

return _MAP
