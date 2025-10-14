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

    // Initialize hook contracts
    _setUpHooks();

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

  function test_v32_repay() public {
    this.supply(2, 0, 2);
    this.borrow(1, 0, 2);
    this.repay(2, 0, 2);
  }

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

  function test_v32_2_borrow() public {
    _setUpActorAndDelay(USER1, 453881);
    this.approveDelegation(
      1482526189130252178123437018605205213532554266044322803735452163998541884248,
      226,
      251
    );
    _setUpActorAndDelay(USER1, 42941);
    this.supply(1000000000000000001, 33, 89);
    _setUpActorAndDelay(USER1, 67960);
    this.setEModeCategory(118, 189, 2300, 30039);
    _setUpActorAndDelay(USER2, 287316);
    this.setUserEMode(145);
    _setUpActorAndDelay(USER2, 438639);
    this.borrow(2848252610, 0, 2);
  }

  function test_v32_mintToTreasury() public {
    this.supply(3041074758, 0, 2);
    this.borrow(1751260225, 0, 2);
    this.setSupplyCap(1, 2);
    _delay(1);
    this.repay(970718753344623226599485441986528198456093968035926, 0, 2);
    this.mintToTreasury(2);
  }

  function test_v32_setPoolPause() public {
    vm.warp(300000);
    vm.roll(5000);
    Tester.supply(12, 0, 2);
    Tester.borrow(10, 0, 2);
    _delay(118940, 13757);
    _delay(574632, 9197);
    _delay(471382, 57366);
    _delay(405856, 53171);
    Tester.setBorrowableInIsolation(false, 1);
    _delay(589510, 42942);
    _delay(166788, 47047);
    Tester.setSiloedBorrowing(false, 77);
    _delay(587943, 13);
    Tester.liquidationCall(288742439642722165085359095038843984, false, 47, 149, 1, 1);
    _delay(566826, 14939);
    Tester.setReserveBorrowing(false, 17);
    _delay(4137166, 148483);
    _delay(322122, 25);
    Tester.setReserveBorrowing(false, 5);
    _delay(1731509, 50432);
    Tester.mintToTreasury(94);
    _delay(1175748, 125272);
    _delay(155489, 58989);
    Tester.setLiquidationProtocolFee(0, 0);
    _delay(534073, 1953);
    Tester.increaseAllowance(
      2903000394675170785137978058613790841450925157038471986390143556336053766387,
      32,
      0
    );
    _delay(322295, 18582);
    Tester.setUserUseReserveAsCollateral(false, 115);
    _delay(348682, 54175);
    Tester.increaseAllowance(
      42925595869256018644087582406413896859640439692615489585536378306598920896616,
      128,
      90
    );
    _delay(531977, 11565);
    Tester.setReserveBorrowing(false, 1);
    _delay(263948, 44841);
    Tester.setSiloedBorrowing(false, 45);
    _delay(296955, 3064);
    Tester.setBorrowableInIsolation(false, 0);
    _delay(533788, 46068);
    _delay(578021, 4029);
    Tester.increaseAllowance(
      440958157672998905105592764771506942420834309123016558302398494718463910559,
      70,
      109
    );
    _delay(614330, 99857);
    _delay(235662, 57086);
    Tester.setLatestAnswer(316924, 16);
    _delay(112444, 5237);
    Tester.borrow(214, 105, 18);
    Tester.setPoolPause(false, 0);
  }

  function test_replay_v33_setReserveActive() public {
    Tester.supply(12, 0, 2);
    Tester.borrow(10, 0, 2);
    _delay(221772);
    _delay(198287);
    Tester.mintToTreasury(1);
    _delay(9308017);
    Tester.setReserveActive(false, 4);
  }

  function test_replay_v33_repayWithATokens() public {
    Tester.supply(5699, 0, 2); // Supply actor 0 reserve 2
    Tester.borrow(154, 0, 2); // Borrow actor 0 reserve 2
    Tester.setEModeCategory(1, 1, 1, 10106); // Create eMode category
    Tester.setAssetBorrowableInEMode(true, 2, 0); // Activate eMode for reserve 2
    Tester.setUserEMode(0); // Activate eMode for 0
    Tester.setAssetCollateralInEMode(true, 2, 0); // Activate eMode for reserve 2
    Tester.repayWithATokens(1, 2);
  }

  function test_replay_v33_2setUserEMode() public {
    Tester.supply(4183160697, 0, 2);
    Tester.borrow(1545544875, 0, 2);
    Tester.setEModeCategory(1, 1, 1, 14404);
    Tester.setAssetBorrowableInEMode(true, 2, 0);
    Tester.setUserEMode(0);
    Tester.setAssetCollateralInEMode(true, 2, 0);
    _delay(24867);
    Tester.setUserEMode(15);
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

  function test_replay_v33_2repayWithAtokens() public {
    Tester.supply(550409, 0, 2);
    Tester.borrow(445417, 0, 2);
    _delay(3302127);
    Tester.repayWithATokens(5, 2);
  }

  function test_replay_v33_assert_BORROWING_HSPOST_G() public {
    Tester.supply(2, 0, 2);
    Tester.borrow(1, 0, 2);
    _delay(412020);
    _delay(8045);
    Tester.setReserveBorrowing(false, 0);
    _delay(580741);
    Tester.supply(2897875185, 0, 2);
    Tester.repay(32575726, 0, 2);
    Tester.assert_BORROWING_HSPOST_G(2);
  }

  function test_replay_v33_3liquidationCall() public {
    Tester.supply(550409, 0, 2);
    Tester.borrow(445417, 0, 2);
    _delay(2252661 + 393101);
    Tester.approve(
      85816025910022903715357347415778016859141149493197187365595267387137827715779,
      0,
      5
    );
    _delay(112516);
    Tester.repay(
      115792089237316195423570985008687907853269984665640564039457584007913129639933,
      23,
      110
    );
    _delay(243803);
    Tester.approve(
      65609807886680263139209343924550770393978137453194200189176562977589895282170,
      6,
      177
    );
    _delay(585505);
    Tester.increaseAllowance(
      26091149535616436666993674031014365215554587051967826255295155471152712491920,
      7,
      0
    );
    _delay(1433009 + 389576);
    Tester.setLatestAnswer(
      15961020187089609539994664005862511207456112520921648682428095379252895341460,
      86
    );
    _delay(571389);
    Tester.setLatestAnswer(
      12110082393770152637771864563855718214753398550442805668132194565202580299239,
      95
    );
    _delay(5308935 + 65534);
    Tester.setLatestAnswer(72057594037927936, 0);
    _delay(1776602 + 139880);
    Tester.approve(66, 195, 145);
    _delay(1776602 + 439556);
    _setUpActor(USER2);
    Tester.liquidationCall(18, true, 120, 251, 239, 198);
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                    AAVE v3.4 PostConditions                               //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  function test_replay() public {
    _delay(540569);
    _setUpActor(0x0000000000000000000000000000000000020000);
    _delay(144683);
    Tester.supply(385, 13, 13);
    _delay(193);
    Tester.liquidationCall(
      22900426696761416736584470058323642222356459238800218407334671570241883983104,
      false,
      78,
      255,
      124,
      18
    );
    _setUpActor(0x0000000000000000000000000000000000030000);
    _delay(194185);
    Tester.repay(
      111695694298321964670773474604913965605837081970419878535886666889354007262477,
      81,
      107
    );
    _delay(465868);
    _delay(543756);
    Tester.setBorrowableInIsolation(false, 56);
    _delay(322369);
    Tester.repayWithATokens(1000000000000000000000000001, 136);
    _setUpActor(0x0000000000000000000000000000000000020000);
    _delay(554465);
    Tester.borrow(74, 253, 172);
    _delay(1124189);
    _setUpActor(0x0000000000000000000000000000000000010000);
    _delay(321976);
    Tester.setBorrowableInIsolation(false, 30);
    _delay(207616);
    _setUpActor(0x0000000000000000000000000000000000030000);
    _delay(540055);
    Tester.liquidationCall(192, true, 117, 208, 253, 90);
    _setUpActor(0x0000000000000000000000000000000000020000);
    _delay(369744);
    Tester.mintToTreasury(60);
    _delay(326609);
    _setUpActor(0x0000000000000000000000000000000000030000);
    _delay(57);
    Tester.mintToTreasury(127);
    _delay(316376);
    _delay(31593);
    Tester.approve(55, 64, 183);
    _setUpActor(0x0000000000000000000000000000000000010000);
    _delay(322328);
    Tester.approveDelegation(
      8303352665171686146102356330506429166649503984796466138632165112781853194349,
      184,
      17
    );
    _setUpActor(0x0000000000000000000000000000000000030000);
    _delay(322348);
    Tester.setUserUseReserveAsCollateral(true, 49);
    _delay(1792165);
    _setUpActor(0x0000000000000000000000000000000000020000);
    _delay(574633);
    Tester.repay(
      72144593969258653755665686694365197026935503013285187126279558013466900981624,
      55,
      191
    );
    _delay(2320297);
    _delay(147386);
    Tester.setUserUseReserveAsCollateral(false, 123);
    _setUpActor(0x0000000000000000000000000000000000010000);
    _delay(485723);
    Tester.borrow(
      15404404347557743870905086496147925372030932412182646426230501318168770693424,
      167,
      151
    );
    _delay(704107);
    _setUpActor(0x0000000000000000000000000000000000020000);
    _delay(507315);
    Tester.setReserveBorrowing(true, 10);
    _delay(290780);
    _setUpActor(0x0000000000000000000000000000000000030000);
    _delay(201321);
    Tester.approve(36, 77, 162);
    _delay(566827);
    _setUpActor(0x0000000000000000000000000000000000020000);
    _delay(244395);
    Tester.setReserveActive(false, 101);
    _setUpActor(0x0000000000000000000000000000000000030000);
    _delay(571676);
    Tester.donateUnderlying(
      60291210913057668399543349168457288827189842013386976297734076226517468937168,
      53
    );
    _delay(129);
    Tester.borrow(
      73513395575466754555890836269373299360027492438755715214792618479483629238494,
      34,
      8
    );
    _delay(474371);
    _setUpActor(0x0000000000000000000000000000000000010000);
    _delay(207835);
    Tester.repay(5999, 253, 11);
    _delay(150661);
    _setUpActor(0x0000000000000000000000000000000000030000);
    _delay(335983);
    Tester.increaseAllowance(
      115792089237316195423570985008687907853269984665640564039457584007913129639837,
      81,
      165
    );
    _delay(201322);
    _delay(31);
    Tester.setSiloedBorrowing(false, 254);
    _setUpActor(0x0000000000000000000000000000000000020000);
    _delay(267747);
    Tester.setSiloedBorrowing(false, 192);
    _delay(254480);
    _setUpActor(0x0000000000000000000000000000000000010000);
    _delay(322370);
    Tester.setUserUseReserveAsCollateral(true, 59);
    _delay(1631417);
    _setUpActor(0x0000000000000000000000000000000000030000);
    _delay(128188);
    Tester.disableLiquidationGracePeriod(2);
    _delay(500051);
    _delay(525476);
    Tester.mintToTreasury(0);
    _delay(4500);
    _setUpActor(0x0000000000000000000000000000000000010000);
    _delay(352544);
    Tester.setReservePause(false, 59, 70);
    _delay(433110);
    Tester.borrow(
      15858183724532343881079421634084711474828947298149665635368121885305367154254,
      88,
      6
    );
    _delay(100001);
    _setUpActor(0x0000000000000000000000000000000000020000);
    _delay(85182);
    Tester.setReserveActive(true, 133);
    _delay(1124024);
    _delay(448552);
    Tester.setReservePause(true, 401, 153);
    _setUpActor(0x0000000000000000000000000000000000010000);
    _delay(79274);
    Tester.liquidationCall(839, true, 191, 213, 151, 169);
    _setUpActor(0x0000000000000000000000000000000000030000);
    _delay(441539);
    Tester.approveDelegation(27, 26, 202);
    _delay(863014);
    _setUpActor(0x0000000000000000000000000000000000010000);
    _delay(177691);
    Tester.setSiloedBorrowing(false, 254);
    _delay(2207685);
    _delay(322247);
    Tester.disableLiquidationGracePeriod(5);
    _delay(589539);
    _setUpActor(0x0000000000000000000000000000000000030000);
    _delay(357826);
    Tester.increaseAllowance(1513729759371624186953334462000902398281919011002523341962, 245, 41);
    _delay(1394092);
    _setUpActor(0x0000000000000000000000000000000000020000);
    _delay(256841);
    Tester.increaseAllowance(
      28815262393387353891699682522559882541826515824646724370937775750521242317293,
      122,
      220
    );
    _delay(1344969);
    _setUpActor(0x0000000000000000000000000000000000030000);
    _delay(344203);
    Tester.approve(
      42781945847000261017560425177569179459669254910944366752090067922001662062337,
      36,
      152
    );
    _delay(322163);
    _setUpActor(0x0000000000000000000000000000000000010000);
    _delay(317875);
    Tester.setReserveBorrowing(true, 241);
    _delay(557434);
    _setUpActor(0x0000000000000000000000000000000000030000);
    _delay(65534);
    Tester.repayWithATokens(
      39418351649016577482093460580674059228558974499491399749985371727708980813621,
      254
    );
    _setUpActor(0x0000000000000000000000000000000000010000);
    _delay(136392);
    Tester.repay(
      115792089237316195423570985008687907853269984665640564039457584007913129639685,
      197,
      191
    );
    _delay(128189);
    _setUpActor(0x0000000000000000000000000000000000030000);
    _delay(16802);
    Tester.mintToTreasury(10);
    _delay(352898);
    _setUpActor(0x0000000000000000000000000000000000020000);
    _delay(201322);
    Tester.rescueTokens(0, 233, 24);
    _delay(615435);
    _setUpActor(0x0000000000000000000000000000000000030000);
    _delay(490446);
    Tester.increaseAllowance(4611686018427387903, 158, 237);
    _setUpActor(0x0000000000000000000000000000000000020000);
    _delay(207449);
    Tester.setBorrowCap(86, 135);
    _setUpActor(0x0000000000000000000000000000000000010000);
    _delay(474370);
    Tester.setBorrowableInIsolation(true, 57);
    _delay(321974);
    _setUpActor(0x0000000000000000000000000000000000020000);
    _delay(126794);
    Tester.increaseAllowance(
      115792089237316195423570985008687907853269984665640564039457584007913129639869,
      19,
      252
    );
    _delay(1922781);
    _setUpActor(0x0000000000000000000000000000000000010000);
    _delay(322297);
    Tester.donateUnderlying(661498954887064897801522981861045230038519621, 77);
    _delay(332493);
    _delay(489339);
    Tester.repayWithATokens(2158778574, 81);
    _setUpActor(0x0000000000000000000000000000000000020000);
    _delay(360350);
    Tester.setSiloedBorrowing(true, 180);
    _delay(1579099);
    _delay(243724);
    Tester.borrow(74, 253, 172);
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
