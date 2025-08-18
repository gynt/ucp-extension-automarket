local _, pGameSynchronyState = utils.AOBExtract("C7 ? I( ? ? ? ? ) ? ? ? ? FF D7")
local pPlayerID = ffi.cast("int *", pGameSynchronyState + 0x109e74)

local pProtocolInvokerPlayerID = ffi.cast("int *", pGameSynchronyState + 0x109e70)

return {
  pPlayerID = pPlayerID,
  pProtocolInvokerPlayerID = pProtocolInvokerPlayerID,
}