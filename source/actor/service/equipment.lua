--[[
	desc: EQUIPMENT, a service for equipment.
	author: Musoucrow
	since: 2018-6-25
	alter: 2019-9-13
]]--

local _RESMGR = require("actor.resmgr")

---@class Actor.Service.EQUIPMENT
local _EQUIPMENT = {}

---@param entity Actor.Entity
---@param key string
---@param data Actor.RESMGR.EquipmentData
function _EQUIPMENT.Set(entity, key, data)
    local container = entity.equipments.container
    local equ = container:Get(key) ---@type Actor.Equipment
    local edata

    if (equ) then
        edata = equ:GetData()
        equ:Exit()
        container:Del(key)
    end

    if (not data and key == "weapon") then
        ---@type Actor.Equipment
        local defaultWeaponEqu = entity.equipments.container:Get("defaultWeapon")
        if defaultWeaponEqu then
            data = defaultWeaponEqu:GetData()
        end
    end

    if (data) then
        equ = data.class.New(entity, key, data)
        container:Add(equ, key)

        -- 隐藏默认武器装扮
        if "defaultWeapon" == key then
            equ:Exit()

            -- 默认武器创建后，重新加载武器
            ---@type Actor.Equipment
            local weaponEqu = container:Get("weapon")
            if weaponEqu then
                weaponEqu:LoadFromData()
            end
        end
    end

    entity.equipments.caller:Call(key, edata)
end

---@param equipments Actor.Component.Equipments
---@return table<string, Actor.Equipment>
function _EQUIPMENT.GetMap(equipments)
    return equipments.container:GetMap()
end

---@param equipments Actor.Component.Equipments
---@param key string
---@return string
function _EQUIPMENT.GetKind(equipments, key)
    return equipments.container:Get(key):GetData().kind
end

---@param equipments Actor.Component.Equipments
---@param key string
---@return string
function _EQUIPMENT.GetSubKind(equipments, key)
    return equipments.container:Get(key):GetData().subKind
end

---@param equipments Actor.Component.Equipments
---@param data Actor.RESMGR.EquipmentData
---@return string
function _EQUIPMENT.GetKey(equipments, data)
    local key
    local container = equipments.container

    if (data.kind == "clothes") then
        key = data.subKind
    else
        key = data.kind
    end

    return key
end

---@param entity Actor.Entity
---@param key string
---@param data Actor.RESMGR.EquipmentData
function _EQUIPMENT.Equip(entity, key, data)
    _EQUIPMENT.Set(entity, key, data)

    return true
end

---@param entity Actor.Entity
---@param key string
function _EQUIPMENT.Del(entity, key)
    _EQUIPMENT.Set(entity, key)
end

return _EQUIPMENT
