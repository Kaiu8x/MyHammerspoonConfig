-- =============================================================================
--  Shortcuts for managing windows and window layouts.
--
--  In order to enable this module, just require it
--  from init.lua file inside ~/.hammerspoon/ folder
--
--  author: Adrian Moreno
--  link: https://gist.github.com/Adriem/d8f98308c91a9688f7efaa0f93729f12
-- =============================================================================


-- ---===[ CONFIG ]===----------------------------------------------------------

-- BINDINGS are lists of objects in which the first element represents the
-- prefix of the key strokes and the second one represents the key that will
-- trigger the action

-- ACTIONS are objects that contain a test() method that checks if the
-- action has been performed and an exec() method which performs the action

-- Bindings are automatically bound to actions based on the name of each entry.
-- In order to add a new action, it is necessary to add a new entry with the
-- same key to both objects. When a keystroke is pressed, it will cycle over
-- all the actions. If it finds an action that has already been executed, it
-- will call the next action; otherwise it will call the first one.

function config()

  local cmd_alt = {"cmd", "alt"}
  local cmd_alt_shift = {"cmd", "alt", "shift"}

  hs.window.animationDuration = 0

  bindings = {

    -- Snap a window to a grid on the active screen
    snapWindowLeft   = {cmd_alt, "j"},
    snapWindowRight  = {cmd_alt, "l"},
    snapWindowCenter = {cmd_alt, "k"},
    snapWindowUpDown   = {cmd_alt, "i"},

    -- Move a window to an adjacent screen
    moveToNorthScreen = {cmd_alt_shift, "k"},
    moveToSouthScreen = {cmd_alt_shift, "j"},
    moveToEastScreen  = {cmd_alt_shift, "l"},
    moveToWestScreen  = {cmd_alt_shift, "h"}
  }

  actions = {

    -- Snap a window to a grid on the active screen
    snapWindowLeft = {
      snapLeft(0.5),
      snapLeft(0.35),
      snapLeft(0.65),
    },
    snapWindowRight = {
      snapRight(0.5),
      snapRight(0.35),
      snapRight(0.65),
    },
    snapWindowCenter = {
      snapCenter(0.97, 0.94),
      snapToUnits(hs.layout.maximized),
    },
    snapWindowUpDown = {
      snapVertical(0, 0.5),
      snapVertical(0.5, 0.5),
    },

    -- Move a window to an adjacent screen
    moveToNorthScreen = { moveToScreen('north') },
    moveToSouthScreen = { moveToScreen('south') },
    moveToEastScreen = { moveToScreen('east') },
    moveToWestScreen = { moveToScreen('west') }
  }

  -- For each action binding, cycle through available actions
  for actionName,binding in pairs(bindings) do
    local actionList = actions[actionName] or {}
    local cycleActionsHandler = function()
      local actionIdx = 1  -- Indexes in Lua are 1-based
      while actionIdx < #actionList and not actionList[actionIdx].test() do
        actionIdx = actionIdx + 1
      end
      actionIdx = actionIdx % #actionList + 1

      actionList[actionIdx].exec()
    end

    hs.hotkey.bind(binding[1], binding[2], cycleActionsHandler)
  end
end


-- ---===[ SNAPPING HELPERS ]===------------------------------------------------

function snapLeft(width)
  return snapToUnits({
    x = 0.0,
    y = 0.0,
    w = width,
    h = 1.0
  })
end

function snapRight(width)
  return snapToUnits({
    x = width,
    y = 0.0,
    w = width,
    h = 1.0
  })
end

function snapCenter(width, height)
  return snapToUnits({
    x = (1 - width) / 2,
    y = (1 - height) / 2,
    w = width,
    h = height
  })
end

function snapVertical(y, height)
  return snapToUnits({
    y = y,
    h = height
  })
end

function snapToUnits(positionUnits)
  return {
    -- Return true if the window is already on the target position
    test = (function()
      local screen = hs.screen.mainScreen()
      local window = hs.window.focusedWindow()
      local targetGeom = calculateTargetGeom(positionUnits)

      return matchGrid(window, targetGeom, screen)
    end),

    -- Move the window to the target relative position
    exec = (function()
      local screen = hs.screen.mainScreen()
      local window = hs.window.focusedWindow()
      local targetGeom = calculateTargetGeom(positionUnits)

      window:moveToUnit(targetGeom)
      correctWindowPosition(window, screen)

      if not matchGrid(window, targetGeom, screen) then
        snapExceptions.set(window:id(), targetGeom, window:frame())
      end
    end)
  }
end

function calculateTargetGeom(positionUnits)
  local screenGeom = hs.screen.mainScreen():frame()
  local windowGeom = hs.window.focusedWindow():frame()

  local relativeX = math.ceil(windowGeom.x / screenGeom.w * 1000) / 1000
  local relativeW = math.ceil(windowGeom.w / screenGeom.w * 1000) / 1000
  local relativeY = math.ceil(windowGeom.y / screenGeom.h * 1000) / 1000
  local relativeH = math.ceil(windowGeom.h / screenGeom.h * 1000) / 1000

  return {
    x = positionUnits.x or math.max(relativeX, 0.0),
    y = positionUnits.y or math.max(relativeY,  0.0),
    w = positionUnits.w or math.min(relativeW, 1.0),
    h = positionUnits.h or math.min(relativeH,  1.0)
  }
end

function matchGrid(window, grid, screen)
  local screenGeom = screen:frame()
  local windowGeom = window:frame()
  local expectedGeom = (snapExceptions.get(window:id(), grid)
    or hs.geometry.new(grid):fromUnitRect(screenGeom):floor())

  return windowGeom:equals(expectedGeom)
end

snapExceptions = (function()
  snapExceptions = {}

  function positionToId(positionUnits)
    local re= string.format("%1.3f-%1.3f-%1.3f-%1.3f-%d",
      positionUnits.x, positionUnits.y, positionUnits.w, positionUnits.h,
      hs.screen.mainScreen():id())
    print(re)
    return re
  end

  return {
    set = (function(windowId, expectedPos, actualPos)
      snapExceptions[windowId] = snapExceptions[windowId] or {}
      snapExceptions[windowId][positionToId(expectedPos)] = actualPos
    end),
    get = (function(windowId, expectedPos)
      return (snapExceptions[windowId]
        and snapExceptions[windowId][positionToId(expectedPos)])
    end)
  }
end)()

function correctWindowPosition(window, screen)
  local windowGeometry = window:frame()
  local screenGeometry = screen:frame()
  local newGeom = windowGeometry:copy()
  local applyCorrections = false

  local maxWidth = screenGeometry. x + screenGeometry.w - windowGeometry.x
  if windowGeometry.w > maxWidth then
    applyCorrections = true
    newGeom.x = (screenGeometry.x + screenGeometry.w
      - windowGeometry.w - screenGeometry.h * 0.005)
  end

  -- TODO: Correct vertical position

  if applyCorrections then window:move(newGeom) end
end


-- ---===[ MOVE HELPERS ]===----------------------------------------------------

function moveToScreen(direction)
  -- direction = 'north' | 'south' | 'east' | 'west' (case insensitive)
  return {
    test = (function() return false end),
    exec = (function()
      -- Check if window was `snapped`
      local snapAction = nil
      for actionName, actionList in pairs(actions) do
        if actionName:sub(1,4) == 'snap' then
          snapAction = hs.fnutils.find(actionList, function(action)
            return action.test()
          end)
        end
      end

      -- Move window
      local functionName = ('moveOneScreen'
                             ..direction:sub(1,1):upper()
                             ..direction:sub(2):lower())

      hs.window[functionName](hs.window.focusedWindow(), false, true)
      if snapAction then snapAction.exec() end
    end)
  }
end


-- ---===[ SETUP ]===-----------------------------------------------------------

return config()