-- @TODO Ominifocus or hide everything except current window

-- Constant
hyper = {"cmd", "alt", "ctrl"}
shift_hyper = {"cmd", "alt", "ctrl", "shift"}
cmd_ctrl = {"cmd", "ctrl"}
cmd_alt = {"cmd", "alt"}

col = hs.drawing.color.x11

-- Window management
require("window-management")
require("window-chooser")

-- Debug log info to Hammerspoon Console
function debuglog(text)
    hs.console.printStyledtext("DEBUG: "..tostring(text))
end
