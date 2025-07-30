import "MOCKS/rayMulDiv-CVL.spec";


methods {
  function _.ADDRESSES_PROVIDER() external => NONDET; // expect address

  function getReserveDataExtended(address) external returns (DataTypes.ReserveData memory) envfree;
  function getReserveAddressById(uint16 id) external returns (address) envfree;
  function getReservesList() external returns (address[]) envfree;
    
  function _.rayMul(uint256 a, uint256 b) external => rayMulCVL(a,b) expect uint256;
  function _.rayMulFloor(uint256 a, uint256 b) external => rayMulFloorCVL(a,b) expect uint256;
  function _.rayMulCeil(uint256 a, uint256 b) external => rayMulCeilCVL(a,b) expect uint256;
  function _.rayDiv(uint256 a, uint256 b) external => rayDivCVL(a,b) expect uint256;
  function _.rayDivFloor(uint256 a, uint256 b) external => rayDivFloorCVL(a,b) expect uint256;
  function _.rayDivCeil(uint256 a, uint256 b) external => rayDivCeilCVL(a,b) expect uint256;

  function _.rayMul(uint256 a, uint256 b) internal => rayMulCVL(a,b) expect uint256;
  function _.rayMulFloor(uint256 a, uint256 b) internal => rayMulFloorCVL(a,b) expect uint256;
  function _.rayMulCeil(uint256 a, uint256 b) internal => rayMulCeilCVL(a,b) expect uint256;
  function _.rayDiv(uint256 a, uint256 b) internal => rayDivCVL(a,b) expect uint256;
  function _.rayDivFloor(uint256 a, uint256 b) internal => rayDivFloorCVL(a,b) expect uint256;
  function _.rayDivCeil(uint256 a, uint256 b) internal => rayDivCeilCVL(a,b) expect uint256;

  function _.percentMul(uint256 a, uint256 b) internal => percentMulCVL(a,b) expect uint256;
  function _.percentMulCeil(uint256 a, uint256 b) internal => percentMulCeilCVL(a,b) expect uint256;

  function _.percentDiv(uint256 a, uint256 b) internal => percentDivCVL(a,b) expect uint256;
  function _.percentDivCeil(uint256 a, uint256 b) internal => percentDivCeilCVL(a,b) expect uint256;
  function _.percentDivFloor(uint256 a, uint256 b) internal => percentDivFloorCVL(a,b) expect uint256;
}



methods {
  function ReserveConfiguration.getLiquidationProtocolFee(DataTypes.ReserveConfigurationMap memory self)
    internal returns (uint256) => PROTOCOL_FEE;

  function _.getAssetPrice(address asset) external => ASSET_PRICE expect uint256;
  function _.scaledBalanceOf(address user) external => SCALED_BAL_OF[calledContract][user] expect uint256;
  function _.getNormalizedIncome() internal => 10^27 expect uint256;

  function _.get_liquidationThreshold(address asset) internal => CVL_get_liquidationThreshold(asset) expect uint256;

  function _.set_currentReserveAddress(address asset) internal => CVL_set_currentReserveAddress(asset) expect void;

  function _._getUserDebtInBaseCurrency(
                                        address user,
                                        DataTypes.ReserveData storage reserve,
                                        uint256 assetPrice,
                                        uint256 assetUnit
  ) internal => CVL_getUserDebtInBaseCurrency(user) expect uint256;

  function _._getUserBalanceInBaseCurrency(
                                           address user,
                                           DataTypes.ReserveData storage reserve,
                                           uint256 assetPrice,
                                           uint256 assetUnit
  ) internal => CVL_getUserBalanceInBaseCurrency(user) expect uint256;


  // debug functions:
  function _.debug_totalCollateralInBaseCurrency(uint256 val) internal => CVL_totalCollateralInBaseCurrency(val) expect void;
  function _.debug_avgLiquidationThreshold(uint256 val) internal => CVL_avgLiquidationThreshold(val) expect void;
  function _.debug_totalDebtInBaseCurrency(uint256 val) internal => CVL_totalDebtInBaseCurrency(val) expect void;
  function _.debug_avgLiquidationThreshold_final(uint256 val) internal => CVL_avgLiquidationThreshold_final(val) expect void;

}

persistent ghost uint256 PROTOCOL_FEE {
  axiom PROTOCOL_FEE <= 65535;
}


persistent ghost uint256 ASSET_PRICE {
  axiom ASSET_PRICE == 10^8;
}

persistent ghost mapping(address => mapping(address => uint256)) SCALED_BAL_OF {
  axiom 1==1;
}

persistent ghost mapping(address => mapping(address => uint256)) DEBT_IN_BASE_CURRENCY {
  axiom 1==1;
}

persistent ghost mapping(address => mapping(address => uint256)) BAL_IN_BASE_CURRENCY {
  axiom 1==1;
}

persistent ghost mapping(address => uint256) LIQUIDATION_TRASHOLD {
  axiom forall address a. 7000 <= LIQUIDATION_TRASHOLD[a]  &&  LIQUIDATION_TRASHOLD[a] <= 10000;
}

function CVL_get_liquidationThreshold(address asset) returns uint256 {
  return LIQUIDATION_TRASHOLD[asset];
}

persistent ghost address CURR_ASSET {axiom 1==1;}
function CVL_set_currentReserveAddress(address asset) {CURR_ASSET = asset;}

function CVL_getUserDebtInBaseCurrency(address user) returns uint256 {
  return DEBT_IN_BASE_CURRENCY[CURR_ASSET][user];
}
function CVL_getUserBalanceInBaseCurrency(address user) returns uint256 {
  return BAL_IN_BASE_CURRENCY[CURR_ASSET][user];
}



persistent ghost uint256 DEBUG_totalCollateralInBaseCurrency;
function CVL_totalCollateralInBaseCurrency(uint256 val) {
  DEBUG_totalCollateralInBaseCurrency = val;
}

persistent ghost uint256 DEBUG_avgLiquidationThreshold;
function CVL_avgLiquidationThreshold(uint256 val) {
  DEBUG_avgLiquidationThreshold = val;
}

persistent ghost uint256 DEBUG_totalDebtInBaseCurrency;
function CVL_totalDebtInBaseCurrency(uint256 val) {
  DEBUG_totalDebtInBaseCurrency = val;
}

persistent ghost uint256 DEBUG_avgLiquidationThreshold_final;
function CVL_avgLiquidationThreshold_final(uint256 val) {
  DEBUG_avgLiquidationThreshold_final = val;
}

persistent ghost address ASSET1; //persistent ghost address ATOKEN1; persistent ghost address DEBT1;
persistent ghost address ASSET2; //persistent ghost address ATOKEN2; persistent ghost address DEBT2;



// *******************************************
// rule: gift_cannot_decrease_healthFactor_reducedCode
// Description: Gifting a user, cannot decrease his health factor.
//              We use the following configuration: we have 2 assets, both are enabled as collaterals,
//              and only one is borrowed. We call the function calculateUserAccountData twice, where
//              the only difference between the calls is the increased balance of the user in asset-1
//              (used as collateral, but not borrowed). We prove that the HF of the user can only increase.
// Status: passed
// Link: https://prover.certora.com/output/66114/88cba9baa1cc4a6598e26e8f275725b5/?anonymousKey=980df3b3ec4645686873e5127e604312498c698e
// *******************************************
rule gift_cannot_decrease_healthFactor_origCode(env e) {
  address bob = 0xb0b;
  ASSET1 = 1;
  ASSET2 = 2;

  
  DataTypes.CalculateUserAccountDataParams params;
  require params.userEModeCategory == 0;
  require params.user == bob;

  uint256 userConfigCache = params.userConfig.data;

  uint256 userConfigCache1; bool isBorrowed;  bool isEnabledAsCollateral;
  (userConfigCache1,isBorrowed,isEnabledAsCollateral) = getNextFlags(e, userConfigCache);
  require !isBorrowed;
  require isEnabledAsCollateral;

  uint256 userConfigCache2; bool isBorrowed2;  bool isEnabledAsCollateral2;
  (userConfigCache2,isBorrowed2,isEnabledAsCollateral2) = getNextFlags(e, userConfigCache1);
  require isBorrowed2;
  require isEnabledAsCollateral2;

  require getReservesCount(e) == 2;
  require getReserveAddressById(e,0) == ASSET1;
  require getReserveAddressById(e,1) == ASSET2;

  uint256 __ASSET1_bal; uint256 __ASSET1_bal__PLUS;
  uint256 __ASSET2_bal;
  uint256 __DEBT1_bal;
  uint256 __DEBT2_bal;

  BAL_IN_BASE_CURRENCY[ASSET1][bob] = __ASSET1_bal;
  BAL_IN_BASE_CURRENCY[ASSET2][bob] = __ASSET2_bal;
  DEBT_IN_BASE_CURRENCY[ASSET1][bob] = __DEBT1_bal;
  DEBT_IN_BASE_CURRENCY[ASSET2][bob] = __DEBT2_bal;


  uint256 a1;  uint256 b1;  uint256 c1;  uint256 d1;  uint256 health_factor1;  bool f1;
  (a1,b1,c1,d1,health_factor1,f1) = WRP_calculateUserAccountData_ORIG(e, params);
  //  require 10^18 <= health_factor1;
  
  // Someone gifted bob in ASSET1
  BAL_IN_BASE_CURRENCY[ASSET1][bob] = __ASSET1_bal__PLUS;
  require __ASSET1_bal__PLUS > __ASSET1_bal;

  uint256 a2;  uint256 b2;  uint256 c2;  uint256 d2;  uint256 health_factor2;  bool f2;
  (a2,b2,c2,d2,health_factor2,f2) = WRP_calculateUserAccountData_ORIG(e, params);

  //assert 10^18 <= health_factor2;
  assert health_factor1 <= health_factor2;
}


/*
rule gift_cannot_decrease_healthFactor_reducedCode(env e) {
  address bob = 0xb0b;
  ASSET1 = 1; //ATOKEN1 = 0x10; DEBT1 = 0x11;
  ASSET2 = 2; //ATOKEN2 = 0x20; DEBT2 = 0x21;

  
  DataTypes.CalculateUserAccountDataParams params;
  require params.userEModeCategory == 0;
  require params.user == bob;

  uint256 userConfigCache = params.userConfig.data;

  uint256 userConfigCache1; bool isBorrowed;  bool isEnabledAsCollateral;
  (userConfigCache1,isBorrowed,isEnabledAsCollateral) = getNextFlags(e, userConfigCache);
  require !isBorrowed;
  require isEnabledAsCollateral;

  uint256 userConfigCache2; bool isBorrowed2;  bool isEnabledAsCollateral2;
  (userConfigCache2,isBorrowed2,isEnabledAsCollateral2) = getNextFlags(e, userConfigCache1);
  require isBorrowed2;
  require isEnabledAsCollateral2;

  require getReservesCount(e) == 2;
  require getReserveAddressById(e,0) == ASSET1;
  require getReserveAddressById(e,1) == ASSET2;

  uint256 __ASSET1_bal; uint256 __ASSET1_bal__PLUS;
  uint256 __ASSET2_bal;
  uint256 __DEBT1_bal;
  uint256 __DEBT2_bal;

  BAL_IN_BASE_CURRENCY[ASSET1][bob] = __ASSET1_bal;
  BAL_IN_BASE_CURRENCY[ASSET2][bob] = __ASSET2_bal;
  DEBT_IN_BASE_CURRENCY[ASSET1][bob] = __DEBT1_bal;
  DEBT_IN_BASE_CURRENCY[ASSET2][bob] = __DEBT2_bal;


  uint256 health_factor1 = WRP_calculateUserAccountData_REDUCED(e, params);
  //  require 10^18 <= health_factor1;
  
  // Someone gifted bob in ASSET1
  BAL_IN_BASE_CURRENCY[ASSET1][bob] = __ASSET1_bal__PLUS;
  require __ASSET1_bal__PLUS > __ASSET1_bal;


  uint256 health_factor2 = WRP_calculateUserAccountData_REDUCED(e, params);

  //  assert 10^18 <= health_factor2;
  assert health_factor1 <= health_factor2;
}
*/
