// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Ownable} from 'openzeppelin-contracts/contracts/access/Ownable.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import {ReentrancyGuard} from 'openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol';

/**
 * @title JpyUbiConvexAMO
 * @notice Convex-based AMO for JpyUbi liquidity management
 * @dev Manages liquidity provision and yield farming through Convex/Curve
 */
contract JpyUbiConvexAMO is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  address public jpyUbiToken;
  address public amoMinter;
  address public curvePool;
  address public convexBooster;
  address public convexRewards;
  uint256 public convexPoolId;

  uint256 public lpTokensDeposited;
  uint256 public mintedJpyUbi;

  event LiquidityAdded(uint256 jpyUbiAmount, uint256 otherAmount, uint256 lpReceived);
  event LiquidityRemoved(uint256 lpAmount, uint256 jpyUbiReceived, uint256 otherReceived);
  event RewardsClaimed(address indexed token, uint256 amount);
  event ConvexDeposited(uint256 lpAmount);
  event ConvexWithdrawn(uint256 lpAmount);

  error ZeroAddress();
  error InsufficientBalance();
  error NotAuthorized();

  constructor(
    address _jpyUbiToken,
    address _amoMinter,
    address _curvePool,
    address _convexBooster,
    uint256 _convexPoolId
  ) Ownable(msg.sender) {
    if (_jpyUbiToken == address(0) || _amoMinter == address(0)) revert ZeroAddress();
    jpyUbiToken = _jpyUbiToken;
    amoMinter = _amoMinter;
    curvePool = _curvePool;
    convexBooster = _convexBooster;
    convexPoolId = _convexPoolId;
  }

  function setConvexRewards(address _convexRewards) external onlyOwner {
    if (_convexRewards == address(0)) revert ZeroAddress();
    convexRewards = _convexRewards;
  }

  function addLiquidity(uint256 _jpyUbiAmount, uint256 _otherAmount, uint256 _minLp) external onlyOwner nonReentrant returns (uint256 lpReceived) {
    // Note: Actual implementation would:
    // 1. Request mint from AMO minter
    // 2. Approve curve pool
    // 3. Add liquidity to curve pool
    // 4. Return LP tokens received
    mintedJpyUbi += _jpyUbiAmount;
    emit LiquidityAdded(_jpyUbiAmount, _otherAmount, lpReceived);
    return lpReceived;
  }

  function removeLiquidity(uint256 _lpAmount, uint256 _minJpyUbi, uint256 _minOther) external onlyOwner nonReentrant returns (uint256 jpyUbiReceived, uint256 otherReceived) {
    // Note: Actual implementation would:
    // 1. Remove liquidity from curve pool
    // 2. Burn received JpyUbi through AMO minter
    // 3. Return other token to treasury
    emit LiquidityRemoved(_lpAmount, jpyUbiReceived, otherReceived);
    return (jpyUbiReceived, otherReceived);
  }

  function depositToConvex(uint256 _lpAmount) external onlyOwner nonReentrant {
    // Note: Actual implementation would deposit LP tokens to Convex
    lpTokensDeposited += _lpAmount;
    emit ConvexDeposited(_lpAmount);
  }

  function withdrawFromConvex(uint256 _lpAmount) external onlyOwner nonReentrant {
    if (_lpAmount > lpTokensDeposited) revert InsufficientBalance();
    lpTokensDeposited -= _lpAmount;
    emit ConvexWithdrawn(_lpAmount);
  }

  function claimRewards() external onlyOwner nonReentrant {
    // Note: Actual implementation would claim CRV, CVX, and other rewards
    // from Convex rewards contract
  }

  function getCollateralValue() external view returns (uint256) {
    // Note: Would calculate total value of LP tokens in USD terms
    return 0;
  }

  function getMintedJpyUbi() external view returns (uint256) {
    return mintedJpyUbi;
  }

  function emergencyWithdraw(address _token, uint256 _amount) external onlyOwner {
    IERC20(_token).safeTransfer(owner(), _amount);
  }
}
