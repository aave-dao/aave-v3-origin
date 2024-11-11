// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';

import {IERC20} from 'src/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {IAccessControl} from 'src/contracts/dependencies/openzeppelin/contracts/IAccessControl.sol';
import {Collector} from 'src/contracts/treasury/Collector.sol';

contract CollectorTest is Test {
  Collector public collector;

  IERC20 public constant AAVE = IERC20(0xD6DF932A45C0f255f85145f286eA0b292B21C90B);

  // https://polygonscan.com/address/0xDf7d0e6454DB638881302729F5ba99936EaAB233
  address public constant EXECUTOR_LVL_1 = 0xDf7d0e6454DB638881302729F5ba99936EaAB233;

  // https://polygonscan.com/address/0xa72636CbcAa8F5FF95B2cc47F3CDEe83F3294a0B
  address public constant ACL_MANAGER = 0xa72636CbcAa8F5FF95B2cc47F3CDEe83F3294a0B;
  address public constant RECIPIENT_STREAM_1 = 0xd3B5A38aBd16e2636F1e94D1ddF0Ffb4161D5f10;

  address public FUNDS_ADMIN;

  uint256 public streamStartTime;
  uint256 public streamStopTime;

  event NewACLManager(address indexed manager);
  event NewFundsAdmin(address indexed fundsAdmin);
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

  error Create_InvalidStreamId(uint256 id);
  error Create_InvalidSender(address sender);
  error Create_InvalidRecipient(address recipient);
  error Create_InvalidDeposit(uint256 amount);
  error Create_InvalidAsset(address asset);
  error Create_InvalidStartTime(uint256 startTime);
  error Create_InvalidStopTime(uint256 stopTime);
  error Create_InvalidRemaining(uint256 remainingBalance);
  error Create_InvalidRatePerSecond(uint256 rate);
  error Create_InvalidNextStreamId(uint256 id);
  error Cancel_WrongRecipientBalance(uint256 current, uint256 expected);
  error Withdraw_WrongRecipientBalance(uint256 current, uint256 expected);
  error Withdraw_WrongRecipientBalanceStream(uint256 current, uint256 expected);
  error Withdraw_WrongEcoReserveBalance(uint256 current, uint256 expected);
  error Withdraw_WrongEcoReserveBalanceStream(uint256 current, uint256 expected);

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('polygon'));

    collector = new Collector();
    collector.initialize(ACL_MANAGER, 100000);
    deal(address(AAVE), address(collector), 10 ether);

    streamStartTime = block.timestamp + 10;
    streamStopTime = block.timestamp + 70;

    FUNDS_ADMIN = makeAddr('funds-admin');

    vm.startPrank(EXECUTOR_LVL_1);
    IAccessControl(ACL_MANAGER).grantRole(collector.FUNDS_ADMIN_ROLE(), FUNDS_ADMIN);
    IAccessControl(ACL_MANAGER).grantRole(collector.FUNDS_ADMIN_ROLE(), EXECUTOR_LVL_1);
    vm.stopPrank();
  }

  function testGetFundsAdmin_isZeroAddressOnNewVersion() public view {
    address fundsAdmin = collector.getFundsAdmin();
    assertEq(fundsAdmin, address(0));
  }

  function testApprove() public {
    vm.prank(FUNDS_ADMIN);
    collector.approve(AAVE, address(42), 1 ether);

    uint256 allowance = AAVE.allowance(address(collector), address(42));

    assertEq(allowance, 1 ether);
  }

  function testApproveWhenNotFundsAdmin() public {
    vm.expectRevert(bytes('ONLY_BY_FUNDS_ADMIN'));
    collector.approve(AAVE, address(0), 1 ether);
  }

  function testTransfer() public {
    vm.prank(FUNDS_ADMIN);
    collector.transfer(AAVE, address(112), 1 ether);

    uint256 balance = AAVE.balanceOf(address(112));

    assertEq(balance, 1 ether);
  }

  function testTransferWhenNotFundsAdmin() public {
    vm.expectRevert(bytes('ONLY_BY_FUNDS_ADMIN'));

    collector.transfer(AAVE, address(112), 1 ether);
  }
}

contract StreamsTest is CollectorTest {
  function testGetNextStreamId() public view {
    uint256 streamId = collector.getNextStreamId();
    assertEq(streamId, 100000);
  }

  function testGetNotExistingStream() public {
    vm.expectRevert(bytes('stream does not exist'));
    collector.getStream(100000);
  }

  // create stream
  function testCreateStream() public {
    vm.expectEmit(true, true, true, true);

    emit CreateStream(
      100000,
      address(collector),
      RECIPIENT_STREAM_1,
      6 ether,
      address(AAVE),
      streamStartTime,
      streamStopTime
    );

    vm.startPrank(FUNDS_ADMIN);
    uint256 streamId = createStream();

    assertEq(streamId, 100000);

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

  function testCreateStreamWhenNotFundsAdmin() public {
    vm.expectRevert(bytes('ONLY_BY_FUNDS_ADMIN'));

    collector.createStream(
      RECIPIENT_STREAM_1,
      6 ether,
      address(AAVE),
      streamStartTime,
      streamStopTime
    );
  }

  function testCreateStreamWhenRecipientIsZero() public {
    vm.expectRevert(bytes('stream to the zero address'));

    vm.prank(FUNDS_ADMIN);
    collector.createStream(address(0), 6 ether, address(AAVE), streamStartTime, streamStopTime);
  }

  function testCreateStreamWhenRecipientIsCollector() public {
    vm.expectRevert(bytes('stream to the contract itself'));

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
    vm.expectRevert(bytes('stream to the caller'));

    vm.prank(FUNDS_ADMIN);
    collector.createStream(FUNDS_ADMIN, 6 ether, address(AAVE), streamStartTime, streamStopTime);
  }

  function testCreateStreamWhenDepositIsZero() public {
    vm.expectRevert(bytes('deposit is zero'));

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
    vm.expectRevert(bytes('start time before block.timestamp'));

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
    vm.expectRevert(bytes('stop time before the start time'));

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

    vm.expectRevert('stream does not exist');
    collector.getStream(streamId);
  }

  function testWithdrawFromStreamWhenStreamNotExists() public {
    vm.expectRevert(bytes('stream does not exist'));

    collector.withdrawFromStream(100000, 1 ether);
  }

  function testWithdrawFromStreamWhenNotAdminOrRecipient() public {
    vm.prank(FUNDS_ADMIN);
    uint256 streamId = createStream();

    vm.expectRevert(bytes('caller is not the funds admin nor the recipient of the stream'));
    collector.withdrawFromStream(streamId, 1 ether);
  }

  function testWithdrawFromStreamWhenAmountIsZero() public {
    vm.startPrank(FUNDS_ADMIN);
    uint256 streamId = createStream();

    vm.expectRevert(bytes('amount is zero'));

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
    vm.expectRevert(bytes('amount exceeds the available balance'));

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

    vm.expectRevert(bytes('stream does not exist'));
    collector.getStream(streamId);
  }

  function testCancelStreamByRecipient() public {
    vm.prank(FUNDS_ADMIN);
    // Arrange
    uint256 streamId = createStream();
    uint256 balanceRecipientBefore = AAVE.balanceOf(RECIPIENT_STREAM_1);

    vm.warp(block.timestamp + 20);

    vm.expectEmit(true, true, true, true);
    emit CancelStream(streamId, address(collector), RECIPIENT_STREAM_1, 5 ether, 1 ether);

    vm.prank(RECIPIENT_STREAM_1);
    // Act
    collector.cancelStream(streamId);

    // Assert
    uint256 balanceRecipientAfter = AAVE.balanceOf(RECIPIENT_STREAM_1);
    assertEq(balanceRecipientAfter, balanceRecipientBefore + 1 ether);

    vm.expectRevert(bytes('stream does not exist'));
    collector.getStream(streamId);
  }

  function testCancelStreamWhenStreamNotExists() public {
    vm.expectRevert(bytes('stream does not exist'));

    collector.cancelStream(100000);
  }

  function testCancelStreamWhenNotAdminOrRecipient() public {
    vm.prank(FUNDS_ADMIN);
    uint256 streamId = createStream();

    vm.expectRevert(bytes('caller is not the funds admin nor the recipient of the stream'));
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
    assertEq(collector.FUNDS_ADMIN_ROLE(), keccak256('FUNDS_ADMIN'));
  }
}

contract SetACLManagerTest is CollectorTest {
  function test_revertsIf_invalidCaller() public {
    vm.expectRevert('ONLY_BY_FUNDS_ADMIN');
    collector.setACLManager(makeAddr('new-acl'));
  }

  function test_revertsIf_zeroAddress() public {
    vm.startPrank(FUNDS_ADMIN);
    vm.expectRevert('cannot be the zero-address');
    collector.setACLManager(address(0));
  }

  function test_successful() public {
    address newAcl = makeAddr('new-acl');

    vm.startPrank(FUNDS_ADMIN);
    vm.expectEmit(true, true, true, true, address(collector));
    emit NewACLManager(newAcl);
    collector.setACLManager(newAcl);
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
