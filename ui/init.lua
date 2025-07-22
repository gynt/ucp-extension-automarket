

return {
  initialize = function(self)
    ---@type Module_UI
    local ui = modules.ui
    ui:createMenuFromFile("ucp/modules/automarket/ui/automarket.lua")
  end,

  setCallbacks = function(self)
    ---@type Module_UI
    local ui = modules.ui
    ui:registerEventHandler("automarket/ui/save", function(key, obj)
      log(VERBOSE, string.format("save called!"))
    end)
  end,
}