// This is to be used in tandem with `PoolInstanceForAToken` and similar, 
// as we build them.
methods {
    function _.ADDRESSES_PROVIDER() external => NONDET; // expect address

    // Folding an internal function inside `getReserveNormalizedIncome`
    // So that we could summarize it in both spec and contract calls
    function _.getReserveNormalizedIncomeInt(address asset) internal with (env e) 
        => computeReserveNormalizedIncome(asset, e) expect uint256;

    function _.getReserveNormalizedIncome(address asset) external with (env e) 
        => computeReserveNormalizedIncome(asset, e) expect uint256;

    // Same trick for `getReserveNormalizedVariableDebt`
    function _.getReserveNormalizedVariableDebtInt(address asset) internal with (env e) 
        => computeReserveNormalizedVariableDebt(asset, e) expect uint256;

    function _.getReserveNormalizedVariableDebt(address asset) external with (env e) 
        => computeReserveNormalizedVariableDebt(asset, e) expect uint256;

    // these summaries require additional rules to be safe
    function _.finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromBefore,
        uint256 balanceToBefore
    ) external => NONDET; // it is actually non-view, check no interaction with tokens XXX
}

// Probably needs to model also last and current timestamps
persistent ghost mapping(address => uint256) thePoolReservedNormalizedIncome;
function computeReserveNormalizedIncome(address underlyingAsset, env e) returns uint256 {
    // xxx need to take timestamp into account
    return thePoolReservedNormalizedIncome[underlyingAsset];
}

persistent ghost mapping(address => uint256) thePoolReservedNormalizedVariableDebt;
function computeReserveNormalizedVariableDebt(address underlyingAsset, env e) returns uint256 {
    // xxx need to take timestamp into account
    return thePoolReservedNormalizedVariableDebt[underlyingAsset];
}

