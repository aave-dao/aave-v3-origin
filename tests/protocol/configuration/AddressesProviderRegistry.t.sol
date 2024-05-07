// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';
import {Errors} from '../../../src/contracts/protocol/libraries/helpers/Errors.sol';

contract PoolAddressesProviderRegistryTest is TestnetProcedures {
  event AddressesProviderRegistered(address indexed addressesProvider, uint256 indexed id);
  event AddressesProviderUnregistered(address indexed addressesProvider, uint256 indexed id);

  function setUp() public {
    initTestEnvironment();
  }

  function test_addressesProviderAddedToRegistry() public view {
    address[] memory providers = contracts
      .poolAddressesProviderRegistry
      .getAddressesProvidersList();
    assertEq(providers.length, 1);
    assertEq(providers[0], report.poolAddressesProvider);
  }

  function test_revert_registry_0() public {
    vm.expectRevert(bytes(Errors.INVALID_ADDRESSES_PROVIDER_ID));
    vm.prank(poolAdmin);
    contracts.poolAddressesProviderRegistry.registerAddressesProvider(makeAddr('MOCK_PROVIDER'), 0);
  }

  function testAddAddressesProvider() public {
    address newAddressesProvider = makeAddr('NEW_PROVIDER');
    uint256 newAddressesProviderId = 1010;
    vm.expectEmit(address(contracts.poolAddressesProviderRegistry));
    emit AddressesProviderRegistered(newAddressesProvider, newAddressesProviderId);

    vm.startPrank(poolAdmin);
    contracts.poolAddressesProviderRegistry.registerAddressesProvider(
      newAddressesProvider,
      newAddressesProviderId
    );
    vm.stopPrank();

    assertEq(
      contracts.poolAddressesProviderRegistry.getAddressesProviderIdByAddress(newAddressesProvider),
      newAddressesProviderId
    );
    assertEq(
      contracts.poolAddressesProviderRegistry.getAddressesProviderAddressById(
        newAddressesProviderId
      ),
      newAddressesProvider
    );
    assertEq(contracts.poolAddressesProviderRegistry.getAddressesProvidersList().length, 2);
  }

  function testRemoveAddressesProvider() public {
    address newAddressesProvider = makeAddr('NEW_PROVIDER');
    uint256 newAddressesProviderId = 2020;

    vm.expectEmit(address(contracts.poolAddressesProviderRegistry));
    emit AddressesProviderRegistered(newAddressesProvider, newAddressesProviderId);

    vm.startPrank(poolAdmin);
    contracts.poolAddressesProviderRegistry.registerAddressesProvider(
      newAddressesProvider,
      newAddressesProviderId
    );

    vm.expectEmit(address(contracts.poolAddressesProviderRegistry));
    emit AddressesProviderUnregistered(newAddressesProvider, newAddressesProviderId);

    contracts.poolAddressesProviderRegistry.unregisterAddressesProvider(newAddressesProvider);
    vm.stopPrank();

    assertEq(contracts.poolAddressesProviderRegistry.getAddressesProvidersList().length, 1);
    assertEq(
      contracts.poolAddressesProviderRegistry.getAddressesProviderIdByAddress(newAddressesProvider),
      0
    );
    assertEq(
      contracts.poolAddressesProviderRegistry.getAddressesProviderAddressById(
        newAddressesProviderId
      ),
      address(0)
    );
  }

  function testRemoveMultipleAddressesProvider() public {
    address newAddressesProvider1 = makeAddr('NEW_PROVIDER_1');
    address newAddressesProvider2 = makeAddr('NEW_PROVIDER_2');
    address newAddressesProvider3 = makeAddr('NEW_PROVIDER_3');
    uint256 newAddressesProviderId = 2020;

    vm.startPrank(poolAdmin);
    contracts.poolAddressesProviderRegistry.registerAddressesProvider(
      newAddressesProvider1,
      newAddressesProviderId
    );
    contracts.poolAddressesProviderRegistry.registerAddressesProvider(
      newAddressesProvider2,
      newAddressesProviderId + 1
    );
    contracts.poolAddressesProviderRegistry.registerAddressesProvider(
      newAddressesProvider3,
      newAddressesProviderId + 2
    );

    vm.expectEmit(address(contracts.poolAddressesProviderRegistry));
    emit AddressesProviderUnregistered(newAddressesProvider2, newAddressesProviderId + 1);

    contracts.poolAddressesProviderRegistry.unregisterAddressesProvider(newAddressesProvider2);
    vm.stopPrank();

    assertEq(
      contracts.poolAddressesProviderRegistry.getAddressesProviderIdByAddress(
        newAddressesProvider2
      ),
      0
    );
    assertEq(
      contracts.poolAddressesProviderRegistry.getAddressesProviderAddressById(
        newAddressesProviderId + 1
      ),
      address(0)
    );
  }

  function test_revert_removeNonExistingAddressesProvider() public {
    address newAddressesProvider = makeAddr('NEW_PROVIDER');

    vm.startPrank(poolAdmin);
    vm.expectRevert();
    contracts.poolAddressesProviderRegistry.unregisterAddressesProvider(newAddressesProvider);
    vm.stopPrank();

    assertEq(contracts.poolAddressesProviderRegistry.getAddressesProvidersList().length, 1);
    assertEq(
      contracts.poolAddressesProviderRegistry.getAddressesProviderIdByAddress(newAddressesProvider),
      0
    );
  }

  function test_removesLastProvider() public {
    uint256 id = contracts.poolAddressesProviderRegistry.getAddressesProviderIdByAddress(
      report.poolAddressesProvider
    );

    vm.startPrank(poolAdmin);
    contracts.poolAddressesProviderRegistry.unregisterAddressesProvider(
      report.poolAddressesProvider
    );
    vm.stopPrank();

    assertEq(contracts.poolAddressesProviderRegistry.getAddressesProvidersList().length, 0);
    assertEq(
      contracts.poolAddressesProviderRegistry.getAddressesProviderAddressById(id),
      address(0)
    );
    assertEq(
      contracts.poolAddressesProviderRegistry.getAddressesProviderIdByAddress(
        report.poolAddressesProvider
      ),
      0
    );
  }
}
