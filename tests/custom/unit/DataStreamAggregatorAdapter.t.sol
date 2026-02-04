// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Test, console2} from 'forge-std/Test.sol';
import '../base/TestZaiBotsMarket.sol';
import {DataStreamAggregatorAdapter} from 'custom/oracles/DataStreamAggregatorAdapter.sol';

/**
 * @title DataStreamAggregatorAdapterTest
 * @notice Comprehensive tests for DataStreamAggregatorAdapter
 * @dev Tests cover:
 * - Constructor validation
 * - Keeper authorization
 * - Security parameters (price bounds, staleness, deviation)
 * - Report submission
 * - Access control
 * - Error conditions with fuzzing
 */
contract DataStreamAggregatorAdapterTest is TestZaiBotsMarket {
  // ============ Constants ============

  bytes32 constant FEED_ID = keccak256('JPY/USD');
  uint8 constant DECIMALS = 8;
  string constant DESCRIPTION = 'JPY / USD';

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

  // ============ Setup ============

  function setUp() public override {
    super.setUp();
  }

  // ============ Constructor Tests ============

  function test_Constructor_SetsCorrectValues() public view {
    assertEq(jpyUsdOracle.feedId(), FEED_ID);
    assertEq(jpyUsdOracle.decimals(), DECIMALS);
    assertEq(jpyUsdOracle.description(), DESCRIPTION);
  }

  function test_Constructor_SetsDefaultBounds() public view {
    assertEq(jpyUsdOracle.minPrice(), 0);
    assertEq(jpyUsdOracle.maxPrice(), 0);
  }

  function test_Constructor_SetsDefaultStaleness() public view {
    assertEq(jpyUsdOracle.maxStalenessSeconds(), 0);
  }

  function test_Constructor_RequiresKeeperAuthByDefault() public view {
    assertTrue(jpyUsdOracle.requireKeeperAuth());
  }

  // ============ Keeper Authorization Tests ============

  function test_SetKeeperAuthorization_Success() public {
    address newKeeper = makeAddr('newKeeper');

    vm.prank(owner);
    vm.expectEmit(true, false, false, true);
    emit KeeperAuthorizationChanged(newKeeper, true);
    jpyUsdOracle.setKeeperAuthorization(newKeeper, true);

    assertTrue(jpyUsdOracle.authorizedKeepers(newKeeper));
  }

  function test_SetKeeperAuthorization_Revoke() public {
    vm.prank(owner);
    vm.expectEmit(true, false, false, true);
    emit KeeperAuthorizationChanged(keeper, false);
    jpyUsdOracle.setKeeperAuthorization(keeper, false);

    assertFalse(jpyUsdOracle.authorizedKeepers(keeper));
  }

  function test_SetKeeperAuthorization_RevertWhen_NotOwner() public {
    vm.prank(attacker);
    vm.expectRevert();
    jpyUsdOracle.setKeeperAuthorization(attacker, true);
  }

  function test_SetRequireKeeperAuth_Success() public {
    vm.prank(owner);
    jpyUsdOracle.setRequireKeeperAuth(false);

    assertFalse(jpyUsdOracle.requireKeeperAuth());
  }

  // ============ Security Parameters Tests ============

  function test_SetSecurityParameters_Success() public {
    int256 minP = 1e8;
    int256 maxP = 1000e8;
    uint256 staleness = 1 hours;
    uint256 deviation = 500; // 5%

    vm.prank(owner);
    vm.expectEmit(false, false, false, true);
    emit SecurityParametersUpdated(minP, maxP, staleness, deviation);
    jpyUsdOracle.setSecurityParameters(minP, maxP, staleness, deviation);

    assertEq(jpyUsdOracle.minPrice(), minP);
    assertEq(jpyUsdOracle.maxPrice(), maxP);
    assertEq(jpyUsdOracle.maxStalenessSeconds(), staleness);
    assertEq(jpyUsdOracle.maxPriceDeviationBps(), deviation);
  }

  function test_SetSecurityParameters_RevertWhen_MinNegative() public {
    vm.prank(owner);
    vm.expectRevert('Min price cannot be negative');
    jpyUsdOracle.setSecurityParameters(-1, 1000e8, 1 hours, 500);
  }

  function test_SetSecurityParameters_RevertWhen_MaxLessThanMin() public {
    vm.prank(owner);
    vm.expectRevert('Max must be > min');
    jpyUsdOracle.setSecurityParameters(1000e8, 100e8, 1 hours, 500);
  }

  function test_SetSecurityParameters_RevertWhen_DeviationTooHigh() public {
    vm.prank(owner);
    vm.expectRevert('Deviation cannot exceed 100%');
    jpyUsdOracle.setSecurityParameters(0, 0, 1 hours, 10001);
  }

  function testFuzz_SetSecurityParameters_Success(
    int256 minP,
    int256 maxP,
    uint256 staleness,
    uint256 deviation
  ) public {
    minP = int256(bound(uint256(minP), 0, 1e30));
    maxP = int256(bound(uint256(maxP), uint256(minP) + 1, 1e32));
    deviation = bound(deviation, 0, 10000);

    vm.prank(owner);
    jpyUsdOracle.setSecurityParameters(minP, maxP, staleness, deviation);

    assertEq(jpyUsdOracle.minPrice(), minP);
    assertEq(jpyUsdOracle.maxPrice(), maxP);
    assertEq(jpyUsdOracle.maxStalenessSeconds(), staleness);
    assertEq(jpyUsdOracle.maxPriceDeviationBps(), deviation);
  }

  // ============ Report Submission Tests ============

  function test_SubmitReport_Success() public {
    int192 price = 65e15; // 18 decimals stored

    verifierProxy.setMockPrice(price);
    bytes memory signedReport = abi.encode(bytes32(0), bytes32(0), bytes32(0), abi.encode(price));

    vm.prank(keeper);
    jpyUsdOracle.submitReport(signedReport);

    // Verify round was updated
    assertEq(jpyUsdOracle.currentRoundId(), 1);
  }

  function test_SubmitReport_RevertWhen_NotAuthorizedKeeper() public {
    bytes memory signedReport = abi.encode(bytes32(0), bytes32(0), bytes32(0), abi.encode(65e15));

    vm.prank(attacker);
    vm.expectRevert(DataStreamAggregatorAdapter.UnauthorizedKeeper.selector);
    jpyUsdOracle.submitReport(signedReport);
  }

  function test_SubmitReport_SuccessWhen_KeeperAuthDisabled() public {
    vm.prank(owner);
    jpyUsdOracle.setRequireKeeperAuth(false);

    int192 price = 65e15;
    verifierProxy.setMockPrice(price);
    bytes memory signedReport = abi.encode(bytes32(0), bytes32(0), bytes32(0), abi.encode(price));

    // Anyone can submit now
    vm.prank(attacker);
    jpyUsdOracle.submitReport(signedReport);

    assertEq(jpyUsdOracle.currentRoundId(), 1);
  }

  function testFuzz_SubmitReport_Success(int192 price) public {
    // Bound to reasonable price range to avoid overflow
    price = int192(bound(int256(price), 1e10, 1e28));

    verifierProxy.setMockPrice(price);
    bytes memory signedReport = abi.encode(bytes32(0), bytes32(0), bytes32(0), abi.encode(price));

    vm.prank(keeper);
    jpyUsdOracle.submitReport(signedReport);

    assertEq(jpyUsdOracle.currentRoundId(), 1);
  }

  // ============ Price Read Tests ============

  function test_LatestRoundData_ReturnsCompleteData() public {
    int192 price = 65e15;

    verifierProxy.setMockPrice(price);
    bytes memory signedReport = abi.encode(bytes32(0), bytes32(0), bytes32(0), abi.encode(price));

    vm.prank(keeper);
    jpyUsdOracle.submitReport(signedReport);

    (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = jpyUsdOracle
      .latestRoundData();

    assertEq(roundId, 1);
    assertTrue(answer != 0);
    assertGt(startedAt, 0);
    assertGt(updatedAt, 0);
    assertEq(answeredInRound, 1);
  }

  function test_GetRoundData_ReturnsHistoricalData() public {
    int192 price1 = 65e15;
    int192 price2 = 66e15;

    // Submit first price
    verifierProxy.setMockPrice(price1);
    bytes memory report1 = abi.encode(bytes32(0), bytes32(0), bytes32(0), abi.encode(price1));
    vm.prank(keeper);
    jpyUsdOracle.submitReport(report1);

    // Submit second price
    verifierProxy.setMockPrice(price2);
    bytes memory report2 = abi.encode(bytes32(0), bytes32(0), bytes32(0), abi.encode(price2));
    vm.prank(keeper);
    jpyUsdOracle.submitReport(report2);

    // Check round 1 data
    (uint80 roundId, int256 answer, , , ) = jpyUsdOracle.getRoundData(1);
    assertEq(roundId, 1);
    assertTrue(answer != 0);

    // Check round 2 data
    (roundId, answer, , , ) = jpyUsdOracle.getRoundData(2);
    assertEq(roundId, 2);
    assertTrue(answer != 0);
  }

  // ============ Emergency Price Tests ============

  function test_SetEmergencyPrice_Success() public {
    int256 price = 65e5; // 8 decimals
    uint256 timestamp = block.timestamp;

    vm.prank(owner);
    vm.expectEmit(true, false, false, true);
    emit EmergencyPriceSet(1, price, timestamp, owner);
    jpyUsdOracle.setEmergencyPrice(price, timestamp);

    assertEq(jpyUsdOracle.latestPrice(), price);
  }

  function test_SetEmergencyPrice_RevertWhen_FutureTimestamp() public {
    vm.prank(owner);
    vm.expectRevert('Future timestamp not allowed');
    jpyUsdOracle.setEmergencyPrice(65e5, block.timestamp + 1);
  }

  function test_SetEmergencyPrice_RevertWhen_NotOwner() public {
    vm.prank(attacker);
    vm.expectRevert();
    jpyUsdOracle.setEmergencyPrice(65e5, block.timestamp);
  }

  // ============ Version Test ============

  function test_Version_Returns1() public view {
    assertEq(jpyUsdOracle.version(), 1);
  }

  // ============ Multiple Rounds Test ============

  function testFuzz_MultipleRounds_TracksCorrectly(uint8 numRounds) public {
    numRounds = uint8(bound(numRounds, 1, 50));

    for (uint8 i = 0; i < numRounds; i++) {
      // Use bounded price to avoid overflow
      int192 price = int192(int256(65e15 + (int256(uint256(i)) * 1e14)));

      verifierProxy.setMockPrice(price);
      bytes memory signedReport = abi.encode(bytes32(0), bytes32(0), bytes32(0), abi.encode(price));

      vm.prank(keeper);
      jpyUsdOracle.submitReport(signedReport);
    }

    assertEq(jpyUsdOracle.currentRoundId(), numRounds);
  }

  // ============ Edge Cases ============

  function test_LatestPrice_ReturnsStoredPrice() public {
    int192 price = 65e15;

    verifierProxy.setMockPrice(price);
    bytes memory signedReport = abi.encode(bytes32(0), bytes32(0), bytes32(0), abi.encode(price));

    vm.prank(keeper);
    jpyUsdOracle.submitReport(signedReport);

    // latestPrice is stored directly
    int256 storedPrice = jpyUsdOracle.latestPrice();
    assertTrue(storedPrice != 0);
  }

  function test_LatestTimestamp_ReturnsObservationTime() public {
    int192 price = 65e15;

    verifierProxy.setMockPrice(price);
    bytes memory signedReport = abi.encode(bytes32(0), bytes32(0), bytes32(0), abi.encode(price));

    vm.prank(keeper);
    jpyUsdOracle.submitReport(signedReport);

    uint256 timestamp = jpyUsdOracle.latestTimestamp();
    assertGt(timestamp, 0);
  }

  function test_LastSubmissionTime_ReturnsOnchainTime() public {
    int192 price = 65e15;

    verifierProxy.setMockPrice(price);
    bytes memory signedReport = abi.encode(bytes32(0), bytes32(0), bytes32(0), abi.encode(price));

    uint256 beforeSubmit = block.timestamp;
    vm.prank(keeper);
    jpyUsdOracle.submitReport(signedReport);

    uint256 submissionTime = jpyUsdOracle.lastSubmissionTime();
    assertGe(submissionTime, beforeSubmit);
  }
}
