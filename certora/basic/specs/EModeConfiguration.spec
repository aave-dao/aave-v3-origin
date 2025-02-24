methods {
  function setCollateral(uint256 reserveIndex,bool enabled) external envfree;
  function isCollateralAsset(uint256 reserveIndex) external returns (bool) envfree;
  function setBorrowable(uint256 reserveIndex,bool enabled) external envfree;
  function isBorrowableAsset(uint256 reserveIndex) external returns (bool) envfree;
}


/*=====================================================================================
  Rule: setCollateralIntegrity / setBorrowableIntegrity:
  We check the integrity of the functions setReserveBitmapBit (which is a setter) and 
  isReserveEnabledOnBitmap (which is a getter), simply by setting an arbitrary value to arbitrary 
  location, and then reading it using the getter.

  Note: the functions setCollateral and isCollateralAsset are envelopes to the above setter and getter
  and are implemented in the harness.

  Status: PASS
  Link: 
  =====================================================================================*/
rule setCollateralIntegrity(uint256 reserveIndex, bool collateral) {
  setCollateral(reserveIndex,collateral);
  assert isCollateralAsset(reserveIndex) == collateral;
}
rule setBorrowableIntegrity(uint256 reserveIndex, bool borrowable) {
  setBorrowable(reserveIndex,borrowable);
  assert isBorrowableAsset(reserveIndex) == borrowable;
}



/*=====================================================================================
  Rule: independencyOfCollateralSetters / independencyOfBorrowableSetters:
  We check that when calling to setReserveBitmapBit(index,val) only the value at the given
  index may be altered.

  Status: PASS
  Link: 
  =====================================================================================*/
rule independencyOfCollateralSetters(uint256 reserveIndex, bool collateral) {
  uint256 reserveIndex_other;

  bool before = isCollateralAsset(reserveIndex_other);
  setCollateral(reserveIndex,collateral);
  bool after = isCollateralAsset(reserveIndex_other);

  assert (reserveIndex != reserveIndex_other => before == after);
}
rule independencyOfBorrowableSetters(uint256 reserveIndex, bool borrowable) {
  uint256 reserveIndex_other;

  bool before = isBorrowableAsset(reserveIndex_other);
  setBorrowable(reserveIndex,borrowable);
  bool after = isBorrowableAsset(reserveIndex_other);

  assert (reserveIndex != reserveIndex_other => before == after);
}

