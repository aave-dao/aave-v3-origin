// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IAccessControl} from '../../src/contracts/dependencies/openzeppelin/contracts/IAccessControl.sol';
import {IERC20} from '../../src/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {TestnetRwaERC20} from '../../src/contracts/mocks/testnet-helpers/TestnetRwaERC20.sol';
import {Errors} from '../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {IPool} from '../../src/contracts/interfaces/IPool.sol';
import {IRwaAToken} from '../../src/contracts/interfaces/IRwaAToken.sol';
import {stdError} from 'forge-std/Test.sol';
import {Vm} from 'forge-std/Vm.sol';
import {RwaATokenManager, IRwaATokenManager} from '../../src/contracts/misc/RwaATokenManager.sol';
import {TestnetProcedures} from '../utils/TestnetProcedures.sol';

contract RwaATokenManagerTest is TestnetProcedures {
  struct RwaATokenInfo {
    TestnetRwaERC20 rwaToken;
    address rwaAToken;
    address rwaATokenAdmin;
  }

  address internal aBuidlAdmin;
  address internal aUstbAdmin;
  address internal aWtgxxAdmin;

  RwaATokenManager internal rwaATokenManager;

  RwaATokenInfo[] internal rwaATokenInfos;

  function setUp() public {
    initTestEnvironment();

    aBuidlAdmin = makeAddr('aBUIDL_ADMIN');
    aUstbAdmin = makeAddr('aUSTB_ADMIN');
    aWtgxxAdmin = makeAddr('aWTGXX_ADMIN');

    rwaATokenManager = RwaATokenManager(rwaATokenTransferAdmin);

    rwaATokenInfos.push(
      RwaATokenInfo({
        rwaToken: TestnetRwaERC20(tokenList.buidl),
        rwaAToken: rwaATokenList.aBuidl,
        rwaATokenAdmin: aBuidlAdmin
      })
    );
    rwaATokenInfos.push(
      RwaATokenInfo({
        rwaToken: TestnetRwaERC20(tokenList.ustb),
        rwaAToken: rwaATokenList.aUstb,
        rwaATokenAdmin: aUstbAdmin
      })
    );
    rwaATokenInfos.push(
      RwaATokenInfo({
        rwaToken: TestnetRwaERC20(tokenList.wtgxx),
        rwaAToken: rwaATokenList.aWtgxx,
        rwaATokenAdmin: aWtgxxAdmin
      })
    );
  }

  function test_authorizedATokenTransferRole() public view {
    assertEq(rwaATokenManager.AUTHORIZED_TRANSFER_ROLE(), keccak256('AUTHORIZED_TRANSFER'));
  }

  function test_fuzz_getAuthorizedTransferRole(address aToken) public view {
    assertEq(
      rwaATokenManager.getAuthorizedTransferRole(aToken),
      keccak256(abi.encode(rwaATokenManager.AUTHORIZED_TRANSFER_ROLE(), aToken))
    );
  }

  function test_getAuthorizedTransferRole() public view {
    test_fuzz_getAuthorizedTransferRole(rwaATokenList.aBuidl);
  }

  function test_fuzz_reverts_grantAuthorizedTransferRole_AccountIsMissingDefaultAdminRole(
    uint256 rwaATokenIndex,
    address sender
  ) public {
    vm.assume(sender != rwaATokenManagerOwner);

    rwaATokenIndex = bound(rwaATokenIndex, 0, rwaATokenInfos.length - 1);
    RwaATokenInfo memory rwaATokenInfo = rwaATokenInfos[rwaATokenIndex];

    vm.expectRevert(
      abi.encodePacked(
        'AccessControl: account ',
        vm.toLowercase(vm.toString(sender)),
        ' is missing role 0x0000000000000000000000000000000000000000000000000000000000000000'
      )
    );

    vm.prank(sender);
    rwaATokenManager.grantAuthorizedTransferRole(
      rwaATokenInfo.rwaAToken,
      rwaATokenInfo.rwaATokenAdmin
    );
  }

  function test_reverts_grantAuthorizedTransferRole_AccountIsMissingDefaultAdminRole() public {
    test_fuzz_reverts_grantAuthorizedTransferRole_AccountIsMissingDefaultAdminRole({
      rwaATokenIndex: 0,
      sender: poolAdmin
    });
  }

  function test_fuzz_grantAuthorizedTransferRole(uint256 rwaATokenIndex) public {
    rwaATokenIndex = bound(rwaATokenIndex, 0, rwaATokenInfos.length - 1);
    RwaATokenInfo memory rwaATokenInfo = rwaATokenInfos[rwaATokenIndex];

    vm.expectEmit(address(rwaATokenManager));
    emit IAccessControl.RoleGranted(
      rwaATokenManager.getAuthorizedTransferRole(rwaATokenInfo.rwaAToken),
      rwaATokenInfo.rwaATokenAdmin,
      rwaATokenManagerOwner
    );

    vm.prank(rwaATokenManagerOwner);
    rwaATokenManager.grantAuthorizedTransferRole(
      rwaATokenInfo.rwaAToken,
      rwaATokenInfo.rwaATokenAdmin
    );
  }

  function test_grantAuthorizedTransferRole_twice() public {
    test_fuzz_grantAuthorizedTransferRole(0);

    vm.recordLogs();

    vm.prank(rwaATokenManagerOwner);
    rwaATokenManager.grantAuthorizedTransferRole(rwaATokenList.aBuidl, aBuidlAdmin);

    // assert no event was emitted (since role was already granted)
    Vm.Log[] memory entries = vm.getRecordedLogs();
    assertEq(entries.length, 0);
  }

  function test_fuzz_reverts_revokeAuthorizedTransferRole_AccountIsMissingDefaultAdminRole(
    uint256 rwaATokenIndex,
    address sender
  ) public {
    vm.assume(sender != rwaATokenManagerOwner);

    rwaATokenIndex = bound(rwaATokenIndex, 0, rwaATokenInfos.length - 1);
    RwaATokenInfo memory rwaATokenInfo = rwaATokenInfos[rwaATokenIndex];

    vm.expectRevert(
      abi.encodePacked(
        'AccessControl: account ',
        vm.toLowercase(vm.toString(sender)),
        ' is missing role 0x0000000000000000000000000000000000000000000000000000000000000000'
      )
    );

    vm.prank(sender);
    rwaATokenManager.revokeAuthorizedTransferRole(
      rwaATokenInfo.rwaAToken,
      rwaATokenInfo.rwaATokenAdmin
    );
  }

  function test_reverts_revokeAuthorizedTransferRole_AccountIsMissingDefaultAdminRole() public {
    test_fuzz_reverts_revokeAuthorizedTransferRole_AccountIsMissingDefaultAdminRole({
      rwaATokenIndex: 0,
      sender: poolAdmin
    });
  }

  function test_fuzz_revokeAuthorizedTransferRole(uint256 rwaATokenIndex) public {
    rwaATokenIndex = bound(rwaATokenIndex, 0, rwaATokenInfos.length - 1);
    RwaATokenInfo memory rwaATokenInfo = rwaATokenInfos[rwaATokenIndex];

    test_fuzz_grantAuthorizedTransferRole(rwaATokenIndex);

    vm.expectEmit(address(rwaATokenManager));
    emit IAccessControl.RoleRevoked(
      rwaATokenManager.getAuthorizedTransferRole(rwaATokenInfo.rwaAToken),
      rwaATokenInfo.rwaATokenAdmin,
      rwaATokenManagerOwner
    );

    vm.prank(rwaATokenManagerOwner);
    rwaATokenManager.revokeAuthorizedTransferRole(
      rwaATokenInfo.rwaAToken,
      rwaATokenInfo.rwaATokenAdmin
    );
  }

  function test_fuzz_revokeAuthorizedTransferRole_NoEffect(uint256 rwaATokenIndex) public {
    rwaATokenIndex = bound(rwaATokenIndex, 0, rwaATokenInfos.length - 1);
    RwaATokenInfo memory rwaATokenInfo = rwaATokenInfos[rwaATokenIndex];

    vm.recordLogs();

    vm.prank(rwaATokenManagerOwner);
    rwaATokenManager.revokeAuthorizedTransferRole(
      rwaATokenInfo.rwaAToken,
      rwaATokenInfo.rwaATokenAdmin
    );

    // assert no event was emitted (since role was already revoked)
    Vm.Log[] memory entries = vm.getRecordedLogs();
    assertEq(entries.length, 0);
  }

  function test_fuzz_hasAuthorizedTransferRole_true(uint256 rwaATokenIndex) public {
    rwaATokenIndex = bound(rwaATokenIndex, 0, rwaATokenInfos.length - 1);
    RwaATokenInfo memory rwaATokenInfo = rwaATokenInfos[rwaATokenIndex];

    test_fuzz_grantAuthorizedTransferRole(rwaATokenIndex);

    assertTrue(
      rwaATokenManager.hasAuthorizedTransferRole(
        rwaATokenInfo.rwaAToken,
        rwaATokenInfo.rwaATokenAdmin
      )
    );
  }

  function test_fuzz_hasAuthorizedTransferRole_False(address aToken, address account) public view {
    assertFalse(rwaATokenManager.hasAuthorizedTransferRole(aToken, account));
  }

  /// @dev Grant role to aBuidl admin, then revoke role
  function test_fuzz_hasAuthorizedTransfer_False_Scenario() public {
    address aToken = rwaATokenInfos[0].rwaAToken;

    test_fuzz_hasAuthorizedTransferRole_true(0);
    test_fuzz_hasAuthorizedTransferRole_False(aToken, poolAdmin);
    test_fuzz_hasAuthorizedTransferRole_False(aToken, rwaATokenInfos[1].rwaATokenAdmin);
    test_fuzz_hasAuthorizedTransferRole_False(aToken, rwaATokenInfos[2].rwaATokenAdmin);

    vm.prank(rwaATokenManagerOwner);
    rwaATokenManager.revokeAuthorizedTransferRole(rwaATokenList.aBuidl, aBuidlAdmin);
    test_fuzz_hasAuthorizedTransferRole_False(aToken, rwaATokenInfos[1].rwaATokenAdmin);
  }

  function test_fuzz_reverts_transferRwaAToken_NotATokenTransferRole(
    uint256 rwaATokenIndex,
    address sender,
    address from,
    address to,
    uint256 amount
  ) public {
    rwaATokenIndex = bound(rwaATokenIndex, 0, rwaATokenInfos.length - 1);
    RwaATokenInfo memory rwaATokenInfo = rwaATokenInfos[rwaATokenIndex];

    vm.expectRevert(
      abi.encodePacked(
        'AccessControl: account ',
        vm.toLowercase(vm.toString(sender)),
        ' is missing role ',
        vm.toString(rwaATokenManager.getAuthorizedTransferRole(rwaATokenInfo.rwaAToken))
      )
    );

    vm.prank(sender);
    rwaATokenManager.transferRwaAToken(rwaATokenInfo.rwaAToken, from, to, amount);
  }

  function test_reverts_transferRwaAToken_NotATokenTransferRole() public {
    test_fuzz_grantAuthorizedTransferRole(0);
    test_fuzz_reverts_transferRwaAToken_NotATokenTransferRole({
      rwaATokenIndex: 0,
      sender: rwaATokenManagerOwner,
      from: alice,
      to: bob,
      amount: 0
    });
  }

  function test_fuzz_reverts_transferRwaAToken_NotEnoughBalance(
    uint256 rwaATokenIndex,
    address from,
    address to,
    uint256 amount
  ) public {
    rwaATokenIndex = bound(rwaATokenIndex, 0, rwaATokenInfos.length - 1);
    RwaATokenInfo memory rwaATokenInfo = rwaATokenInfos[rwaATokenIndex];

    amount = bound(amount, 1, type(uint128).max);

    test_fuzz_grantAuthorizedTransferRole(rwaATokenIndex);

    vm.expectRevert(stdError.arithmeticError);

    vm.prank(rwaATokenInfo.rwaATokenAdmin);
    rwaATokenManager.transferRwaAToken(rwaATokenInfo.rwaAToken, from, to, amount);
  }

  function test_fuzz_reverts_transferRwaAToken_CallerNotATokenTransferAdmin(
    uint256 rwaATokenIndex,
    address from,
    address to,
    uint256 amount
  ) public {
    rwaATokenIndex = bound(rwaATokenIndex, 0, rwaATokenInfos.length - 1);
    RwaATokenInfo memory rwaATokenInfo = rwaATokenInfos[rwaATokenIndex];

    test_fuzz_grantAuthorizedTransferRole(rwaATokenIndex);

    vm.startPrank(poolAdmin);
    IAccessControl(report.aclManager).revokeRole(
      // fetch role from aBuidl (it is the same for all RwaATokens)
      IRwaAToken(rwaATokenList.aBuidl).ATOKEN_ADMIN_ROLE(),
      rwaATokenTransferAdmin
    );
    vm.stopPrank();

    vm.expectRevert(bytes(Errors.CALLER_NOT_ATOKEN_TRANSFER_ADMIN));

    vm.prank(rwaATokenInfo.rwaATokenAdmin);
    rwaATokenManager.transferRwaAToken(rwaATokenInfo.rwaAToken, from, to, amount);
  }

  function test_fuzz_reverts_transferRwaAToken_AuthorizedTransferFails(
    uint256 rwaATokenIndex,
    address from,
    address to,
    uint256 amount
  ) public {
    rwaATokenIndex = bound(rwaATokenIndex, 0, rwaATokenInfos.length - 1);
    RwaATokenInfo memory rwaATokenInfo = rwaATokenInfos[rwaATokenIndex];

    test_fuzz_grantAuthorizedTransferRole(rwaATokenIndex);

    vm.mockCallRevert(
      rwaATokenInfo.rwaAToken,
      abi.encodeCall(IRwaAToken.authorizedTransfer, (from, to, amount)),
      bytes('INTERNAL_RWA_ATOKEN_REVERT')
    );

    vm.expectRevert(bytes('INTERNAL_RWA_ATOKEN_REVERT'));

    vm.prank(rwaATokenInfo.rwaATokenAdmin);
    rwaATokenManager.transferRwaAToken(rwaATokenInfo.rwaAToken, from, to, amount);
  }

  function test_fuzz_transferRwaAToken(
    uint256 rwaATokenIndex,
    address from,
    address to,
    uint256 amount
  ) public {
    rwaATokenIndex = bound(rwaATokenIndex, 0, rwaATokenInfos.length - 1);
    RwaATokenInfo memory rwaATokenInfo = rwaATokenInfos[rwaATokenIndex];

    vm.assume(from != report.poolAddressesProvider); // otherwise the pool proxy will not fallback);
    vm.assume(from != address(rwaATokenInfo.rwaToken) && from != rwaATokenInfo.rwaAToken);
    vm.assume(from != to);
    vm.assume(from != address(0) && to != address(0));

    amount = bound(amount, 1, type(uint128).max);

    test_fuzz_grantAuthorizedTransferRole(rwaATokenIndex);

    vm.startPrank(poolAdmin);
    rwaATokenInfo.rwaToken.authorize(from, true);
    rwaATokenInfo.rwaToken.mint(from, amount);
    vm.stopPrank();

    vm.startPrank(from);
    rwaATokenInfo.rwaToken.approve(report.poolProxy, amount);
    contracts.poolProxy.supply(address(rwaATokenInfo.rwaToken), amount, from, 0);
    vm.stopPrank();

    uint256 fromBalanceBefore = IERC20(rwaATokenInfo.rwaAToken).balanceOf(from);
    uint256 toBalanceBefore = IERC20(rwaATokenInfo.rwaAToken).balanceOf(to);

    assertEq(fromBalanceBefore, amount);
    assertEq(toBalanceBefore, 0);

    vm.expectCall(
      report.poolProxy,
      abi.encodeCall(
        IPool.finalizeTransfer,
        (address(rwaATokenInfo.rwaToken), from, to, amount, fromBalanceBefore, toBalanceBefore)
      )
    );

    vm.expectEmit(address(rwaATokenManager));
    emit IRwaATokenManager.TransferRwaAToken(
      rwaATokenInfo.rwaATokenAdmin,
      address(rwaATokenInfo.rwaAToken),
      from,
      to,
      amount
    );

    vm.prank(rwaATokenInfo.rwaATokenAdmin);
    bool success = rwaATokenManager.transferRwaAToken(rwaATokenInfo.rwaAToken, from, to, amount);

    assertTrue(success);

    assertEq(IERC20(rwaATokenInfo.rwaAToken).balanceOf(from), 0);
    assertEq(IERC20(rwaATokenInfo.rwaAToken).balanceOf(to), amount);
  }
}
