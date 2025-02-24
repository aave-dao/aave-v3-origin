// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20Errors} from 'openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import {TestnetProcedures, TestnetERC20} from '../../utils/TestnetProcedures.sol';
import {ERC20AaveLMUpgradeable, IERC20AaveLM} from '../../../src/contracts/extensions/stata-token/ERC20AaveLMUpgradeable.sol';
import {IRewardsController} from '../../../src/contracts/rewards/interfaces/IRewardsController.sol';
import {PullRewardsTransferStrategy, ITransferStrategyBase} from '../../../src/contracts/rewards/transfer-strategies/PullRewardsTransferStrategy.sol';
import {RewardsDataTypes} from '../../../src/contracts/rewards/libraries/RewardsDataTypes.sol';
import {AggregatorInterface} from '../../../src/contracts/dependencies/chainlink/AggregatorInterface.sol';
import {DataTypes} from '../../../src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';

// Minimal mock as contract is abstract
contract MockERC20AaveLMUpgradeable is ERC20AaveLMUpgradeable {
  constructor(IRewardsController rewardsController) ERC20AaveLMUpgradeable(rewardsController) {}

  function mockInit(address asset) external initializer {
    __ERC20AaveLM_init(asset);
  }

  function mint(address user, uint256 amount) external {
    _mint(user, amount);
  }
}

contract MockScaledTestnetERC20 is TestnetERC20 {
  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals,
    address owner
  ) TestnetERC20(name, symbol, decimals, owner) {}

  function scaledTotalSupply() external view returns (uint256) {
    return totalSupply();
  }

  function scaledBalanceOf(address user) external view returns (uint256) {
    return balanceOf(user);
  }

  function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256) {
    return (balanceOf(user), totalSupply());
  }

  function mint(address user, uint256 amount) public override returns (bool) {
    _mint(user, amount);
    return true;
  }
}

contract ERC20AaveLMUpgradableTest is TestnetProcedures {
  MockERC20AaveLMUpgradeable internal lmUpgradeable;
  MockScaledTestnetERC20 internal underlying;

  address public user;
  uint256 internal userPrivateKey;

  address internal rewardToken;
  address internal emissionAdmin;
  PullRewardsTransferStrategy strategy;

  function setUp() public virtual {
    initTestEnvironment(false);

    emissionAdmin = vm.addr(1024);

    userPrivateKey = 0xA11CE;
    user = address(vm.addr(userPrivateKey));

    underlying = new MockScaledTestnetERC20('Mock underlying', 'UND', 18, poolAdmin);

    lmUpgradeable = new MockERC20AaveLMUpgradeable(contracts.rewardsControllerProxy);
    lmUpgradeable.mockInit(address(underlying));

    rewardToken = address(new TestnetERC20('LM Reward ERC20', 'RWD', 18, poolAdmin));
    strategy = new PullRewardsTransferStrategy(
      report.rewardsControllerProxy,
      emissionAdmin,
      emissionAdmin
    );

    vm.prank(poolAdmin);
    contracts.emissionManager.setEmissionAdmin(rewardToken, emissionAdmin);
  }

  function test_7201() external pure {
    assertEq(
      keccak256(abi.encode(uint256(keccak256('aave-dao.storage.ERC20AaveLM')) - 1)) &
        ~bytes32(uint256(0xff)),
      0x4fad66563f105be0bff96185c9058c4934b504d3ba15ca31e86294f0b01fd200
    );
  }

  function test_zeroIncentivesController() external {
    vm.expectRevert(IERC20AaveLM.ZeroIncentivesControllerIsForbidden.selector);
    new MockERC20AaveLMUpgradeable(IRewardsController(address(0)));
  }

  function test_noRewardsInitialized() external {
    vm.expectRevert(
      abi.encodeWithSelector(IERC20AaveLM.RewardNotInitialized.selector, rewardToken)
    );
    lmUpgradeable.getClaimableRewards(user, rewardToken);
  }

  function test_noopWhenNotInitialized() external {
    assertEq(IERC20(rewardToken).balanceOf(address(lmUpgradeable)), 0);
    assertEq(lmUpgradeable.getTotalClaimableRewards(rewardToken), 0);
    assertEq(lmUpgradeable.collectAndUpdateRewards(rewardToken), 0);
    assertEq(IERC20(rewardToken).balanceOf(address(lmUpgradeable)), 0);
  }

  function test_claimableRewards(
    uint256 depositAmount,
    uint32 emissionEnd,
    uint88 emissionPerSecond,
    uint32 waitDuration
  ) public {
    TestEnv memory env = _setupTestEnvironment(
      depositAmount,
      emissionEnd,
      emissionPerSecond,
      waitDuration
    );

    uint256 claimable = lmUpgradeable.getClaimableRewards(user, rewardToken);
    assertLe(claimable, env.emissionDuration * env.emissionPerSecond);
  }

  function test_collectAndUpdateRewards(
    uint256 depositAmount,
    uint32 emissionEnd,
    uint88 emissionPerSecond,
    uint32 waitDuration
  ) public {
    _setupTestEnvironment(depositAmount, emissionEnd, emissionPerSecond, waitDuration);

    assertEq(IERC20(rewardToken).balanceOf(address(lmUpgradeable)), 0);
    uint256 claimable = lmUpgradeable.getTotalClaimableRewards(rewardToken);
    lmUpgradeable.collectAndUpdateRewards(rewardToken);
    assertEq(IERC20(rewardToken).balanceOf(address(lmUpgradeable)), claimable);
  }

  function test_claimRewards(
    uint256 depositAmount,
    uint32 emissionEnd,
    uint88 emissionPerSecond,
    uint32 waitDuration
  ) public {
    _setupTestEnvironment(depositAmount, emissionEnd, emissionPerSecond, waitDuration);

    uint256 claimable = lmUpgradeable.getClaimableRewards(user, rewardToken);
    vm.prank(user);
    lmUpgradeable.claimRewards(address(this), _getRewardTokens());
    assertEq(IERC20(rewardToken).balanceOf(address(this)), claimable);
    assertEq(lmUpgradeable.getClaimableRewards(user, rewardToken), 0);
  }

  function test_claimRewardsToSelf(
    uint256 depositAmount,
    uint32 emissionEnd,
    uint88 emissionPerSecond,
    uint32 waitDuration
  ) public {
    _setupTestEnvironment(depositAmount, emissionEnd, emissionPerSecond, waitDuration);

    uint256 claimable = lmUpgradeable.getClaimableRewards(user, rewardToken);
    vm.prank(user);
    lmUpgradeable.claimRewardsToSelf(_getRewardTokens());
    assertEq(IERC20(rewardToken).balanceOf(user), claimable);
    assertEq(lmUpgradeable.getClaimableRewards(user, rewardToken), 0);
  }

  function test_claimRewardsOnBehalfOf_shouldRevertForInvalidClaimer(
    uint256 depositAmount,
    uint32 emissionEnd,
    uint88 emissionPerSecond,
    uint32 waitDuration
  ) external {
    _setupTestEnvironment(depositAmount, emissionEnd, emissionPerSecond, waitDuration);

    vm.expectRevert(abi.encodeWithSelector(IERC20AaveLM.InvalidClaimer.selector, address(this)));
    lmUpgradeable.claimRewardsOnBehalf(user, address(this), _getRewardTokens());
  }

  function test_claimRewardsOnBehalfOf_self(
    uint256 depositAmount,
    uint32 emissionEnd,
    uint88 emissionPerSecond,
    uint32 waitDuration
  ) external {
    _setupTestEnvironment(depositAmount, emissionEnd, emissionPerSecond, waitDuration);

    uint256 claimable = lmUpgradeable.getClaimableRewards(user, rewardToken);
    vm.prank(user);
    lmUpgradeable.claimRewardsOnBehalf(user, address(this), _getRewardTokens());
    assertEq(IERC20(rewardToken).balanceOf(address(this)), claimable);
    assertEq(lmUpgradeable.getClaimableRewards(user, rewardToken), 0);
  }

  function test_claimRewardsOnBehalfOf_validClaimer(
    uint256 depositAmount,
    uint32 emissionEnd,
    uint88 emissionPerSecond,
    uint32 waitDuration
  ) external {
    _setupTestEnvironment(depositAmount, emissionEnd, emissionPerSecond, waitDuration);

    vm.prank(poolAdmin);
    contracts.emissionManager.setClaimer(user, address(this));

    uint256 claimable = lmUpgradeable.getClaimableRewards(user, rewardToken);
    lmUpgradeable.claimRewardsOnBehalf(user, address(this), _getRewardTokens());
    assertEq(IERC20(rewardToken).balanceOf(address(this)), claimable);
    assertEq(lmUpgradeable.getClaimableRewards(user, rewardToken), 0);
  }

  function test_transfer_toSelf(
    uint256 depositAmount,
    uint32 emissionEnd,
    uint88 emissionPerSecond,
    uint32 waitDuration
  ) external {
    TestEnv memory env = _setupTestEnvironment(
      depositAmount,
      emissionEnd,
      emissionPerSecond,
      waitDuration
    );

    uint256 claimableBefore = lmUpgradeable.getClaimableRewards(user, rewardToken);
    assertEq(lmUpgradeable.getUnclaimedRewards(user, rewardToken), 0);
    vm.prank(user);
    lmUpgradeable.transfer(user, env.depositAmount);
    uint256 claimableAfter = lmUpgradeable.getClaimableRewards(user, rewardToken);
    assertEq(lmUpgradeable.getUnclaimedRewards(user, rewardToken), claimableAfter);
    assertEq(claimableBefore, claimableAfter);
  }

  function test_transfer(
    uint256 depositAmount,
    uint32 emissionEnd,
    uint88 emissionPerSecond,
    uint32 waitDuration,
    address receiver,
    uint256 sendAmount
  ) external {
    vm.assume(user != receiver && receiver != address(0));
    TestEnv memory env = _setupTestEnvironment(
      depositAmount,
      emissionEnd,
      emissionPerSecond,
      waitDuration
    );

    if (sendAmount > env.depositAmount) {
      vm.expectRevert(
        abi.encodeWithSelector(
          IERC20Errors.ERC20InsufficientBalance.selector,
          user,
          env.depositAmount,
          sendAmount
        )
      );
      vm.prank(user);
      lmUpgradeable.transfer(receiver, sendAmount);
    } else {
      _fund(env.depositAmount, receiver);
      assertEq(lmUpgradeable.getUnclaimedRewards(user, rewardToken), 0);
      assertEq(lmUpgradeable.getUnclaimedRewards(receiver, rewardToken), 0);

      uint256 senderClaimableBefore = lmUpgradeable.getClaimableRewards(user, rewardToken);
      uint256 receiverClaimableBefore = lmUpgradeable.getClaimableRewards(receiver, rewardToken);

      vm.prank(user);
      lmUpgradeable.transfer(receiver, sendAmount);
      // rewards should remain the same, but move to unclaimed
      assertEq(lmUpgradeable.getUnclaimedRewards(user, rewardToken), senderClaimableBefore);
      assertEq(lmUpgradeable.getClaimableRewards(user, rewardToken), senderClaimableBefore);
      assertEq(lmUpgradeable.getUnclaimedRewards(receiver, rewardToken), receiverClaimableBefore);
      assertEq(lmUpgradeable.getClaimableRewards(receiver, rewardToken), receiverClaimableBefore);
    }
  }

  function test_isRegisteredRewardToken() external {
    assertEq(lmUpgradeable.isRegisteredRewardToken(rewardToken), false);
    _setupEmission(uint32(block.timestamp), 0);
    assertEq(lmUpgradeable.isRegisteredRewardToken(rewardToken), false);
    lmUpgradeable.refreshRewardTokens();
    assertEq(lmUpgradeable.isRegisteredRewardToken(rewardToken), true);
  }

  function test_getReferenceAsset() external view {
    address ref = lmUpgradeable.getReferenceAsset();
    assertEq(ref, address(underlying));
  }

  function test_rewardTokens() external {
    _setupEmission(uint32(block.timestamp), 0);
    lmUpgradeable.refreshRewardTokens();
    address[] memory assets = lmUpgradeable.rewardTokens();
    assertEq(assets.length, 1);
    assertEq(assets[0], rewardToken);
  }

  function test_correctAccountingForDelayedRegistration() external {
    address earlyDepositor = address(0xB0B);
    _fund(1 ether, earlyDepositor);
    _setupEmission(uint32(block.timestamp + 2 days), 1 ether);

    vm.warp(block.timestamp + 1 days);
    _fund(1 ether, user);
    lmUpgradeable.refreshRewardTokens();
    // as the rewards were not tracked before they should be zero
    assertEq(lmUpgradeable.getClaimableRewards(earlyDepositor, rewardToken), 0);
    assertEq(lmUpgradeable.getClaimableRewards(user, rewardToken), 0);

    vm.warp(block.timestamp + 3 days);
    uint256 claimableBob = lmUpgradeable.getClaimableRewards(earlyDepositor, rewardToken);
    uint256 claimableUser = lmUpgradeable.getClaimableRewards(user, rewardToken);
    assertEq(claimableBob, claimableUser);
    assertEq(claimableBob + claimableUser, 1 days * 1 ether);
  }

  // ### INTERNAL HELPER FUNCTIONS ###
  struct TestEnv {
    // @notice the amount deposited
    uint256 depositAmount;
    // @notice the timestamp at which emission stops
    uint32 emissionEnd;
    // @notice emission per second
    uint88 emissionPerSecond;
    // @notice the duration of emissions in the test environment (time passed)
    uint32 emissionDuration;
  }

  function _setupTestEnvironment(
    uint256 depositAmount,
    uint32 emissionEnd,
    uint88 emissionPerSecond,
    uint32 waitDuration
  ) internal returns (TestEnv memory) {
    TestEnv memory env;
    env.depositAmount = bound(depositAmount, 1 ether, type(uint96).max);
    env.emissionEnd = uint32(bound(emissionEnd, block.timestamp, 365 days * 100));
    uint32 endTimestamp = uint32(bound(waitDuration, block.timestamp, 365 days * 100));
    env.emissionDuration = env.emissionEnd > endTimestamp
      ? endTimestamp - uint32(block.timestamp)
      : env.emissionEnd - uint32(block.timestamp);
    env.emissionPerSecond = uint88(
      bound(
        emissionPerSecond,
        0,
        env.emissionDuration > 0 ? type(uint88).max / env.emissionDuration : type(uint88).max
      )
    );
    _setupEmission(env.emissionEnd, env.emissionPerSecond);
    lmUpgradeable.refreshRewardTokens();
    _fund(env.depositAmount, user);

    vm.warp(endTimestamp);

    return env;
  }

  function _getRewardTokens() internal view returns (address[] memory) {
    address[] memory rewardTokens = new address[](1);
    rewardTokens[0] = rewardToken;
    return rewardTokens;
  }

  function _setupEmission(uint32 emissionEnd, uint88 emissionPerSecond) internal {
    RewardsDataTypes.RewardsConfigInput[] memory config = new RewardsDataTypes.RewardsConfigInput[](
      1
    );
    config[0] = RewardsDataTypes.RewardsConfigInput(
      emissionPerSecond,
      0, // totalSupply is overwritten internally
      emissionEnd,
      address(underlying),
      rewardToken,
      ITransferStrategyBase(strategy),
      AggregatorInterface(address(2))
    );

    // configure asset
    vm.prank(emissionAdmin);
    contracts.emissionManager.configureAssets(config);

    // fund admin & approve transfers to allow claiming
    uint256 fundsToEmit = (emissionEnd - block.timestamp) * emissionPerSecond;
    deal(rewardToken, emissionAdmin, fundsToEmit, true);
    vm.prank(emissionAdmin);
    IERC20(rewardToken).approve(address(strategy), fundsToEmit);
  }

  /**
   * @dev funds the given user with the lm token and updates total supply.
   * Maintains consistency by also funding the underlying to the lmUpgradeable
   */
  function _fund(uint256 amount, address receiver) internal {
    underlying.mint(receiver, amount);
    lmUpgradeable.mint(receiver, amount);
    vm.prank(receiver);
    underlying.transfer(address(lmUpgradeable), amount);
  }
}
