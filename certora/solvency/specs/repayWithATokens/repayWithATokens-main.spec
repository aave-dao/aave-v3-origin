
// aave imports
import "../MOCKS/aToken.spec";
import "../common/AddressProvider.spec";

import "../common/optimizations.spec";
import "../common/functions.spec";
import "../common/validation_functions.spec";

/*================================================================================================
  See the README.txt file in the solvency/ directory

  In order to deal with time-outs, we helped the prover by adding several "hooks" inside the function
  executeRepay. In these hooks (see their summarizations below) we added several asserts, hence 
  the prover proves them, and later uses them as requirement for later asserts.
  We run with --multi_asset_check.
  ================================================================================================*/


persistent ghost uint256 LIQUIDITY_INDEX {axiom LIQUIDITY_INDEX >= 10^27;}
persistent ghost uint256 DEBT_INDEX {axiom DEBT_INDEX >= 10^27;}


methods {
  function ValidationLogic.validateRepay(address user,
                                         DataTypes.ReserveCache memory reserveCache,
                                         uint256 amountSent,
                                         DataTypes.InterestRateMode interestRateMode,
                                         address onBehalfOf,
                                         uint256 debt
  ) internal => NONDET;

  function BorrowLogic.HOOK_repay_after_updateState(DataTypes.ReserveCache memory reserveCache)
    internal => HOOK_repay_after_updateState_CVL(reserveCache);
  
  function BorrowLogic.HOOK_repay_before_burn(DataTypes.ReserveCache memory reserveCache)
    internal with (env e) => HOOK_repay_before_burn_CVL(e, reserveCache);
  
  function BorrowLogic.HOOK_repay_after_burn(DataTypes.ReserveCache memory reserveCache, uint256 paybackAmount)
    internal with (env e) => HOOK_repay_after_burn_CVL(e, reserveCache, paybackAmount);

  function BorrowLogic.HOOK_repay_after_burn_ATOKEN(DataTypes.ReserveCache memory reserveCache)
    internal with (env e) => HOOK_repay_after_burn_ATOKEN_CVL(e, reserveCache);

  function _.havoc_all_dummy() external => HAVOC_ALL;
}


function HOOK_repay_after_updateState_CVL(DataTypes.ReserveCache res) {
  assert currentContract._reserves[ASSET].liquidityIndex == assert_uint128(LIQUIDITY_INDEX);
  assert res.nextLiquidityIndex == LIQUIDITY_INDEX;

  assert currentContract._reserves[ASSET].variableBorrowIndex == assert_uint128(DEBT_INDEX);
  assert res.nextVariableBorrowIndex == DEBT_INDEX;
}

function HOOK_repay_before_burn_CVL(env e, DataTypes.ReserveCache res) {
  assert res.nextLiquidityIndex==LIQUIDITY_INDEX;
  assert res.nextVariableBorrowIndex == DEBT_INDEX;
  assert getReserveNormalizedIncome(e, ASSET) == LIQUIDITY_INDEX;
  assert getReserveNormalizedVariableDebt(e, ASSET) == DEBT_INDEX;
  uint128 __deficit = getReserveDataExtended(ASSET).deficit;

  mathint __totSUP_aToken = aTokenTotalSupplyCVL(ATOKEN, e);
  mathint __totSUP_debt = aTokenTotalSupplyCVL(DEBT, e);

  // THE MAIN ASSERTION
  assert __totSUP_aToken <= VB + __totSUP_debt + __deficit + DELTA;
}

function HOOK_repay_after_burn_CVL(env e, DataTypes.ReserveCache res, uint256 paybackAmount) {
  assert res.nextLiquidityIndex==LIQUIDITY_INDEX;
  assert res.nextVariableBorrowIndex == DEBT_INDEX;
  assert getReserveNormalizedIncome(e, ASSET) == LIQUIDITY_INDEX;
  assert getReserveNormalizedVariableDebt(e, ASSET) == DEBT_INDEX;
  assert currentContract._reserves[ASSET].lastUpdateTimestamp == assert_uint40(e.block.timestamp);
  assert assert_uint256(currentContract._reserves[ASSET].liquidityIndex) == LIQUIDITY_INDEX;
  assert assert_uint256(currentContract._reserves[ASSET].variableBorrowIndex) == DEBT_INDEX;
  assert VB == currentContract._reserves[ASSET].virtualUnderlyingBalance;
  
  mathint __totSUP_aToken = aTokenTotalSupplyCVL(ATOKEN, e);
  mathint __totSUP_debt = aTokenTotalSupplyCVL(DEBT, e);
  uint128 __deficit = getReserveDataExtended(ASSET).deficit;

  // THE MAIN ASSERTION
  assert  __totSUP_aToken - paybackAmount <= VB + __totSUP_debt + __deficit + DELTA;
  
  uint256 scaled = totalSupplyByToken[ATOKEN]; uint256 IND = LIQUIDITY_INDEX;
  assert
    to_mathint(rayMulFloorCVL(require_uint256(scaled - rayDivCeilCVL(paybackAmount,IND)), IND) )
    <=
    rayMulFloorCVL(scaled,IND) - paybackAmount;
}

function HOOK_repay_after_burn_ATOKEN_CVL(env e, DataTypes.ReserveCache res) {
  mathint __totSUP_aToken = aTokenTotalSupplyCVL(ATOKEN, e);
  mathint __totSUP_debt = aTokenTotalSupplyCVL(DEBT, e);
  uint128 __deficit = getReserveDataExtended(ASSET).deficit;

  // THE MAIN ASSERTION
  assert  __totSUP_aToken <= VB + __totSUP_debt + __deficit + DELTA;
}

persistent ghost address ATOKEN; //The current atoken in use. Should be assigned from within the rule.
persistent ghost address DEBT; //The current debt-token in use. Should be assigned from within the rule.
persistent ghost mathint DELTA;
persistent ghost uint128 VB; // the virtual balance. should not be changed in repayWithATokens.

  


/*=====================================================================================
  Rule: repayWithATokens__solvency
  Note: We assume that the scaled-total-supply of variable-debt != 0. We justify it in the rule
        repayWithATokens__revertsIF_totDbtEQ0() (in the file repayWithATokens-lemmas.spec).

  Status: PASS
  =====================================================================================*/
rule repayWithATokens__solvency(env e, address _asset) {
  init_state();

  address _atoken = currentContract._reserves[_asset].aTokenAddress; ATOKEN = _atoken;
  address _debt = currentContract._reserves[_asset].variableDebtTokenAddress; DEBT = _debt;
  tokens_addresses_limitations(_atoken,_debt,_asset);

  require aTokenToUnderlying[_atoken]==_asset; require aTokenToUnderlying[_debt]==_asset;

  DataTypes.ReserveData reserve = getReserveDataExtended(_asset);
  require reserve.lastUpdateTimestamp <= require_uint40(e.block.timestamp);

  mathint __totSUP_aToken = aTokenTotalSupplyCVL(_atoken, e);
  mathint __totSUP_debt = aTokenTotalSupplyCVL(_debt, e);
  uint128 __virtual_bal = getReserveDataExtended(_asset).virtualUnderlyingBalance;
  uint128 __deficit = getReserveDataExtended(_asset).deficit;

  // UPDATING GHOSTS
  VB = __virtual_bal;
  LIQUIDITY_INDEX = getReserveNormalizedIncome(e, _asset);
  DEBT_INDEX = getReserveNormalizedVariableDebt(e, _asset);
  //  require RAY() <= LIQUIDITY_INDEX  &&  RAY() <= DEBT_INDEX;

  // THE MAIN REQUIREMENT
  require __totSUP_aToken <= __virtual_bal + __totSUP_debt + __deficit + DELTA;

  // PROVED ASSUMPTIONS
  bool exists_debt = scaledTotalSupplyCVL(_debt)!=0;  require exists_debt;

  // THE FUNCTION CALL
  uint256 _amount; uint256 interestRateMode; address onBehalfOf; uint16 referralCode;
  repayWithATokens(e, _asset, _amount, interestRateMode);
  
  mathint __totSUP_aToken__ = aTokenTotalSupplyCVL(_atoken, e);
  mathint __totSUP_debt__   = aTokenTotalSupplyCVL(_debt, e);
  uint128 __virtual_bal__   = getReserveDataExtended(_asset).virtualUnderlyingBalance;
  uint128 __deficit__ = getReserveDataExtended(_asset).deficit;

  assert __virtual_bal__==__virtual_bal;   // The virtual-balance stays unchanged
  // THE MAIN ASSERTION
  assert __totSUP_aToken__ <= __virtual_bal__ + __totSUP_debt__ + __deficit__ + DELTA;
}

