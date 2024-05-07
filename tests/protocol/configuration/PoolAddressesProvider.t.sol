// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {PoolAddressesProvider, IPoolAddressesProvider} from '../../../src/contracts/protocol/configuration/PoolAddressesProvider.sol';
import {PoolInstance} from '../../../src/contracts/instances/PoolInstance.sol';
import {MockInitializableV1, MockInitializableV2} from '../../../src/contracts/mocks/upgradeability/MockInitializableImplementation.sol';
import {PoolConfiguratorInstance} from '../../../src/contracts/instances/PoolConfiguratorInstance.sol';
import {MockPoolInherited} from '../../../src/contracts/mocks/helpers/MockPool.sol';
import {ACLManager} from '../../../src/contracts/protocol/configuration/ACLManager.sol';
import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';
import {SlotParser} from '../../utils/SlotParser.sol';

contract PoolAddressesProviderTests is TestnetProcedures {
  using stdStorage for StdStorage;

  address internal stranger;

  string constant CALLER_NOT_OWNER = 'Ownable: caller is not the owner';

  event MarketIdSet(string indexed oldMarketId, string indexed newMarketId);

  event PoolUpdated(address indexed oldAddress, address indexed newAddress);

  event PoolConfiguratorUpdated(address indexed oldAddress, address indexed newAddress);

  event PriceOracleUpdated(address indexed oldAddress, address indexed newAddress);

  event ACLManagerUpdated(address indexed oldAddress, address indexed newAddress);

  event ACLAdminUpdated(address indexed oldAddress, address indexed newAddress);

  event PriceOracleSentinelUpdated(address indexed oldAddress, address indexed newAddress);

  event PoolDataProviderUpdated(address indexed oldAddress, address indexed newAddress);

  event ProxyCreated(
    bytes32 indexed id,
    address indexed proxyAddress,
    address indexed implementationAddress
  );

  event AddressSet(bytes32 indexed id, address indexed oldAddress, address indexed newAddress);

  event AddressSetAsProxy(
    bytes32 indexed id,
    address indexed proxyAddress,
    address oldImplementationAddress,
    address indexed newImplementationAddress
  );
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function setUp() public {
    stranger = makeAddr('STRANGER');

    initTestEnvironment();
  }

  function test_new_PoolAddressesProvider() public returns (PoolAddressesProvider) {
    string memory id = 'Constructor Test Market';
    address expectedAddress = vm.computeCreateAddress(alice, vm.getNonce(alice));

    vm.expectEmit(expectedAddress);
    emit OwnershipTransferred(address(0), alice);

    vm.expectEmit(expectedAddress);
    emit MarketIdSet('', id);

    vm.expectEmit(expectedAddress);
    emit OwnershipTransferred(alice, alice);

    vm.prank(alice);
    PoolAddressesProvider provider = new PoolAddressesProvider(id, alice);

    assertEq(provider.getMarketId(), id);
    assertEq(provider.owner(), alice);

    return provider;
  }

  function test_getter_getMarketId() public {
    string memory id = 'Foundry Test Market';
    PoolAddressesProvider provider = new PoolAddressesProvider(id, alice);

    assertEq(provider.getMarketId(), id);
  }

  function test_setter_setMarketId() public {
    string memory deploymentId = 'Initial Market';
    string memory updatedId = 'New Test Market';
    PoolAddressesProvider provider = new PoolAddressesProvider(deploymentId, alice);

    assertEq(provider.getMarketId(), deploymentId);

    vm.expectEmit(address(provider));
    emit MarketIdSet(deploymentId, updatedId);

    vm.prank(alice);
    provider.setMarketId(updatedId);

    assertEq(provider.getMarketId(), updatedId);
  }

  function test_reverts_setters_notOwner() public {
    string memory deploymentId = 'Initial Market';
    PoolAddressesProvider provider = new PoolAddressesProvider(deploymentId, alice);
    bytes32 id = keccak256('REVERT_TEST');
    address contractAddress = makeAddr('TEST');

    vm.expectRevert(bytes(CALLER_NOT_OWNER));
    provider.setMarketId('123');

    vm.expectRevert(bytes(CALLER_NOT_OWNER));
    provider.setAddress(id, contractAddress);

    vm.expectRevert(bytes(CALLER_NOT_OWNER));
    provider.setAddressAsProxy(id, contractAddress);

    vm.expectRevert(bytes(CALLER_NOT_OWNER));
    provider.setACLAdmin(contractAddress);

    vm.expectRevert(bytes(CALLER_NOT_OWNER));
    provider.setPoolImpl(contractAddress);

    vm.expectRevert(bytes(CALLER_NOT_OWNER));
    provider.setPoolConfiguratorImpl(contractAddress);

    vm.expectRevert(bytes(CALLER_NOT_OWNER));
    provider.setPriceOracle(contractAddress);

    vm.expectRevert(bytes(CALLER_NOT_OWNER));
    provider.setPriceOracleSentinel(contractAddress);

    vm.expectRevert(bytes(CALLER_NOT_OWNER));
    provider.setACLManager(contractAddress);

    vm.expectRevert(bytes(CALLER_NOT_OWNER));
    provider.setPoolDataProvider(contractAddress);
  }

  function test_setAddressAsProxy_new_proxy() public returns (PoolAddressesProvider, address) {
    PoolAddressesProvider provider = new PoolAddressesProvider('test', alice);

    bytes32 id = keccak256('MOCK_TEST');

    address implementation = address(new MockInitializableV1());

    vm.expectEmit(true, false, true, true, address(provider));
    emit ProxyCreated(id, address(0), implementation);
    vm.expectEmit(true, true, true, true, address(provider));
    emit AddressSetAsProxy(id, address(0), address(0), implementation);

    vm.prank(alice);
    provider.setAddressAsProxy(id, implementation);

    assertEq(
      SlotParser.loadAddressFromSlot(
        provider.getAddress(id),
        bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
      ),
      implementation
    );
    return (provider, implementation);
  }

  function test_setAddressAsProxy_upgrade_proxy() public {
    (
      PoolAddressesProvider provider,
      address previousImplementation
    ) = test_setAddressAsProxy_new_proxy();
    bytes32 id = keccak256('MOCK_TEST');
    address proxyAddress = provider.getAddress(id);
    address newImplementationAddress = address(new MockInitializableV2());

    vm.expectEmit(true, true, true, true, address(provider));
    emit AddressSetAsProxy(id, proxyAddress, previousImplementation, newImplementationAddress);

    vm.prank(alice);
    provider.setAddressAsProxy(id, newImplementationAddress);

    assertEq(
      SlotParser.loadAddressFromSlot(
        provider.getAddress(id),
        bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
      ),
      newImplementationAddress
    );
  }

  function test_reverts_setAddressAsProxy_notAuth() public {
    PoolAddressesProvider provider = test_new_PoolAddressesProvider();
    vm.expectRevert(bytes(CALLER_NOT_OWNER));

    vm.prank(stranger);
    provider.setAddressAsProxy(keccak256('1'), address(1));
  }

  function test_setAddress() public {
    PoolAddressesProvider provider = new PoolAddressesProvider('test', alice);

    bytes32 id = keccak256('MOCK_CONTRACT');
    address contractAddress = makeAddr('MOCK_CONTRACT');

    vm.expectEmit();
    emit AddressSet(id, address(0), contractAddress);

    vm.prank(alice);
    provider.setAddress(id, contractAddress);

    assertEq(provider.getAddress(id), contractAddress);
  }

  function test_setAddress_updateAddress() public {
    PoolAddressesProvider provider = new PoolAddressesProvider('test', alice);

    bytes32 id = keccak256('MOCK_CONTRACT');
    address firstContract = makeAddr('FIRST_CONTRACT');
    address secondContract = makeAddr('SECOND_CONTRACT');

    vm.expectEmit(address(provider));
    emit AddressSet(id, address(0), firstContract);

    vm.prank(alice);
    provider.setAddress(id, firstContract);

    assertEq(provider.getAddress(id), firstContract);

    vm.expectEmit(address(provider));
    emit AddressSet(id, firstContract, secondContract);

    vm.prank(alice);
    provider.setAddress(id, secondContract);
    assertEq(provider.getAddress(id), secondContract);
  }

  function test_reverts_setAddress_noAuth() public {
    PoolAddressesProvider provider = test_new_PoolAddressesProvider();
    vm.expectRevert(bytes(CALLER_NOT_OWNER));
    vm.prank(stranger);
    provider.setAddress(keccak256('0'), makeAddr('123'));

    assertEq(provider.getAddress(keccak256('0')), address(0));
  }

  function test_setPoolImpl() public returns (PoolAddressesProvider, address) {
    PoolAddressesProvider provider = new PoolAddressesProvider('test', alice);

    address poolImplementation = address(
      new PoolInstance(IPoolAddressesProvider(address(provider)))
    );
    assertEq(provider.getPool(), address(0));

    vm.expectEmit(address(provider));
    emit PoolUpdated(address(0), poolImplementation);

    vm.prank(alice);
    provider.setPoolImpl(poolImplementation);

    assertTrue(provider.getPool() != address(0));
    assertEq(
      SlotParser.loadAddressFromSlot(
        provider.getPool(),
        bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
      ),
      poolImplementation
    );

    return (provider, poolImplementation);
  }

  function test_setPoolImpl_upgrade() public {
    (PoolAddressesProvider provider, address currentImplementation) = test_setPoolImpl();
    address poolImplementation = address(
      new MockPoolInherited(IPoolAddressesProvider(address(provider)))
    );
    assertTrue(currentImplementation != address(0));

    vm.expectEmit(address(provider));
    emit PoolUpdated(currentImplementation, poolImplementation);

    vm.prank(alice);
    provider.setPoolImpl(poolImplementation);

    assertEq(
      SlotParser.loadAddressFromSlot(
        provider.getPool(),
        bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
      ),
      poolImplementation
    );
  }

  function test_setPoolConfiguratorImpl() public returns (PoolAddressesProvider, address) {
    PoolAddressesProvider provider = new PoolAddressesProvider('test', alice);

    address implementation = address(new PoolConfiguratorInstance());
    vm.expectEmit(address(provider));
    emit PoolConfiguratorUpdated(address(0), implementation);

    assertEq(provider.getPoolConfigurator(), address(0));

    vm.prank(alice);
    provider.setPoolConfiguratorImpl(implementation);

    assertTrue(provider.getPoolConfigurator() != address(0));
    assertEq(
      SlotParser.loadAddressFromSlot(
        provider.getPoolConfigurator(),
        bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
      ),
      implementation
    );

    return (provider, implementation);
  }

  function test_setPoolConfiguratorImpl_upgrade() public {
    (
      PoolAddressesProvider provider,
      address currentImplementation
    ) = test_setPoolConfiguratorImpl();
    address implementation = address(
      new MockPoolInherited(IPoolAddressesProvider(address(provider)))
    );
    assertTrue(implementation != address(0));

    vm.expectEmit(address(provider));
    emit PoolConfiguratorUpdated(currentImplementation, implementation);

    vm.prank(alice);
    provider.setPoolConfiguratorImpl(implementation);

    assertEq(
      SlotParser.loadAddressFromSlot(
        provider.getPoolConfigurator(),
        bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
      ),
      implementation
    );
  }

  function test_setPriceOracle() public returns (PoolAddressesProvider, address) {
    PoolAddressesProvider provider = new PoolAddressesProvider('test', alice);

    address contractAddress = makeAddr('PriceOracle');
    vm.expectEmit(address(provider));
    emit PriceOracleUpdated(address(0), contractAddress);

    assertEq(provider.getPriceOracle(), address(0));

    vm.prank(alice);
    provider.setPriceOracle(contractAddress);

    assertEq(provider.getPriceOracle(), contractAddress);

    return (provider, contractAddress);
  }

  function test_setPriceOracle_changeContract() public returns (PoolAddressesProvider, address) {
    (PoolAddressesProvider provider, address previousAddress) = test_setPriceOracle();
    address contractAddress = makeAddr('PriceOracle_V2');
    vm.expectEmit(address(provider));
    emit PriceOracleUpdated(previousAddress, contractAddress);

    assertEq(provider.getPriceOracle(), previousAddress);

    vm.prank(alice);
    provider.setPriceOracle(contractAddress);

    assertEq(provider.getPriceOracle(), contractAddress);

    return (provider, contractAddress);
  }

  function test_setACLManager_setACLAdmin() public returns (PoolAddressesProvider, address) {
    PoolAddressesProvider provider = new PoolAddressesProvider('test', alice);

    vm.expectEmit(address(provider));
    emit ACLAdminUpdated(address(0), alice);

    vm.prank(alice);
    provider.setACLAdmin(alice);

    assertEq(provider.getACLAdmin(), alice);

    address contractAddress = address(new ACLManager(IPoolAddressesProvider(address(provider))));
    vm.expectEmit(address(provider));
    emit ACLManagerUpdated(address(0), contractAddress);

    assertEq(provider.getACLManager(), address(0));

    vm.prank(alice);
    provider.setACLManager(contractAddress);

    assertEq(provider.getACLManager(), contractAddress);

    return (provider, contractAddress);
  }

  function test_setACLManager_changeContract() public returns (PoolAddressesProvider, address) {
    (PoolAddressesProvider provider, address previousAddress) = test_setACLManager_setACLAdmin();
    address contractAddress = address(new ACLManager(IPoolAddressesProvider(address(provider))));
    vm.expectEmit(address(provider));
    emit ACLManagerUpdated(previousAddress, contractAddress);

    assertEq(provider.getACLManager(), previousAddress);

    vm.prank(alice);
    provider.setACLManager(contractAddress);

    assertEq(provider.getACLManager(), contractAddress);

    return (provider, contractAddress);
  }

  function test_setPriceOracleSentinel() public returns (PoolAddressesProvider, address) {
    PoolAddressesProvider provider = new PoolAddressesProvider('test', alice);

    address contractAddress = makeAddr('PriceOracleSentinel');
    vm.expectEmit(address(provider));
    emit PriceOracleSentinelUpdated(address(0), contractAddress);

    assertEq(provider.getPriceOracleSentinel(), address(0));

    vm.prank(alice);
    provider.setPriceOracleSentinel(contractAddress);

    assertEq(provider.getPriceOracleSentinel(), contractAddress);

    return (provider, contractAddress);
  }

  function test_setPriceOracleSentinel_changeContract()
    public
    returns (PoolAddressesProvider, address)
  {
    (PoolAddressesProvider provider, address previousAddress) = test_setPriceOracleSentinel();
    address contractAddress = makeAddr('PriceOracleSentinel_V2');
    vm.expectEmit(address(provider));
    emit PriceOracleSentinelUpdated(previousAddress, contractAddress);

    assertEq(provider.getPriceOracleSentinel(), previousAddress);

    vm.prank(alice);
    provider.setPriceOracleSentinel(contractAddress);

    assertEq(provider.getPriceOracleSentinel(), contractAddress);

    return (provider, contractAddress);
  }

  function test_setPoolDataProvider() public returns (PoolAddressesProvider, address) {
    PoolAddressesProvider provider = new PoolAddressesProvider('test', alice);

    address contractAddress = makeAddr('PoolDataProvider');

    assertEq(provider.getPoolDataProvider(), address(0));

    vm.expectEmit(address(provider));
    emit PoolDataProviderUpdated(address(0), contractAddress);

    vm.prank(alice);
    provider.setPoolDataProvider(contractAddress);

    assertEq(provider.getPoolDataProvider(), contractAddress);

    return (provider, contractAddress);
  }

  function test_PoolDataProvider_changeContract() public returns (PoolAddressesProvider, address) {
    (PoolAddressesProvider provider, address previousAddress) = test_setPoolDataProvider();
    address contractAddress = makeAddr('PoolDataProvider_V2');

    assertEq(provider.getPoolDataProvider(), previousAddress);

    vm.expectEmit(address(provider));
    emit PoolDataProviderUpdated(previousAddress, contractAddress);

    vm.prank(alice);
    provider.setPoolDataProvider(contractAddress);

    assertEq(provider.getPoolDataProvider(), contractAddress);

    return (provider, contractAddress);
  }
}
