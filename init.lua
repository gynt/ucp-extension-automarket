

---@type CFFIInterface
local ffi = modules.cffi:cffi()
local automarket = {}

local common = require("common")
common.loadHeaders()
local automarketDataSize = common.sizes["AutoMarketPlayerData"]

local automarketData, pAutomarketData

local automarketProtocolNumber = -1

---@type Handler
local automarketProtocolHandler = {
  schedule = function(self, meta, context)
    log(VERBOSE, string.format("scheduling automarket protocol for setting data for player: %s", 1))
    meta.parameters:serializeInteger(1) -- TODO: involve player number
    -- 0th element is the UI state
    meta.parameters:serializeBytes(core.readBytes(pAutomarketData + 0, automarketDataSize))
  end,
  scheduleAfterReceive = function(self, meta)
    
  end,
  execute = function(self, meta)
    local playerID = meta.parameters:deserializeInteger()
    local data = meta.parameters:deserializeBytes(automarketDataSize)
    log(VERBOSE, string.format("executing automarket protocol for setting data for player: %s", playerID))
    core.writeBytes(pAutomarketData + (playerID * automarketDataSize), data)
  end
}

function automarket:enable(config)

  ---@type protocol
  local p = modules.protocol
  automarketProtocolNumber = p:registerCustomProtocol('automarket', 'saveSingle', 'LOCKSTEP', 4 + automarketDataSize, automarketProtocolHandler)

  local automarketUI = require("ui")
  automarketUI:initialize()
  automarketUI:setCallbacks({
    setPointer = function(pointer)
        self.automarketData = ffi.cast("AutoMarketPlayerData *", pointer)
        self.pAutomarketData = pointer
        automarketData = self.automarketData
        pAutomarketData = self.pAutomarketData
    end,
    saveData = function()
      log(WARNING, "do the saving!")
      p:invokeProtocol(automarketProtocolNumber)
    end,
  })


  

  
end

function automarket:disable()
end


return automarket