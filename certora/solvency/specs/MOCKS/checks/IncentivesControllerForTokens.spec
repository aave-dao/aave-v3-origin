methods {
    // these summaries require additional rules to be safe
    function _.handleAction(address user, uint256 totalSupply, uint256 userBalance) external => NONDET; // it is actually non-view, check no interaction with tokens XXX
}