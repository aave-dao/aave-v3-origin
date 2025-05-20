// SPDX-License-Identifier: agpl-3
pragma solidity ^0.8.19;

import {console} from 'forge-std/console.sol';
import {stdStorage, StdStorage} from 'forge-std/Test.sol';
import {TestnetProcedures, TestnetERC20} from '../../utils/TestnetProcedures.sol';
import {YieldMaestro} from '../../../src/contracts/extensions/sgho/YieldMaestro.sol';
import {sGHO} from '../../../src/contracts/extensions/sgho/sGHO.sol';
import {IAccessControl} from 'openzeppelin-contracts/contracts/access/IAccessControl.sol';

contract YieldMaestroTest is TestnetProcedures {
  using stdStorage for StdStorage;

  // Contracts
  YieldMaestro internal yieldMaestro;
  sGHO internal sgho;
  TestnetERC20 internal gho;
  IAccessControl internal aclManager;

  // Users & Keys
  address internal user1;
  address internal yManager; // Yield manager
  address internal fundsAdmin; // Funds admin

  function setUp() public virtual {
    initTestEnvironment(false);

    // Users
    user1 = vm.addr(0xB0B);
    yManager = vm.addr(0xDEAD);
    fundsAdmin = vm.addr(0xCAFE);

    // Deploy contracts
    gho = new TestnetERC20('Mock GHO', 'GHO', 18, poolAdmin);
    yieldMaestro = new YieldMaestro(address(gho), address(contracts.aclManager));
    sgho = new sGHO(address(gho), address(yieldMaestro));

    // Grant roles
    vm.startPrank(poolAdmin);
    aclManager = IAccessControl(address(contracts.aclManager));
    aclManager.grantRole(yieldMaestro.YIELD_MANAGER_ROLE(), yManager);
    aclManager.grantRole(yieldMaestro.FUNDS_ADMIN_ROLE(), fundsAdmin);
    vm.stopPrank();

    // Initialize YieldMaestro
    yieldMaestro.initialize(address(sgho));

    // Fund users
    deal(address(gho), user1, 1_000_000 ether, true);
    deal(address(gho), address(yieldMaestro), 1_000_000 ether, true);
  }

  // --- Constructor Tests ---
  function test_constructor() external {
    assertEq(address(yieldMaestro.GHO()), address(gho), 'GHO address mismatch');
  }

  // --- Initialize Tests ---
  function test_initialize() external {
    assertEq(yieldMaestro.sGHO(), address(sgho), 'sGHO address mismatch');
    assertEq(yieldMaestro.lastClaimTimestamp(), block.timestamp, 'lastClaimTimestamp mismatch');
    assertEq(yieldMaestro.targetRate(), 0, 'initial targetRate should be 0');
  }

  function test_revert_initialize_alreadyInitialized() external {
    vm.expectRevert(abi.encodeWithSignature('InvalidInitialization()'));
    yieldMaestro.initialize(address(sgho));
  }

  // --- Target Rate Tests ---
  function test_setTargetRate() external {
    vm.startPrank(yManager);
    yieldMaestro.setTargetRate(1000); // 10% APR
    assertEq(yieldMaestro.targetRate(), 1000 * 1e6, 'targetRate mismatch');
    vm.stopPrank();
  }

  function test_revert_setTargetRate_notYieldManager() external {
    vm.startPrank(user1);
    vm.expectRevert(abi.encodeWithSignature('OnlyYieldManager()'));
    yieldMaestro.setTargetRate(1000);
    vm.stopPrank();
  }

  // --- Claim Savings Tests ---
  function test_claimSavings() external {
    // Set target rate
    vm.startPrank(yManager);
    yieldMaestro.setTargetRate(1000); // 10% APR
    vm.stopPrank();

    // Mock vault assets
    vm.mockCall(
      address(sgho),
      abi.encodeWithSelector(sgho.totalAssets.selector),
      abi.encode(1000 ether)
    );

    // Skip time
    vm.warp(block.timestamp + 30 days);

    // Claim savings
    vm.prank(address(sgho));
    uint256 claimed = yieldMaestro.claimSavings();

    // Calculate expected yield
    uint256 assets = 1000 ether;
    uint256 rate = 1000 * 1e6; // 10% APR
    uint256 timeElapsed = 30 days;
    uint256 expectedYield = (assets * rate) / 1e10; // First divide by precision
    expectedYield = (expectedYield * timeElapsed) / 365 days; // Then apply time factor
    assertEq(claimed, expectedYield, 'claimed amount mismatch');
    assertEq(yieldMaestro.lastClaimTimestamp(), block.timestamp, 'lastClaimTimestamp not updated');
  }

  function test_claimSavings_zeroRate() external {
    // Ensure target rate is 0
    assertEq(yieldMaestro.targetRate(), 0, 'targetRate should be 0');

    // Skip time
    vm.warp(block.timestamp + 30 days);

    // Claim savings
    vm.prank(address(sgho));
    uint256 claimed = yieldMaestro.claimSavings();

    assertEq(claimed, 0, 'should not claim when rate is 0');
    assertEq(yieldMaestro.lastClaimTimestamp(), block.timestamp, 'lastClaimTimestamp not updated');
  }

  function test_revert_claimSavings_notVault() external {
    vm.expectRevert(abi.encodeWithSignature('OnlyVault()'));
    yieldMaestro.claimSavings();
  }

  function test_claimSavings_insufficientBalance() external {
    // Set target rate
    vm.startPrank(yManager);
    yieldMaestro.setTargetRate(1000); // 10% APR
    vm.stopPrank();

    // Mock vault assets
    vm.mockCall(
      address(sgho),
      abi.encodeWithSelector(sgho.totalAssets.selector),
      abi.encode(1000 ether)
    );

    // Skip time
    vm.warp(block.timestamp + 30 days);

    // Calculate expected yield
    uint256 assets = 1000 ether;
    uint256 rate = 1000 * 1e6; // 10% APR
    uint256 timeElapsed = 30 days;
    uint256 expectedYield = (assets * rate) / 1e10; // First divide by precision
    expectedYield = (expectedYield * timeElapsed) / 365 days; // Then apply time factor

    // Ensure YieldMaestro has less balance than expected yield
    uint256 availableBalance = expectedYield / 2;
    deal(address(gho), address(yieldMaestro), availableBalance, true);

    // Claim savings
    vm.prank(address(sgho));
    uint256 claimed = yieldMaestro.claimSavings();

    // Should only claim what's available
    assertEq(claimed, availableBalance, 'should only claim available balance');
    assertEq(gho.balanceOf(address(sgho)), availableBalance, 'sGHO should receive available balance');
    assertEq(gho.balanceOf(address(yieldMaestro)), 0, 'YieldMaestro should be empty');
    assertEq(yieldMaestro.lastClaimTimestamp(), block.timestamp, 'lastClaimTimestamp not updated');
  }

  // --- Preview Claimable Tests ---
  function test_previewClaimable() external {
    // Set target rate
    vm.startPrank(yManager);
    yieldMaestro.setTargetRate(1000); // 10% APR
    vm.stopPrank();

    // Mock vault assets
    vm.mockCall(
      address(sgho),
      abi.encodeWithSelector(sgho.totalAssets.selector),
      abi.encode(1000 ether)
    );

    // Skip time
    vm.warp(block.timestamp + 30 days);

    // Preview claimable
    uint256 claimable = yieldMaestro.previewClaimable();

    // Calculate expected yield
    uint256 assets = 1000 ether;
    uint256 rate = 1000 * 1e6; // 10% APR
    uint256 timeElapsed = 30 days;
    uint256 expectedYield = (assets * rate) / 1e10; // First divide by precision
    expectedYield = (expectedYield * timeElapsed) / 365 days; // Then apply time factor
    assertEq(claimable, expectedYield, 'claimable amount mismatch');
  }

  // --- Vault APR Tests ---
  function test_vaultAPR() external {
    // Set target rate
    vm.startPrank(yManager);
    yieldMaestro.setTargetRate(1000); // 10% APR
    vm.stopPrank();

    assertEq(yieldMaestro.vaultAPR(), 1000, 'APR mismatch');
  }

  // --- Rescue ERC20 Tests ---
  function test_rescueERC20() external {
    uint256 rescueAmount = 100 ether;
    uint256 initialBalance = gho.balanceOf(fundsAdmin);

    vm.startPrank(fundsAdmin);
    yieldMaestro.rescueERC20(address(gho), fundsAdmin, rescueAmount);
    vm.stopPrank();

    assertEq(
      gho.balanceOf(fundsAdmin),
      initialBalance + rescueAmount,
      'rescue amount mismatch'
    );
  }

  function test_rescueERC20_maxAmount() external {
    uint256 maxAmount = type(uint256).max;
    uint256 actualBalance = gho.balanceOf(address(yieldMaestro));

    vm.startPrank(fundsAdmin);
    yieldMaestro.rescueERC20(address(gho), fundsAdmin, maxAmount);
    vm.stopPrank();

    assertEq(gho.balanceOf(fundsAdmin), actualBalance, 'should rescue actual balance');
  }

  function test_revert_rescueERC20_notFundsAdmin() external {
    vm.startPrank(user1);
    vm.expectRevert(abi.encodeWithSignature('OnlyFundsAdmin()'));
    yieldMaestro.rescueERC20(address(gho), user1, 100 ether);
    vm.stopPrank();
  }

  // --- Receive Tests ---
  function test_revert_receive() external {
    vm.expectRevert('No ETH allowed');
    payable(address(yieldMaestro)).transfer(1 ether);
  }

  // --- APR Calculation Tests ---
  function test_APRCalculation_OneYear() external {
    // Set target rate to 1000 (10%)
    vm.startPrank(yManager);
    yieldMaestro.setTargetRate(1000);
    vm.stopPrank();

    // Set initial vault assets to 1000 GHO
    vm.startPrank(user1);
    gho.approve(address(sgho), 1000 ether);
    sgho.deposit(1000 ether, address(user1));
    vm.stopPrank();

    // Move forward 1 year
    vm.warp(block.timestamp + 365 days);

    // Get initial total assets
    uint256 initialAssets = sgho.totalAssets();
    assertEq(initialAssets, 1000 ether, 'should be 1000 GHO');

    // Claim savings
    vm.prank(address(sgho));
    uint256 claimed = yieldMaestro.claimSavings();

    // Verify claimed amount is exactly 10% of initial assets
    assertEq(claimed, 100 ether, 'should claim exactly 10% after 1 year');
    assertEq(gho.balanceOf(address(sgho)), initialAssets + claimed, 'sGHO should receive 10% yield');
  }
} 