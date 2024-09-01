--[[
	desc: Background, one of MAP's layer.
	author: Musoucrow
	since: 2018-11-15
	alter: 2018-12-24
]]--

local _TABLE = require("lib.table")
local _GRAPHICS = require("lib.graphics") ---@type Lib.GRAPHICS

local _Sprite = require("graphics.drawable.sprite") ---@type Graphics.Drawable.Sprite

---@class Map.Background
---@field public rate number
local _Background = require("core.class")()

---@class MapBgItemInfo
---@field Id int
---@field Order int
---@field SpriteData Lib.RESOURCE.SpriteData
---@field DrawableSprite Graphics.Drawable.Sprite
---@field X int
---@field Y int
---@field W int
---@field H int
local MapBgItemInfo = {
    Id = 0,
    Order = 0,
    ---@type Lib.RESOURCE.SpriteData
    SpriteData = nil,
    ---@type Graphics.Drawable.Sprite
    DrawableSprite = nil,
    X = 0,
    Y = 0,
    W = 0,
    H = 0
}

---@return MapBgItemInfo
function _Background.NewMapBgItemInfo()
    return _TABLE.DeepClone(MapBgItemInfo)
end

---@param a MapBgItemInfo
---@param b MapBgItemInfo
local function SortingCompFunc(a, b)
    local ao = a.SpriteData.oy or 0
    local bo = b.SpriteData.oy or 0
    local ad = a.Order or 0
    local bd = b.Order or 0
    local ai = a.Id or 0
    local bi = b.Id or 0
    local _, ay = a.DrawableSprite:GetAttri("position")
    local av = ay - ao + ad
    local _, by = b.DrawableSprite:GetAttri("position")
    local bv = by - bo + bd

    if (av == bv) then
        return ai > bi
    end

    return av < bv
end

---@param map MAP
---@param rate number
function _Background:Ctor(map, rate)
    self.map = map

    ---@type table<int, MapBgItemInfo>
    self.list = {}

    ---@type table<int, MapBgItemInfo>
    self.needDrawList = {}

    self.rate = rate
end

function _Background:Update(dt)
    local cameraVisibleAreaW, cameraVisibleAreaH = self.map.camera:GetVisibleArea()
    local cameraXPos, cameraYPos = self.map.camera:GetPosition()

    self.needDrawList = {}
    for _, info in pairs(self.list) do
        local x = info.X
        local y = info.Y
        local w = info.W
        local h = info.H
        if x + w > cameraXPos - cameraVisibleAreaW / 2 and x < cameraXPos + cameraVisibleAreaW / 2 and
            y + h > cameraYPos - cameraVisibleAreaH / 2 and y < cameraYPos + cameraVisibleAreaH / 2
        then
            table.insert(self.needDrawList, info)
        end
    end
end

function _Background:Draw()
    _GRAPHICS.Push()
    _GRAPHICS.Translate(-self.map.camera:GetShift() * self.rate, 0)

    for _, info in pairs(self.needDrawList) do
        info.DrawableSprite:Draw()
    end

    _GRAPHICS.Pop()
end

---@param rate number
function _Background:SetTranslateRate(rate)
    self.rate = rate
end

---@param itemInfo MapBgItemInfo
function _Background:AppendItem(itemInfo)
    table.insert(self.list, itemInfo)
end

function _Background:ClearAllSprite()
    self.list = {}
end

function _Background:Sort()
    table.sort(self.list, SortingCompFunc)
end

return _Background