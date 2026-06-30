import '../Utilities.sol';

contract PoolInstanceHarness is Utilities {
  uint h;

  function getReserveNormalizedIncomeInt(address asset) internal returns (uint256) {
    // should be summarized, if not, h will be nondet and other 'bad' things
    this.havocAll();
    return h;
  }

  function getReserveNormalizedIncome(address asset) external returns (uint256) {
    return getReserveNormalizedIncomeInt(asset);
  }

  function getReserveNormalizedVariableDebtInt(address asset) internal returns (uint256) {
    // should be summarized, if not, h will be nondet and other 'bad' things
    this.havocAll();
    return h;
  }

  function getReserveNormalizedVariableDebt(address asset) external returns (uint256) {
    return getReserveNormalizedVariableDebtInt(asset);
  }
}
