// SPDX-License-Identifier: agpl-3

pragma solidity ^0.8.19;

import {console} from 'forge-std/console.sol';
import {stdStorage, StdStorage} from 'forge-std/Test.sol';
import {TestnetProcedures, TestnetERC20} from '../../utils/TestnetProcedures.sol';
import {sGHO, IERC1271} from '../../../src/contracts/extensions/sgho/sGHO.sol';
import {YieldMaestro} from '../../../src/contracts/extensions/sgho/YieldMaestro.sol';
import {IAccessControl} from 'openzeppelin-contracts/contracts/access/IAccessControl.sol';
import {IERC20Permit} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol';
import {IERC4626} from 'openzeppelin-contracts/contracts/interfaces/IERC4626.sol';
import {IERC20Errors} from 'openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol';
import {IERC20Metadata as IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';

// --- Test Contract ---

contract sGhoTest is TestnetProcedures {
  using stdStorage for StdStorage;

  // Contracts
  sGHO internal sgho;
  TestnetERC20 internal gho;
  YieldMaestro internal yieldMaestro;
  IAccessControl internal aclManager;

  // Users & Keys
  address internal user1;
  uint256 internal user1PrivateKey;
  address internal user2;
  address internal Admin;
  address internal yManager; // Yield manager user

  // Permit constants
  bytes32 internal constant PERMIT_TYPEHASH =
    keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');
  string internal constant VERSION = '1'; // Matches sGHO constructor
  bytes32 internal DOMAIN_SEPARATOR_sGHO;

  function setUp() public virtual {
    initTestEnvironment(false); // Use TestnetProcedures setup

    // Users
    user1PrivateKey = 0xB0B;
    user1 = vm.addr(user1PrivateKey);
    user2 = vm.addr(0xCAFE);
    Admin = address(this);
    yManager = vm.addr(0xDEAD); // Yield manager address

    // Deploy Mocks & sGHO
    gho = new TestnetERC20('Mock GHO', 'GHO', 18, poolAdmin);

    // Deploy YieldMaestro first
    yieldMaestro = new YieldMaestro(address(gho), address(contracts.aclManager));

    // Deploy sGHO with YieldMaestro address
    sgho = new sGHO(address(gho), address(yieldMaestro));
    deal(address(gho), address(sgho), 1 ether, true);
    // Initialize YieldMaestro with sGHO address
    yieldMaestro.initialize(address(sgho));

    // Grant YIELD_MANAGER role to yManager through ACLManager
    vm.startPrank(poolAdmin);
    aclManager = IAccessControl(address(contracts.aclManager));
    aclManager.grantRole(yieldMaestro.YIELD_MANAGER_ROLE(), yManager);
    vm.stopPrank();

    // Set target rate as yield manager
    vm.startPrank(yManager);
    yieldMaestro.setTargetRate(1000); // 10% APR
    vm.stopPrank();

    // Calculate domain separator for permits
    DOMAIN_SEPARATOR_sGHO = sgho.DOMAIN_SEPARATOR();

    // Initial GHO funding for users
    deal(address(gho), user1, 1_000_000 ether, true);
    deal(address(gho), user2, 1_000_000 ether, true);
    deal(address(gho), address(yieldMaestro), 1_000_000 ether, true);

    // Approve sGHO to spend user GHO
    vm.startPrank(user1);
    gho.approve(address(sgho), type(uint256).max);
    vm.stopPrank();
    vm.startPrank(user2);
    gho.approve(address(sgho), type(uint256).max);
    vm.stopPrank();
  }

  // --- Constructor Tests ---

  function test_constructor() external {
    assertEq(sgho.gho(), address(gho), 'GHO address mismatch');
    assertEq(sgho.YIELD_MAESTRO(), address(yieldMaestro), 'YieldMaestro address mismatch');
    assertEq(sgho.deploymentChainId(), block.chainid, 'Chain ID mismatch');
    assertEq(sgho.VERSION(), VERSION, 'Version mismatch');
    assertEq(sgho.PERMIT_TYPEHASH(), PERMIT_TYPEHASH, 'Permit typehash mismatch');
  }

  // --- Receive ETH Test ---
  function test_revert_ReceiveETH() external {
    vm.expectRevert('No ETH allowed');
    payable(address(sgho)).transfer(1 ether);
  }

  // --- ERC4626 Tests ---

  function test_4626_initialState() external view {
    assertEq(sgho.asset(), address(gho), 'Asset mismatch');
    assertEq(sgho.totalAssets(), 0, 'Initial totalAssets mismatch');
    assertEq(sgho.totalSupply(), 0, 'Initial totalSupply mismatch');
    assertEq(sgho.decimals(), gho.decimals(), 'Decimals mismatch'); // Inherits ERC20 decimals
  }

  function test_4626_deposit_mint_preview(uint256 amount) external {
    amount = uint256(bound(amount, 1, 100_000 ether));
    vm.startPrank(user1);

    // Preview
    uint256 previewShares = sgho.previewDeposit(amount);
    uint256 previewAssets = sgho.previewMint(previewShares);
    assertEq(previewAssets, amount, 'Preview mismatch deposit/mint'); // Should be 1:1 initially
    assertEq(sgho.convertToShares(amount), previewShares, 'convertToShares mismatch');
    assertEq(sgho.convertToAssets(previewShares), amount, 'convertToAssets mismatch');

    // Deposit
    uint256 initialGhoBalance = gho.balanceOf(user1);
    uint256 initialSghoBalance = sgho.balanceOf(user1);
    uint256 shares = sgho.deposit(amount, user1);

    assertEq(shares, previewShares, 'Shares mismatch');
    assertEq(sgho.balanceOf(user1), initialSghoBalance + shares, 'sGHO balance mismatch');
    assertEq(gho.balanceOf(user1), initialGhoBalance - amount, 'GHO balance mismatch');
    assertEq(sgho.totalAssets(), amount, 'totalAssets mismatch after deposit');
    assertEq(sgho.totalSupply(), shares, 'totalSupply mismatch after deposit');

    vm.stopPrank();
  }

  function test_4626_withdraw_redeem_preview(uint256 depositAmount, uint256 withdrawAmount) external {
    depositAmount = uint256(bound(depositAmount, 1, 100_000 ether));
    vm.assume(withdrawAmount <= depositAmount);
    withdrawAmount = uint256(bound(withdrawAmount, 1, depositAmount));

    // Initial deposit
    vm.startPrank(user1);
    uint256 sharesDeposited = sgho.deposit(depositAmount, user1);

    // Preview
    uint256 previewShares = sgho.previewWithdraw(withdrawAmount);
    uint256 previewAssets = sgho.previewRedeem(previewShares);
    // Allow for rounding differences if ratio != 1
    assertApproxEqAbs(previewAssets, withdrawAmount, 1, 'Preview mismatch withdraw/redeem');

    // Withdraw
    uint256 initialGhoBalance = gho.balanceOf(user1);
    uint256 initialSghoBalance = sgho.balanceOf(user1);
    uint256 sharesWithdrawn = sgho.withdraw(withdrawAmount, user1, user1);

    assertApproxEqAbs(sharesWithdrawn, previewShares, 1, 'Shares withdrawn mismatch');
    assertApproxEqAbs(
      sgho.balanceOf(user1),
      initialSghoBalance - sharesWithdrawn,
      1,
      'sGHO balance mismatch after withdraw'
    );
    assertEq(
      gho.balanceOf(user1),
      initialGhoBalance + withdrawAmount,
      'GHO balance mismatch after withdraw'
    );
    assertApproxEqAbs(
      sgho.totalAssets(),
      depositAmount - withdrawAmount,
      1,
      'totalAssets mismatch after withdraw'
    );
    assertApproxEqAbs(
      sgho.totalSupply(),
      sharesDeposited - sharesWithdrawn,
      1,
      'totalSupply mismatch after withdraw'
    );

    vm.stopPrank();
  }

  function test_4626_maxMethods() external {
    // Deposit max checks (no limits implemented in this sGHO version)
    assertEq(sgho.maxDeposit(user1), type(uint256).max, 'maxDeposit should be max');
    assertEq(sgho.maxMint(user1), type(uint256).max, 'maxMint should be max');

    // Withdraw max checks
    vm.startPrank(user1);
    uint256 depositAmount = 100 ether;
    sgho.deposit(depositAmount, user1);
    uint256 shares = sgho.balanceOf(user1);

    assertEq(sgho.maxWithdraw(user1), depositAmount, 'maxWithdraw mismatch');
    assertEq(sgho.maxRedeem(user1), shares, 'maxRedeem mismatch');
    vm.stopPrank();
  }

  // --- Permit Tests ---
  function test_permit() external {
    uint256 privateKey = 0xA11CE;
    address owner = vm.addr(privateKey);
    address spender = user2;
    uint256 value = 100 ether;
    uint256 deadline = block.timestamp + 1 hours;
    uint256 nonce = sgho.nonces(owner);

    // Create permit signature
    bytes32 structHash = keccak256(
      abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonce, deadline)
    );
    bytes32 hash = keccak256(
      abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR_sGHO, structHash)
    );
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, hash);

    // Execute permit
    sgho.permit(owner, spender, value, deadline, v, r, s);

    assertEq(sgho.allowance(owner, spender), value, 'Allowance not set correctly');
  }

  function test_revert_permit_expired() external {
    uint256 privateKey = 0xA11CE;
    address owner = vm.addr(privateKey);
    address spender = user2;
    uint256 value = 100 ether;
    uint256 deadline = block.timestamp - 1; // Expired
    uint256 nonce = sgho.nonces(owner);

    bytes32 structHash = keccak256(
      abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonce, deadline)
    );
    bytes32 hash = keccak256(
      abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR_sGHO, structHash)
    );
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, hash);

    vm.expectRevert('SavingsXDai/permit-expired');
    sgho.permit(owner, spender, value, deadline, v, r, s);
  }

  function test_revert_permit_invalidSignature() external {
    uint256 privateKey = 0xA11CE;
    address owner = vm.addr(privateKey);
    address spender = user2;
    uint256 value = 100 ether;
    uint256 deadline = block.timestamp + 1 hours;
    uint256 nonce = sgho.nonces(owner);

    bytes32 structHash = keccak256(
      abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonce, deadline)
    );
    bytes32 hash = keccak256(
      abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR_sGHO, structHash)
    );
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, hash);

    // Use wrong owner
    vm.expectRevert('SavingsXDai/invalid-permit');
    sgho.permit(user1, spender, value, deadline, v, r, s);
  }

  // --- Yield Integration Tests (_updateVault) ---

  function test_yield_claimSavingsIntegration(
    uint256 depositAmount,
    uint64 timeSkip
  ) external {
    depositAmount = uint256(bound(depositAmount, 1 ether, 100_000 ether));
    timeSkip = uint64(bound(timeSkip, 601, 30 days)); // Ensure > 600s

    // Initial deposit
    vm.startPrank(user1);
    uint256 initialBalance = gho.balanceOf(address(sgho));
    uint256 initialTotalAssets = sgho.totalAssets();
    console.log('Initial balance:', initialBalance);
    console.log('Initial totalAssets:', initialTotalAssets);
    
    sgho.deposit(depositAmount, user1);
    
    uint256 finalBalance = gho.balanceOf(address(sgho));
    uint256 finalTotalAssets = sgho.totalAssets();
    console.log('Final balance:', finalBalance);
    console.log('Final totalAssets:', finalTotalAssets);
    console.log('Deposit amount:', depositAmount);
    
    assertEq(sgho.totalAssets(), depositAmount, 'Initial totalAssets');

    // Skip time and trigger _updateVault via another deposit
    vm.warp(block.timestamp + timeSkip);
    uint256 depositAmount2 = 1 ether;
    deal(address(gho), user1, depositAmount2, true); // Ensure user1 has more GHO
    gho.approve(address(sgho), depositAmount2);
    sgho.deposit(depositAmount2, user1); // This deposit triggers _updateVault

    // Calculate expected yield based on time elapsed and target rate
    uint256 expectedYield = (depositAmount * yieldMaestro.targetRate() * timeSkip) / (1e10 * 365 days);
    uint256 expectedAssets = depositAmount + expectedYield + depositAmount2;
    assertEq(sgho.totalAssets(), expectedAssets, 'totalAssets mismatch after yield claim');

    // Check if withdraw/redeem reflects yield (share price > 1)
    uint256 shares = sgho.balanceOf(user1);
    uint256 expectedWithdrawAssets = sgho.previewRedeem(shares);
    assertTrue(
      expectedWithdrawAssets > depositAmount + depositAmount2,
      'Assets per share should increase with yield'
    );
    assertApproxEqAbs(
      expectedWithdrawAssets,
      expectedAssets,
      1,
      'Preview redeem should equal total assets'
    ); // Single depositor case
    vm.stopPrank();
  }

  function test_yield_noClaimIfTimeSkipLow(
    uint256 depositAmount,
    uint64 timeSkip,
    uint256 yieldAmount
  ) external {
    depositAmount = uint256(bound(depositAmount, 1 ether, 100_000 ether));
    timeSkip = uint64(bound(timeSkip, 1, 599)); // Ensure <= 600s
    yieldAmount = uint256(bound(yieldAmount, 1 wei, 1_000 ether));

    // Initial deposit
    vm.startPrank(user1);
    sgho.deposit(depositAmount, user1);

    assertEq(sgho.totalAssets(), depositAmount);

    // Skip time and trigger _updateVault via another deposit
    vm.warp(block.timestamp + timeSkip);
    uint256 depositAmount2 = 1 ether;

    // Ensure user1 has enough GHO for second deposit
    deal(address(gho), user1, depositAmount2, true);

    gho.approve(address(sgho), depositAmount2);
    sgho.deposit(depositAmount2, user1); // This deposit triggers _updateVault
    vm.stopPrank();

    // Check yield was NOT added
    uint256 expectedAssets = depositAmount + depositAmount2;
    assertEq(sgho.totalAssets(), expectedAssets, 'totalAssets should not include yield');
  }

  // --- Precision Tests ---
  function test_precision_multipleOperations(
    uint256[5] memory depositAmounts,
    uint256[5] memory withdrawAmounts,
    uint64[5] memory timeSkips
  ) external {
    // Bound inputs to reasonable ranges
    for (uint i = 0; i < 5; i++) {
      depositAmounts[i] = bound(depositAmounts[i], 1 ether, 100_000 ether);
      timeSkips[i] = uint64(bound(timeSkips[i], 601, 30 days)); // Ensure > 600s
    }

    // Set target rate
    vm.startPrank(yManager);
    yieldMaestro.setTargetRate(1000); // 10% APR
    vm.stopPrank();

    // Track state
    uint256 lastTotalAssets = 0;
    uint256 totalShares = 0;
    uint256 totalDeposited = 0;
    uint256 totalClaimedYield = 0;
    uint256 totalWithdrawn = 0;

    // Perform sequence of operations
    for (uint i = 0; i < 5; i++) {
      // Skip time if not first operation
      if (i > 0) {
        vm.warp(block.timestamp + timeSkips[i]);
      }

      // Deposit
      vm.startPrank(user1);
      deal(address(gho), user1, depositAmounts[i], true);
      gho.approve(address(sgho), depositAmounts[i]);
      
      uint256 shares = sgho.deposit(depositAmounts[i], user1);
      totalDeposited += depositAmounts[i];
      totalShares += shares;

      // Calculate expected yield for this period
      if (i > 0) {
        uint256 expectedYield = (lastTotalAssets * yieldMaestro.targetRate() * timeSkips[i]) / (1e10 * 365 days);
        totalClaimedYield += expectedYield;
      }

      // Verify deposit precision
      assertEq(
        sgho.totalAssets(),
        totalDeposited + totalClaimedYield - totalWithdrawn,
        'totalAssets mismatch after deposit'
      );
      assertEq(
        sgho.totalSupply(),
        totalShares,
        'totalSupply mismatch after deposit'
      );

      // Withdraw if not first operation and if we have enough balance
      if (i > 0 && withdrawAmounts[i] <= sgho.balanceOf(user1)) {
        uint256 withdrawAmount = bound(withdrawAmounts[i], 1 ether, sgho.balanceOf(user1));
        uint256 withdrawnShares = sgho.withdraw(withdrawAmount, user1, user1);
        totalShares -= withdrawnShares;
        totalWithdrawn += withdrawAmount;

        // Verify withdrawal precision
        assertApproxEqAbs(
          sgho.totalAssets(),
          totalDeposited + totalClaimedYield - totalWithdrawn,
          1,
          'totalAssets mismatch after withdraw'
        );
        assertApproxEqAbs(
          sgho.totalSupply(),
          totalShares,
          1,
          'totalSupply mismatch after withdraw'
        );
      }

      // Verify share price consistency
      if (sgho.totalSupply() > 0) {
        // Calculate user's share of total assets directly instead of using share price
        uint256 userShares = sgho.balanceOf(user1);
        uint256 userAssets = sgho.previewRedeem(userShares);
        uint256 expectedUserAssets = (sgho.totalAssets() * userShares) / sgho.totalSupply();
        
        // Allow for 1 wei rounding error
        assertApproxEqAbs(
          userAssets,
          expectedUserAssets,
          1,
          'share price calculation mismatch'
        );
      }

      // Verify yield calculation precision
      if (i > 0) {
        uint256 expectedYield = (lastTotalAssets * yieldMaestro.targetRate() * timeSkips[i]) / (1e10 * 365 days);
        // Calculate actual yield by comparing total assets before and after the operation
        uint256 actualYield = sgho.totalAssets() + totalWithdrawn - totalDeposited ;
        
        // Allow for 1 wei rounding error in yield calculation
        assertApproxEqAbs(
          actualYield,
          totalClaimedYield,
          1,
          'yield calculation mismatch'
        );
      }

      lastTotalAssets = sgho.totalAssets();
      vm.stopPrank();
    }

    // Final checks
    vm.startPrank(user1);
    uint256 finalShares = sgho.balanceOf(user1);
    uint256 finalAssets = sgho.previewRedeem(finalShares);
    
    // Verify final redemption precision
    assertApproxEqAbs(
      finalAssets,
      sgho.totalAssets(),
      1,
      'final redemption mismatch'
    );
    vm.stopPrank();
  }

  // --- takeDonated() Test ---
  function test_takeDonated() external {
    uint256 depositAmount = 100 ether;
    uint256 donatedAmount = 50 ether;

    uint256 sghoBalanceInitial = gho.balanceOf(address(sgho));

    // User deposits
    vm.prank(user1);
    sgho.deposit(depositAmount, user1);
    assertEq(sgho.totalAssets(), depositAmount);
    assertEq(gho.balanceOf(address(sgho)), depositAmount + sghoBalanceInitial);

    // Simulate external donation (direct transfer)
    deal(address(gho), address(sgho), gho.balanceOf(address(sgho)) + donatedAmount); // Force balance increase
    assertEq(gho.balanceOf(address(sgho)), depositAmount + donatedAmount + sghoBalanceInitial);

    // Check YieldMaestro balance before
    uint256 ymBalanceBefore = gho.balanceOf(address(yieldMaestro));

    // Call takeDonated
    sgho.takeDonated();

    // Check balances after
    assertEq(sgho.totalAssets(), depositAmount, 'totalAssets should be unchanged'); // Should not change internal accounting
    assertEq(
      gho.balanceOf(address(sgho)),
      depositAmount,
      'sGHO GHO balance should revert to totalAssets'
    );
    assertEq(
      gho.balanceOf(address(yieldMaestro)),
      ymBalanceBefore + donatedAmount + sghoBalanceInitial,
      'YieldMaestro should receive donated amount'
    );
  }
}
