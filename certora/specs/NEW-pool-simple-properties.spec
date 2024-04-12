import "NEW-pool-base.spec";

methods {
  function _._getUserDebtInBaseCurrency(address user, DataTypes.ReserveData storage reserve, uint256 assetPrice, uint256 assetUnit) internal => NONDET;

  function _.rayMul(uint256 a, uint256 b) internal => mulDivDownAbstractPlus(a, b, 10^27) expect uint256 ALL;
  function _.rayDiv(uint256 a, uint256 b) internal => mulDivDownAbstractPlus(a, 10^27, b) expect uint256 ALL;
}

ghost mapping(uint256 => mapping(uint256 => uint256)) rayMulSummariztionValues;
ghost mapping(uint256 => mapping(uint256 => uint256)) rayDivSummariztionValues;

function rayMulSummariztion(uint256 x, uint256 y) returns uint256 {
  if ((x == 0) || (y == 0)) {
    return 0;
  }
  if (x == RAY()) {
    return y;
  }
  if (y == RAY()) {
    return x;
  }

  if (y > x) {
    if (y > RAY()) {
      require rayMulSummariztionValues[y][x] >= x;
    }
    if (x > RAY()) {
      require rayMulSummariztionValues[y][x] >= y;
    }
    return rayMulSummariztionValues[y][x];
  }
  else {
    if (x > RAY()) {
      require rayMulSummariztionValues[x][y] >= y;
    }
    if (y > RAY()) {
      require rayMulSummariztionValues[x][y] >= x;
    }
    return rayMulSummariztionValues[x][y];
  }
}

function rayDivSummariztion(uint256 x, uint256 y) returns uint256 {
  if (x == 0) {
    return 0;
  }
  if (y == RAY()) {
    return x;
  }
  if (y == x) {
    return RAY();
  }
  require y > RAY() => rayDivSummariztionValues[x][y] <= x;
  require y < RAY() => x <= rayDivSummariztionValues[x][y];
  return rayDivSummariztionValues[x][y];
}

// Passing for PoolHarness:
// https://prover.certora.com/output/40577/e75bfa369a10490ca0cc71992984dc54/?anonymousKey=c12450d39df13d66fd92b82819c9dcc7f66d2012
rule method_reachability(env e, method f) {
  calldataarg args;
  f(e, args);
  satisfy true;
}

// @title It is impossible to deposit an inactive reserve
// Proved:
// https://prover.certora.com/output/40577/b8bd6244053e42e4bddb129f04e1dd93/?anonymousKey=5374001e512e1149d120f0efa19c18a3d531d115
// Note, that getFlags must not be NONDET.
rule cannotDepositInInactiveReserve(env e) {
  address asset;
  uint256 amount;
  address onBehalfOf;
  uint16 referralCode;
  bool reserveIsActive = isActiveReserve(e, asset);

  deposit(e, asset, amount, onBehalfOf, referralCode);

  assert reserveIsActive;
}

// @title It is impossible to deposit a frozen reserve
// Proved:
// https://prover.certora.com/output/40577/d4f2bfae10ae4092bb7dab309e72b166/?anonymousKey=a370279a63e87a810fd79cb20d33ef00aead7c2b
// Note, that getFlags must not be NONDET.
rule cannotDepositInFrozenReserve(env e) {
  address asset;
  uint256 amount;
  address onBehalfOf;
  uint16 referralCode;
  bool reserveIsFrozen = isFrozenReserve(e, asset);

  deposit(e, asset, amount, onBehalfOf, referralCode);

  assert !reserveIsFrozen;
}

// @title It is impossible to deposit zero amount
// Proved
// https://prover.certora.com/output/40577/400f77e9ca1948b9896ca35435b0ea03/?anonymousKey=760e8acd1473e9eb801aa4bcaf60d50927f9f026
rule cannotDepositZeroAmount(env e) {
  address asset;
  uint256 amount;
  address onBehalfOf;
  uint16 referralCode;

  deposit(e, asset, amount, onBehalfOf, referralCode);

  assert amount != 0;
}

// @title It is impossible to withdraw zero amount
// Proved
// https://prover.certora.com/output/40577/869e48220a2d40369884dd6a0cbd1734/?anonymousKey=7cf6aced7660c59314f767f4f14de508e38a37ea
rule cannotWithdrawZeroAmount(env e) {
  address asset;
  uint256 amount;
  address to;
  uint16 referralCode;

  withdraw(e, asset, amount, to);

  assert amount != 0;
}

// @title It is impossible to withdraw an inactive reserve
// Proved
// https://prover.certora.com/output/40577/a4eb1d4472ae43c2a1bfe202f070453a/?anonymousKey=05c0ddc494d371d6a28fc40ed4cc1902bba29eba
// Note, that getFlags must not be NONDET.
rule cannotWithdrawFromInactiveReserve(env e) {
  address asset;
  uint256 amount;
  address to;
  uint16 referralCode;
  bool reserveIsActive = isActiveReserve(e, asset);

  withdraw(e, asset, amount, to);

  assert reserveIsActive;
}

// @title It is impossible to borrow zero amount
// Proved
// https://prover.certora.com/output/40577/13a0a08cbc6f448888bcdb28716d856b/?anonymousKey=48621623ac7255815e8a6465d72d38f39d55f0f4
rule cannotBorrowZeroAmount(env e) {
  address asset;
  uint256 amount;
  uint256 interestRateMode;
  uint16 referralCode;
  address onBehalfOf;

  borrow(e, asset, amount, interestRateMode, referralCode, onBehalfOf);

  assert amount != 0;
}

// @title It is impossible to borrow on inactive reserve.
// Proved
// https://prover.certora.com/output/40577/2e93cd5ce80f4aa491b9d648e1a73583/?anonymousKey=64bbd85099c3ae4a387bd0a24ce565c23094ee4f
// Note, that getFlags must not be NONDET.
rule cannotBorrowOnInactiveReserve(env e) {
  address asset;
  uint256 amount;
  uint256 interestRateMode;
  uint16 referralCode;
  address onBehalfOf;
  bool reserveIsActive = isActiveReserve(e, asset);

  borrow(e, asset, amount, interestRateMode, referralCode, onBehalfOf);

  assert reserveIsActive;
}

// It is impossible to borrow on a reserve, that is disabled for borrowing.
// Proved
// https://prover.certora.com/output/40577/1b50faf4cbb3459c9563e4af75658525/?anonymousKey=e04b8838d1f6eceb3fb29504969ecf0817269679
// Note, that getFlags must not be NONDET.
rule cannotBorrowOnReserveDisabledForBorrowing(env e) {
  address asset;
  uint256 amount;
  uint256 interestRateMode;
  uint16 referralCode;
  address onBehalfOf;
  bool reserveIsEnabledForBorrow = isEnabledForBorrow(e, asset);

  borrow(e, asset, amount, interestRateMode, referralCode, onBehalfOf);

  assert reserveIsEnabledForBorrow;
}

// @title It is impossible to borrow on frozen reserve.
// Proved
// https://prover.certora.com/output/40577/b25ecb5e5b804832b3aa75e3bd54079c/?anonymousKey=8029d9f6ac5edf386f4795c4de0e7928f0487722
// Note, that getFlags must not be NONDET.
rule cannotBorrowOnFrozenReserve(env e) {
  address asset;
  uint256 amount;
  uint256 interestRateMode;
  uint16 referralCode;
  address onBehalfOf;
  bool reserveIsFrozen = isFrozenReserve(e, asset);

  borrow(e, asset, amount, interestRateMode, referralCode, onBehalfOf);

  assert !reserveIsFrozen;
}
