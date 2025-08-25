// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Libraries
import 'forge-std/Test.sol';
import 'src/contracts/protocol/libraries/types/DataTypes.sol';

// Contracts
import {Invariants} from './Invariants.t.sol';
import {Setup} from './Setup.t.sol';

/*
 * Test suite that converts from  "fuzz tests" to foundry "unit tests"
 * The objective is to go from random values to hardcoded values that can be analyzed more easily
 */
contract CryticToFoundry is Invariants, Setup {
  CryticToFoundry public Tester = this;

  modifier setup() override {
    _setSenderActor(address(actor));
    _;
    _resetActorTargets();
  }

  function setUp() public {
    // Deal initial funds
    vm.deal(address(this), 10e40);

    // Etch the create2 factory
    _etchCreate2Factory();

    // Deploy protocol contracts
    _setUp();

    // Deploy actors
    _setUpActors();

    // Initialize handler contracts
    _setUpHandlers();

    /// @dev fixes the actor to the first user
    actor = actors[USER1];
  }

  function _resetActorTargets() internal override {
    delete senderActor;
    delete receiverActor;
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                      POSTCONDITIONS REPLAY                                //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  function test_v32_withdrawEchidna() public {
    this.supply(1677594330, 0, 2);
    this.borrow(1318388898, 0, 2);
    _delay(1096945 + 359438);
    this.withdraw(1, 0, 2);
  }

  function test_v32_borrow() public {
    this.supply(3431582965, 0, 2);
    this.borrow(2345683238, 0, 2);
    _delay(487155);
    this.borrow(1, 0, 2);
  }

  function test_replay_V33_supply() public {
    _setUpActor(0x0000000000000000000000000000000000010000);
    Tester.supply(13, 0, 2);
    Tester.borrow(10, 0, 2);
    _setUpActor(0x0000000000000000000000000000000000020000);
    _delay(202911);
    Tester.supply(32481465935809588205733845034799, 159, 5);
  }

  function test_replay_v33_2transfer() public {
    Tester.supply(13858792590, 0, 0);
    Tester.borrow(11421756840, 0, 0);
    _delay(9317488);
    _delay(435018);
    Tester.setReserveBorrowing(false, 0);
    _delay(405856);
    Tester.transfer(1, 0, 0);
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                 AAVE v3.3 POSTCONDITIONS                                  //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  function test_replay_v33_supply() public {
    Tester.supply(2774, 0, 2); // supply actor 0, reserve 2
    Tester.borrow(1, 0, 2); // borrow actor 0, reserve 2
    Tester.setEModeCategory(1, 1, 1, 10796); // create eMODE
    Tester.setAssetBorrowableInEMode(true, 2, 0); // set reserve 2 as borrowable in eMODE
    Tester.setUserEMode(0); // activate eMode for user 0
    Tester.setAssetCollateralInEMode(true, 0, 0); // set reserve 0 as collateral in eMODE
    Tester.supply(5657367, 0, 0); // supply actor 0 reserve 0
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                    ACKNOWLEDGED PROPERTIES                                //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                           HELPERS                                         //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  /// @notice Fast forward the time and set up an actor,
  /// @dev Use for ECHIDNA call-traces
  function _delay(uint256 _seconds) internal {
    vm.warp(block.timestamp + _seconds);
  }

  function _delay(uint256 _seconds, uint256 _blocks) internal {
    vm.warp(block.timestamp + _seconds);
    vm.roll(block.number + _blocks);
  }

  /// @notice Set up an actor
  function _setUpActor(address _origin) internal {
    actor = actors[_origin];
  }

  /// @notice Set up an actor and fast forward the time
  /// @dev Use for ECHIDNA call-traces
  function _setUpActorAndDelay(address _origin, uint256 _seconds) internal {
    actor = actors[_origin];
    vm.warp(block.timestamp + _seconds);
  }

  /// @notice Set up a specific block and actor
  function _setUpBlockAndActor(uint256 _block, address _user) internal {
    vm.roll(_block);
    actor = actors[_user];
  }

  /// @notice Set up a specific timestamp and actor
  function _setUpTimestampAndActor(uint256 _timestamp, address _user) internal {
    vm.warp(_timestamp);
    actor = actors[_user];
  }
}
