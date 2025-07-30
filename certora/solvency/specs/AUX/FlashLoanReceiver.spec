methods {
    function _.executeOperation(
        address[] assets,
        uint256[] amounts,
        uint256[] premiums,
        address initiator,
        bytes params
    ) external => NONDET; // expect bool;

    // simple receiver
    function _.executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes params
    ) external => NONDET; // expect bool;
}