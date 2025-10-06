local core = remote.interface.core
local utils = remote.interface.utils

local trigger = {}

local pAutomarketData
function trigger.setAutomarketDataPointer(automarketDataPointer)
  pAutomarketData = automarketDataPointer
end

local pPlayerID
function trigger.setControllingPlayerPoint(playerIDPointer)
  pPlayerID = playerIDPointer
end

local render = ffi.cast("void (__cdecl *)(int)", function(parameter)
  ---@type ButtonRenderState
  local state = game.Rendering.ButtonState
  -- game.Rendering.renderButtonBackground(game.Rendering.alphaAndButtonSurface, 0, -1)
  game.Rendering.pDrawBufferChoiceValue[0] = 0
  local color = 0 -- 0xB8EEFB
  game.Rendering.renderTextToScreenConst(game.Rendering.textManager, "Auto market", state.x - 14, state.y + 30, 0, color, 0x12, 0, 0)
  game.Rendering.renderGM(game.Rendering.textureRenderCore, 0x2E, 204, state.x, state.y)
  state.gmPictureIndex = 204
  game.Rendering.pDrawBufferChoiceValue[0] = 1
end)
registerObject(render)

local action = ffi.cast("void (__cdecl *)(int)", function(parameter)
  log(VERBOSE, string.format("trigger automarket window for player: %s", pPlayerID[0]))
  pAutomarketData[0].playerSettings[0] = pAutomarketData[0].playerSettings[pPlayerID[0]]
  game.UI.activateModalMenu(game.UI.MenuModalComposition1, 2025, false)
end)
registerObject(action)

local item =  {
  -- TODO: this menuItemType isn't proper, it should have the "tab" flag too
  menuItemType = 0x02000003, -- Button in interaction group (bit flags)
  menuItemRenderFunctionType = 0x1,
  position = {
    position = {
      x = 375 + 90,
      y = 511 - 50,
    }
  },
  itemWidth = 50,
  itemHeight = 30,
  callbackParameter = {
    parameter = 0x35, -- mimick prices... can be anything
  },
  menuItemRenderFunction = {
    address = tonumber(ffi.cast("unsigned long", render)),
  },
  menuItemActionHandler = {
    address = tonumber(ffi.cast("unsigned long", action)),
  },
}
registerObject(item)

local item2 =  {
  menuItemType = 0x02000003, -- Button in interaction group (bit flags)
  menuItemRenderFunctionType = 0x3,
  position = {
    position = {
      x = 375 + 80,
      y = 511,
    }
  },
  firstItemTypeData = {
    gmDataIndex = 0x82,
  },
  callbackParameter = {
    parameter = 0x35, -- mimick prices...
  },
}
registerObject(item2)
trigger.triggerItem = item

local _, pMenuHandlerStateXY = utils.AOBExtract("A1 I(? ? ? ?) 53 55 56 57 33 FF 57 57 6A 10 57 8D 91 00 02 00 00")
ffi.cdef([[
  struct AM_Temp_Position {
    int x;
    int y;
  };
]])
local menuHandlerStateXY = ffi.cast("struct AM_Temp_Position *", pMenuHandlerStateXY)
local _, pLeftClickStart = utils.AOBExtract("83 ? I(? ? ? ?) ? 0F ? ? ? ? ? 8B ? ? ? ? ? 8B ? ? ? ? ? 8D 44 0A FF")
pLeftClickStart = ffi.cast("int *", pLeftClickStart)

local stockpileRenderActionHandlerCombined = ffi.cast("void (__cdecl *)(void)", function()
  local x = menuHandlerStateXY.x + 465
  local y = menuHandlerStateXY.y + 461

  game.Rendering.pDrawBufferChoiceValue[0] = 0
  local color = 0 -- 0xB8EEFB
  game.Rendering.renderTextToScreenConst(game.Rendering.textManager, "Auto market", x - 14, y + 30, 0, color, 0x12, 0, 0)
  game.Rendering.renderGM(game.Rendering.textureRenderCore, 0x2E, 204, x, y)
  game.Rendering.pDrawBufferChoiceValue[0] = 1

  if pLeftClickStart[0] == 1 then
    if game.Input.isMouseInsideBox(game.Input.mouseState, x, y, 50, 30) == 1 then
      action(0)
    end
  end
end)
registerObject(stockpileRenderActionHandlerCombined)
trigger.renderAndHandleInOne = tonumber(ffi.cast("unsigned long", stockpileRenderActionHandlerCombined))

return trigger