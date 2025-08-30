--[[
	desc: NpcSys, a system of Npc.
	author: keke <243768648@qq.com>
]]--

local Common = require("UI.ui_common")
local Config = require("config")
local _Base = require("actor.system.base")
local Map = require("map.init")

local MotionSrv = require("actor.service.motion")
local InputSrv = require("actor.service.input")
local NpcSrv = require("actor.service.NpcSrv")
local AspectSrv = require("actor.service.aspect")

local ResLib = require("lib.resource")
local SoundLib = require("lib.sound")
local MouseLib = require("lib.mouse")

---@class Actor.System.NpcSys : Actor.System
local NpcSys = require("core.class")(_Base)

---@type Actor.Entity
local NpcCanInteract = nil

---@param upperEvent WorldEvent
function NpcSys.Create(upperEvent)
    return NpcSys.New(upperEvent)
end

---@param upperEvent WorldEvent
function NpcSys:Ctor(upperEvent)
    _Base.Ctor(self, upperEvent, {
        aspect = true,
        transform = true,
        Npc = true
    }, "Npc")

    ---@type Actor.Entity
    self.canTalkedNpc = nil
end

function NpcSys:Update(dt, rate)
    if (not Config.user.player) then
        return
    end
    local player = Config.user.player

    for n = self._list:GetLength(), 1, -1 do
        ---@type Actor.Entity
        local e = self._list:Get(n)
        -- 更新Npc交互检测碰撞盒坐标
        MotionSrv.AdjustCollider(e.transform, e.Npc.InteractingCollider, 0, 0)
        -- 检测Npc是否被鼠标点击了
        self:judgeWhetherNpcClicked(e)

        if math.abs(e.transform.position.x - player.transform.position.x) < 200
            and math.abs(e.transform.position.y - player.transform.position.y) < 200
            and math.abs(e.transform.position.z - player.transform.position.z) < 100
            and e.Npc.TalkingSource == nil
            and e.Npc.TalkingWaitTimeMs == 0
            and #e.Npc.NormalVoiceDataList > 0
        then
            local index = math.random(1, #e.Npc.NormalVoiceDataList)
            local soundData = e.Npc.NormalVoiceDataList[index]
            e.Npc.TalkingSource = SoundLib.Play(soundData)

            goto continue
        end

        if e.Npc.TalkingSource
            and SoundLib.IsSourceInQueue(e.Npc.TalkingSource) == false
            and SoundLib.IsSourcePlaying(e.Npc.TalkingSource) == false
        then
            e.Npc.TalkingSource = nil
            e.Npc.TalkingWaitTimeMs = 10000
        end
        if e.Npc.TalkingWaitTimeMs > 0 then
            e.Npc.TalkingWaitTimeMs = e.Npc.TalkingWaitTimeMs - dt
        end
        if e.Npc.TalkingWaitTimeMs < 0 then
            e.Npc.TalkingWaitTimeMs = 0
        end

        ::continue::
    end

    self:judgeWhetherNpcCanInteractChanged()
end

---@param entity Actor.Entity
function NpcSys:OnExit(entity)
end

---@param entity Actor.Entity
function NpcSys:judgeWhetherNpcClicked(entity)
    if false == MouseLib.IsPressed(1) then
        return
    end

    local bodySolidRectList = AspectSrv.GetBodySolidRectList(entity.aspect)
    if nil == bodySolidRectList then
        return
    end
    local mousePosXInWorld, mousePosYInWorld = Map.camera:GetMousePosInWorld()
    for _, rect in pairs(bodySolidRectList) do
        if rect:XzCheckPoint(mousePosXInWorld, mousePosYInWorld, 0) then
            NpcSrv.CallerNpcClickedCall(entity)
            break
        end
    end
end

function NpcSys:judgeWhetherNpcCanInteractChanged()
    if nil == Config.user.player then
        return
    end
    if self._list:GetLength() < 1 then
        return
    end

    local playerPos = Config.user.player.transform.position
    -- 找出最近Npc
    ---@type Actor.Entity
    local nearestNpc = nil
    local nearestDistance = -1
    for n = 1, self._list:GetLength() do
        ---@type Actor.Entity
        local e = self._list:Get(n)
        local ePos = e.transform.position
        local distance = (ePos.x - playerPos.x) ^ 2 + (ePos.y - playerPos.y) ^ 2 + (ePos.z - playerPos.z) ^ 2
        if nearestDistance < 0 or nearestDistance > distance then
            nearestNpc = e
            nearestDistance = distance
        end
    end

    -- 最近Npc是否可交互
    if nearestNpc then
        local interactingCollider = nearestNpc.Npc.InteractingCollider
        local playerCollider = AspectSrv.GetPart(Config.user.player.aspect):GetCollider()
        local collided, x, y, z = interactingCollider:Collide(playerCollider)
        if collided then
            if NpcCanInteract ~= nearestNpc then
                NpcCanInteract = nearestNpc
                NpcSrv.CallerNpcCanInteractChangedCall(nearestNpc)
            end
        else
            if NpcCanInteract then
                NpcCanInteract = nil
                NpcSrv.CallerNpcCanInteractChangedCall(nil)
            end
        end
    end
end

return NpcSys
