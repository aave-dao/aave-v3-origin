methods {
  function _.getMarketId() external => NONDET; // expect string;
  function _.getAddress(bytes32 id) external => NONDET; // expect address;
  function _.getPool() external => NONDET; // expect address;
  function _.getPoolConfigurator() external => NONDET; // expect address;
  function _.getPriceOracle() external => NONDET; // expect address;
  function _.getACLManager() external => NONDET; // expect address;
  function _.getACLAdmin() external => NONDET; // expect address;
  function _.getPriceOracleSentinel() external => NONDET; // expect address;
  function _.getPoolDataProvider() external => NONDET; // expect address;
}