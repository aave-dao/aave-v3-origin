// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Ownable} from '../../dependencies/openzeppelin/contracts/Ownable.sol';
import {ISequencerOracle} from '../../interfaces/ISequencerOracle.sol';

contract SequencerOracle is ISequencerOracle, Ownable {
  bool internal _isDown;
  uint256 internal _timestampChangedStatus;

  /**
   * @dev Constructor.
   * @param owner The owner address of this contract
   */
  constructor(address owner) {
    transferOwnership(owner);
  }

  /**
   * @notice Updates the health status of the sequencer.
   * @param isDown True if the sequencer is down, false otherwise
   * @param timestamp The timestamp when the sequencer changed status
   */
  function setAnswer(bool isDown, uint256 timestamp) external onlyOwner {
    _isDown = isDown;
    _timestampChangedStatus = timestamp;
  }

  /// @inheritdoc ISequencerOracle
  function latestRoundData()
    external
    view
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    int256 isDown;
    if (_isDown) {
      isDown = 1;
    }
    return (0, isDown, _timestampChangedStatus, 0, 0);
  }
}
