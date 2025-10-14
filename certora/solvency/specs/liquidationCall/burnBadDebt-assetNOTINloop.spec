
// aave imports
import "../MOCKS/aToken.spec";
import "../common/AddressProvider.spec";

import "../common/optimizations.spec";
import "../common/functions.spec";
import "../common/validation_functions.spec";


/*================================================================================================
  Rules in the file:
  PASS: https://prover.certora.com/output/66114/cd7e0f9d2fc44e16a1f2c80918ec0fba/?anonymousKey=04d6f84469e7d81aea57a662f69e2f9bf8fae266
  ================================================================================================*/


persistent ghost address ATOKEN; persistent ghost address DEBT;

persistent ghost mathint DELTA;

persistent ghost mathint ORIG_totSUP_aToken;
persistent ghost mathint ORIG_totSUP_debt;
persistent ghost uint128 ORIG_VB;
persistent ghost uint128 ORIG_deficit;

persistent ghost mathint INTR1_totSUP_aToken;
persistent ghost mathint INTR1_totSUP_debt;
persistent ghost uint128 INTR1_VB;
persistent ghost uint128 INTR1_deficit;

persistent ghost mathint INTR2_totSUP_aToken;
persistent ghost mathint INTR2_totSUP_debt;
persistent ghost uint128 INTR2_VB;
persistent ghost uint128 INTR2_deficit;



methods {
  function LiquidationLogic.HOOK_burnBadDebt_inside_loop(address reserveAddress)
    internal with (env e) => HOOK_burnBadDebt_inside_loop_CVL(e, reserveAddress);

  function LiquidationLogic.HOOK_burnBadDebt_before_burnDebtTokens(address reserveAddress, uint256 amount)
    internal with (env e) => HOOK_burnBadDebt_before_burnDebtTokens_CVL(e,reserveAddress,amount);

  function LiquidationLogic.HOOK_burnBadDebt_after_burnDebtTokens(address reserveAddress)
    internal with (env e) => HOOK_burnBadDebt_after_burnDebtTokens_CVL(e,reserveAddress);
}

function HOOK_burnBadDebt_inside_loop_CVL(env e, address reserveAddress) {
  assert reserveAddress != ASSET;
}

function HOOK_burnBadDebt_before_burnDebtTokens_CVL(env e, address reserveAddress, uint256 amount) {
  INTR1_totSUP_aToken = aTokenTotalSupplyCVL(ATOKEN, e);
  INTR1_totSUP_debt   = aTokenTotalSupplyCVL(DEBT, e);
  INTR1_VB            = getReserveDataExtended(ASSET).virtualUnderlyingBalance;
  INTR1_deficit       = getReserveDataExtended(ASSET).deficit;

  assert INTR1_totSUP_aToken == ORIG_totSUP_aToken;
  assert INTR1_totSUP_debt == ORIG_totSUP_debt;
  assert INTR1_VB == ORIG_VB;
  assert INTR1_deficit == ORIG_deficit;
}

function HOOK_burnBadDebt_after_burnDebtTokens_CVL(env e, address reserveAddress) {
  INTR2_totSUP_aToken = aTokenTotalSupplyCVL(ATOKEN, e);
  INTR2_totSUP_debt   = aTokenTotalSupplyCVL(DEBT, e);
  INTR2_VB            = getReserveDataExtended(ASSET).virtualUnderlyingBalance;
  INTR2_deficit       = getReserveDataExtended(ASSET).deficit;

  assert INTR2_totSUP_aToken == INTR1_totSUP_aToken;
  assert INTR2_totSUP_debt == INTR1_totSUP_debt;
  assert INTR2_VB == INTR1_VB;
  assert INTR2_deficit == INTR1_deficit;
}


function configuration(address asset) {
  init_state();

  // Different assets have different Debt tokens.
  require forall address a1. forall address a2.
    a1!=a2 => currentContract._reserves[a1].variableDebtTokenAddress != currentContract._reserves[a2].variableDebtTokenAddress;

  ATOKEN = currentContract._reserves[asset].aTokenAddress;
  DEBT = currentContract._reserves[asset].variableDebtTokenAddress;
  tokens_addresses_limitations(ATOKEN,DEBT,asset); // this call makes (among other things ASSET==asset)

  require aTokenToUnderlying[ATOKEN]==asset; require aTokenToUnderlying[DEBT]==asset;
}




rule solvency__burnBadDebt(env e, address _asset) {
  configuration(_asset);

  DataTypes.ReserveData reserve = getReserveDataExtended(_asset);
  require reserve.lastUpdateTimestamp <= require_uint40(e.block.timestamp);

  // INDEXES REQUIREMENTS
  uint128 __liqInd_beforeS = reserve.liquidityIndex;
  uint128 __dbtInd_beforeS = reserve.variableBorrowIndex;
  uint256 __liqInd_before = getReserveNormalizedIncome(e, _asset);
  uint256 __dbtInd_before = getReserveNormalizedVariableDebt(e, _asset);
  require RAY()<=__liqInd_before && RAY()<=__dbtInd_before;
  require assert_uint128(RAY()) <= __liqInd_beforeS && assert_uint128(RAY()) <= __dbtInd_beforeS;

  ORIG_totSUP_aToken = aTokenTotalSupplyCVL(ATOKEN, e);
  ORIG_totSUP_debt   = aTokenTotalSupplyCVL(DEBT, e);
  ORIG_VB = getReserveDataExtended(_asset).virtualUnderlyingBalance;
  ORIG_deficit = getReserveDataExtended(_asset).deficit;
  
  // BASIC ASSUMPTION FOR THE RULE
  require isVirtualAccActive(reserve.configuration.data);
  require currentContract._reservesCount >= 1; // We assume that there exists at lease one asset.

  // We assume that the ASSET is NOT processed in the loop (of _burnBadDebt). The opposite is considered in the
  // file burnBadDebt-assetINloop.spec. 
  require getReservesList()[0]!=ASSET;

  //THE MAIN REQUIREMENT
  require ORIG_totSUP_aToken <= ORIG_VB + ORIG_totSUP_debt + ORIG_deficit + DELTA;
  
  //  require ORIG_totSUP_aToken <= 10^27; // Without this requirement we get a failure.
                                       // I believe it's due inaccure RAY-calculations.

  // THE FUNCTION CALL
  address user;  _burnBadDebt_WRP(e, user);

  DataTypes.ReserveData reserve2 = getReserveDataExtended(_asset);
  mathint FINAL_totSUP_aToken; FINAL_totSUP_aToken = aTokenTotalSupplyCVL(ATOKEN, e);
  mathint FINAL_totSUP_debt;   FINAL_totSUP_debt   = aTokenTotalSupplyCVL(DEBT, e);
  uint128 FINAL_VB = getReserveDataExtended(_asset).virtualUnderlyingBalance;
  uint128 FINAL_deficit = getReserveDataExtended(_asset).deficit;

  assert FINAL_totSUP_aToken==ORIG_totSUP_aToken;
  assert FINAL_totSUP_debt==ORIG_totSUP_debt;
  assert FINAL_VB==ORIG_VB;
  assert FINAL_deficit==ORIG_deficit;
    
  //THE ASSERTION
  assert
    FINAL_totSUP_aToken <= FINAL_VB + FINAL_totSUP_debt + FINAL_deficit + DELTA;
    //    + getReserveNormalizedVariableDebt(e, ASSET) / RAY();
}

