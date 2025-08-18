---market.lua

local core = remote.interface.core
local utils = remote.interface.utils

local pBuyGoods = core.AOBScan("53 8B 5C 24 10 55 8B 6C 24 10 56 8B 74 24 10")
local pSellGoods = core.AOBScan("53 8B 5C 24 0C 56 8B 74 24 0C 57")
local _, pAICState = utils.AOBExtract("B9 I( ? ? ? ? ) E8 ? ? ? ? 8B ? ? ? ? ? 52 B9 ? ? ? ? E8 ? ? ? ? 8B ? ? ? ? ? 8B ? ? ? ? ? 69 C9 2C 03 00 00")

local AICState = ffi.cast("void *", pAICState)

---@type fun(aicState, playerID, resourceType, amount):boolean
local buyGoods = ffi.cast([[
  bool (__thiscall *)(
    void * this, // aicState
    int playerID,
    int resourceType,
    int amount
  )
]], pBuyGoods)

---@type fun(aicState, playerID, resourceType, amount):void
local sellGoods = ffi.cast([[
  void (__thiscall *)(
    void * this, // aicState
    int playerID,
    int resourceType,
    int amount
  )
]], pSellGoods)

-- 0x30d40 + 4d0

local _, pGameState = utils.AOBExtract("B9 I( ? ? ? ? ) E8 ? ? ? ? 8B F3 69 F6 F4 39 00 00 8B ? ? ? ? ? 8B ? ? ? ? ?")
local GameState = ffi.cast("void *", pGameState)
local _pPlayerDataArray = pGameState + 0x30d40
local _pResources0 = _pPlayerDataArray + 0x4d0

local _pResources = ffi.new("int*[9]")
for i=0, 8 do
  _pResources[i] = ffi.cast("int*", _pResources0 + (i * 0x39f4))
end

local _pMarketBuildingID = _pPlayerDataArray + 0x1ac
local _pMarketBuildings = ffi.new("int*[9]")
for i=0, 8 do
  _pMarketBuildings[i] = ffi.cast("int*", _pMarketBuildingID + (i * 0x39f4))
end


local _, pGameSynchronyState = utils.AOBExtract("C7 ? I( ? ? ? ? ) ? ? ? ? FF D7")

local pGetBuyPrice = core.AOBScan("8B 44 24 08 8B 8C C1 1C 1F 05 00")

---@type fun(gameState, playerID, resourceType, amount):integer
local getBuyPrice = ffi.cast([[
  int (__thiscall *)(
    void * this, // game state
    int playerID, // unused actually
    int resourceType,
    int amount
  )
]], pGetBuyPrice)

local _, pUnitsState = utils.AOBExtract("8B ? I( ? ? ? ? ) B8 01 00 00 00 3B D0 7E 3A")
local UnitsState = ffi.cast("void *", pUnitsState)
local getAliveLordForPlayer = ffi.cast([[
  int (__thiscall *)(
    void * this, // units state
    int playerID
  )
]], core.AOBScan("8B 11 B8 01 00 00 00 3B D0 55"))

return {
  buyGoods = buyGoods,
  sellGoods = sellGoods,
  playerResources = _pResources,
  pPlayerID = ffi.cast("int *", pGameSynchronyState + 0x109e74),
  AICState = AICState,
  getBuyPrice = getBuyPrice,
  GameState = GameState,
  marketBuildings = _pMarketBuildings,
  UnitsState = UnitsState,
  getAliveLordForPlayer = getAliveLordForPlayer,
}