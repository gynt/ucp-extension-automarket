local ffi = ffi
if remote == nil then
  ffi = modules.cffi:cffi()  
else
  utils = remote.interface.utils
end

local _, pGameSynchronyState = utils.AOBExtract("C7 ? I( ? ? ? ? ) ? ? ? ? FF D7")
local pPlayerID = ffi.cast("int *", pGameSynchronyState + 0x109e74)

local pProtocolInvokerPlayerID = ffi.cast("int *", pGameSynchronyState + 0x109e70)

local _, pGameState = utils.AOBExtract("B9 I( ? ? ? ? ) E8 ? ? ? ? 8B F3 69 F6 F4 39 00 00 8B ? ? ? ? ? 8B ? ? ? ? ?")
local pMapAndTime = pGameState + 0x516d4
local pWeekChanged = pMapAndTime + 0x340

return {
  pPlayerID = pPlayerID,
  pProtocolInvokerPlayerID = pProtocolInvokerPlayerID,
  pWeekChanged = pWeekChanged,
}