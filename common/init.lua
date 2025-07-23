local ffi = ffi
if remote == nil then
  ffi = modules.cffi:cffi()  
end

local sizes = {}

local function loadHeaders()
  ffi.cdef([[

  // This info should be in lockstep
typedef struct AutoMarketPlayerData {
  bool enabled;
  int goldReserve;
  bool buyEnabled[25];
  bool sellEnabled[25];
  int buyValues[25];
  int sellValues[25];
} AutoMarketPlayerData;

typedef struct AutoMarketPlayerCredit {
  int credit[25];
} AutoMarketPlayerCredit;

typedef struct AutoMarketDataHeader {
  int version;
} AutoMarketDataHeader;

// This info should be saved
typedef struct AutoMarketData {
  AutoMarketDataHeader header;
  AutoMarketPlayerData playerSettings[9];
  AutoMarketPlayerCredit playerCredit[9];
} AutoMarketData;

  ]])

  sizes["AutoMarketPlayerData"] = ffi.sizeof("AutoMarketPlayerData")
  sizes["AutoMarketPlayerCredit"] = ffi.sizeof("AutoMarketPlayerCredit")
  sizes["AutoMarketData"] = ffi.sizeof("AutoMarketData")
  sizes["AutoMarketDataHeader"] = ffi.sizeof("AutoMarketDataHeader")
end

return {
  loadHeaders = loadHeaders,
  sizes = sizes,
}