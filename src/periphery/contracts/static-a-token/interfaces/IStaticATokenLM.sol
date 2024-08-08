// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {IERC4626} from './IERC4626.sol';
import {IInitializableStaticATokenLM} from './IInitializableStaticATokenLM.sol';

interface IStaticATokenLM is IInitializableStaticATokenLM, IERC4626 {
  struct SignatureParams {
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  struct PermitParams {
    uint256 value;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  struct UserRewardsData {
    uint128 rewardsIndexOnLastInteraction; // (in RAYs)
    uint128 unclaimedRewards; // (in RAYs)
  }

  struct RewardIndexCache {
    bool isRegistered;
    uint248 lastUpdatedIndex;
  }

  error OnlyPauseGuardian(address caller);

  event RewardTokenRegistered(address indexed reward, uint256 startIndex);

  /**
   * @notice Burns `amount` of static aToken, with receiver receiving the corresponding amount of `ASSET`
   * @param shares The amount to withdraw, in static balance of StaticAToken
   * @param receiver The address that will receive the amount of `ASSET` withdrawn from the Aave protocol
   * @param withdrawFromAave bool
   * - `true` for the receiver to get underlying tokens (e.g. USDC)
   * - `false` for the receiver to get aTokens (e.g. aUSDC)
   * @return amountToBurn: StaticATokens burnt, static balance
   * @return amountToWithdraw: underlying/aToken send to `receiver`, dynamic balance
   **/
  function redeem(
    uint256 shares,
    address receiver,
    address owner,
    bool withdrawFromAave
  ) external returns (uint256, uint256);

  /**
   * @notice Deposits `ASSET` in the Aave protocol and mints static aTokens to msg.sender
   * @param assets The amount of underlying `ASSET` to deposit (e.g. deposit of 100 USDC)
   * @param receiver The address that will receive the static aTokens
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param depositToAave bool
   * - `true` if the msg.sender comes with underlying tokens (e.g. USDC)
   * - `false` if the msg.sender comes already with aTokens (e.g. aUSDC)
   * @return uint256 The amount of StaticAToken minted, static balance
   **/
  function deposit(
    uint256 assets,
    address receiver,
    uint16 referralCode,
    bool depositToAave
  ) external returns (uint256);

  /**
   * @notice Allows to deposit on Aave via meta-transaction
   * https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
   * @param depositor Address from which the funds to deposit are going to be pulled
   * @param receiver Address that will receive the staticATokens, in the average case, same as the `depositor`
   * @param assets The amount to deposit
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param depositToAave bool
   * - `true` if the msg.sender comes with underlying tokens (e.g. USDC)
   * - `false` if the msg.sender comes already with aTokens (e.g. aUSDC)
   * @param deadline The deadline timestamp, type(uint256).max for max deadline
   * @param sigParams Signature params: v,r,s
   * @return uint256 The amount of StaticAToken minted, static balance
   */
  function metaDeposit(
    address depositor,
    address receiver,
    uint256 assets,
    uint16 referralCode,
    bool depositToAave,
    uint256 deadline,
    PermitParams calldata permit,
    SignatureParams calldata sigParams
  ) external returns (uint256);

  /**
   * @notice Allows to withdraw from Aave via meta-transaction
   * https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
   * @param owner Address owning the staticATokens
   * @param receiver Address that will receive the underlying withdrawn from Aave
   * @param shares The amount of staticAToken to withdraw. If > 0, `assets` needs to be 0
   * @param assets The amount of underlying/aToken to withdraw. If > 0, `shares` needs to be 0
   * @param withdrawFromAave bool
   * - `true` for the receiver to get underlying tokens (e.g. USDC)
   * - `false` for the receiver to get aTokens (e.g. aUSDC)
   * @param deadline The deadline timestamp, type(uint256).max for max deadline
   * @param sigParams Signature params: v,r,s
   * @return amountToBurn: StaticATokens burnt, static balance
   * @return amountToWithdraw: underlying/aToken send to `receiver`, dynamic balance
   */
  function metaWithdraw(
    address owner,
    address receiver,
    uint256 shares,
    uint256 assets,
    bool withdrawFromAave,
    uint256 deadline,
    SignatureParams calldata sigParams
  ) external returns (uint256, uint256);

  /**
   * @notice Returns the Aave liquidity index of the underlying aToken, denominated rate here
   * as it can be considered as an ever-increasing exchange rate
   * @return The liquidity index
   **/
  function rate() external view returns (uint256);

  /**
   * @notice Claims rewards from `INCENTIVES_CONTROLLER` and updates internal accounting of rewards.
   * @param reward The reward to claim
   * @return uint256 Amount collected
   */
  function collectAndUpdateRewards(address reward) external returns (uint256);

  /**
   * @notice Claim rewards on behalf of a user and send them to a receiver
   * @dev Only callable by if sender is onBehalfOf or sender is approved claimer
   * @param onBehalfOf The address to claim on behalf of
   * @param receiver The address to receive the rewards
   * @param rewards The rewards to claim
   */
  function claimRewardsOnBehalf(
    address onBehalfOf,
    address receiver,
    address[] memory rewards
  ) external;

  /**
   * @notice Claim rewards and send them to a receiver
   * @param receiver The address to receive the rewards
   * @param rewards The rewards to claim
   */
  function claimRewards(address receiver, address[] memory rewards) external;

  /**
   * @notice Claim rewards
   * @param rewards The rewards to claim
   */
  function claimRewardsToSelf(address[] memory rewards) external;

  /**
   * @notice Get the total claimable rewards of the contract.
   * @param reward The reward to claim
   * @return uint256 The current balance + pending rewards from the `_incentivesController`
   */
  function getTotalClaimableRewards(address reward) external view returns (uint256);

  /**
   * @notice Get the total claimable rewards for a user in WAD
   * @param user The address of the user
   * @param reward The reward to claim
   * @return uint256 The claimable amount of rewards in WAD
   */
  function getClaimableRewards(address user, address reward) external view returns (uint256);

  /**
   * @notice The unclaimed rewards for a user in WAD
   * @param user The address of the user
   * @param reward The reward to claim
   * @return uint256 The unclaimed amount of rewards in WAD
   */
  function getUnclaimedRewards(address user, address reward) external view returns (uint256);

  /**
   * @notice The underlying asset reward index in RAY
   * @param reward The reward to claim
   * @return uint256 The underlying asset reward index in RAY
   */
  function getCurrentRewardsIndex(address reward) external view returns (uint256);

  /**
   * @notice The aToken used inside the 4626 vault.
   * @return IERC20 The aToken IERC20.
   */
  function aToken() external view returns (IERC20);

  /**
   * @notice The IERC20s that are currently rewarded to addresses of the vault via LM on incentivescontroller.
   * @return IERC20 The IERC20s of the rewards.
   */
  function rewardTokens() external view returns (address[] memory);

  /**
   * @notice Fetches all rewardTokens from the incentivecontroller and registers the missing ones.
   */
  function refreshRewardTokens() external;

  /**
   * @notice Checks if the passed token is a registered reward.
   * @param reward The reward to claim
   * @return bool signaling if token is a registered reward.
   */
  function isRegisteredRewardToken(address reward) external view returns (bool);

  /**
   * @notice Pauses/unpauses all system's operations
   * @param paused boolean determining if the token should be paused or unpaused
   */
  function setPaused(bool paused) external;
}
