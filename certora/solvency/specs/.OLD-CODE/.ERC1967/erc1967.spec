methods {
    // avoids linking messages upon upgradeToAndCall
    function _._upgradeToAndCall(address,bytes memory,bool) internal => NONDET;
    function _._upgradeToAndCallUUPS(address,bytes memory,bool) internal => NONDET;
    // view function
    function _.proxiableUUID() external => NONDET; // expect bytes32
}