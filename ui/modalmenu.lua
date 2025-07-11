-- jit.off(true, true)

--tests/test3-modal.lua
local core = remote.interface.core
local utils = remote.interface.utils

-- menu1337 = api.ui.ModalMenu:createModalMenu({
--   menuID = 1337,
--   menuItemsCount = 100,
--   pPrepare = ffi.cast("void (*)(void)", addr_0x00424c40),
--   pInitial = ffi.cast("void (*)(void)", addr_0x00424cd0),
--   pFrame = ffi.cast("void (*)(void)", addr_0x00424da0),
-- })

local renderText = game.Rendering.renderTextToScreen
local getText = game.Rendering.getTextStringInGroupAtOffset
local textManager = ffi.cast("void *", game.Rendering.pTextManager)
-- log(ERROR, string.format("%s", textManager))
-- log(ERROR, string.format("%s", getText(textManager, 224, 7)))

local AUTOMARKET_TITLE = "Auto Market"
local pAutomarketTitle = registerObject(ffi.new("char[?]", #AUTOMARKET_TITLE + 1))
ffi.copy(pAutomarketTitle, AUTOMARKET_TITLE)

-- This line is subject to garbage collection
-- local pAutomarketTitle = registerObject(ffi.new("char const *", AUTOMARKET_TITLE))

log(WARNING, AUTOMARKET_TITLE, pAutomarketTitle)

ffi.cdef([[
  typedef struct AutoMarketPlayerData {
    bool enabled[25];
    int buyValues[25];
    int sellValues[25];
  } AutoMarketPlayerData;
]])

local autoMarketPlayerDataStructs = ffi.new("AutoMarketPlayerData[9]", {})

local setterValues = ffi.new("int[7]", {0, 1, 2, 5, 10, 20, 50, })

local pCurrentlyHoveredGood = ffi.new("int[1]", {})
local pLastSelectedGood = ffi.new("int[1]", {})

local value1 = 0
local actionCallback1 = function(param)
  log(WARNING, param)
  if param < 25 then
    local v1SwitchNew = not autoMarketPlayerDataStructs[0].enabled[param]
    autoMarketPlayerDataStructs[0].enabled[param] = v1SwitchNew
    pLastSelectedGood = param
  end
  if param == 26 then
    value1 = value1 + 1
  end

  -- if param >= 30 and param <=36 then
  --   local v = setterValues[param-30]
  --   local good = pLastSelectedGood
  --   if v == 0 then
  --     autoMarketPlayerDataStructs[0].buyValues[good] = 0
  --   else
  --     local ov = autoMarketPlayerDataStructs[0].buyValues[good]
  --     autoMarketPlayerDataStructs[0].buyValues[good] = ov + v
  --     log(INFO, string.format("increment buy %s with: %s", good, v))
  --   end
  -- elseif param >= 37 and param <= 43 then
  --   local v = setterValues[param-37]
  --   local good = pLastSelectedGood
  --   if v == 0 then
  --     autoMarketPlayerDataStructs[0].sellValues[good] = 0
  --   else
  --     local ov = autoMarketPlayerDataStructs[0].sellValues[good]
  --     autoMarketPlayerDataStructs[0].sellValues[good] = ov + v
  --   end
  -- end
end

local textureRenderCore = ffi.cast("void *", game.Rendering.pTextureRenderCore)

local pRenderButtonGM = core.AOBScan("56 33 F6 39 ? ? ? ? ? 57 74 05")
local renderButtonGM = ffi.cast("void (*)(void)", pRenderButtonGM)



local renderCallback1 = function(param)
  ---@type ButtonRenderState
  local state = game.Rendering.ButtonState
  if param == 30 then return end
  if param < 25 then
    local gmID = (param * 2) + 0x269 - 2
    if state.interacting ~= 0 then
      gmID = (param * 2) + 0x26a - 2
      pCurrentlyHoveredGood[0] = param
    end
    game.Rendering.renderGM(textureRenderCore, 46, gmID, state.x + 0, state.y + 0)
    if not autoMarketPlayerDataStructs[0].enabled[param] then
      -- Forbidden icon
      -- game.Rendering.renderGMWithBlending(textureRenderCore, 46, 0x2D, state.x - 0, state.y - 0, 16)
      local stubTxt = ffi.cast("char *", "-")
      game.Rendering.renderTextToScreen(textManager, stubTxt, state.x + 55, state.y, 0, 0xB8EEFB, 0x13, 0, 0)
      game.Rendering.renderTextToScreen(textManager, stubTxt, state.x + 55, state.y + 0x13, 0, 0xB8EEFB, 0x13, 0, 0)
    else
      local buyTxt = ffi.cast("char *", string.format("< %d", autoMarketPlayerDataStructs[0].buyValues[param]))
      game.Rendering.renderTextToScreen(textManager, buyTxt, state.x + 55, state.y, 0, 0xB8EEFB, 0x13, 0, 0)

      local sellTxt = ffi.cast("char *", string.format("> %d", autoMarketPlayerDataStructs[0].sellValues[param]))
      game.Rendering.renderTextToScreen(textManager, sellTxt, state.x + 55, state.y + 0x13, 0, 0xB8EEFB, 0x13, 0, 0)
    end
  -- elseif param >= 30 and param <= 36 then
  --   renderButtonGM()
  --   game.Rendering.renderNumber2(textManager, setterValues[(param - 30)], state.x + 0x12, state.y + 0x10, 0, 0xB8EEFB, 0, 0x11, 0, 0)
  -- elseif param >= 37 and param <= 43 then
  --   renderButtonGM()
  --   game.Rendering.renderNumber2(textManager, setterValues[(param - 37)], state.x + 0x12, state.y + 0x10, 0, 0xB8EEFB, 0, 0x11, 0, 0)
  elseif param == 27 then
    -- renderButtonGM()
    -- or manually:
    local blendStrength = 6 * 2
    if state.interacting ~= 0 then
      blendStrength = blendStrength / 2
    end
    game.Rendering.renderGMWithBlending(textureRenderCore, 46, 0x2D, state.x - 0, state.y - 0, blendStrength)
  elseif param == 28 then
    -- 0xd0
    if state.interacting ~= 0 then
      game.Rendering.renderGM(textureRenderCore, 156, 0xCE + 1, state.x, state.y)
    else
      game.Rendering.renderGM(textureRenderCore, 156, 0xCE, state.x, state.y)
    end
    
  elseif param == 29 then
    -- 0xd0
    local i = 0xD0
    if state.interacting ~= 0 then
      i = i + 1
    end
    game.Rendering.renderGM(textureRenderCore, 156, i, state.x, state.y)
  end

  if pCurrentlyHoveredGood[0] ~= 0 then
    local gmID = (pCurrentlyHoveredGood[0] * 2) + 0x269 - 2
    game.Rendering.renderGM(textureRenderCore, 46, gmID, 21, 408 - 65)
  end

end

local sliderTempValue = 0
local sliderMin = 0
local sliderMax = 256
local sliderStep = 8

local sliderBuyValue_actionHandler = function(param_1, event, pMinValue, pMaxValue, pCurrentValue)
  -- log(WARNING, "slider action callback")
  if event == 1 then
    -- initialize
    log(WARNING, string.format("%d, %d, %d, %d, %d", param_1, event, pMinValue[0], pMaxValue[0], pCurrentValue[0]))
    pMinValue[0] = sliderMin
    pMaxValue[0] = sliderMax
    pCurrentValue[0] = sliderTempValue
  elseif event == 2 or event == 3 then
    -- 2 means shift thumb by clicking next to it
    -- 3 means dragging the thumb
    log(WARNING, string.format("%d, %d, %d, %d, %d", param_1, event, pMinValue[0], pMaxValue[0], pCurrentValue[0]))
    -- log(WARNING, string.format("new value is: %s", pCurrentValue[0]))
    sliderTempValue = pCurrentValue[0]
  elseif event == 4 then
    -- Some kind of "pre", called on almost every render...
    -- log(WARNING, string.format("%d, %d, %d, %d, %d", param_1, event, pMinValue[0], pMaxValue[0], pCurrentStep[0]))
    pMinValue[0] = sliderMin
    pMaxValue[0] = sliderMax
    pCurrentValue[0] = sliderTempValue
  elseif event == 5 then
    -- scroll up
    log(WARNING, string.format("%d, %d, %d, %d, %d", param_1, event, pMinValue[0], pMaxValue[0], pCurrentValue[0]))
    pCurrentValue[0] = pCurrentValue[0] - 1
    sliderTempValue = sliderTempValue - 1
  elseif event == 6 then
    -- scroll down
    log(WARNING, string.format("%d, %d, %d, %d, %d", param_1, event, pMinValue[0], pMaxValue[0], pCurrentValue[0]))
    pCurrentValue[0] = pCurrentValue[0] + 1
    sliderTempValue = sliderTempValue + 1
  elseif event == 7 then
    -- announce step size
    log(WARNING, string.format("%d, %d, %d, %d, %d", param_1, event, pMinValue[0], pMaxValue[0], pCurrentValue[0]))
    local pCurrentStep = pCurrentValue
    local currentValue = sliderTempValue
    local remainder = currentValue % 8
    if remainder == 0 then
      remainder = 8
    end
    pCurrentStep[0] = remainder
  else
    log(WARNING, string.format("%d, %d, %d, %d, %d", param_1, event, pMinValue[0], pMaxValue[0], pCurrentValue[0]))
  end

end
local pSliderBuyValue_actionHandler = ffi.cast("void (__cdecl *)(int, int, int*, int*, int*)", sliderBuyValue_actionHandler)

local sliderBuyValue_render = function(param_1, thumbXPos, sliderValue, thumbWidth, isDragged)
  game.Rendering.renderButtonBackground(game.Rendering.alphaAndButtonSurface, -1, -1)
  -- log(WARNING, "slider render callback")
  local color = game.Rendering.Colors.pGreyishYellow[0]
  if isDragged then 
    color = game.Rendering.Colors.pColorDarkLime[0]
  end

  ---@type ButtonRenderState
  local state = game.Rendering.ButtonState
  game.Rendering.drawColorBox(game.Rendering.pencilRenderCore, thumbXPos + state.x + 1, state.y + 2, thumbXPos + state.x - 2 + thumbWidth, state.height - 4 + state.y, color)
  game.Rendering.renderNumberToScreen2(game.Rendering.textManager, sliderValue, state.width + 0x14 + state.x, state.y  + 6, 0, 0xCCFAFF, 0x12, 0, 0)
end
local pSliderBuyValue_render = ffi.cast("void (__cdecl *)(int, int, int, int, bool)", sliderBuyValue_render)

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
        x = 21,
        y = 75,
      }
    },
    itemWidth = 50,
    itemHeight = 50,
    callbackParameter = {
      parameter = 2,
    },
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = 21 + (55 + 35),
        y = 75,
      }
    },
    itemWidth = 50,
    itemHeight = 50,
    callbackParameter = {
      parameter = 3,
    },
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = 21 + (55 + 35) + (55 + 35),
        y = 75,
      }
    },
    itemWidth = 50,
    itemHeight = 50,
    callbackParameter = {
      parameter = 4,
    },
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = 21 + (55 + 35) + (55 + 35) + (55 + 35),
        y = 75,
      }
    },
    itemWidth = 50,
    itemHeight = 50,
    callbackParameter = {
      parameter = 6,
    },
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = 21 + (55 + 35) + (55 + 35) + (55 + 35) + (55 + 35),
        y = 75,
      }
    },
    itemWidth = 50,
    itemHeight = 50,
    callbackParameter = {
      parameter = 8,
    },
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = 21 + (55 + 35) + (55 + 35) + (55 + 35) + (55 + 35) + (55 + 35),
        y = 75,
      }
    },
    itemWidth = 50,
    itemHeight = 50,
    callbackParameter = {
      parameter = 9,
    },
  },

  -- second row

  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = 21,
        y = 75 + 55,
      }
    },
    itemWidth = 50,
    itemHeight = 50,
    callbackParameter = {
      parameter = 10,
    },
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = 21 + (55 + 35),
        y = 75 + 55,
      }
    },
    itemWidth = 50,
    itemHeight = 50,
    callbackParameter = {
      parameter = 11,
    },
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = 21 + (55 + 35) + (55 + 35),
        y = 75 + 55,
      }
    },
    itemWidth = 50,
    itemHeight = 50,
    callbackParameter = {
      parameter = 12,
    },
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = 21 + (55 + 35) + (55 + 35) + (55 + 35),
        y = 75 + 55,
      }
    },
    itemWidth = 50,
    itemHeight = 50,
    callbackParameter = {
      parameter = 13,
    },
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = 21 + (55 + 35) + (55 + 35) + (55 + 35) + (55 + 35),
        y = 75 + 55,
      }
    },
    itemWidth = 50,
    itemHeight = 50,
    callbackParameter = {
      parameter = 14,
    },
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = 21 + (55 + 35) + (55 + 35) + (55 + 35) + (55 + 35) + (55 + 35),
        y = 75 + 55,
      }
    },
    itemWidth = 50,
    itemHeight = 50,
    callbackParameter = {
      parameter = 16,
    },
  },

  
  -- third row

  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = 21,
        y = 75 + 55 + 55,
      }
    },
    itemWidth = 50,
    itemHeight = 50,
    callbackParameter = {
      parameter = 17,
    },
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = 21 + (55 + 35),
        y = 75 + 55 + 55,
      }
    },
    itemWidth = 50,
    itemHeight = 50,
    callbackParameter = {
      parameter = 18,
    },
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = 21 + (55 + 35) + (55 + 35),
        y = 75 + 55 + 55,
      }
    },
    itemWidth = 50,
    itemHeight = 50,
    callbackParameter = {
      parameter = 19,
    },
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = 21 + (55 + 35) + (55 + 35) + (55 + 35),
        y = 75 + 55 + 55,
      }
    },
    itemWidth = 50,
    itemHeight = 50,
    callbackParameter = {
      parameter = 20,
    },
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = 21 + (55 + 35) + (55 + 35) + (55 + 35) + (55 + 35),
        y = 75 + 55 + 55,
      }
    },
    itemWidth = 50,
    itemHeight = 50,
    callbackParameter = {
      parameter = 21,
    },
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = 21 + (55 + 35) + (55 + 35) + (55 + 35) + (55 + 35) + (55 + 35),
        y = 75 + 55 + 55,
      }
    },
    itemWidth = 50,
    itemHeight = 50,
    callbackParameter = {
      parameter = 22,
    },
  },

   -- fourth row

  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = 21,
        y = 75 + 55 + 55 + 55,
      }
    },
    itemWidth = 50,
    itemHeight = 50,
    callbackParameter = {
      parameter = 23,
    },
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = 21 + (55 + 35),
        y = 75 + 55 + 55 + 55,
      }
    },
    itemWidth = 50,
    itemHeight = 50,
    callbackParameter = {
      parameter = 24,
    },
  },
  -- {
  --   menuItemType = 0x02000003, -- Button in interaction group (bit flags)
  --   menuItemRenderFunctionType = 0x1,
  --   position = {
  --     position = {
  --       x = 21 + (55 + 35) + (55 + 35),
  --       y = 75 + 55 + 55 + 55,
  --     }
  --   },
  --   itemWidth = 50,
  --   itemHeight = 50,
  --   callbackParameter = {
  --     parameter = 23,
  --   },
  -- },

  -- 

  
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    -- firstItemTypeData = {
    --   gmDataIndex = 0x2D,
    -- },
    position = {
      position = {
        x = 600 - 55,
        y = 408 - 55,
      }
    },
    itemWidth = 50,
    itemHeight = 50,
    callbackParameter = {
      parameter = 27,
    },
  },

  -- Top right buttons
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = 600 - 45 - 35,
        y = 15,
      }
    },
    itemWidth = 30,
    itemHeight = 30,
    callbackParameter = {
      parameter = 28,
    },
  },
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

  -- Slider: Buy value
  {
    menuItemType = 0x01000000, 
  },
  {
    menuItemType = 0x02000005, -- Slider
    menuItemRenderFunctionType = 0x4, -- Slider
    position = {
      position = {
        x = 21 + 100,
        y = 408 - 10 - 30,
      }
    },
    itemWidth = 256,
    itemHeight = 30,
    callbackParameter = {
      parameter = 30,
    },
    firstItemTypeData = {
      itemsToSkip = 8, -- scroll bar how many steps to jump per click
    },
    menuItemActionHandler = {
      slider = pSliderBuyValue_actionHandler,
    },
    menuItemRenderFunction = {
      slider = pSliderBuyValue_render,
    },
  },

  {menuItemType = 0x66, },
}

---@type ModalMenu
local ModalMenu = api.ui.ModalMenu
ModalMenu:createModalMenu({
  modalMenuID = 2025,
  width = 600,
  height = 408,
  x = -1,
  y = -1,
  borderStyle = 512,
  backgroundColor = 0,
  menuModalRenderFunction = function(x, y, width, height)
    -- render "Auto market"
    game.Rendering.renderTextToScreenConst(game.Rendering.textManager, pAutomarketTitle, x + 20, y + 25, 0, 0xCCFAFF, 0xF, false, 0)
  end,
  menu = api.ui.Menu:createMenu({
    menuID = 2024,
    -- menuItemsCount = 10,
    -- TODO: Without jit being on, this will crash because menuItems pointer becomes 0
    menuItems = ffi.new(string.format("MenuItem[%s]", #menuItems), menuItems)
  }),
})


remote.events.receive('ui-tests/test3/afterInit', function(key, value)
  -- log(ERROR, string.format("%s", getText(textManager, 224, 7)))
end)