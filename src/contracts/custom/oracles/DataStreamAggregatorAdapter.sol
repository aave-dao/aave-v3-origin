// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import {Ownable} from 'openzeppelin-contracts/contracts/access/Ownable.sol';
import {IAggregatorV3} from './interfaces/IAggregatorV3.sol';
import {IVerifierProxy} from './interfaces/IVerifierProxy.sol';
import {IVerifierFeeManager} from './interfaces/IVerifierFeeManager.sol';

/**
 * @title DataStreamAggregatorAdapter
 * @notice Adapter that wraps Chainlink Data Streams to provide AggregatorV3Interface
 * @dev Bridges pull-based Data Streams with push-based interface that Aave expects
 *
 * Usage:
 * 1. Keepers fetch signed reports from Chainlink Data Streams API
 * 2. Keepers call submitReport() to verify and store the price
 * 3. Aave calls latestRoundData() to get the stored price
 */
contract DataStreamAggregatorAdapter is IAggregatorV3, Ownable {
  using SafeERC20 for IERC20;

  // ============ Structs ============

  struct ReportV3 {
    bytes32 feedId;
    uint32 validFromTimestamp;
    uint32 observationsTimestamp;
    uint192 nativeFee;
    uint192 linkFee;
    uint32 expiresAt;
    int192 price;
    int192 bid;
    int192 ask;
  }

  struct RoundData {
    int256 answer;
    uint256 startedAt;
    uint256 updatedAt;
  }

  // ============ Immutables ============

  IVerifierProxy public immutable verifierProxy;
  bytes32 public immutable feedId;
  uint8 private immutable _decimals;
  string private _description;

  // ============ Storage ============

  uint80 public currentRoundId;
  int256 public latestPrice;
  uint256 public latestTimestamp; // When price was observed (from Data Streams)
  uint256 public lastSubmissionTime; // When price was submitted on-chain

  mapping(uint80 => RoundData) public rounds;

  // Security parameters
  int256 public minPrice; // Minimum allowed price (0 = disabled)
  int256 public maxPrice; // Maximum allowed price (0 = disabled)
  uint256 public maxStalenessSeconds; // Maximum age of price observation (0 = disabled)
  uint256 public maxPriceDeviationBps; // Maximum price change per update in bps (0 = disabled)

  mapping(address => bool) public authorizedKeepers;
  bool public requireKeeperAuth;

  // ============ Events ============

  event PriceUpdated(
    uint80 indexed roundId,
    int256 price,
    uint256 observationTimestamp,
    uint256 submissionTimestamp,
    address indexed submitter
  );
  event KeeperAuthorizationChanged(address indexed keeper, bool authorized);
  event SecurityParametersUpdated(
    int256 minPrice,
    int256 maxPrice,
    uint256 maxStalenessSeconds,
    uint256 maxPriceDeviationBps
  );
  event EmergencyPriceSet(uint80 indexed roundId, int256 price, uint256 timestamp, address indexed setter);

  // ============ Errors ============

  error UnauthorizedKeeper();
  error InvalidFeedId();
  error ExpiredReport();
  error PriceTooStale();
  error PriceOutOfBounds();
  error PriceDeviationTooLarge();
  error InvalidPrice();

  // ============ Constructor ============

  constructor(
    address _verifierProxy,
    bytes32 _feedId,
    uint8 decimals_,
    string memory description_
  ) Ownable(msg.sender) {
    verifierProxy = IVerifierProxy(_verifierProxy);
    feedId = _feedId;
    _decimals = decimals_;
    _description = description_;
    requireKeeperAuth = true;
  }

  // ============ External Functions ============

  /**
   * @notice Submit a signed report from Chainlink Data Streams
   * @param signedReport The signed report bytes from Chainlink Data Streams API
   */
  function submitReport(bytes calldata signedReport) external payable {
    if (requireKeeperAuth && !authorizedKeepers[msg.sender]) {
      revert UnauthorizedKeeper();
    }

    (int256 price, uint256 timestamp) = _verifyAndDecodeReport(signedReport);

    // Validate price
    _validatePrice(price, timestamp);

    currentRoundId++;
    latestPrice = price;
    latestTimestamp = timestamp;
    lastSubmissionTime = block.timestamp;

    rounds[currentRoundId] = RoundData({answer: price, startedAt: timestamp, updatedAt: block.timestamp});

    emit PriceUpdated(currentRoundId, price, timestamp, block.timestamp, msg.sender);
  }

  /**
   * @notice Validate price against security parameters
   */
  function _validatePrice(int256 price, uint256 timestamp) internal view {
    // Check price is positive
    if (price <= 0) revert InvalidPrice();

    // Check staleness
    if (maxStalenessSeconds > 0 && block.timestamp - timestamp > maxStalenessSeconds) {
      revert PriceTooStale();
    }

    // Check price bounds
    if (minPrice > 0 && price < minPrice) revert PriceOutOfBounds();
    if (maxPrice > 0 && price > maxPrice) revert PriceOutOfBounds();

    // Check price deviation from last price
    if (maxPriceDeviationBps > 0 && latestPrice > 0) {
      int256 deviation = price > latestPrice
        ? ((price - latestPrice) * 10000) / latestPrice
        : ((latestPrice - price) * 10000) / latestPrice;
      if (uint256(deviation) > maxPriceDeviationBps) {
        revert PriceDeviationTooLarge();
      }
    }
  }

  // ============ AggregatorV3Interface ============

  function decimals() external view override returns (uint8) {
    return _decimals;
  }

  function description() external view override returns (string memory) {
    return _description;
  }

  function version() external pure override returns (uint256) {
    return 1;
  }

  function getRoundData(
    uint80 _roundId
  )
    external
    view
    override
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
  {
    RoundData storage round = rounds[_roundId];
    return (_roundId, round.answer, round.startedAt, round.updatedAt, _roundId);
  }

  function latestRoundData()
    external
    view
    override
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
  {
    return (currentRoundId, latestPrice, latestTimestamp, lastSubmissionTime, currentRoundId);
  }

  // ============ Admin Functions ============

  function setKeeperAuthorization(address keeper, bool authorized) external onlyOwner {
    authorizedKeepers[keeper] = authorized;
    emit KeeperAuthorizationChanged(keeper, authorized);
  }

  function setRequireKeeperAuth(bool required) external onlyOwner {
    requireKeeperAuth = required;
  }

  /**
   * @notice Set emergency price with validation
   */
  function setEmergencyPrice(int256 price, uint256 timestamp) external onlyOwner {
    _validatePrice(price, timestamp);
    require(timestamp <= block.timestamp, 'Future timestamp not allowed');

    currentRoundId++;
    latestPrice = price;
    latestTimestamp = timestamp;
    lastSubmissionTime = block.timestamp;

    rounds[currentRoundId] = RoundData({answer: price, startedAt: timestamp, updatedAt: block.timestamp});

    emit EmergencyPriceSet(currentRoundId, price, timestamp, msg.sender);
  }

  /**
   * @notice Set security parameters for price validation
   */
  function setSecurityParameters(
    int256 _minPrice,
    int256 _maxPrice,
    uint256 _maxStalenessSeconds,
    uint256 _maxPriceDeviationBps
  ) external onlyOwner {
    require(_minPrice >= 0, 'Min price cannot be negative');
    require(_maxPrice == 0 || _maxPrice > _minPrice, 'Max must be > min');
    require(_maxPriceDeviationBps <= 10000, 'Deviation cannot exceed 100%');

    minPrice = _minPrice;
    maxPrice = _maxPrice;
    maxStalenessSeconds = _maxStalenessSeconds;
    maxPriceDeviationBps = _maxPriceDeviationBps;

    emit SecurityParametersUpdated(_minPrice, _maxPrice, _maxStalenessSeconds, _maxPriceDeviationBps);
  }

  // ============ Internal Functions ============

  function _verifyAndDecodeReport(bytes calldata signedReport) internal returns (int256, uint256) {
    IVerifierFeeManager feeManager = verifierProxy.s_feeManager();
    bytes memory verifiedReportData;

    if (address(feeManager) != address(0)) {
      (, bytes memory reportData) = abi.decode(signedReport, (bytes32[3], bytes));
      address linkToken = feeManager.i_linkAddress();
      (IVerifierFeeManager.Asset memory fee, , ) = feeManager.getFeeAndReward(address(this), reportData, linkToken);

      if (fee.amount > 0) {
        IERC20(linkToken).forceApprove(feeManager.i_rewardManager(), fee.amount);
        verifiedReportData = verifierProxy.verify(signedReport, abi.encode(linkToken));
      } else {
        verifiedReportData = verifierProxy.verify(signedReport, '');
      }
    } else {
      verifiedReportData = verifierProxy.verify(signedReport, '');
    }

    ReportV3 memory report = abi.decode(verifiedReportData, (ReportV3));

    if (report.feedId != feedId) revert InvalidFeedId();
    if (block.timestamp > report.expiresAt) revert ExpiredReport();

    // Scale from 18 decimals (Data Streams) to target decimals (8 for Aave)
    int256 scaledPrice = int256(report.price) / int256(10 ** (18 - _decimals));

    return (scaledPrice, report.observationsTimestamp);
  }

  receive() external payable {}
}
