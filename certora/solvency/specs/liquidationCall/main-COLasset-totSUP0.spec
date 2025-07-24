
// aave imports
import "../MOCKS/aToken.spec";
import "../common/AddressProvider.spec";

import "../common/optimizations.spec";
import "../common/functions.spec";
import "../common/validation_functions.spec";


/*================================================================================================
  Assumptions for this spec file:
  1. Debt asset != Collateral asset.
  2a. scaledTotalSupplyCVL(_DBT_debt)!=0  
      [See lemma-revertsIF_totDbt_of_DBTasset_is0.spec for justifications.]
  2b. scaledTotalSupplyCVL(_COL_debt)==0  
      [In main-COLasset.spec we prove the solvency for the case scaledTotalSupplyCVL(_COL_debt)!=0.]
  3. We summarize ReserveLogic.getNormalizedDebt(...), and ReserveLogic.getNormalizedIncome(...) to
     CVL functions. We justify it in the file lemma-COLasset-totSUP0.spec.


  See also the README.txt files in the spec/ and spec/liquidationCall/ directories
  ================================================================================================*/

methods {
  function ReserveLogic.getNormalizedIncome(DataTypes.ReserveData storage reserve)
    internal returns (uint256) => _COL_liqIND;

  function LiquidationLogic.HOOK_liquidation_after_burnCollateralATokens(uint256 actualCollateralToLiquidate)
    internal => HOOK_liquidation_after_burnCollateralATokens_CVL();


  function IsolationModeLogic.reduceIsolatedDebtIfIsolated(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    DataTypes.UserConfigurationMap storage userConfig,
    DataTypes.ReserveCache memory reserveCache,
    uint256 repayAmount
  ) internal => reduceIsolatedDebtIfIsolatedCVL();

  function LiquidationLogic._calculateAvailableCollateralToLiquidate(
    DataTypes.ReserveConfigurationMap memory collateralReserveConfiguration,
    uint256 collateralAssetPrice,
    uint256 collateralAssetUnit,
    uint256 debtAssetPrice,
    uint256 debtAssetUnit,
    uint256 debtToCover,
    uint256 userCollateralBalance,
    uint256 liquidationBonus
  ) internal returns (uint256,uint256,uint256,uint256) =>
    _calculateAvailableCollateralToLiquidateCVL();
}

// This is immediately after the call to updateState for the COL token
function HOOK_liquidation_after_burnCollateralATokens_CVL() {
  require currentContract._reserves[_COL_asset].liquidityIndex == _COL_liqIND;
}

function _calculateAvailableCollateralToLiquidateCVL() returns (uint256,uint256,uint256,uint256) {
  uint256 a; uint256 b; uint256 c; uint256 d; // require c==0;
  return (a,b,c,d);
}

// The function reduceIsolatedDebtIfIsolated(...) only writes to the field isolationModeTotalDebt.
function reduceIsolatedDebtIfIsolatedCVL() {
  address asset;
  havoc currentContract._reserves[asset].isolationModeTotalDebt;
}


persistent ghost bool INSIDE_liquidationCall;

persistent ghost address _DBT_asset; persistent ghost address _DBT_atoken; persistent ghost address _DBT_debt;
persistent ghost uint256 _DBT_liqIND;
persistent ghost uint256 _DBT_dbtIND;

persistent ghost address _COL_asset; persistent ghost address _COL_atoken; persistent ghost address _COL_debt;
persistent ghost uint256 _COL_liqIND {axiom _COL_liqIND >= 10^27;}
persistent ghost uint256 _COL_dbtIND;



function tokens_addresses_limitations_LQD(address asset, address atoken, address debt,
                                          address asset2, address atoken2, address debt2
                                         ) {
  require asset==100;  require atoken==10;  require debt==11; 
  require asset2==200; require atoken2==20; require debt2==21; 
}


function configuration() {
  init_state();

  _DBT_atoken = currentContract._reserves[_DBT_asset].aTokenAddress;
  _COL_atoken = currentContract._reserves[_COL_asset].aTokenAddress;            
  _DBT_debt = currentContract._reserves[_DBT_asset].variableDebtTokenAddress;
  _COL_debt = currentContract._reserves[_COL_asset].variableDebtTokenAddress;
  tokens_addresses_limitations_LQD(_DBT_asset, _DBT_atoken, _DBT_debt,
                                   _COL_asset, _COL_atoken, _COL_debt);

  require aTokenToUnderlying[_DBT_atoken]==_DBT_asset; require aTokenToUnderlying[_DBT_debt]==_DBT_asset;
  require aTokenToUnderlying[_COL_atoken]==_COL_asset; require aTokenToUnderlying[_COL_debt]==_COL_asset;

  require tokenToSort[_DBT_asset] == VanillaERC20_token();
  require tokenToSort[_COL_asset] == VanillaERC20_token();
}



/*=====================================================================================
  Rule: solvency__liquidationCall_totDebt_of_COLasset_EQ_0  
  =====================================================================================*/
rule solvency__liquidationCall_totDebt_of_COLasset_EQ_0(env e) {
  INSIDE_liquidationCall = false;
  configuration();

  DataTypes.ReserveData reserve = getReserveDataExtended(_COL_asset);
  require reserve.lastUpdateTimestamp <= require_uint40(e.block.timestamp);

  mathint __totSUP_aToken = aTokenTotalSupplyCVL(_COL_atoken, e);
  mathint __totSUP_debt = aTokenTotalSupplyCVL(_COL_debt, e);
  uint128 __virtual_bal = getReserveDataExtended(_COL_asset).virtualUnderlyingBalance;

  // BASIC ASSUMPTION FOR THE RULE
  require isVirtualAccActive(reserve.configuration.data);
  require scaledTotalSupplyCVL(_COL_debt)==0;

  // THE MAIN REQUIREMENT
  mathint DELTA;
  require __totSUP_aToken <= __virtual_bal + DELTA;

  assert __totSUP_debt==0;

  // THE FUNCTION CALL
  require _COL_asset != _DBT_asset;
  address _user; uint256 _debtToCover; bool _receiveAToken;
  INSIDE_liquidationCall = true;
  liquidationCall(e, _COL_asset, _DBT_asset, _user, _debtToCover, _receiveAToken);
  INSIDE_liquidationCall = false;

  DataTypes.ReserveData reserve2 = getReserveDataExtended(_COL_asset);

  mathint __totSUP_aToken__ = aTokenTotalSupplyCVL(_COL_atoken, e);
  mathint __totSUP_debt__   = aTokenTotalSupplyCVL(_COL_debt, e);
  uint128 __virtual_bal__ = getReserveDataExtended(_COL_asset).virtualUnderlyingBalance;

  assert __totSUP_debt__==0;
  
  //THE ASSERTION
  assert __totSUP_aToken__ <= __virtual_bal__ + DELTA;
}






