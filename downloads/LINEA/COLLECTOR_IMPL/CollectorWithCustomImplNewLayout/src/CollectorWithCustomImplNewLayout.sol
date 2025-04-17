// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Collector, ICollector} from '../lib/aave-v3-origin/src/contracts/treasury/Collector.sol';

/**
 * @title Collector
 * Custom modifications of this implementation:
 * - the initialize function manually alters private storage slots via assembly
 * - storage slot 0 (previously revision) is reset to zero
 * - storage slot 53 (previously fundsAdmin) is set to 100000 (the previous nextStreamId)
 * - storage slot 54 (previously nextStreamId) is reset to 0
 * @author BGD Labs
 *
 */
contract CollectorWithCustomImplNewLayout is Collector {
  function initialize(uint256, address admin) external virtual override initializer {
    assembly {
      sstore(0, 0) // this slot was revision, which is no longer used
      sstore(53, 100000) // this slot was _fundsAdmin, but is now _nextStreamId
      sstore(54, 0) // this slot was _nextStreamId, but is now _streams
    }
    __AccessControl_init();
    __ReentrancyGuard_init();
    _grantRole(DEFAULT_ADMIN_ROLE, admin);
  }
}
