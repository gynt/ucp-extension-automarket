
local automarket

return {
  initialize = function(self)
    ---@type Module_UI
    local ui = modules.ui
    automarket = ui:createMenuFromFile("ucp/modules/automarket/ui/automarket.lua", true, true)
  end,

  setCallbacks = function(self, callbacks)
    ---@type Module_UI
    local ui = modules.ui
    ui:registerEventHandler("automarket/ui/data/save", function(key, obj)
      log(VERBOSE, string.format("save called!"))
      callbacks.commitData()
    end)

    log(VERBOSE, string.format("setCallbacks: received pointer: %X", automarket.pAutoMarketData))
    callbacks.setPointer(automarket.pAutoMarketData)

    log(VERBOSE, string.format("setCallbacks: setting hook to callback: %X", automarket.pCallback))
    callbacks.allocateMarketProcess(automarket.pCallback)
  end,
}