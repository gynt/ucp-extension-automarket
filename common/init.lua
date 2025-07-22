local ffi = ffi
if remote == nil then
  ffi = modules.cffi:cffi()  
end

local function loadHeaders()
  ffi.cdef([[

typedef struct AutoMarketPlayerData {
  bool enabled;
  int goldReserve;
  bool buyEnabled[25];
  bool sellEnabled[25];
  int buyValues[25];
  int sellValues[25];
} AutoMarketPlayerData;

  ]])
end

return {
  loadHeaders = loadHeaders,
}