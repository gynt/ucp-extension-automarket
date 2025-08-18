

---@type CFFIInterface
local ffi = modules.cffi:cffi()
local automarket = {}

local common = require("common")
local addresses = require("common.addresses")
common.loadHeaders()
local autoMarketPlayerDataSize = common.sizes["AutoMarketPlayerData"]
local autoMarketPlayerCreditSize = common.sizes["AutoMarketPlayerCredit"]
local autoMarketDataSize = common.sizes["AutoMarketData"]
local autoMarketDataHeaderSize = common.sizes["AutoMarketDataHeader"]

local automarketData, pAutomarketData, pAutomarketPlayerSettings

local automarketProtocolNumber = -1
local automarketProtocolKey = ""

local function getControllingPlayerID()
  return addresses.pPlayerID[0]
end

local function getInvoker()
  return addresses.pProtocolInvokerPlayerID[0]
end

---@type Handler
local automarketProtocolHandler = {
  schedule = function(self, meta, context)
    log(VERBOSE, string.format("scheduling automarket protocol for comitting data for player: %s", 1))
    meta.parameters:serializeInteger(getControllingPlayerID())
    -- 0th element is the UI state
    meta.parameters:serializeBytes(core.readBytes(pAutomarketPlayerSettings + 0, autoMarketPlayerDataSize))
  end,
  scheduleAfterReceive = function(self, meta)
    
  end,
  execute = function(self, meta)
    local playerID = meta.parameters:deserializeInteger()
    local realPlayer = getInvoker()

    if playerID ~= realPlayer then
      log(WARNING, string.format("player %s may be cheating by trying to set the automarket of player %s", realPlayer, playerID))
    end

    local data = meta.parameters:deserializeBytes(autoMarketPlayerDataSize)
    log(VERBOSE, string.format("executing automarket protocol for comitting data for player: %s", realPlayer))
    core.writeBytes(pAutomarketPlayerSettings + (realPlayer * autoMarketPlayerDataSize), data)

    if realPlayer == getControllingPlayerID() then 
      -- If this data is for us, also update UI slot
      core.writeBytes(pAutomarketPlayerSettings + 0, data)
    end
  end
}

function automarket:enable(config)

  ---@type protocol
  local p = modules.protocol
  automarketProtocolNumber, automarketProtocolKey = p:registerCustomProtocol('automarket', 'commitSingle', 'LOCKSTEP', 4 + autoMarketDataSize, automarketProtocolHandler)

  local automarketUI = require("ui")
  automarketUI:initialize()
  automarketUI:setCallbacks({
    setPointer = function(pointer)
        self.automarketData = ffi.cast("AutoMarketData *", pointer)
        self.pAutomarketData = pointer
        automarketData = self.automarketData
        pAutomarketData = self.pAutomarketData
        pAutomarketPlayerSettings = ffi.tonumber(ffi.cast("unsigned long", self.automarketData.playerSettings))
        if pAutomarketPlayerSettings == nil then error("pAutomarketPlayerSettings is nil!") end
    end,
    commitData = function()
      log(WARNING, "do the commit!")
      p:invokeProtocol(automarketProtocolNumber)
    end,
  })

  local mapdatapath = "automarketplayerdata.bin"

  ---@type SerializationCallbacks
  local callbacks = {
    ---@param handle WriteHandle
    serialize = function(self, handle)
      handle:put(mapdatapath, core.readString(pAutomarketData, autoMarketDataSize))
    end,

    ---@param handle ReadHandle
    deserialize = function(self, handle)
      local success = false
      
      if handle:exists(mapdatapath) == true then
        local data = handle:get(mapdatapath)
        log(VERBOSE, string.format("size of the data: %d", data:len()))
        
        if data:len() > autoMarketDataSize then
          log(WARNING, string.format("Could not load automarket data, is it from a future version?"))
          success = false
        elseif data:len() < autoMarketDataSize then
          log(WARNING, string.format("The loaded data may be compatible but a converter isnt implemented"))
          if data:len() >= 4 then
            log(WARNING, string.format("expected version %d but received version %s", automarketData.header.version, string.unpack("<i", data:sub(1, 4))))
          end
          success = false
        else
          local expectedVersion = automarketData.header.version
          local receivedVersion = string.unpack("<i", data:sub(1, 4))
          log(WARNING, string.format("expected version %d and received version %s", automarketData.header.version, receivedVersion))

          if expectedVersion == receivedVersion then
            success = true
          end
        end

        if success then
          log(INFO, string.format("writing automarket data from map file (length: %d) to %X", data:len(), pAutomarketData))
          
          -- This nonsense is here due to a bug in RPS (or UCP?) with core.writeString
          local bytes = table.pack(string.byte(data, 1, -1))
          -- local chunkSize = 32
          -- for i=1,(data:len() - chunkSize), chunkSize do
          --   local bs = table.pack(string.byte(data, i, i + chunkSize - 1))
          --   for _, b in ipairs(bs) do
          --     table.insert(bytes, b)
          --   end
          -- end

          log(INFO, string.format("bytes data size: %d", #bytes))
          
          local v = automarketData.header.version
          core.writeBytes(pAutomarketData, bytes)
          automarketData.header.version = v
        end
      else
        
        success = false
      end

      if success  == false then
        -- reset the info
        log(VERBOSE, string.format("resetting automarket data to 0"))
        ffi.fill(ffi.cast("void *", pAutomarketData + autoMarketDataHeaderSize), autoMarketDataSize - autoMarketDataHeaderSize, 0)
      end

    end
  }

  ---@type mapextensions
  local m = modules['map-extensions']
  m:registerSection('automarket', callbacks)
  

  
end

function automarket:disable()
end


return automarket