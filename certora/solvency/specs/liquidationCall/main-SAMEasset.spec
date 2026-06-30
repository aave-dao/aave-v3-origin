 
// aave imports
import "../MOCKS/aToken.spec";
import "../common/AddressProvider.spec";

import "../common/optimizations.spec";
import "../common/functions.spec";
import "../common/validation_functions.spec";
import "common-SAMEasset.spec";

/*================================================================================================
  Assumptions for this spec file:
  1. Debt asset == Collateral asset.
  2. scaledTotalSupplyCVL(_DBT_debt)!=0  
     [See lemma-revertsIF_totDbt_of_DBTasset_is0.spec for justifications.]
  3. We summarize ReserveLogic.getNormalizedDebt(...), and ReserveLogic.getNormalizedIncome(...) to
     CVL functions. We justify it in the file lemma-COLasset.spec.
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

persistent ghost mathint INTR1_totSUP_aToken;
persistent ghost mathint INTR1_totSUP_debt;
persistent ghost uint128 INTR1_VB;
persistent ghost uint128 INTR1_deficit;

persistent ghost mathint INTR1a_totSUP_aToken;
persistent ghost mathint INTR1a_totSUP_debt;
persistent ghost uint128 INTR1a_VB;
persistent ghost uint128 INTR1a_deficit;

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

  mathint curr_totSUP_aToken = aTokenTotalSupplyCVL(ATOKEN, e);
  mathint curr_totSUP_debt   = aTokenTotalSupplyCVL(DEBT, e);
  uint128 curr_VB            = getReserveDataExtended(ASSET).virtualUnderlyingBalance;
  uint128 curr_deficit       = getReserveDataExtended(ASSET).deficit;
  
  if (curr_totSUP_aToken <= curr_VB + curr_totSUP_debt + curr_deficit + DELTA + _DBT_dbtIND / RAY()) {
    havoc_all(e);
    mathint after_totSUP_aToken = aTokenTotalSupplyCVL(ATOKEN, e);
    mathint after_totSUP_debt   = aTokenTotalSupplyCVL(DEBT, e);
    uint128 after_VB            = getReserveDataExtended(ASSET).virtualUnderlyingBalance;
    uint128 after_deficit       = getReserveDataExtended(ASSET).deficit;

    require
      after_totSUP_aToken <=
      after_VB + after_totSUP_debt + after_deficit + DELTA
      ;

    require
      getReserveDataExtended(ASSET).variableBorrowIndex == getNormalizedDebt_CVL();

    require
      getReserveDataExtended(ASSET).liquidityIndex == _DBT_liqIND;
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
    (bool hasNoCollateralLeft, uint256 actualDebtToLiquidate, uint256 borrowerReserveDebt) internal with (env e) =>
    HOOK_liquidation_after_burnDebtTokens_CVL(e, hasNoCollateralLeft, actualDebtToLiquidate, borrowerReserveDebt);

  function LiquidationLogic.HOOK_liquidation_after_liquidateATokens()
    internal with (env e) => HOOK_liquidation_after_liquidateATokens_CVL(e);

  function LiquidationLogic.HOOK_liquidation_after_burnCollateralATokens(uint256 actualCollateralToLiquidate)
    internal with (env e) => HOOK_liquidation_after_burnCollateralATokens_CVL(e, actualCollateralToLiquidate);

  function LiquidationLogic.HOOK_liquidation_before_burnBadDebt()
    internal with (env e) => HOOK_liquidation_before_burnBadDebt_CVL(e);

  function LiquidationLogic.HOOK_burnBadDebt_inside_loop(address reserveAddress)
    internal with (env e) => HOOK_burnBadDebt_inside_loop_CVL(e, reserveAddress);

  function LiquidationLogic.HOOK_liquidation_after_burnBadDebt()
    internal with (env e) => HOOK_liquidation_after_burnBadDebt_CVL(e);
}


// This is immediately after the call to updateState for the DBT token
function HOOK_liquidation_after_updateState_DBT_CVL() {
  require currentContract._reserves[ASSET].liquidityIndex == _DBT_liqIND;
  require currentContract._reserves[ASSET].variableBorrowIndex == _DBT_dbtIND;
}

function HOOK_liquidation_before_burnDebtTokens_CVL(env e, bool hasNoCollateralLeft) {
  INSIDE_liquidationCall = false;
  
  mathint curr_totSUP_aToken;  curr_totSUP_aToken = aTokenTotalSupplyCVL(ATOKEN, e);
  mathint curr_totSUP_debt;    curr_totSUP_debt   = aTokenTotalSupplyCVL(DEBT, e);
  uint128 curr_VB;             curr_VB            = getReserveDataExtended(ASSET).virtualUnderlyingBalance;
  uint128 curr_deficit;        curr_deficit       = getReserveDataExtended(ASSET).deficit;
  
  // The following assertions imply that so far nothing changed.
  assert ORIG_totSUP_aToken == curr_totSUP_aToken;
  assert ORIG_totSUP_debt   == curr_totSUP_debt;
  assert ORIG_VB == curr_VB;
  assert ORIG_deficit == curr_deficit;

  assert ORIG_totSUP_aToken <= ORIG_VB + ORIG_totSUP_debt + ORIG_deficit + DELTA;

  INSIDE_liquidationCall = true;
}

function HOOK_liquidation_after_burnDebtTokens_CVL(env e, bool hasNoCollateralLeft,
                                                   uint256 actualDebtToLiquidate, uint256 borrowerReserveDebt) {
  INSIDE_liquidationCall = false;
  HASNoCollateralLeft = hasNoCollateralLeft;
  ACTUAL = actualDebtToLiquidate;
  USER_RESERVE_DEBT = borrowerReserveDebt;

  INTR1_totSUP_aToken = aTokenTotalSupplyCVL(ATOKEN, e);
  INTR1_totSUP_debt   = aTokenTotalSupplyCVL(DEBT, e);
  INTR1_VB            = getReserveDataExtended(ASSET).virtualUnderlyingBalance;
  INTR1_deficit       = getReserveDataExtended(ASSET).deficit;


  assert ORIG_totSUP_aToken == INTR1_totSUP_aToken;
  assert INTR1_VB == ORIG_VB + actualDebtToLiquidate;
  assert !hasNoCollateralLeft => 
    INTR1_totSUP_debt >= ORIG_totSUP_debt - actualDebtToLiquidate;

  assert hasNoCollateralLeft =>
    INTR1_totSUP_debt >= ORIG_totSUP_debt - borrowerReserveDebt;
  assert hasNoCollateralLeft =>
    INTR1_deficit == ORIG_deficit + (borrowerReserveDebt - actualDebtToLiquidate);

  // THE MAIN ASSERTION
  assert INTR1_totSUP_aToken <= INTR1_VB + INTR1_totSUP_debt + INTR1_deficit + DELTA;

  INSIDE_liquidationCall = true;
}


// NEW1
function HOOK_liquidation_after_liquidateATokens_CVL(env e) {
  INSIDE_liquidationCall = false;
  
  INTR1a_totSUP_aToken = aTokenTotalSupplyCVL(ATOKEN, e);
  INTR1a_totSUP_debt   = aTokenTotalSupplyCVL(DEBT, e);
  INTR1a_VB            = getReserveDataExtended(ASSET).virtualUnderlyingBalance;
  INTR1a_deficit       = getReserveDataExtended(ASSET).deficit;
  
  assert INTR1a_totSUP_debt == INTR1_totSUP_debt; //ORIG_totSUP_debt;
  assert INTR1a_deficit == INTR1_deficit; //ORIG_deficit;
  assert INTR1a_VB == INTR1_VB;
  assert INTR1a_totSUP_aToken == INTR1_totSUP_aToken;

  // THE MAIN ASSERTION
  assert INTR1a_totSUP_aToken <= INTR1a_VB + INTR1a_totSUP_debt + INTR1a_deficit + DELTA;

  INSIDE_liquidationCall = true;
}

// NEW2
function HOOK_liquidation_after_burnCollateralATokens_CVL(env e, uint256 actualCollateralToLiquidate) {
  INSIDE_liquidationCall = false;
  
  INTR1a_totSUP_aToken = aTokenTotalSupplyCVL(ATOKEN, e);
  INTR1a_totSUP_debt   = aTokenTotalSupplyCVL(DEBT, e);
  INTR1a_VB            = getReserveDataExtended(ASSET).virtualUnderlyingBalance;
  INTR1a_deficit       = getReserveDataExtended(ASSET).deficit;
  
  assert INTR1a_totSUP_debt == INTR1_totSUP_debt; //ORIG_totSUP_debt;
  assert INTR1a_deficit == INTR1_deficit; //ORIG_deficit;

  assert INTR1a_VB == INTR1_VB - actualCollateralToLiquidate; //ORIG_VB - actualCollateralToLiquidate;
  assert INTR1a_totSUP_aToken <= INTR1_totSUP_aToken - actualCollateralToLiquidate;//ORIG_totSUP_aToken - actualCollateralToLiquidate;

  // THE MAIN ASSERTION
  assert INTR1a_totSUP_aToken <= INTR1a_VB + INTR1a_totSUP_debt + INTR1a_deficit + DELTA;

  INSIDE_liquidationCall = true;
}






function HOOK_liquidation_before_burnBadDebt_CVL(env e) {
  INSIDE_liquidationCall = false;

  INTR2_totSUP_aToken = aTokenTotalSupplyCVL(ATOKEN, e);
  INTR2_totSUP_debt   = aTokenTotalSupplyCVL(DEBT, e);
  INTR2_deficit       = getReserveDataExtended(ASSET).deficit;
  INTR2_VB            = getReserveDataExtended(ASSET).virtualUnderlyingBalance;
  
  assert INTR2_totSUP_aToken == INTR1a_totSUP_aToken;
  assert INTR2_totSUP_debt == INTR1a_totSUP_debt;
  assert INTR2_deficit == INTR1a_deficit;
  assert INTR2_VB == INTR1a_VB;
  
  // THE MAIN ASSERTION
  assert INTR2_totSUP_aToken <= INTR2_VB + INTR2_totSUP_debt + INTR2_deficit + DELTA;
  
  INSIDE_burnBadDebt = true;
  INSIDE_liquidationCall = true;
}


function HOOK_burnBadDebt_inside_loop_CVL(env e, address reserveAddress) {}

function HOOK_liquidation_after_burnBadDebt_CVL(env e) {
  INSIDE_burnBadDebt = false;
  INSIDE_liquidationCall = false;
  
  INTR3_totSUP_aToken = aTokenTotalSupplyCVL(ATOKEN, e);
  INTR3_totSUP_debt   = aTokenTotalSupplyCVL(DEBT, e);
  INTR3_deficit       = getReserveDataExtended(ASSET).deficit;
  INTR3_VB            = getReserveDataExtended(ASSET).virtualUnderlyingBalance;
  
  assert INTR3_totSUP_aToken == INTR1a_totSUP_aToken;
  assert INTR3_totSUP_debt == INTR1a_totSUP_debt;
  assert INTR3_deficit == INTR1a_deficit;
  assert INTR3_VB == INTR1a_VB;
  
  // THE MAIN ASSERTION
  assert INTR3_totSUP_aToken <= INTR3_VB + INTR3_totSUP_debt + INTR3_deficit + DELTA;
  
  INSIDE_liquidationCall = true;
}



/*=====================================================================================
  Rule: liquidationCall__SAMEasset__solvency
  =====================================================================================*/
rule liquidationCall__SAMEasset__solvency(env e) {
  INSIDE_liquidationCall = false;
  INSIDE_burnBadDebt = false;
  configuration_DBTeqCOL();

  DataTypes.ReserveData reserve = getReserveDataExtended(ASSET);
  require getReserveAddressById(reserve.id)==ASSET;
  require reserve.id!=0 => getReserveAddressById(0) != ASSET;
  require reserve.lastUpdateTimestamp <= require_uint40(e.block.timestamp);
  
  ORIG_totSUP_aToken = aTokenTotalSupplyCVL(ATOKEN, e);
  ORIG_totSUP_debt = aTokenTotalSupplyCVL(DEBT, e);
  ORIG_VB = getReserveDataExtended(ASSET).virtualUnderlyingBalance;
  ORIG_deficit = getReserveDataExtended(ASSET).deficit;

  // BASIC ASSUMPTION FOR THE RULE
  require isVirtualAccActive(reserve.configuration.data);

  // THE MAIN REQUIREMENT
  require ORIG_totSUP_aToken <= ORIG_VB + ORIG_totSUP_debt + ORIG_deficit + DELTA;

  //  require ORIG_totSUP_aToken <= 10^27; // Without this requirement we get a timeout
                                       // I believe it's due inaccure RAY-calculations.

  // PROVED ASSUMPTIONS
  bool exists_debt = scaledTotalSupplyCVL(DEBT)!=0;
  require exists_debt;

  // THE FUNCTION CALL
  address user; uint256 debtToCover; bool receiveAToken;
  INSIDE_liquidationCall = true;
  liquidationCall(e, ASSET/*==_COL_asset*/, ASSET, user, debtToCover, receiveAToken);
  INSIDE_liquidationCall = false;
  
  DataTypes.ReserveData reserve2 = getReserveDataExtended(ASSET);
  
  mathint FINAL_totSUP_aToken; FINAL_totSUP_aToken = aTokenTotalSupplyCVL(ATOKEN, e);
  mathint FINAL_totSUP_debt;   FINAL_totSUP_debt   = aTokenTotalSupplyCVL(DEBT, e);
  uint128 FINAL_VB = getReserveDataExtended(ASSET).virtualUnderlyingBalance;
  uint128 FINAL_deficit = getReserveDataExtended(ASSET).deficit;

  assert FINAL_totSUP_aToken == INTR1a_totSUP_aToken;
  assert FINAL_totSUP_debt == INTR1a_totSUP_debt;
  assert FINAL_deficit == INTR1a_deficit;
  assert FINAL_VB == INTR1a_VB;


  //THE ASSERTION
  assert
    FINAL_totSUP_aToken <= FINAL_VB + FINAL_totSUP_debt + FINAL_deficit + DELTA
    ;
  
}

