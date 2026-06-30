methods {
    function _.isPoolAdmin(address admin) external => NONDET; // expect bool;
    function _.isEmergencyAdmin(address admin) external => NONDET; // expect bool;
    function _.isRiskAdmin(address admin) external => NONDET; // expect bool;
    function _.isFlashBorrower(address borrower) external => NONDET; // expect bool;
    function _.isBridge(address bridge) external => NONDET; // expect bool;
    function _.isAssetListingAdmin(address admin) external => NONDET; // expect bool;

    function _.hasRole(bytes32 role, address account) external => NONDET; // expect bool;
}