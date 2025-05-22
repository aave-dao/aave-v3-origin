import "NEW-pool-base.spec";

methods {
  function _.hasRole(bytes32 b ,address a) external => DISPATCHER(true);

  function _.getReservesList() external => DISPATCHER(true);
  function _.getReserveData(address a) external => DISPATCHER(true);

  function _.symbol() external => DISPATCHER(true);
  function _.isFlashBorrower(address a) external => DISPATCHER(true);

  //  function _.executeOperation(address[] a, uint256[]b, uint256[]c, address d, bytes e) external => DISPATCHER(true);

  function _.isPoolAdmin(address a) external => DISPATCHER(true);
  function _.getConfiguration(address a) external => DISPATCHER(true);

  function _.rayMul(uint256 a, uint256 b) internal => mulDivDownAbstractPlus(a, b, 10^27) expect uint256 ALL;
  function _.rayDiv(uint256 a, uint256 b) internal => mulDivDownAbstractPlus(a, 10^27, b) expect uint256 ALL;

  // IPriceOracleSentinel
  function _.isBorrowAllowed() external => DISPATCHER(true);
  function _.isLiquidationAllowed() external => DISPATCHER(true);
  function _.setSequencerOracle(address newSequencerOracle) external => DISPATCHER(true);
  function _.setGracePeriod(uint256 newGracePeriod) external => DISPATCHER(true);
  function _.getGracePeriod() external => DISPATCHER(true);

  // Modification of index is tracked by incrementCounter:
  function _.incrementCounter() external => ghostUpdate() expect bool ALL;
}

ghost mathint counterUpdateIndexes;

function ghostUpdate() returns bool {
  counterUpdateIndexes = counterUpdateIndexes + 1;
  return true;
}


function calculateInterestRatesMock(DataTypes.CalculateInterestRatesParams params) returns (uint256, uint256) {
  uint256 liquidityRate = 1;
  uint256 variableBorrowRate = 1;
  return (liquidityRate, variableBorrowRate);
}


/* =================================================================================================
  @title Rule checking, that the ghostUpdate summary is correct and that it is being applied
  This rule is part of a check, that the liquidity index cannot decrease.

  Nissan remark on 26/03/2024: This rule fails!
  See here: https://prover.certora.com/output/66114/812c9675658a4d4d935a8e0a3e1f4a99/?anonymousKey=46e0337ab421a402e525e156b4aa1fb7a9b2fce9
  ================================================================================================ */
rule _updateIndexesWrapperReachable(env e, method f) {
  calldataarg args;

  mathint updateIndexesCallCountBefore = counterUpdateIndexes;
  f(e, args);

  mathint updateIndexesCallCountAfter = counterUpdateIndexes;

  satisfy updateIndexesCallCountBefore != updateIndexesCallCountAfter;
}

// @title cumulateToLiquidityIndex does not decrease the liquidity index.
// This rule is part of a check, that the liquidity index cannot decrease.
// Proved here:
// https://prover.certora.com/output/40577/bb018f9a52b64b27a0ac364e0c22cd79/?anonymousKey=21613bfbfc0f479ed2c99ce5fa2dd16e581baf5e
rule liquidityIndexNonDecresingFor_cumulateToLiquidityIndex() {
  address asset;
  uint256 totalLiquidity;
  uint256 amount;
  env e;

  uint256 reserveLiquidityIndexBefore = getReserveLiquidityIndex(e, asset);
  require reserveLiquidityIndexBefore >= RAY();

  uint256 reserveLiquidityIndexAfter = cumulateToLiquidityIndex(e, asset, totalLiquidity, amount);

  assert reserveLiquidityIndexAfter >= reserveLiquidityIndexBefore;
}


function get_AToken_of_asset(env e, address asset) returns address {
  DataTypes.ReserveDataLegacy data = getReserveData(e, asset);
  return data.aTokenAddress;
}


/* ===========================================================================================
  When a user deposits X amount of an asset and the current liquidity index for this asset is 1,
  his scaled balance (=superBalance) increases by X.

  Note: Using superBalance is easier for the prover as we do not need to compute the balance
        from the scaled balance.
        WE ALLOW OFF BY ONE RAY.
  =========================================================================================== */
rule depositUpdatesUserATokenSuperBalance(env e) {
  address asset;
  uint256 amount;
  address onBehalfOf;
  uint16 referralCode;

  require to_mathint(amount) == 30*RAY(); //under approx
  require asset != onBehalfOf;
  require onBehalfOf != _aToken;
  require e.msg.sender != _aToken;
  require e.msg.sender != asset;
  require asset == _aToken.UNDERLYING_ASSET_ADDRESS(e);
  require get_AToken_of_asset(e,asset) == _aToken;

  mathint superBalanceBefore = _aToken.superBalance(e, onBehalfOf);
  require superBalanceBefore == 20*RAY(); //under approx
  mathint liquidityIndexBefore = getLiquidityIndex(e, asset);
  require liquidityIndexBefore == 1*RAY(); //under approx
  mathint currentLiquidityRateBefore = getCurrentLiquidityRate(e, asset);
  require currentLiquidityRateBefore == 1; //under approx

  deposit(e, asset, amount, onBehalfOf, referralCode);

  mathint superBalanceAfter = _aToken.superBalance(e, onBehalfOf);
  mathint currentLiquidityRateAfter = getCurrentLiquidityRate(e, asset);
  require currentLiquidityRateAfter == currentLiquidityRateBefore;

  mathint liquidityIndexAfter = getLiquidityIndex(e, asset);

  require liquidityIndexAfter == liquidityIndexBefore;
  assert superBalanceAfter >= superBalanceBefore + amount - 1 * RAY();
  assert superBalanceAfter <= superBalanceBefore + amount + 1 * RAY();
}

/* ===========================================================================================
  Depositing on behalf of user A does not change balance of user other than A.
  ========================================================================================= */
rule depositCannotChangeOthersATokenSuperBalance(env e) {
  address asset;
  uint256 amount;
  address onBehalfOf;
  address otherUser;
  uint16 referralCode;

  require to_mathint(amount) == 30*RAY(); //under approx
  require asset != onBehalfOf;
  require onBehalfOf != _aToken;
  require e.msg.sender != _aToken;
  require e.msg.sender != asset;
  require asset == _aToken.UNDERLYING_ASSET_ADDRESS(e);
  require otherUser != onBehalfOf;
  require otherUser != _aToken;

  mathint superBalanceBefore = _aToken.superBalance(e, otherUser);

  deposit(e, asset, amount, onBehalfOf, referralCode);

  mathint superBalanceAfter = _aToken.superBalance(e, otherUser);
  assert superBalanceAfter == superBalanceBefore;
}
