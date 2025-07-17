
// aave imports
import "../MOCKS/aToken.spec";
import "../common/AddressProvider.spec";

import "../common/optimizations.spec";
import "../common/functions.spec";
import "../common/validation_functions.spec";


/*================================================================================================
  See the README.txt file in the solvency/ directory.

  We summarize the functions getNormalizedIncome() and getNormalizedDebt() to return some constant
  value. We justify it by proving the rule repay__index_unchanged() in the file repay-lemma.spec.
  ================================================================================================*/

methods {
  function ValidationLogic.validateRepay(
                                         address user,
                                         DataTypes.ReserveCache memory reserveCache,
                                         uint256 amountSent,
                                         DataTypes.InterestRateMode interestRateMode,
                                         address onBehalfOf,
                                         uint256 debt
  ) internal => NONDET;

  function ReserveLogic.getNormalizedIncome(DataTypes.ReserveData storage reserve)
    internal returns (uint256) => LIQUIDITY_INDEX;

  function ReserveLogic.getNormalizedDebt(DataTypes.ReserveData storage reserve)
    internal returns (uint256) => DEBT_INDEX;
}

persistent ghost uint256 LIQUIDITY_INDEX {axiom LIQUIDITY_INDEX >= 10^27;}
persistent ghost uint256 DEBT_INDEX {axiom DEBT_INDEX >= 10^27;}


/*=====================================================================================
  Rule: repay__solvency
  Status: PASS

  Note: We assume that the scaled-total-supply of variable-debt != 0. We justify it in the rule
        repay__revertsIF_totDbtEQ0() (in the file repay-lemma.spec).
  =====================================================================================*/
rule repay__solvency(env e, address _asset) {
  init_state();

  address _atoken = currentContract._reserves[_asset].aTokenAddress;
  address _debt = currentContract._reserves[_asset].variableDebtTokenAddress;
  tokens_addresses_limitations(_atoken,_debt,_asset);

  require aTokenToUnderlying[_atoken]==_asset; require aTokenToUnderlying[_debt]==_asset;

  DataTypes.ReserveData reserve = getReserveDataExtended(_asset);
  require reserve.lastUpdateTimestamp <= require_uint40(e.block.timestamp);
  
  mathint __totSUP_aToken; __totSUP_aToken = aTokenTotalSupplyCVL(_atoken, e);
  mathint __totSUP_debt;  __totSUP_debt = aTokenTotalSupplyCVL(_debt, e);
  uint128 __virtual_bal = getReserveDataExtended(_asset).virtualUnderlyingBalance;
  uint128 __deficit = getReserveDataExtended(_asset).deficit;

  // BASIC ASSUMPTION FOR THE RULE
  require isVirtualAccActive(reserve.configuration.data);

  // THE MAIN REQUIREMENT
  mathint CONST;
  require __totSUP_aToken <= __virtual_bal + __totSUP_debt + __deficit + CONST;

  bool exists_debt = scaledTotalSupplyCVL(_debt)!=0;
  require exists_debt;

  // THE FUNCTION CALL
  uint256 _amount; uint256 interestRateMode; address onBehalfOf; uint16 referralCode;
  repay(e, _asset, _amount, interestRateMode, onBehalfOf);

  
  DataTypes.ReserveData reserve2 = getReserveDataExtended(_asset);
  assert reserve2.lastUpdateTimestamp == assert_uint40(e.block.timestamp);
  require assert_uint256(reserve2.liquidityIndex) == LIQUIDITY_INDEX;
  require assert_uint256(reserve2.variableBorrowIndex) == DEBT_INDEX;
  
  mathint __totSUP_aToken__; __totSUP_aToken__ = aTokenTotalSupplyCVL(_atoken, e);
  mathint __totSUP_debt__;   __totSUP_debt__   = aTokenTotalSupplyCVL(_debt, e);
  uint128 __virtual_bal__ = getReserveDataExtended(_asset).virtualUnderlyingBalance;
  uint128 __deficit__ = getReserveDataExtended(_asset).deficit;
  
  //THE ASSERTION
  assert __totSUP_aToken__ <= __virtual_bal__ + __totSUP_debt__ + __deficit__ + CONST;
}

