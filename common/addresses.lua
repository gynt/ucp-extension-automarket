local ffi = ffi
if remote == nil then
  ffi = modules.cffi:cffi()  
else
  utils = remote.interface.utils
end

local _, pPlayerID = utils.AOBExtract("A1 I(? ? ? ?) 53 55 56 8B E9")

local _, pInvoker = utils.AOBExtract("A1 I(? ? ? ?) 8D 48 FF 83 F9 07 77 0D")

local _, pWeekChanged = utils.AOBExtract("39 ? I(? ? ? ?) 0F ? ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 85 C0 0F ? ? ? ? ? A1 ? ? ? ?")

return {
  pPlayerID = pPlayerID,
  pProtocolInvokerPlayerID = pInvoker,
  pWeekChanged = pWeekChanged,
}