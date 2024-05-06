// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {ATokenInstance} from '../../../src/contracts/instances/ATokenInstance.sol';
import {IAaveIncentivesController} from '../../../src/contracts/interfaces/IAaveIncentivesController.sol';
import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';
import {Errors} from '../../../src/contracts/protocol/libraries/helpers/Errors.sol';

contract ATokenEdgeCasesTests is TestnetProcedures {
  ATokenInstance public aToken;
  address public ZERO_ADDRESS = address(0);

  event Transfer(address indexed from, address indexed to, uint256 amount);

  function setUp() public {
    initTestEnvironment();

    (address aUSDX, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(tokenList.usdx);
    aToken = ATokenInstance(aUSDX);
  }

  function testCheckGetters() public {
    assertEq(aToken.decimals(), usdx.decimals(), 'Decimals mismatch');
    assertEq(aToken.UNDERLYING_ASSET_ADDRESS(), address(usdx), 'Underlying asset address mismatch');
    assertEq(address(aToken.POOL()), address(contracts.poolProxy), 'Pool address mismatch');
    assertEq(
      address(aToken.getIncentivesController()),
      address(contracts.rewardsControllerProxy),
      'Incentives controller is not zero address'
    );

    (uint256 userBalanceBefore, uint256 supplyBefore) = aToken.getScaledUserBalanceAndSupply(alice);
    assertEq(userBalanceBefore, 0, 'Initial user balance is non-zero');
    assertEq(supplyBefore, 0, 'Initial supply is non-zero');

    uint256 mintAmount = 1000e6;
    vm.prank(poolAdmin);
    usdx.mint(alice, mintAmount);

    vm.startPrank(alice);
    usdx.approve(address(contracts.poolProxy), mintAmount);
    contracts.poolProxy.deposit(address(usdx), mintAmount, alice, 0);

    (uint256 userBalanceAfter, uint256 supplyAfter) = aToken.getScaledUserBalanceAndSupply(alice);
    uint256 expectedBalance = mintAmount;
    vm.stopPrank();

    assertEq(userBalanceAfter, expectedBalance, 'User balance mismatch after deposit');
    assertEq(supplyAfter, expectedBalance, 'Supply mismatch after deposit');
  }

  function testApproveMax() public {
    vm.prank(alice);
    aToken.approve(bob, UINT256_MAX);
    assertEq(aToken.allowance(alice, bob), UINT256_MAX, 'Max allowance mismatch after approve');
  }

  function testApprove() public {
    vm.prank(alice);
    aToken.approve(bob, 9999);
    assertEq(aToken.allowance(alice, bob), 9999, 'Allowance mismatch after approve');
  }

  function testApproveWithZeroAddressSpender() public {
    vm.prank(alice);
    aToken.approve(ZERO_ADDRESS, UINT256_MAX);
  }

  function testTransferFromZeroAmount() public {
    vm.prank(alice);
    aToken.transferFrom(alice, bob, 0);
  }

  function testIncreaseAllowanceFromZero() public {
    assertEq(aToken.allowance(bob, alice), 0, 'Initial allowance should be zero');

    vm.prank(bob);
    aToken.increaseAllowance(alice, 1e6);

    assertEq(aToken.allowance(bob, alice), 1e6, 'Allowance mismatch after increaseAllowance');
  }

  function testIncreaseAllowance() public {
    assertEq(aToken.allowance(bob, alice), 0, 'Initial allowance should be zero');

    vm.startPrank(bob);
    aToken.increaseAllowance(alice, 1e6);
    aToken.increaseAllowance(alice, 1e6);
    vm.stopPrank();

    assertEq(aToken.allowance(bob, alice), 2e6, 'Allowance mismatch after increaseAllowance');
  }

  function testDecreaseAllowance() public {
    assertEq(aToken.allowance(bob, alice), 0, 'Initial allowance should be zero');
    vm.startPrank(bob);

    aToken.increaseAllowance(alice, 10e6);
    aToken.decreaseAllowance(alice, 1e6);
    vm.stopPrank();

    assertEq(aToken.allowance(bob, alice), 9e6, 'Allowance mismatch after decreaseAllowance');
  }

  function test_transferFrom_zeroAddress_origin() public {
    vm.expectEmit(address(aToken));

    emit Transfer(address(0), alice, 0);

    aToken.transferFrom(address(0), alice, 0);
  }

  function test_reverts_mintAmountScaledZero() public {
    vm.expectRevert(bytes(Errors.INVALID_MINT_AMOUNT));
    vm.prank(address(contracts.poolProxy));
    aToken.mint(alice, alice, 0, 1e27);
  }

  function test_mintToZeroAddress() public {
    uint256 mintAmount = 100e6;

    vm.expectEmit(address(aToken));

    emit Transfer(address(0), address(0), mintAmount);

    vm.prank(address(contracts.poolProxy));
    aToken.mint(address(0), address(0), mintAmount, 1e27);
  }

  function test_reverts_burnAmountScaledZero() public {
    vm.expectRevert(bytes(Errors.INVALID_BURN_AMOUNT));
    vm.prank(address(contracts.poolProxy));
    aToken.burn(alice, alice, 0, 1e27);
  }

  function test_burn_zeroAddress() public {
    uint256 burnAmount = 100e6;
    vm.expectEmit(address(aToken));

    emit Transfer(address(0), address(0), burnAmount);

    vm.startPrank(address(contracts.poolProxy));

    deal(address(usdx), address(aToken), burnAmount);

    aToken.mint(address(0), address(0), burnAmount, 1e27);
    aToken.burn(address(0), alice, burnAmount, 1e27);
    vm.stopPrank();
  }

  function testMintToTreasury_amount_zero() public {
    vm.prank(address(contracts.poolProxy));

    aToken.mintToTreasury(0, 1e27);
  }

  function test_poolAdmin_setIncentivesController() public {
    address incentivesContract = makeAddr('incentives');

    vm.prank(poolAdmin);

    aToken.setIncentivesController(IAaveIncentivesController(incentivesContract));

    assertEq(address(aToken.getIncentivesController()), incentivesContract);
  }

  function test_revert_notAdmin_setIncentivesController() public {
    address incentivesContract = makeAddr('incentives');

    vm.prank(alice);
    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    aToken.setIncentivesController(IAaveIncentivesController(incentivesContract));

    assertEq(address(aToken.getIncentivesController()), report.rewardsControllerProxy);
  }

  function test_transfer_amount_MAX_UINT_128() public {
    vm.expectRevert(bytes("SafeCast: value doesn't fit in 128 bits"));
    aToken.transfer(alice, UINT256_MAX);
  }
}
