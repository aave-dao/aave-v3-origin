
// aave imports
import "../MOCKS/aToken.spec";
import "../common/AddressProvider.spec";

import "../common/optimizations.spec";
import "../common/functions.spec";
import "../common/validation_functions.spec";



/*================================================================================================
  See the README.txt file in the solvency/ directory
  ================================================================================================*/

persistent ghost bool INSIDE_liquidationCall;
persistent ghost bool INSIDE_burnBadDebt;

persistent ghost address _DBT_asset; persistent ghost address _DBT_atoken; persistent ghost address _DBT_debt;

persistent ghost address _COL_asset; persistent ghost address _COL_atoken; persistent ghost address _COL_debt;
persistent ghost uint256 _COL_liqIND {axiom _COL_liqIND >= 10^27;}
persistent ghost uint256 _COL_dbtIND {axiom _COL_dbtIND >= 10^27;}


methods {
  //TEMPORARY !!! we remove the following
  //  function LiquidationLogic._burnBadDebt(
  //  mapping(address => DataTypes.ReserveData) storage reservesData,
  //  mapping(uint256 => address) storage reservesList,
  //  DataTypes.UserConfigurationMap storage userConfig,
  //  uint256 reservesCount,
  //  address user
  //) internal => NONDET;

  function ReserveLogic.getNormalizedIncome(DataTypes.ReserveData storage reserve)
    internal returns (uint256) => _COL_liqIND;

  function ReserveLogic.getNormalizedDebt(DataTypes.ReserveData storage reserve)
    internal returns (uint256) => getNormalizedDebt_CVL();

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


function getNormalizedDebt_CVL() returns uint256 {
  if (INSIDE_liquidationCall) {
    uint256 dbt_index;
    return dbt_index;
  }
  else
    return _COL_liqIND;
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
}

/*=====================================================================================
  Rule: solvency__liquidationCall
  =====================================================================================*/
rule sanity__liquidationCall(env e) {
  INSIDE_liquidationCall = false;
  configuration();

  // THE FUNCTION CALL
  address _user; uint256 _debtToCover; bool _receiveAToken;
  INSIDE_liquidationCall = true;
  liquidationCall(e, _COL_asset, _DBT_asset, _user, _debtToCover, _receiveAToken);
  INSIDE_liquidationCall = false;

  satisfy true;
}

