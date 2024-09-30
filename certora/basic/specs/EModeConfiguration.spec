methods {
  function setCollateral(uint256 reserveIndex,bool enabled) external envfree;
  function isCollateralAsset(uint256 reserveIndex) external returns (bool) envfree;
  function setBorrowable(uint256 reserveIndex,bool enabled) external envfree;
  function isBorrowableAsset(uint256 reserveIndex) external returns (bool) envfree;
}


rule setCollateralIntegrity(uint256 reserveIndex, bool collateral) {
  setCollateral(reserveIndex,collateral);
  assert isCollateralAsset(reserveIndex) == collateral;
}

rule independencyOfCollateralSetters(uint256 reserveIndex, bool collateral) {
  uint256 reserveIndex_other;

  bool before = isCollateralAsset(reserveIndex_other);
  setCollateral(reserveIndex,collateral);
  bool after = isCollateralAsset(reserveIndex_other);

  assert (reserveIndex != reserveIndex_other => before == after);
}


rule setBorrowableIntegrity(uint256 reserveIndex, bool borrowable) {
  setBorrowable(reserveIndex,borrowable);
  assert isBorrowableAsset(reserveIndex) == borrowable;
}

rule independencyOfBorrowableSetters(uint256 reserveIndex, bool borrowable) {
  uint256 reserveIndex_other;

  bool before = isBorrowableAsset(reserveIndex_other);
  setBorrowable(reserveIndex,borrowable);
  bool after = isBorrowableAsset(reserveIndex_other);

  assert (reserveIndex != reserveIndex_other => before == after);
}



