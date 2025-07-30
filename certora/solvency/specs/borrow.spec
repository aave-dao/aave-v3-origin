
// aave imports
import "MOCKS/aToken.spec";
import "common/AddressProvider.spec";


import "common/optimizations.spec";
import "common/functions.spec";
import "common/validation_functions.spec";


/*================================================================================================
  See the README.txt file in the spec/ directory
  ================================================================================================*/


/*=====================================================================================
  Rule: borrow__solvency
  Status: PASS
  =====================================================================================*/
rule borrow__solvency(env e, address _asset) {
  init_state();

  address _atoken = currentContract._reserves[_asset].aTokenAddress;
  address _debt = currentContract._reserves[_asset].variableDebtTokenAddress;
  tokens_addresses_limitations(_atoken,_debt,_asset);

  require aTokenToUnderlying[_atoken]==_asset; require aTokenToUnderlying[_debt]==_asset;

  DataTypes.ReserveData reserve = getReserveDataExtended(_asset);
  require reserve.lastUpdateTimestamp <= require_uint40(e.block.timestamp);

  // INDEXES REQUIREMENTS
  uint128 __liqInd_beforeS = reserve.liquidityIndex;
  uint128 __dbtInd_beforeS = reserve.variableBorrowIndex;
  uint256 __liqInd_before = getReserveNormalizedIncome(e, _asset);
  uint256 __dbtInd_before = getReserveNormalizedVariableDebt(e, _asset);
  require RAY()<=__liqInd_before && RAY()<=__dbtInd_before;
  require RAY() <= __liqInd_beforeS && RAY() <= __dbtInd_beforeS;

  mathint __totSUP_aToken; __totSUP_aToken = aTokenTotalSupplyCVL(_atoken, e);
  mathint __totSUP_debt;   __totSUP_debt   = aTokenTotalSupplyCVL(_debt, e);
  uint128 __virtual_bal = getReserveDataExtended(_asset).virtualUnderlyingBalance;
  uint128 __deficit = getReserveDataExtended(_asset).deficit;

  //THE MAIN REQUIREMENT
  mathint CONST;
  require __totSUP_aToken <= __virtual_bal + __totSUP_debt + __deficit + CONST;

  // THE FUNCTION CALL
  uint256 _amount; uint256 _interestRateMode; address onBehalfOf; uint16 referralCode;
  borrow(e, _asset, _amount, _interestRateMode, referralCode, onBehalfOf);

  //HELPERS
  DataTypes.ReserveData reserve2 = getReserveDataExtended(_asset);
  assert reserve2.lastUpdateTimestamp == assert_uint40(e.block.timestamp);
  assert reserve2.liquidityIndex == assert_uint128(__liqInd_before);
  assert __totSUP_debt != 0 => (reserve2.variableBorrowIndex == assert_uint128(__dbtInd_before));
  assert getReserveNormalizedIncome(e, _asset) == __liqInd_before;
  assert __totSUP_debt != 0 => (getReserveNormalizedVariableDebt(e, _asset) == __dbtInd_before);


  mathint __totSUP_aToken__; __totSUP_aToken__ = aTokenTotalSupplyCVL(_atoken, e);
  mathint __totSUP_debt__;   __totSUP_debt__   = aTokenTotalSupplyCVL(_debt, e);
  uint128 __virtual_bal__ = getReserveDataExtended(_asset).virtualUnderlyingBalance;
  uint128 __deficit__ = getReserveDataExtended(_asset).deficit;


  // THE MAIN ASSERTION
  assert __totSUP_aToken__ <= __virtual_bal__ + __totSUP_debt__ + __deficit__ + CONST;
}

