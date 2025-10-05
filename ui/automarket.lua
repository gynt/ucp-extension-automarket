--automarket
-- jit.off(true, true)

-- debug.sethook(function() local info=debug.getinfo(2); log(VERBOSE, string.format("[%s] %s: line %s: %s", info.what, info.short_src, info.currentline, info.name)) end, "l")

local core = remote.interface.core
local utils = remote.interface.utils

local SETTINGS = {
  ui = {
    buySellSliders = {
      scrollWheel = {
        invert = false,
      }
    }
  },
  logic = {
    marketFee = {
      enabled = false,
      value = 0,
    }
  }
}

remote.events.receive('automarket/config/update', function(key, obj)
  log(DEBUG, string.format("received event: config/update"))
  local effect = false
  if obj then
    if obj.ui then
      if obj.ui.buySellSliders then
        if obj.ui.buySellSliders.scrollWheel then
          if obj.ui.buySellSliders.scrollWheel.invert ~= nil then
            log(DEBUG, string.format("ui.buySellSliders.scrollWheel.invert: %s", obj.ui.buySellSliders.scrollWheel.invert))
            SETTINGS.ui.buySellSliders.scrollWheel.invert = obj.ui.buySellSliders.scrollWheel.invert
            effect = true
          end
        end
      end
    end
    if obj.logic then
      if obj.logic.marketFee then
        if obj.logic.marketFee.enabled ~= nil then
          log(DEBUG, string.format("logic.marketFee.enabled: %s", obj.logic.marketFee.enabled))
          SETTINGS.logic.marketFee.enabled = obj.logic.marketFee.enabled
          effect = true
        end
        if obj.logic.marketFee.sliderValue ~= nil then
          log(DEBUG, string.format("logic.marketFee.value: %s", obj.logic.marketFee.sliderValue))
          SETTINGS.logic.marketFee.value = obj.logic.marketFee.sliderValue
          effect = true
        end
      end
    end
  end
  if effect == false then 
    log(WARNING, string.format("config/update had no effect: %s", json:encode(obj)))
  end
end)

local market = require("ucp/modules/automarket/ui/market")
local feeLogic = require("ucp/modules/automarket/ui/market/fees")
local tradeable = require("ucp/modules/automarket/ui/market/tradeable")
local tradeability = tradeable.tradeablility

local common = require("ucp/modules/automarket/common")
common.loadHeaders()

---@type Menu
local menu
-- menu1337 = api.ui.ModalMenu:createModalMenu({
--   menuID = 1337,
--   menuItemsCount = 100,
--   pPrepare = ffi.cast("void (*)(void)", addr_0x00424c40),
--   pInitial = ffi.cast("void (*)(void)", addr_0x00424cd0),
--   pFrame = ffi.cast("void (*)(void)", addr_0x00424da0),
-- })

local renderText = game.Rendering.renderTextToScreen
local getText = game.Rendering.getTextStringInGroupAtOffset
local textManager = game.Rendering.textManager
-- log(ERROR, string.format("%s", textManager))
-- log(ERROR, string.format("%s", getText(textManager, 224, 7)))

local AUTOMARKET_MODAL_MENU_ID = 2025
local AUTOMARKET_TITLE = "Auto market"
local pAutomarketTitle = registerObject(ffi.new("char[?]", AUTOMARKET_TITLE:len() + 1))
ffi.copy(pAutomarketTitle, AUTOMARKET_TITLE)

--TODO: half implemented
local defaultHelpTxtIndex = 1
local helpTxtIndex = defaultHelpTxtIndex
local helpTxts = {
  "",
  "Auto market will stop buying goods when your gold is less than this value",
  "Auto market is currently switched off. Switch it on to use it",
  "Auto market is currently switched on. Switch it off to stop using it",
  "Close without saving",
  "Save and close",
  "Click to select resource",
  "Buy the resource when you have less than this value",
  "Sell the resource when you have more than this value",
}

-- This line is subject to garbage collection
-- local pAutomarketTitle = registerObject(ffi.new("char const *", AUTOMARKET_TITLE))

log(DEBUG, AUTOMARKET_TITLE, pAutomarketTitle)

log(DEBUG, string.format("pAutomarketDataArray: allocating size: 0x%X", common.sizes.AutoMarketData))
-- allocate permanently
local pAutoMarketDataArray = core.allocate(common.sizes.AutoMarketData)
log(DEBUG, string.format("pAutomarketDataArray: 0x%x", tonumber(pAutoMarketDataArray)))
local automarketDataArray = ffi.cast("AutoMarketData*", pAutoMarketDataArray)
registerObject(automarketDataArray)
local automarketData = automarketDataArray[0]
automarketData.header.version = 1
local autoMarketPlayerDataStructs = automarketData.playerSettings
local pAutoMarketData = tonumber(ffi.cast("unsigned long", automarketDataArray))

local pCurrentlyHoveredGood = ffi.new("int[1]", {})
local pLastSelectedGood = ffi.new("int[1]", {})

local actionCallback1 = function(param)
  if param < 25 then
    if tradeability[param] == 1 then
      if pLastSelectedGood[0] == param then
        pLastSelectedGood[0] = 0
      else
        pLastSelectedGood[0] = param
      end
    end
  elseif param == 28 then
    log(VERBOSE, "save clicked")
    remote.events.send("automarket/ui/data/save", {
      enabled = autoMarketPlayerDataStructs[0].enabled,
    })
    game.UI.activateModalMenu(game.UI.MenuModalComposition1, -1, false)
  elseif param == 29 then
    log(VERBOSE, "close clicked")
    game.UI.activateModalMenu(game.UI.MenuModalComposition1, -1, false)
  end
end

-- local GOODS_DISPLAY_ORDER = {
--   2,
--   3,
--   4,
--   6,
--   7,
--   9,
--   24,

--   16,
--   10,
--   11,
--   12,
--   13,
--   14,
--   23,

--   17,
--   18,
--   19,
--   20,
--   21,
--   22,
-- }

--- heroes order :)
local GOODS_DISPLAY_ORDER = {
  2,
  4,
  6,
  7,
  21,
  22,
  24,
  
  9,
  3,
  14,
  16,
  23,
  19,
  20,

  12,
  13,
  11,
  10,
  17,
  18,
  
}

local GOODS_OFFSETS = ffi.new("IntegerPoint[25]", {})
GOODS_OFFSETS[2] = {
  x = 0,
  y = 4,
}
GOODS_OFFSETS[3] = {
  x = 4,
  y = 6,
}
GOODS_OFFSETS[4] = {
  x = 2,
  y = 4,
}
GOODS_OFFSETS[4] = {
  x = 0,
  y = 2,
}
GOODS_OFFSETS[8] = {
  x = 6,
  y = 0,
}
GOODS_OFFSETS[9] = {
  x = 12,
  y = 0,
}
GOODS_OFFSETS[24] = {
  x = 2,
  y = 2,
}

GOODS_OFFSETS[10] = {
  x = 0,
  y = 6,
}
GOODS_OFFSETS[11] = {
  x = 2,
  y = 6,
}
GOODS_OFFSETS[12] = {
  x = 2,
  y = 6,
}
GOODS_OFFSETS[13] = {
  x = 0,
  y = 6,
}
GOODS_OFFSETS[14] = {
  x = 6,
  y = 4,
}
GOODS_OFFSETS[16] = {
  x = 3,
  y = 2,
}
GOODS_OFFSETS[23] = {
  x = 8,
  y = 0,
}

GOODS_OFFSETS[17] = {
  x = 0,
  y = 2,
}


local GOODS_TEXT_SIZE = 30
local GOODS_BUTTON_BASE_SIZE = 40
local GOODS_START_X = 15 + 2
local GOODS_START_Y = 75
local GOODS_MARGIN = 12
local GOODS_TEXT_MARGIN = 4

local GOODS_BUTTON_WIDTH = GOODS_BUTTON_BASE_SIZE + GOODS_TEXT_SIZE + GOODS_MARGIN
local GOODS_BUTTON_HEIGHT = GOODS_BUTTON_BASE_SIZE
local GOODS_TEXT_START_X = GOODS_BUTTON_BASE_SIZE + GOODS_TEXT_MARGIN
local GOODS_HORIZONTAL_SPACING = (GOODS_BUTTON_WIDTH)
local GOODS_VERTICAL_SPACING = (GOODS_BUTTON_HEIGHT + 10)

local renderCallback1 = function(param)
  ---@type ButtonRenderState
  local state = game.Rendering.ButtonState

  if param < 25 then

    if tradeability[param] ~= 1 then return end

    local renderParam = param
    if param == 7 then renderParam = 8 end

    local playerID = market.pPlayerID[0]
    local resources = market.playerResources[playerID]

    local gmID = (renderParam * 2) + 0x269 - 2
    
    local blendStrength = 6 -- * 2

    local gmX = state.x
    local gmY = state.y

    gmX = gmX + GOODS_OFFSETS[param].x
    gmY = gmY + GOODS_OFFSETS[param].y

    if state.interacting ~= 0 or pLastSelectedGood[0] == param then
      gmID = (renderParam * 2) + 0x26a - 2
      
      if pLastSelectedGood[0] ~= param then
        pCurrentlyHoveredGood[0] = param
      end

      -- Useful for debug purposes but otherwise ugly
      -- game.Rendering.drawBorderBox(game.Rendering.pencilRenderCore, state.x-1, state.y-1, state.x-1 + state.width + 2, state.y-1 + state.height + 2, 0xFFFFFF)
      -- game.Rendering.drawBorderBox(game.Rendering.pencilRenderCore, state.x, state.y, state.x + state.width, state.y + state.height, 0xFFFFFF)
      -- game.Rendering.drawBorderBox(game.Rendering.pencilRenderCore, state.x, state.y, state.x + state.height, state.y + state.height, 0xFFFFFF)

      game.Rendering.renderGM(game.Rendering.textureRenderCore, 46, gmID, gmX, gmY)
    else
      game.Rendering.renderGMWithBlending(game.Rendering.textureRenderCore, 46, gmID, gmX, gmY, blendStrength)
    end

    local stubTxt = ffi.cast("char *", "-")

    local buyTxt = stubTxt
    if  autoMarketPlayerDataStructs[0].buyEnabled[param] then
      buyTxt = ffi.cast("char *", string.format("< %d", autoMarketPlayerDataStructs[0].buyValues[param]))
    end
    game.Rendering.renderTextToScreen(textManager, buyTxt, state.x + GOODS_TEXT_START_X, state.y + 5, 0, 0xB8EEFB, 0x13, 0, 0)

    local sellTxt = stubTxt
    if autoMarketPlayerDataStructs[0].sellEnabled[param] then
      sellTxt = ffi.cast("char *", string.format("> %d", autoMarketPlayerDataStructs[0].sellValues[param]))
    end
    game.Rendering.renderTextToScreen(textManager, sellTxt, state.x + GOODS_TEXT_START_X, state.y + 5 + 0x13, 0, 0xB8EEFB, 0x13, 0, 0)

    local resourceTxt = string.format("%d", resources[param])
    game.Rendering.renderTextToScreenConst(textManager, resourceTxt, state.x + 0, state.y + state.height - 4, 0, 0xB8EEFB, 0x13, 0, 0)
  elseif param == 27 then
    -- renderButtonGM()
    -- or manually:
    local blendStrength = 6 * 2
    if state.interacting ~= 0 then
      blendStrength = blendStrength / 2
    end
    game.Rendering.renderGMWithBlending(game.Rendering.textureRenderCore, 46, 0x2D, state.x - 0, state.y - 0, blendStrength)
  elseif param == 28 then
    -- 0xd0
    local i = 0xCE
    if state.interacting ~= 0 then
      i = i + 1
    end
    game.Rendering.renderGM(game.Rendering.textureRenderCore, 156, i, state.x, state.y)
  elseif param == 29 then
    -- 0xd0
    local i = 0xD0
    if state.interacting ~= 0 then
      i = i + 1
    end
    game.Rendering.renderGM(game.Rendering.textureRenderCore, 156, i, state.x, state.y)
  end



end

-- Note that menu items with parameter 2 to 24 are special...
local function chooseFocusGood()
  if pLastSelectedGood[0] ~= 0 and tradeability[pLastSelectedGood[0]] == 1 then
    return pLastSelectedGood[0]
  elseif menu.menu ~= nil and menu.menu.hoveredItem ~= nil then
    ---@type MenuItem
    local mi = menu.menu.hoveredItem[0]
    local inferredParameter = mi.callbackParameter.parameter
    if inferredParameter > 1 and  inferredParameter < 25 then
      if tradeability[inferredParameter] == 1 then
        local good = inferredParameter
        return good
      end
    end
  end
  return 0
end

local GOODS_SLIDER_MIN = 0
local GOODS_SLIDER_MAX = 256
local GOODS_SLIDER_STEP = 8

local GOLD_SLIDER_MIN = 0
local GOLD_SLIDER_MAX = 40000
local GOLD_SLIDER_STEP = 100

local sliderActionHandler = function(parameter, event, pMinValue, pMaxValue, pCurrentValue)
  ---@type ButtonRenderState
  local state = game.Rendering.ButtonState

  local buying = parameter == 30
  local selling = parameter == 31

  if buying or selling then

    local pValues = autoMarketPlayerDataStructs[0].buyValues
    local pEnabled = autoMarketPlayerDataStructs[0].buyEnabled
    if selling then
      pValues = autoMarketPlayerDataStructs[0].sellValues
      pEnabled = autoMarketPlayerDataStructs[0].sellEnabled
    end

    local good = chooseFocusGood()

    if event == 1 then
      -- initialize (e.g. prepare for render)
      pMinValue[0] = GOODS_SLIDER_MIN
      pMaxValue[0] = GOODS_SLIDER_MAX
      pCurrentValue[0] = pValues[good]
    elseif event == 2 or event == 3 then
      if good == 0 then return end
      -- 2 means shift thumb by clicking next to it
      -- 3 means dragging the thumb
      pEnabled[good] = true
      pValues[good] = pCurrentValue[0]
    elseif event == 4 then
      -- Some kind of "pre", called on almost every render... (I mean callback)
      pMinValue[0] = GOODS_SLIDER_MIN
      pMaxValue[0] = GOODS_SLIDER_MAX
      pCurrentValue[0] = pValues[good]
    elseif (not SETTINGS.ui.buySellSliders.scrollWheel.invert and event == 5) or(SETTINGS.ui.buySellSliders.scrollWheel.invert and event == 6) then
      -- scroll up
      if good == 0 then return end
      local isInside = game.Input.isMouseInsideBox(game.Input.mouseState, state.x, state.y, state.width, state.height)

      if isInside ~= 0 then      
        if tonumber(pValues[good]) > tonumber(pMinValue[0]) then
          pEnabled[good] = true
          pCurrentValue[0] = pCurrentValue[0] - 1
          pValues[good] = pValues[good] - 1
        end
      end
      
    elseif (not SETTINGS.ui.buySellSliders.scrollWheel.invert and event == 6) or(SETTINGS.ui.buySellSliders.scrollWheel.invert and event == 5) then
      -- scroll down

      if good == 0 then return end

      local isInside = game.Input.isMouseInsideBox(game.Input.mouseState, state.x, state.y, state.width, state.height)
      if isInside ~= 0 then      
        if tonumber(pValues[good]) < tonumber(pMaxValue[0]) then
          pEnabled[good] = true
          pCurrentValue[0] = pCurrentValue[0] + 1
          pValues[good] = pValues[good] + 1
        end
      end
    elseif event == 7 then
      -- announce step size
      local pCurrentStep = pCurrentValue
      if good == 0 then 
        pCurrentStep[0] = 0
      else
        pCurrentStep[0] = GOODS_SLIDER_STEP
      end
    else
      log(VERBOSE, string.format("%d, %d, %d, %d, %d", parameter, event, pMinValue[0], pMaxValue[0], pCurrentValue[0]))
    end

    return
  end

  if parameter == 34 then
    -- Gold Threshold

    if event == 1 then
      -- initialize (e.g. prepare for render)
      pMinValue[0] = GOLD_SLIDER_MIN
      pMaxValue[0] = GOLD_SLIDER_MAX
      pCurrentValue[0] = autoMarketPlayerDataStructs[0].goldReserve
    elseif event == 2 or event == 3 then
      -- 2 means shift thumb by clicking next to it
      -- 3 means dragging the thumb
      autoMarketPlayerDataStructs[0].goldReserve = pCurrentValue[0]
    elseif event == 4 then
      -- Some kind of "pre", called on almost every render... (I mean callback)
      pMinValue[0] = GOLD_SLIDER_MIN
      pMaxValue[0] = GOLD_SLIDER_MAX
      pCurrentValue[0] = autoMarketPlayerDataStructs[0].goldReserve

    elseif event == 5 then
      -- scroll up
      local isInside = game.Input.isMouseInsideBox(game.Input.mouseState, state.x, state.y, state.width, state.height)
      if isInside ~= 0 then      
        if tonumber(autoMarketPlayerDataStructs[0].goldReserve) > tonumber(pMinValue[0]) then
          pCurrentValue[0] = pCurrentValue[0] - 1
          autoMarketPlayerDataStructs[0].goldReserve = autoMarketPlayerDataStructs[0].goldReserve - 1
        end
      end
      
    elseif event == 6 then
      -- scroll down
      local isInside = game.Input.isMouseInsideBox(game.Input.mouseState, state.x, state.y, state.width, state.height)
      if isInside ~= 0 then      
        if tonumber(autoMarketPlayerDataStructs[0].goldReserve) < tonumber(pMaxValue[0]) then
          pCurrentValue[0] = pCurrentValue[0] + 1
          autoMarketPlayerDataStructs[0].goldReserve = autoMarketPlayerDataStructs[0].goldReserve + 1
        end
      end
    elseif event == 7 then
      -- announce step size
      local pCurrentStep = pCurrentValue
      pCurrentStep[0] = GOLD_SLIDER_STEP
    else
      log(VERBOSE, string.format("%d, %d, %d, %d, %d", parameter, event, pMinValue[0], pMaxValue[0], pCurrentValue[0]))
    end

    return
  end
end
local pSliderActionHandler = ffi.cast("void (__cdecl *)(int, int, int*, int*, int*)", sliderActionHandler)

local sliderRenderFunction = function(parameter, thumbXPos, sliderValue, thumbWidth, isDragged)
  ---@type ButtonRenderState
  local state = game.Rendering.ButtonState
  -- Well this has be to set to 0 in order for no artifacts to appear
  local interacting = state.interacting + 0
  state.interacting = 0

  local buying = parameter == 30
  local selling = parameter == 31

  if buying or selling then

    local pValues = autoMarketPlayerDataStructs[0].buyValues
    local pEnabled = autoMarketPlayerDataStructs[0].buyEnabled
    local txt = "Buy below"
    if selling then
      pValues = autoMarketPlayerDataStructs[0].sellValues
      pEnabled = autoMarketPlayerDataStructs[0].sellEnabled
      txt = "Sell above"
    end

    game.Rendering.renderButtonBackground(game.Rendering.alphaAndButtonSurface, -1, -1)
    
    local color = game.Rendering.Colors.pGreyishYellow[0]
    if isDragged then 
      color = game.Rendering.Colors.pDarkLime[0]
    end

    local good = chooseFocusGood()
    
    game.Rendering.drawColorBox(game.Rendering.pencilRenderCore, thumbXPos + state.x + 1, state.y + 4, thumbXPos + state.x - 2 + thumbWidth, state.height - 8 + state.y, color)
    
    game.Rendering.renderTextToScreenConst(game.Rendering.textManager, txt, state.x - 75, state.y + 6, 1, 0xCCFAFF, 0x12, 0x0, 0x0)
    if good > 0 and pEnabled[good] then  
      game.Rendering.renderNumberToScreen2(game.Rendering.textManager, pValues[good], state.x - 18, state.y + 6, 1, 0xCCFAFF, 0x12, 0, 0)
    else
      game.Rendering.renderTextToScreenConst(game.Rendering.textManager, "-", state.x - 18, state.y + 6, 1, 0xCCFAFF, 0x12, 0x0, 0x0)
    end

    return
  end
  
  if parameter == 34 then
    -- Gold Threshold
  
    game.Rendering.renderButtonBackground(game.Rendering.alphaAndButtonSurface, -1, -1)
    
    local color = game.Rendering.Colors.pGreyishYellow[0]
    if isDragged then 
      color = game.Rendering.Colors.pDarkLime[0]
    end

    game.Rendering.drawColorBox(game.Rendering.pencilRenderCore, thumbXPos + state.x + 1, state.y + 4, thumbXPos + state.x - 2 + thumbWidth, state.height - 8 + state.y, color)
    
    local txt = "Gold Reserve:"
    game.Rendering.renderTextToScreenConst(game.Rendering.textManager, txt, state.x - 100, state.y + 6, 1, 0xCCFAFF, 0x12, 0x0, 0x0)
    game.Rendering.renderNumberToScreen2(game.Rendering.textManager, autoMarketPlayerDataStructs[0].goldReserve, state.x - 24, state.y + 6, 1, 0xCCFAFF, 0x12, 0, 0)

    

    return
  end
end
local pSliderRenderFunction = ffi.cast("void (__cdecl *)(int, int, int, int, bool)", sliderRenderFunction)

local SLIDER_ROW_X = GOODS_START_X
local SLIDER_ROW_Y = GOODS_START_Y + GOODS_VERTICAL_SPACING * 3 + GOODS_MARGIN
local SLIDER_TEXT_WIDTH = 75

local menuItems = {
  {
    menuItemType = 0x01000000, 
    menuItemActionHandler = {
      simple = ffi.cast("void (__cdecl *)(int)", actionCallback1),
    },
    menuItemRenderFunction = {
      simple = ffi.cast("void (__cdecl *)(int)", renderCallback1),
    },
  },

  -- first row

  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = GOODS_START_X,
        y = GOODS_START_Y,
      }
    },
    itemWidth = GOODS_BUTTON_WIDTH,
    itemHeight = GOODS_BUTTON_HEIGHT,
    callbackParameter = {
      parameter = GOODS_DISPLAY_ORDER[1],
    },
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = GOODS_START_X + GOODS_HORIZONTAL_SPACING,
        y = GOODS_START_Y,
      }
    },
    itemWidth = GOODS_BUTTON_WIDTH,
    itemHeight = GOODS_BUTTON_HEIGHT,
    callbackParameter = {
      parameter = GOODS_DISPLAY_ORDER[2],
    },
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = GOODS_START_X + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING,
        y = GOODS_START_Y,
      }
    },
    itemWidth = GOODS_BUTTON_WIDTH,
    itemHeight = GOODS_BUTTON_HEIGHT,
    callbackParameter = {
      parameter = GOODS_DISPLAY_ORDER[3],
    },
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = GOODS_START_X + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING,
        y = GOODS_START_Y,
      }
    },
    itemWidth = GOODS_BUTTON_WIDTH,
    itemHeight = GOODS_BUTTON_HEIGHT,
    callbackParameter = {
      parameter = GOODS_DISPLAY_ORDER[4],
    },
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = GOODS_START_X + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING,
        y = GOODS_START_Y,
      }
    },
    itemWidth = GOODS_BUTTON_WIDTH,
    itemHeight = GOODS_BUTTON_HEIGHT,
    callbackParameter = {
      parameter = GOODS_DISPLAY_ORDER[5],
    },
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = GOODS_START_X + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING,
        y = GOODS_START_Y,
      }
    },
    itemWidth = GOODS_BUTTON_WIDTH,
    itemHeight = GOODS_BUTTON_HEIGHT,
    callbackParameter = {
      parameter = GOODS_DISPLAY_ORDER[6],
    },
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = GOODS_START_X + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING,
        y = GOODS_START_Y,
      }
    },
    itemWidth = GOODS_BUTTON_WIDTH,
    itemHeight = GOODS_BUTTON_HEIGHT,
    callbackParameter = {
      parameter = GOODS_DISPLAY_ORDER[7],
    },
  },

  -- second row

  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = GOODS_START_X,
        y = GOODS_START_Y + GOODS_VERTICAL_SPACING,
      }
    },
    itemWidth = GOODS_BUTTON_WIDTH,
    itemHeight = GOODS_BUTTON_HEIGHT,
    callbackParameter = {
      parameter = GOODS_DISPLAY_ORDER[8],
    },
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = GOODS_START_X + GOODS_HORIZONTAL_SPACING,
        y = GOODS_START_Y + GOODS_VERTICAL_SPACING,
      }
    },
    itemWidth = GOODS_BUTTON_WIDTH,
    itemHeight = GOODS_BUTTON_HEIGHT,
    callbackParameter = {
      parameter = GOODS_DISPLAY_ORDER[9],
    },
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = GOODS_START_X + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING,
        y = GOODS_START_Y + GOODS_VERTICAL_SPACING,
      }
    },
    itemWidth = GOODS_BUTTON_WIDTH,
    itemHeight = GOODS_BUTTON_HEIGHT,
    callbackParameter = {
      parameter = GOODS_DISPLAY_ORDER[10],
    },
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = GOODS_START_X + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING,
        y = GOODS_START_Y + GOODS_VERTICAL_SPACING,
      }
    },
    itemWidth = GOODS_BUTTON_WIDTH,
    itemHeight = GOODS_BUTTON_HEIGHT,
    callbackParameter = {
      parameter = GOODS_DISPLAY_ORDER[11],
    },
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = GOODS_START_X + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING,
        y = GOODS_START_Y + GOODS_VERTICAL_SPACING,
      }
    },
    itemWidth = GOODS_BUTTON_WIDTH,
    itemHeight = GOODS_BUTTON_HEIGHT,
    callbackParameter = {
      parameter = GOODS_DISPLAY_ORDER[12],
    },
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = GOODS_START_X + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING,
        y = GOODS_START_Y + GOODS_VERTICAL_SPACING,
      }
    },
    itemWidth = GOODS_BUTTON_WIDTH,
    itemHeight = GOODS_BUTTON_HEIGHT,
    callbackParameter = {
      parameter = GOODS_DISPLAY_ORDER[13],
    },
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = GOODS_START_X + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING,
        y = GOODS_START_Y + GOODS_VERTICAL_SPACING,
      }
    },
    itemWidth = GOODS_BUTTON_WIDTH,
    itemHeight = GOODS_BUTTON_HEIGHT,
    callbackParameter = {
      parameter = GOODS_DISPLAY_ORDER[14],
    },
  },

  
  -- third row

  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = GOODS_START_X,
        y = GOODS_START_Y + GOODS_VERTICAL_SPACING + GOODS_VERTICAL_SPACING,
      }
    },
    itemWidth = GOODS_BUTTON_WIDTH,
    itemHeight = GOODS_BUTTON_HEIGHT,
    callbackParameter = {
      parameter = GOODS_DISPLAY_ORDER[15],
    },
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = GOODS_START_X + GOODS_HORIZONTAL_SPACING,
        y = GOODS_START_Y + GOODS_VERTICAL_SPACING + GOODS_VERTICAL_SPACING,
      }
    },
    itemWidth = GOODS_BUTTON_WIDTH,
    itemHeight = GOODS_BUTTON_HEIGHT,
    callbackParameter = {
      parameter = GOODS_DISPLAY_ORDER[16],
    },
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = GOODS_START_X + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING,
        y = GOODS_START_Y + GOODS_VERTICAL_SPACING + GOODS_VERTICAL_SPACING,
      }
    },
    itemWidth = GOODS_BUTTON_WIDTH,
    itemHeight = GOODS_BUTTON_HEIGHT,
    callbackParameter = {
      parameter = GOODS_DISPLAY_ORDER[17],
    },
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = GOODS_START_X + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING,
        y = GOODS_START_Y + GOODS_VERTICAL_SPACING + GOODS_VERTICAL_SPACING,
      }
    },
    itemWidth = GOODS_BUTTON_WIDTH,
    itemHeight = GOODS_BUTTON_HEIGHT,
    callbackParameter = {
      parameter = GOODS_DISPLAY_ORDER[18],
    },
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = GOODS_START_X + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING,
        y = GOODS_START_Y + GOODS_VERTICAL_SPACING + GOODS_VERTICAL_SPACING,
      }
    },
    itemWidth = GOODS_BUTTON_WIDTH,
    itemHeight = GOODS_BUTTON_HEIGHT,
    callbackParameter = {
      parameter = GOODS_DISPLAY_ORDER[19],
    },
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = GOODS_START_X + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING + GOODS_HORIZONTAL_SPACING,
        y = GOODS_START_Y + GOODS_VERTICAL_SPACING + GOODS_VERTICAL_SPACING,
      }
    },
    itemWidth = GOODS_BUTTON_WIDTH,
    itemHeight = GOODS_BUTTON_HEIGHT,
    callbackParameter = {
      parameter = GOODS_DISPLAY_ORDER[20],
    },
  },

  -- Top right buttons
  -- SAVE AND CLOSE
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = 600 - 45,
        y = 408 - 30 - 15,
      }
    },
    itemWidth = 30,
    itemHeight = 30,
    callbackParameter = {
      parameter = 28,
    },
  },
  -- CLOSE
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = 600 - 45,
        y = 15,
      }
    },
    itemWidth = 30,
    itemHeight = 30,
    callbackParameter = {
      parameter = 29,
    },
  },
  -- ENABLE BUTTON
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        -- x = 600 - 10 - 35 - 35 - 155,
        x = 250,
        -- y = 15,
        y = 20 + 15,
      }
    },
    itemWidth = 50,
    itemHeight = 30,
    callbackParameter = {
      parameter = 26,
    },
    menuItemRenderFunction = {
      simple = ffi.cast("void (__cdecl *)(int)", function(parameter)
        ---@type ButtonRenderState
        local state = game.Rendering.ButtonState
        state.interacting = state.interacting or autoMarketPlayerDataStructs[0].enabled
        game.Rendering.renderButtonBackground(game.Rendering.alphaAndButtonSurface, 0, -1)

        local txt = "Off"
        if autoMarketPlayerDataStructs[0].enabled then
          txt = "On"
        end
        game.Rendering.renderTextToScreenConst(game.Rendering.textManager, txt, state.x + 6 + 4, state.y + 6, 0, 0xB8EEFB, 0x12, 0, 0)
      end),
    },
    menuItemActionHandler = {
      simple = ffi.cast("void (__cdecl *)(int)", function(parameter)
        autoMarketPlayerDataStructs[0].enabled = not autoMarketPlayerDataStructs[0].enabled
      end),
    }
  },


  -- Slider: goods image
  {
    menuItemType = 0x01000000, 
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = 600 - 50 - 15 - 25 - 256 - 5 - 140 - 50 + 25,
        y = SLIDER_ROW_Y,
      }
    },
    itemWidth = 65,
    itemHeight = 65,
    callbackParameter = {
      parameter = 1,
    },
    menuItemRenderFunction = {
      simple = ffi.cast("void (__cdecl *)(int)", function(parameter)
        ---@type ButtonRenderState
        local state = game.Rendering.ButtonState
        -- state.interacting = 0
        -- state.height = 60

        -- For some reason this image has the wrong dimensions...
        -- game.Rendering.renderButtonBackground(game.Rendering.alphaAndButtonSurface, -1, -1)
        game.Rendering.drawBlendedBlackBox(game.Rendering.pencilRenderCore, state.x, state.y, state.x + state.width, state.y + state.height, 0x14)

        local good = chooseFocusGood()
        if good ~= 0 then
          local renderParam = good
          if good == 7 then renderParam = 8 end

          local gmID = (renderParam * 2) + 0x269 - 2
          if good == pLastSelectedGood[0] then
            gmID = gmID + 1
          end
          game.Rendering.renderGM(game.Rendering.textureRenderCore, 46, gmID, state.x + 15 + GOODS_OFFSETS[good].x, state.y + 4 + GOODS_OFFSETS[good].y)
          ---TODO: add current player logic to get the right resources...
          local txt = string.format("%d", market.playerResources[market.pPlayerID[0]][good])
          game.Rendering.renderTextToScreenConst(game.Rendering.textManager, txt, state.x + 15 + 20, state.y + 8 + 40, 1, 0xB8EEFB, 0x12, 0, 0) 
        else
          game.Rendering.renderTextToScreenConst(game.Rendering.textManager, "Select", state.x + 6, state.y + 6, 0, 0xB8EEFB, 0x13, 0, 0)
          game.Rendering.renderTextToScreenConst(game.Rendering.textManager, "goods", state.x + 6, state.y + 6 + 0x13, 0, 0xB8EEFB, 0x13, 0, 0)
        end
      end),
    },
    menuItemActionHandler = {
      simple = ffi.cast("void (__cdecl *)(int)", function(parameter)
        
      end),
    },
  },

  -- Slider: Buy value
  {
    menuItemType = 0x01000000, 
  },
  {
    menuItemType = 0x02000005, -- Slider
    menuItemRenderFunctionType = 0x4, -- Slider
    position = {
      position = {
        x = 600 - 50 - 25 - 15 - 256 - 10 + 25,
        y = SLIDER_ROW_Y,
      }
    },
    itemWidth = GOODS_SLIDER_MAX,
    itemHeight = 30, -- seems to be the minimum size...
    callbackParameter = {
      parameter = 30,
    },
    firstItemTypeData = {
      itemsToSkip = GOODS_SLIDER_STEP, -- scroll bar how many steps to jump per click
    },
    menuItemActionHandler = {
      slider = pSliderActionHandler,
    },
    menuItemRenderFunction = {
      slider = pSliderRenderFunction, -- ffi.cast("void (__cdecl *)(int, int, int, int, bool)", core.AOBScan("56 33 F6 39 ? ? ? ? ? 89 ? ? ? ? ? 7E 2B"))
    },
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = 600 - 50 - 15,
        y = SLIDER_ROW_Y,
      }
    },
    itemWidth = 50,
    itemHeight = 30,
    callbackParameter = {
      parameter = 32,
    },
    menuItemRenderFunction = {
      simple = ffi.cast("void (__cdecl *)(int)", function(parameter)
        ---@type ButtonRenderState
        local state = game.Rendering.ButtonState
        game.Rendering.renderButtonBackground(game.Rendering.alphaAndButtonSurface, 0, -1)
        game.Rendering.renderTextToScreenConst(game.Rendering.textManager, "Clear", state.x + 4, state.y + 6, 0, 0xB8EEFB, 0x12, 0, 0)
      end),
    },
    menuItemActionHandler = {
      simple = ffi.cast("void (__cdecl *)(int)", function(parameter)
        local good = pLastSelectedGood[0]
        autoMarketPlayerDataStructs[0].buyEnabled[good] = false
        autoMarketPlayerDataStructs[0].buyValues[good] = 0
      end),
    },
  },

  -- Slider: sell value
  {
    menuItemType = 0x01000000,
  },
  {
    menuItemType = 5, -- Slider
    menuItemRenderFunctionType = 0x4, -- Slider
    position = {
      position = {
        x = 600 - 50 - 25 - 15 - 256 - 10 + 25,
        y = SLIDER_ROW_Y + 30 + 5,
      }
    },
    itemWidth = GOODS_SLIDER_MAX,
    itemHeight = 30, -- seems to be the minimum size...
    callbackParameter = {
      parameter = 31,
    },
    firstItemTypeData = {
      itemsToSkip = GOODS_SLIDER_STEP, -- scroll bar how many steps to jump per click
    },
    menuItemActionHandler = {
      slider = pSliderActionHandler,
    },
    menuItemRenderFunction = {
      slider = pSliderRenderFunction, -- ffi.cast("void (__cdecl *)(int, int, int, int, bool)", core.AOBScan("56 33 F6 39 ? ? ? ? ? 89 ? ? ? ? ? 7E 2B"))
    },
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = 600 - 50 - 15,
        y = SLIDER_ROW_Y + 30 + 5,
      }
    },
    itemWidth = 50,
    itemHeight = 30,
    callbackParameter = {
      parameter = 33,
    },
    menuItemRenderFunction = {
      simple = ffi.cast("void (__cdecl *)(int)", function(parameter)
        ---@type ButtonRenderState
        local state = game.Rendering.ButtonState
        game.Rendering.renderButtonBackground(game.Rendering.alphaAndButtonSurface, 0, -1)
        game.Rendering.renderTextToScreenConst(game.Rendering.textManager, "Clear", state.x + 4, state.y + 6, 0, 0xB8EEFB, 0x12, 0, 0)
      end),
    },
    menuItemActionHandler = {
      simple = ffi.cast("void (__cdecl *)(int)", function(parameter)
        local good = pLastSelectedGood[0]
        autoMarketPlayerDataStructs[0].sellEnabled[good] = false
        autoMarketPlayerDataStructs[0].sellValues[good] = 0
      end),
    },
  },

  -- Slider: Gold Threshold
  {
    menuItemType = 0x01000000,
  },
  {
    menuItemType = 5, -- Slider
    menuItemRenderFunctionType = 0x4, -- Slider
    position = {
      position = {
        x = 600 - 15 - 400,
        y = 408 - 30 - 30 - 15 - 5,
      }
    },
    itemWidth = GOLD_SLIDER_MAX / GOLD_SLIDER_STEP,
    itemHeight = 30, -- seems to be the minimum size...
    callbackParameter = {
      parameter = 34,
    },
    firstItemTypeData = {
      itemsToSkip = 10,
    },
    menuItemActionHandler = {
      slider = pSliderActionHandler,
    },
    menuItemRenderFunction = {
      slider = pSliderRenderFunction, -- ffi.cast("void (__cdecl *)(int, int, int, int, bool)", core.AOBScan("56 33 F6 39 ? ? ? ? ? 89 ? ? ? ? ? 7E 2B"))
    },
  },

  {menuItemType = 0x66, },
}

menu = api.ui.Menu:createMenu({
  menuID = 2024,
  menuItems = ffi.new(string.format("MenuItem[%s]", #menuItems), menuItems)
})

---@type ModalMenu
local ModalMenu = api.ui.ModalMenu
ModalMenu:createModalMenu({
  modalMenuID = AUTOMARKET_MODAL_MENU_ID,
  width = 600,
  height = 408,
  x = -1,
  y = -1,
  borderStyle = 512,
  backgroundColor = 0,
  menuModalRenderFunction = function(x, y, width, height)
    -- render "Auto market"
    game.Rendering.drawBlendedBlackBox(game.Rendering.pencilRenderCore, x+6, y+6, x + 600 - 6, y + 408-6, 0x14)
    game.Rendering.renderTextToScreenConst(game.Rendering.textManager, pAutomarketTitle, x + 20, y + 25, 0, 0xCCFAFF, 0xF, false, 0)
    
    game.Rendering.renderTextToScreenConst(textManager, "Save & Close", x + width - 150, y + height - 45 + 5 + 3, 0, 0xB8EEFB, 0x13, 0, 0)

    local status, err = pcall(function()
      local feeTxt = string.format("Market fee:   %d", 0) .. " %"
      if SETTINGS.logic.marketFee.enabled == true then
        feeTxt = string.format("Market fee:   %d", SETTINGS.logic.marketFee.value) .. " %"
      end
      
      game.Rendering.renderTextToScreenConst(textManager, feeTxt, x + 30, y + height - 45 + 5 + 3, 0, 0xB8EEFB, 0x13, 0, 0)
    end)
    if status == false then log(ERROR, err) end
    
  end,
  menu = menu,
})

local callback = registerObject(function()
  local status, err = pcall(function() 
    for playerID=1,8 do
      local isLordAlive = market.getAliveLordForPlayer(market.UnitsState, playerID) > 0
      local hasMarket = market.marketBuildings[playerID][0] ~= 0
      local am = autoMarketPlayerDataStructs[playerID]
      local resources = market.playerResources[playerID]
      
      if isLordAlive and hasMarket and am.enabled then
        -- selling
        for _, good in ipairs(GOODS_DISPLAY_ORDER) do
          local illegalSellValue = am.buyEnabled[good] and (am.sellValues[good] <= am.buyValues[good])
          if tradeability[good] == 1 and am.sellEnabled[good] then
            if illegalSellValue == false then
              local surplus = resources[good] - am.sellValues[good]
              if surplus > 0 then
                -- Calculate the gold the game would hand out
                local gameReward = market.getSellPrice(market.GameState, playerID, good, surplus)
                local reward = gameReward
                local credit
                local extraGold = false
                local playerCredit = automarketData.playerCredit[playerID].credit
                if SETTINGS.logic.marketFee.enabled == true and SETTINGS.logic.marketFee.value > 0 and SETTINGS.logic.marketFee.value <= 100 then
                  reward, credit = feeLogic.calculateFeedReward(gameReward, SETTINGS.logic.marketFee.value)
                  
                  playerCredit = playerCredit + credit
                  if playerCredit > 100 then
                    extraGold = true

                    playerCredit = playerCredit - 100
                  end
                  automarketData.playerCredit[playerID].credit = playerCredit
                end
                local oldGold = resources[0xF]
                market.sellGoods(market.AICState, playerID, good, surplus)
                -- game handed out too much gold
                resources[0xF] = resources[0xF] - (gameReward - reward)
                if extraGold == true then
                  resources[0xF] = resources[0xF] + 1
                end
                local newGold = resources[0xF]
                log(VERBOSE, string.format("sold goods: %s (amount: %s, raw reward: %s, feed reward: %s, old gold: %s, new gold: %s, credit: %s, credit payout: %s)", good, surplus, gameReward, reward, oldGold, newGold, playerCredit, extraGold))

                -- imagine reward: 
              end
            else
              log(WARNING, string.format("illegal sell value for good: %s (sell: %s, buy: %s)", good, am.sellValues[good], am.buyValues[good]))
            end
          end        
        end

        -- buying
        for _, good in ipairs(GOODS_DISPLAY_ORDER) do
          local availableGold = resources[0xF] - am.goldReserve
          if availableGold < 0 then
            break
          end
          local illegalBuyValue = am.sellEnabled[good] and (am.buyValues[good] >= am.sellValues[good])
          if tradeability[good] == 1 and am.buyEnabled[good] then
            if illegalBuyValue == false then
              local shortage = am.buyValues[good] - resources[good]
              if shortage > 0 then
                local gameCost = market.getBuyPrice(market.GameState, playerID, good, shortage)
                local cost = gameCost
                local credit
                local extraGold = false
                local playerCredit = automarketData.playerCredit[playerID].credit
                if SETTINGS.logic.marketFee.enabled == true and SETTINGS.logic.marketFee.value > 0 and SETTINGS.logic.marketFee.value <= 100 then
                  cost, credit = feeLogic.calculateFeedCost(gameCost, SETTINGS.logic.marketFee.value)
                  playerCredit = playerCredit + credit
                  if playerCredit > 100 then
                    extraGold = true

                    playerCredit = playerCredit - 100
                  end   
                  automarketData.playerCredit[playerID].credit = playerCredit
                end

                if availableGold > cost then
                  local oldGold = resources[0xF]
                  if market.buyGoods(market.AICState, playerID, good, shortage) then
                    -- gameCost has been deducted, deduct remainder
                    resources[0xF] = resources[0xF] - (cost - gameCost)
                    if extraGold then
                      resources[0xF] = resources[0xF] + 1
                    end
                    local newGold = resources[0xF]

                    log(VERBOSE, string.format("bought goods: %s (amount: %s, cost: %s, feed cost: %s, old gold: %s, new gold: %s, credit: %s, credit payout: %s)", good, shortage, gameCost, cost, oldGold, newGold, playerCredit, extraGold))
                  else
                    log(WARNING, string.format("failed to buy goods: %s (amount: %s, gold: %s)", good, shortage, cost))
                  end
                else
                  log(WARNING, string.format("failed to buy goods (not enough gold): %s (amount: %s, gold: %s, available: %s)", good, shortage, cost, availableGold))
                end
              end
            else
              log(WARNING, string.format("failed to buy goods (illegal buy value): %s (buy: %s, sell: %s)", good, am.buyValues[good], am.sellValues[good]))
            end
          end
        end
      end
    end
  end)
  if not status then log(ERROR, string.format("error: %s", err)) end
end)

local pCallback = registerObject(ffi.cast("void (__cdecl *)()", callback))

local trigger = require("ucp/modules/automarket/ui/trigger")

trigger.setAutomarketDataPointer(automarketDataArray)
trigger.setControllingPlayerPoint(market.pPlayerID)

return {
  pAutoMarketData = pAutoMarketData,
  pCallback = tonumber(ffi.cast("unsigned long", pCallback)),
  triggerItem = trigger.triggerItem,
}