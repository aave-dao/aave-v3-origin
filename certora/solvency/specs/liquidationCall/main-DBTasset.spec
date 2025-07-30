
// aave imports
import "../MOCKS/aToken.spec";
import "../common/AddressProvider.spec";

import "../common/optimizations.spec";
import "../common/functions.spec";
import "../common/validation_functions.spec";
import "common-DBTasset.spec";

/*================================================================================================
  Assumptions for this spec file:
  1. Debt asset != Collateral asset.
  2. scaledTotalSupplyCVL(_DBT_debt)!=0  
     [See lemma-revertsIF_totDbt_of_DBTasset_is0.spec for justifications.]
  3. We summarize ReserveLogic.getNormalizedDebt(...), and ReserveLogic.getNormalizedIncome(...) to
     CVL functions. We justify it in the file lemma-DBTasset.spec.
  4. The function _burnBadDebt(..) preserve the solvency property.  
     [See burnBadDebt-* files for justifications]


  See also the README.txt files in the spec/ and spec/liquidationCall/ directories
  ================================================================================================*/

persistent ghost bool INSIDE_liquidationCall;
persistent ghost bool INSIDE_burnBadDebt;

persistent ghost bool HASNoCollateralLeft;
persistent ghost uint256 ACTUAL;
persistent ghost uint256 USER_RESERVE_DEBT;

persistent ghost uint256 _DBT_liqIND {axiom _DBT_liqIND >= 10^27;}
persistent ghost uint256 _DBT_dbtIND {axiom _DBT_dbtIND >= 10^27;}


persistent ghost mathint DELTA;
persistent ghost mathint ORIG_totSUP_aToken;
persistent ghost mathint ORIG_totSUP_debt;
persistent ghost uint128 ORIG_VB;
persistent ghost uint128 ORIG_deficit;

persistent ghost mathint INTR_totSUP_aToken;
persistent ghost mathint INTR_totSUP_debt;
persistent ghost uint128 INTR_VB;
persistent ghost uint128 INTR_deficit;

persistent ghost mathint INTR2_totSUP_aToken;
persistent ghost mathint INTR2_totSUP_debt;
persistent ghost uint128 INTR2_VB;
persistent ghost uint128 INTR2_deficit;

persistent ghost mathint INTR3_totSUP_aToken;
persistent ghost mathint INTR3_totSUP_debt;
persistent ghost uint128 INTR3_VB;
persistent ghost uint128 INTR3_deficit;


/*================================================================================================
  Summarizations
  ================================================================================================*/
methods {
  function ReserveLogic.getNormalizedIncome(DataTypes.ReserveData storage reserve)
    internal returns (uint256) => getNormalizedIncome_CVL();

  function ReserveLogic.getNormalizedDebt(DataTypes.ReserveData storage reserve)
    internal returns (uint256) => getNormalizedDebt_CVL();

  function LiquidationLogic._burnBadDebt(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    DataTypes.UserConfigurationMap storage userConfig,
    DataTypes.ExecuteLiquidationCallParams memory params
  ) internal with (env e) => _burnBadDebt_CVL(e);
}

function getNormalizedIncome_CVL() returns uint256 {
  if (INSIDE_liquidationCall) {
    uint256 col_index;
    return col_index;
  }
  else
    return _DBT_liqIND;
}

function getNormalizedDebt_CVL() returns uint256 {
  if (!INSIDE_burnBadDebt)
    return _DBT_dbtIND;
  else {
    uint256 val;
    return val;
  }
}

function _burnBadDebt_CVL(env e) {
  INSIDE_liquidationCall = false;

  mathint curr_totSUP_aToken = aTokenTotalSupplyCVL(_DBT_atoken, e);
  mathint curr_totSUP_debt   = aTokenTotalSupplyCVL(_DBT_debt, e);
  uint128 curr_VB            = getReserveDataExtended(_DBT_asset).virtualUnderlyingBalance;
  uint128 curr_deficit       = getReserveDataExtended(_DBT_asset).deficit;
  
  if (curr_totSUP_aToken <= curr_VB + curr_totSUP_debt + curr_deficit + DELTA + _DBT_dbtIND / RAY()) {
    havoc_all(e);
    mathint after_totSUP_aToken = aTokenTotalSupplyCVL(_DBT_atoken, e);
    mathint after_totSUP_debt   = aTokenTotalSupplyCVL(_DBT_debt, e);
    uint128 after_VB            = getReserveDataExtended(_DBT_asset).virtualUnderlyingBalance;
    uint128 after_deficit       = getReserveDataExtended(_DBT_asset).deficit;

    require
      after_totSUP_aToken <=
      after_VB + after_totSUP_debt + after_deficit + DELTA
      ;

    require
      getReserveDataExtended(_DBT_asset).variableBorrowIndex == getNormalizedDebt_CVL();

    require
      getReserveDataExtended(_DBT_asset).liquidityIndex == _DBT_liqIND;
  }
  INSIDE_liquidationCall = true;
}


/*================================================================================================
  Summarizations of HOOKS function 
  ================================================================================================*/
methods {
  function LiquidationLogic.HOOK_liquidation_after_updateState_DBT()
    internal => HOOK_liquidation_after_updateState_DBT_CVL();

  function LiquidationLogic.HOOK_liquidation_before_burnDebtTokens(bool hasNoCollateralLeft)
    internal with (env e) => HOOK_liquidation_before_burnDebtTokens_CVL(e, hasNoCollateralLeft);

  function LiquidationLogic.HOOK_liquidation_after_burnDebtTokens
    (bool hasNoCollateralLeft, uint256 actualDebtToLiquidate, uint256 userReserveDebt) internal with (env e) =>
    HOOK_liquidation_after_burnDebtTokens_CVL(e, hasNoCollateralLeft, actualDebtToLiquidate, userReserveDebt);

  function LiquidationLogic.HOOK_liquidation_before_burnBadDebt()
    internal with (env e) => HOOK_liquidation_before_burnBadDebt_CVL(e);

  function LiquidationLogic.HOOK_burnBadDebt_inside_loop(address reserveAddress)
    internal with (env e) => HOOK_burnBadDebt_inside_loop_CVL(e, reserveAddress);

  function LiquidationLogic.HOOK_liquidation_after_burnBadDebt()
    internal with (env e) => HOOK_liquidation_after_burnBadDebt_CVL(e);
}


// This is immediately after the call to updateState for the DBT token
function HOOK_liquidation_after_updateState_DBT_CVL() {
  require currentContract._reserves[_DBT_asset].liquidityIndex == _DBT_liqIND;
  require currentContract._reserves[_DBT_asset].variableBorrowIndex == _DBT_dbtIND;
}

function HOOK_liquidation_before_burnDebtTokens_CVL(env e, bool hasNoCollateralLeft) {
  INSIDE_liquidationCall = false;
  
  mathint curr_totSUP_aToken;  curr_totSUP_aToken = aTokenTotalSupplyCVL(_DBT_atoken, e);
  mathint curr_totSUP_debt;    curr_totSUP_debt   = aTokenTotalSupplyCVL(_DBT_debt, e);
  uint128 curr_VB;             curr_VB            = getReserveDataExtended(_DBT_asset).virtualUnderlyingBalance;
  uint128 curr_deficit;        curr_deficit       = getReserveDataExtended(_DBT_asset).deficit;
  
  assert ORIG_totSUP_aToken == curr_totSUP_aToken;
  assert ORIG_totSUP_debt   == curr_totSUP_debt;
  assert ORIG_VB == curr_VB;
  assert ORIG_deficit == curr_deficit;

  assert ORIG_totSUP_aToken <= ORIG_VB + ORIG_totSUP_debt + ORIG_deficit + DELTA;

  INSIDE_liquidationCall = true;
}

function HOOK_liquidation_after_burnDebtTokens_CVL(env e, bool hasNoCollateralLeft,
                                                   uint256 actualDebtToLiquidate, uint256 userReserveDebt) {
  INSIDE_liquidationCall = false;
  HASNoCollateralLeft = hasNoCollateralLeft;
  ACTUAL = actualDebtToLiquidate;
  USER_RESERVE_DEBT = userReserveDebt;

  INTR_totSUP_aToken = aTokenTotalSupplyCVL(_DBT_atoken, e);
  INTR_totSUP_debt   = aTokenTotalSupplyCVL(_DBT_debt, e);
  INTR_VB            = getReserveDataExtended(_DBT_asset).virtualUnderlyingBalance;
  INTR_deficit       = getReserveDataExtended(_DBT_asset).deficit;


  assert ORIG_totSUP_aToken == INTR_totSUP_aToken;
  assert INTR_VB == ORIG_VB + actualDebtToLiquidate;
  assert !hasNoCollateralLeft => 
    INTR_totSUP_debt >= ORIG_totSUP_debt - actualDebtToLiquidate;

  assert hasNoCollateralLeft =>
    INTR_totSUP_debt >= ORIG_totSUP_debt - userReserveDebt;
  assert hasNoCollateralLeft =>
    INTR_deficit == ORIG_deficit + (userReserveDebt - actualDebtToLiquidate);

  // THE MAIN ASSERTION
  assert INTR_totSUP_aToken <= INTR_VB + INTR_totSUP_debt + INTR_deficit + DELTA;

  INSIDE_liquidationCall = true;
}


function HOOK_liquidation_before_burnBadDebt_CVL(env e) {
  INSIDE_liquidationCall = false;

  INTR2_totSUP_aToken = aTokenTotalSupplyCVL(_DBT_atoken, e);
  INTR2_totSUP_debt   = aTokenTotalSupplyCVL(_DBT_debt, e);
  INTR2_deficit       = getReserveDataExtended(_DBT_asset).deficit;
  INTR2_VB            = getReserveDataExtended(_DBT_asset).virtualUnderlyingBalance;
  
  assert INTR2_totSUP_aToken == INTR_totSUP_aToken;
  assert INTR2_totSUP_debt == INTR_totSUP_debt;
  assert INTR2_deficit == INTR_deficit;
  assert INTR2_VB == INTR_VB;
  
  // THE MAIN ASSERTION
  assert INTR2_totSUP_aToken <= INTR2_VB + INTR2_totSUP_debt + INTR2_deficit + DELTA;
  
  INSIDE_burnBadDebt = true;
  INSIDE_liquidationCall = true;
}


function HOOK_burnBadDebt_inside_loop_CVL(env e, address reserveAddress) {}

function HOOK_liquidation_after_burnBadDebt_CVL(env e) {
  INSIDE_burnBadDebt = false;
  INSIDE_liquidationCall = false;
  
  INTR3_totSUP_aToken = aTokenTotalSupplyCVL(_DBT_atoken, e);
  INTR3_totSUP_debt   = aTokenTotalSupplyCVL(_DBT_debt, e);
  INTR3_deficit       = getReserveDataExtended(_DBT_asset).deficit;
  INTR3_VB            = getReserveDataExtended(_DBT_asset).virtualUnderlyingBalance;
  
  assert INTR3_totSUP_aToken == INTR_totSUP_aToken;
  assert INTR3_totSUP_debt == INTR_totSUP_debt;
  assert INTR3_deficit == INTR_deficit;
  assert INTR3_VB == INTR_VB;
  
  // THE MAIN ASSERTION
  assert INTR3_totSUP_aToken <= INTR3_VB + INTR3_totSUP_debt + INTR3_deficit + DELTA;
  
  INSIDE_liquidationCall = true;
}



/*=====================================================================================
  Rule: solvency__liquidationCall
  =====================================================================================*/
rule solvency__liquidationCall_DBTasset(env e) {
  INSIDE_liquidationCall = false;
  INSIDE_burnBadDebt = false;
  configuration();

  DataTypes.ReserveData reserve = getReserveDataExtended(_DBT_asset);
  require getReserveAddressById(reserve.id)==_DBT_asset;
  require reserve.id!=0 => getReserveAddressById(0) != _DBT_asset;
  require reserve.lastUpdateTimestamp <= require_uint40(e.block.timestamp);
  
  ORIG_totSUP_aToken = aTokenTotalSupplyCVL(_DBT_atoken, e);
  ORIG_totSUP_debt = aTokenTotalSupplyCVL(_DBT_debt, e);
  ORIG_VB = getReserveDataExtended(_DBT_asset).virtualUnderlyingBalance;
  ORIG_deficit = getReserveDataExtended(_DBT_asset).deficit;

  // BASIC ASSUMPTION FOR THE RULE
  require isVirtualAccActive(reserve.configuration.data);

  // THE MAIN REQUIREMENT
  require ORIG_totSUP_aToken <= ORIG_VB + ORIG_totSUP_debt + ORIG_deficit + DELTA;

  // PROVED ASSUMPTIONS
  bool exists_debt = scaledTotalSupplyCVL(_DBT_debt)!=0;
  require exists_debt;

  // THE FUNCTION CALL
  address user; uint256 debtToCover; bool receiveAToken;
  INSIDE_liquidationCall = true;
  liquidationCall(e, _COL_asset, _DBT_asset, user, debtToCover, receiveAToken);
  INSIDE_liquidationCall = false;
  
  DataTypes.ReserveData reserve2 = getReserveDataExtended(_DBT_asset);
  
  mathint FINAL_totSUP_aToken; FINAL_totSUP_aToken = aTokenTotalSupplyCVL(_DBT_atoken, e);
  mathint FINAL_totSUP_debt;   FINAL_totSUP_debt   = aTokenTotalSupplyCVL(_DBT_debt, e);
  uint128 FINAL_VB = getReserveDataExtended(_DBT_asset).virtualUnderlyingBalance;
  uint128 FINAL_deficit = getReserveDataExtended(_DBT_asset).deficit;

  assert FINAL_totSUP_aToken == INTR_totSUP_aToken;
  assert FINAL_totSUP_debt == INTR_totSUP_debt;
  assert FINAL_deficit == INTR_deficit;
  assert FINAL_VB == INTR_VB;


  //THE ASSERTION
  assert
    FINAL_totSUP_aToken <= FINAL_VB + FINAL_totSUP_debt + FINAL_deficit + DELTA
    ;
  
}

