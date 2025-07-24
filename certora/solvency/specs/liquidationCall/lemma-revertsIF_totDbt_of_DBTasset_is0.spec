
// aave imports
import "../MOCKS/aToken.spec";
import "../common/AddressProvider.spec";

import "../common/optimizations.spec";
import "../common/functions.spec";

persistent ghost address _DBT_asset; persistent ghost address _DBT_atoken; persistent ghost address _DBT_debt;

/*================================================================================================
  Summarizations
  ================================================================================================*/
methods {
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


/*================================================================================================
  Functions for summarizations
  ================================================================================================*/
function _calculateAvailableCollateralToLiquidateCVL() returns (uint256,uint256,uint256,uint256) {
  uint256 a; uint256 b; uint256 c; uint256 d;
  return (a,b,c,d);
}

// The function reduceIsolatedDebtIfIsolated(...) only writes to the field isolationModeTotalDebt.
function reduceIsolatedDebtIfIsolatedCVL() {
  address asset;
  havoc currentContract._reserves[asset].isolationModeTotalDebt;
}


methods {
  function LiquidationLogic.HOOK_liquidation_before_validateLiquidationCall(uint256 userTotalDebt)
    internal => HOOK_liquidation_before_validateLiquidationCall_CVL(userTotalDebt);
}

function HOOK_liquidation_before_validateLiquidationCall_CVL(uint256 userTotalDebt) {
  assert userTotalDebt==0;
}


function configuration() {
  init_state();
  require _DBT_asset!=0;

  require currentContract._reserves[_DBT_asset].aTokenAddress == _DBT_atoken;
  require currentContract._reserves[_DBT_asset].variableDebtTokenAddress == _DBT_debt;

  require aTokenToUnderlying[_DBT_atoken]==_DBT_asset;
  require aTokenToUnderlying[_DBT_debt]==_DBT_asset;
}




/*=====================================================================================
  Rule: liquidationCall__revertsIF_totDbt_of_DBTasset_EQ0
  Details: We prove that if scaledTotalSupplyCVL(_DBT_debt)==0, then liquidationCall reverts.
           That means that from now on we may assume that scaledTotalSupplyCVL(_DBT_debt)!=0
  Status: PASS
  =====================================================================================*/
rule liquidationCall__revertsIF_totDbt_of_DBTasset_is0(env e) {
  configuration();

  DataTypes.ReserveData reserve = getReserveDataExtended(_DBT_asset);
  require reserve.lastUpdateTimestamp <= require_uint40(e.block.timestamp);

  require scaledTotalSupplyCVL(_DBT_debt)==0;

  // This is a basic erc20 property
  address user;
  require aTokenBalanceOfCVL(_DBT_debt,user,e) <= scaledTotalSupplyCVL(_DBT_debt);

  // THE FUNCTION CALL
  uint256 debtToCover; bool receiveAToken;
  address some_COL_asset__; // Note that it may be equal to _DBT_asset
  liquidationCall@withrevert(e, some_COL_asset__, _DBT_asset, user, debtToCover, receiveAToken);

  assert lastReverted;
}
