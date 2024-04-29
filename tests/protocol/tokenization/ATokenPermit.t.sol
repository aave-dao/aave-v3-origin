// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IAToken} from '../../../src/contracts/interfaces/IAToken.sol';
import {Errors} from '../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';
import {EIP712SigUtils} from '../../utils/EIP712SigUtils.sol';

interface IATokenWithMetadata is IAToken {
  function name() external view returns (string memory);
}

contract ATokenPermitTests is TestnetProcedures {
  bytes32 internal constant EIP712_DOMAIN =
    keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)');

  IATokenWithMetadata public aToken;

  function setUp() public {
    initTestEnvironment();
    (address aUSDX, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(tokenList.usdx);
    aToken = IATokenWithMetadata(aUSDX);
  }

  function _assertDomainSeparator(
    bytes32 domainSeparator,
    string memory name,
    bytes memory revision,
    address contractAddress
  ) internal view {
    assertEq(
      domainSeparator,
      EIP712SigUtils.getDomainSeparator(bytes(name), revision, contractAddress),
      'Domain Separator do not match'
    );
  }

  function testCheckDomainSeparator() public view {
    bytes32 domainSeparator = aToken.DOMAIN_SEPARATOR();
    _assertDomainSeparator(domainSeparator, aToken.name(), bytes('1'), address(aToken));
  }

  function test_submitPermit() public {
    EIP712SigUtils.Permit memory permit = EIP712SigUtils.Permit({
      owner: alice,
      spender: bob,
      value: 1e6,
      nonce: 0,
      deadline: block.timestamp + 1 days
    });
    bytes32 digest = EIP712SigUtils.getTypedDataHash(
      permit,
      bytes(aToken.name()),
      bytes('1'),
      address(aToken)
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, digest);

    assertEq(
      aToken.allowance(alice, bob),
      0,
      'Alice allowance to bob should be zero before permit'
    );

    vm.prank(bob);
    aToken.permit(alice, bob, permit.value, permit.deadline, v, r, s);
    assertEq(
      aToken.allowance(alice, bob),
      permit.value,
      'Alice allowance does not match permit.value'
    );
    assertEq(aToken.nonces(alice), 1, 'Alice nonce does not match expected nonce');
  }

  function test_cancelPermit() public {
    // Submit permit by Alice to Bob
    test_submitPermit();

    EIP712SigUtils.Permit memory permit = EIP712SigUtils.Permit({
      owner: alice,
      spender: bob,
      value: 0,
      nonce: 1,
      deadline: block.timestamp + 1 days
    });
    bytes32 digest = EIP712SigUtils.getTypedDataHash(
      permit,
      bytes(aToken.name()),
      bytes('1'),
      address(aToken)
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, digest);

    assertEq(
      aToken.allowance(alice, bob),
      1e6,
      'Alice allowance to bob should be 1e6 before the cancel the permit'
    );

    vm.prank(bob);
    aToken.permit(alice, bob, permit.value, permit.deadline, v, r, s);
    assertEq(aToken.allowance(alice, bob), 0, 'Alice allowance to bob should be zero');
    assertEq(aToken.nonces(alice), 2, 'Alice nonce does not match expected nonce');
  }

  function test_revert_submitPermit_0_expiration() public {
    EIP712SigUtils.Permit memory permit = EIP712SigUtils.Permit({
      owner: alice,
      spender: bob,
      value: 1e6,
      nonce: 0,
      deadline: 0
    });
    bytes32 digest = EIP712SigUtils.getTypedDataHash(
      permit,
      bytes(aToken.name()),
      bytes('1'),
      address(aToken)
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, digest);

    assertEq(
      aToken.allowance(alice, bob),
      0,
      'Alice allowance to bob should be zero before permit'
    );

    vm.expectRevert(bytes(Errors.INVALID_EXPIRATION));
    vm.prank(bob);
    aToken.permit(alice, bob, permit.value, permit.deadline, v, r, s);
    assertEq(aToken.allowance(alice, bob), 0, 'Alice allowance should still be zero');
    assertEq(aToken.nonces(alice), 0, 'Alice nonce does not match expected nonce');
  }

  function test_revert_submitPermit_invalid_nonce() public {
    EIP712SigUtils.Permit memory permit = EIP712SigUtils.Permit({
      owner: alice,
      spender: bob,
      value: 1e6,
      nonce: 10,
      deadline: block.timestamp + 1 days
    });
    bytes32 digest = EIP712SigUtils.getTypedDataHash(
      permit,
      bytes(aToken.name()),
      bytes('1'),
      address(aToken)
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, digest);

    assertEq(
      aToken.allowance(alice, bob),
      0,
      'Alice allowance to bob should be zero before permit'
    );

    vm.expectRevert(bytes(Errors.INVALID_SIGNATURE));
    vm.prank(bob);
    aToken.permit(alice, bob, permit.value, permit.deadline, v, r, s);
    assertEq(aToken.allowance(alice, bob), 0, 'Alice allowance should still be zero');
    assertEq(aToken.nonces(alice), 0, 'Alice nonce does not match expected nonce');
  }

  function test_revert_submitPermit_invalid_expiration_previosCurrentBlock() public {
    EIP712SigUtils.Permit memory permit = EIP712SigUtils.Permit({
      owner: alice,
      spender: bob,
      value: 1e6,
      nonce: 0,
      deadline: 1
    });
    bytes32 digest = EIP712SigUtils.getTypedDataHash(
      permit,
      bytes(aToken.name()),
      bytes('1'),
      address(aToken)
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, digest);

    assertEq(
      aToken.allowance(alice, bob),
      0,
      'Alice allowance to bob should be zero before permit'
    );
    vm.warp(block.timestamp + 4080);

    vm.expectRevert(bytes(Errors.INVALID_EXPIRATION));
    vm.prank(bob);
    aToken.permit(alice, bob, permit.value, permit.deadline, v, r, s);
    assertEq(aToken.allowance(alice, bob), 0, 'Alice allowance should still be zero');
    assertEq(aToken.nonces(alice), 0, 'Alice nonce does not match expected nonce');
  }

  function test_revert_submitPermit_invalid_signature() public {
    EIP712SigUtils.Permit memory permit = EIP712SigUtils.Permit({
      owner: alice,
      spender: bob,
      value: 1e6,
      nonce: 0,
      deadline: 1 days
    });
    bytes32 digest = EIP712SigUtils.getTypedDataHash(
      permit,
      bytes(aToken.name()),
      bytes('1'),
      address(aToken)
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, digest);

    assertEq(
      aToken.allowance(alice, bob),
      0,
      'Alice allowance to bob should be zero before permit'
    );

    vm.expectRevert(bytes(Errors.INVALID_SIGNATURE));
    vm.prank(bob);
    aToken.permit(alice, address(0), permit.value, permit.deadline, v, r, s);
    assertEq(aToken.allowance(alice, bob), 0, 'Alice allowance should still be zero');
    assertEq(aToken.nonces(alice), 0, 'Alice nonce does not match expected nonce');
  }

  function test_revert_submitPermit_invalid_owner() public {
    EIP712SigUtils.Permit memory permit = EIP712SigUtils.Permit({
      owner: alice,
      spender: bob,
      value: 1e6,
      nonce: 0,
      deadline: 1
    });
    bytes32 digest = EIP712SigUtils.getTypedDataHash(
      permit,
      bytes(aToken.name()),
      bytes('1'),
      address(aToken)
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, digest);

    assertEq(
      aToken.allowance(alice, bob),
      0,
      'Alice allowance to bob should be zero before permit'
    );

    vm.expectRevert(bytes(Errors.ZERO_ADDRESS_NOT_VALID));
    vm.prank(bob);
    aToken.permit(address(0), bob, permit.value, permit.deadline, v, r, s);
    assertEq(aToken.allowance(alice, bob), 0, 'Alice allowance should still be zero');
    assertEq(aToken.nonces(alice), 0, 'Alice nonce does not match expected nonce');
  }

  function test_chain_fork_calculateDomainSeparator() public {
    bytes32 cachedDomainSeparator = aToken.DOMAIN_SEPARATOR();
    uint256 baseChainId = block.chainid;

    // Simulate fork to chain id 333
    vm.chainId(333);
    bytes32 forkedDomainSeparator = aToken.DOMAIN_SEPARATOR();

    assertTrue(
      cachedDomainSeparator != forkedDomainSeparator,
      'domain separator should not match cached if chain id mutates'
    );
    assertEq(
      forkedDomainSeparator,
      EIP712SigUtils.getDomainSeparator(bytes(aToken.name()), bytes('1'), address(aToken)),
      'domain separator should match calculated'
    );

    // Rollback to base chain id
    vm.chainId(baseChainId);

    assertEq(
      aToken.DOMAIN_SEPARATOR(),
      cachedDomainSeparator,
      'domain separator should match cached'
    );
  }
}
