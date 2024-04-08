// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {TransparentProxyFactory} from '../src/contracts/transparent-proxy/TransparentProxyFactory.sol';
import {TransparentUpgradeableProxy} from '../src/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';
import {IOwnable} from '../src/contracts/transparent-proxy/interfaces/IOwnable.sol';
import {MockImpl} from '../src/mocks/MockImpl.sol';

contract TestTransparentProxyFactory is Test {
  TransparentProxyFactory internal factory;
  MockImpl internal mockImpl;

  function setUp() public {
    factory = new TransparentProxyFactory();
    mockImpl = new MockImpl();
  }

  function testCreateDeterministic(address admin, bytes32 salt) public {
    // we know that this is covered at the ERC1967Upgrade
    vm.assume(admin != address(0));

    uint256 FOO = 2;
    bytes memory data = abi.encodeWithSelector(mockImpl.initialize.selector, FOO);

    address predictedAddress1 = factory.predictCreateDeterministic(
      address(mockImpl),
      admin,
      data,
      salt
    );

    address proxy1 = factory.createDeterministic(address(mockImpl), admin, data, salt);

    assertEq(predictedAddress1, proxy1);
    assertEq(MockImpl(proxy1).getFoo(), FOO);
  }

  function testCreateDeterministicWithDeterministicProxy(bytes32 proxyAdminSalt, bytes32 proxySalt)
    public
  {
    address deterministicProxyAdmin = factory.predictCreateDeterministicProxyAdmin(proxyAdminSalt);

    uint256 FOO = 2;

    bytes memory data = abi.encodeWithSelector(mockImpl.initialize.selector, FOO);

    address predictedAddress1 = factory.predictCreateDeterministic(
      address(mockImpl),
      deterministicProxyAdmin,
      data,
      proxySalt
    );

    address proxy1 = factory.createDeterministic(
      address(mockImpl),
      deterministicProxyAdmin,
      data,
      proxySalt
    );

    assertEq(predictedAddress1, proxy1);
    assertEq(MockImpl(proxy1).getFoo(), FOO);
  }

  function testCreateDeterministicProxyAdmin(address proxyAdminOwner, bytes32 proxyAdminSalt)
    public
  {
    // we know that this is covered at the ProxyAdmin contract
    vm.assume(proxyAdminOwner != address(0));

    address proxyAdmin = factory.createDeterministicProxyAdmin(proxyAdminOwner, proxyAdminSalt);

    address predictedProxyAdmin = factory.predictCreateDeterministicProxyAdmin(proxyAdminSalt);

    address proxyOwner = IOwnable(proxyAdmin).owner();

    assertEq(predictedProxyAdmin, proxyAdmin);
    assertEq(proxyOwner, proxyAdminOwner);
  }

  function testCreateProxyAdmin(address proxyAdminOwner, bytes32 proxyAdminSalt) public {
    // we know that this is covered at the ProxyAdmin contract
    vm.assume(proxyAdminOwner != address(0));

    address proxyAdmin = factory.createDeterministicProxyAdmin(proxyAdminOwner, proxyAdminSalt);
    assertEq(IOwnable(proxyAdmin).owner(), proxyAdminOwner);
  }
}
