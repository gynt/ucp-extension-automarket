---market.lua

local core = remote.interface.core
local utils = remote.interface.utils

local pBuyGoods = core.AOBScan("53 8B 5C 24 10 55 8B 6C 24 10 56 8B 74 24 10")
local pSellGoods = core.AOBScan("53 8B 5C 24 0C 56 8B 74 24 0C 57")
local _, pAICState = utils.AOBExtract("B9 I( ? ? ? ? ) E8 ? ? ? ? 8B ? ? ? ? ? 52 B9 ? ? ? ? E8 ? ? ? ? 8B ? ? ? ? ? 8B ? ? ? ? ? 69 C9 2C 03 00 00")

local buyGoods = ffi.cast([[
  bool (__thiscall *)(
    void * this, // aicState
    int playerID,
    int resourceType,
    int amount
  )
]], pBuyGoods)

local sellGoods = ffi.cast([[
  bool (__thiscall *)(
    void * this, // aicState
    int playerID,
    int resourceType,
    int amount
  )
]], pSellGoods)

-- 0x30d40 + 4d0

local _, pGameState = utils.AOBExtract("B9 I( ? ? ? ? ) E8 ? ? ? ? 8B F3 69 F6 F4 39 00 00 8B ? ? ? ? ? 8B ? ? ? ? ?")
local _pPlayerDataArray = pGameState + 0x30d40
local _pResources0 = _pPlayerDataArray + 0x4d0

local _pResources = ffi.new("int*[9]")
for i=0, 8 do
  _pResources[i] = ffi.cast("int*", _pResources0 + (i * 0x39f4))
end

local _, pGameSynchronyState = utils.AOBExtract("C7 ? I( ? ? ? ? ) ? ? ? ? FF D7")

return {
  buyGoods = buyGoods,
  sellGoods = sellGoods,
  playerResources = _pResources,
  pPlayerID = ffi.cast("int *", pGameSynchronyState + 0x109e74)
}