// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';

import {IERC20} from 'src/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {IAccessControl} from 'src/contracts/dependencies/openzeppelin/contracts/IAccessControl.sol';
import {ProxyAdmin} from 'solidity-utils/contracts/transparent-proxy/ProxyAdmin.sol';
import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';

import {Collector} from 'src/contracts/treasury/Collector.sol';
import {ICollector} from 'src/contracts/treasury/ICollector.sol';

contract UpgradeCollectorTest is Test {
  IERC20 public constant AAVE = IERC20(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);
  address public constant COLLECTOR_ADDRESS = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;
  Collector originalCollector;
  Collector newCollector;

  address public constant EXECUTOR_LVL_1 = 0x5300A1a15135EA4dc7aD5a167152C01EFc9b192A;
  address public constant ACL_MANAGER = 0xc2aaCf6553D20d1e9d78E365AAba8032af9c85b0;
  address public constant RECIPIENT_STREAM_1 = 0xd3B5A38aBd16e2636F1e94D1ddF0Ffb4161D5f10;
  address public FUNDS_ADMIN;
  uint256 public streamStartTime;
  uint256 public streamStopTime;
  uint256 public nextStreamID;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'));

    originalCollector = Collector(COLLECTOR_ADDRESS);
    nextStreamID = originalCollector.getNextStreamId();
    newCollector = new Collector(ACL_MANAGER);
    newCollector.initialize(nextStreamID);
    deal(address(AAVE), address(newCollector), 10 ether);

    streamStartTime = block.timestamp + 10;
    streamStopTime = block.timestamp + 70;

    FUNDS_ADMIN = makeAddr('funds-admin');

    vm.startPrank(EXECUTOR_LVL_1);
    IAccessControl(ACL_MANAGER).grantRole(newCollector.FUNDS_ADMIN_ROLE(), FUNDS_ADMIN);
    IAccessControl(ACL_MANAGER).grantRole(newCollector.FUNDS_ADMIN_ROLE(), EXECUTOR_LVL_1);
    vm.stopPrank();
  }

  function test_slots_upgrade() public {
    vm.startMappingRecording();

    vm.prank(EXECUTOR_LVL_1);
    originalCollector.createStream(
      RECIPIENT_STREAM_1,
      6 ether,
      address(AAVE),
      streamStartTime,
      streamStopTime
    );

    {
      bytes32 dataSlot = bytes32(uint256(55));
      bytes32 dataValueSlot = vm.getMappingSlotAt(address(originalCollector), dataSlot, 0);

      vm.getMappingLength(address(originalCollector), dataSlot);
      vm.load(address(originalCollector), dataValueSlot);

      (
        address sender,
        address recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime,
        ,

      ) = originalCollector.getStream(nextStreamID);
      assertEq(streamStartTime, startTime);
      assertEq(streamStopTime, stopTime);
      assertEq(address(AAVE), tokenAddress);
      assertEq(6 ether, deposit);
      assertEq(RECIPIENT_STREAM_1, recipient);
      assertEq(address(originalCollector), sender);
    }

    {
      bytes32 dataSlot = bytes32(uint256(55));
      bytes32 dataValueSlot = vm.getMappingSlotAt(address(originalCollector), dataSlot, 0);

      vm.getMappingLength(address(originalCollector), dataSlot);
      vm.load(address(originalCollector), dataValueSlot);

      (
        address sender,
        address recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime,
        ,

      ) = originalCollector.getStream(nextStreamID);
      assertEq(streamStartTime, startTime);
      assertEq(streamStopTime, stopTime);
      assertEq(address(AAVE), tokenAddress);
      assertEq(6 ether, deposit);
      assertEq(RECIPIENT_STREAM_1, recipient);
      assertEq(address(originalCollector), sender);
    }
  }
}

contract CollectorTest is Test {
  Collector public collector;

  IERC20 public constant AAVE = IERC20(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);

  // https://etherscan.com/address/0x5300A1a15135EA4dc7aD5a167152C01EFc9b192A
  address public constant EXECUTOR_LVL_1 = 0x5300A1a15135EA4dc7aD5a167152C01EFc9b192A;

  // https://etherscan.com/address/0xc2aaCf6553D20d1e9d78E365AAba8032af9c85b0
  address public constant ACL_MANAGER = 0xc2aaCf6553D20d1e9d78E365AAba8032af9c85b0;
  address public constant RECIPIENT_STREAM_1 = 0xd3B5A38aBd16e2636F1e94D1ddF0Ffb4161D5f10;

  address public FUNDS_ADMIN;

  uint256 public streamStartTime;
  uint256 public streamStopTime;
  uint256 public nextStreamID;

  event StreamIdChanged(uint256 indexed streamId);

  event CreateStream(
    uint256 indexed streamId,
    address indexed sender,
    address indexed recipient,
    uint256 deposit,
    address tokenAddress,
    uint256 startTime,
    uint256 stopTime
  );

  event CancelStream(
    uint256 indexed streamId,
    address indexed sender,
    address indexed recipient,
    uint256 senderBalance,
    uint256 recipientBalance
  );

  event WithdrawFromStream(uint256 indexed streamId, address indexed recipient, uint256 amount);

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'));

    collector = new Collector(ACL_MANAGER);
    deal(address(AAVE), address(collector), 10 ether);

    streamStartTime = block.timestamp + 10;
    streamStopTime = block.timestamp + 70;

    FUNDS_ADMIN = makeAddr('funds-admin');

    nextStreamID = 10;

    collector.initialize(nextStreamID);

    vm.startPrank(EXECUTOR_LVL_1);
    IAccessControl(ACL_MANAGER).grantRole(collector.FUNDS_ADMIN_ROLE(), FUNDS_ADMIN);
    IAccessControl(ACL_MANAGER).grantRole(collector.FUNDS_ADMIN_ROLE(), EXECUTOR_LVL_1);
    vm.stopPrank();
  }

  function testApprove() public {
    vm.prank(FUNDS_ADMIN);
    collector.approve(AAVE, address(42), 1 ether);

    uint256 allowance = AAVE.allowance(address(collector), address(42));

    assertEq(allowance, 1 ether);
  }

  function testApproveWhenNotFundsAdmin() public {
    vm.expectRevert(ICollector.OnlyFundsAdmin.selector);
    collector.approve(AAVE, address(0), 1 ether);
  }

  function testTransfer() public {
    vm.prank(FUNDS_ADMIN);
    collector.transfer(AAVE, address(112), 1 ether);

    uint256 balance = AAVE.balanceOf(address(112));

    assertEq(balance, 1 ether);
  }

  function testTransferWhenNotFundsAdmin() public {
    vm.expectRevert(ICollector.OnlyFundsAdmin.selector);

    collector.transfer(AAVE, address(112), 1 ether);
  }
}

contract StreamsTest is CollectorTest {
  function testGetNextStreamId() public view {
    uint256 streamId = collector.getNextStreamId();
    assertEq(streamId, nextStreamID);
  }

  function testGetNotExistingStream() public {
    vm.expectRevert(ICollector.StreamDoesNotExist.selector);
    collector.getStream(nextStreamID + 1);
  }

  // create stream
  function testCreateStream() public {
    vm.expectEmit(true, true, true, true);
    emit CreateStream(
      nextStreamID,
      address(collector),
      RECIPIENT_STREAM_1,
      6 ether,
      address(AAVE),
      streamStartTime,
      streamStopTime
    );

    vm.startPrank(FUNDS_ADMIN);
    uint256 streamId = createStream();

    assertEq(streamId, nextStreamID);

    (
      address sender,
      address recipient,
      uint256 deposit,
      address tokenAddress,
      uint256 startTime,
      uint256 stopTime,
      uint256 remainingBalance,

    ) = collector.getStream(streamId);

    assertEq(sender, address(collector));
    assertEq(recipient, RECIPIENT_STREAM_1);
    assertEq(deposit, 6 ether);
    assertEq(tokenAddress, address(AAVE));
    assertEq(startTime, streamStartTime);
    assertEq(stopTime, streamStopTime);
    assertEq(remainingBalance, 6 ether);
  }

  function testGetStream() public {
    vm.prank(FUNDS_ADMIN);
    uint256 streamId = createStream();
    (, , , , uint256 startTime, , , ) = collector.getStream(streamId);
    assertEq(startTime, streamStartTime);
  }

  function testCreateStreamWhenNotFundsAdmin() public {
    vm.expectRevert(ICollector.OnlyFundsAdmin.selector);

    collector.createStream(
      RECIPIENT_STREAM_1,
      6 ether,
      address(AAVE),
      streamStartTime,
      streamStopTime
    );
  }

  function testCreateStreamWhenRecipientIsZero() public {
    vm.expectRevert(ICollector.InvalidZeroAddress.selector);

    vm.prank(FUNDS_ADMIN);
    collector.createStream(address(0), 6 ether, address(AAVE), streamStartTime, streamStopTime);
  }

  function testCreateStreamWhenRecipientIsCollector() public {
    vm.expectRevert(ICollector.InvalidRecipient.selector);

    vm.prank(FUNDS_ADMIN);
    collector.createStream(
      address(collector),
      6 ether,
      address(AAVE),
      streamStartTime,
      streamStopTime
    );
  }

  function testCreateStreamWhenRecipientIsTheCaller() public {
    vm.expectRevert(ICollector.InvalidRecipient.selector);

    vm.prank(FUNDS_ADMIN);
    collector.createStream(FUNDS_ADMIN, 6 ether, address(AAVE), streamStartTime, streamStopTime);
  }

  function testCreateStreamWhenDepositIsZero() public {
    vm.expectRevert(ICollector.InvalidZeroAmount.selector);

    vm.prank(FUNDS_ADMIN);
    collector.createStream(
      RECIPIENT_STREAM_1,
      0 ether,
      address(AAVE),
      streamStartTime,
      streamStopTime
    );
  }

  function testCreateStreamWhenStartTimeInThePast() public {
    vm.expectRevert(ICollector.InvalidStartTime.selector);

    vm.prank(FUNDS_ADMIN);
    collector.createStream(
      RECIPIENT_STREAM_1,
      6 ether,
      address(AAVE),
      block.timestamp - 10,
      streamStopTime
    );
  }

  function testCreateStreamWhenStopTimeBeforeStart() public {
    vm.expectRevert(ICollector.InvalidStopTime.selector);

    vm.prank(FUNDS_ADMIN);
    collector.createStream(
      RECIPIENT_STREAM_1,
      6 ether,
      address(AAVE),
      block.timestamp + 70,
      block.timestamp + 10
    );
  }

  // withdraw from stream
  function testWithdrawFromStream() public {
    vm.startPrank(FUNDS_ADMIN);
    // Arrange
    uint256 streamId = createStream();
    vm.stopPrank();

    vm.warp(block.timestamp + 20);

    uint256 balanceRecipientBefore = AAVE.balanceOf(RECIPIENT_STREAM_1);
    uint256 balanceRecipientStreamBefore = collector.balanceOf(streamId, RECIPIENT_STREAM_1);
    uint256 balanceCollectorBefore = AAVE.balanceOf(address(collector));
    uint256 balanceCollectorStreamBefore = collector.balanceOf(streamId, address(collector));

    vm.expectEmit(true, true, true, true);
    emit WithdrawFromStream(streamId, RECIPIENT_STREAM_1, 1 ether);

    vm.prank(RECIPIENT_STREAM_1);
    // Act
    collector.withdrawFromStream(streamId, 1 ether);

    // Assert
    uint256 balanceRecipientAfter = AAVE.balanceOf(RECIPIENT_STREAM_1);
    uint256 balanceRecipientStreamAfter = collector.balanceOf(streamId, RECIPIENT_STREAM_1);
    uint256 balanceCollectorAfter = AAVE.balanceOf(address(collector));
    uint256 balanceCollectorStreamAfter = collector.balanceOf(streamId, address(collector));

    assertEq(balanceRecipientAfter, balanceRecipientBefore + 1 ether);
    assertEq(balanceRecipientStreamAfter, balanceRecipientStreamBefore - 1 ether);
    assertEq(balanceCollectorAfter, balanceCollectorBefore - 1 ether);
    assertEq(balanceCollectorStreamAfter, balanceCollectorStreamBefore);
  }

  function testWithdrawFromStreamFinishesSuccessfully() public {
    vm.startPrank(FUNDS_ADMIN);
    // Arrange
    uint256 streamId = createStream();
    vm.stopPrank();

    vm.warp(block.timestamp + 70);

    uint256 balanceRecipientBefore = AAVE.balanceOf(RECIPIENT_STREAM_1);
    uint256 balanceCollectorBefore = AAVE.balanceOf(address(collector));

    vm.expectEmit(true, true, true, true);
    emit WithdrawFromStream(streamId, RECIPIENT_STREAM_1, 6 ether);

    vm.prank(RECIPIENT_STREAM_1);
    // Act
    collector.withdrawFromStream(streamId, 6 ether);

    // Assert
    uint256 balanceRecipientAfter = AAVE.balanceOf(RECIPIENT_STREAM_1);
    uint256 balanceCollectorAfter = AAVE.balanceOf(address(collector));

    assertEq(balanceRecipientAfter, balanceRecipientBefore + 6 ether);
    assertEq(balanceCollectorAfter, balanceCollectorBefore - 6 ether);

    vm.expectRevert(ICollector.StreamDoesNotExist.selector);
    collector.getStream(streamId);
  }

  function testWithdrawFromStreamWhenStreamNotExists() public {
    vm.expectRevert(ICollector.StreamDoesNotExist.selector);

    collector.withdrawFromStream(nextStreamID, 1 ether);
  }

  function testWithdrawFromStreamWhenNotAdminOrRecipient() public {
    vm.prank(FUNDS_ADMIN);
    uint256 streamId = createStream();

    vm.expectRevert(ICollector.OnlyFundsAdminOrRceipient.selector);
    collector.withdrawFromStream(streamId, 1 ether);
  }

  function testWithdrawFromStreamWhenAmountIsZero() public {
    vm.startPrank(FUNDS_ADMIN);
    uint256 streamId = createStream();

    vm.expectRevert(ICollector.InvalidZeroAmount.selector);

    collector.withdrawFromStream(streamId, 0 ether);
  }

  function testWithdrawFromStreamWhenAmountExceedsBalance() public {
    vm.prank(FUNDS_ADMIN);
    uint256 streamId = collector.createStream(
      RECIPIENT_STREAM_1,
      6 ether,
      address(AAVE),
      streamStartTime,
      streamStopTime
    );

    vm.warp(block.timestamp + 20);
    vm.expectRevert(ICollector.BalanceExceeded.selector);

    vm.prank(FUNDS_ADMIN);
    collector.withdrawFromStream(streamId, 2 ether);
  }

  // cancel stream
  function testCancelStreamByFundsAdmin() public {
    vm.prank(FUNDS_ADMIN);
    // Arrange
    uint256 streamId = createStream();
    uint256 balanceRecipientBefore = AAVE.balanceOf(RECIPIENT_STREAM_1);

    vm.expectEmit(true, true, true, true);
    emit CancelStream(streamId, address(collector), RECIPIENT_STREAM_1, 6 ether, 0);

    vm.prank(FUNDS_ADMIN);
    // Act
    collector.cancelStream(streamId);

    // Assert
    uint256 balanceRecipientAfter = AAVE.balanceOf(RECIPIENT_STREAM_1);
    assertEq(balanceRecipientAfter, balanceRecipientBefore);

    vm.expectRevert(ICollector.StreamDoesNotExist.selector);
    collector.getStream(streamId);
  }

  function testCancelStreamByRecipient() public {
    vm.prank(FUNDS_ADMIN);
    // Arrange
    uint256 streamId = createStream();
    uint256 balanceRecipientBefore = AAVE.balanceOf(RECIPIENT_STREAM_1);

    vm.warp(block.timestamp + 20);

    vm.expectEmit(true, true, true, true);
    emit CancelStream(
      streamId,
      address(collector),
      RECIPIENT_STREAM_1,
      5 ether,
      1 ether
    );

    vm.prank(RECIPIENT_STREAM_1);
    // Act
    collector.cancelStream(streamId);

    // Assert
    uint256 balanceRecipientAfter = AAVE.balanceOf(RECIPIENT_STREAM_1);
    assertEq(balanceRecipientAfter, balanceRecipientBefore + 1 ether);

    vm.expectRevert(ICollector.StreamDoesNotExist.selector);
    collector.getStream(streamId);
  }

  function testCancelStreamWhenStreamNotExists() public {
    vm.expectRevert(ICollector.StreamDoesNotExist.selector);

    collector.cancelStream(nextStreamID);
  }

  function testCancelStreamWhenNotAdminOrRecipient() public {
    vm.prank(FUNDS_ADMIN);
    uint256 streamId = createStream();

    vm.expectRevert(ICollector.OnlyFundsAdminOrRceipient.selector);
    vm.prank(makeAddr('random'));

    collector.cancelStream(streamId);
  }

  function createStream() private returns (uint256) {
    return
      collector.createStream(
        RECIPIENT_STREAM_1,
        6 ether,
        address(AAVE),
        streamStartTime,
        streamStopTime
      );
  }
}

contract GetRevision is CollectorTest {
  function test_successful() public view {
    assertEq(collector.REVISION(), 6);
  }
}

contract FundsAdminRoleBytesTest is CollectorTest {
  function test_successful() public view {
    assertEq(collector.FUNDS_ADMIN_ROLE(), 'FUNDS_ADMIN');
  }
}

contract IsFundsAdminTest is CollectorTest {
  function test_isNotFundsAdmin() public {
    assertFalse(collector.isFundsAdmin(makeAddr('not-funds-admin')));
  }

  function test_isFundsAdmin() public view {
    assertTrue(collector.isFundsAdmin(FUNDS_ADMIN));
    assertTrue(collector.isFundsAdmin(EXECUTOR_LVL_1));
  }
}
