// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import {Ownable} from 'openzeppelin-contracts/contracts/access/Ownable.sol';
import {ReentrancyGuard} from 'openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol';

import {IChainlinkAggregatorV3} from '../../integrations/morpho/interfaces/IChainlinkAutomation.sol';
import {IMilkman} from '../../integrations/morpho/interfaces/IMilkman.sol';
import {IZaibots} from '../../integrations/morpho/interfaces/IZaibots.sol';
import {ILinearBlockTwapOracle} from './LinearBlockTwapOracle.sol';

/**
 * @title CarryStrategy
 * @notice Configurable leveraged yen-carry trade strategy
 */
contract CarryStrategy is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  enum StrategyType { CONSERVATIVE, MODERATE, AGGRESSIVE }
  enum ShouldRebalance { NONE, REBALANCE, ITERATE, RIPCORD }
  enum SwapState { IDLE, PENDING_LEVER_SWAP, PENDING_DELEVER_SWAP }

  struct Addresses {
    address adapter;
    address zaibots;
    address collateralToken;
    address debtToken;
    address jpyUsdOracle;
    address twapOracle;
    address milkman;
    address priceChecker;
  }

  struct LeverageParams {
    uint64 target;
    uint64 min;
    uint64 max;
    uint64 ripcord;
  }

  struct ExecutionParams {
    uint128 maxTradeSize;
    uint32 twapCooldown;
    uint16 slippageBps;
    uint32 rebalanceInterval;
    uint64 recenterSpeed;
  }

  struct IncentiveParams {
    uint16 slippageBps;
    uint16 twapCooldown;
    uint128 maxTrade;
    uint96 etherReward;
  }

  string public name;
  StrategyType public strategyType;
  Addresses public addr;
  LeverageParams public leverage;
  ExecutionParams public execution;
  IncentiveParams public incentive;

  SwapState public swapState;
  uint64 public twapLeverageRatio;
  uint64 public lastRebalanceTs;
  uint64 public lastTradeTs;
  uint64 public pendingSwapTs;
  uint128 public pendingSwapAmount;

  mapping(address => bool) public isAllowedCaller;
  address public operator;
  bool public isActive;

  uint256 public constant FULL_PRECISION = 1e18;
  uint256 public constant SWAP_TIMEOUT = 30 minutes;
  uint256 public constant MAX_BPS = 10000;

  event Engaged(uint256 collateral, uint256 targetLeverage);
  event Disengaged(uint256 collateral);
  event Rebalanced(uint256 fromLeverage, uint256 toLeverage, bool isLever);
  event Ripcorded(address indexed caller, uint256 leverage, uint256 reward);
  event AssetsReceived(uint256 amount);
  event AssetsWithdrawn(uint256 amount);

  error NotAllowedCaller();
  error NotOperator();
  error NotAdapter();
  error SwapPending();
  error LeverageTooHigh();
  error LeverageTooLow();
  error RebalanceIntervalNotElapsed();
  error TwapNotActive();
  error StrategyNotActive();
  error AlreadyEngaged();
  error NotEngaged();
  error InsufficientEtherReward();
  error InsufficientAssets();

  modifier onlyAllowedCaller() {
    if (!isAllowedCaller[msg.sender] && msg.sender != operator && msg.sender != owner()) revert NotAllowedCaller();
    _;
  }

  modifier onlyOperator() {
    if (msg.sender != operator && msg.sender != owner()) revert NotOperator();
    _;
  }

  modifier onlyAdapter() {
    if (msg.sender != addr.adapter) revert NotAdapter();
    _;
  }

  modifier onlyEOA() {
    require(msg.sender == tx.origin, 'Not EOA');
    _;
  }

  modifier whenActive() {
    if (!isActive) revert StrategyNotActive();
    _;
  }

  modifier whenNoSwap() {
    if (swapState != SwapState.IDLE) revert SwapPending();
    _;
  }

  constructor(
    string memory _name,
    StrategyType _type,
    Addresses memory _addresses,
    uint64[4] memory _leverage,
    ExecutionParams memory _execution,
    IncentiveParams memory _incentive
  ) Ownable(msg.sender) {
    name = _name;
    strategyType = _type;
    addr = _addresses;
    leverage = LeverageParams(_leverage[0], _leverage[1], _leverage[2], _leverage[3]);
    execution = _execution;
    incentive = _incentive;
    operator = msg.sender;
    isActive = true;
    swapState = SwapState.IDLE;
    IERC20(_addresses.collateralToken).approve(_addresses.zaibots, type(uint256).max);
    IERC20(_addresses.debtToken).approve(_addresses.zaibots, type(uint256).max);
    IERC20(_addresses.debtToken).approve(_addresses.milkman, type(uint256).max);
    IERC20(_addresses.collateralToken).approve(_addresses.milkman, type(uint256).max);
  }

  function receiveAssets(uint256 amount) external onlyAdapter nonReentrant {
    IERC20(addr.collateralToken).safeTransferFrom(msg.sender, address(this), amount);
    IZaibots(addr.zaibots).supply(addr.collateralToken, amount, address(this));
    emit AssetsReceived(amount);
  }

  function withdrawAssets(uint256 amount) external onlyAdapter nonReentrant returns (uint256 withdrawn) {
    uint256 available = _getAvailableCollateral();
    uint256 toWithdraw = amount < available ? amount : available;
    if (toWithdraw == 0) revert InsufficientAssets();
    withdrawn = IZaibots(addr.zaibots).withdraw(addr.collateralToken, toWithdraw, msg.sender);
    emit AssetsWithdrawn(withdrawn);
  }

  function engage() external onlyAllowedCaller whenActive whenNoSwap nonReentrant {
    uint256 currentLev = getCurrentLeverageRatio();
    if (currentLev > FULL_PRECISION + 1e16) revert AlreadyEngaged();
    uint256 collateral = _getCollateralBalance();
    if (collateral == 0) revert NotEngaged();
    twapLeverageRatio = leverage.target;
    _lever(_calculateLeverAmount());
    emit Engaged(collateral, uint256(leverage.target) * 1e9);
  }

  function rebalance() external onlyEOA onlyAllowedCaller whenActive whenNoSwap nonReentrant {
    ShouldRebalance action = shouldRebalance();
    if (action == ShouldRebalance.NONE || action == ShouldRebalance.ITERATE) revert RebalanceIntervalNotElapsed();
    if (action == ShouldRebalance.RIPCORD) revert LeverageTooHigh();
    uint256 currentLev = getCurrentLeverageRatio();
    uint256 targetLev = _calculateNewLeverageRatio(currentLev);
    if (currentLev > targetLev) {
      _delever(_calculateDeleverAmount(currentLev, targetLev));
      emit Rebalanced(currentLev, targetLev, false);
    } else {
      _lever(_calculateLeverAmount());
      emit Rebalanced(currentLev, targetLev, true);
    }
    lastRebalanceTs = uint64(block.timestamp);
  }

  function ripcord() external onlyEOA nonReentrant {
    uint256 currentLev = getCurrentLeverageRatio();
    if (currentLev < uint256(leverage.ripcord) * 1e9) revert LeverageTooLow();
    uint256 deleverAmount = _min(_calculateDeleverAmount(currentLev, uint256(leverage.max) * 1e9), uint256(incentive.maxTrade));
    _deleverWithSlippage(deleverAmount, incentive.slippageBps);
    uint256 reward = uint256(incentive.etherReward);
    if (address(this).balance < reward) revert InsufficientEtherReward();
    (bool success, ) = msg.sender.call{value: reward}('');
    require(success, 'ETH transfer failed');
    emit Ripcorded(msg.sender, currentLev, reward);
    lastTradeTs = uint64(block.timestamp);
  }

  function getCurrentLeverageRatio() public view returns (uint256) {
    uint256 collateral = _getCollateralBalance();
    if (collateral == 0) return FULL_PRECISION;
    uint256 debt = _getDebtBalanceInBase();
    if (debt == 0) return FULL_PRECISION;
    uint256 equity = collateral > debt ? collateral - debt : 0;
    if (equity == 0) return type(uint256).max;
    return (collateral * FULL_PRECISION) / equity;
  }

  function shouldRebalance() public view returns (ShouldRebalance) {
    if (swapState != SwapState.IDLE) return ShouldRebalance.NONE;
    uint256 currentLev = getCurrentLeverageRatio();
    if (currentLev >= uint256(leverage.ripcord) * 1e9) return ShouldRebalance.RIPCORD;
    if (twapLeverageRatio != 0 && block.timestamp >= lastTradeTs + execution.twapCooldown) return ShouldRebalance.ITERATE;
    if (twapLeverageRatio != 0) return ShouldRebalance.NONE;
    if (currentLev > uint256(leverage.max) * 1e9 || currentLev < uint256(leverage.min) * 1e9) return ShouldRebalance.REBALANCE;
    if (block.timestamp >= lastRebalanceTs + execution.rebalanceInterval) {
      uint256 targetLev = uint256(leverage.target) * 1e9;
      uint256 deviation = currentLev > targetLev ? currentLev - targetLev : targetLev - currentLev;
      if (deviation > 1e16) return ShouldRebalance.REBALANCE;
    }
    return ShouldRebalance.NONE;
  }

  function getRealAssets() public view returns (uint256) {
    uint256 collateral = _getCollateralBalance();
    uint256 debt = _getDebtBalanceInBase();
    if (swapState == SwapState.PENDING_LEVER_SWAP) return collateral > debt ? collateral - debt - pendingSwapAmount : 0;
    return collateral > debt ? collateral - debt : 0;
  }

  function isEngaged() external view returns (bool) {
    return getCurrentLeverageRatio() > FULL_PRECISION + 1e16;
  }

  function _lever(uint256 _notionalBase) internal {
    if (_notionalBase == 0) return;
    uint256 tradeSize = _min(_notionalBase, execution.maxTradeSize);
    if (_notionalBase > execution.maxTradeSize) twapLeverageRatio = leverage.target;
    uint256 debtToBorrow = _calculateDebtBorrowAmount(tradeSize);
    IZaibots(addr.zaibots).borrow(addr.debtToken, debtToBorrow, address(this));
    bytes memory priceCheckerData = abi.encode(execution.slippageBps, addr.priceChecker);
    IMilkman(addr.milkman).requestSwapExactTokensForTokens(debtToBorrow, IERC20(addr.debtToken), IERC20(addr.collateralToken), address(this), addr.priceChecker, priceCheckerData);
    swapState = SwapState.PENDING_LEVER_SWAP;
    pendingSwapTs = uint64(block.timestamp);
    pendingSwapAmount = uint128(tradeSize);
    lastTradeTs = uint64(block.timestamp);
  }

  function _delever(uint256 _notionalBase) internal {
    _deleverWithSlippage(_notionalBase, execution.slippageBps);
  }

  function _deleverWithSlippage(uint256 _notionalBase, uint16 _slippageBps) internal {
    if (_notionalBase == 0) return;
    uint256 tradeSize = _min(_notionalBase, execution.maxTradeSize);
    IZaibots(addr.zaibots).withdraw(addr.collateralToken, tradeSize, address(this));
    bytes memory priceCheckerData = abi.encode(_slippageBps, addr.priceChecker);
    IMilkman(addr.milkman).requestSwapExactTokensForTokens(tradeSize, IERC20(addr.collateralToken), IERC20(addr.debtToken), address(this), addr.priceChecker, priceCheckerData);
    swapState = SwapState.PENDING_DELEVER_SWAP;
    pendingSwapTs = uint64(block.timestamp);
    pendingSwapAmount = uint128(tradeSize);
    lastTradeTs = uint64(block.timestamp);
  }

  function _getCollateralBalance() internal view returns (uint256) {
    return IZaibots(addr.zaibots).getCollateralBalance(address(this), addr.collateralToken);
  }

  function _getDebtBalance() internal view returns (uint256) {
    return IZaibots(addr.zaibots).getDebtBalance(address(this), addr.debtToken);
  }

  function _getDebtBalanceInBase() internal view returns (uint256) {
    uint256 debtBalance = _getDebtBalance();
    if (debtBalance == 0) return 0;
    (, int256 price, , , ) = IChainlinkAggregatorV3(addr.jpyUsdOracle).latestRoundData();
    return (debtBalance * uint256(price)) / 1e20;
  }

  function _getAvailableCollateral() internal view returns (uint256) {
    uint256 collateral = _getCollateralBalance();
    uint256 debt = _getDebtBalanceInBase();
    uint256 ltv = _getLTV();
    uint256 minCollateral = (debt * FULL_PRECISION) / ltv;
    return collateral > minCollateral ? collateral - minCollateral : 0;
  }

  function _getLTV() internal view returns (uint256) {
    return IZaibots(addr.zaibots).getLTV(addr.collateralToken, addr.debtToken);
  }

  function _calculateDebtBorrowAmount(uint256 baseAmount) internal view returns (uint256) {
    (, int256 price, , , ) = IChainlinkAggregatorV3(addr.jpyUsdOracle).latestRoundData();
    uint256 jpyAmount = (baseAmount * 1e20) / uint256(price);
    uint256 ltv = _getLTV();
    return (jpyAmount * ltv) / FULL_PRECISION;
  }

  function _calculateNewLeverageRatio(uint256 _currentLev) internal view returns (uint256) {
    uint256 target = uint256(leverage.target) * 1e9;
    uint256 speed = uint256(execution.recenterSpeed) * 1e9;
    if (_currentLev > target) return _currentLev - ((_currentLev - target) * speed) / FULL_PRECISION;
    return _currentLev + ((target - _currentLev) * speed) / FULL_PRECISION;
  }

  function _calculateLeverAmount() internal view returns (uint256) {
    uint256 collateral = _getCollateralBalance();
    uint256 currentLev = getCurrentLeverageRatio();
    uint256 targetLev = uint256(leverage.target) * 1e9;
    if (currentLev >= targetLev) return 0;
    uint256 debt = _getDebtBalanceInBase();
    uint256 equity = collateral > debt ? collateral - debt : 0;
    uint256 targetCollateral = (equity * targetLev) / FULL_PRECISION;
    return targetCollateral > collateral ? targetCollateral - collateral : 0;
  }

  function _calculateDeleverAmount(uint256 _currentLev, uint256 _targetLev) internal view returns (uint256) {
    uint256 collateral = _getCollateralBalance();
    uint256 debt = _getDebtBalanceInBase();
    uint256 equity = collateral > debt ? collateral - debt : 0;
    uint256 targetCollateral = (equity * _targetLev) / FULL_PRECISION;
    return collateral > targetCollateral ? collateral - targetCollateral : 0;
  }

  function _min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  function setActive(bool _isActive) external onlyOperator {
    isActive = _isActive;
  }

  function setAllowedCaller(address _caller, bool _isAllowed) external onlyOperator {
    isAllowedCaller[_caller] = _isAllowed;
  }

  function setOperator(address _operator) external onlyOwner {
    operator = _operator;
  }

  function setAdapter(address _adapter) external onlyOwner {
    addr.adapter = _adapter;
  }

  receive() external payable {}

  function withdrawEther(uint256 _amount) external onlyOperator {
    (bool success, ) = msg.sender.call{value: _amount}('');
    require(success, 'ETH transfer failed');
  }
}
