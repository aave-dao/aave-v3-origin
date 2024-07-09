// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

library EngineFlags {
  /// @dev magic value to be used as flag to keep unchanged any current configuration
  /// Strongly assumes that the value `type(uint256).max - 42` will never be used, which seems reasonable
  uint256 internal constant KEEP_CURRENT = type(uint256).max - 42;

  /// @dev magic value to be used as flag to keep unchanged any current configuration
  /// Strongly assumes that the value `KEEP_CURRENT_STRING` will never be used, which seems reasonable
  string internal constant KEEP_CURRENT_STRING = 'KEEP_CURRENT_STRING';

  /// @dev magic value to be used as flag to keep unchanged any current configuration
  /// Strongly assumes that the value `0x0000000000000000000000000000000000000050` will never be used, which seems reasonable
  address internal constant KEEP_CURRENT_ADDRESS =
    address(0x0000000000000000000000000000000000000050);

  /// @dev value to be used as flag for bool value true
  uint256 internal constant ENABLED = 1;

  /// @dev value to be used as flag for bool value false
  uint256 internal constant DISABLED = 0;

  /// @dev converts flag ENABLED DISABLED to bool
  function toBool(uint256 flag) internal pure returns (bool) {
    require(flag == 0 || flag == 1, 'INVALID_CONVERSION_TO_BOOL');
    return flag == 1;
  }

  /// @dev converts bool to ENABLED DISABLED flags
  function fromBool(bool isTrue) internal pure returns (uint256) {
    return isTrue ? ENABLED : DISABLED;
  }
}
