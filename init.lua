-- @TODO Ominifocus or hide everything except current window

-- Constant
local hyper = {"cmd", "alt", "ctrl"}
local shift_hyper = {"cmd", "alt", "ctrl", "shift"}
local cmd_ctrl = {"cmd", "ctrl"}
local cmd_alt = {"cmd", "alt"}

local col = hs.drawing.color.x11



-- Debug log info to Hammerspoon Console
function debuglog(text)
    hs.console.printStyledtext("DEBUG: "..tostring(text))
end


hs.hotkey.bind({"cmd", "alt", "ctrl"}, "W", function()
    hs.alert.show("Hello World!")
end)