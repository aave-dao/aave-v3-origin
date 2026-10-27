methods {
  function getReserveAToken(address) external returns (address) envfree;
}

definition isProtectedEntryPoint(method f) returns bool =
  f.contract == currentContract &&
  (f.selector == sig:supply(address,uint256,address,uint16).selector ||
   f.selector == sig:supplyWithPermit(address,uint256,address,uint16,uint256,uint8,bytes32,bytes32).selector ||
   f.selector == sig:deposit(address,uint256,address,uint16).selector ||
   f.selector == sig:withdraw(address,uint256,address).selector ||
   f.selector == sig:borrow(address,uint256,uint256,uint16,address).selector ||
   f.selector == sig:repay(address,uint256,uint256,address).selector ||
   f.selector == sig:repayWithPermit(address,uint256,uint256,address,uint256,uint8,bytes32,bytes32).selector ||
   f.selector == sig:repayWithATokens(address,uint256,uint256).selector ||
   f.selector == sig:setUserUseReserveAsCollateral(address,bool).selector ||
   f.selector == sig:setUserEMode(uint8).selector ||
   f.selector == sig:liquidationCall(address,address,address,uint256,bool).selector ||
   f.selector == sig:mintToTreasury(address[]).selector ||
   f.selector == sig:initReserve(address,address,address).selector ||
   f.selector == sig:syncIndexesState(address).selector ||
   f.selector == sig:syncRatesState(address).selector ||
   f.selector == sig:setConfiguration(address,DataTypes.ReserveConfigurationMap).selector ||
   f.selector == sig:updateFlashloanPremium(uint128).selector ||
   f.selector == sig:configureEModeCategory(uint8,DataTypes.EModeCategoryBaseConfiguration).selector ||
   f.selector == sig:configureEModeCategoryCollateralBitmap(uint8,uint128).selector ||
   f.selector == sig:configureEModeCategoryBorrowableBitmap(uint8,uint128).selector ||
   f.selector == sig:configureEModeCategoryLtvzeroBitmap(uint8,uint128).selector ||
   f.selector == sig:configureEModeCategoryIsolated(uint8,bool).selector ||
   f.selector == sig:setLiquidationGracePeriod(address,uint40).selector ||
   f.selector == sig:rescueTokens(address,address,uint256).selector ||
   f.selector == sig:flashLoan(address,address[],uint256[],uint256[],address,bytes,uint16).selector ||
   f.selector == sig:flashLoanSimple(address,address,uint256,bytes,uint16).selector ||
   f.selector == sig:setUserUseReserveAsCollateralOnBehalfOf(address,bool,address).selector ||
   f.selector == sig:setUserEModeOnBehalfOf(uint8,address).selector ||
   f.selector == sig:finalizeTransfer(address,address,address,uint256,uint256).selector ||
   f.selector == sig:eliminateReserveDeficit(address,uint256).selector);

definition acquiresGuard(method f) returns bool =
  isProtectedEntryPoint(f) &&
  f.selector != sig:flashLoan(address,address[],uint256[],uint256[],address,bytes,uint16).selector &&
  f.selector != sig:flashLoanSimple(address,address,uint256,bytes,uint16).selector &&
  f.selector != sig:rescueTokens(address,address,uint256).selector;

definition mayRevertInGuardAcquisitionRule(method f) returns bool =
  f.contract == currentContract &&
  (f.selector == sig:liquidationCall(address,address,address,uint256,bool).selector ||
   f.selector == sig:mintToTreasury(address[]).selector ||
   f.selector == sig:initReserve(address,address,address).selector ||
   f.selector == sig:syncIndexesState(address).selector ||
   f.selector == sig:syncRatesState(address).selector ||
   f.selector == sig:setConfiguration(address,DataTypes.ReserveConfigurationMap).selector ||
   f.selector == sig:updateFlashloanPremium(uint128).selector ||
   f.selector == sig:configureEModeCategory(uint8,DataTypes.EModeCategoryBaseConfiguration).selector ||
   f.selector == sig:configureEModeCategoryCollateralBitmap(uint8,uint128).selector ||
   f.selector == sig:configureEModeCategoryBorrowableBitmap(uint8,uint128).selector ||
   f.selector == sig:configureEModeCategoryLtvzeroBitmap(uint8,uint128).selector ||
   f.selector == sig:configureEModeCategoryIsolated(uint8,bool).selector ||
   f.selector == sig:setLiquidationGracePeriod(address,uint40).selector ||
   f.selector == sig:finalizeTransfer(address,address,address,uint256,uint256).selector ||
   f.selector == sig:eliminateReserveDeficit(address,uint256).selector);

persistent ghost bool sawGuardEnter;

hook ALL_TSTORE(uint slot, uint value) {
  if (
    slot == 0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00 &&
    value != 0
  ) {
    sawGuardEnter = true;
  }
}

rule protectedEntryPointsRevertWhileEntered(method f)
  filtered { f -> isProtectedEntryPoint(f) }
{
  env e;
  calldataarg args;

  setReentrancyGuardEntered(e, true);
  f@withrevert(e, args);

  assert lastReverted;
}

/// flashLoan, flashLoanSimple and rescueTokens check the lock without taking it, so a Pool action
/// stays reachable from inside their callbacks. Nothing else pins that they leave it free.
rule nonLockingEntryPointsLeaveGuardFree(method f)
  filtered { f -> isProtectedEntryPoint(f) && !acquiresGuard(f) }
{
  env e;
  calldataarg args;

  require e.msg.value == 0;
  setReentrancyGuardEntered(e, false);
  sawGuardEnter = false;
  f@withrevert(e, args);

  assert !sawGuardEnter;
}

rule lockingEntryPointsAcquireGuard(method f)
  filtered { f -> acquiresGuard(f) }
{
  env e;
  calldataarg args;

  require e.msg.value == 0;
  setReentrancyGuardEntered(e, false);
  sawGuardEnter = false;
  f@withrevert(e, args);

  if (!mayRevertInGuardAcquisitionRule(f)) {
    require !lastReverted;
  }
  assert lastReverted || sawGuardEnter;
}


/// The generic rules above call finalizeTransfer with an arbitrary sender, which reverts on the
/// CallerNotAToken check before ever reaching the guard. These call it as the aToken.
///
/// Asserting only `lastReverted` here would be worthless: from an unconstrained state the body
/// reverts for many reasons other than the guard, so such a rule passes with the guard removed.
/// The property is therefore differential. Whenever the call would go through with the guard
/// clear, the very same state must revert with the guard entered.
rule finalizeTransferBlockedByGuard(
  env e,
  address asset,
  address from,
  address to,
  uint256 scaledAmount,
  uint256 scaledBalanceFromBefore
) {
  address aToken = getReserveAToken(asset);
  require aToken != 0;
  require e.msg.sender == aToken;
  require e.msg.value == 0;

  storage init = lastStorage;

  setReentrancyGuardEntered(e, false);
  finalizeTransfer@withrevert(e, asset, from, to, scaledAmount, scaledBalanceFromBefore);
  bool revertedWithGuardClear = lastReverted;

  setReentrancyGuardEntered(e, true) at init;
  finalizeTransfer@withrevert(e, asset, from, to, scaledAmount, scaledBalanceFromBefore);
  bool revertedWithGuardEntered = lastReverted;

  assert !revertedWithGuardClear => revertedWithGuardEntered;
}

/// Establishes that the implication above is not vacuous, and that the guard has not bricked
/// ordinary aToken transfers: a state exists where finalizeTransfer goes through.
rule finalizeTransferReachableWithGuardClear(
  env e,
  address asset,
  address from,
  address to,
  uint256 scaledAmount,
  uint256 scaledBalanceFromBefore
) {
  address aToken = getReserveAToken(asset);
  require aToken != 0;
  require e.msg.sender == aToken;
  require e.msg.value == 0;

  setReentrancyGuardEntered(e, false);
  finalizeTransfer@withrevert(e, asset, from, to, scaledAmount, scaledBalanceFromBefore);

  satisfy !lastReverted;
}
