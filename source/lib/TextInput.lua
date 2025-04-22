--[[
    desc: TextInput, a lib that encapsulate TextInput function.
    author: keke
]]--

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
end

return TextInput
