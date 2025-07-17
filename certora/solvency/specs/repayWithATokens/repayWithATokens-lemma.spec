
// aave imports
import "../MOCKS/aToken.spec";
import "../common/AddressProvider.spec";

import "../common/optimizations.spec";
import "../common/functions.spec";
import "../common/validation_functions.spec";


/*=====================================================================================
  Rule: repayWithATokens__revertsIF_totDbtEQ0
  Details: We prove that if scaled-total-supply of the variable-debt is 0, then repayWithATokens reverts.
           That means that from now on we may assume that scaled-total-supply of variable-debt != 0

  Status: PASS
  =====================================================================================*/
rule repayWithATokens__revertsIF_totDbtEQ0(env e, address _asset) {
  init_state();

  address _atoken = currentContract._reserves[_asset].aTokenAddress;
  address _debt = currentContract._reserves[_asset].variableDebtTokenAddress;
  tokens_addresses_limitations(_atoken,_debt,_asset);

  require aTokenToUnderlying[_atoken]==_asset; require aTokenToUnderlying[_debt]==_asset;
  require forall address a. balanceByToken[_debt][a] <= totalSupplyByToken[_debt];
  bool exists_debt = scaledTotalSupplyCVL(_debt)!=0;
  require !exists_debt;  
  
  // THE FUNCTION CALL
  uint256 _amount; uint256 interestRateMode; address onBehalfOf; uint16 referralCode;
  assert balanceByToken[_debt][onBehalfOf]==0; // This should help the prover
  repayWithATokens@withrevert(e, _asset, _amount, interestRateMode);
  assert lastReverted;
}


