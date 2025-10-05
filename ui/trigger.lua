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
  game.Rendering.renderTextToScreenConst(game.Rendering.textManager, "Auto market", state.x - 14, state.y + 30, 0, 0xB8EEFB, 0x12, 0, 0)
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
return trigger