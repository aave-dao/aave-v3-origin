// SPDX-License-Identifier: agpl-3

pragma solidity ^0.8.19;

import {console} from 'forge-std/console.sol';
import {stdStorage, StdStorage} from 'forge-std/Test.sol';
import {TestnetProcedures, TestnetERC20} from '../../utils/TestnetProcedures.sol';
import {sGHO} from '../../../src/contracts/extensions/sgho/sGHO.sol';
import {MockERC1271, IERC1271} from '../../mocks/MockERC1271.sol';
import {IAccessControl} from 'openzeppelin-contracts/contracts/access/IAccessControl.sol';
import {IERC20Permit} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol';
import {ERC20Permit} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol';
import {IERC4626} from 'openzeppelin-contracts/contracts/interfaces/IERC4626.sol';
import {IERC20Errors} from 'openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol';
import {IERC20Metadata as IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import {IsGHO} from '../../../src/contracts/extensions/sgho/interfaces/IsGHO.sol';
import {ERC4626} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol';
import {Math} from 'openzeppelin-contracts/contracts/utils/math/Math.sol';
import {TransparentUpgradeableProxy} from 'openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';

// --- Test Contract ---

contract sGhoTest is TestnetProcedures {
  using stdStorage for StdStorage;

  // Contracts
  sGHO internal sgho;
  TestnetERC20 internal gho;
  IAccessControl internal aclManager;

  // Users & Keys
  address internal user1;
  uint256 internal user1PrivateKey;
  address internal user2;
  address internal Admin;
  address internal yManager; // Yield manager user

  // Permit constants
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

    // Deploy sGHO implementation and proxy
    address sghoImpl = address(new sGHO());
    sgho = sGHO(
      payable(
        address(
          new TransparentUpgradeableProxy(
            sghoImpl,
            address(this),
            abi.encodeWithSelector(
              sGHO.initialize.selector,
              address(gho),
              address(contracts.aclManager)
            )
          )
        )
      )
    );

    deal(address(gho), address(sgho), 1 ether, true);

    // Grant YIELD_MANAGER role to yManager through ACLManager
    vm.startPrank(poolAdmin);
    aclManager = IAccessControl(address(contracts.aclManager));
    aclManager.grantRole(sgho.YIELD_MANAGER_ROLE(), yManager);
    vm.stopPrank();

    // Set target rate as yield manager
    vm.startPrank(yManager);
    sgho.setTargetRate(1000); // 10% APR
    vm.stopPrank();

    // Calculate domain separator for permits
    DOMAIN_SEPARATOR_sGHO = sgho.DOMAIN_SEPARATOR();

    // Initial GHO funding for users
    deal(address(gho), user1, 1_000_000 ether, true);
    deal(address(gho), user2, 1_000_000 ether, true);

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
    assertEq(sgho.deploymentChainId(), block.chainid, 'Chain ID mismatch');
    assertEq(sgho.VERSION(), VERSION, 'Version mismatch');
    assertEq(sgho.DOMAIN_SEPARATOR(), DOMAIN_SEPARATOR_sGHO, 'Domain separator mismatch');
  }

  // --- ERC20 Metadata Tests ---
  function test_metadata() external view {
    assertEq(sgho.name(), 'sGHO', 'Name mismatch');
    assertEq(sgho.symbol(), 'sGHO', 'Symbol mismatch');
    assertEq(sgho.decimals(), 18, 'Decimals mismatch');
  }

  // --- Receive ETH Test ---
  function test_revert_ReceiveETH() external {
    vm.expectRevert(abi.encodeWithSelector(IsGHO.NoEthAllowed.selector));
    payable(address(sgho)).transfer(1 ether);
  }

  // --- Admin functions ---
  function test_setTargetRate_event() external {
    vm.startPrank(yManager);
    uint256 newRate = 2000; // 20% APR
    vm.expectEmit(true, true, true, true, address(sgho));
    emit IsGHO.TargetRateUpdated(newRate);
    sgho.setTargetRate(newRate);
    vm.stopPrank();
    assertEq(sgho.targetRate(), newRate, 'Target rate should be updated');
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

  function test_4626_mint(uint256 shares) external {
    shares = uint256(bound(shares, 1, 100_000 ether));
    vm.startPrank(user1);

    // Preview
    uint256 previewAssets = sgho.previewMint(shares);

    // Mint
    uint256 initialGhoBalance = gho.balanceOf(user1);
    uint256 initialSghoBalance = sgho.balanceOf(user1);
    uint256 assets = sgho.mint(shares, user1);

    assertEq(assets, previewAssets, 'Assets mismatch');
    assertEq(sgho.balanceOf(user1), initialSghoBalance + shares, 'sGHO balance mismatch');
    assertEq(gho.balanceOf(user1), initialGhoBalance - assets, 'GHO balance mismatch');
    assertEq(sgho.totalAssets(), assets, 'totalAssets mismatch after mint');
    assertEq(sgho.totalSupply(), shares, 'totalSupply mismatch after mint');

    vm.stopPrank();
  }

  function test_4626_withdraw_redeem_preview(
    uint256 depositAmount,
    uint256 withdrawAmount
  ) external {
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

  function test_4626_redeem(uint256 depositAmount, uint256 redeemShares) external {
    depositAmount = uint256(bound(depositAmount, 1, 100_000 ether));

    // Initial deposit
    vm.startPrank(user1);
    uint256 sharesDeposited = sgho.deposit(depositAmount, user1);
    vm.assume(redeemShares <= sharesDeposited);
    redeemShares = uint256(bound(redeemShares, 1, sharesDeposited));

    // Preview
    uint256 previewAssets = sgho.previewRedeem(redeemShares);

    // Redeem
    uint256 initialGhoBalance = gho.balanceOf(user1);
    uint256 initialSghoBalance = sgho.balanceOf(user1);
    uint256 assetsRedeemed = sgho.redeem(redeemShares, user1, user1);

    assertApproxEqAbs(assetsRedeemed, previewAssets, 1, 'Assets redeemed mismatch');
    assertApproxEqAbs(
      sgho.balanceOf(user1),
      initialSghoBalance - redeemShares,
      1,
      'sGHO balance mismatch after redeem'
    );
    assertEq(
      gho.balanceOf(user1),
      initialGhoBalance + assetsRedeemed,
      'GHO balance mismatch after redeem'
    );
    assertApproxEqAbs(
      sgho.totalAssets(),
      depositAmount - assetsRedeemed,
      1,
      'totalAssets mismatch after redeem'
    );
    assertApproxEqAbs(
      sgho.totalSupply(),
      sharesDeposited - redeemShares,
      1,
      'totalSupply mismatch after redeem'
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

  function test_revert_4626_withdraw_max() external {
    vm.startPrank(user1);
    uint256 depositAmount = 100 ether;
    sgho.deposit(depositAmount, user1);

    uint256 maxAssets = sgho.maxWithdraw(user1);
    uint256 withdrawAmount = maxAssets + 1;

    vm.expectRevert(
      abi.encodeWithSelector(
        ERC4626.ERC4626ExceededMaxWithdraw.selector,
        user1,
        withdrawAmount,
        maxAssets
      )
    );
    sgho.withdraw(withdrawAmount, user1, user1);

    vm.stopPrank();
  }

  function test_revert_4626_redeem_max() external {
    vm.startPrank(user1);
    uint256 depositAmount = 100 ether;
    sgho.deposit(depositAmount, user1);

    uint256 maxShares = sgho.maxRedeem(user1);
    uint256 redeemShares = maxShares + 1;

    vm.expectRevert(
      abi.encodeWithSelector(
        ERC4626.ERC4626ExceededMaxRedeem.selector,
        user1,
        redeemShares,
        maxShares
      )
    );
    sgho.redeem(redeemShares, user1, user1);

    vm.stopPrank();
  }

  // --- Yield Integration Tests (_updateVault) ---

  function test_yield_claimSavingsIntegration(uint256 depositAmount, uint64 timeSkip) external {
    depositAmount = uint256(bound(depositAmount, 1 ether, 100_000 ether));
    timeSkip = uint64(bound(timeSkip, 1, 30 days)); // No minimum time requirement in new implementation

    // Initial deposit
    vm.startPrank(user1);
    uint256 initialBalance = gho.balanceOf(address(sgho));
    uint256 initialTotalAssets = sgho.totalAssets();
    console.log('Initial balance:', initialBalance);
    console.log('Initial totalAssets:', initialTotalAssets);
    console.log('Initial Yield index:', sgho.yieldIndex());

    sgho.deposit(depositAmount, user1);

    uint256 finalBalance = gho.balanceOf(address(sgho));
    uint256 finalTotalAssets = sgho.totalAssets();
    console.log('Final balance:', finalBalance);
    console.log('Final totalAssets:', finalTotalAssets);
    console.log('Deposit amount:', depositAmount);
    console.log('Final Yield index:', sgho.yieldIndex());

    assertEq(sgho.totalAssets(), depositAmount, 'Initial totalAssets');

    // Skip time and trigger _updateVault via another deposit
    vm.warp(block.timestamp + timeSkip);
    uint256 depositAmount2 = 1 ether;
    deal(address(gho), user1, depositAmount2, true); // Ensure user1 has more GHO
    gho.approve(address(sgho), depositAmount2);
    sgho.deposit(depositAmount2, user1); // This deposit triggers _updateVault

    // Calculate expected yield based on time elapsed and target rate
    uint256 expectedYield = (depositAmount * sgho.vaultAPR() * timeSkip) / (10000 * 365 days);
    uint256 expectedAssets = depositAmount + expectedYield + depositAmount2;

    console.log('after skip totalAssets:', sgho.totalAssets());
    console.log('after skip balance:', gho.balanceOf(address(sgho)));
    console.log('after skip totalSupply:', sgho.totalSupply());
    console.log('after skip yield index:', sgho.yieldIndex());

    assertApproxEqAbs(
      sgho.totalAssets(),
      expectedAssets,
      1,
      'totalAssets mismatch after yield claim'
    );

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

  function test_yield_10_percent_one_year() external {
    // Set target rate to 10% APR
    vm.startPrank(yManager);
    sgho.setTargetRate(1000); // 10% APR is 1000 bps
    vm.stopPrank();

    // User1 deposits 100 GHO
    uint256 depositAmount = 100 ether;
    vm.startPrank(user1);
    sgho.deposit(depositAmount, user1);

    assertEq(sgho.totalAssets(), depositAmount, 'Initial total assets should be deposit amount');

    // Skip time by 365 days
    uint256 timeSkip = 365 days;
    vm.warp(block.timestamp + timeSkip);

    // Trigger yield update by a small deposit.
    // Any state-changing action that calls `_updateVault` would work.
    uint256 smallDeposit = 1 wei;
    deal(address(gho), user1, smallDeposit, true);
    gho.approve(address(sgho), smallDeposit);
    sgho.deposit(smallDeposit, user1);

    // After 1 year at 10% APR, the 100 GHO should have become ~110 GHO.
    // The total assets will be ~110 GHO + the small deposit.
    uint256 expectedYield = (depositAmount * 1000) / 10000;
    uint256 expectedTotalAssets = depositAmount + expectedYield + smallDeposit;

    assertApproxEqAbs(
      sgho.totalAssets(),
      expectedTotalAssets,
      1,
      'Total assets should reflect 10% yield after 1 year'
    );

    // Also check the value of user1's shares
    uint256 user1Shares = sgho.balanceOf(user1);
    uint256 user1Assets = sgho.previewRedeem(user1Shares);
    assertApproxEqAbs(user1Assets, expectedTotalAssets, 1, 'User asset value should reflect 10% yield');
    vm.stopPrank();
  }

  function test_yield_is_compounded_with_intermediate_update(uint256 rate) external {
    rate = uint256(bound(rate, 100, 5000));
    vm.startPrank(yManager);
    sgho.setTargetRate(rate);
    vm.stopPrank();

    // User1 deposits 100 GHO
    uint256 depositAmount = 100 ether;
    vm.startPrank(user1);
    sgho.deposit(depositAmount, user1);
    uint256 user1Shares = sgho.balanceOf(user1);
    vm.stopPrank();

    // Warp time to the middle of the year
    for(uint i = 0; i < 365; i++) {
      vm.warp(block.timestamp + 1 days);
      vm.prank(yManager);
      sgho.setTargetRate(rate); // Re-setting the rate triggers the update
      vm.stopPrank();
    }
    // --- Verification ---
    // Get the current value of user1's shares
    uint256 user1FinalAssets = sgho.previewRedeem(user1Shares);

    // Calculate what the assets would be with simple (non-compounded) interest over 365 days
    uint256 simpleYield = (depositAmount * rate) / 10000;
    uint256 simpleInterestAssets = depositAmount + simpleYield;

    // Calculate the expected assets with daily compounding.
    // APY = (1 + APR/n)^n - 1, where n=365 for daily.
    // This is a theoretical calculation. The actual result will be slightly different
    // due to per-second interest calculation in the contract.
    uint256 WAD = 1e18;
    uint256 aprWad = (rate * WAD) / 10000;
    uint256 dailyCompoundingTerm = WAD + (aprWad / 365);

    // Calculate (1 + apr/365)^365 using a helper for WAD math to prevent overflow
    uint256 compoundedMultiplier = _wadPow(dailyCompoundingTerm, 365);
    uint256 expectedAssets = (depositAmount * compoundedMultiplier) / WAD;
    console.log('rate', rate);
    assertApproxEqAbs(
      user1FinalAssets,
      expectedAssets,
      1e6, // Use a tolerance for small differences from ideal calculation
      'Final assets should be close to theoretical daily compounded value'
    );

    // With compounding due to the intermediate update, user1's final assets should be greater than with simple interest.
    assertTrue(
      user1FinalAssets > simpleInterestAssets,
      'Compounded assets for user1 should be greater than simple interest assets'
    );
  }

  // --- Precision Tests ---
  function test_precision_multipleOperations(
    uint256[5] memory depositAmounts,
    uint256[5] memory withdrawAmounts,
    uint64[5] memory timeSkips
  ) external {
    // Bound inputs to reasonable ranges
    for (uint i = 0; i < 5; i++) {
      depositAmounts[i] = bound(depositAmounts[i], 1, 100_000 ether);
      timeSkips[i] = uint64(bound(timeSkips[i], 1, 30 days)); // No minimum time requirement
      withdrawAmounts[i] = bound(withdrawAmounts[i], 1, 100_000 ether);
    }

    // Set target rate
    vm.startPrank(yManager);
    sgho.setTargetRate(1000); // 10% APR
    vm.stopPrank();

    // Track state
    uint256 lastTotalAssets = sgho.totalAssets();
    uint256 lastYieldIndex = sgho.yieldIndex();
    uint256 totalBobShares = 0;
    uint256 totalDeposited = 0;
    uint256 totalClaimedYield = 0;
    uint256 totalWithdrawn = 0;
    uint256 totalExpectedYield = 0;

    // Perform sequence of operations
    for (uint i = 0; i < 5; i++) {
      // Skip time if not first operation
      if (i > 0) {
        vm.warp(block.timestamp + timeSkips[i]);
      }

      // Calculate expected yield for this period
      if (i > 0) {
        uint256 currentRatePerSecond = ((sgho.targetRate() * 1e27) / 365 days);
        uint256 currentIndexChangePerSecond = (lastYieldIndex * currentRatePerSecond)/10000;
        uint256 nextYieldIndex = lastYieldIndex +
          ((currentIndexChangePerSecond * timeSkips[i])/1e27);
        uint256 expectedTotalAssets = (sgho.totalSupply() * nextYieldIndex)/1e27;
        uint256 expectedYield = expectedTotalAssets - lastTotalAssets;

        totalExpectedYield += expectedYield;
        totalClaimedYield += sgho.totalAssets() - lastTotalAssets;
        assertApproxEqAbs(expectedTotalAssets, sgho.totalAssets(), 1, 'totalAssets mismatch from Yield calculation');
        assertEq(sgho.balanceOf(user1), totalBobShares, 'user1 balance mismatch from Yield calculation');
      }

      // Deposit
      vm.startPrank(user1);
      deal(address(gho), user1, depositAmounts[i], true);
      gho.approve(address(sgho), depositAmounts[i]);

      uint256 shares = sgho.deposit(depositAmounts[i], user1);
      totalDeposited += depositAmounts[i];
      totalBobShares += shares;

      // Verify deposit precision
      assertEq(sgho.balanceOf(user1), totalBobShares, 'balanceOf mismatch after deposit');
      assertEq(
        sgho.totalAssets(),
        sgho.previewRedeem(totalBobShares),
        'totalAssets mismatch after deposit'
      );
      assertEq(sgho.totalSupply(), totalBobShares, 'totalSupply mismatch after deposit');

      // Withdraw if not first operation and if we have enough balance
      if (i > 0) {
        uint256 withdrawAmount = withdrawAmounts[i];
        uint256 maxWithdrawable = sgho.maxWithdraw(user1);
        if (withdrawAmount > maxWithdrawable) {
          vm.expectRevert(
            abi.encodeWithSelector(
              ERC4626.ERC4626ExceededMaxWithdraw.selector,
              user1,
              withdrawAmount,
              maxWithdrawable
            )
          );
          sgho.withdraw(withdrawAmount, user1, user1);
        } else {
          uint256 withdrawnShares = sgho.withdraw(withdrawAmount, user1, user1);
          assertEq(
            sgho.balanceOf(user1),
            totalBobShares - withdrawnShares,
            'balanceOf mismatch after withdraw'
          );
          totalBobShares -= withdrawnShares;
          totalWithdrawn += withdrawAmount;

          // Verify withdrawal precision
          assertEq(
            sgho.totalAssets(),
            sgho.previewRedeem(totalBobShares),
            'totalAssets mismatch after withdraw'
          );
          assertApproxEqAbs(
            sgho.totalSupply(),
            totalBobShares,
            1,
            'totalSupply mismatch after withdraw'
          );
        }
      }

      // Verify share price consistency
      if (sgho.totalSupply() > 0) {
        // Calculate user's share of total assets directly instead of using share price
        uint256 userShares = sgho.balanceOf(user1);
        uint256 userAssets = sgho.previewRedeem(userShares);
        uint256 expectedUserAssets = (sgho.totalAssets() * userShares) / sgho.totalSupply();

        // Allow for 1 wei rounding error
        assertApproxEqAbs(userAssets, expectedUserAssets, 1, 'share price calculation mismatch');
      }

      lastTotalAssets = sgho.totalAssets();
      lastYieldIndex = sgho.yieldIndex();
      vm.stopPrank();
    }

    // Final checks
    vm.startPrank(user1);
    uint256 finalShares = sgho.balanceOf(user1);
    uint256 finalAssets = sgho.previewRedeem(finalShares);

    // Verify final redemption precision
    assertApproxEqAbs(finalAssets, sgho.totalAssets(), 1, 'final redemption mismatch');

    // Verify final state
    assertEq(sgho.totalSupply(), totalBobShares, 'final sgho.totalSupply mismatch');
    assertApproxEqAbs(
      sgho.totalSupply(),
      sgho.previewDeposit(sgho.totalAssets()),
      1,
      'final sgho.totalSupply preview mismatch'
    );
    assertApproxEqAbs(
      sgho.totalAssets(),
      sgho.previewRedeem(sgho.totalSupply()),
      1,
      'final sgho.totalAssets preview mismatch'
    );
    assertApproxEqAbs(
      sgho.totalAssets(),
      totalDeposited + totalClaimedYield - totalWithdrawn,
      10,
      'final sgho.totalAssets mismatch'
    );
    assertEq(sgho.balanceOf(user1), totalBobShares, 'final sgho.balance mismatch for Bob');
    vm.stopPrank();
  }

  // --- Target Rate Tests ---
  function test_setTargetRate() external {
    uint256 newRate = 2000; // 20% APR

    vm.startPrank(yManager);
    sgho.setTargetRate(newRate);
    vm.stopPrank();

    assertEq(sgho.vaultAPR(), newRate, 'Target rate not set correctly');
  }

  function test_revert_setTargetRate_notYieldManager() external {
    uint256 newRate = 2000; // 20% APR

    vm.expectRevert(abi.encodeWithSelector(IsGHO.OnlyYieldManager.selector));
    sgho.setTargetRate(newRate);
  }

  function test_revert_setTargetRate_rateGreaterThan50Percent() external {
    uint256 newRate = 5001; // 50.01% APR
    vm.startPrank(yManager);
    vm.expectRevert(abi.encodeWithSelector(IsGHO.RateMustBeLessThan50Percent.selector));
    sgho.setTargetRate(newRate);
    vm.stopPrank();
  }

  function test_vaultAPR() external {
    uint256 targetRate = 1500; // 15% APR

    vm.startPrank(yManager);
    sgho.setTargetRate(targetRate);
    vm.stopPrank();

    assertEq(sgho.vaultAPR(), targetRate, 'Vault APR mismatch');
  }

  // --- Rescue Tests ---
  function test_rescueERC20() external {
    // Deploy a mock ERC20 token
    TestnetERC20 mockToken = new TestnetERC20('Mock Token', 'MTK', 18, address(this));
    uint256 rescueAmount = 100 ether;

    // Transfer some tokens to sGHO
    deal(address(mockToken), address(sgho), rescueAmount, true);

    // Grant FUNDS_ADMIN role to Admin
    vm.startPrank(poolAdmin);
    aclManager.grantRole(sgho.FUNDS_ADMIN_ROLE(), Admin);
    vm.stopPrank();

    // Rescue tokens
    vm.startPrank(Admin);
    sgho.rescueERC20(address(mockToken), user1, rescueAmount);
    vm.stopPrank();

    assertEq(mockToken.balanceOf(user1), rescueAmount, 'Tokens not rescued correctly');
  }

  function test_rescueERC20_amountGreaterThanBalance() external {
    // Deploy a mock ERC20 token
    TestnetERC20 mockToken = new TestnetERC20('Mock Token', 'MTK', 18, address(this));
    uint256 initialAmount = 100 ether;
    uint256 rescueAmount = 200 ether;

    // Transfer some tokens to sGHO
    deal(address(mockToken), address(sgho), initialAmount, true);

    // Grant FUNDS_ADMIN role to Admin
    vm.startPrank(poolAdmin);
    aclManager.grantRole(sgho.FUNDS_ADMIN_ROLE(), Admin);
    vm.stopPrank();

    // Rescue tokens
    vm.startPrank(Admin);
    sgho.rescueERC20(address(mockToken), user1, rescueAmount);
    vm.stopPrank();

    assertEq(
      mockToken.balanceOf(user1),
      initialAmount,
      'Rescued amount should be capped at balance'
    );
  }

  function test_revert_rescueERC20_notFundsAdmin() external {
    TestnetERC20 mockToken = new TestnetERC20('Mock Token', 'MTK', 18, address(this));

    vm.expectRevert(abi.encodeWithSelector(IsGHO.OnlyFundsAdmin.selector));
    sgho.rescueERC20(address(mockToken), user1, 100 ether);
  }

  function test_revert_rescueERC20_cannotRescueGHO() external {
    vm.startPrank(poolAdmin);
    aclManager.grantRole(sgho.FUNDS_ADMIN_ROLE(), Admin);
    vm.stopPrank();

    vm.startPrank(Admin);
    vm.expectRevert(abi.encodeWithSelector(IsGHO.CannotRescueGHO.selector));
    sgho.rescueERC20(address(gho), user1, 100 ether);
    vm.stopPrank();
  }

  // --- Initialization Tests ---
  function test_initialization() external {
    // Deploy a new sGHO instance
    address impl = address(new sGHO());
    sGHO newSgho = sGHO(
      payable(
        address(
          new TransparentUpgradeableProxy(
            impl,
            address(this),
            abi.encodeWithSelector(sGHO.initialize.selector, address(gho), address(contracts.aclManager))
          )
        )
      )
    );

    // Should work after initialization
    assertEq(newSgho.totalAssets(), 0, 'Should be initialized');
  }

  function test_revert_initialize_twice() external {
    // Deploy a new sGHO instance
    address impl = address(new sGHO());
    TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
      impl,
      address(this),
      abi.encodeWithSelector(sGHO.initialize.selector, address(gho), address(contracts.aclManager))
    );

    sGHO newSgho = sGHO(payable(address(proxy)));

    // Should revert on second initialization via proxy
    vm.expectRevert();
    newSgho.initialize(address(gho), address(contracts.aclManager));
  }

  function _wadPow(uint256 base, uint256 exp) internal pure returns (uint256) {
    uint256 res = 1e18; // WAD
    while (exp > 0) {
      if (exp % 2 == 1) {
        res = (res * base) / 1e18;
      }
      base = (base * base) / 1e18;
      exp /= 2;
    }
    return res;
  }
}
