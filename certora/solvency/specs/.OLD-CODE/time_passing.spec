
// aave imports
import "MOCKS/aToken.spec";
import "common/AddressProvider.spec";


import "common/optimizations.spec";
import "common/functions.spec";
import "common/validation_functions.spec";






/*=====================================================================================
  Rule: solvency__time_passing

  Status:
  1. Currently , in order to avoid time-out the are too many restrictions (see under 
     "// RESTRICTIONS" below.
  2. There is a big assumption that is not proved. See under "// ASSMPTION" and the explanation
     above it.
  =====================================================================================*/
rule solvency__time_passing(env e1, env e2, address _asset) {
  init_state();
  require require_uint40(e1.block.timestamp) <= require_uint40(e2.block.timestamp);

  address _atoken = currentContract._reserves[_asset].aTokenAddress;
  address _debt = currentContract._reserves[_asset].variableDebtTokenAddress;
  address _stb = currentContract._reserves[_asset].stableDebtTokenAddress;
  //tokens_addresses_limitations(_atoken,_debt,_stb,_asset);
  require _atoken==10; require _debt==11; require _stb==12; require _asset==100;
  //  require weth!=10 && weth!=11 && weth!=12;
  ASSET = _asset;

  require forall address a. balanceByToken[_debt][a] <= totalSupplyByToken[_debt];
  require forall address a. balanceByToken[_atoken][a] <= totalSupplyByToken[_atoken];
  require aTokenToUnderlying[_atoken]==_asset; require aTokenToUnderlying[_debt]==_asset; require aTokenToUnderlying[_stb]==_asset;

  DataTypes.ReserveData reserve1 = getReserveDataExtended(_asset);
  require reserve1.lastUpdateTimestamp == require_uint40(e1.block.timestamp);

  // INDEXES REQUIREMENTS
  uint128 __liqInd_beforeS = reserve1.liquidityIndex;
  uint128 __dbtInd_beforeS = reserve1.variableBorrowIndex;
  require 10^27<=__liqInd_beforeS && 10^27<=__dbtInd_beforeS;
  // the following 3 line are redundant because we assume lastUpdateTimestamp == e1.block.timestamp, but hopfully
  // it helps the prover.
  uint256 __liqInd_before = getReserveNormalizedIncome(e1, _asset);
  uint256 __dbtInd_before = getReserveNormalizedVariableDebt(e1, _asset);
  require RAY()<=__liqInd_before && RAY()<=__dbtInd_before;
  
  // BASIC ASSUMPTION FOR THE RULE
  require scaledTotalSupplyCVL(_stb)==0;

  uint256 __totSUP_aToken; __totSUP_aToken = aTokenTotalSupplyCVL(_atoken, e1);
  uint256 __totSUP_debt;   __totSUP_debt = aTokenTotalSupplyCVL(_debt, e1);
  //  uint256 supply_usage_ratio = rayDivCVLPrecise(__totSUP_debt,__totSUP_aToken);
  
  // Here we need to require some property about the relation between the liq-rate and borrow-rate.
  // The property should follow from the function DefaultReserveInterestRateStrategyV2.calculateInterestRates
  // and it should be something like liq-rate <= borrow-rate * supply-usage-ratio
  // where supply-usage-ratio is total-debt / (VB + total-debt + unbacked)
  //  require reserve1.currentLiquidityRate <= reserve1.currentVariableBorrowRate;
  //  require assert_uint256(reserve1.currentLiquidityRate) <= rayMulCVLPrecise(reserve1.currentVariableBorrowRate, supply_usage_ratio);

  // ASSUMPTION
  require rayMulCVLPrecise(reserve1.currentLiquidityRate, __totSUP_aToken) <=
    rayMulCVLPrecise(reserve1.currentVariableBorrowRate, __totSUP_debt);
  

  uint128 __virtual_bal = getReserveDataExtended(_asset).virtualUnderlyingBalance;

  //THE MAIN REQUIREMENT
  mathint CONST;
  //  require __totSUP_aToken <= __virtual_bal + __totSUP_debt + CONST;
  require __totSUP_aToken <= __totSUP_debt;


  // RESTRICTIONS
  require __totSUP_aToken <= 10^27;
  require __totSUP_debt <= 10^27;
  require e1.block.timestamp==0;
  require e2.block.timestamp==365*86400;

  //  require __liqInd_before ==10^27  &&  __dbtInd_before == 10^27;
  require reserve1.liquidityIndex == 10^27  &&  reserve1.variableBorrowIndex==10^27;
  //require reserve1.currentLiquidityRate == reserve1.currentVariableBorrowRate;
  //require reserve1.currentLiquidityRate == 10^27;
  require totalSupplyCVL(_debt)==0;


  // FUNCTION CALL: NONE !!!

  
  DataTypes.ReserveData reserve2 = getReserveDataExtended(_asset);
  uint256 __liqInd_after = getReserveNormalizedIncome(e2, _asset);
  uint256 __dbtInd_after = getReserveNormalizedVariableDebt(e2, _asset);


  mathint __totSUP_aToken__ = aTokenTotalSupplyCVL(_atoken, e2);
  mathint __totSUP_debt__   = aTokenTotalSupplyCVL(_debt, e2);
  uint128 __virtual_bal__ = getReserveDataExtended(_asset).virtualUnderlyingBalance;

  assert __virtual_bal__ == __virtual_bal;

  //THE ASSERTION
  //assert __totSUP_aToken__ <= __virtual_bal__ + __totSUP_debt__ + CONST
  assert __totSUP_aToken__ <= __totSUP_debt__
    /* + some rounding error */;
}




