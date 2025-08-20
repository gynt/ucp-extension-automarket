local core = remote.interface.core
local utils = remote.interface.utils

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

local activateModalDialog = ffi.cast([[
  void (__thiscall *)(
    void * this, // MenuModalComposition
    int menuModalID,
    bool retainOther
  )
]], core.AOBScan("53 55 33 ED 39 6C 24 10"))

local _, pMenuModalComposition1 = utils.AOBExtract("B9 I( ? ? ? ? ) E8 ? ? ? ? 5E 5B E9 ? ? ? ?")
local MenuModalComposition1 = ffi.cast("void *", pMenuModalComposition1)

local action = ffi.cast("void (__cdecl *)(int)", function(parameter)
  log(VERBOSE, "wow!")
  activateModalDialog(MenuModalComposition1, 2025, false)
end)
registerObject(action)

local item =  {
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
    parameter = 0x35, -- mimick prices...
  },
  menuItemRenderFunction = {
    simple = tonumber(ffi.cast("unsigned long", render)),
  },
  menuItemActionHandler = {
    simple = tonumber(ffi.cast("unsigned long", action)),
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

return item