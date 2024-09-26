// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {SlotParser} from '../../utils/SlotParser.sol';
import {MockInitializableImple, MockInitializableImpleV2} from '../../../src/contracts/mocks/upgradeability/MockInitializableImplementation.sol';
import '../../../src/contracts/misc/aave-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol';

contract InitializableImmutableAdminUpgradeabilityProxyTests is Test {
  using stdStorage for StdStorage;

  address internal poolAdmin;
  MockInitializableImple internal implementationV1;
  MockInitializableImpleV2 internal implementationV2;

  address internal admin;

  function setUp() public {
    admin = makeAddr('PROXY_ADMIN');

    implementationV1 = new MockInitializableImple();
    implementationV2 = new MockInitializableImpleV2();
  }

  function test_proxy_upgradeToAndCall_initialize()
    public
    returns (InitializableImmutableAdminUpgradeabilityProxy)
  {
    uint256 initialValue = 2;
    string memory initialText = 'pool';
    uint256[] memory initialList = new uint256[](2);
    initialList[0] = 10;
    initialList[1] = 20;

    InitializableImmutableAdminUpgradeabilityProxy proxy = new InitializableImmutableAdminUpgradeabilityProxy(
        admin
      );
    address proxyAddress = address(proxy);

    bytes memory encodedCall = abi.encodeWithSelector(
      MockInitializableImple.initialize.selector,
      initialValue,
      initialText,
      initialList
    );

    vm.prank(admin);
    proxy.upgradeToAndCall(address(implementationV1), encodedCall);

    // Proxy admin matches constructor
    vm.prank(admin);
    address currentAdmin = proxy.admin();
    assertEq(currentAdmin, admin);
    // Proxy target implementation matches implementation address
    assertEq(
      SlotParser.loadAddressFromSlot(
        proxyAddress,
        bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
      ),
      address(implementationV1)
    );

    // Perform getter calls to proxy with MockInitializableImple interface
    assertEq(MockInitializableImple(proxyAddress).value(), initialValue);
    assertEq(MockInitializableImple(proxyAddress).text(), initialText);
    assertEq(MockInitializableImple(proxyAddress).values(0), initialList[0]);
    assertEq(MockInitializableImple(proxyAddress).values(1), initialList[1]);
    assertEq(MockInitializableImple(proxyAddress).REVISION(), 1);

    return proxy;
  }

  function test_proxy_fallback() public {
    InitializableImmutableAdminUpgradeabilityProxy proxy = test_proxy_upgradeToAndCall_initialize();
    address proxyAddress = address(proxy);

    uint256 newValues = 15;

    MockInitializableImple(proxyAddress).setValue(15);

    assertEq(MockInitializableImple(proxyAddress).value(), newValues);
  }

  function test_proxy_upgradeToAndCall() public {
    InitializableImmutableAdminUpgradeabilityProxy proxy = test_proxy_upgradeToAndCall_initialize();
    address proxyAddress = address(proxy);

    uint256 initialValue = 4;
    string memory initialText = 'poolv4';
    uint256[] memory initialList = new uint256[](2);
    initialList[0] = 50;
    initialList[1] = 60;

    bytes memory encodedCall = abi.encodeWithSelector(
      MockInitializableImple.initialize.selector,
      initialValue,
      initialText,
      initialList
    );

    vm.prank(admin);
    proxy.upgradeToAndCall(address(implementationV2), encodedCall);

    // Proxy admin matches constructor
    vm.prank(admin);
    address currentAdmin = proxy.admin();
    assertEq(currentAdmin, admin);
    // Proxy target implementation matches implementation address
    assertEq(
      SlotParser.loadAddressFromSlot(
        proxyAddress,
        bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
      ),
      address(implementationV2)
    );

    // Perform getter calls to proxy with MockInitializableImple interface
    assertEq(MockInitializableImple(proxyAddress).value(), initialValue);
    assertEq(MockInitializableImple(proxyAddress).text(), initialText);
    assertEq(MockInitializableImple(proxyAddress).values(0), initialList[0]);
    assertEq(MockInitializableImple(proxyAddress).values(1), initialList[1]);
    assertEq(MockInitializableImple(proxyAddress).REVISION(), 2);

    // Test fallback
    MockInitializableImple(proxyAddress).setValue(4502310);
    assertEq(MockInitializableImple(proxyAddress).value(), 4502310);
  }

  function test_proxy_upgradeTo() public {
    InitializableImmutableAdminUpgradeabilityProxy proxy = test_proxy_upgradeToAndCall_initialize();
    address proxyAddress = address(proxy);
    uint256 initialValue = 2;
    string memory initialText = 'pool';
    uint256[] memory initialList = new uint256[](2);
    initialList[0] = 10;
    initialList[1] = 20;

    vm.prank(admin);
    proxy.upgradeTo(address(implementationV2));

    // Proxy admin matches constructor
    vm.prank(admin);
    address currentAdmin = proxy.admin();
    assertEq(currentAdmin, admin);
    // Proxy target implementation matches implementation address
    assertEq(
      SlotParser.loadAddressFromSlot(
        proxyAddress,
        bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
      ),
      address(implementationV2)
    );

    // Perform getter calls to proxy with MockInitializableImple interface
    assertEq(MockInitializableImple(proxyAddress).value(), initialValue);
    assertEq(MockInitializableImple(proxyAddress).text(), initialText);
    assertEq(MockInitializableImple(proxyAddress).values(0), initialList[0]);
    assertEq(MockInitializableImple(proxyAddress).values(1), initialList[1]);
    assertEq(MockInitializableImple(proxyAddress).REVISION(), 2);

    // Test fallback
    MockInitializableImple(proxyAddress).setValue(4502310);
    assertEq(MockInitializableImple(proxyAddress).value(), 4502310);
  }

  function test_reverts_upgradeToAndCall_notAdmin() public {
    InitializableImmutableAdminUpgradeabilityProxy proxy = test_proxy_upgradeToAndCall_initialize();

    uint256 initialValue = 5;
    string memory initialText = 'poolv5';
    uint256[] memory initialList = new uint256[](2);
    initialList[0] = 120;
    initialList[1] = 20;

    bytes memory encodedCall = abi.encodeWithSelector(
      MockInitializableImple.initialize.selector,
      initialValue,
      initialText,
      initialList
    );

    vm.expectRevert();
    proxy.upgradeToAndCall(address(implementationV2), encodedCall);
  }

  function test_reverts_upgradeTo_notAdmin() public {
    InitializableImmutableAdminUpgradeabilityProxy proxy = test_proxy_upgradeToAndCall_initialize();

    vm.expectRevert();
    proxy.upgradeTo(address(implementationV2));
  }
}
