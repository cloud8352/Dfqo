local npk = require("npk")

npk.extractNPK("sprite_character_swordman_equipment_weapon_beamswd.NPK")


--[[
-- test libsvpng
local libSavePng = require("libsvpng")
local rgba = {}
for y = 1, 256 do
    for x = 1, 256 do
        rgba[(y - 1) * 256 * 4 + (x - 1) * 4 + 1] = x - 1
        rgba[(y - 1) * 256 * 4 + (x - 1) * 4 + 2] = y - 1
        rgba[(y - 1) * 256 * 4 + (x - 1) * 4 + 3] = 128
        rgba[(y - 1) * 256 * 4 + (x - 1) * 4 + 4] = (x + y) / 2 - 1
    end
end
libSavePng.savePNG("1.png", 256, 256, rgba)
]]
