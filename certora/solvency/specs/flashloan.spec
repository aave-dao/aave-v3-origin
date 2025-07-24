
// aave imports
import "MOCKS/aToken.spec";
import "common/AddressProvider.spec";
import "AUX/FlashLoanReceiver.spec";

import "common/optimizations.spec";
import "common/functions.spec";
import "common/validation_functions.spec";

/*================================================================================================
  See the README.txt file in the spec/ directory.
  ================================================================================================*/

methods {
  function ValidationLogic.validateFlashloanSimple(
                                                   DataTypes.ReserveData storage reserve,
                                                   uint256 amount
  ) internal => validateFlashloanSimpleCVL(amount);
}

ghost mathint TOT_SUP_ATOKEN;

function validateFlashloanSimpleCVL(uint256 amount) {
  require amount <= TOT_SUP_ATOKEN;
}


/*=====================================================================================
  Rule: flashLoanSimple__solvency

  Status: PASS
  =====================================================================================*/
rule flashLoanSimple__solvency(env e, address _asset) {
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
  require __liqInd_before >= RAY() && __dbtInd_before >= RAY();

  mathint __totSUP_aToken = aTokenTotalSupplyCVL(_atoken, e);  TOT_SUP_ATOKEN = __totSUP_aToken;
  mathint __totSUP_debt;  __totSUP_debt = aTokenTotalSupplyCVL(_debt, e);
  uint128 __virtual_bal = getReserveDataExtended(_asset).virtualUnderlyingBalance;
  uint128 __deficit = getReserveDataExtended(_asset).deficit;

  // THE MAIN REQUIREMENT
  mathint DELTA;
  require __totSUP_aToken <= __virtual_bal + __totSUP_debt + __deficit + DELTA;

  // THE FUNCTION CALL
  address receiverAddress; uint256 _amount; bytes params; uint16 referralCode; 
  flashLoanSimple(e, receiverAddress, _asset, _amount, params, referralCode);

  mathint __totSUP_aToken__ = aTokenTotalSupplyCVL(_atoken, e);
  mathint __totSUP_debt__ = aTokenTotalSupplyCVL(_debt, e);
  uint128 __virtual_bal__ = getReserveDataExtended(_asset).virtualUnderlyingBalance;
  uint128 __deficit__ = getReserveDataExtended(_asset).deficit;
  
  //THE ASSERTION
  assert __totSUP_aToken__ <= __virtual_bal__ + __totSUP_debt__ + __deficit__ + DELTA;
}

