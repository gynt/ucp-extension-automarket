

---@type CFFIInterface
local ffi = modules.cffi:cffi()
local automarket = {}


function automarket:enable(config)
  local automarketUI = require("ui")
  automarketUI:initialize()
  automarketUI:setCallbacks()

  local headersDataHandle, err = io.open("ucp/modules/automarket/ui/data.h", 'r')
  if headersDataHandle == nil then error(err) end
  local headersData = headersDataHandle:read("*all")
  headersDataHandle:close()

  -- ---@type Module_UI
  -- local ui = modules.ui
  -- ui:getState():importHeaderFile("ucp/modules/automarket/ui/data.h")

  -- modules.cffi:importHeaderFile("ucp/modules/automarket/ui/data.h")
  local common = require("common")
  common.loadHeaders()
  self.automarketData = ffi.new("AutoMarketPlayerData[9]", {})
end

function automarket:disable()
end


return automarket