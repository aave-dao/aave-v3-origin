// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IPool} from '../../../contracts/interfaces/IPool.sol';
import {DataTypes, ReserveConfiguration} from '../../../contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {IRewardsController} from '../../../contracts/rewards/interfaces/IRewardsController.sol';
import {WadRayMath} from '../../../contracts/protocol/libraries/math/WadRayMath.sol';
import {MathUtils} from '../../../contracts/protocol/libraries/math/MathUtils.sol';
import {SafeCast} from 'solidity-utils/contracts/oz-common/SafeCast.sol';
import {Initializable} from 'solidity-utils/contracts/transparent-proxy/Initializable.sol';
import {SafeERC20} from 'solidity-utils/contracts/oz-common/SafeERC20.sol';
import {IERC20Metadata} from 'solidity-utils/contracts/oz-common/interfaces/IERC20Metadata.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {IERC20WithPermit} from 'solidity-utils/contracts/oz-common/interfaces/IERC20WithPermit.sol';

import {IStaticATokenLM} from './interfaces/IStaticATokenLM.sol';
import {IAToken} from './interfaces/IAToken.sol';
import {ERC20} from '../dependencies/solmate/ERC20.sol';
import {IInitializableStaticATokenLM} from './interfaces/IInitializableStaticATokenLM.sol';
import {StaticATokenErrors} from './StaticATokenErrors.sol';
import {RayMathExplicitRounding, Rounding} from '../../../contracts/misc/libraries/RayMathExplicitRounding.sol';
import {IERC4626} from './interfaces/IERC4626.sol';

/**
 * @title StaticATokenLM
 * @notice Wrapper smart contract that allows to deposit tokens on the Aave protocol and receive
 * a token which balance doesn't increase automatically, but uses an ever-increasing exchange rate.
 * It supports claiming liquidity mining rewards from the Aave system.
 * @author BGD labs
 */
contract StaticATokenLM is
  Initializable,
  ERC20('STATIC__aToken_IMPL', 'STATIC__aToken_IMPL', 18),
  IStaticATokenLM,
  IERC4626
{
  using SafeERC20 for IERC20;
  using SafeCast for uint256;
  using WadRayMath for uint256;
  using RayMathExplicitRounding for uint256;

  bytes32 public constant METADEPOSIT_TYPEHASH =
    keccak256(
      'Deposit(address depositor,address receiver,uint256 assets,uint16 referralCode,bool depositToAave,uint256 nonce,uint256 deadline,PermitParams permit)'
    );
  bytes32 public constant METAWITHDRAWAL_TYPEHASH =
    keccak256(
      'Withdraw(address owner,address receiver,uint256 shares,uint256 assets,bool withdrawFromAave,uint256 nonce,uint256 deadline)'
    );

  uint256 public constant STATIC__ATOKEN_LM_REVISION = 2;

  IPool public immutable POOL;
  IRewardsController public immutable INCENTIVES_CONTROLLER;

  IERC20 internal _aToken;
  address internal _aTokenUnderlying;
  address[] internal _rewardTokens;
  mapping(address => RewardIndexCache) internal _startIndex;
  mapping(address => mapping(address => UserRewardsData)) internal _userRewardsData;

  constructor(IPool pool, IRewardsController rewardsController) {
    POOL = pool;
    INCENTIVES_CONTROLLER = rewardsController;
  }

  ///@inheritdoc IInitializableStaticATokenLM
  function initialize(
    address newAToken,
    string calldata staticATokenName,
    string calldata staticATokenSymbol
  ) external initializer {
    require(IAToken(newAToken).POOL() == address(POOL));
    _aToken = IERC20(newAToken);

    name = staticATokenName;
    symbol = staticATokenSymbol;
    decimals = IERC20Metadata(newAToken).decimals();

    _aTokenUnderlying = IAToken(newAToken).UNDERLYING_ASSET_ADDRESS();
    IERC20(_aTokenUnderlying).forceApprove(address(POOL), type(uint256).max);

    if (INCENTIVES_CONTROLLER != IRewardsController(address(0))) {
      refreshRewardTokens();
    }

    emit Initialized(newAToken, staticATokenName, staticATokenSymbol);
  }

  ///@inheritdoc IStaticATokenLM
  function refreshRewardTokens() public override {
    address[] memory rewards = INCENTIVES_CONTROLLER.getRewardsByAsset(address(_aToken));
    for (uint256 i = 0; i < rewards.length; i++) {
      _registerRewardToken(rewards[i]);
    }
  }

  ///@inheritdoc IStaticATokenLM
  function isRegisteredRewardToken(address reward) public view override returns (bool) {
    return _startIndex[reward].isRegistered;
  }

  ///@inheritdoc IStaticATokenLM
  function deposit(
    uint256 assets,
    address receiver,
    uint16 referralCode,
    bool depositToAave
  ) external returns (uint256) {
    (uint256 shares, ) = _deposit(msg.sender, receiver, 0, assets, referralCode, depositToAave);
    return shares;
  }

  ///@inheritdoc IStaticATokenLM
  function metaDeposit(
    address depositor,
    address receiver,
    uint256 assets,
    uint16 referralCode,
    bool depositToAave,
    uint256 deadline,
    PermitParams calldata permit,
    SignatureParams calldata sigParams
  ) external returns (uint256) {
    require(depositor != address(0), StaticATokenErrors.INVALID_DEPOSITOR);
    //solium-disable-next-line
    require(deadline >= block.timestamp, StaticATokenErrors.INVALID_EXPIRATION);
    uint256 nonce = nonces[depositor];

    // Unchecked because the only math done is incrementing
    // the owner's nonce which cannot realistically overflow.
    unchecked {
      bytes32 digest = keccak256(
        abi.encodePacked(
          '\x19\x01',
          DOMAIN_SEPARATOR(),
          keccak256(
            abi.encode(
              METADEPOSIT_TYPEHASH,
              depositor,
              receiver,
              assets,
              referralCode,
              depositToAave,
              nonce,
              deadline,
              permit
            )
          )
        )
      );
      nonces[depositor] = nonce + 1;
      require(
        depositor == ecrecover(digest, sigParams.v, sigParams.r, sigParams.s),
        StaticATokenErrors.INVALID_SIGNATURE
      );
    }
    // assume if deadline 0 no permit was supplied
    if (permit.deadline != 0) {
      try
        IERC20WithPermit(depositToAave ? address(_aTokenUnderlying) : address(_aToken)).permit(
          depositor,
          address(this),
          permit.value,
          permit.deadline,
          permit.v,
          permit.r,
          permit.s
        )
      {} catch {}
    }
    (uint256 shares, ) = _deposit(depositor, receiver, 0, assets, referralCode, depositToAave);
    return shares;
  }

  ///@inheritdoc IStaticATokenLM
  function metaWithdraw(
    address owner,
    address receiver,
    uint256 shares,
    uint256 assets,
    bool withdrawFromAave,
    uint256 deadline,
    SignatureParams calldata sigParams
  ) external returns (uint256, uint256) {
    require(owner != address(0), StaticATokenErrors.INVALID_OWNER);
    //solium-disable-next-line
    require(deadline >= block.timestamp, StaticATokenErrors.INVALID_EXPIRATION);
    uint256 nonce = nonces[owner];
    // Unchecked because the only math done is incrementing
    // the owner's nonce which cannot realistically overflow.
    unchecked {
      bytes32 digest = keccak256(
        abi.encodePacked(
          '\x19\x01',
          DOMAIN_SEPARATOR(),
          keccak256(
            abi.encode(
              METAWITHDRAWAL_TYPEHASH,
              owner,
              receiver,
              shares,
              assets,
              withdrawFromAave,
              nonce,
              deadline
            )
          )
        )
      );
      nonces[owner] = nonce + 1;
      require(
        owner == ecrecover(digest, sigParams.v, sigParams.r, sigParams.s),
        StaticATokenErrors.INVALID_SIGNATURE
      );
    }
    return _withdraw(owner, receiver, shares, assets, withdrawFromAave);
  }

  ///@inheritdoc IERC4626
  function previewRedeem(uint256 shares) public view virtual returns (uint256) {
    return _convertToAssets(shares, Rounding.DOWN);
  }

  ///@inheritdoc IERC4626
  function previewMint(uint256 shares) public view virtual returns (uint256) {
    return _convertToAssets(shares, Rounding.UP);
  }

  ///@inheritdoc IERC4626
  function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
    return _convertToShares(assets, Rounding.UP);
  }

  ///@inheritdoc IERC4626
  function previewDeposit(uint256 assets) public view virtual returns (uint256) {
    return _convertToShares(assets, Rounding.DOWN);
  }

  ///@inheritdoc IStaticATokenLM
  function rate() public view returns (uint256) {
    return POOL.getReserveNormalizedIncome(_aTokenUnderlying);
  }

  ///@inheritdoc IStaticATokenLM
  function collectAndUpdateRewards(address reward) public returns (uint256) {
    if (reward == address(0)) {
      return 0;
    }

    address[] memory assets = new address[](1);
    assets[0] = address(_aToken);

    return INCENTIVES_CONTROLLER.claimRewards(assets, type(uint256).max, address(this), reward);
  }

  ///@inheritdoc IStaticATokenLM
  function claimRewardsOnBehalf(
    address onBehalfOf,
    address receiver,
    address[] memory rewards
  ) external {
    require(
      msg.sender == onBehalfOf || msg.sender == INCENTIVES_CONTROLLER.getClaimer(onBehalfOf),
      StaticATokenErrors.INVALID_CLAIMER
    );
    _claimRewardsOnBehalf(onBehalfOf, receiver, rewards);
  }

  ///@inheritdoc IStaticATokenLM
  function claimRewards(address receiver, address[] memory rewards) external {
    _claimRewardsOnBehalf(msg.sender, receiver, rewards);
  }

  ///@inheritdoc IStaticATokenLM
  function claimRewardsToSelf(address[] memory rewards) external {
    _claimRewardsOnBehalf(msg.sender, msg.sender, rewards);
  }

  ///@inheritdoc IStaticATokenLM
  function getCurrentRewardsIndex(address reward) public view returns (uint256) {
    if (address(reward) == address(0)) {
      return 0;
    }
    (, uint256 nextIndex) = INCENTIVES_CONTROLLER.getAssetIndex(address(_aToken), reward);
    return nextIndex;
  }

  ///@inheritdoc IStaticATokenLM
  function getTotalClaimableRewards(address reward) external view returns (uint256) {
    if (reward == address(0)) {
      return 0;
    }

    address[] memory assets = new address[](1);
    assets[0] = address(_aToken);
    uint256 freshRewards = INCENTIVES_CONTROLLER.getUserRewards(assets, address(this), reward);
    return IERC20(reward).balanceOf(address(this)) + freshRewards;
  }

  ///@inheritdoc IStaticATokenLM
  function getClaimableRewards(address user, address reward) external view returns (uint256) {
    return _getClaimableRewards(user, reward, balanceOf[user], getCurrentRewardsIndex(reward));
  }

  ///@inheritdoc IStaticATokenLM
  function getUnclaimedRewards(address user, address reward) external view returns (uint256) {
    return _userRewardsData[user][reward].unclaimedRewards;
  }

  ///@inheritdoc IERC4626
  function asset() external view returns (address) {
    return address(_aTokenUnderlying);
  }

  ///@inheritdoc IStaticATokenLM
  function aToken() external view returns (IERC20) {
    return _aToken;
  }

  ///@inheritdoc IStaticATokenLM
  function rewardTokens() external view returns (address[] memory) {
    return _rewardTokens;
  }

  ///@inheritdoc IERC4626
  function totalAssets() external view returns (uint256) {
    return _aToken.balanceOf(address(this));
  }

  ///@inheritdoc IERC4626
  function convertToShares(uint256 assets) external view returns (uint256) {
    return _convertToShares(assets, Rounding.DOWN);
  }

  ///@inheritdoc IERC4626
  function convertToAssets(uint256 shares) external view returns (uint256) {
    return _convertToAssets(shares, Rounding.DOWN);
  }

  ///@inheritdoc IERC4626
  function maxMint(address) public view virtual returns (uint256) {
    uint256 assets = maxDeposit(address(0));
    if (assets == type(uint256).max) return type(uint256).max;
    return _convertToShares(assets, Rounding.DOWN);
  }

  ///@inheritdoc IERC4626
  function maxWithdraw(address owner) public view virtual returns (uint256) {
    uint256 shares = maxRedeem(owner);
    return _convertToAssets(shares, Rounding.DOWN);
  }

  ///@inheritdoc IERC4626
  function maxRedeem(address owner) public view virtual returns (uint256) {
    address cachedATokenUnderlying = _aTokenUnderlying;
    DataTypes.ReserveDataLegacy memory reserveData = POOL.getReserveData(cachedATokenUnderlying);

    // if paused or inactive users cannot withdraw underlying
    if (
      !ReserveConfiguration.getActive(reserveData.configuration) ||
      ReserveConfiguration.getPaused(reserveData.configuration)
    ) {
      return 0;
    }

    // otherwise users can withdraw up to the available amount
    uint256 underlyingTokenBalanceInShares = _convertToShares(
      IERC20(cachedATokenUnderlying).balanceOf(reserveData.aTokenAddress),
      Rounding.DOWN
    );
    uint256 cachedUserBalance = balanceOf[owner];
    return
      underlyingTokenBalanceInShares >= cachedUserBalance
        ? cachedUserBalance
        : underlyingTokenBalanceInShares;
  }

  ///@inheritdoc IERC4626
  function maxDeposit(address) public view virtual returns (uint256) {
    DataTypes.ReserveDataLegacy memory reserveData = POOL.getReserveData(_aTokenUnderlying);

    // if inactive, paused or frozen users cannot deposit underlying
    if (
      !ReserveConfiguration.getActive(reserveData.configuration) ||
      ReserveConfiguration.getPaused(reserveData.configuration) ||
      ReserveConfiguration.getFrozen(reserveData.configuration)
    ) {
      return 0;
    }

    uint256 supplyCap = ReserveConfiguration.getSupplyCap(reserveData.configuration) *
      (10 ** ReserveConfiguration.getDecimals(reserveData.configuration));
    // if no supply cap deposit is unlimited
    if (supplyCap == 0) return type(uint256).max;
    // return remaining supply cap margin
    uint256 currentSupply = (IAToken(reserveData.aTokenAddress).scaledTotalSupply() +
      reserveData.accruedToTreasury).rayMulRoundUp(_getNormalizedIncome(reserveData));
    return currentSupply > supplyCap ? 0 : supplyCap - currentSupply;
  }

  ///@inheritdoc IERC4626
  function deposit(uint256 assets, address receiver) external virtual returns (uint256) {
    (uint256 shares, ) = _deposit(msg.sender, receiver, 0, assets, 0, true);
    return shares;
  }

  ///@inheritdoc IERC4626
  function mint(uint256 shares, address receiver) external virtual returns (uint256) {
    (, uint256 assets) = _deposit(msg.sender, receiver, shares, 0, 0, true);

    return assets;
  }

  ///@inheritdoc IERC4626
  function withdraw(
    uint256 assets,
    address receiver,
    address owner
  ) external virtual returns (uint256) {
    (uint256 shares, ) = _withdraw(owner, receiver, 0, assets, true);

    return shares;
  }

  ///@inheritdoc IERC4626
  function redeem(
    uint256 shares,
    address receiver,
    address owner
  ) external virtual returns (uint256) {
    (, uint256 assets) = _withdraw(owner, receiver, shares, 0, true);

    return assets;
  }

  ///@inheritdoc IStaticATokenLM
  function redeem(
    uint256 shares,
    address receiver,
    address owner,
    bool withdrawFromAave
  ) external virtual returns (uint256, uint256) {
    return _withdraw(owner, receiver, shares, 0, withdrawFromAave);
  }

  function _deposit(
    address depositor,
    address receiver,
    uint256 _shares,
    uint256 _assets,
    uint16 referralCode,
    bool depositToAave
  ) internal returns (uint256, uint256) {
    require(receiver != address(0), StaticATokenErrors.INVALID_RECIPIENT);
    require(_shares == 0 || _assets == 0, StaticATokenErrors.ONLY_ONE_AMOUNT_FORMAT_ALLOWED);

    uint256 assets = _assets;
    uint256 shares = _shares;
    if (shares > 0) {
      if (depositToAave) {
        require(shares <= maxMint(receiver), 'ERC4626: mint more than max');
      }
      assets = previewMint(shares);
    } else {
      if (depositToAave) {
        require(assets <= maxDeposit(receiver), 'ERC4626: deposit more than max');
      }
      shares = previewDeposit(assets);
    }
    require(shares != 0, StaticATokenErrors.INVALID_ZERO_AMOUNT);

    if (depositToAave) {
      address cachedATokenUnderlying = _aTokenUnderlying;
      IERC20(cachedATokenUnderlying).safeTransferFrom(depositor, address(this), assets);
      POOL.deposit(cachedATokenUnderlying, assets, address(this), referralCode);
    } else {
      _aToken.safeTransferFrom(depositor, address(this), assets);
    }

    _mint(receiver, shares);

    emit Deposit(depositor, receiver, assets, shares);

    return (shares, assets);
  }

  function _withdraw(
    address owner,
    address receiver,
    uint256 _shares,
    uint256 _assets,
    bool withdrawFromAave
  ) internal returns (uint256, uint256) {
    require(receiver != address(0), StaticATokenErrors.INVALID_RECIPIENT);
    require(_shares == 0 || _assets == 0, StaticATokenErrors.ONLY_ONE_AMOUNT_FORMAT_ALLOWED);
    require(_shares != _assets, StaticATokenErrors.INVALID_ZERO_AMOUNT);

    uint256 assets = _assets;
    uint256 shares = _shares;

    if (shares > 0) {
      if (withdrawFromAave) {
        require(shares <= maxRedeem(owner), 'ERC4626: redeem more than max');
      }
      assets = previewRedeem(shares);
    } else {
      if (withdrawFromAave) {
        require(assets <= maxWithdraw(owner), 'ERC4626: withdraw more than max');
      }
      shares = previewWithdraw(assets);
    }

    if (msg.sender != owner) {
      uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

      if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
    }

    _burn(owner, shares);

    emit Withdraw(msg.sender, receiver, owner, assets, shares);

    if (withdrawFromAave) {
      POOL.withdraw(_aTokenUnderlying, assets, receiver);
    } else {
      _aToken.safeTransfer(receiver, assets);
    }

    return (shares, assets);
  }

  /**
   * @notice Updates rewards for senders and receiver in a transfer (not updating rewards for address(0))
   * @param from The address of the sender of tokens
   * @param to The address of the receiver of tokens
   */
  function _beforeTokenTransfer(address from, address to, uint256) internal override {
    for (uint256 i = 0; i < _rewardTokens.length; i++) {
      address rewardToken = address(_rewardTokens[i]);
      uint256 rewardsIndex = getCurrentRewardsIndex(rewardToken);
      if (from != address(0)) {
        _updateUser(from, rewardsIndex, rewardToken);
      }
      if (to != address(0) && from != to) {
        _updateUser(to, rewardsIndex, rewardToken);
      }
    }
  }

  /**
   * @notice Adding the pending rewards to the unclaimed for specific user and updating user index
   * @param user The address of the user to update
   * @param currentRewardsIndex The current rewardIndex
   * @param rewardToken The address of the reward token
   */
  function _updateUser(address user, uint256 currentRewardsIndex, address rewardToken) internal {
    uint256 balance = balanceOf[user];
    if (balance > 0) {
      _userRewardsData[user][rewardToken].unclaimedRewards = _getClaimableRewards(
        user,
        rewardToken,
        balance,
        currentRewardsIndex
      ).toUint128();
    }
    _userRewardsData[user][rewardToken].rewardsIndexOnLastInteraction = currentRewardsIndex
      .toUint128();
  }

  /**
   * @notice Compute the pending in WAD. Pending is the amount to add (not yet unclaimed) rewards in WAD.
   * @param balance The balance of the user
   * @param rewardsIndexOnLastInteraction The index which was on the last interaction of the user
   * @param currentRewardsIndex The current rewards index in the system
   * @param assetUnit One unit of asset (10**decimals)
   * @return The amount of pending rewards in WAD
   */
  function _getPendingRewards(
    uint256 balance,
    uint256 rewardsIndexOnLastInteraction,
    uint256 currentRewardsIndex,
    uint256 assetUnit
  ) internal pure returns (uint256) {
    if (balance == 0) {
      return 0;
    }
    return (balance * (currentRewardsIndex - rewardsIndexOnLastInteraction)) / assetUnit;
  }

  /**
   * @notice Compute the claimable rewards for a user
   * @param user The address of the user
   * @param reward The address of the reward
   * @param balance The balance of the user in WAD
   * @param currentRewardsIndex The current rewards index
   * @return The total rewards that can be claimed by the user (if `fresh` flag true, after updating rewards)
   */
  function _getClaimableRewards(
    address user,
    address reward,
    uint256 balance,
    uint256 currentRewardsIndex
  ) internal view returns (uint256) {
    RewardIndexCache memory rewardsIndexCache = _startIndex[reward];
    require(rewardsIndexCache.isRegistered == true, StaticATokenErrors.REWARD_NOT_INITIALIZED);
    UserRewardsData memory currentUserRewardsData = _userRewardsData[user][reward];
    uint256 assetUnit = 10 ** decimals;
    return
      currentUserRewardsData.unclaimedRewards +
      _getPendingRewards(
        balance,
        currentUserRewardsData.rewardsIndexOnLastInteraction == 0
          ? rewardsIndexCache.lastUpdatedIndex
          : currentUserRewardsData.rewardsIndexOnLastInteraction,
        currentRewardsIndex,
        assetUnit
      );
  }

  /**
   * @notice Claim rewards on behalf of a user and send them to a receiver
   * @param onBehalfOf The address to claim on behalf of
   * @param rewards The addresses of the rewards
   * @param receiver The address to receive the rewards
   */
  function _claimRewardsOnBehalf(
    address onBehalfOf,
    address receiver,
    address[] memory rewards
  ) internal {
    for (uint256 i = 0; i < rewards.length; i++) {
      if (address(rewards[i]) == address(0)) {
        continue;
      }
      uint256 currentRewardsIndex = getCurrentRewardsIndex(rewards[i]);
      uint256 balance = balanceOf[onBehalfOf];
      uint256 userReward = _getClaimableRewards(
        onBehalfOf,
        rewards[i],
        balance,
        currentRewardsIndex
      );
      uint256 totalRewardTokenBalance = IERC20(rewards[i]).balanceOf(address(this));
      uint256 unclaimedReward = 0;

      if (userReward > totalRewardTokenBalance) {
        totalRewardTokenBalance += collectAndUpdateRewards(address(rewards[i]));
      }

      if (userReward > totalRewardTokenBalance) {
        unclaimedReward = userReward - totalRewardTokenBalance;
        userReward = totalRewardTokenBalance;
      }
      if (userReward > 0) {
        _userRewardsData[onBehalfOf][rewards[i]].unclaimedRewards = unclaimedReward.toUint128();
        _userRewardsData[onBehalfOf][rewards[i]].rewardsIndexOnLastInteraction = currentRewardsIndex
          .toUint128();
        IERC20(rewards[i]).safeTransfer(receiver, userReward);
      }
    }
  }

  function _convertToShares(uint256 assets, Rounding rounding) internal view returns (uint256) {
    if (rounding == Rounding.UP) return assets.rayDivRoundUp(rate());
    return assets.rayDivRoundDown(rate());
  }

  function _convertToAssets(uint256 shares, Rounding rounding) internal view returns (uint256) {
    if (rounding == Rounding.UP) return shares.rayMulRoundUp(rate());
    return shares.rayMulRoundDown(rate());
  }

  /**
   * @notice Initializes a new rewardToken
   * @param reward The reward token to be registered
   */
  function _registerRewardToken(address reward) internal {
    if (isRegisteredRewardToken(reward)) return;
    uint256 startIndex = getCurrentRewardsIndex(reward);

    _rewardTokens.push(reward);
    _startIndex[reward] = RewardIndexCache(true, startIndex.toUint240());

    emit RewardTokenRegistered(reward, startIndex);
  }

  /**
   * Copy of https://github.com/aave/aave-v3-core/blob/29ff9b9f89af7cd8255231bc5faf26c3ce0fb7ce/contracts/protocol/libraries/logic/ReserveLogic.sol#L47 with memory instead of calldata
   * @notice Returns the ongoing normalized income for the reserve.
   * @dev A value of 1e27 means there is no income. As time passes, the income is accrued
   * @dev A value of 2*1e27 means for each unit of asset one unit of income has been accrued
   * @param reserve The reserve object
   * @return The normalized income, expressed in ray
   */
  function _getNormalizedIncome(
    DataTypes.ReserveDataLegacy memory reserve
  ) internal view returns (uint256) {
    uint40 timestamp = reserve.lastUpdateTimestamp;

    //solium-disable-next-line
    if (timestamp == block.timestamp) {
      //if the index was updated in the same block, no need to perform any calculation
      return reserve.liquidityIndex;
    } else {
      return
        MathUtils.calculateLinearInterest(reserve.currentLiquidityRate, timestamp).rayMul(
          reserve.liquidityIndex
        );
    }
  }
}
