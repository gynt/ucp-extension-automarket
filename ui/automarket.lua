-- jit.off(true, true)

--tests/test3-modal.lua
local core = remote.interface.core
local utils = remote.interface.utils


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
local textManager = ffi.cast("void *", game.Rendering.pTextManager)
-- log(ERROR, string.format("%s", textManager))
-- log(ERROR, string.format("%s", getText(textManager, 224, 7)))

local AUTOMARKET_MODAL_MENU_ID = 2025
local AUTOMARKET_TITLE = "Auto Market"
local pAutomarketTitle = registerObject(ffi.new("char[?]", #AUTOMARKET_TITLE + 1))
ffi.copy(pAutomarketTitle, AUTOMARKET_TITLE)

-- This line is subject to garbage collection
-- local pAutomarketTitle = registerObject(ffi.new("char const *", AUTOMARKET_TITLE))

log(WARNING, AUTOMARKET_TITLE, pAutomarketTitle)

ffi.cdef([[
  typedef struct AutoMarketPlayerData {
    bool enabled;
    bool buyEnabled[25];
    bool sellEnabled[25];
    int buyValues[25];
    int sellValues[25];
  } AutoMarketPlayerData;
]])

local autoMarketPlayerDataStructs = ffi.new("AutoMarketPlayerData[9]", {})

local pCurrentlyHoveredGood = ffi.new("int[1]", {})
local pLastSelectedGood = ffi.new("int[1]", {})

local actionCallback1 = function(param)
  log(WARNING, param)
  if param < 25 then
    if pLastSelectedGood[0] == param then
      pLastSelectedGood[0] = 0
    else
      pLastSelectedGood[0] = param
    end
  end
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
    
    local blendStrength = 6 -- * 2

    if state.interacting ~= 0 or pLastSelectedGood[0] == param then
      gmID = (param * 2) + 0x26a - 2
      
      if pLastSelectedGood[0] ~= param then
        pCurrentlyHoveredGood[0] = param
      end

      -- Useful for debug purposes but otherwise ugly
      -- game.Rendering.drawBorderBox(game.Rendering.pencilRenderCore, state.x, state.y, state.x + state.width, state.y + state.height, 0xB8EEFB)

      game.Rendering.renderGM(textureRenderCore, 46, gmID, state.x + 0, state.y + 0)
    else
      game.Rendering.renderGMWithBlending(textureRenderCore, 46, gmID, state.x + 0, state.y + 0, blendStrength)
    end

    if not autoMarketPlayerDataStructs[0].buyEnabled[param] then
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
    local i = 0xCE
    if state.interacting ~= 0 then
      i = i + 1
    end
    game.Rendering.renderGM(textureRenderCore, 156, i, state.x, state.y)
  elseif param == 29 then
    -- 0xd0
    local i = 0xD0
    if state.interacting ~= 0 then
      i = i + 1
    end
    game.Rendering.renderGM(textureRenderCore, 156, i, state.x, state.y)
  end



end

local function chooseFocusGood()
  if pLastSelectedGood[0] ~= 0 then
    return pLastSelectedGood[0]
  elseif menu.menu ~= nil and menu.menu.hoveredItem ~= nil then
    ---@type MenuItem
    local mi = menu.menu.hoveredItem[0]
    local inferredParameter = mi.callbackParameter.parameter
    if inferredParameter > 0 and  inferredParameter < 25 then
      local good = inferredParameter
      return good
    end
  end
  return 0
end

local sliderMin = 0
local sliderMax = 256
local sliderStep = 8

local sliderBuyValue_actionHandler = function(param_1, event, pMinValue, pMaxValue, pCurrentValue)
  ---@type ButtonRenderState
  local state = game.Rendering.ButtonState
  local good = chooseFocusGood()
  -- log(WARNING, "slider action callback")
  if event == 1 then
    -- initialize (e.g. prepare for render)
    log(WARNING, string.format("%d, %d, %d, %d, %d", param_1, event, pMinValue[0], pMaxValue[0], pCurrentValue[0]))
    pMinValue[0] = sliderMin
    pMaxValue[0] = sliderMax
    pCurrentValue[0] = autoMarketPlayerDataStructs[0].buyValues[pLastSelectedGood[0]]
  elseif event == 2 or event == 3 then
    -- 2 means shift thumb by clicking next to it
    -- 3 means dragging the thumb
    log(WARNING, string.format("%d, %d, %d, %d, %d", param_1, event, pMinValue[0], pMaxValue[0], pCurrentValue[0]))
    -- log(WARNING, string.format("new value is: %s", pCurrentValue[0]))
    autoMarketPlayerDataStructs[0].buyEnabled[pLastSelectedGood[0]] = true
    autoMarketPlayerDataStructs[0].sellEnabled[pLastSelectedGood[0]] = true -- TODO: remove line
    autoMarketPlayerDataStructs[0].buyValues[pLastSelectedGood[0]] = pCurrentValue[0]
  elseif event == 4 then
    -- Some kind of "pre", called on almost every render... (I mean callback)
    -- log(WARNING, string.format("%d, %d, %d, %d, %d", param_1, event, pMinValue[0], pMaxValue[0], pCurrentStep[0]))
    pMinValue[0] = sliderMin
    pMaxValue[0] = sliderMax
    pCurrentValue[0] = autoMarketPlayerDataStructs[0].buyValues[pLastSelectedGood[0]]

  elseif event == 5 then
    -- scroll up
    log(WARNING, string.format("%d, %d, %d, %d, %d", param_1, event, pMinValue[0], pMaxValue[0], pCurrentValue[0]))
    -- log(WARNING, string.format("interacting: %s", state.interacting))
    -- TODO: strangely enough x and y is not properly set when scrolling on top of a scrollbar. It works for buttons and other menu places... Stumps me!
    -- Perhaps the state is not set as valid or something...
    log(WARNING, string.format("x, y, width, height: %s, %s, %s, %s", state.x, state.y, state.width, state.height))

    local isInside = game.Input.isMouseInsideBox(game.Input.mouseState, state.x, state.y, state.width, state.height)
    log(WARNING, string.format("mouse: %s", isInside))
    if isInside ~= 0 then
      pCurrentValue[0] = pCurrentValue[0] - 1
      autoMarketPlayerDataStructs[0].buyValues[pLastSelectedGood[0]] = autoMarketPlayerDataStructs[0].buyValues[pLastSelectedGood[0]] - 1
    end
    
  elseif event == 6 then
    -- scroll down
    log(WARNING, string.format("%d, %d, %d, %d, %d", param_1, event, pMinValue[0], pMaxValue[0], pCurrentValue[0]))
    log(WARNING, string.format("x, y, width, height: %s, %s, %s, %s", state.x, state.y, state.width, state.height))

    local isInside = game.Input.isMouseInsideBox(game.Input.mouseState, state.x, state.y, state.width, state.height)
    log(WARNING, string.format("mouse: %s", isInside))
    if isInside ~= 0 then
      pCurrentValue[0] = pCurrentValue[0] + 1
      autoMarketPlayerDataStructs[0].buyValues[pLastSelectedGood[0]] = autoMarketPlayerDataStructs[0].buyValues[pLastSelectedGood[0]] + 1
    end
  elseif event == 7 then
    -- announce step size
    log(WARNING, string.format("%d, %d, %d, %d, %d", param_1, event, pMinValue[0], pMaxValue[0], pCurrentValue[0]))
    local pCurrentStep = pCurrentValue
    local currentValue = autoMarketPlayerDataStructs[0].buyValues[pLastSelectedGood[0]]
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
  ---@type ButtonRenderState
  local state = game.Rendering.ButtonState
  -- Well this has be to set to 0 in order for no artifacts to appear
  state.interacting = 0
  game.Rendering.renderButtonBackground(game.Rendering.alphaAndButtonSurface, -1, -1)
  -- log(WARNING, "slider render callback")
  local color = game.Rendering.Colors.pGreyishYellow[0]
  if isDragged then 
    color = game.Rendering.Colors.pColorDarkLime[0]
  end

  local good = chooseFocusGood()
  
  game.Rendering.drawColorBox(game.Rendering.pencilRenderCore, thumbXPos + state.x + 1, state.y + 2, thumbXPos + state.x - 2 + thumbWidth, state.height - 4 + state.y, color)
  
  game.Rendering.renderTextToScreenConst(game.Rendering.textManager, string.format("Buy below"), state.x - 75, state.y + 6, 1, 0xCCFAFF, 0x12, 0x0, 0x0)
  if good > 0 and autoMarketPlayerDataStructs[0].buyEnabled[good] then  
    game.Rendering.renderNumberToScreen2(game.Rendering.textManager, autoMarketPlayerDataStructs[0].buyValues[good], state.x - 18, state.y + 6, 1, 0xCCFAFF, 0x12, 0, 0)
  else
    game.Rendering.renderTextToScreenConst(game.Rendering.textManager, "-", state.x - 18, state.y + 6, 1, 0xCCFAFF, 0x12, 0x0, 0x0)
  end
  
end
local pSliderBuyValue_render = ffi.cast("void (__cdecl *)(int, int, int, int, bool)", sliderBuyValue_render)


--TODO: currently clears buy value :)
local clearSellValue = function(parameter)
  if parameter == 1 then
    autoMarketPlayerDataStructs[0].buyValues[pLastSelectedGood[0]] = 0
  end
end

local pClearSellValue = ffi.cast("void (__cdecl *)(int)", clearSellValue)

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

  
  -- {
  --   menuItemType = 0x02000003, -- Button in interaction group (bit flags)
  --   menuItemRenderFunctionType = 0x1,
  --   -- firstItemTypeData = {
  --   --   gmDataIndex = 0x2D,
  --   -- },
  --   position = {
  --     position = {
  --       x = 600 - 55,
  --       y = 408 - 55,
  --     }
  --   },
  --   itemWidth = 50,
  --   itemHeight = 50,
  --   callbackParameter = {
  --     parameter = 27,
  --   },
  -- },

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
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = 600 - 10 - 35 - 35 - 155,
        y = 15,
      }
    },
    itemWidth = 150,
    itemHeight = 30,
    callbackParameter = {
      parameter = 26,
    },
    menuItemRenderFunction = {
      simple = ffi.cast("void (__cdecl *)(int)", function(parameter)
        ---@type ButtonRenderState
        local state = game.Rendering.ButtonState
        state.interacting = autoMarketPlayerDataStructs[0].enabled
        game.Rendering.renderButtonBackground(game.Rendering.alphaAndButtonSurface, 0, -1)

        local txt = "Auto Market: Off"
        if autoMarketPlayerDataStructs[0].enabled then
          txt = "Auto Market: On"
        end
        game.Rendering.renderTextToScreenConst(game.Rendering.textManager, txt, state.x + 6, state.y + 6, 0, 0xB8EEFB, 0x12, 0, 0)
      end),
    },
    menuItemActionHandler = {
      simple = ffi.cast("void (__cdecl *)(int)", function(parameter)
        autoMarketPlayerDataStructs[0].enabled = not autoMarketPlayerDataStructs[0].enabled
      end),
    }
  },
  -- Sleep button
  -- {
  --   menuItemType = 0x02000003, -- Button in interaction group (bit flags)
  --   menuItemRenderFunctionType = 0x3,
  --   firstItemTypeData = {
  --     gmDataIndex = 0xCD,
  --   },
  --   position = {
  --     position = {
  --       x = 600 - 45 - 35 - 50,
  --       y = 15,
  --     }
  --   },
  --   itemWidth = 50,
  --   itemHeight = 50,
  --   callbackParameter = {
  --     parameter = 26,
  --   },
  --   menuItemRenderFunction = {
  --     gmDataImage = game.Rendering.generalButtonRender,
  --   }
  -- },


  -- Slider: goods image
  {
    menuItemType = 0x01000000, 
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = 600 - 256 - 50 - 50 - 100 - 100,
        y = 408 - 10 - 20 - 10 - 30 - 5,
      }
    },
    itemWidth = 50,
    itemHeight = 50,
    callbackParameter = {
      parameter = 1,
    },
    menuItemRenderFunction = {
      simple = ffi.cast("void (__cdecl *)(int)", function(parameter)
        ---@type ButtonRenderState
        local state = game.Rendering.ButtonState
        state.interacting = 0
        -- For some reason this image has the wrong dimensions...
        -- game.Rendering.renderButtonBackground(game.Rendering.alphaAndButtonSurface, 0, -1)

        local good = chooseFocusGood()
        if good ~= 0 then
          local gmID = (good * 2) + 0x26a - 2
          if good == pLastSelectedGood[0] then
            gmID = gmID + 1
          end
          game.Rendering.renderGM(textureRenderCore, 46, gmID, state.x, state.y)
          local txt = "0" -- TODO: current resource count
          game.Rendering.renderTextToScreenConst(game.Rendering.textManager, txt, state.x + (state.width / 2), state.y + state.height, 1, 0xB8EEFB, 0x12, 0, 0) 
        end
      end),
    },
    menuItemActionHandler = {
      simple = ffi.cast("void (__cdecl *)(int)", function(parameter)
        log(WARNING, "yay!")
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
        x = 600 - 50 - 10 - 256 - 5,
        y = 408 - 10 - 20 - 10 - 30 - 5,
      }
    },
    itemWidth = sliderMax,
    itemHeight = 30, -- seems to be the minimum size...
    callbackParameter = {
      parameter = 30,
    },
    firstItemTypeData = {
      itemsToSkip = sliderStep, -- scroll bar how many steps to jump per click
    },
    menuItemActionHandler = {
      slider = pSliderBuyValue_actionHandler,
    },
    menuItemRenderFunction = {
      slider = pSliderBuyValue_render, -- ffi.cast("void (__cdecl *)(int, int, int, int, bool)", core.AOBScan("56 33 F6 39 ? ? ? ? ? 89 ? ? ? ? ? 7E 2B"))
    },
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = 600 - 50 - 10,
        y = 408 - 10 - 20 - 10 - 30 - 5,
      }
    },
    itemWidth = 50,
    itemHeight = 30,
    callbackParameter = {
      parameter = 0,
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
      end),
    },
  },
  -- {
  --   menuItemType = 0x02000003, -- Button in interaction group (bit flags)
  --   menuItemRenderFunctionType = 0x3,
  --   firstItemTypeData = {
  --     gmDataIndex = 0x023A,
  --   },
  --   position = {
  --     position = {
  --       x = 600 - 50 - 10,
  --       y = 408 - 10 - 20 - 10 - 30 - 5,
  --     }
  --   },
  --   itemWidth = 30,
  --   itemHeight = 30,
  --   callbackParameter = {
  --     parameter = 0,
  --   },
  -- },

  -- Slider: sell value
  {
    menuItemType = 0x01000000,
  },
  {
    menuItemType = 5, -- Slider
    menuItemRenderFunctionType = 0x4, -- Slider
    position = {
      position = {
        x = 600 - 50 - 10 - 256 - 5,
        y = 408 - 10 - 20 - 10,
      }
    },
    itemWidth = sliderMax,
    itemHeight = 30, -- seems to be the minimum size...
    callbackParameter = {
      parameter = 0,
    },
    firstItemTypeData = {
      itemsToSkip = sliderStep, -- scroll bar how many steps to jump per click
    },
    menuItemActionHandler = {
      slider = pSliderBuyValue_actionHandler,
    },
    menuItemRenderFunction = {
      slider = pSliderBuyValue_render, -- ffi.cast("void (__cdecl *)(int, int, int, int, bool)", core.AOBScan("56 33 F6 39 ? ? ? ? ? 89 ? ? ? ? ? 7E 2B"))
    },
  },
  {
    menuItemType = 0x02000003, -- Button in interaction group (bit flags)
    menuItemRenderFunctionType = 0x1,
    position = {
      position = {
        x = 600 - 50 - 10,
        y = 408 - 10 - 20 - 10,
      }
    },
    itemWidth = 50,
    itemHeight = 30,
    callbackParameter = {
      parameter = 0,
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
      end),
    },
  },

  {menuItemType = 0x66, },
}

menu = api.ui.Menu:createMenu({
  menuID = 2024,
  -- menuItemsCount = 10,
  -- TODO: Without jit being on, this will crash because menuItems pointer becomes 0
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
    game.Rendering.renderTextToScreenConst(game.Rendering.textManager, pAutomarketTitle, x + 20, y + 25, 0, 0xCCFAFF, 0xF, false, 0)
  end,
  menu = menu,
})


remote.events.receive('ui-tests/test3/afterInit', function(key, value)
  -- log(ERROR, string.format("%s", getText(textManager, 224, 7)))
end)