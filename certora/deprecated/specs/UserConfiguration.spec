methods {
  function setBorrowing(uint256, bool) external envfree;
  function setUsingAsCollateral(uint256, bool) external envfree;
  function isUsingAsCollateralOrBorrowing(uint256) external returns bool envfree;
  function isBorrowing(uint256) external returns bool envfree;
  function isUsingAsCollateral(uint256) external returns bool envfree;
  function isUsingAsCollateralOne() external returns bool envfree;
  function isUsingAsCollateralAny() external returns bool envfree;
  function isBorrowingOne() external returns (bool) envfree;
  function isBorrowingAny() external returns bool envfree;
  function isEmpty() external returns bool envfree;
  function getIsolationModeState() external returns (bool, address, uint256) envfree;
  function getSiloedBorrowingState() external returns (bool, address) envfree;
}


// checks the integrity of set Borrowing function and correct retrieval of the corresponding getter
rule setBorrowing(uint256 reserveIndex, bool borrowing) {
  setBorrowing(reserveIndex, borrowing);
  assert isBorrowing(reserveIndex) == borrowing, "unexpected result";
}

// checks that changes made to a specific borrowing asset doesnt effect the other assets
rule setBorrowingNoChangeToOther(uint256 reserveIndex, uint256 reserveIndexOther, bool borrowing) {
  // reserveIndexOther info
  bool otherReserveBorrowingBefore =  isBorrowing(reserveIndexOther);
  bool otherReserveCollateralBefore = isUsingAsCollateral(reserveIndexOther);

  setBorrowing(reserveIndex, borrowing);

  // reserveIndex info
  bool ReserveBorrowingAfter =  isBorrowing(reserveIndex);
  // reserveIndexOther info
  bool otherReserveBorrowingAfter = isBorrowing(reserveIndexOther);
  bool otherReserveCollateralAfter = isUsingAsCollateral(reserveIndexOther);

  assert (reserveIndex != reserveIndexOther =>
    (otherReserveBorrowingAfter == otherReserveBorrowingBefore &&
      otherReserveCollateralAfter == otherReserveCollateralBefore));
}

// checks the integrity of set UsingAsCollateral function and correct retrieval of the corresponding getter
rule  setUsingAsCollateral(uint256 reserveIndex, bool usingAsCollateral) {
  setUsingAsCollateral(reserveIndex, usingAsCollateral);
  assert isUsingAsCollateral(reserveIndex) == usingAsCollateral;
}

// checks that changes made to a specific borrowing asset doesnt effect the other assets
rule setCollateralNoChangeToOther(uint256 reserveIndex, uint256 reserveIndexOther, bool usingAsCollateral) {
  // reserveIndexOther info
  bool otherReserveBorrowingBefore =  isBorrowing(reserveIndexOther);
  bool otherReserveCollateralBefore = isUsingAsCollateral(reserveIndexOther);

  setUsingAsCollateral(reserveIndex, usingAsCollateral);

  // reserveIndex info
  bool ReserveBorrowingAfter =  isBorrowing(reserveIndex);
  // reserveIndexOther info
  bool otherReserveBorrowingAfter = isBorrowing(reserveIndexOther);
  bool otherReserveCollateralAfter = isUsingAsCollateral(reserveIndexOther);

  assert (reserveIndex != reserveIndexOther =>
    (otherReserveBorrowingAfter == otherReserveBorrowingBefore &&
      otherReserveCollateralAfter == otherReserveCollateralBefore));
}

invariant isUsingAsCollateralOrBorrowing(uint256 reserveIndex )
  (isUsingAsCollateral(reserveIndex) || isBorrowing(reserveIndex)) <=>
  isUsingAsCollateralOrBorrowing(reserveIndex);

invariant integrityOfisUsingAsCollateralOne(uint256 reserveIndex, uint256 reserveIndexOther)
  isUsingAsCollateral(reserveIndex) && isUsingAsCollateralOne() =>
  !isUsingAsCollateral(reserveIndexOther) || reserveIndexOther == reserveIndex;

invariant integrityOfisUsingAsCollateralAny(uint256 reserveIndex)
  isUsingAsCollateral(reserveIndex) => isUsingAsCollateralAny();

invariant integrityOfisBorrowingOne(uint256 reserveIndex, uint256 reserveIndexOther)
  isBorrowing(reserveIndex) && isBorrowingOne() => !isBorrowing(reserveIndexOther) || reserveIndexOther == reserveIndex;

invariant integrityOfisBorrowingAny(uint256 reserveIndex)
  isBorrowing(reserveIndex) => isBorrowingAny();

invariant integrityOfEmpty(uint256 reserveIndex)
  isEmpty() => !isBorrowingAny() && !isUsingAsCollateralOrBorrowing(reserveIndex);

// if IsolationModeState is active then there must be exactly one asset register as collateral.
// note that this is a necessary requirement, but it is not sufficient.
rule integrityOfIsolationModeState() {
  bool existExactlyOneCollateral = isUsingAsCollateralOne();
  bool answer; address asset; uint256 ceiling;
  answer, asset, ceiling = getIsolationModeState();
  assert answer => existExactlyOneCollateral;
}

// if IsolationModeState is active then there must be exactly one asset register as collateral.
// note that this is a necessary requirement, but it is not sufficient.
rule integrityOfSiloedBorrowingState() {
  bool existExactlyOneBorrow = isBorrowingOne();
  bool answer; address asset;
  answer, asset = getSiloedBorrowingState();
  assert answer => existExactlyOneBorrow;
}
