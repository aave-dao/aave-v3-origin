// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {HorizonMainnetListing} from '../../scripts/misc/ConfigureHorizonMainnet.sol';
import {IAaveV3ConfigEngine as IEngine} from '../../src/contracts/extensions/v3-config-engine/IAaveV3ConfigEngine.sol';
import {ACLManager, IACLManager} from '../../src/contracts/protocol/configuration/ACLManager.sol';
import {IPoolDataProvider, AaveProtocolDataProvider} from '../../src/contracts/helpers/AaveProtocolDataProvider.sol';
import {IUiPoolDataProviderV3} from '../../src/contracts/helpers/interfaces/IUiPoolDataProviderV3.sol';
import {console2 as console} from 'forge-std/console2.sol';

contract HorizonMainnetListingForkTest is Test {
  // Known mainnet addresses
  address constant CONFIG_ENGINE = 0x0Ffe992faB9D51B14C296748F29A96DACA9B6476; // TODO
  address constant ACL_MANAGER = 0x7Ec3e2a60e8f24FA6A10387318b6d017711F6E34; // TODO
  address constant DATA_PROVIDER = 0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d; // TODO
  address constant UI_POOL_DATA_PROVIDER = 0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d; // TODO

  bytes32 public poolAdminRole;
  HorizonMainnetListing public listing;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'));

    // Deploy listing payload
    listing = new HorizonMainnetListing(IEngine(CONFIG_ENGINE));

    // Grant POOL_ADMIN_ROLE
    IACLManager(ACL_MANAGER).addPoolAdmin(address(listing));
    poolAdminRole = IACLManager(ACL_MANAGER).POOL_ADMIN_ROLE();

    listing.execute();
  }

  function testAdminRevoked() public {
    // Check that the payload has renounced pool admin role
    bool isAdmin = ACLManager(ACL_MANAGER).hasRole(poolAdminRole, address(listing));
    assertFalse(isAdmin, 'Admin role was not renounced');
  }

  function testBUIDLListing_getReserveConfigurationData() public {
    console.log('testExecuteListing');

    // Check that the assets are listed with expected params
    IPoolDataProvider provider = IPoolDataProvider(DATA_PROVIDER);

    // Example: check BUIDL
    (
      uint256 decimals,
      uint256 ltv,
      uint256 liquidationThreshold,
      uint256 liquidationBonus,
      uint256 reserveFactor,
      bool usageAsCollateralEnabled,
      bool borrowingEnabled,
      bool stableBorrowRateEnabled,
      bool isActive,
      bool isFrozen
    ) = provider.getReserveConfigurationData(listing.BUIDL());

    // assertEq(ltv, 8250, 'Wrong LTV');
    // assertEq(liqThreshold, 8600, 'Wrong LiqThreshold');
    // assertEq(liqBonus, 500, 'Wrong LiqBonus');
    // assertEq(reserveFactor, 1000, 'Wrong ReserveFactor');
  }

  function testBUIDLListing_getReservesData() public {
    console.log('testExecuteListing');

    // Check that the assets are listed with expected params
    IUiPoolDataProviderV3 provider = IUiPoolDataProviderV3(UI_POOL_DATA_PROVIDER);

    // // Example: check BUIDL
    // (
    //   uint256 decimals,
    //   uint256 ltv,
    //   uint256 liquidationThreshold,
    //   uint256 liquidationBonus,
    //   uint256 reserveFactor,
    //   bool usageAsCollateralEnabled,
    //   bool borrowingEnabled,
    //   bool stableBorrowRateEnabled,
    //   bool isActive,
    //   bool isFrozen
    // ) = provider.getReservesData(listing.BUIDL());

    // assertEq(ltv, 8250, 'Wrong LTV');
    // assertEq(liqThreshold, 8600, 'Wrong LiqThreshold');
    // assertEq(liqBonus, 500, 'Wrong LiqBonus');
    // assertEq(reserveFactor, 1000, 'Wrong ReserveFactor');
  }

  function testUSDCListing_getReserveConfigurationData() public {
    console.log('testExecuteListing');

    // Check that the assets are listed with expected params
    IPoolDataProvider provider = IPoolDataProvider(DATA_PROVIDER);

    // Example: check USDC
    (
      uint256 decimals,
      uint256 ltv,
      uint256 liquidationThreshold,
      uint256 liquidationBonus,
      uint256 reserveFactor,
      bool usageAsCollateralEnabled,
      bool borrowingEnabled,
      bool stableBorrowRateEnabled,
      bool isActive,
      bool isFrozen
    ) = provider.getReserveConfigurationData(listing.USDC());

    // assertEq(ltv, 8250, 'Wrong LTV');
    // assertEq(liqThreshold, 8600, 'Wrong LiqThreshold');
    // assertEq(liqBonus, 500, 'Wrong LiqBonus');
    // assertEq(reserveFactor, 1000, 'Wrong ReserveFactor');
  }

  function testUSDCListing_getReservesData() public {
    console.log('testExecuteListing');

    // Check that the assets are listed with expected params
    IUiPoolDataProviderV3 provider = IUiPoolDataProviderV3(UI_POOL_DATA_PROVIDER);

    // // Example: check BUIDL
    // (
    //   uint256 decimals,
    //   uint256 ltv,
    //   uint256 liquidationThreshold,
    //   uint256 liquidationBonus,
    //   uint256 reserveFactor,
    //   bool usageAsCollateralEnabled,
    //   bool borrowingEnabled,
    //   bool stableBorrowRateEnabled,
    //   bool isActive,
    //   bool isFrozen
    // ) = provider.getReservesData(listing.BUIDL());

    (
      IUiPoolDataProviderV3.AggregatedReserveData[] memory reserveData,
      IUiPoolDataProviderV3.BaseCurrencyInfo memory baseCurrencyInfo
    ) = provider.getReservesData(IPoolAddressesProvider(provider));

    // assertEq(ltv, 8250, 'Wrong LTV');
    // assertEq(liqThreshold, 8600, 'Wrong LiqThreshold');
    // assertEq(liqBonus, 500, 'Wrong LiqBonus');
    // assertEq(reserveFactor, 1000, 'Wrong ReserveFactor');
  }
}
