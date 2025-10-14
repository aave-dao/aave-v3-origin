

// optimizing summaries
methods {
  function utils.SECONDS_PER_YEAR() external returns (uint256) envfree;

  //  function ReserveLogic.cumulateToLiquidityIndex(
  //    DataTypes.ReserveData storage reserve,
  //    uint256 totalLiquidity,
  //    uint256 amount
  //) internal returns (uint256) => cumulateToLiquidityIndexCVL();
    
  function ValidationLogic.validateLiquidationCall(
                                                   DataTypes.UserConfigurationMap storage userConfig,
                                                   DataTypes.ReserveData storage collateralReserve,
                                                   DataTypes.ReserveData storage debtReserve,
                                                   DataTypes.ValidateLiquidationCallParams memory params
  ) internal => NONDET;

  /*  function ValidationLogic.validateRepay(
                                         DataTypes.ReserveCache memory reserveCache,
                                         uint256 amountSent,
                                         DataTypes.InterestRateMode interestRateMode,
                                         address onBehalfOf,
                                         uint256 stableDebt,
                                         uint256 variableDebt
  ) internal => NONDET;
  */
  function ValidationLogic.validateWithdraw(
                                            DataTypes.ReserveCache memory reserveCache,
                                            uint256 amount,
                                            uint256 userBalance
  ) internal => NONDET;

  function ValidationLogic.validateFlashloanSimple(
                                                   DataTypes.ReserveData storage reserve,
                                                   uint256 amount
  ) internal => NONDET;

  function ValidationLogic.validateAutomaticUseAsCollateral(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ReserveConfigurationMap memory reserveConfig,
        address aTokenAddress
  ) internal returns (bool) => NONDET;

  function ReserveLogic._accrueToTreasury(
        DataTypes.ReserveData storage reserve,
        DataTypes.ReserveCache memory reserveCache
  ) internal => _accrueToTreasuryCVL();

  function MathUtils.calculateCompoundedInterest(uint256 rate,uint40 lastUpdateTimestamp, uint256 currentTimestamp)
    internal returns (uint256)=> compoundedInterestCVL(rate, lastUpdateTimestamp, currentTimestamp);

  function MathUtils.calculateLinearInterest(uint256 rate, uint40 lastUpdateTimestamp)
    internal returns (uint256) with (env e) => f_linearInterestCVL(e,rate,lastUpdateTimestamp);


    function GenericLogic._getUserDebtInBaseCurrency(
        address,
        DataTypes.ReserveData storage,
        uint256,
        uint256
    ) internal returns (uint256) => NONDET /* difficulty 106 */;
    
    function GenericLogic.calculateUserAccountData(
        mapping (address => DataTypes.ReserveData) storage,
        mapping (uint256 => address) storage,
        mapping (uint8 => DataTypes.EModeCategory) storage,
        DataTypes.CalculateUserAccountDataParams memory
    ) internal returns (uint256,uint256,uint256,uint256,uint256,bool) => NONDET /* difficulty 214 */;

    function LiquidationLogic._calculateAvailableCollateralToLiquidate(
        DataTypes.ReserveData storage,
        DataTypes.ReserveCache memory,
        address,
        address,
        uint256,
        uint256,
        uint256,
        address // IPriceOracleGetter
    ) internal returns (uint256,uint256,uint256) => NONDET /* difficulty 90 */;
    
    function ValidationLogic.validateSupply(
        DataTypes.ReserveCache memory,
        DataTypes.ReserveData storage,
        uint256,
        address
    ) internal  => NONDET /* difficulty 52 */;

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
        uint256,
        address
    ) internal returns (uint256,bool) => NONDET /* difficulty 214 */;
    
    function ValidationLogic.validateHFAndLtv(
        mapping (address => DataTypes.ReserveData) storage,
        mapping (uint256 => address) storage,
        mapping (uint8 => DataTypes.EModeCategory) storage,
        DataTypes.UserConfigurationMap memory,
        address,
        address,
        uint256,
        address,
        uint8
    ) internal  => NONDET /* difficulty 216 */;
    

    // xxxx
    // monotonically increase stuff in the reserve
    // updates lastUpdateTimestamp
    //    function ReserveLogic.updateState(
    //    DataTypes.ReserveData storage reserve,
    //    DataTypes.ReserveCache memory reserveCache
    //) internal => NONDET;

} // END METHODS BLOCK



ghost linearInterestCVL(mathint,mathint,mathint) returns uint {
  axiom forall mathint rate. forall mathint lastUpdateTimestamp. forall mathint currentTimestamp.
    to_mathint(linearInterestCVL(rate, lastUpdateTimestamp, currentTimestamp)) ==
    RAY() + rate * (currentTimestamp - lastUpdateTimestamp) / (365*86400);
  // the 365*86400 is SECONDS_PER_YEAR() as defined in MathUtils.
}
ghost compoundedInterestCVL(mathint,mathint,mathint) returns uint {
  axiom forall mathint rate. forall mathint lastUpdateTimestamp. forall mathint currentTimestamp.
    to_mathint(compoundedInterestCVL(rate, lastUpdateTimestamp, currentTimestamp)) >=
    to_mathint(linearInterestCVL(rate, lastUpdateTimestamp, currentTimestamp));
    //    RAY() + rate * (currentTimestamp - lastUpdateTimestamp) / (365*86400);
  // the 365*86400 is SECONDS_PER_YEAR() as defined in MathUtils.
}

ghost address ASSET; //The asset that current rule refers to. Should be assigned from within the rule.

// The function _accrueToTreasury(...) only writes to the field accruedToTreasury.
function _accrueToTreasuryCVL() {
  havoc currentContract._reserves[ASSET].accruedToTreasury;
}

function f_linearInterestCVL(env e,uint256 rate,uint40 lastUpdateTimestamp) returns uint256 {
  return linearInterestCVL(rate,lastUpdateTimestamp, e.block.timestamp);
}
