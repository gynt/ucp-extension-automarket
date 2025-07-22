

return {
  initialize = function(self)
    ---@type Module_UI
    local ui = modules.ui
    ui:createMenuFromFile("ucp/modules/automarket/ui/automarket.lua")
  end,

  setCallbacks = function(self, callbacks)
    ---@type Module_UI
    local ui = modules.ui
    ui:registerEventHandler("automarket/ui/data/save", function(key, obj)
      log(VERBOSE, string.format("save called!"))
      callbacks.saveData()
    end)

    ui:registerEventHandler("automarket/ui/data/set/pointer", function(key, obj) 
      log(VERBOSE, string.format("received pointer: %X", obj))
      callbacks.setPointer(obj)
    end)
    ui:sendEvent("automarket/ui/data/get/pointer", {})
  end,
}