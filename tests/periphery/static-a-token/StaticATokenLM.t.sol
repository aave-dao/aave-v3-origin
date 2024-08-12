// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IRescuable} from 'solidity-utils/contracts/utils/Rescuable.sol';
import {ERC20PermitUpgradeable} from 'openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PermitUpgradeable.sol';
import {Initializable} from 'openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol';
import {AToken} from '../../../src/core/contracts/protocol/tokenization/AToken.sol';
import {DataTypes} from '../../../src/core/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {IERC20, IERC20Metadata} from '../../../src/periphery/contracts/static-a-token/StaticATokenLM.sol';
import {RayMathExplicitRounding} from '../../../src/periphery/contracts/libraries/RayMathExplicitRounding.sol';
import {IStaticATokenLM} from '../../../src/periphery/contracts/static-a-token/interfaces/IStaticATokenLM.sol';
import {SigUtils} from '../../utils/SigUtils.sol';
import {BaseTest, TestnetERC20} from './TestBase.sol';
import {IPool} from '../../../src/core/contracts/interfaces/IPool.sol';

contract StaticATokenLMTest is BaseTest {
  using RayMathExplicitRounding for uint256;

  function setUp() public override {
    super.setUp();

    _configureLM();
    _openSupplyAndBorrowPositions();

    vm.startPrank(user);
  }

  function test_initializeShouldRevert() public {
    address impl = factory.STATIC_A_TOKEN_IMPL();
    vm.expectRevert(Initializable.InvalidInitialization.selector);
    IStaticATokenLM(impl).initialize(A_TOKEN, 'hey', 'ho');
  }

  function test_getters() public view {
    assertEq(staticATokenLM.name(), 'Static Aave Local WETH');
    assertEq(staticATokenLM.symbol(), 'stataLocWETH');

    IERC20 aToken = staticATokenLM.aToken();
    assertEq(address(aToken), A_TOKEN);

    address underlyingAddress = address(staticATokenLM.asset());
    assertEq(underlyingAddress, UNDERLYING);

    IERC20Metadata underlying = IERC20Metadata(underlyingAddress);
    assertEq(staticATokenLM.decimals(), underlying.decimals());

    assertEq(
      address(staticATokenLM.INCENTIVES_CONTROLLER()),
      address(AToken(A_TOKEN).getIncentivesController())
    );
  }

  function test_convertersAndPreviews() public view {
    uint128 amount = 5 ether;
    uint256 shares = staticATokenLM.convertToShares(amount);
    assertLe(shares, amount, 'SHARES LOWER');
    assertEq(shares, staticATokenLM.previewDeposit(amount), 'PREVIEW_DEPOSIT');
    assertLe(shares, staticATokenLM.previewWithdraw(amount), 'PREVIEW_WITHDRAW');
    uint256 assets = staticATokenLM.convertToAssets(amount);
    assertGe(assets, shares, 'ASSETS GREATER');
    assertLe(assets, staticATokenLM.previewMint(amount), 'PREVIEW_MINT');
    assertEq(assets, staticATokenLM.previewRedeem(amount), 'PREVIEW_REDEEM');
  }

  // Redeem tests
  function test_redeem() public {
    uint128 amountToDeposit = 5 ether;
    _fundUser(amountToDeposit, user);

    _depositAToken(amountToDeposit, user);

    assertEq(staticATokenLM.maxRedeem(user), staticATokenLM.balanceOf(user));
    staticATokenLM.redeem(staticATokenLM.maxRedeem(user), user, user);
    assertEq(staticATokenLM.balanceOf(user), 0);
    assertLe(IERC20(UNDERLYING).balanceOf(user), amountToDeposit);
    assertApproxEqAbs(IERC20(UNDERLYING).balanceOf(user), amountToDeposit, 1);
  }

  function test_redeemAToken() public {
    uint128 amountToDeposit = 5 ether;
    _fundUser(amountToDeposit, user);

    _depositAToken(amountToDeposit, user);

    assertEq(staticATokenLM.maxRedeem(user), staticATokenLM.balanceOf(user));
    staticATokenLM.redeem(staticATokenLM.maxRedeem(user), user, user, false);
    assertEq(staticATokenLM.balanceOf(user), 0);
    assertLe(IERC20(A_TOKEN).balanceOf(user), amountToDeposit);
    assertApproxEqAbs(IERC20(A_TOKEN).balanceOf(user), amountToDeposit, 1);
  }

  function test_redeemAllowance() public {
    uint128 amountToDeposit = 5 ether;
    _fundUser(amountToDeposit, user);

    _depositAToken(amountToDeposit, user);

    staticATokenLM.approve(user1, staticATokenLM.maxRedeem(user));
    vm.stopPrank();
    vm.startPrank(user1);
    staticATokenLM.redeem(staticATokenLM.maxRedeem(user), user1, user);
    assertEq(staticATokenLM.balanceOf(user), 0);
    assertLe(IERC20(UNDERLYING).balanceOf(user1), amountToDeposit);
    assertApproxEqAbs(IERC20(UNDERLYING).balanceOf(user1), amountToDeposit, 1);
  }

  function testFail_redeemOverflowAllowance() public {
    uint128 amountToDeposit = 5 ether;
    _fundUser(amountToDeposit, user);

    _depositAToken(amountToDeposit, user);

    staticATokenLM.approve(user1, staticATokenLM.maxRedeem(user) / 2);
    vm.stopPrank();
    vm.startPrank(user1);
    staticATokenLM.redeem(staticATokenLM.maxRedeem(user), user1, user);
    assertEq(staticATokenLM.balanceOf(user), 0);
    assertEq(IERC20(A_TOKEN).balanceOf(user1), amountToDeposit);
  }

  function testFail_redeemAboveBalance() public {
    uint128 amountToDeposit = 5 ether;
    _fundUser(amountToDeposit, user);

    _depositAToken(amountToDeposit, user);
    staticATokenLM.redeem(staticATokenLM.maxRedeem(user) + 1, user, user);
  }

  // Withdraw tests
  function test_withdraw() public {
    uint128 amountToDeposit = 5 ether;
    _fundUser(amountToDeposit, user);

    _depositAToken(amountToDeposit, user);

    assertLe(staticATokenLM.maxWithdraw(user), amountToDeposit);
    staticATokenLM.withdraw(staticATokenLM.maxWithdraw(user), user, user);
    assertEq(staticATokenLM.balanceOf(user), 0);
    assertLe(IERC20(UNDERLYING).balanceOf(user), amountToDeposit);
    assertApproxEqAbs(IERC20(UNDERLYING).balanceOf(user), amountToDeposit, 1);
  }

  function testFail_withdrawAboveBalance() public {
    uint128 amountToDeposit = 5 ether;
    _fundUser(amountToDeposit, user);
    _fundUser(amountToDeposit, user1);

    _depositAToken(amountToDeposit, user);
    _depositAToken(amountToDeposit, user1);

    assertEq(staticATokenLM.maxWithdraw(user), amountToDeposit);
    staticATokenLM.withdraw(staticATokenLM.maxWithdraw(user) + 1, user, user);
  }

  // mint
  function test_mint() public {
    vm.stopPrank();

    // set supply cap to non-zero
    vm.startPrank(poolAdmin);
    contracts.poolConfiguratorProxy.setSupplyCap(UNDERLYING, 15_000);
    vm.stopPrank();

    vm.startPrank(user);

    uint128 amountToDeposit = 5 ether;
    _fundUser(amountToDeposit, user);

    IERC20(UNDERLYING).approve(address(staticATokenLM), amountToDeposit);
    uint256 shares = 1 ether;
    staticATokenLM.mint(shares, user);
    assertEq(shares, staticATokenLM.balanceOf(user));
  }

  function testFail_mintAboveBalance() public {
    uint128 amountToDeposit = 5 ether;
    _fundUser(amountToDeposit, user);

    _underlyingToAToken(amountToDeposit, user);
    IERC20(A_TOKEN).approve(address(staticATokenLM), amountToDeposit);
    staticATokenLM.mint(amountToDeposit, user);
  }

  /**
   * maxDeposit test
   */
  function test_maxDeposit_freeze() public {
    vm.stopPrank();
    vm.startPrank(roleList.marketOwner);
    contracts.poolConfiguratorProxy.setReserveFreeze(UNDERLYING, true);

    uint256 max = staticATokenLM.maxDeposit(address(0));

    assertEq(max, 0);
  }

  function test_maxDeposit_paused() public {
    vm.stopPrank();
    vm.startPrank(address(roleList.marketOwner));
    contracts.poolConfiguratorProxy.setReservePause(UNDERLYING, true);

    uint256 max = staticATokenLM.maxDeposit(address(0));

    assertEq(max, 0);
  }

  function test_maxDeposit_noCap() public {
    vm.stopPrank();
    vm.startPrank(address(roleList.marketOwner));
    contracts.poolConfiguratorProxy.setSupplyCap(UNDERLYING, 0);

    uint256 maxDeposit = staticATokenLM.maxDeposit(address(0));
    uint256 maxMint = staticATokenLM.maxMint(address(0));

    assertEq(maxDeposit, type(uint256).max);
    assertEq(maxMint, type(uint256).max);
  }

  // should be 0 as supply is ~5k
  function test_maxDeposit_5kCap() public {
    vm.stopPrank();
    vm.startPrank(address(roleList.marketOwner));
    contracts.poolConfiguratorProxy.setSupplyCap(UNDERLYING, 5_000);

    uint256 max = staticATokenLM.maxDeposit(address(0));
    assertEq(max, 0);
  }

  function test_maxDeposit_50kCap() public {
    vm.stopPrank();
    vm.startPrank(address(roleList.marketOwner));
    contracts.poolConfiguratorProxy.setSupplyCap(UNDERLYING, 50_000);

    uint256 max = staticATokenLM.maxDeposit(address(0));
    DataTypes.ReserveDataLegacy memory reserveData = POOL.getReserveData(UNDERLYING);
    assertEq(
      max,
      50_000 *
        (10 ** IERC20Metadata(UNDERLYING).decimals()) -
        (IERC20Metadata(A_TOKEN).totalSupply() +
          uint256(reserveData.accruedToTreasury).rayMulRoundUp(staticATokenLM.rate()))
    );
  }

  /**
   * maxRedeem test
   */
  function test_maxRedeem_paused() public {
    uint128 amountToDeposit = 5 ether;
    _fundUser(amountToDeposit, user);

    _depositAToken(amountToDeposit, user);

    vm.stopPrank();
    vm.startPrank(address(roleList.marketOwner));
    contracts.poolConfiguratorProxy.setReservePause(UNDERLYING, true);

    uint256 max = staticATokenLM.maxRedeem(address(user));

    assertEq(max, 0);
  }

  function test_maxRedeem_allAvailable() public {
    uint128 amountToDeposit = 5 ether;
    _fundUser(amountToDeposit, user);

    _depositAToken(amountToDeposit, user);

    uint256 max = staticATokenLM.maxRedeem(address(user));

    assertEq(max, staticATokenLM.balanceOf(user));
  }

  function test_maxRedeem_partAvailable() public {
    uint128 amountToDeposit = 50 ether;
    _fundUser(amountToDeposit, user);

    _depositAToken(amountToDeposit, user);
    vm.stopPrank();

    uint256 maxRedeemBefore = staticATokenLM.previewRedeem(staticATokenLM.maxRedeem(address(user)));
    uint256 underlyingBalanceBefore = IERC20Metadata(UNDERLYING).balanceOf(A_TOKEN);

    // create rich user
    address borrowUser = address(99);
    vm.startPrank(borrowUser);
    deal(address(wbtc), borrowUser, 2_000e8);
    wbtc.approve(address(POOL), 2_000e8);
    POOL.deposit(address(wbtc), 2_000e8, borrowUser, 0);

    // borrow all available
    POOL.borrow(UNDERLYING, underlyingBalanceBefore - (maxRedeemBefore / 2), 2, 0, borrowUser);

    uint256 maxRedeemAfter = staticATokenLM.previewRedeem(staticATokenLM.maxRedeem(address(user)));
    assertApproxEqAbs(maxRedeemAfter, (maxRedeemBefore / 2), 1);
  }

  function test_maxRedeem_nonAvailable() public {
    uint128 amountToDeposit = 50 ether;
    _fundUser(amountToDeposit, user);

    _depositAToken(amountToDeposit, user);
    vm.stopPrank();

    uint256 underlyingBalanceBefore = IERC20Metadata(UNDERLYING).balanceOf(A_TOKEN);
    // create rich user
    address borrowUser = address(99);
    vm.startPrank(borrowUser);
    deal(address(wbtc), borrowUser, 2_000e8);
    wbtc.approve(address(POOL), 2_000e8);
    POOL.deposit(address(wbtc), 2_000e8, borrowUser, 0);

    // borrow all available
    contracts.poolProxy.borrow(UNDERLYING, underlyingBalanceBefore, 2, 0, borrowUser);

    uint256 maxRedeemAfter = staticATokenLM.maxRedeem(address(user));
    assertEq(maxRedeemAfter, 0);
  }

  function test_permit() public {
    SigUtils.Permit memory permit = SigUtils.Permit({
      owner: user,
      spender: spender,
      value: 1 ether,
      nonce: staticATokenLM.nonces(user),
      deadline: block.timestamp + 1 days
    });

    bytes32 permitDigest = SigUtils.getTypedDataHash(
      permit,
      PERMIT_TYPEHASH,
      staticATokenLM.DOMAIN_SEPARATOR()
    );
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, permitDigest);

    staticATokenLM.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);

    assertEq(staticATokenLM.allowance(permit.owner, spender), permit.value);
  }

  function test_permit_expired() public {
    // as the default timestamp is 0, we move ahead in time a bit
    vm.warp(10 days);

    SigUtils.Permit memory permit = SigUtils.Permit({
      owner: user,
      spender: spender,
      value: 1 ether,
      nonce: staticATokenLM.nonces(user),
      deadline: block.timestamp - 1 days
    });

    bytes32 permitDigest = SigUtils.getTypedDataHash(
      permit,
      PERMIT_TYPEHASH,
      staticATokenLM.DOMAIN_SEPARATOR()
    );
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, permitDigest);

    vm.expectRevert(
      abi.encodeWithSelector(
        ERC20PermitUpgradeable.ERC2612ExpiredSignature.selector,
        permit.deadline
      )
    );
    staticATokenLM.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);
  }

  function test_permit_invalidSigner() public {
    SigUtils.Permit memory permit = SigUtils.Permit({
      owner: address(424242),
      spender: spender,
      value: 1 ether,
      nonce: staticATokenLM.nonces(user),
      deadline: block.timestamp + 1 days
    });

    bytes32 permitDigest = SigUtils.getTypedDataHash(
      permit,
      PERMIT_TYPEHASH,
      staticATokenLM.DOMAIN_SEPARATOR()
    );
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, permitDigest);

    vm.expectRevert(
      abi.encodeWithSelector(
        ERC20PermitUpgradeable.ERC2612InvalidSigner.selector,
        user,
        permit.owner
      )
    );
    staticATokenLM.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);
  }

  function test_rescuable_shouldRevertForInvalidCaller() external {
    deal(tokenList.usdx, address(staticATokenLM), 1 ether);
    vm.expectRevert('ONLY_RESCUE_GUARDIAN');
    IRescuable(address(staticATokenLM)).emergencyTokenTransfer(
      tokenList.usdx,
      address(this),
      1 ether
    );
  }

  function test_rescuable_shouldSuceedForOwner() external {
    deal(tokenList.usdx, address(staticATokenLM), 1 ether);
    vm.startPrank(poolAdmin);
    IRescuable(address(staticATokenLM)).emergencyTokenTransfer(
      tokenList.usdx,
      address(this),
      1 ether
    );
  }

  function _openSupplyAndBorrowPositions() internal {
    // this is to open borrow positions so that the aToken balance increases
    address whale = address(79);
    vm.startPrank(whale);
    _fundUser(5_000 ether, whale);

    weth.approve(address(POOL), 5_000 ether);
    POOL.deposit(address(weth), 5_000 ether, whale, 0);

    POOL.borrow(address(weth), 1_000 ether, 2, 0, whale);
    vm.stopPrank();
  }
}
