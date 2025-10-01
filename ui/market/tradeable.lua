local utils = remote.interface.utils
local _, pTradeAbilityArray = utils.AOBExtract("89 ? I(? ? ? ?) 83 C0 08 83 C1 04 83 C6 04")

return {
    tradeablility = ffi.cast("int *", pTradeAbilityArray)
}