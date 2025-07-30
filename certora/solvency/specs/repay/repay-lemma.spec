
// aave imports
import "../MOCKS/aToken.spec";
import "../common/AddressProvider.spec";

import "../common/optimizations.spec";
import "../common/functions.spec";
import "../common/validation_functions.spec";


/*================================================================================================
  See the top comment at the file repay-indexSUMM.spec (this directory).
  ================================================================================================*/


persistent ghost uint256 LIQUIDITY_INDEX;  persistent ghost uint256 DEBT_INDEX;
persistent ghost bool INSIDE_repay;

methods {
  function ReserveLogic.getNormalizedIncome_hook(uint256 ret_val, address aTokenAddress)
    internal => getNormalizedIncome_hook_CVL(ret_val);

  function ReserveLogic.getNormalizedDebt_hook(uint256 ret_val, address aTokenAddress)
    internal => getNormalizedDebt_hook_CVL(ret_val);
}

function getNormalizedIncome_hook_CVL(uint256 ret_val) {
  assert INSIDE_repay => ret_val == LIQUIDITY_INDEX;
}

function getNormalizedDebt_hook_CVL(uint256 ret_val) {
  assert INSIDE_repay => ret_val == DEBT_INDEX;
}



/*=====================================================================================
  Rule: repay__revertsIF_totDbtEQ0
  Details: We prove that if scaled-total-supply of variable-debt is 0, then repay reverts.
           That means that from now on we may assume that scaled-total-supply of variable-debt != 0
  Status: PASS
  =====================================================================================*/
rule repay__revertsIF_totDbtEQ0(env e, address _asset) {
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
  require interestRateMode == assert_uint256(DataTypes.InterestRateMode.VARIABLE);
  repay@withrevert(e, _asset, _amount, interestRateMode, onBehalfOf);
  assert lastReverted;
}


/*=====================================================================================
  Rule: repay__index_unchanged
  
  The rule is the following lemma (assumed in the file repay-main.spec):
  The return values of getNormalizedIncome() and getNormalizedDebt() are the same before, 
  after, and during the call to repay().

  Status: PASS
  =====================================================================================*/
rule repay__index_unchanged(env e, address _asset) {
  INSIDE_repay = false;
  init_state();

  LIQUIDITY_INDEX = getReserveNormalizedIncome(e, _asset);
  DEBT_INDEX = getReserveNormalizedVariableDebt(e, _asset);
    
  address _atoken = currentContract._reserves[_asset].aTokenAddress;
  address _debt = currentContract._reserves[_asset].variableDebtTokenAddress;
  tokens_addresses_limitations(_atoken,_debt,_asset);

  require aTokenToUnderlying[_atoken]==_asset; require aTokenToUnderlying[_debt]==_asset;

  DataTypes.ReserveData reserve = getReserveDataExtended(_asset);
  require reserve.lastUpdateTimestamp <= require_uint40(e.block.timestamp);

  // INDEXES REQUIREMENTS
  uint256 __liqInd_before = getNormalizedIncome(e, _asset);
  uint256 __dbtInd_before = getNormalizedDebt(e, _asset);
  uint128 __liqInd_beforeS = reserve.liquidityIndex;
  uint128 __dbtInd_beforeS = reserve.variableBorrowIndex;
  require RAY()<=__liqInd_before && RAY()<=__dbtInd_before;
  require RAY() <= __liqInd_beforeS && RAY() <= __dbtInd_beforeS;
  

  // BASIC ASSUMPTION FOR THE RULE
  require isVirtualAccActive(reserve.configuration.data);

  bool exists_debt = scaledTotalSupplyCVL(_debt)!=0;
  require exists_debt; // we justified it in the previous rule.

  // THE FUNCTION CALL
  uint256 _amount; uint256 interestRateMode; address onBehalfOf; uint16 referralCode;
  INSIDE_repay = true;
  repay(e, _asset, _amount, interestRateMode, onBehalfOf);
  INSIDE_repay = false;

  uint256 LIQUIDITY_INDEX_after = getReserveNormalizedIncome(e, _asset);
  assert  LIQUIDITY_INDEX_after == LIQUIDITY_INDEX;

  uint256 DEBT_INDEX_after = getReserveNormalizedVariableDebt(e, _asset);
  assert  DEBT_INDEX_after == DEBT_INDEX;
}



