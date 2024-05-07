// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IParaSwapAugustusRegistry} from '../../extensions/paraswap-adapters/interfaces/IParaSwapAugustusRegistry.sol';

contract MockParaSwapAugustusRegistry is IParaSwapAugustusRegistry {
  address immutable AUGUSTUS;

  constructor(address augustus) {
    AUGUSTUS = augustus;
  }

  function isValidAugustus(address augustus) external view override returns (bool) {
    return augustus == AUGUSTUS;
  }
}
