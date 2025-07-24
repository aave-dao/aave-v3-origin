

persistent ghost address _DBT_asset; persistent ghost address _DBT_atoken; persistent ghost address _DBT_debt;
persistent ghost address _COL_asset; persistent ghost address _COL_atoken; persistent ghost address _COL_debt;


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



/*================================================================================================
  General Function
  ================================================================================================*/
function tokens_addresses_limitations_LQD() {
  //  _DBT_asset=100;  _DBT_atoken=10;  _DBT_debt=11; 
  // _COL_asset=200;  _COL_atoken=20;  _COL_debt=21;

  require _DBT_asset!=0;   require _COL_asset!=0;
  
  require _DBT_asset  != _COL_asset;
  require _DBT_atoken != _COL_atoken;
  require _DBT_debt   != _COL_debt;
}

function configuration() {
  init_state();
  tokens_addresses_limitations_LQD();

  require currentContract._reserves[_DBT_asset].aTokenAddress == _DBT_atoken;
  require currentContract._reserves[_COL_asset].aTokenAddress == _COL_atoken;
  require currentContract._reserves[_DBT_asset].variableDebtTokenAddress == _DBT_debt;
  require currentContract._reserves[_COL_asset].variableDebtTokenAddress == _COL_debt;

  require aTokenToUnderlying[_DBT_atoken]==_DBT_asset; require aTokenToUnderlying[_DBT_debt]==_DBT_asset;
  require aTokenToUnderlying[_COL_atoken]==_COL_asset; require aTokenToUnderlying[_COL_debt]==_COL_asset;

  require tokenToSort[_DBT_asset] == VanillaERC20_token();
  require tokenToSort[_COL_asset] == VanillaERC20_token();
}

/*
function tokens_addresses_limitations_DBTeqCOL() {
  //  _DBT_asset=100;  _DBT_atoken=10;  _DBT_debt=11; 
  // _COL_asset=200;  _COL_atoken=20;  _COL_debt=21;

  require _DBT_asset!=0;
  require _DBT_asset  == _COL_asset;
}

function configuration_DBTeqCOL() {
  init_state();
  tokens_addresses_limitations_DBTeqCOL();

  require currentContract._reserves[_DBT_asset].aTokenAddress == _DBT_atoken;
  require currentContract._reserves[_DBT_asset].variableDebtTokenAddress == _DBT_debt;

  require aTokenToUnderlying[_DBT_atoken]==_DBT_asset; require aTokenToUnderlying[_DBT_debt]==_DBT_asset;
}
*/
