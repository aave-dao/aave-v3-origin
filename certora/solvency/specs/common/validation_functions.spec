


// The validtion function are usually summarized to NONDET
methods {
    function ValidationLogic.validateLiquidationCall(
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ReserveData storage collateralReserve,
        DataTypes.ReserveData storage debtReserve,
        DataTypes.ValidateLiquidationCallParams memory params
    ) internal => NONDET;

  function ValidationLogic.validateWithdraw(
      DataTypes.ReserveCache memory reserveCache,
      uint256 amount,
      uint256 userBalance
  ) internal => NONDET;
  
  function ValidationLogic.validateAutomaticUseAsCollateral(
    address sender,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    DataTypes.UserConfigurationMap storage userConfig,
    DataTypes.ReserveConfigurationMap memory reserveConfig,
    address aTokenAddress
  ) internal returns (bool) => NONDET;
   
  function ValidationLogic.validateSupply(
    DataTypes.ReserveCache memory,
    DataTypes.ReserveData storage,
    uint256,
    address
  ) internal  => NONDET;

  
  function ValidationLogic.validateBorrow(
    mapping (address => DataTypes.ReserveData) storage reservesData,
    mapping (uint256 => address) storage reservesList,
    mapping (uint8 => DataTypes.EModeCategory) storage eModeCategories,
    DataTypes.ValidateBorrowParams memory params
  ) internal => NONDET;
  /* difficulty 331 ; */

  function ValidationLogic.validateHealthFactor(
    mapping (address => DataTypes.ReserveData) storage,
    mapping (uint256 => address) storage,
    mapping (uint8 => DataTypes.EModeCategory) storage,
    DataTypes.UserConfigurationMap memory,
    address,
    uint8,
    address
  ) internal returns (uint256,bool) => NONDET /* difficulty 214 */;
    
  function ValidationLogic.validateHFAndLtv(
    mapping (address => DataTypes.ReserveData) storage,
    mapping (uint256 => address) storage,
    mapping (uint8 => DataTypes.EModeCategory) storage,
    DataTypes.UserConfigurationMap memory,
    address,
    uint8,
    address
  ) internal  => NONDET /* difficulty 216 */;

  function ValidationLogic.validateHFAndLtvzero(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    mapping(uint8 => DataTypes.EModeCategory) storage eModeCategories,
    DataTypes.UserConfigurationMap memory userConfig,
    address asset,
    address from,
    address oracle,
    uint8 userEModeCategory
  ) internal => NONDET;

}
