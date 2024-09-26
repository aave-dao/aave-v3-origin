// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';
import {Errors} from '../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {ACLManager} from '../../../src/contracts/protocol/configuration/ACLManager.sol';
import {PoolAddressesProvider} from '../../../src/contracts/protocol/configuration/PoolAddressesProvider.sol';

contract ACLManagerTest is TestnetProcedures {
  address internal immutable deployer;
  address internal immutable defaultAdmin;
  address internal immutable poolAdminRole;
  address internal immutable riskAdminRole;
  address internal immutable bridgeAdminRole;
  address internal immutable assetsListingAdminRole;
  address internal immutable emergencyAdminRole;
  address internal immutable flashBorrowAdmin;
  address internal immutable flashBorrowRole;
  address internal immutable anyUser;

  bytes32 internal constant FLASH_BORROWER_ADMIN = keccak256('FLASH_BORROWER_ADMIN');

  ACLManager internal aclManager;
  PoolAddressesProvider internal poolAddressesProvider;
  bytes32 DEFAULT_ADMIN_ROLE;
  bytes32 FLASH_BORROWER_ROLE;

  constructor() {
    deployer = makeAddr('DEPLOYER');
    defaultAdmin = makeAddr('DEFAULT_ADMIN');
    poolAdminRole = makeAddr('POOL_ADMIN_ROLE');
    riskAdminRole = makeAddr('RISK_ADMIN_ROLE');
    bridgeAdminRole = makeAddr('BRIDGE_ADMIN_ROLE');
    assetsListingAdminRole = makeAddr('ASSETS_LISTING_ADMIN_ROLE');
    emergencyAdminRole = makeAddr('EMERGENCY_ADMIN_ROLE');
    flashBorrowAdmin = makeAddr('FLASH_BORROW_ROLE_ADMIN');
    flashBorrowRole = makeAddr('FLASH_BORROW_ROLE');
    anyUser = makeAddr('ANY_USER');
  }

  function setUp() public {
    vm.startPrank(deployer);
    poolAddressesProvider = new PoolAddressesProvider('1', deployer);

    // Sets future DEFAULT_ADMIN_ROLE
    poolAddressesProvider.setACLAdmin(defaultAdmin);

    aclManager = new ACLManager(poolAddressesProvider);

    vm.stopPrank();

    DEFAULT_ADMIN_ROLE = aclManager.DEFAULT_ADMIN_ROLE();
    FLASH_BORROWER_ROLE = aclManager.FLASH_BORROWER_ROLE();
  }

  function testDefaultAdminRoleAfterDeploy() public view {
    assertTrue(aclManager.hasRole(DEFAULT_ADMIN_ROLE, defaultAdmin));
    assertFalse(aclManager.hasRole(DEFAULT_ADMIN_ROLE, anyUser));
    assertFalse(aclManager.hasRole(DEFAULT_ADMIN_ROLE, deployer));
  }

  function test_reverts_notAdmin_grantRole_FlashBorrow() public {
    assertFalse(aclManager.isFlashBorrower(flashBorrowRole));
    vm.prank(defaultAdmin);
    aclManager.grantRole(FLASH_BORROWER_ADMIN, flashBorrowAdmin);
    string memory revertError1 = 'AccessControl: account ';
    string
      memory revertError2 = ' is missing role 0x0000000000000000000000000000000000000000000000000000000000000000';
    vm.expectRevert(
      bytes(string(abi.encodePacked(revertError1, toAsciiString(flashBorrowAdmin), revertError2)))
    );
    vm.prank(flashBorrowAdmin);
    aclManager.grantRole(FLASH_BORROWER_ROLE, flashBorrowRole);
  }

  function test_defaultAdmin_grantAdminRole_FlashBorrowAdmin() public {
    vm.prank(defaultAdmin);
    aclManager.grantRole(FLASH_BORROWER_ADMIN, flashBorrowAdmin);

    vm.prank(defaultAdmin);
    aclManager.setRoleAdmin(FLASH_BORROWER_ROLE, FLASH_BORROWER_ADMIN);
  }

  function test_revert_anyUser_grantAdminRole_FlashBorrowAdmin() public {
    vm.prank(defaultAdmin);
    aclManager.grantRole(FLASH_BORROWER_ADMIN, flashBorrowAdmin);

    vm.prank(anyUser);
    vm.expectRevert();
    aclManager.setRoleAdmin(FLASH_BORROWER_ROLE, FLASH_BORROWER_ADMIN);
  }

  function test_flashBorrowAdmin_grantRole_FlashBorrowRole() public {
    vm.prank(defaultAdmin);
    aclManager.grantRole(FLASH_BORROWER_ADMIN, flashBorrowAdmin);

    vm.prank(defaultAdmin);
    aclManager.setRoleAdmin(FLASH_BORROWER_ROLE, FLASH_BORROWER_ADMIN);

    vm.prank(flashBorrowAdmin);
    aclManager.addFlashBorrower(flashBorrowRole);
  }

  function test_flashBorrowAdmin_removeRole_FlashBorrowRole() public {
    vm.startPrank(defaultAdmin);

    aclManager.grantRole(FLASH_BORROWER_ADMIN, flashBorrowAdmin);
    aclManager.setRoleAdmin(FLASH_BORROWER_ROLE, FLASH_BORROWER_ADMIN);

    vm.stopPrank();

    vm.startPrank(flashBorrowAdmin);

    aclManager.addFlashBorrower(flashBorrowRole);
    aclManager.removeFlashBorrower(flashBorrowRole);

    vm.stopPrank();
  }

  function test_reverts_defaultAdmin_notRoleAdmin_addRole_FlashBorrowRole() public {
    vm.startPrank(defaultAdmin);

    aclManager.grantRole(FLASH_BORROWER_ADMIN, flashBorrowAdmin);
    aclManager.setRoleAdmin(FLASH_BORROWER_ROLE, FLASH_BORROWER_ADMIN);

    vm.stopPrank();

    vm.prank(defaultAdmin);
    vm.expectRevert();
    aclManager.addFlashBorrower(flashBorrowRole);
  }

  function test_reverts_defaultAdmin_notRoleAdmin_revokeRole_FlashBorrowRole() public {
    vm.startPrank(defaultAdmin);

    aclManager.grantRole(FLASH_BORROWER_ADMIN, flashBorrowAdmin);
    aclManager.setRoleAdmin(FLASH_BORROWER_ROLE, FLASH_BORROWER_ADMIN);

    vm.stopPrank();

    vm.prank(flashBorrowAdmin);
    aclManager.addFlashBorrower(flashBorrowRole);

    vm.prank(defaultAdmin);
    vm.expectRevert();
    aclManager.removeFlashBorrower(flashBorrowRole);
  }

  function test_defaultAdmin_grants_PoolAdminRole() public {
    vm.prank(defaultAdmin);
    aclManager.addPoolAdmin(poolAdminRole);
  }

  function test_remove_riskAdmin() public {
    vm.startPrank(defaultAdmin);
    aclManager.addRiskAdmin(riskAdminRole);
    aclManager.removeRiskAdmin(riskAdminRole);
    vm.stopPrank();
  }

  function test_defaultAdmin_grants_EmergencyAdminRole() public {
    vm.prank(defaultAdmin);
    aclManager.addEmergencyAdmin(emergencyAdminRole);
  }

  function test_defaultAdmin_grants_BridgeRole() public {
    vm.prank(defaultAdmin);
    aclManager.addBridge(bridgeAdminRole);
  }

  function test_defaultAdmin_grants_RiskRole() public {
    vm.prank(defaultAdmin);
    aclManager.addRiskAdmin(riskAdminRole);
  }

  function test_defaultAdmin_grants_AssetsListingRole() public {
    vm.prank(defaultAdmin);
    aclManager.addAssetListingAdmin(assetsListingAdminRole);
  }

  function test_defaultAdmin_remove_PoolAdminRole() public {
    vm.startPrank(defaultAdmin);

    aclManager.addPoolAdmin(poolAdminRole);
    aclManager.removePoolAdmin(poolAdminRole);
    vm.stopPrank();
  }

  function test_defaultAdmin_remove_BridgeRole() public {
    vm.startPrank(defaultAdmin);

    aclManager.addBridge(bridgeAdminRole);
    aclManager.removeBridge(bridgeAdminRole);
    vm.stopPrank();
  }

  function test_defaultAdmin_remove_EmergencyAdminRole() public {
    vm.startPrank(defaultAdmin);

    aclManager.addEmergencyAdmin(emergencyAdminRole);
    aclManager.removeEmergencyAdmin(emergencyAdminRole);
    vm.stopPrank();
  }

  function test_defaultAdmin_remove_RiskRole() public {
    vm.startPrank(defaultAdmin);

    aclManager.addAssetListingAdmin(riskAdminRole);
    aclManager.removeAssetListingAdmin(riskAdminRole);
    vm.stopPrank();
  }

  function test_defaultAdmin_remove_AssetsListingRole() public {
    vm.startPrank(defaultAdmin);

    aclManager.addAssetListingAdmin(assetsListingAdminRole);
    aclManager.removeAssetListingAdmin(assetsListingAdminRole);
    vm.stopPrank();
  }

  function test_revert_deploy_ACLADMIN_zeroAddress() public {
    vm.startPrank(deployer);
    PoolAddressesProvider provider = new PoolAddressesProvider('1', deployer);
    provider.setACLAdmin(address(0));

    vm.expectRevert(bytes(Errors.ACL_ADMIN_CANNOT_BE_ZERO));
    new ACLManager(provider);
    vm.stopPrank();
  }

  /**
   * @dev Needed to check revert messages with addresses. Convert an Address to a String without checksum. Foundry vm.toString preserves checksum.
   */
  function toAsciiString(address x) internal pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint256 i = 0; i < 20; i++) {
      bytes1 b = bytes1(uint8(uint(uint160(x)) / (2 ** (8 * (19 - i)))));
      bytes1 hi = bytes1(uint8(b) / 16);
      bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
      s[2 * i] = char(hi);
      s[2 * i + 1] = char(lo);
    }
    return string(abi.encodePacked('0x', string(s)));
  }

  function char(bytes1 b) internal pure returns (bytes1 c) {
    if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
    else return bytes1(uint8(b) + 0x57);
  }
}
