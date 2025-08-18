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
end

function NpcSys:Update(dt, rate)
    if (not Config.user.player) then
        return
    end
    local player = Config.user.player

    for n = self._list:GetLength(), 1, -1 do
        ---@type Actor.Entity
        local e = self._list:Get(n)
        -- 
        self:judgeWhetherNpcClicked(e)

        if math.abs(e.transform.position.x - player.transform.position.x) < 200
            and math.abs(e.transform.position.y - player.transform.position.y) < 200
            and math.abs(e.transform.position.z - player.transform.position.z) < 100
            and e.Npc.TalkingSource == nil
            and e.Npc.TalkingWaitTimeMs == 0
        then
            local index = math.random(1, #e.Npc.VoiceDataList)
            local soundData = e.Npc.VoiceDataList[index]
            e.Npc.TalkingSource = SoundLib.Play(soundData)

            goto continue
        end

        if e.Npc.TalkingSource 
            and e.Npc.TalkingSource:isPlaying() == false
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
            NpcSrv.NpcClickedCallerCall(entity)
            break
        end
    end
end

return NpcSys
