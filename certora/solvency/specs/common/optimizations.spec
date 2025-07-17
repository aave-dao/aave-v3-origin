

// optimizing summaries
methods {
  function ReserveLogic._accrueToTreasury(
        DataTypes.ReserveData storage reserve,
        DataTypes.ReserveCache memory reserveCache
  ) internal => _accrueToTreasuryCVL();

  function MathUtils.calculateCompoundedInterest(
    uint256 rate,uint40 lastUpdateTimestamp, uint256 currentTimestamp
  ) internal returns (uint256)=> compoundedInterestCVL(rate, lastUpdateTimestamp, currentTimestamp);

  function MathUtils.calculateLinearInterest(uint256 rate, uint40 lastUpdateTimestamp)
    internal returns (uint256) with (env e) => f_linearInterestCVL(e,rate,lastUpdateTimestamp);

  function _.calculateInterestRates(DataTypes.CalculateInterestRatesParams params) external => NONDET;

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

} // END METHODS BLOCK



persistent ghost linearInterestCVL(mathint,mathint,mathint) returns uint {
  axiom forall mathint rate. forall mathint lastUpdateTimestamp. forall mathint currentTimestamp.
    linearInterestCVL(rate, lastUpdateTimestamp, currentTimestamp) ==
    RAY() + rate * (currentTimestamp - lastUpdateTimestamp) / (365*86400);
  // the 365*86400 is SECONDS_PER_YEAR() as defined in MathUtils.
}
persistent ghost compoundedInterestCVL(mathint,mathint,mathint) returns uint {
  axiom forall mathint rate. forall mathint lastUpdateTimestamp. forall mathint currentTimestamp.
    compoundedInterestCVL(rate, lastUpdateTimestamp, currentTimestamp) >=
    linearInterestCVL(rate, lastUpdateTimestamp, currentTimestamp);
    //    RAY() + rate * (currentTimestamp - lastUpdateTimestamp) / (365*86400);
  // the 365*86400 is SECONDS_PER_YEAR() as defined in MathUtils.
}

persistent ghost address ASSET; //The asset that current rule refers to. Should be assigned from within the rule.

// The function _accrueToTreasury(...) only writes to the field accruedToTreasury.
function _accrueToTreasuryCVL() {
  havoc currentContract._reserves[ASSET].accruedToTreasury;
}

function f_linearInterestCVL(env e,uint256 rate,uint40 lastUpdateTimestamp) returns uint256 {
  return linearInterestCVL(rate,lastUpdateTimestamp, e.block.timestamp);
}
