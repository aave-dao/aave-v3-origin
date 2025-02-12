// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AccessControlUpgradeable} from 'openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol';
import {ReentrancyGuardUpgradeable} from 'openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import {Address} from 'openzeppelin-contracts/contracts/utils/Address.sol';
import {ICollector} from './ICollector.sol';

/**
 * @title Collector
 * @notice Stores ERC20 tokens of an ecosystem reserve and allows to dispose of them via approval
 * or transfer dynamics or streaming capabilities.
 * Modification of Sablier https://github.com/sablierhq/sablier/blob/develop/packages/protocol/contracts/Sablier.sol
 * Original can be found also deployed on https://etherscan.io/address/0xCD18eAa163733Da39c232722cBC4E8940b1D8888
 * Modifications:
 * - Sablier "pulls" the funds from the creator of the stream at creation. In the Aave case, we already have the funds.
 * - Anybody can create streams on Sablier. Here, only the funds admin (Aave governance via controller) can
 * - Adapted codebase to Solidity 0.8.11, mainly removing SafeMath and CarefulMath to use native safe math
 * - Same as with creation, on Sablier the `sender` and `recipient` can cancel a stream. Here, only fund admin and recipient
 * @author BGD Labs
 **/
contract Collector is AccessControlUpgradeable, ReentrancyGuardUpgradeable, ICollector {
  using SafeERC20 for IERC20;
  using Address for address payable;

  /*** Storage Properties ***/
  /// @inheritdoc ICollector
  address public constant ETH_MOCK_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /// @inheritdoc ICollector
  bytes32 public constant FUNDS_ADMIN_ROLE = 'FUNDS_ADMIN';

  // Reserved storage space to account for deprecated inherited storage
  // 0 was lastInitializedRevision
  // 1-50 were the ____gap
  // 51 was the reentrancy guard _status
  // 52 was the _fundsAdmin
  // On some networks the layout was shifted by 1 due to `initializing` being on slot 1
  // The upgrade proposal would in this case manually shift the storage layout to properly align the networks
  uint256[53] private ______gap;

  /**
   * @notice Counter for new stream ids.
   */
  uint256 private _nextStreamId;

  /**
   * @notice The stream objects identifiable by their unsigned integer ids.
   */
  mapping(uint256 => Stream) private _streams;

  /*** Modifiers ***/

  /**
   * @dev Throws if the caller does not have the FUNDS_ADMIN role
   */
  modifier onlyFundsAdmin() {
    if (_onlyFundsAdmin() == false) {
      revert OnlyFundsAdmin();
    }
    _;
  }

  /**
   * @dev Throws if the caller is not the funds admin of the recipient of the stream.
   * @param streamId The id of the stream to query.
   */
  modifier onlyAdminOrRecipient(uint256 streamId) {
    if (_onlyFundsAdmin() == false && msg.sender != _streams[streamId].recipient) {
      revert OnlyFundsAdminOrRecipient();
    }
    _;
  }

  /**
   * @dev Throws if the provided id does not point to a valid stream.
   */
  modifier streamExists(uint256 streamId) {
    if (!_streams[streamId].isEntity) revert StreamDoesNotExist();
    _;
  }

  constructor() {
    _disableInitializers();
  }

  /*** Contract Logic Starts Here */

  /** @notice Initializes the contracts
   * @param nextStreamId StreamId to set, applied if greater than 0
   * @param admin The default admin managing the FundsAdmins
   **/
  function initialize(uint256 nextStreamId, address admin) external virtual initializer {
    __AccessControl_init();
    __ReentrancyGuard_init();
    _grantRole(DEFAULT_ADMIN_ROLE, admin);
    _grantRole(FUNDS_ADMIN_ROLE, admin);
    if (nextStreamId != 0) {
      _nextStreamId = nextStreamId;
    }
  }

  /*** View Functions ***/
  /// @inheritdoc ICollector
  function isFundsAdmin(address admin) external view returns (bool) {
    return hasRole(FUNDS_ADMIN_ROLE, admin);
  }

  /// @inheritdoc ICollector
  function getNextStreamId() external view returns (uint256) {
    return _nextStreamId;
  }

  /// @inheritdoc ICollector
  function getStream(
    uint256 streamId
  )
    external
    view
    streamExists(streamId)
    returns (
      address sender,
      address recipient,
      uint256 deposit,
      address tokenAddress,
      uint256 startTime,
      uint256 stopTime,
      uint256 remainingBalance,
      uint256 ratePerSecond
    )
  {
    sender = _streams[streamId].sender;
    recipient = _streams[streamId].recipient;
    deposit = _streams[streamId].deposit;
    tokenAddress = _streams[streamId].tokenAddress;
    startTime = _streams[streamId].startTime;
    stopTime = _streams[streamId].stopTime;
    remainingBalance = _streams[streamId].remainingBalance;
    ratePerSecond = _streams[streamId].ratePerSecond;
  }

  /**
   * @notice Returns either the delta in seconds between `block.timestamp` and `startTime` or
   *  between `stopTime` and `startTime, whichever is smaller. If `block.timestamp` is before
   *  `startTime`, it returns 0.
   * @dev Throws if the id does not point to a valid stream.
   * @param streamId The id of the stream for which to query the delta.
   * @notice Returns the time delta in seconds.
   */
  function deltaOf(uint256 streamId) public view streamExists(streamId) returns (uint256 delta) {
    Stream memory stream = _streams[streamId];
    if (block.timestamp <= stream.startTime) return 0;
    if (block.timestamp < stream.stopTime) return block.timestamp - stream.startTime;
    return stream.stopTime - stream.startTime;
  }

  struct BalanceOfLocalVars {
    uint256 recipientBalance;
    uint256 withdrawalAmount;
    uint256 senderBalance;
  }

  /// @inheritdoc ICollector
  function balanceOf(
    uint256 streamId,
    address who
  ) public view streamExists(streamId) returns (uint256 balance) {
    Stream memory stream = _streams[streamId];
    BalanceOfLocalVars memory vars;

    uint256 delta = deltaOf(streamId);
    vars.recipientBalance = delta * stream.ratePerSecond;

    /*
     * If the stream `balance` does not equal `deposit`, it means there have been withdrawals.
     * We have to subtract the total amount withdrawn from the amount of money that has been
     * streamed until now.
     */
    if (stream.deposit > stream.remainingBalance) {
      vars.withdrawalAmount = stream.deposit - stream.remainingBalance;
      vars.recipientBalance = vars.recipientBalance - vars.withdrawalAmount;
    }

    if (who == stream.recipient) return vars.recipientBalance;
    if (who == stream.sender) {
      vars.senderBalance = stream.remainingBalance - vars.recipientBalance;
      return vars.senderBalance;
    }
    return 0;
  }

  /*** Public Effects & Interactions Functions ***/

  /// @inheritdoc ICollector
  function approve(IERC20 token, address recipient, uint256 amount) external onlyFundsAdmin {
    token.forceApprove(recipient, amount);
  }

  /// @inheritdoc ICollector
  function transfer(IERC20 token, address recipient, uint256 amount) external onlyFundsAdmin {
    if (recipient == address(0)) revert InvalidZeroAddress();

    if (address(token) == ETH_MOCK_ADDRESS) {
      payable(recipient).sendValue(amount);
    } else {
      token.safeTransfer(recipient, amount);
    }
  }

  function _onlyFundsAdmin() internal view returns (bool) {
    return hasRole(FUNDS_ADMIN_ROLE, msg.sender);
  }

  struct CreateStreamLocalVars {
    uint256 duration;
    uint256 ratePerSecond;
  }

  /// @inheritdoc ICollector
  /**
   * @dev Throws if the recipient is the zero address, the contract itself or the caller.
   *  Throws if the deposit is 0.
   *  Throws if the start time is before `block.timestamp`.
   *  Throws if the stop time is before the start time.
   *  Throws if the duration calculation has a math error.
   *  Throws if the deposit is smaller than the duration.
   *  Throws if the deposit is not a multiple of the duration.
   *  Throws if the rate calculation has a math error.
   *  Throws if the next stream id calculation has a math error.
   *  Throws if the contract is not allowed to transfer enough tokens.
   *  Throws if there is a token transfer failure.
   */
  function createStream(
    address recipient,
    uint256 deposit,
    address tokenAddress,
    uint256 startTime,
    uint256 stopTime
  ) external onlyFundsAdmin returns (uint256) {
    if (recipient == address(0)) revert InvalidZeroAddress();
    if (recipient == address(this)) revert InvalidRecipient();
    if (recipient == msg.sender) revert InvalidRecipient();
    if (deposit == 0) revert InvalidZeroAmount();
    if (startTime < block.timestamp) revert InvalidStartTime();
    if (stopTime <= startTime) revert InvalidStopTime();

    CreateStreamLocalVars memory vars;
    vars.duration = stopTime - startTime;

    /* Without this, the rate per second would be zero. */
    if (deposit < vars.duration) revert DepositSmallerTimeDelta();

    /* This condition avoids dealing with remainders */
    if (deposit % vars.duration > 0) revert DepositNotMultipleTimeDelta();

    vars.ratePerSecond = deposit / vars.duration;

    /* Create and store the stream object. */
    uint256 streamId = _nextStreamId;
    _streams[streamId] = Stream({
      remainingBalance: deposit,
      deposit: deposit,
      isEntity: true,
      ratePerSecond: vars.ratePerSecond,
      recipient: recipient,
      sender: address(this),
      startTime: startTime,
      stopTime: stopTime,
      tokenAddress: tokenAddress
    });

    /* Increment the next stream id. */
    _nextStreamId++;

    emit CreateStream(
      streamId,
      address(this),
      recipient,
      deposit,
      tokenAddress,
      startTime,
      stopTime
    );
    return streamId;
  }

  /// @inheritdoc ICollector
  /**
   * @dev Throws if the id does not point to a valid stream.
   *  Throws if the caller is not the funds admin or the recipient of the stream.
   *  Throws if the amount exceeds the available balance.
   *  Throws if there is a token transfer failure.
   */
  function withdrawFromStream(
    uint256 streamId,
    uint256 amount
  ) external nonReentrant streamExists(streamId) onlyAdminOrRecipient(streamId) returns (bool) {
    if (amount == 0) revert InvalidZeroAmount();
    Stream memory stream = _streams[streamId];

    uint256 balance = balanceOf(streamId, stream.recipient);
    if (balance < amount) revert BalanceExceeded();

    _streams[streamId].remainingBalance = stream.remainingBalance - amount;

    if (_streams[streamId].remainingBalance == 0) delete _streams[streamId];

    IERC20(stream.tokenAddress).safeTransfer(stream.recipient, amount);
    emit WithdrawFromStream(streamId, stream.recipient, amount);
    return true;
  }

  /// @inheritdoc ICollector
  /**
   * @dev Throws if the id does not point to a valid stream.
   *  Throws if the caller is not the funds admin or the recipient of the stream.
   *  Throws if there is a token transfer failure.
   */
  function cancelStream(
    uint256 streamId
  ) external nonReentrant streamExists(streamId) onlyAdminOrRecipient(streamId) returns (bool) {
    Stream memory stream = _streams[streamId];
    uint256 senderBalance = balanceOf(streamId, stream.sender);
    uint256 recipientBalance = balanceOf(streamId, stream.recipient);

    delete _streams[streamId];

    IERC20 token = IERC20(stream.tokenAddress);
    if (recipientBalance > 0) token.safeTransfer(stream.recipient, recipientBalance);

    emit CancelStream(streamId, stream.sender, stream.recipient, senderBalance, recipientBalance);
    return true;
  }

  /// @dev needed in order to receive ETH from the Aave v1 ecosystem reserve
  receive() external payable {}
}
