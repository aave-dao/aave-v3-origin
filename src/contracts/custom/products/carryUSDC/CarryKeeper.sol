// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Ownable} from 'openzeppelin-contracts/contracts/access/Ownable.sol';
import {IChainlinkAutomation} from '../../integrations/morpho/interfaces/IChainlinkAutomation.sol';

interface IKeeperCarryStrategy {
  enum ShouldRebalance { NONE, REBALANCE, ITERATE, RIPCORD }
  function shouldRebalance() external view returns (ShouldRebalance);
  function rebalance() external;
  function iterateRebalance() external;
  function ripcord() external;
  function isActive() external view returns (bool);
}

/**
 * @title CarryKeeper
 * @notice Chainlink Automation keeper for multiple CarryStrategy instances
 */
contract CarryKeeper is IChainlinkAutomation, Ownable {
  address[] public strategies;
  mapping(address => uint256) public strategyIndex;
  mapping(address => bool) public isRegistered;

  event StrategyAdded(address indexed strategy);
  event StrategyRemoved(address indexed strategy);
  event RebalanceTriggered(address indexed strategy, uint8 action);

  error AlreadyRegistered();
  error NotRegistered();
  error ZeroAddress();

  constructor() Ownable(msg.sender) {}

  function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory performData) {
    uint256 len = strategies.length;
    for (uint256 i = 0; i < len; i++) {
      address strategy = strategies[i];
      IKeeperCarryStrategy s = IKeeperCarryStrategy(strategy);
      if (!s.isActive()) continue;
      IKeeperCarryStrategy.ShouldRebalance action = s.shouldRebalance();
      if (action != IKeeperCarryStrategy.ShouldRebalance.NONE) {
        return (true, abi.encode(strategy, uint8(action)));
      }
    }
    return (false, '');
  }

  function performUpkeep(bytes calldata performData) external override {
    (address strategy, uint8 actionType) = abi.decode(performData, (address, uint8));
    if (!isRegistered[strategy]) revert NotRegistered();
    IKeeperCarryStrategy s = IKeeperCarryStrategy(strategy);
    IKeeperCarryStrategy.ShouldRebalance currentAction = s.shouldRebalance();
    if (currentAction == IKeeperCarryStrategy.ShouldRebalance.NONE) return;
    if (currentAction == IKeeperCarryStrategy.ShouldRebalance.RIPCORD) s.ripcord();
    else if (currentAction == IKeeperCarryStrategy.ShouldRebalance.ITERATE) s.iterateRebalance();
    else if (currentAction == IKeeperCarryStrategy.ShouldRebalance.REBALANCE) s.rebalance();
    emit RebalanceTriggered(strategy, uint8(currentAction));
  }

  function addStrategy(address _strategy) external onlyOwner {
    if (_strategy == address(0)) revert ZeroAddress();
    if (isRegistered[_strategy]) revert AlreadyRegistered();
    strategyIndex[_strategy] = strategies.length;
    strategies.push(_strategy);
    isRegistered[_strategy] = true;
    emit StrategyAdded(_strategy);
  }

  function removeStrategy(address _strategy) external onlyOwner {
    if (!isRegistered[_strategy]) revert NotRegistered();
    uint256 index = strategyIndex[_strategy];
    uint256 lastIndex = strategies.length - 1;
    if (index != lastIndex) {
      address lastStrategy = strategies[lastIndex];
      strategies[index] = lastStrategy;
      strategyIndex[lastStrategy] = index;
    }
    strategies.pop();
    delete strategyIndex[_strategy];
    delete isRegistered[_strategy];
    emit StrategyRemoved(_strategy);
  }

  function getStrategies() external view returns (address[] memory) {
    return strategies;
  }
}
