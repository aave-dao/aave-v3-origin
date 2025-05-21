/*
  This is a Base Specification File for Smart Contract Verification with the Certora Prover.
  This file is meant to be included
*/

import "NEW-CVLMath.spec";

/*
  Declaration of contracts used in the spec
*/
using ATokenHarness as _aToken;
using PoolHarness as PH;
using AaveProtocolDataProvider as _dataProvider;
using SimpleERC20 as _underlyingAsset;

/*
  Methods Summerizations and Enviroment-Free (e.g relative to e.msg variables) Declarations
*/

methods {
  // Pool
  function _.handleAction(address, uint256, uint256) external => NONDET;
  function _.getAssetPrice(address) external => NONDET;
  function _.getPriceOracle() external => ALWAYS(2);
  function _.getPriceOracleSentinel() external => ALWAYS(4);

  function _.calculateCompoundedInterest(uint256 x, uint40 t0, uint256 t1) internal => calculateCompoundedInterestSummary(x, t0, t1) expect uint256 ALL;

  // ERC20
  function _.transfer(address, uint256) external => DISPATCHER(true);
  function _.transferFrom(address, address, uint256) external => DISPATCHER(true);
  function _.approve(address, uint256) external => DISPATCHER(true);
  //  function _.mint(address, uint256) external => DISPATCHER(true);
  //function _.burn(uint256) external => DISPATCHER(true);
  function _.balanceOf(address) external => DISPATCHER(true);

  function _.totalSupply() external => DISPATCHER(true);

  // ATOKEN
  //function _.mint(address user, uint256 amount, uint256 index) external => DISPATCHER(true);
  function _.burn(address user, address receiverOfUnderlying, uint256 amount, uint256 index) external => DISPATCHER(true);
  function _.mintToTreasury(uint256 amount, uint256 index) external => DISPATCHER(true);
  function _.transferOnLiquidation(address from, address to, uint256 value) external => DISPATCHER(true);
  function _.transferUnderlyingTo(address user, uint256 amount) external => DISPATCHER(true);
  //function _.handleRepayment(address user, uint256 amount) external => DISPATCHER(true);
  function _.permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external => DISPATCHER(true);
  function _.ATokenBalanceOf(address user) external => DISPATCHER(true);

  // Unsat Core Based
  function _.getParams(DataTypes.ReserveConfigurationMap memory self) internal => NONDET;

  function _.calculateUserAccountData(mapping(address => DataTypes.ReserveData) storage reservesData,mapping(uint256 => address) storage reservesList,mapping(uint8 => DataTypes.EModeCategory) storage eModeCategories,DataTypes.CalculateUserAccountDataParams memory params) internal => NONDET;
  function _._getUserBalanceInBaseCurrency(address user,DataTypes.ReserveData storage reserve,uint256 assetPrice,uint256 assetUnit) internal => NONDET;
  function _.wadDiv(uint256 a, uint256 b) internal => NONDET;
  function _.wadToRay(uint256 a) internal => NONDET;
  function _._calculateDomainSeparator() internal => NONDET;


  // Debt Tokens
  function _.scaledTotalSupply() external => DISPATCHER(true);

  function _.getReserveNormalizedIncome(address asset) external => DISPATCHER(true);
  function _.getReserveNormalizedVariableDebt(address asset) external => DISPATCHER(true);
  function _.getACLManager() external  => DISPATCHER(true);
  //  function _.isBridge(address) external => DISPATCHER(true);

  // variableDebt
  function _.burn(address user, uint256 amount, uint256 index) external => DISPATCHER(true);

  function getActive(DataTypes.ReserveConfigurationMap) external returns (bool);
  function getFrozen(DataTypes.ReserveConfigurationMap) external returns (bool);
  function getBorrowingEnabled(DataTypes.ReserveConfigurationMap) external returns (bool);
}

/* definitions and functions to be used within the spec file */

definition IS_UINT256(uint256 x) returns bool = ((x >= 0) && (x <= max_uint256));

function first_term(uint256 x, uint256 y) returns uint256 { return x; }

ghost mapping(uint256 => mapping(uint256 => uint256)) calculateCompoundedInterestSummaryValues;

function calculateCompoundedInterestSummary(uint256 rate, uint40 t0, uint256 t1) returns uint256
{
  uint256 deltaT = assert_uint256( (t1-t0) % 2^256 );
  if (deltaT == 0) {
    return RAY();
  }
  if (rate == RAY()) {
    return RAY();
  }
  if (rate >= RAY()) {
    require calculateCompoundedInterestSummaryValues[rate][deltaT] >= rate;
  }
  else {
    require calculateCompoundedInterestSummaryValues[rate][deltaT] < rate;
  }
  return calculateCompoundedInterestSummaryValues[rate][deltaT];
}

function isActiveReserve(env e, address asset) returns bool {
  DataTypes.ReserveDataLegacy data = getReserveData(e, asset);
  DataTypes.ReserveConfigurationMap configuration = data.configuration;
  bool isActive = getActive(e, configuration);

  return isActive;
}

function isFrozenReserve(env e, address asset) returns bool {
  DataTypes.ReserveDataLegacy data = getReserveData(e, asset);
  DataTypes.ReserveConfigurationMap configuration = data.configuration;
  bool isFrozen = getFrozen(e, configuration);

  return isFrozen;
}

function isEnabledForBorrow(env e, address asset) returns bool {
  DataTypes.ReserveDataLegacy data = getReserveData(e, asset);
  DataTypes.ReserveConfigurationMap configuration = data.configuration;
  bool isBorrowEnabled = getBorrowingEnabled(e, configuration);

  return isBorrowEnabled;
}

function getCurrentLiquidityRate(env e, address asset) returns mathint {
  DataTypes.ReserveDataLegacy data = getReserveData(e, asset);
  return data.currentLiquidityRate;
}

function getLiquidityIndex(env e, address asset) returns mathint {
  DataTypes.ReserveDataLegacy data = getReserveData(e, asset);
  return data.liquidityIndex;
}

function aTokenBalanceOf(env e, address user) returns uint256 {
  return _aToken.ATokenBalanceOf(e, user);
}

function rayMulPreciseSummarization(uint256 x, uint256 y) returns uint256 {
  if ((x == 0) || (y == 0)) {
    return 0;
  }
  if (x == RAY()) {
    return y;
  }
  if (y == RAY())	{
    return x;
  }

  mathint c = x * y;
  return require_uint256(c / RAY());
}

function rayDivPreciseSummarization(uint256 x, uint256 y) returns uint256 {
  require y != 0;
  if (x == 0) {
    return 0;
  }
  if (y == RAY()) {
    return x;
  }
  if (y == x)	{
    return RAY();
  }
  mathint c = x * RAY();
  return require_uint256(c / y);
}
