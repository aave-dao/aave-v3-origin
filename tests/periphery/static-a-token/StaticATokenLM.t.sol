// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {AToken} from '../../../src/contracts/protocol/tokenization/AToken.sol';
import {DataTypes} from '../../../src/contracts/protocol/libraries/types/DataTypes.sol';
import {IERC20, IERC20Metadata} from '../../../src/periphery/contracts/static-a-token/StaticATokenLM.sol';
import {RayMathExplicitRounding} from '../../../src/contracts/misc/libraries/RayMathExplicitRounding.sol';
import {PullRewardsTransferStrategy} from '../../../src/contracts/rewards/transfer-strategies/PullRewardsTransferStrategy.sol';
import {RewardsDataTypes} from '../../../src/contracts/rewards/libraries/RewardsDataTypes.sol';
import {ITransferStrategyBase} from '../../../src/contracts/rewards/interfaces/ITransferStrategyBase.sol';
import {IEACAggregatorProxy} from '../../../src/contracts/helpers/interfaces/IEACAggregatorProxy.sol';
import {IStaticATokenLM} from '../../../src/periphery/contracts/static-a-token/interfaces/IStaticATokenLM.sol';
import {SigUtils} from '../../utils/SigUtils.sol';
import {BaseTest, TestnetERC20} from './TestBase.sol';

contract StaticATokenLMTest is BaseTest {
  using RayMathExplicitRounding for uint256;

  address public constant EMISSION_ADMIN = address(25);

  function setUp() public override {
    super.setUp();

    _configureLM();
    _openSupplyAndBorrowPositions();

    vm.startPrank(user);
  }

  function test_initializeShouldRevert() public {
    address impl = factory.STATIC_A_TOKEN_IMPL();
    vm.expectRevert();
    IStaticATokenLM(impl).initialize(0xe50fA9b3c56FfB159cB0FCA61F5c9D750e8128c8, 'hey', 'ho');
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

  // test rewards
  function test_collectAndUpdateRewards() public {
    uint128 amountToDeposit = 5 ether;
    _fundUser(amountToDeposit, user);

    _depositAToken(amountToDeposit, user);

    _skipBlocks(60);
    assertEq(IERC20(REWARD_TOKEN).balanceOf(address(staticATokenLM)), 0);
    uint256 claimable = staticATokenLM.getTotalClaimableRewards(REWARD_TOKEN);
    staticATokenLM.collectAndUpdateRewards(REWARD_TOKEN);
    assertEq(IERC20(REWARD_TOKEN).balanceOf(address(staticATokenLM)), claimable);
  }

  function test_claimRewardsToSelf() public {
    uint128 amountToDeposit = 5 ether;
    _fundUser(amountToDeposit, user);

    _depositAToken(amountToDeposit, user);

    _skipBlocks(60);

    uint256 claimable = staticATokenLM.getClaimableRewards(user, REWARD_TOKEN);
    staticATokenLM.claimRewardsToSelf(rewardTokens);
    assertEq(IERC20(REWARD_TOKEN).balanceOf(user), claimable);
    assertEq(staticATokenLM.getClaimableRewards(user, REWARD_TOKEN), 0);
  }

  function test_claimRewards() public {
    uint128 amountToDeposit = 5 ether;
    _fundUser(amountToDeposit, user);

    _depositAToken(amountToDeposit, user);

    _skipBlocks(60);

    uint256 claimable = staticATokenLM.getClaimableRewards(user, REWARD_TOKEN);
    staticATokenLM.claimRewards(user, rewardTokens);
    assertEq(claimable, IERC20(REWARD_TOKEN).balanceOf(user));
    assertEq(IERC20(REWARD_TOKEN).balanceOf(address(staticATokenLM)), 0);
    assertEq(staticATokenLM.getClaimableRewards(user, REWARD_TOKEN), 0);
  }

  // should fail as user1 is not a valid claimer
  function testFail_claimRewardsOnBehalfOf() public {
    uint128 amountToDeposit = 5 ether;
    _fundUser(amountToDeposit, user);

    _depositAToken(amountToDeposit, user);

    _skipBlocks(60);

    vm.stopPrank();
    vm.startPrank(user1);

    staticATokenLM.getClaimableRewards(user, REWARD_TOKEN);
    staticATokenLM.claimRewardsOnBehalf(user, user1, rewardTokens);
  }

  function test_depositATokenClaimWithdrawClaim() public {
    uint128 amountToDeposit = 5 ether;
    _fundUser(amountToDeposit, user);

    // deposit aweth
    _depositAToken(amountToDeposit, user);

    // forward time
    _skipBlocks(60);

    // claim
    assertEq(IERC20(REWARD_TOKEN).balanceOf(user), 0);
    uint256 claimable0 = staticATokenLM.getClaimableRewards(user, REWARD_TOKEN);
    assertEq(staticATokenLM.getTotalClaimableRewards(REWARD_TOKEN), claimable0);
    assertGt(claimable0, 0);
    staticATokenLM.claimRewardsToSelf(rewardTokens);
    assertEq(IERC20(REWARD_TOKEN).balanceOf(user), claimable0);

    // forward time
    _skipBlocks(60);

    // redeem
    staticATokenLM.redeem(staticATokenLM.maxRedeem(user), user, user);
    uint256 claimable1 = staticATokenLM.getClaimableRewards(user, REWARD_TOKEN);
    assertEq(staticATokenLM.getTotalClaimableRewards(REWARD_TOKEN), claimable1);
    assertGt(claimable1, 0);

    // claim on behalf of other user
    staticATokenLM.claimRewardsToSelf(rewardTokens);
    assertEq(IERC20(REWARD_TOKEN).balanceOf(user), claimable1 + claimable0);
    assertEq(staticATokenLM.balanceOf(user), 0);
    assertEq(staticATokenLM.getClaimableRewards(user, REWARD_TOKEN), 0);
    assertEq(staticATokenLM.getTotalClaimableRewards(REWARD_TOKEN), 0);
    assertGt(AToken(UNDERLYING).balanceOf(user), 5 ether);
  }

  function test_depositWETHClaimWithdrawClaim() public {
    uint128 amountToDeposit = 5 ether;
    _fundUser(amountToDeposit, user);

    _depositAToken(amountToDeposit, user);

    // forward time
    _skipBlocks(60);

    // claim
    assertEq(IERC20(REWARD_TOKEN).balanceOf(user), 0);
    uint256 claimable0 = staticATokenLM.getClaimableRewards(user, REWARD_TOKEN);
    assertEq(staticATokenLM.getTotalClaimableRewards(REWARD_TOKEN), claimable0);
    assertGt(claimable0, 0);
    staticATokenLM.claimRewardsToSelf(rewardTokens);
    assertEq(IERC20(REWARD_TOKEN).balanceOf(user), claimable0);

    // forward time
    _skipBlocks(60);

    // redeem
    staticATokenLM.redeem(staticATokenLM.maxRedeem(user), user, user);
    uint256 claimable1 = staticATokenLM.getClaimableRewards(user, REWARD_TOKEN);
    assertEq(staticATokenLM.getTotalClaimableRewards(REWARD_TOKEN), claimable1);
    assertGt(claimable1, 0);

    // claim on behalf of other user
    staticATokenLM.claimRewardsToSelf(rewardTokens);
    assertEq(IERC20(REWARD_TOKEN).balanceOf(user), claimable1 + claimable0);
    assertEq(staticATokenLM.balanceOf(user), 0);
    assertEq(staticATokenLM.getClaimableRewards(user, REWARD_TOKEN), 0);
    assertEq(staticATokenLM.getTotalClaimableRewards(REWARD_TOKEN), 0);
    assertGt(AToken(UNDERLYING).balanceOf(user), 5 ether);
  }

  function test_transfer() public {
    uint128 amountToDeposit = 10 ether;
    _fundUser(amountToDeposit, user);

    _depositAToken(amountToDeposit, user);

    // transfer to 2nd user
    staticATokenLM.transfer(user1, amountToDeposit / 2);
    assertEq(staticATokenLM.getClaimableRewards(user1, REWARD_TOKEN), 0);

    // forward time
    _skipBlocks(60);

    // redeem for both
    uint256 claimableUser = staticATokenLM.getClaimableRewards(user, REWARD_TOKEN);
    staticATokenLM.redeem(staticATokenLM.maxRedeem(user), user, user);
    staticATokenLM.claimRewardsToSelf(rewardTokens);
    assertEq(IERC20(REWARD_TOKEN).balanceOf(user), claimableUser);
    vm.stopPrank();
    vm.startPrank(user1);
    uint256 claimableUser1 = staticATokenLM.getClaimableRewards(user1, REWARD_TOKEN);
    staticATokenLM.redeem(staticATokenLM.maxRedeem(user1), user1, user1);
    staticATokenLM.claimRewardsToSelf(rewardTokens);
    assertEq(IERC20(REWARD_TOKEN).balanceOf(user1), claimableUser1);
    assertGt(claimableUser1, 0);

    assertEq(staticATokenLM.getTotalClaimableRewards(REWARD_TOKEN), 0);
    assertEq(staticATokenLM.getClaimableRewards(user, REWARD_TOKEN), 0);
    assertEq(staticATokenLM.getClaimableRewards(user1, REWARD_TOKEN), 0);
  }

  // getUnclaimedRewards
  function test_getUnclaimedRewards() public {
    uint128 amountToDeposit = 5 ether;
    _fundUser(amountToDeposit, user);

    uint256 shares = _depositAToken(amountToDeposit, user);
    assertEq(staticATokenLM.getUnclaimedRewards(user, REWARD_TOKEN), 0);
    _skipBlocks(1000);
    staticATokenLM.redeem(shares, user, user);
    assertGt(staticATokenLM.getUnclaimedRewards(user, REWARD_TOKEN), 0);
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
      staticATokenLM.PERMIT_TYPEHASH(),
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
      staticATokenLM.PERMIT_TYPEHASH(),
      staticATokenLM.DOMAIN_SEPARATOR()
    );
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, permitDigest);

    vm.expectRevert('PERMIT_DEADLINE_EXPIRED');
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
      staticATokenLM.PERMIT_TYPEHASH(),
      staticATokenLM.DOMAIN_SEPARATOR()
    );
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, permitDigest);

    vm.expectRevert('INVALID_SIGNER');
    staticATokenLM.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);
  }

  function _configureLM() internal {
    PullRewardsTransferStrategy strat = new PullRewardsTransferStrategy(
      report.rewardsControllerProxy,
      EMISSION_ADMIN,
      EMISSION_ADMIN
    );

    vm.startPrank(poolAdmin);
    contracts.emissionManager.setEmissionAdmin(REWARD_TOKEN, EMISSION_ADMIN);
    vm.stopPrank();

    vm.startPrank(EMISSION_ADMIN);
    IERC20(REWARD_TOKEN).approve(address(strat), 10_000 ether);
    vm.stopPrank();

    vm.startPrank(OWNER);
    TestnetERC20(REWARD_TOKEN).mint(EMISSION_ADMIN, 10_000 ether);
    vm.stopPrank();

    RewardsDataTypes.RewardsConfigInput[] memory config = new RewardsDataTypes.RewardsConfigInput[](
      1
    );
    config[0] = RewardsDataTypes.RewardsConfigInput(
      0.00385 ether,
      10_000 ether,
      uint32(block.timestamp + 30 days),
      A_TOKEN,
      REWARD_TOKEN,
      ITransferStrategyBase(strat),
      IEACAggregatorProxy(address(2))
    );

    vm.prank(EMISSION_ADMIN);
    contracts.emissionManager.configureAssets(config);

    staticATokenLM.refreshRewardTokens();
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
