--[[
	desc: InventoryItemsSys, a system of InventoryItems.
	author: keke <243768648@qq.com>
]]--

local Common = require("UI.ui_common")
local Config = require("config")
local _Base = require("actor.system.base")

local MotionSrv = require("actor.service.motion")
local InputSrv = require("actor.service.input")
local StateSrv = require("actor.service.state")
local InventoryItemsSrv = require("actor.service.InventoryItemsSrv")

local ResLib = require("lib.resource")
local SoundLib = require("lib.sound")

---@class Actor.System.Life : Actor.System
local InventoryItemsSys = require("core.class")(_Base)

function InventoryItemsSys:Ctor(upperEvent)
    _Base.Ctor(self, upperEvent, {
        aspect = true,
        transform = true,
        InventoryItems = true
    }, "InventoryItems")

    -- itemGotSoundData
    self.itemGotSoundData = ResLib.GetSoundData("ui/InventoryItemGot")
end

function InventoryItemsSys:Update()
    if (not Config.user.player) then
        return
    end

    -- 判断物品拾取
    for n = self._list:GetLength(), 1, -1 do
        ---@type Actor.Entity
        local e = self._list:Get(n)
        if e.identity.Job == Common.JobEnum.InventoryItem then
            local inventoryItems = e.InventoryItems
            -- 更新物品项碰撞盒坐标
            MotionSrv.AdjustCollider(e.transform, inventoryItems.Collider, 0, 0)

            local playerTransformPos = Config.user.player.transform.position
            if inventoryItems.Collider:CheckPoint(playerTransformPos.x, playerTransformPos.y,
                    playerTransformPos.z) and
                InputSrv.IsPressed(Config.user.player.input, Common.InputKeyValueStruct.GetItem)
            then
                local articleInfo = inventoryItems:GetFirstNotEmptyItem()
                StateSrv.Play(Config.user.player.states, "sit")
                InventoryItemsSrv.AddItemToEntity(Config.user.player,
                    articleInfo.count, articleInfo.path)

                -- 播放物品放置音效
                SoundLib.Play(self.itemGotSoundData)

                -- destroy inventoryItems entity
                e.identity.destroyProcess = 1
                break
            end
        end
    end
end

if (Config.debug.InventoryItems) then
    function InventoryItemsSys:Draw()

        for n = 1, self._list:GetLength() do
            local e = self._list:Get(n) ---@type Actor.Entity
            if e.identity.Job == Common.JobEnum.InventoryItem then
                local inventoryItems = e.InventoryItems
                inventoryItems.Collider:Draw()
            end
        end
    end
end

return InventoryItemsSys
