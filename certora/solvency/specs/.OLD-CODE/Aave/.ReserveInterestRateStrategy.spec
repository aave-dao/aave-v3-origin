methods {
  //    function _.calculateInterestRates(
  //      DataTypes.CalculateInterestRatesParams params
  //  ) external => calculateInterestRatesCVL(calledContract, params) expect (uint256, uint256, uint256); // marked view
}

ghost mapping(mathint /* liquidityDelta */ => uint256) liquidityRateModel {
    // monotone-decreasing, see [checkNextLiquidityRateChangeWhenLiquidityAddedOrTakenChangesLe]
    axiom forall mathint n. forall mathint m. n >= m => liquidityRateModel[n] <= liquidityRateModel[m];
}

function calculateInterestRatesCVL(
    address interestRateStrategy, // redundancy
    DataTypes.CalculateInterestRatesParams params
) returns (uint256, uint256, uint256) {
    uint256 liquidityRate = liquidityRateModel[params.liquidityAdded - params.liquidityTaken];
    uint256 stableBorrowRate;
    uint256 variableBorrowRate;

    require (params.usingVirtualBalance && params.totalStableDebt + params.totalVariableDebt != 0) 
        => params.liquidityTaken <= require_uint256(params.virtualUnderlyingBalance + params.liquidityAdded);

    return (liquidityRate, stableBorrowRate, variableBorrowRate);  
}
