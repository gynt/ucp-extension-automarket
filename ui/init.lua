

return {
  initialize = function()
    ---@type Module_UI
    local ui = modules.ui
    ui:createMenuFromFile("ucp/modules/automarket/ui/automarket.lua")
  end,
}