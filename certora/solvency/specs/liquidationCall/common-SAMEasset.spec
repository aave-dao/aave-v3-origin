

//persistent ghost address ASSET;
persistent ghost address ATOKEN; persistent ghost address DEBT;


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

function tokens_addresses_limitations_DBTeqCOL() {
  require ASSET!=0;
}

function configuration_DBTeqCOL() {
  init_state();
  tokens_addresses_limitations_DBTeqCOL();

  require currentContract._reserves[ASSET].aTokenAddress == ATOKEN;
  require currentContract._reserves[ASSET].variableDebtTokenAddress == DEBT;

  require aTokenToUnderlying[ATOKEN]==ASSET; require aTokenToUnderlying[DEBT]==ASSET;

  require tokenToSort[ASSET] == VanillaERC20_token();
}
