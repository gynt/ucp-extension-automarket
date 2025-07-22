

---@type CFFIInterface
local ffi = modules.cffi:cffi()
local automarket = {}

local common = require("common")
common.loadHeaders()

function automarket:enable(config)
  local automarketUI = require("ui")
  automarketUI:initialize()
  automarketUI:setCallbacks({
    setPointer = function(pointer)
        self.automarketData = ffi.cast("AutoMarketPlayerData *", pointer)
        self.pAutomarketData = pointer
    end,
    saveData = function()
      log(WARNING, "do the saving!")
    end,
  })


  

  
end

function automarket:disable()
end


return automarket