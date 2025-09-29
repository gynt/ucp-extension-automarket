
-- 17, 23

---@return integer cost,integer credit 
local function calculateFeedCost(rawCost, neutralFee100)
    -- 2091
  local cost100 = (100 + neutralFee100) * rawCost

  -- 91
  local decimals100 = cost100 % 100

  local roundedCost100 = cost100
  if decimals100 ~= 0 then
    -- 2100
    roundedCost100 = cost100 + 100 - decimals100
  end

  if roundedCost100 % 100 ~= 0 then error(string.format("math fail: %s, %s", rawCost, neutralFee100)) end

  -- 9
  local overpayDecimals100 = roundedCost100 - cost100

  -- 21
  local roundedCost = roundedCost100 / 100

  -- 21, 9
  return roundedCost, overpayDecimals100
end


-- 17, 23

---@return integer reward,integer credit 
local function calculateFeedReward(rawReward, neutralFee100)
  -- 1309
  local reward100 = (100 - neutralFee100) * rawReward

  -- 9
  local decimals100 = reward100 % 100

  local roundedReward100 = reward100
  if decimals100 ~= 0 then
    -- 1300
    roundedReward100 = reward100 - decimals100
  end

  if roundedReward100 % 100 ~= 0 then error(string.format("math fail: %s, %s", rawReward, neutralFee100)) end

  -- 9
  local withheldDecimals100 = decimals100

  -- 13
  local roundedReward = roundedReward100 / 100

  -- 13, 9
  return roundedReward, withheldDecimals100
end

local state = {
  fee = 10,
  overpay = 0,
  withheld = 0,
  gold = 1000,
}

function processBuy(cost)
  local roundedCost, overpay = calculateFeedCost(cost, state.fee)
  state.overpay = state.overpay + overpay
  if state.overpay > 100 then
    roundedCost = roundedCost - 1
    state.overpay = state.overpay - 100
  end

  return roundedCost, state.overpay
end

function processSell(reward)
  local roundedReward, withheld = calculateFeedReward(reward, state.fee)
  state.withheld = state.withheld + withheld
  if state.withheld > 100 then
    roundedReward = roundedReward + 1
    state.withheld = state.withheld - 100
  end

  return roundedReward, state.withheld
end

function tick()
  print(string.format("state   start: fee=%d gold=%d withheld=%d overpay=%d", state.fee, state.gold, state.withheld, state.overpay))
  local sales = math.random(1, 25)
  
  local reward = processSell(sales)
  print(string.format("state selling: %d gain %d", sales, reward))

  state.gold = state.gold + reward

  print(string.format("state between: fee=%d gold=%d withheld=%d overpay=%d", state.fee, state.gold, state.withheld, state.overpay))

  local buys = math.random(1, 25)
  -- print(string.format("state  buying: %s", buys))
  local cost = processBuy(buys)
  print(string.format("state  buying: %d cost %d", buys, cost))

  state.gold = state.gold - cost

  print(string.format("state     end: fee=%d gold=%d withheld=%d overpay=%d", state.fee, state.gold, state.withheld, state.overpay))
end

return {
    calculateFeedCost = calculateFeedCost,
    calculateFeedReward = calculateFeedReward,
}