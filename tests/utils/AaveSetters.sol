// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import {Vm} from 'forge-std/Vm.sol';

/**
 * Helper library to set Aave state variables directly in storage
 * Notice: These methods currently only set the relevant storage for their exact purpose.
 *         They do not set all the storage slots that would be set by the actual Aave contracts.
 */
library AaveSetters {
  Vm private constant vm = Vm(address(uint160(uint256(keccak256('hevm cheat code')))));

  function setLiquidityIndex(address pool, address reserve, uint256 index) internal {
    uint256 reserveSlot = uint256(keccak256(abi.encode(reserve, 52))) + 1;
    uint256 currentValue = uint256(vm.load(pool, bytes32(reserveSlot)));
    uint128 existingRate = uint128(currentValue >> 128);
    bytes32 newPackedValue = bytes32(
      (uint256(existingRate) << 128) | uint256(index) // Keep upper 128 bits // Overwrite lower 128 bits
    );
    vm.store(pool, bytes32(reserveSlot), newPackedValue);
  }

  function setVariableBorrowIndex(address pool, address reserve, uint256 index) internal {
    uint256 reserveSlot = uint256(keccak256(abi.encode(reserve, 52))) + 2;
    uint256 currentValue = uint256(vm.load(pool, bytes32(reserveSlot)));
    uint128 existingRate = uint128(currentValue >> 128);
    bytes32 newPackedValue = bytes32(
      (uint256(existingRate) << 128) | uint256(index) // Keep upper 128 bits // Overwrite lower 128 bits
    );
    vm.store(pool, bytes32(reserveSlot), newPackedValue);
  }

  function setLastUpdateTimestamp(address pool, address reserve, uint40 timestamp) internal {
    uint256 reserveSlot = uint256(keccak256(abi.encode(reserve, 52))) + 3;
    uint256 currentValue = uint256(vm.load(pool, bytes32(reserveSlot)));
    bytes32 newPackedValue = bytes32(
      (currentValue & (~(uint256(type(uint40).max) << 128))) | (uint256(timestamp) << 128)
    );
    vm.store(pool, bytes32(reserveSlot), newPackedValue);
  }

  function setATokenBalance(address token, address user, uint256 balance, uint256 index) internal {
    bytes32 balanceSlot = keccak256(abi.encode(user, 52));
    bytes32 newPackedValue = bytes32(
      (uint256(balance)) | // Insert balance (120 bits)
        (uint256(0) << 120) | // set delegation zero (might make sense to maintain though)
        (uint256(index) << 128) // Preserve index (128 bits)
    );
    vm.store(token, balanceSlot, newPackedValue);
  }

  function setATokenTotalSupply(address token, uint256 totalSupply) internal {
    vm.store(token, bytes32(uint256(54)), bytes32(totalSupply));
  }

  function setVariableDebtTokenBalance(
    address token,
    address user,
    uint256 balance,
    uint256 index
  ) internal {
    bytes32 balanceSlot = keccak256(abi.encode(user, 56));
    bytes32 newPackedValue = bytes32(
      (uint256(balance)) | // Insert balance (120 bits)
        (uint256(0) << 120) | // set delegation zero
        (uint256(index) << 128) // Preserve index (128 bits)
    );
    vm.store(token, balanceSlot, newPackedValue);
  }

  function setVariableDebtTokenTotalSupply(address token, uint256 totalSupply) internal {
    vm.store(token, bytes32(uint256(58)), bytes32(totalSupply));
  }
}
