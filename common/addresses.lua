local ffi = ffi
if remote == nil then
  ffi = modules.cffi:cffi()  
else
  utils = remote.interface.utils
end

-- TODO: make this extreme compatible
-- local _, pGameSynchronyState = utils.AOBExtract("C7 ? I( ? ? ? ? ) ? ? ? ? FF D7")
local _, pPlayerID = utils.AOBExtract("A1 I(? ? ? ?) 53 55 56 8B E9")

local _, pInvoker = utils.AOBExtract("A1 I(? ? ? ?) 8D 48 FF 83 F9 07 77 0D")

local pProtocolInvokerPlayerID = ffi.cast("int *", pInvoker)

-- TODO: make this extreme compatible
-- local _, pGameState = utils.AOBExtract("B9 I( ? ? ? ? ) E8 ? ? ? ? 8B F3 69 F6 F4 39 00 00 8B ? ? ? ? ? 8B ? ? ? ? ?")
local _, pWeekChanged = utils.AOBExtract("89 9E I(? ? ? ?) 89 9E ? ? ? ? 89 9E ? ? ? ? 89 9E ? ? ? ? 75 0c 89 BE ? ? ? ? 89 9E ? ? ? ?")

return {
  pPlayerID = pPlayerID,
  pProtocolInvokerPlayerID = pProtocolInvokerPlayerID,
  pWeekChanged = pWeekChanged,
}