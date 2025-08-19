local render = ffi.cast("void (__cdecl *)(int)", function(parameter)
  ---@type ButtonRenderState
  local state = game.Rendering.ButtonState
  game.Rendering.renderButtonBackground(game.Rendering.alphaAndButtonSurface, 0, -1)
  game.Rendering.renderTextToScreenConst(game.Rendering.textManager, "Auto market", state.x + 4, state.y + 6, 0, 0xB8EEFB, 0x12, 0, 0)
end)
registerObject(render)

local action = ffi.cast("void (__cdecl *)(int)", function(parameter)
  log(VERBOSE, "wow!")
end)
registerObject(action)

local item =  {
  menuItemType = 0x02000003, -- Button in interaction group (bit flags)
  menuItemRenderFunctionType = 0x1,
  position = {
    position = {
      x = 375 + 20,
      y = 511,
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
      x = 375 + 20,
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

return item2