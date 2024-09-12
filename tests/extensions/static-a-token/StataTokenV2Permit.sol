// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {ERC20PermitUpgradeable} from 'openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PermitUpgradeable.sol';
import {SigUtils} from '../../utils/SigUtils.sol';
import {BaseTest} from './TestBase.sol';

contract StataTokenV2PermitTest is BaseTest {
  function test_permit() public {
    SigUtils.Permit memory permit = SigUtils.Permit({
      owner: user,
      spender: spender,
      value: 1 ether,
      nonce: stataTokenV2.nonces(user),
      deadline: block.timestamp + 1 days
    });

    bytes32 permitDigest = SigUtils.getTypedDataHash(
      permit,
      SigUtils.PERMIT_TYPEHASH,
      stataTokenV2.DOMAIN_SEPARATOR()
    );
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, permitDigest);

    stataTokenV2.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);

    assertEq(stataTokenV2.allowance(permit.owner, spender), permit.value);
  }

  function test_permit_expired() public {
    // as the default timestamp is 0, we move ahead in time a bit
    vm.warp(10 days);

    SigUtils.Permit memory permit = SigUtils.Permit({
      owner: user,
      spender: spender,
      value: 1 ether,
      nonce: stataTokenV2.nonces(user),
      deadline: block.timestamp - 1 days
    });

    bytes32 permitDigest = SigUtils.getTypedDataHash(
      permit,
      SigUtils.PERMIT_TYPEHASH,
      stataTokenV2.DOMAIN_SEPARATOR()
    );
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, permitDigest);

    vm.expectRevert(
      abi.encodeWithSelector(
        ERC20PermitUpgradeable.ERC2612ExpiredSignature.selector,
        permit.deadline
      )
    );
    stataTokenV2.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);
  }

  function test_permit_invalidSigner() public {
    SigUtils.Permit memory permit = SigUtils.Permit({
      owner: address(424242),
      spender: spender,
      value: 1 ether,
      nonce: stataTokenV2.nonces(user),
      deadline: block.timestamp + 1 days
    });

    bytes32 permitDigest = SigUtils.getTypedDataHash(
      permit,
      SigUtils.PERMIT_TYPEHASH,
      stataTokenV2.DOMAIN_SEPARATOR()
    );
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, permitDigest);

    vm.expectRevert(
      abi.encodeWithSelector(
        ERC20PermitUpgradeable.ERC2612InvalidSigner.selector,
        user,
        permit.owner
      )
    );
    stataTokenV2.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);
  }
}
