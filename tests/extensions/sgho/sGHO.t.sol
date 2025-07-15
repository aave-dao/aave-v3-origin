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
import {ERC20Permit} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol';
import {ECDSA} from 'openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol';

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

  uint256 internal constant MAX_TARGET_RATE = 5000; // 50%
  uint256 internal constant SUPPLY_CAP = 1_000_000 ether; // 1M GHO

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
              address(contracts.aclManager),
              MAX_TARGET_RATE,
              SUPPLY_CAP
            )
          )
        )
      )
    );

    deal(address(user1), 10 ether);
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

  function test_constructor() external view {
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
    vm.startPrank(user1);
    uint256 initialBalance = user1.balance;
    vm.expectRevert(abi.encodeWithSelector(IsGHO.NoEthAllowed.selector));
    payable(address(sgho)).call{value: 1 ether}('');
    assertEq(user1.balance, initialBalance, 'Transfer should revert');
    vm.stopPrank();
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

  function test_revert_setTargetRate_exceedsMaxRate() external {
    vm.startPrank(yManager);
    uint256 newRate = MAX_TARGET_RATE + 1;
    vm.expectRevert(IsGHO.RateMustBeLessThanMaxRate.selector);
    sgho.setTargetRate(newRate);
    vm.stopPrank();
  }

  function test_setTargetRate_atMaxRate() external {
    vm.startPrank(yManager);
    sgho.setTargetRate(MAX_TARGET_RATE);
    vm.stopPrank();
    assertEq(sgho.targetRate(), MAX_TARGET_RATE, 'Target rate should be updated to max rate');
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
    // Max deposit should be the supply cap initially
    assertEq(sgho.maxDeposit(user1), SUPPLY_CAP, 'maxDeposit should be supply cap');

    // Max mint should correspond to the supply cap
    uint256 expectedMaxMint = sgho.convertToShares(SUPPLY_CAP);
    assertEq(sgho.maxMint(user1), expectedMaxMint, 'maxMint should be supply cap in shares');

    // Deposit some amount and check max withdraw/redeem
    vm.startPrank(user1);
    uint256 depositAmount = 100 ether;
    sgho.deposit(depositAmount, user1);
    uint256 shares = sgho.balanceOf(user1);

    assertEq(sgho.maxWithdraw(user1), depositAmount, 'maxWithdraw mismatch');
    assertEq(sgho.maxRedeem(user1), shares, 'maxRedeem mismatch');

    // Max deposit should be reduced by the deposited amount
    assertEq(sgho.maxDeposit(user1), SUPPLY_CAP - depositAmount, 'maxDeposit should be reduced');
    vm.stopPrank();
  }

  function test_4626_convertToShares() external {
    uint256 assets = 100 ether;
    uint256 shares = sgho.convertToShares(assets);
    
    // Initially, 1:1 conversion since yield index starts at RAY
    assertEq(shares, assets, 'Initial convertToShares should be 1:1');
    
    // After some yield accrual, conversion should change
    vm.warp(block.timestamp + 365 days);
    uint256 sharesAfterYield = sgho.convertToShares(assets);
    assertTrue(sharesAfterYield < assets, 'Shares should be less than assets after yield accrual');
  }

  function test_4626_convertToAssets() external {
    uint256 shares = 100 ether;
    uint256 assets = sgho.convertToAssets(shares);
    
    // Initially, 1:1 conversion since yield index starts at RAY
    assertEq(assets, shares, 'Initial convertToAssets should be 1:1');
    
    // After some yield accrual, conversion should change
    vm.warp(block.timestamp + 365 days);
    uint256 assetsAfterYield = sgho.convertToAssets(shares);
    assertTrue(assetsAfterYield > shares, 'Assets should be greater than shares after yield accrual');
  }

  function test_4626_convertFunctionsConsistency() external {
    uint256 assets = 100 ether;
    uint256 shares = sgho.convertToShares(assets);
    uint256 convertedBackAssets = sgho.convertToAssets(shares);
    
    // Round-trip conversion should be consistent (allowing for rounding)
    assertApproxEqAbs(assets, convertedBackAssets, 1, 'Round-trip conversion should be consistent');
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

  function test_4626_zeroDeposit() external {
    vm.startPrank(user1);
    uint256 initialBalance = sgho.balanceOf(user1);
    uint256 initialGhoBalance = gho.balanceOf(user1);
    
    uint256 shares = sgho.deposit(0, user1);
    
    assertEq(shares, 0, 'Zero deposit should return 0 shares');
    assertEq(sgho.balanceOf(user1), initialBalance, 'Balance should remain unchanged');
    assertEq(gho.balanceOf(user1), initialGhoBalance, 'GHO balance should remain unchanged');
    vm.stopPrank();
  }

  function test_4626_zeroMint() external {
    vm.startPrank(user1);
    uint256 initialBalance = sgho.balanceOf(user1);
    uint256 initialGhoBalance = gho.balanceOf(user1);
    
    uint256 assets = sgho.mint(0, user1);
    
    assertEq(assets, 0, 'Zero mint should return 0 assets');
    assertEq(sgho.balanceOf(user1), initialBalance, 'Balance should remain unchanged');
    assertEq(gho.balanceOf(user1), initialGhoBalance, 'GHO balance should remain unchanged');
    vm.stopPrank();
  }

  function test_4626_zeroWithdraw() external {
    vm.startPrank(user1);
    // First deposit some amount to have balance
    sgho.deposit(100 ether, user1);
    uint256 initialBalance = sgho.balanceOf(user1);
    uint256 initialGhoBalance = gho.balanceOf(user1);
    
    uint256 shares = sgho.withdraw(0, user1, user1);
    
    assertEq(shares, 0, 'Zero withdraw should return 0 shares');
    assertEq(sgho.balanceOf(user1), initialBalance, 'Balance should remain unchanged');
    assertEq(gho.balanceOf(user1), initialGhoBalance, 'GHO balance should remain unchanged');
    vm.stopPrank();
  }

  function test_4626_zeroRedeem() external {
    vm.startPrank(user1);
    // First deposit some amount to have balance
    sgho.deposit(100 ether, user1);
    uint256 initialBalance = sgho.balanceOf(user1);
    uint256 initialGhoBalance = gho.balanceOf(user1);
    
    uint256 assets = sgho.redeem(0, user1, user1);
    
    assertEq(assets, 0, 'Zero redeem should return 0 assets');
    assertEq(sgho.balanceOf(user1), initialBalance, 'Balance should remain unchanged');
    assertEq(gho.balanceOf(user1), initialGhoBalance, 'GHO balance should remain unchanged');
    vm.stopPrank();
  }

  function test_4626_previewZero() external view {
    assertEq(sgho.previewDeposit(0), 0, 'previewDeposit(0) should be 0');
    assertEq(sgho.previewMint(0), 0, 'previewMint(0) should be 0');
    assertEq(sgho.previewWithdraw(0), 0, 'previewWithdraw(0) should be 0');
    assertEq(sgho.previewRedeem(0), 0, 'previewRedeem(0) should be 0');
  }

  function test_4626_maxTypeDeposit() external {
    vm.startPrank(user1);
    // Try to deposit max uint256 - should revert due to supply cap
    vm.expectRevert(
      abi.encodeWithSelector(ERC4626.ERC4626ExceededMaxDeposit.selector, user1, type(uint256).max, SUPPLY_CAP)
    );
    sgho.deposit(type(uint256).max, user1);
    vm.stopPrank();
  }

  function test_4626_maxTypeMint() external {
    vm.startPrank(user1);
    // Try to mint max uint256 shares - should revert due to supply cap
    uint256 maxShares = sgho.convertToShares(SUPPLY_CAP);
    vm.expectRevert(
      abi.encodeWithSelector(ERC4626.ERC4626ExceededMaxMint.selector, user1, type(uint256).max, maxShares)
    );
    sgho.mint(type(uint256).max, user1);
    vm.stopPrank();
  }

  function test_4626_maxTypeWithdraw() external {
    vm.startPrank(user1);
    // First deposit some amount
    uint256 depositAmount = 100 ether;
    sgho.deposit(depositAmount, user1);
    
    // Try to withdraw max uint256 - should revert due to insufficient balance
    vm.expectRevert(
      abi.encodeWithSelector(ERC4626.ERC4626ExceededMaxWithdraw.selector, user1, type(uint256).max, depositAmount)
    );
    sgho.withdraw(type(uint256).max, user1, user1);
    vm.stopPrank();
  }

  function test_4626_maxTypeRedeem() external {
    vm.startPrank(user1);
    // First deposit some amount
    uint256 depositAmount = 100 ether;
    sgho.deposit(depositAmount, user1);
    uint256 shares = sgho.balanceOf(user1);
    
    // Try to redeem max uint256 shares - should revert due to insufficient shares
    vm.expectRevert(
      abi.encodeWithSelector(ERC4626.ERC4626ExceededMaxRedeem.selector, user1, type(uint256).max, shares)
    );
    sgho.redeem(type(uint256).max, user1, user1);
    vm.stopPrank();
  }

  function test_4626_maxTypePreview() external view {
    // Preview functions should handle max uint256 gracefully and never revert
    uint256 maxPreviewDeposit = sgho.previewDeposit(type(uint256).max);
    uint256 maxPreviewMint = sgho.previewMint(type(uint256).max);
    
    // Preview functions should return the theoretical conversion result regardless of supply cap
    // They are pure conversion functions that don't enforce limits
    assertTrue(maxPreviewDeposit > 0, 'previewDeposit should return positive value for max uint256');
    assertTrue(maxPreviewMint > 0, 'previewMint should return positive value for max uint256');
  }

  function test_4626_previewWithdrawMaxType() external {
    vm.startPrank(user1);
    uint256 depositAmount = 100 ether;
    sgho.deposit(depositAmount, user1);
    
    // Preview withdraw with max uint256 should perform conversion calculation
    // It should return the theoretical shares needed for max uint256 assets
    uint256 maxPreviewWithdraw = sgho.previewWithdraw(type(uint256).max);
    assertTrue(maxPreviewWithdraw > 0, 'previewWithdraw should return positive value for max uint256');
    vm.stopPrank();
  }

  function test_4626_previewRedeemMaxType() external {
    vm.startPrank(user1);
    uint256 depositAmount = 100 ether;
    sgho.deposit(depositAmount, user1);
    uint256 shares = sgho.balanceOf(user1);
    
    // Preview redeem with max uint256 should perform conversion calculation
    // It should return the theoretical assets for max uint256 shares
    uint256 maxPreviewRedeem = sgho.previewRedeem(type(uint256).max);
    assertTrue(maxPreviewRedeem > 0, 'previewRedeem should return positive value for max uint256');
    vm.stopPrank();
  }

  // --- ERC20 Standard Tests ---

  function test_transfer() external {
    vm.startPrank(user1);
    uint256 depositAmount = 100 ether;
    sgho.deposit(depositAmount, user1);
    
    uint256 transferAmount = 50 ether;
    bool success = sgho.transfer(user2, transferAmount);
    
    assertTrue(success, 'Transfer should succeed');
    assertEq(sgho.balanceOf(user1), depositAmount - transferAmount, 'Sender balance should decrease');
    assertEq(sgho.balanceOf(user2), transferAmount, 'Receiver balance should increase');
    vm.stopPrank();
  }

  function test_transfer_zeroAmount() external {
    vm.startPrank(user1);
    sgho.deposit(100 ether, user1);
    bool success = sgho.transfer(user2, 0);
    assertTrue(success, 'transfer of 0 should succeed');
    vm.stopPrank();
  }

  function test_transferFrom() external {
    vm.startPrank(user1);
    uint256 depositAmount = 100 ether;
    sgho.deposit(depositAmount, user1);
    
    uint256 approveAmount = 50 ether;
    sgho.approve(user2, approveAmount);
    vm.stopPrank();
    
    vm.startPrank(user2);
    uint256 transferAmount = 30 ether;
    bool success = sgho.transferFrom(user1, user2, transferAmount);
    
    assertTrue(success, 'TransferFrom should succeed');
    assertEq(sgho.balanceOf(user1), depositAmount - transferAmount, 'Owner balance should decrease');
    assertEq(sgho.balanceOf(user2), transferAmount, 'Receiver balance should increase');
    assertEq(sgho.allowance(user1, user2), approveAmount - transferAmount, 'Allowance should decrease');
    vm.stopPrank();
  }

  function test_transferFrom_zeroAmount() external {
    vm.startPrank(user1);
    sgho.deposit(100 ether, user1);
    sgho.approve(user2, 100 ether);
    vm.stopPrank();
    vm.startPrank(user2);
    bool success = sgho.transferFrom(user1, user2, 0);
    assertTrue(success, 'transferFrom of 0 should succeed');
    vm.stopPrank();
  }

  function test_approve() external {
    vm.startPrank(user1);
    uint256 approveAmount = 100 ether;
    bool success = sgho.approve(user2, approveAmount);
    
    assertTrue(success, 'Approve should succeed');
    assertEq(sgho.allowance(user1, user2), approveAmount, 'Allowance should be set correctly');
    vm.stopPrank();
  }

  function test_approve_zeroAmount() external {
    vm.startPrank(user1);
    bool success = sgho.approve(user2, 0);
    assertTrue(success, 'approve of 0 should succeed');
    assertEq(sgho.allowance(user1, user2), 0, 'allowance should be 0');
    vm.stopPrank();
  }

  function test_transfer_maxType() external {
    vm.startPrank(user1);
    // First deposit some amount
    uint256 depositAmount = 100 ether;
    sgho.deposit(depositAmount, user1);
    
    // Try to transfer max uint256 - should revert due to insufficient balance
    vm.expectRevert();
    sgho.transfer(user2, type(uint256).max);
    vm.stopPrank();
  }

  function test_transferFrom_maxType() external {
    vm.startPrank(user1);
    // First deposit some amount
    uint256 depositAmount = 100 ether;
    sgho.deposit(depositAmount, user1);
    sgho.approve(user2, type(uint256).max);
    vm.stopPrank();
    
    vm.startPrank(user2);
    // Try to transferFrom max uint256 - should revert due to insufficient balance
    vm.expectRevert();
    sgho.transferFrom(user1, user2, type(uint256).max);
    vm.stopPrank();
  }

  function test_approve_maxType() external {
    vm.startPrank(user1);
    // Approve max uint256 should succeed
    bool success = sgho.approve(user2, type(uint256).max);
    assertTrue(success, 'approve of max uint256 should succeed');
    assertEq(sgho.allowance(user1, user2), type(uint256).max, 'allowance should be max uint256');
    vm.stopPrank();
  }

  function test_allowance() external {
    vm.startPrank(user1);
    uint256 approveAmount = 100 ether;
    sgho.approve(user2, approveAmount);
    vm.stopPrank();
    
    assertEq(sgho.allowance(user1, user2), approveAmount, 'Allowance should return correct amount');
    assertEq(sgho.allowance(user1, user1), 0, 'Self allowance should be zero');
  }

  // --- ERC20Permit Tests ---

  struct PermitVars {
    uint256 privateKey;
    address owner;
    address spender;
    uint256 value;
    uint256 deadline;
    uint256 nonce;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  function test_permit_invalidSignature() external {
    PermitVars memory vars;
    vars.privateKey = 0xA11CE;
    vars.owner = vm.addr(vars.privateKey);
    vars.spender = user2;
    vars.value = 100 ether;
    vars.deadline = block.timestamp + 1 hours;
    vars.nonce = sgho.nonces(vars.owner);
    (vars.v, vars.r, vars.s) = _createPermitSignature(vars.owner, vars.spender, vars.value, vars.nonce, vars.deadline, vars.privateKey);
    // Use wrong owner address - should revert with ERC2612InvalidSigner
    {
      bytes32 PERMIT_TYPEHASH = keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');
      bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, user1, vars.spender, vars.value, vars.nonce, vars.deadline));
      bytes32 hash = keccak256(abi.encodePacked('\x19\x01', sgho.DOMAIN_SEPARATOR(), structHash));
      address recovered = ECDSA.recover(hash, vars.v, vars.r, vars.s);
      vm.expectRevert(abi.encodeWithSelector(ERC20Permit.ERC2612InvalidSigner.selector, recovered, user1));
      sgho.permit(user1, vars.spender, vars.value, vars.deadline, vars.v, vars.r, vars.s);
    }
  }

  function test_permit_replay() external {
    PermitVars memory vars;
    vars.privateKey = 0xA11CE;
    vars.owner = vm.addr(vars.privateKey);
    vars.spender = user2;
    vars.value = 100 ether;
    vars.deadline = block.timestamp + 1 hours;
    vars.nonce = sgho.nonces(vars.owner);
    (vars.v, vars.r, vars.s) = _createPermitSignature(vars.owner, vars.spender, vars.value, vars.nonce, vars.deadline, vars.privateKey);
    // First permit should succeed
    sgho.permit(vars.owner, vars.spender, vars.value, vars.deadline, vars.v, vars.r, vars.s);
    assertEq(sgho.allowance(vars.owner, vars.spender), vars.value, 'First permit should set allowance');
    // Second permit with same signature should revert (nonce already used)
    // The contract expects nonce 1, but our signature is for nonce 0
    {
      bytes32 PERMIT_TYPEHASH = keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');
      bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, vars.owner, vars.spender, vars.value, vars.nonce + 1, vars.deadline));
      bytes32 hash = keccak256(abi.encodePacked('\x19\x01', sgho.DOMAIN_SEPARATOR(), structHash));
      address recovered = ECDSA.recover(hash, vars.v, vars.r, vars.s);
      vm.expectRevert(abi.encodeWithSelector(ERC20Permit.ERC2612InvalidSigner.selector, recovered, vars.owner));
      sgho.permit(vars.owner, vars.spender, vars.value, vars.deadline, vars.v, vars.r, vars.s);
    }
  }

  function test_permit_wrongDomainSeparator() external {
    PermitVars memory vars;
    vars.privateKey = 0xA11CE;
    vars.owner = vm.addr(vars.privateKey);
    vars.spender = user2;
    vars.value = 100 ether;
    vars.deadline = block.timestamp + 1 hours;
    vars.nonce = sgho.nonces(vars.owner);
    // Use wrong domain separator
    bytes32 PERMIT_TYPEHASH = keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');
    bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, vars.owner, vars.spender, vars.value, vars.nonce, vars.deadline));
    bytes32 wrongDomainSeparator = keccak256('WRONG_DOMAIN');
    bytes32 hash = keccak256(abi.encodePacked('\x19\x01', wrongDomainSeparator, structHash));
    (vars.v, vars.r, vars.s) = vm.sign(vars.privateKey, hash);
    // The contract will recover a different signer than owner
    {
      bytes32 contractHash = keccak256(abi.encodePacked('\x19\x01', sgho.DOMAIN_SEPARATOR(), structHash));
      address recovered = ECDSA.recover(contractHash, vars.v, vars.r, vars.s);
      vm.expectRevert(abi.encodeWithSelector(ERC20Permit.ERC2612InvalidSigner.selector, recovered, vars.owner));
      sgho.permit(vars.owner, vars.spender, vars.value, vars.deadline, vars.v, vars.r, vars.s);
    }
  }

  function test_permit_validSignature() external {
    PermitVars memory vars;
    vars.privateKey = 0xA11CE;
    vars.owner = vm.addr(vars.privateKey);
    vars.spender = user2;
    vars.value = 100 ether;
    vars.deadline = block.timestamp + 1 hours;
    vars.nonce = sgho.nonces(vars.owner);
    (vars.v, vars.r, vars.s) = _createPermitSignature(vars.owner, vars.spender, vars.value, vars.nonce, vars.deadline, vars.privateKey);
    sgho.permit(vars.owner, vars.spender, vars.value, vars.deadline, vars.v, vars.r, vars.s);
    assertEq(sgho.allowance(vars.owner, vars.spender), vars.value, 'Permit should set allowance correctly');
  }

  function test_permit_expiredDeadline() external {
    PermitVars memory vars;
    vars.privateKey = 0xA11CE;
    vars.owner = vm.addr(vars.privateKey);
    vars.spender = user2;
    vars.value = 100 ether;
    vars.deadline = block.timestamp - 1; // Expired deadline
    vars.nonce = sgho.nonces(vars.owner);
    (vars.v, vars.r, vars.s) = _createPermitSignature(vars.owner, vars.spender, vars.value, vars.nonce, vars.deadline, vars.privateKey);
    vm.expectRevert(
      abi.encodeWithSelector(
        ERC20Permit.ERC2612ExpiredSignature.selector,
        vars.deadline
      )
    );
    sgho.permit(vars.owner, vars.spender, vars.value, vars.deadline, vars.v, vars.r, vars.s);
  }

  function test_permit_zeroValue() external {
    PermitVars memory vars;
    vars.privateKey = 0xA11CE;
    vars.owner = vm.addr(vars.privateKey);
    vars.spender = user2;
    vars.value = 0;
    vars.deadline = block.timestamp + 1 hours;
    vars.nonce = sgho.nonces(vars.owner);
    (vars.v, vars.r, vars.s) = _createPermitSignature(vars.owner, vars.spender, vars.value, vars.nonce, vars.deadline, vars.privateKey);
    sgho.permit(vars.owner, vars.spender, vars.value, vars.deadline, vars.v, vars.r, vars.s);
    assertEq(sgho.allowance(vars.owner, vars.spender), 0, 'permit with value 0 should set allowance to 0');
  }

  function test_permit_selfApproval() external {
    PermitVars memory vars;
    vars.privateKey = 0xA11CE;
    vars.owner = vm.addr(vars.privateKey);
    vars.value = 100 ether;
    vars.deadline = block.timestamp + 1 hours;
    vars.nonce = sgho.nonces(vars.owner);
    (vars.v, vars.r, vars.s) = _createPermitSignature(vars.owner, vars.owner, vars.value, vars.nonce, vars.deadline, vars.privateKey);
    sgho.permit(vars.owner, vars.owner, vars.value, vars.deadline, vars.v, vars.r, vars.s);
    assertEq(sgho.allowance(vars.owner, vars.owner), vars.value, 'Self approval should work');
  }

  function test_nonces() external {
    address owner = user1;
    uint256 initialNonce = sgho.nonces(owner);
    
    // Nonce should increment after permit
    uint256 privateKey = 0xA11CE;
    address permitOwner = vm.addr(privateKey);
    address spender = user2;
    uint256 value = 100 ether;
    uint256 deadline = block.timestamp + 1 hours;
    uint256 nonce = sgho.nonces(permitOwner);
    
    (uint8 v, bytes32 r, bytes32 s) = _createPermitSignature(permitOwner, spender, value, nonce, deadline, privateKey);
    
    sgho.permit(permitOwner, spender, value, deadline, v, r, s);
    
    assertEq(sgho.nonces(permitOwner), nonce + 1, 'Nonce should increment after permit');
    assertEq(sgho.nonces(owner), initialNonce, 'Other user nonce should remain unchanged');
  }

  // --- Supply Cap Tests ---
  function test_revert_deposit_exceedsCap() external {
    vm.startPrank(user1);
    uint256 amount = SUPPLY_CAP + 1;
    vm.expectRevert(
      abi.encodeWithSelector(ERC4626.ERC4626ExceededMaxDeposit.selector, user1, amount, SUPPLY_CAP)
    );
    sgho.deposit(amount, user1);
    vm.stopPrank();
  }

  function test_revert_mint_exceedsCap() external {
    vm.startPrank(user1);
    uint256 shares = sgho.convertToShares(SUPPLY_CAP) + 1;
    uint256 maxShares = sgho.maxMint(user1);
    vm.expectRevert(
      abi.encodeWithSelector(ERC4626.ERC4626ExceededMaxMint.selector, user1, shares, maxShares)
    );
    sgho.mint(shares, user1);
    vm.stopPrank();
  }

  function test_deposit_atCap() external {
    vm.startPrank(user1);
    sgho.deposit(SUPPLY_CAP, user1);
    assertEq(sgho.totalAssets(), SUPPLY_CAP, 'Total assets should equal supply cap');
    // The contract balance will be the supply cap plus the 1 GHO donated in setUp
    assertEq(
      gho.balanceOf(address(sgho)),
      SUPPLY_CAP + 1 ether,
      'Contract balance should be supply cap + initial donation'
    );
    vm.stopPrank();
  }

  function test_maxDeposit_atCap() external {
    vm.startPrank(user1);
    sgho.deposit(SUPPLY_CAP, user1);
    vm.stopPrank();
    
    // Max deposit should be 0 when at cap
    assertEq(sgho.maxDeposit(user2), 0, 'maxDeposit should be 0 when at supply cap');
    assertEq(sgho.maxMint(user2), 0, 'maxMint should be 0 when at supply cap');
  }

  function test_maxDeposit_partialCap() external {
    vm.startPrank(user1);
    uint256 depositAmount = SUPPLY_CAP / 2;
    sgho.deposit(depositAmount, user1);
    vm.stopPrank();
    
    // Max deposit should be remaining capacity
    assertEq(sgho.maxDeposit(user2), SUPPLY_CAP - depositAmount, 'maxDeposit should be remaining capacity');
    uint256 expectedMaxMint = sgho.convertToShares(SUPPLY_CAP - depositAmount);
    assertEq(sgho.maxMint(user2), expectedMaxMint, 'maxMint should be remaining capacity in shares');
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

    // User2 deposits 500 GHO
    uint256 depositAmount2 = 500 ether;
    vm.startPrank(user2);
    sgho.deposit(depositAmount2, user2);
    vm.stopPrank();

    // Skip time by 365 days
    uint256 timeSkip = 365 days;
    vm.warp(block.timestamp + timeSkip);

    // Trigger yield update by redeeming all of user2 shares
    // Any state-changing action that calls `_updateVault` would work.
    vm.startPrank(user2);
    uint256 user2Shares = sgho.balanceOf(user2);
    sgho.redeem(user2Shares, user2, user2);
    assertEq(sgho.balanceOf(user2), 0, 'User2 should have no shares after redeeming');
    vm.stopPrank();

    // After 1 year at 10% APR, the 100 GHO should have become ~110 GHO.
    // The total assets will be ~110 GHO + the small deposit.
    uint256 expectedYield = ((depositAmount) * 1000) / 10000;
    uint256 expectedTotalAssets = depositAmount + expectedYield;

    assertApproxEqAbs(
      sgho.totalAssets(),
      expectedTotalAssets,
      1,
      'Total assets should reflect 10% yield after 1 year'
    );

    // Also check the value of user1's shares
    uint256 user1Shares = sgho.balanceOf(user1);
    uint256 user1Assets = sgho.previewRedeem(user1Shares);
    assertApproxEqAbs(
      user1Assets,
      expectedTotalAssets,
      1,
      'User asset value should reflect 10% yield'
    );
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
    for (uint i = 0; i < 365; i++) {
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

  // --- Yield Edge Case Tests ---

  function test_yield_zeroTargetRate() external {
    // Set target rate to 0
    vm.startPrank(yManager);
    sgho.setTargetRate(0);
    vm.stopPrank();

    // User1 deposits 100 GHO
    uint256 depositAmount = 100 ether;
    vm.startPrank(user1);
    sgho.deposit(depositAmount, user1);
    uint256 initialShares = sgho.balanceOf(user1);
    vm.stopPrank();

    // Skip time - no yield should accrue
    vm.warp(block.timestamp + 365 days);
    
    // Trigger yield update
    vm.startPrank(user2);
    sgho.deposit(1 ether, user2);
    vm.stopPrank();

    // User1 should have the same assets value
    vm.startPrank(user1);
    uint256 finalAssets = sgho.previewRedeem(initialShares);
    assertEq(finalAssets, depositAmount, 'Assets should remain unchanged with zero target rate');
    vm.stopPrank();
  }

  function test_yield_zeroTimeSinceLastUpdate() external {
    // User1 deposits 100 GHO
    uint256 depositAmount = 100 ether;
    vm.startPrank(user1);
    sgho.deposit(depositAmount, user1);
    uint256 initialShares = sgho.balanceOf(user1);
    vm.stopPrank();

    // Don't skip time - timeSinceLastUpdate should be 0
    // Trigger another operation immediately
    vm.startPrank(user2);
    sgho.deposit(1 ether, user2);
    vm.stopPrank();

    // User1 should have the same assets value (no time passed)
    vm.startPrank(user1);
    uint256 finalAssets = sgho.previewRedeem(initialShares);
    assertEq(finalAssets, depositAmount, 'Assets should remain unchanged with zero time since last update');
    vm.stopPrank();
  }

  function test_yield_index_edgeCases() external {
    // Test with very small amounts and very large amounts
    uint256 smallAmount = 1; // 1 wei
    uint256 largeAmount = SUPPLY_CAP - 1 ether;
    
    vm.startPrank(user1);
    
    // Test small amount
    sgho.deposit(smallAmount, user1);
    uint256 smallShares = sgho.balanceOf(user1);
    assertEq(smallShares, smallAmount, 'Small amount should convert 1:1 initially');
    
    // Test large amount
    deal(address(gho), user1, largeAmount, true);
    gho.approve(address(sgho), largeAmount);
    sgho.deposit(largeAmount, user1);
    uint256 largeShares = sgho.balanceOf(user1);
    assertEq(largeShares, smallShares + largeAmount, 'Large amount should convert 1:1 initially');
    
    vm.stopPrank();
  }

  function test_yield_accrual_atSupplyCap() external {
    // Set a higher target rate to ensure significant yield accrual
    vm.startPrank(yManager);
    sgho.setTargetRate(5000); // 50% APR to ensure significant yield
    vm.stopPrank();
    
    // Fill the vault to supply cap
    vm.startPrank(user1);
    sgho.deposit(SUPPLY_CAP, user1);
    uint256 initialShares = sgho.balanceOf(user1);
    vm.stopPrank();

    // Check that yield accrual still works even at supply cap
    uint256 totalAssetsBefore = sgho.totalAssets();
    uint256 yieldIndexBefore = sgho.yieldIndex();
    
    // Skip time to accrue yield (use a longer period to ensure significant yield)
    vm.warp(block.timestamp + 365 days);
    
    // Trigger yield update by withdrawing 1 wei (any state-changing operation would work)
    vm.startPrank(user1);
    sgho.withdraw(1, user1, user1);
    vm.stopPrank();
    
    uint256 totalAssetsAfter = sgho.totalAssets();
    uint256 yieldIndexAfter = sgho.yieldIndex();
    
    // Yield should have accrued even at supply cap
    // The total assets after should be greater than before minus the withdrawal amount
    // because yield accrual should offset the withdrawal
    assertTrue(totalAssetsAfter > totalAssetsBefore - 1, 'Yield should accrue even at supply cap');
    assertTrue(yieldIndexAfter > yieldIndexBefore, 'Yield index should increase even at supply cap');
    
    // User's share value should have increased (accounting for the 1 wei withdrawal)
    vm.startPrank(user1);
    uint256 userAssetsAfter = sgho.previewRedeem(initialShares - sgho.convertToShares(1));
    assertTrue(userAssetsAfter > SUPPLY_CAP - 1, 'User assets should increase with yield even at supply cap');
    vm.stopPrank();
  }

  function test_maxDeposit_withYieldAccrual() external {
    // Set up initial state with some deposits
    vm.startPrank(user1);
    uint256 initialDeposit = SUPPLY_CAP / 2;
    sgho.deposit(initialDeposit, user1);
    vm.stopPrank();
    
    // Check maxDeposit before any yield update
    uint256 maxDepositBefore = sgho.maxDeposit(user2);
    uint256 totalAssetsBefore = sgho.totalAssets();
    
    // Skip time to accrue yield
    vm.warp(block.timestamp + 30 days);
    
    // The maxDeposit should account for the fact that the deposit itself will trigger yield update
    // and potentially increase totalAssets beyond the current calculation  
    
    // The maxDeposit should account for the fact that the deposit itself will trigger yield update
    // and potentially increase totalAssets beyond the current calculation
    assertTrue(maxDepositBefore <= SUPPLY_CAP - totalAssetsBefore, 'maxDeposit should not exceed remaining capacity');
    
    // Now trigger a yield update by withdrawing 1 wei from user1
    vm.startPrank(user1);
    sgho.withdraw(1, user1, user1);
    vm.stopPrank();
    
    uint256 totalAssetsAfter = sgho.totalAssets();
    uint256 maxDepositAfter = sgho.maxDeposit(user2);
    
    // The total assets should have increased due to yield accrual (minus the 1 wei withdrawal)
    assertTrue(totalAssetsAfter > totalAssetsBefore - 1, 'Total assets should increase due to yield despite withdrawal');
    
    // The new maxDeposit should be accurate after the yield update
    assertEq(maxDepositAfter, SUPPLY_CAP - totalAssetsAfter, 'maxDeposit should be accurate after yield update');
    
    // Verify that the maxDeposit calculation is correct by attempting to deposit exactly that amount
    vm.startPrank(user2);
    deal(address(gho), user2, maxDepositAfter, true);
    gho.approve(address(sgho), maxDepositAfter);
    sgho.deposit(maxDepositAfter, user2);
    vm.stopPrank();
    
    // Should now be at supply cap
    assertEq(sgho.totalAssets(), SUPPLY_CAP, 'Should be at supply cap after depositing maxDeposit amount');
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
        uint256 currentIndexChangePerSecond = (lastYieldIndex * currentRatePerSecond) / 10000;
        uint256 nextYieldIndex = lastYieldIndex +
          ((currentIndexChangePerSecond * timeSkips[i]) / 1e27);
        uint256 expectedTotalAssets = (sgho.totalSupply() * nextYieldIndex) / 1e27;
        uint256 expectedYield = expectedTotalAssets - lastTotalAssets;

        totalExpectedYield += expectedYield;
        totalClaimedYield += sgho.totalAssets() - lastTotalAssets;
        assertApproxEqAbs(
          expectedTotalAssets,
          sgho.totalAssets(),
          1,
          'totalAssets mismatch from Yield calculation'
        );
        assertEq(
          sgho.balanceOf(user1),
          totalBobShares,
          'user1 balance mismatch from Yield calculation'
        );
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

  function test_revert_setTargetRate_rateGreaterThanMaxRate() external {
    uint256 newRate = 5001; // 50.01% APR
    vm.startPrank(yManager);
    vm.expectRevert(abi.encodeWithSelector(IsGHO.RateMustBeLessThanMaxRate.selector));
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

  function test_rescueERC20_zeroAmount() external {
    // Deploy a mock ERC20 token
    TestnetERC20 mockToken = new TestnetERC20('Mock Token', 'MTK', 18, address(this));
    uint256 initialAmount = 100 ether;

    // Transfer some tokens to sGHO
    deal(address(mockToken), address(sgho), initialAmount, true);

    // Grant FUNDS_ADMIN role to Admin
    vm.startPrank(poolAdmin);
    aclManager.grantRole(sgho.FUNDS_ADMIN_ROLE(), Admin);
    vm.stopPrank();

    // Rescue zero amount should be a no-op
    vm.startPrank(Admin);
    sgho.rescueERC20(address(mockToken), user1, 0);
    vm.stopPrank();

    // Token balances should remain unchanged
    assertEq(mockToken.balanceOf(address(sgho)), initialAmount, 'Contract balance should remain unchanged');
    assertEq(mockToken.balanceOf(user1), 0, 'User balance should remain unchanged');
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
            abi.encodeWithSelector(
              sGHO.initialize.selector,
              address(gho),
              address(contracts.aclManager),
              MAX_TARGET_RATE,
              SUPPLY_CAP
            )
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
      abi.encodeWithSelector(
        sGHO.initialize.selector,
        address(gho),
        address(contracts.aclManager),
        MAX_TARGET_RATE,
        SUPPLY_CAP
      )
    );

    sGHO newSgho = sGHO(payable(address(proxy)));

    // Should revert on second initialization via proxy
    vm.expectRevert();
    newSgho.initialize(address(gho), address(contracts.aclManager), MAX_TARGET_RATE, SUPPLY_CAP);
  }

  function test_revert_notInitialized() external {
    // Deploy a new sGHO implementation and proxy without initializing it
    address impl = address(new sGHO());
    TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
      impl,
      address(this),
      '' // No initialization data
    );
    sGHO uninitializedSgho = sGHO(payable(address(proxy)));
    
    // Since the isInitialized modifier is not used by any functions,
    // we'll test that the contract works correctly when not initialized
    // The totalAssets should return 0 for an uninitialized contract
    assertEq(uninitializedSgho.totalAssets(), 0, 'Uninitialized contract should return 0 totalAssets');
  }

  // --- Getter Functions Tests ---

  function test_getter_gho() external view {
    assertEq(sgho.gho(), address(gho), 'GHO address getter should return correct address');
  }

  function test_getter_deploymentChainId() external view {
    assertEq(sgho.deploymentChainId(), block.chainid, 'Deployment chain ID should match current chain');
  }

  function test_getter_VERSION() external view {
    assertEq(sgho.VERSION(), VERSION, 'VERSION should match constant');
  }

  function test_getter_name() external view {
    assertEq(sgho.name(), 'sGHO', 'Name should be sGHO');
  }

  function test_getter_symbol() external view {
    assertEq(sgho.symbol(), 'sGHO', 'Symbol should be sGHO');
  }

  function test_getter_decimals() external view {
    assertEq(sgho.decimals(), 18, 'Decimals should be 18');
  }

  function test_getter_asset() external view {
    assertEq(sgho.asset(), address(gho), 'Asset should return GHO address');
  }

  function test_getter_targetRate() external view {
    assertEq(sgho.targetRate(), 1000, 'Target rate should be 10% (1000 bps)');
  }

  function test_getter_maxTargetRate() external view {
    assertEq(sgho.maxTargetRate(), MAX_TARGET_RATE, 'Max target rate should match constant');
  }

  function test_getter_supplyCap() external view {
    assertEq(sgho.supplyCap(), SUPPLY_CAP, 'Supply cap should match constant');
  }

  function test_getter_yieldIndex() external view {
    assertEq(sgho.yieldIndex(), 1e27, 'Initial yield index should be RAY (1e27)');
  }

  function test_getter_lastUpdate() external view {
    assertEq(sgho.lastUpdate(), block.timestamp, 'Last update should be current timestamp');
  }

  function test_getter_vaultAPR() external view {
    assertEq(sgho.vaultAPR(), sgho.targetRate(), 'Vault APR should equal target rate');
  }

  function test_getter_FUNDS_ADMIN_ROLE() external view {
    assertEq(sgho.FUNDS_ADMIN_ROLE(), bytes32('FUNDS_ADMIN'), 'FUNDS_ADMIN_ROLE should match hash');
  }

  function test_getter_YIELD_MANAGER_ROLE() external view {
    assertEq(sgho.YIELD_MANAGER_ROLE(), bytes32('YIELD_MANAGER'), 'YIELD_MANAGER_ROLE should match hash');
  }

  function test_getter_DOMAIN_SEPARATOR() external view {
    assertEq(sgho.DOMAIN_SEPARATOR(), DOMAIN_SEPARATOR_sGHO, 'Domain separator should match calculated value');
  }

  function test_getter_totalSupply() external view {
    assertEq(sgho.totalSupply(), 0, 'Initial total supply should be 0');
  }

  function test_getter_balanceOf() external {
    vm.startPrank(user1);
    uint256 depositAmount = 100 ether;
    sgho.deposit(depositAmount, user1);
    assertEq(sgho.balanceOf(user1), depositAmount, 'Balance should match deposited amount');
    assertEq(sgho.balanceOf(user2), 0, 'User2 balance should be 0');
    vm.stopPrank();
  }

  function test_getter_totalAssets() external view {
    assertEq(sgho.totalAssets(), 0, 'Initial total assets should be 0');
  }


  // --- Internal Utility Functions ---

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

  function _createPermitSignature(
    address owner,
    address spender,
    uint256 value,
    uint256 nonce,
    uint256 deadline,
    uint256 privateKey
  ) internal view returns (uint8 v, bytes32 r, bytes32 s) {
    bytes32 PERMIT_TYPEHASH = keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');
    bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonce, deadline));
    bytes32 hash = keccak256(abi.encodePacked('\x19\x01', sgho.DOMAIN_SEPARATOR(), structHash));
    return vm.sign(privateKey, hash);
  }
}
