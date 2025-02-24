// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {StdUtils} from 'forge-std/StdUtils.sol';

import {TransparentUpgradeableProxy} from 'openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {IAccessControl} from '../../src/contracts/dependencies/openzeppelin/contracts/IAccessControl.sol';
import {PoolAddressesProvider} from '../../src/contracts/protocol/configuration/PoolAddressesProvider.sol';
import {Collector} from '../../src/contracts/treasury/Collector.sol';
import {ICollector} from '../../src/contracts/treasury/ICollector.sol';

contract CollectorTest is StdUtils, Test {
  Collector public collector;

  address public EXECUTOR_LVL_1;
  address public ACL_ADMIN;
  address public RECIPIENT_STREAM_1;
  address public FUNDS_ADMIN;
  address public OWNER;

  IERC20 tokenA;
  IERC20 tokenB;

  uint256 public streamStartTime;
  uint256 public streamStopTime;
  uint256 public nextStreamID = 100_000;

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
    EXECUTOR_LVL_1 = makeAddr('governance');
    FUNDS_ADMIN = makeAddr('funds-admin');
    OWNER = makeAddr('owner');
    RECIPIENT_STREAM_1 = makeAddr('recipient');

    PoolAddressesProvider provider = new PoolAddressesProvider('aave', OWNER);
    vm.prank(OWNER);
    provider.setACLAdmin(EXECUTOR_LVL_1);

    tokenA = IERC20(address(deployMockERC20('Token A', 'TK_A', 18)));
    tokenB = IERC20(address(deployMockERC20('Token B', 'TK_B', 6)));

    streamStartTime = block.timestamp + 10;
    streamStopTime = block.timestamp + 70;
    nextStreamID = 0;

    address collectorImpl = address(new Collector());
    collector = Collector(
      payable(
        new TransparentUpgradeableProxy(
          collectorImpl,
          address(this),
          abi.encodeWithSelector(Collector.initialize.selector, nextStreamID, EXECUTOR_LVL_1)
        )
      )
    );

    deal(address(tokenA), address(collector), 100 ether);

    vm.startPrank(EXECUTOR_LVL_1);
    IAccessControl(address(collector)).grantRole(collector.FUNDS_ADMIN_ROLE(), FUNDS_ADMIN);
    IAccessControl(address(collector)).grantRole(collector.FUNDS_ADMIN_ROLE(), EXECUTOR_LVL_1);
    vm.stopPrank();
  }

  function testApprove() public {
    vm.prank(FUNDS_ADMIN);
    collector.approve(tokenA, address(42), 1 ether);

    uint256 allowance = tokenA.allowance(address(collector), address(42));

    assertEq(allowance, 1 ether);
  }

  function testApproveWhenNotFundsAdmin() public {
    vm.expectRevert(ICollector.OnlyFundsAdmin.selector);
    collector.approve(tokenA, address(0), 1 ether);
  }

  function testTransfer() public {
    vm.prank(FUNDS_ADMIN);
    collector.transfer(tokenA, address(112), 1 ether);

    uint256 balance = tokenA.balanceOf(address(112));

    assertEq(balance, 1 ether);
  }

  function testTransferWhenNotFundsAdmin() public {
    vm.expectRevert(ICollector.OnlyFundsAdmin.selector);

    collector.transfer(tokenA, address(112), 1 ether);
  }

  function test_receiveEth() external {
    deal(address(this), 1000 ether);
    (bool success, ) = address(collector).call{value: 1000 ether}(new bytes(0));
    assertEq(success, true);
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
      address(tokenA),
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
    assertEq(tokenAddress, address(tokenA));
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
      address(tokenA),
      streamStartTime,
      streamStopTime
    );
  }

  function testCreateStreamWhenRecipientIsZero() public {
    vm.expectRevert(ICollector.InvalidZeroAddress.selector);

    vm.prank(FUNDS_ADMIN);
    collector.createStream(address(0), 6 ether, address(tokenA), streamStartTime, streamStopTime);
  }

  function testCreateStreamWhenRecipientIsCollector() public {
    vm.expectRevert(ICollector.InvalidRecipient.selector);

    vm.prank(FUNDS_ADMIN);
    collector.createStream(
      address(collector),
      6 ether,
      address(tokenA),
      streamStartTime,
      streamStopTime
    );
  }

  function testCreateStreamWhenRecipientIsTheCaller() public {
    vm.expectRevert(ICollector.InvalidRecipient.selector);

    vm.prank(FUNDS_ADMIN);
    collector.createStream(FUNDS_ADMIN, 6 ether, address(tokenA), streamStartTime, streamStopTime);
  }

  function testCreateStreamWhenDepositIsZero() public {
    vm.expectRevert(ICollector.InvalidZeroAmount.selector);

    vm.prank(FUNDS_ADMIN);
    collector.createStream(
      RECIPIENT_STREAM_1,
      0 ether,
      address(tokenA),
      streamStartTime,
      streamStopTime
    );
  }

  function testCreateStreamWhenStartTimeInThePast() public {
    vm.warp(block.timestamp + 100);

    vm.expectRevert(ICollector.InvalidStartTime.selector);

    vm.prank(FUNDS_ADMIN);
    collector.createStream(
      RECIPIENT_STREAM_1,
      6 ether,
      address(tokenA),
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
      address(tokenA),
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

    uint256 balanceRecipientBefore = tokenA.balanceOf(RECIPIENT_STREAM_1);
    uint256 balanceRecipientStreamBefore = collector.balanceOf(streamId, RECIPIENT_STREAM_1);
    uint256 balanceCollectorBefore = tokenA.balanceOf(address(collector));
    uint256 balanceCollectorStreamBefore = collector.balanceOf(streamId, address(collector));

    vm.expectEmit(true, true, true, true);
    emit WithdrawFromStream(streamId, RECIPIENT_STREAM_1, 1 ether);

    vm.prank(RECIPIENT_STREAM_1);
    // Act
    collector.withdrawFromStream(streamId, 1 ether);

    // Assert
    uint256 balanceRecipientAfter = tokenA.balanceOf(RECIPIENT_STREAM_1);
    uint256 balanceRecipientStreamAfter = collector.balanceOf(streamId, RECIPIENT_STREAM_1);
    uint256 balanceCollectorAfter = tokenA.balanceOf(address(collector));
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

    uint256 balanceRecipientBefore = tokenA.balanceOf(RECIPIENT_STREAM_1);
    uint256 balanceCollectorBefore = tokenA.balanceOf(address(collector));

    vm.expectEmit(true, true, true, true);
    emit WithdrawFromStream(streamId, RECIPIENT_STREAM_1, 6 ether);

    vm.prank(RECIPIENT_STREAM_1);
    // Act
    collector.withdrawFromStream(streamId, 6 ether);

    // Assert
    uint256 balanceRecipientAfter = tokenA.balanceOf(RECIPIENT_STREAM_1);
    uint256 balanceCollectorAfter = tokenA.balanceOf(address(collector));

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

    vm.expectRevert(ICollector.OnlyFundsAdminOrRecipient.selector);
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
      address(tokenA),
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
    uint256 balanceRecipientBefore = tokenA.balanceOf(RECIPIENT_STREAM_1);

    vm.expectEmit(true, true, true, true);
    emit CancelStream(streamId, address(collector), RECIPIENT_STREAM_1, 6 ether, 0);

    vm.prank(FUNDS_ADMIN);
    // Act
    collector.cancelStream(streamId);

    // Assert
    uint256 balanceRecipientAfter = tokenA.balanceOf(RECIPIENT_STREAM_1);
    assertEq(balanceRecipientAfter, balanceRecipientBefore);

    vm.expectRevert(ICollector.StreamDoesNotExist.selector);
    collector.getStream(streamId);
  }

  function testCancelStreamByRecipient() public {
    vm.prank(FUNDS_ADMIN);
    // Arrange
    uint256 streamId = createStream();
    uint256 balanceRecipientBefore = tokenA.balanceOf(RECIPIENT_STREAM_1);

    vm.warp(block.timestamp + 20);

    vm.expectEmit(true, true, true, true);
    emit CancelStream(streamId, address(collector), RECIPIENT_STREAM_1, 5 ether, 1 ether);

    vm.prank(RECIPIENT_STREAM_1);
    // Act
    collector.cancelStream(streamId);

    // Assert
    uint256 balanceRecipientAfter = tokenA.balanceOf(RECIPIENT_STREAM_1);
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

    vm.expectRevert(ICollector.OnlyFundsAdminOrRecipient.selector);
    vm.prank(makeAddr('random'));

    collector.cancelStream(streamId);
  }

  function createStream() private returns (uint256) {
    return
      collector.createStream(
        RECIPIENT_STREAM_1,
        6 ether,
        address(tokenA),
        streamStartTime,
        streamStopTime
      );
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
