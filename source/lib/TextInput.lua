--[[
    desc: TextInput, a lib that encapsulate TextInput function.
    author: keke
]]--

local KeyboardLib = require("lib.keyboard")

---@class Lib.TextInput
local TextInput = {}

local Text = ""

---@param enable boolean
function TextInput.EnableTextInput(enable)
    love.keyboard.setTextInput(enable)
end

---@param text string
function TextInput.SetText(text)
    Text = text
end

function TextInput.GetText()
    return Text
end

function TextInput.LateUpdate()
    Text = ""

    if KeyboardLib.IsHold("lctrl") and KeyboardLib.IsPressed("v") then
        Text = love.system.getClipboardText()
    end
end

return TextInput
