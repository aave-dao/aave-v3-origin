import "../Math/CVLMath.spec";

// current contract is assumed to be an IReserveInterestRateStrategy
methods {
    function calculateInterestRates(
        DataTypes.CalculateInterestRatesParams params
    ) external; // view function

    // optimizations
    function _.wadToRay(uint256 a) internal => wadToRayCVL(a) expect uint256; // this is optimized well actually
    function _.rayMul(uint256 a, uint256 b) internal => rayMulCVLPrecise(a, b) expect uint256; // not optimized well by Prover
    function _.rayDiv(uint256 a, uint256 b) internal => rayDivCVLPrecise(a, b) expect uint256; // seems to be optimized well by Prover
    function _.percentMul(uint256 value, uint256 percentage) internal => percentMulPrecise(value, percentage) expect uint256; // to use require_uint256 instead of inline assembly
}

definition WAD_RAY_RATIO() returns uint256 = /* 1e9 */ 1000000000;

function wadToRayCVL(uint256 a) returns uint256 {
    return require_uint256(a * WAD_RAY_RATIO());
}


definition PERCENTAGE_FACTOR() returns uint256 = /* 1e4 */ 10000;
definition HALF_PERCENTAGE_FACTOR() returns uint256 = /* 0.5e4 */ 5000;

function percentMulPrecise(uint256 value, uint256 percentage) returns uint256 {
    return require_uint256((value*percentage + HALF_PERCENTAGE_FACTOR())/ PERCENTAGE_FACTOR());
}


rule checkCalculateInterestRatesCVLSummary {
    env e;
    DataTypes.CalculateInterestRatesParams params;
    calculateInterestRates(e, params);
    assert (params.usingVirtualBalance && params.totalStableDebt + params.totalVariableDebt != 0) 
        => params.liquidityTaken <= assert_uint256(params.virtualUnderlyingBalance + params.liquidityAdded);
}

// exploratory rule section
function checkNextLiquidityRateEffects(
    DataTypes.CalculateInterestRatesParams params1,
    DataTypes.CalculateInterestRatesParams params2
) returns (uint256, uint256) {
    env e;
    
    uint256 nextLiquidityRate1;
    uint256 nextStableRate1;
    uint256 nextVariableRate1;
    nextLiquidityRate1, nextStableRate1, nextVariableRate1 = calculateInterestRates(e, params1);
    uint256 nextLiquidityRate2;
    uint256 nextStableRate2;
    uint256 nextVariableRate2;
    nextLiquidityRate2, nextStableRate2, nextVariableRate2 = calculateInterestRates(e, params2);

    return (nextLiquidityRate1, nextLiquidityRate2);
}

function LeTotalVariableDebt(
    DataTypes.CalculateInterestRatesParams params1,
    DataTypes.CalculateInterestRatesParams params2
) {
    require 
        params1.unbacked == params2.unbacked
        && params1.liquidityAdded == params2.liquidityAdded
        && params1.liquidityTaken == params2.liquidityTaken
        && params1.totalStableDebt == params2.totalStableDebt
        && params1.totalVariableDebt <= params2.totalVariableDebt
        && params1.averageStableBorrowRate == params2.averageStableBorrowRate
        && params1.reserveFactor == params2.reserveFactor
        && params1.reserve == params2.reserve
        && params1.usingVirtualBalance == params2.usingVirtualBalance
        && params1.virtualUnderlyingBalance == params2.virtualUnderlyingBalance
    ;
}

function GeTotalVariableDebt(
    DataTypes.CalculateInterestRatesParams params1,
    DataTypes.CalculateInterestRatesParams params2
) {
    require 
        params1.unbacked == params2.unbacked
        && params1.liquidityAdded == params2.liquidityAdded
        && params1.liquidityTaken == params2.liquidityTaken
        && params1.totalStableDebt == params2.totalStableDebt
        && params1.totalVariableDebt >= params2.totalVariableDebt
        && params1.averageStableBorrowRate == params2.averageStableBorrowRate
        && params1.reserveFactor == params2.reserveFactor
        && params1.reserve == params2.reserve
        && params1.usingVirtualBalance == params2.usingVirtualBalance
        && params1.virtualUnderlyingBalance == params2.virtualUnderlyingBalance
    ; 
}

function GeLiquidity(
    DataTypes.CalculateInterestRatesParams params1,
    DataTypes.CalculateInterestRatesParams params2
) {
    // if liquidity added is increased and liquidity taken is decreased then there's _more_ available liquidity
    // which decreases the borrow rate, thus decreasing the liquidity rate
    require 
        params1.unbacked == params2.unbacked
        && params1.liquidityAdded >= params2.liquidityAdded
        && params1.liquidityTaken <= params2.liquidityTaken
        && params1.totalStableDebt == params2.totalStableDebt
        && params1.totalVariableDebt == params2.totalVariableDebt
        && params1.averageStableBorrowRate == params2.averageStableBorrowRate
        && params1.reserveFactor == params2.reserveFactor
        && params1.reserve == params2.reserve
        && params1.usingVirtualBalance == params2.usingVirtualBalance
        && params1.virtualUnderlyingBalance == params2.virtualUnderlyingBalance
    ;
}

// wrong
rule checkNextLiquidityRateChangeWhenTotalVariableDebtDecreasesGe() {
    DataTypes.CalculateInterestRatesParams params1;
    DataTypes.CalculateInterestRatesParams params2;
    LeTotalVariableDebt(params1, params2);
    uint256 nextLiquidityRate1;
    uint256 nextLiquidityRate2;
    (nextLiquidityRate1, nextLiquidityRate2) = checkNextLiquidityRateEffects(params1, params2);
    assert nextLiquidityRate1 >= nextLiquidityRate2, "params1 resulted in >= nextLiquidityRate";
}

// wrong
rule checkNextLiquidityRateChangeWhenTotalVariableDebtDecreasesLe() {
    DataTypes.CalculateInterestRatesParams params1;
    DataTypes.CalculateInterestRatesParams params2;
    LeTotalVariableDebt(params1, params2);
    uint256 nextLiquidityRate1;
    uint256 nextLiquidityRate2;
    (nextLiquidityRate1, nextLiquidityRate2) = checkNextLiquidityRateEffects(params1, params2);
    assert nextLiquidityRate1 <= nextLiquidityRate2, "params1 resulted in >= nextLiquidityRate";
}

// wrong
rule checkNextLiquidityRateChangeWhenTotalVariableDebtDecreasesEq() {
    DataTypes.CalculateInterestRatesParams params1;
    DataTypes.CalculateInterestRatesParams params2;
    LeTotalVariableDebt(params1, params2);
    uint256 nextLiquidityRate1;
    uint256 nextLiquidityRate2;
    (nextLiquidityRate1, nextLiquidityRate2) = checkNextLiquidityRateEffects(params1, params2);
    assert nextLiquidityRate1 == nextLiquidityRate2, "params1 resulted in >= nextLiquidityRate";
}

// wrong
rule checkNextLiquidityRateChangeWhenTotalVariableDebtIncreasesGe() {
    DataTypes.CalculateInterestRatesParams params1;
    DataTypes.CalculateInterestRatesParams params2;
    GeTotalVariableDebt(params1, params2);
    uint256 nextLiquidityRate1;
    uint256 nextLiquidityRate2;
    (nextLiquidityRate1, nextLiquidityRate2) = checkNextLiquidityRateEffects(params1, params2);
    assert nextLiquidityRate1 >= nextLiquidityRate2, "params1 resulted in >= nextLiquidityRate";
}

// wrong
rule checkNextLiquidityRateChangeWhenTotalVariableDebtIncreasesLe() {
    DataTypes.CalculateInterestRatesParams params1;
    DataTypes.CalculateInterestRatesParams params2;
    GeTotalVariableDebt(params1, params2);
    uint256 nextLiquidityRate1;
    uint256 nextLiquidityRate2;
    (nextLiquidityRate1, nextLiquidityRate2) = checkNextLiquidityRateEffects(params1, params2);
    assert nextLiquidityRate1 <= nextLiquidityRate2, "params1 resulted in <= nextLiquidityRate";
}

// wrong
rule checkNextLiquidityRateChangeWhenLiquidityAddedOrTakenChangesGe() {
    DataTypes.CalculateInterestRatesParams params1;
    DataTypes.CalculateInterestRatesParams params2;
    GeLiquidity(params1, params2);
    uint256 nextLiquidityRate1;
    uint256 nextLiquidityRate2;
    (nextLiquidityRate1, nextLiquidityRate2) = checkNextLiquidityRateEffects(params1, params2);
    assert nextLiquidityRate1 >= nextLiquidityRate2, "params1 resulted in >= nextLiquidityRate";
}

// see [GeLiquidity] - I'd expect this to be true - liquidity increased in params1 -> nextLiquidityRate1 is smaller
rule checkNextLiquidityRateChangeWhenLiquidityAddedOrTakenChangesLe() {
    DataTypes.CalculateInterestRatesParams params1;
    DataTypes.CalculateInterestRatesParams params2;
    GeLiquidity(params1, params2);
    uint256 nextLiquidityRate1;
    uint256 nextLiquidityRate2;
    (nextLiquidityRate1, nextLiquidityRate2) = checkNextLiquidityRateEffects(params1, params2);
    assert nextLiquidityRate1 <= nextLiquidityRate2, "params1 resulted in <= nextLiquidityRate";
}

// wrong
rule checkNextLiquidityRateChangeWhenLiquidityAddedOrTakenChangesEq() {
    DataTypes.CalculateInterestRatesParams params1;
    DataTypes.CalculateInterestRatesParams params2;
    GeLiquidity(params1, params2);
    uint256 nextLiquidityRate1;
    uint256 nextLiquidityRate2;
    (nextLiquidityRate1, nextLiquidityRate2) = checkNextLiquidityRateEffects(params1, params2);
    assert nextLiquidityRate1 == nextLiquidityRate2, "params1 resulted in == nextLiquidityRate";
}

// sanity
//use builtin rule sanity filtered { f -> f.contract == currentContract }






// wrong
rule checkNextLiquidityRateChangeWhenTotalVariableDebtIncreasesEq() {
    DataTypes.CalculateInterestRatesParams params1;
    DataTypes.CalculateInterestRatesParams params2;
    GeTotalVariableDebt(params1, params2);
    uint256 nextLiquidityRate1;
    uint256 nextLiquidityRate2;
    (nextLiquidityRate1, nextLiquidityRate2) = checkNextLiquidityRateEffects(params1, params2);
    assert nextLiquidityRate1 >= nextLiquidityRate2, "params1 resulted in == nextLiquidityRate";
}



rule borrowRate_GEQ_liquidityRate(env e) {
  DataTypes.CalculateInterestRatesParams params;

  require params.totalStableDebt == 0;
  require params.averageStableBorrowRate == 0;
  //  require params.unbacked==0;
  //  require params.totalVariableDebt == 1;
  //require params.virtualUnderlyingBalance == 1;
  require params.reserveFactor == 500; // 5%
  
  uint256 liquidity_rate;
  uint256 nextStableRate1;
  uint256 variable_rate;
  liquidity_rate, nextStableRate1, variable_rate = calculateInterestRates(e, params);

  //  require get___vars_availableLiquidityPlusDebt() > 1;

  assert liquidity_rate <= variable_rate;
}


rule _getOverallBorrowRate_with_0_stable(env e) {
  //  uint256 totalStableDebt;
  uint256 _totalVariableDebt;
  uint256 _currentVariableBorrowRate;
  uint256 _currentAverageStableBorrowRate;

  require 10^23 <= _currentVariableBorrowRate && _currentVariableBorrowRate <= 10^27;
  require _totalVariableDebt * 10^9 >= 10^27 / 2;

  uint256 _ret_val = _getOverallBorrowRate(e,
                                          0, // no stable debt
                                          _totalVariableDebt,
                                          _currentVariableBorrowRate,
                                          _currentAverageStableBorrowRate);

  assert _ret_val == _currentVariableBorrowRate;

}



/*
0x27abba297a2388bdb0599e976abf
0x27abba297a2389cfe04891b00000
*/
