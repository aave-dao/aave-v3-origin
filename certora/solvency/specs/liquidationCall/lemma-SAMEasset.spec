
// aave imports
import "../MOCKS/aToken.spec";
import "../common/AddressProvider.spec";

import "../common/optimizations.spec";
import "../common/functions.spec";
import "../common/validation_functions.spec";
import "common-SAMEasset.spec";



persistent ghost bool INSIDE_liquidationCall;
persistent ghost bool INSIDE_burnBadDebt;

persistent ghost uint256 LIQUIDITY_INDEX; persistent ghost uint256 DEBT_INDEX;



/*================================================================================================
  Summarizations of HOOKS function 
  ================================================================================================*/
methods {
  function ReserveLogic.getNormalizedIncome_hook(uint256 ret_val, address aTokenAddress)
    internal => getNormalizedIncome_hook_CVL(ret_val, aTokenAddress);

  function ReserveLogic.getNormalizedDebt_hook(uint256 ret_val, address aTokenAddress)
    internal => getNormalizedDebt_hook_CVL(ret_val, aTokenAddress);

  function LiquidationLogic.HOOK_liquidation_after_updateState_DBT()
    internal => HOOK_liquidation_after_updateState_DBT_CVL();

  function LiquidationLogic.HOOK_liquidation_before_burnBadDebt()
    internal with (env e) => HOOK_liquidation_before_burnBadDebt_CVL(e);

  function LiquidationLogic.HOOK_liquidation_after_burnBadDebt()
    internal with (env e) => HOOK_liquidation_after_burnBadDebt_CVL(e);
}


function getNormalizedIncome_hook_CVL(uint256 ret_val, address aTokenAddress) {}

function getNormalizedDebt_hook_CVL(uint256 ret_val, address aTokenAddress) {
  assert (INSIDE_liquidationCall && !INSIDE_burnBadDebt) => aTokenAddress==ATOKEN;
  assert (INSIDE_liquidationCall && !INSIDE_burnBadDebt) => ret_val==DEBT_INDEX;
}


// This is immediately after the call to updateState for the DBT token
function HOOK_liquidation_after_updateState_DBT_CVL() {
  assert currentContract._reserves[ASSET].liquidityIndex == LIQUIDITY_INDEX;
  assert currentContract._reserves[ASSET].variableBorrowIndex == DEBT_INDEX;
}

function HOOK_liquidation_before_burnBadDebt_CVL(env e) {INSIDE_burnBadDebt = true;}
function HOOK_liquidation_after_burnBadDebt_CVL(env e) {INSIDE_burnBadDebt = false;}



/*=====================================================================================
  Rule: liquidationCall__index_unchanged

  Details: The rule is the following lemma (assumed in the file DBTasset-main.spec):
  The return values of getNormalizedIncome() and getNormalizedDebt() are the same before, 
  after, and during the call to liquidationCall().

  Status: PASS
  =====================================================================================*/
rule liquidationCall__index_unchanged(env e) {
  INSIDE_liquidationCall = false;
  INSIDE_burnBadDebt = false;
  configuration_DBTeqCOL();
 
  LIQUIDITY_INDEX = getReserveNormalizedIncome(e, ASSET);
  DEBT_INDEX = getReserveNormalizedVariableDebt(e, ASSET);

  DataTypes.ReserveData reserve = getReserveDataExtended(ASSET);
  require reserve.lastUpdateTimestamp <= require_uint40(e.block.timestamp);

  // BASIC ASSUMPTION FOR THE RULE
  require scaledTotalSupplyCVL(DEBT)!=0;

  // THE FUNCTION CALL
  address user; uint256 debtToCover; bool receiveAToken;

  INSIDE_liquidationCall = true;
  liquidationCall(e, ASSET /*==COL_asset*/, ASSET, user, debtToCover, receiveAToken);
  INSIDE_liquidationCall = false;

  uint256 _LIQUIDITY_INDEX_after = getReserveNormalizedIncome(e, ASSET);
  assert  _LIQUIDITY_INDEX_after == LIQUIDITY_INDEX;

  uint256 _DEBT_INDEX_after = getReserveNormalizedVariableDebt(e, ASSET);
  assert  _DEBT_INDEX_after == DEBT_INDEX;
}
