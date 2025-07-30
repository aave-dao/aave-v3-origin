
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
  Rule: supply__solvency

  Status: PASS
  =====================================================================================*/
rule supply__solvency(env e, address _asset) {
  init_state();

  address _atoken = currentContract._reserves[_asset].aTokenAddress;
  address _debt = currentContract._reserves[_asset].variableDebtTokenAddress;
  tokens_addresses_limitations(_atoken,_debt,_asset);

  require aTokenToUnderlying[_atoken]==_asset; require aTokenToUnderlying[_debt]==_asset;

  DataTypes.ReserveData reserve = getReserveDataExtended(_asset);
  require reserve.lastUpdateTimestamp <= require_uint40(e.block.timestamp);

  // INDEXES REQUIREMENTS
  uint256 __liqInd_before = getReserveNormalizedIncome(e, _asset);
  uint256 __dbtInd_before = getReserveNormalizedVariableDebt(e, _asset);
  require RAY()  <= __liqInd_before    && RAY()    <= __dbtInd_before   ;
  
  mathint __totSUP_aToken = aTokenTotalSupplyCVL(_atoken, e);
  mathint __totSUP_debt = aTokenTotalSupplyCVL(_debt, e);
  uint128 __virtual_bal = getReserveDataExtended(_asset).virtualUnderlyingBalance;
  uint128 __deficit = getReserveDataExtended(_asset).deficit;

  
  // THE MAIN REQUIREMENT
  mathint CONST;
  require __totSUP_aToken <= __virtual_bal + __totSUP_debt + __deficit + CONST;

  // THE FUNCTION CALL
  uint256 _amount; address onBehalfOf; uint16 referralCode;
  supply(e, _asset, _amount, onBehalfOf, referralCode);
  
  // HELPERS
  DataTypes.ReserveData reserve2 = getReserveDataExtended(_asset);
  assert reserve2.lastUpdateTimestamp == assert_uint40(e.block.timestamp);
  assert reserve2.liquidityIndex == assert_uint128(__liqInd_before);
  assert __totSUP_debt != 0 => (reserve2.variableBorrowIndex == assert_uint128(__dbtInd_before));
  assert getReserveNormalizedIncome(e, _asset) == __liqInd_before;
  assert __totSUP_debt != 0 => (getReserveNormalizedVariableDebt(e, _asset) == __dbtInd_before);
  

  mathint __totSUP_aToken__ = aTokenTotalSupplyCVL(_atoken, e);
  mathint __totSUP_debt__  = aTokenTotalSupplyCVL(_debt, e);
  uint128 __virtual_bal__ = getReserveDataExtended(_asset).virtualUnderlyingBalance;
  uint128 __deficit__ = getReserveDataExtended(_asset).deficit;
  
  //THE ASSERTION
  assert __totSUP_aToken__ <= __virtual_bal__ + __totSUP_debt__ + __deficit__ + CONST;
}
