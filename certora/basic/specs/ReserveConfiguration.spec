methods {
  function setLtv(uint256) external envfree;
  function getLtv() external returns (uint256) envfree;
  function setLiquidationThreshold(uint256) external envfree;
  function getLiquidationThreshold() external returns (uint256) envfree;
  function setLiquidationBonus(uint256) external envfree;
  function getLiquidationBonus() external returns (uint256) envfree;
  function setDecimals(uint256) external envfree;
  function getDecimals() external returns (uint256) envfree;
  function setActive(bool) external envfree;
  function getActive() external returns (bool) envfree;
  function setFrozen(bool) external envfree;
  function getFrozen() external returns (bool) envfree;
  function setPaused(bool) external envfree;
  function getPaused() external returns (bool) envfree;
  function setBorrowableInIsolation(bool) external envfree;
  function getBorrowableInIsolation() external returns (bool) envfree;
  function setSiloedBorrowing(bool) external envfree;
  function getSiloedBorrowing() external returns (bool) envfree;
  function setBorrowingEnabled(bool) external envfree;
  function getBorrowingEnabled() external returns (bool) envfree;
  function setReserveFactor(uint256) external envfree;
  function getReserveFactor() external returns (uint256) envfree;
  function setBorrowCap(uint256) external envfree;
  function getBorrowCap() external returns (uint256) envfree;
  function setSupplyCap(uint256) external envfree;
  function getSupplyCap() external returns (uint256) envfree;
  function setDebtCeiling(uint256) external envfree;
  function getDebtCeiling() external returns (uint256) envfree;
  function setLiquidationProtocolFee(uint256) external envfree;
  function getLiquidationProtocolFee() external returns (uint256) envfree;
  function setUnbackedMintCap(uint256) external envfree;
  function getUnbackedMintCap() external returns (uint256) envfree;
  //  function setEModeCategory(uint256) external envfree;
  //  function getEModeCategory() external returns (uint256) envfree;
  function setFlashLoanEnabled(bool) external envfree;
  function getFlashLoanEnabled() external returns (bool) envfree;
  function getData() external returns uint256 envfree;
  function executeIntSetterById(uint256, uint256) external envfree;
  function executeIntGetterById(uint256) external returns uint256 envfree;
  function executeBoolSetterById(uint256, bool) external envfree;
  function executeBoolGetterById(uint256) external returns bool envfree;
}

// checks the integrity of set LTV function and correct retrieval of the corresponding getter.
rule setLtvIntegrity(uint256 ltv) {
  setLtv(ltv);
  assert getLtv() == ltv;
}

// checks the integrity of set LiquidationThreshold function and correct retrieval of the corresponding getter.
rule setLiquidationThresholdIntegrity(uint256 threshold) {
  setLiquidationThreshold(threshold);
  assert getLiquidationThreshold() == threshold;
}

// checks the integrity of set LiquidationBonus function and correct retrieval of the corresponding getter.
rule setLiquidationBonusIntegrity(uint256 bonus) {
  setLiquidationBonus(bonus);
  assert getLiquidationBonus() == bonus;
}

// checks the integrity of set Decimals function and correct retrieval of the corresponding getter.
rule setDecimalsIntegrity(uint256 decimals) {
  setDecimals(decimals);
  assert getDecimals() == decimals;
}

// checks the integrity of set Active function and correct retrieval of the corresponding getter.
rule setActiveIntegrity(bool active) {
  setActive(active);
  assert getActive() == active;
}

// checks the integrity of set Frozen function and correct retrieval of the corresponding getter.
rule setFrozenIntegrity(bool frozen) {
  setFrozen(frozen);
  assert getFrozen() == frozen;
}

// checks the integrity of set Paused function and correct retrieval of the corresponding getter.
rule setPausedIntegrity(bool paused) {
  setPaused(paused);
  assert getPaused() == paused;
}

// checks the integrity of set BorrowableInIsolation function and correct retrieval of the corresponding getter.
rule setBorrowableInIsolationIntegrity(bool borrowable) {
  setBorrowableInIsolation(borrowable);
  assert getBorrowableInIsolation() == borrowable;
}

// checks the integrity of set SiloedBorrowing function and correct retrieval of the corresponding getter.
rule setSiloedBorrowingIntegrity(bool siloed) {
  setSiloedBorrowing(siloed);
  assert getSiloedBorrowing() == siloed;
}

// checks the integrity of set BorrowingEnabled function and correct retrieval of the corresponding getter.
rule setBorrowingEnabledIntegrity(bool enabled) {
  setBorrowingEnabled(enabled);
  assert getBorrowingEnabled() == enabled;
}

// checks the integrity of set ReserveFactor function and correct retrieval of the corresponding getter.
rule setReserveFactorIntegrity(uint256 reserveFactor) {
  setReserveFactor(reserveFactor);
  assert getReserveFactor() == reserveFactor;
}

// checks the integrity of set BorrowCap function and correct retrieval of the corresponding getter.
rule setBorrowCapIntegrity(uint256 borrowCap) {
  setBorrowCap(borrowCap);
  assert getBorrowCap() == borrowCap;
}

// checks the integrity of set SupplyCap function and correct retrieval of the corresponding getter.
rule setSupplyCapIntegrity(uint256 supplyCap) {
  setSupplyCap(supplyCap);
  assert getSupplyCap() == supplyCap;
}

// checks the integrity of set DebtCeiling function and correct retrieval of the corresponding getter.
rule setDebtCeilingIntegrity(uint256 ceiling) {
  setDebtCeiling(ceiling);
  assert getDebtCeiling() == ceiling;
}

// checks the integrity of set LiquidationProtocolFee function and correct retrieval of the corresponding getter.
rule setLiquidationProtocolFeeIntegrity(uint256 liquidationProtocolFee) {
  setLiquidationProtocolFee(liquidationProtocolFee);
  assert getLiquidationProtocolFee() == liquidationProtocolFee;
}

// checks the integrity of set UnbackedMintCap function and correct retrieval of the corresponding getter.
rule setUnbackedMintCapIntegrity(uint256 unbackedMintCap) {
  setUnbackedMintCap(unbackedMintCap);
  assert getUnbackedMintCap() == unbackedMintCap;
}

// checks the integrity of set EModeCategory function and correct retrieval of the corresponding getter.
//rule setEModeCategoryIntegrity(uint256 category) {
//  setEModeCategory(category);
//  assert getEModeCategory() == category;
//}

// checks for independence of int parameters - if one parameter is being set, non of the others is being changed
rule integrityAndIndependencyOfIntSetters(uint256 funcId, uint256 otherFuncId, uint256 val) {
  require 0 <= funcId && funcId <= 9;
  require 0 <= otherFuncId && otherFuncId <= 9;
  uint256 valueBefore = executeIntGetterById(funcId);
  uint256 otherValueBefore = executeIntGetterById(otherFuncId);

  executeIntSetterById(funcId, val);

  uint256 valueAfter = executeIntGetterById(funcId);
  uint256 otherValueAfter = executeIntGetterById(otherFuncId);

  assert valueAfter == val;
  assert (otherFuncId != funcId => otherValueAfter == otherValueBefore);
}

// checks for independence of bool parameters - if one parameter is being set, non of the others is being changed
rule integrityAndIndependencyOfBoolSetters(uint256 funcId, uint256 otherFuncId, bool val) {
  require 0 <= funcId && funcId <= 10;
  require 0 <= otherFuncId && otherFuncId <= 10;
  bool valueBefore = executeBoolGetterById(funcId);
  bool otherValueBefore = executeBoolGetterById(otherFuncId);

  executeBoolSetterById(funcId, val);

  bool valueAfter = executeBoolGetterById(funcId);
  bool otherValueAfter = executeBoolGetterById(otherFuncId);

  assert valueAfter == val;
  assert (otherFuncId != funcId => otherValueAfter == otherValueBefore);
}
