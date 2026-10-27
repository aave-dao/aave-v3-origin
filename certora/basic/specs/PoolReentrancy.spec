methods {
  // Each sub-call of a multicall is an entry point checked on its own, covered by the rules.
  function multicall(bytes[]) external returns (bytes[]) => HAVOC_ALL DELETE;
}

/// State-changing functions deliberately left without a guard. approvePositionManager and
/// renouncePositionManagerRole only write a mapping and emit; initialize runs once.
definition isUnguarded(method f) returns bool =
  f.selector == sig:approvePositionManager(address,bool).selector ||
  f.selector == sig:renouncePositionManagerRole(address).selector ||
  f.selector == sig:initialize(address).selector;

definition isHarnessHelper(method f) returns bool =
  f.selector == sig:setReentrancyGuardEntered(bool).selector ||
  f.selector == sig:updateReserveIndexes(address).selector ||
  f.selector == sig:updateReserveIndexesWithCache(address,DataTypes.ReserveCache).selector;

/// Every other state-changing Pool function is protected, so a new entry point added without a
/// guard fails protectedEntryPointsRevertWhileEntered.
definition isProtectedEntryPoint(method f) returns bool =
  f.contract == currentContract && !f.isView && !f.isPure && !isUnguarded(f) && !isHarnessHelper(f);

definition acquiresGuard(method f) returns bool =
  isProtectedEntryPoint(f) &&
  f.selector != sig:flashLoan(address,address[],uint256[],uint256[],address,bytes,uint16).selector &&
  f.selector != sig:flashLoanSimple(address,address,uint256,bytes,uint16).selector &&
  f.selector != sig:rescueTokens(address,address,uint256).selector;

persistent ghost bool sawGuardEnter;

/// Mirrors the guard slot, so the CALL hook can tell whether the lock is held.
persistent ghost bool guardHeld;

/// Ordering trackers for reentrancySafeUnderLock.
persistent ghost bool storageChanged;
persistent ghost bool unlockedCallAfterStore;
persistent ghost bool unsafeCall;

persistent ghost bool externalCall;

hook ALL_TSTORE(uint slot, uint value) {
  if (slot == 0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00) {
    guardHeld = value != 0;
    if (value != 0) {
      sawGuardEnter = true;
    }
  } else {
    storageChanged = true;
    if (unlockedCallAfterStore) {
      unsafeCall = true;
    }
  }
}

hook ALL_SSTORE(uint slot, uint value) {
  storageChanged = true;
  if (unlockedCallAfterStore) {
    unsafeCall = true;
  }
}

hook CALL(uint g, address addr, uint value, uint argsOffset, uint argsLength, uint retOffset, uint retLength) uint rc {
  externalCall = true;
  if (storageChanged && !guardHeld) {
    unlockedCallAfterStore = true;
  }
}

hook STATICCALL(uint g, address addr, uint argsOffset, uint argsLength, uint retOffset, uint retLength) uint rc {
  externalCall = true;
}

/// Every protected entry point reverts when lock is enabled
rule protectedEntryPointsRevertWhileEntered(method f) filtered { f -> isProtectedEntryPoint(f) }
{
  env e;
  calldataarg args;

  setReentrancyGuardEntered(e, true);
  f@withrevert(e, args);

  assert lastReverted;
}

/// Every locking entry point that succeeds takes the lock during the call.
/// Liquidation is checked separately, including executions that revert after acquiring it.
rule lockingEntryPointsAcquireGuard(method f)
  filtered { f -> acquiresGuard(f) &&
                  f.selector != sig:liquidationCall(address,address,address,uint256,bool).selector }
{
  env e;
  calldataarg args;

  setReentrancyGuardEntered(e, false);
  sawGuardEnter = false;
  f(e, args);

  assert sawGuardEnter;
}

/// With the guard initially free, a nonpayable liquidation call acquires it even if the
/// liquidation body later reverts. The persistent ghost retains that acquisition event.
rule lockingEntryPointsAcquireGuardLiquidationCall(
  address collateralAsset,
  address debtAsset,
  address borrower,
  uint256 debtToCover,
  bool receiveAToken
) {
  env e;

  require e.msg.value == 0, "liquidationCall is nonpayable";
  setReentrancyGuardEntered(e, false);
  sawGuardEnter = false;
  liquidationCall@withrevert(e, collateralAsset, debtAsset, borrower, debtToCover, receiveAToken);

  assert sawGuardEnter;
}

/// flashLoan, flashLoanSimple and rescueTokens never take the lock, so Pool actions stay
/// callable from inside their callbacks.
rule nonLockingEntryPointsLeaveGuardFree(method f) filtered { f -> isProtectedEntryPoint(f) && !acquiresGuard(f) }
{
  env e;
  calldataarg args;

  setReentrancyGuardEntered(e, false);
  sawGuardEnter = false;
  f@withrevert(e, args);

  assert !sawGuardEnter;
}

/// approvePositionManager succeeds while the lock is held and makes no external calls.
rule approvePositionManagerSucceedsWithoutCalls(address positionManager, bool approve)
{
  env e;

  require e.msg.value == 0, "approvePositionManager is nonpayable";
  setReentrancyGuardEntered(e, true);
  externalCall = false;
  approvePositionManager@withrevert(e, positionManager, approve);

  assert !lastReverted && !externalCall;
}

/// renouncePositionManagerRole succeeds while the lock is held and makes no external calls.
rule renouncePositionManagerRoleSucceedsWithoutCalls(address user)
{
  env e;

  require e.msg.value == 0, "renouncePositionManagerRole is nonpayable";
  setReentrancyGuardEntered(e, true);
  externalCall = false;
  renouncePositionManagerRole@withrevert(e, user);

  assert !lastReverted && !externalCall;
}

/// A state-changing call must not write storage, make an external CALL while the reentrancy
/// lock is off, and then write storage again. That middle CALL has to run with the lock held,
/// so a callback cannot act on half-updated Pool state. A staticcall does not count as the CALL.
/// FlashLoan and flashLoanSimple are excluded: their callback is meant to re-enter the Pool.
rule reentrancySafeUnderLock(method f)
  filtered { f -> !f.isView && !f.isPure && !isHarnessHelper(f) &&
                  f.selector != sig:flashLoan(address,address[],uint256[],uint256[],address,bytes,uint16).selector &&
                  f.selector != sig:flashLoanSimple(address,address,uint256,bytes,uint16).selector &&
                  /// Liquidation is checked separately by reentrancySafeUnderLockLiquidationCall.
                  f.selector != sig:liquidationCall(address,address,address,uint256,bool).selector 
            }
{
  env e;
  calldataarg args;

  setReentrancyGuardEntered(e, false);
  require !storageChanged && !unlockedCallAfterStore && !unsafeCall;
  f(e, args);

  assert !unsafeCall;
}

/// liquidationCall must not write storage, make an external CALL while the reentrancy lock is
/// off, and then write storage again.
rule reentrancySafeUnderLockLiquidationCall(address collateralAsset,address debtAsset,address borrower,uint256 debtToCover,bool receiveAToken)
{
  env e;

  setReentrancyGuardEntered(e, false);
  require !storageChanged && !unlockedCallAfterStore && !unsafeCall;
  liquidationCall@withrevert(e, collateralAsset, debtAsset, borrower, debtToCover, receiveAToken);

  assert !unsafeCall;
}
