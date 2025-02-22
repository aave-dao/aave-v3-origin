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

  function test_v32_liquidationCall() public {
    this.supply(5, 0, 2);
    this.borrow(3, 0, 2);
    this.setEModeCategory(1, 1, 1, 10162);
    this.setAssetBorrowableInEMode(true, 2, 0);
    this.setUserEMode(0);
    this.setBorrowCap(1, 2);
    this.setAssetCollateralInEMode(true, 2, 0);
    this.repayWithATokens(573563701426480009549314384455393, 0);
    this.liquidationCall(1, false, 0, 2, 2, 1);
  }

  function test_v32_2_liquidationCall() public {
    Tester.supply(2, 0, 2);
    Tester.borrow(1, 0, 2);
    Tester.setEModeCategory(1, 1, 1, 10056);
    Tester.setAssetBorrowableInEMode(true, 2, 0);
    Tester.setUserEMode(0);
    Tester.setAssetCollateralInEMode(true, 2, 0);
    Tester.liquidationCall(6778532116232073050300278441650955286601645000915606, false, 0, 2, 2, 1);
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

  function test_replay_V33_transferFrom() public {
    _setUpActor(0x0000000000000000000000000000000000030000);
    _delay(522178);
    Tester.supply(657417928008, 0, 1);
    _setUpActor(0x0000000000000000000000000000000000010000);
    Tester.supply(12, 0, 2);
    Tester.borrow(10, 0, 2);
    _delay(571677);
    Tester.increaseAllowance(
      6273176033789177866065594142720493832380394006134877985919878609507187554376,
      241,
      11
    );
    _delay(4444503);
    _setUpActor(0x0000000000000000000000000000000000020000);
    _delay(5999);
    Tester.transferFrom(
      13,
      237,
      203,
      77967604747426594918862951366170156297569950523258733931584971918416530236914
    );
  }

  function test_replay_v33_setPoolPause() public {
    Tester.supply(3800242383, 0, 2);
    Tester.borrow(1545544875, 0, 2);
    Tester.transfer(1915936695, 1, 14);
    Tester.setEModeCategory(1, 1, 1, 12585);
    Tester.setAssetBorrowableInEMode(true, 2, 0);
    Tester.setUserEMode(0);
    Tester.setAssetCollateralInEMode(true, 2, 0);
    Tester.liquidationCall(1530121547, false, 0, 59, 26, 0);
    Tester.eliminateReserveDeficit(1, 2);
    Tester.setPoolPause(false, 0);
  }

  function test_replay_V33_setUserEMode() public {
    Tester.supply(4044391234, 0, 2);
    Tester.borrow(1534216041, 0, 2);
    Tester.transfer(1985216202, 1, 2);
    Tester.setEModeCategory(1, 1, 1, 14404);
    Tester.setAssetBorrowableInEMode(true, 2, 0);
    Tester.setUserEMode(0);
    Tester.setAssetCollateralInEMode(true, 2, 0);
    Tester.liquidationCall(1746069837, false, 75, 83, 38, 1);
    Tester.eliminateReserveDeficit(1, 2);
    Tester.setUserEMode(0);
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

  function test_replay_v33_eliminateReserveDeficit() public {
    Tester.supply(4183160697, 0, 2);
    Tester.borrow(1545544875, 0, 2);
    Tester.transfer(1985216202, 1, 17);
    Tester.setEModeCategory(1, 1, 1, 14404);
    Tester.setAssetBorrowableInEMode(true, 2, 0);
    Tester.setUserEMode(0);
    Tester.setAssetCollateralInEMode(true, 2, 0);
    Tester.liquidationCall(1549948783, false, 15, 14, 2, 21);
    Tester.eliminateReserveDeficit(19880870, 5);
  }

  function test_replay_v33_2liquidationCall() public {
    // SUPPLY reserve 2 to actor 0
    Tester.supply(1922549088, 0, 2);
    // BORROW reserve 2 from actor 0
    Tester.borrow(1463850880, 0, 2);
    Tester.setEModeCategory(1, 1, 1, 14404); // Emode category 1
    Tester.setAssetBorrowableInEMode(true, 2, 0); // Activate Emode category 1 for reserve 2
    Tester.setUserEMode(0); // User set Emode category 1
    Tester.setAssetCollateralInEMode(true, 2, 0);
    Tester.liquidationCall( // liquidate actor 0 reserve 2 debt receivingAtokens and max debtToCover
      365179074625689739418917921589108537988802797566181241070158536003800606873,
      true,
      0,
      2,
      2,
      3
    );
  }

  function test_replay_v33_borrow() public {
    // HF_GPOST_D: If HF is unsafe after an action (HF < 1.0), the action must belong to hfUnsafeAfterAction
    _setUpActor(0x0000000000000000000000000000000000010000);
    Tester.supply(1, 1, 0);
    Tester.supply(1, 0, 2);
    Tester.borrow(1, 0, 0);
    _delay(311979);
    Tester.increaseAllowance(513105139, 8, 25);
    _delay(516956);
    Tester.setUserUseReserveAsCollateral(true, 168);
    _delay(112916);
    _delay(202181);
    Tester.setBorrowableInIsolation(false, 27);
    _delay(531978);
    Tester.setReserveBorrowing(false, 30);
    _delay(5046848);
    _delay(38059);
    Tester.setBorrowableInIsolation(false, 55);
    _setUpActor(0x0000000000000000000000000000000000020000);
    _delay(303345);
    Tester.disableLiquidationGracePeriod(141);
    _setUpActor(0x0000000000000000000000000000000000030000);
    _delay(322247);
    Tester.borrow(2848252610, 0, 2);
    _delay(82672);
    Tester.setLatestAnswer(
      8297305240048690104559311266951712284695941564805536635134314972350744968943,
      161
    );
    _setUpActor(0x0000000000000000000000000000000000010000);
    _delay(332369);
    Tester.donateUnderlying(
      96632813453761016924137105566782796567896479502322553834458859805073736090880,
      53
    );
    _setUpActor(0x0000000000000000000000000000000000020000);
    _delay(407328);
    Tester.repay(1524785991, 255, 64);
    _delay(277232);
    Tester.setReserveActive(true, 51);
    _setUpActor(0x0000000000000000000000000000000000010000);
    _delay(209930);
    Tester.donateUnderlying(4370000, 208);
    _delay(3072501);
    _setUpActor(0x0000000000000000000000000000000000030000);
    _delay(127251);
    Tester.increaseAllowance(
      100686595376288898789091393373158066141873755820473760922441694199724445608207,
      255,
      255
    );
    _delay(533862);
    _delay(241250);
    Tester.supply(1099511627776, 0, 185);
    _delay(202911);
    Tester.setUserUseReserveAsCollateral(false, 78);
    _delay(209858);
    Tester.setReserveActive(true, 128);
    _setUpActor(0x0000000000000000000000000000000000020000);
    _delay(76);
    Tester.setDebtCeiling(465, 97);
    _setUpActor(0x0000000000000000000000000000000000030000);
    _delay(64406);
    Tester.setSiloedBorrowing(true, 7);
    _setUpActor(0x0000000000000000000000000000000000020000);
    _delay(521219);
    Tester.approveDelegation(
      115792089237316195423570985008687907853269984665640564039457584007910753493070,
      255,
      56
    );
    _delay(3946136);
    _setUpActor(0x0000000000000000000000000000000000010000);
    _delay(463588);
    Tester.borrow(
      20187168876775220233720774761258734003521555161596916184656049765614623609022,
      253,
      141
    );
    _setUpActor(0x0000000000000000000000000000000000030000);
    _delay(585506);
    Tester.setBorrowableInIsolation(true, 134);
    _setUpActor(0x0000000000000000000000000000000000010000);
    _delay(222934);
    Tester.borrow(515, 133, 233);
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

  function test_replay_v33_assert_BORROWING_HSPOST_C() public {
    _setUpActor(0x0000000000000000000000000000000000030000);
    _delay(566039);
    Tester.supply(340282366920938463463374607431768211455, 145, 3);
    _setUpActor(0x0000000000000000000000000000000000020000);
    _delay(366106);
    Tester.borrow(18446744073709551614, 223, 57);
    _delay(290780);
    Tester.supply(64, 0, 0);
    _delay(510412);
    Tester.assert_BORROWING_HSPOST_C(198);
  }

  function test_replay_v33_liquidationCall() public {
    Tester.supply(1922549088, 0, 2);
    Tester.borrow(1545544875, 0, 2);
    _delay(14738813);
    _delay(252150);
    Tester.setLatestAnswer(52842367, 0);
    _delay(395269);
    Tester.liquidationCall(
      96116319240538101021441800223011440398035853240172630474486511372044082416607,
      false,
      0,
      2,
      2,
      0
    );
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
    _delay(322182);
    Tester.updateBridgeProtocolFee(30);
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
  //                                    AAVE v3.3 INVARIANTS                                   //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  function test_replay_v33_echidna_BASE_INVARIANT_B() public {
    Tester.supply(2807715042, 0, 2);
    Tester.borrow(596145839, 0, 2);
    Tester.transfer(1985216202, 1, 2);
    Tester.setEModeCategory(1, 1, 1, 13852);
    Tester.setAssetBorrowableInEMode(true, 2, 0);
    Tester.setUserEMode(0);
    Tester.setAssetCollateralInEMode(true, 2, 0);
    Tester.liquidationCall(601634581, false, 0, 2, 2, 1);
    Tester.eliminateReserveDeficit(2419696, 2);
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                    ACKNOWLEDGED PROPERTIES                                //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  function test_replay_v33_echidna_BORROWING_INVARIANT_B() public {
    Tester.supply(11, 0, 2);
    Tester.borrow(9, 0, 2);
    _delay(249243);
    Tester.approveDelegation(
      96559532227550485757689127554436600813492672962756024016014493407936459690099,
      138,
      5
    );
    _delay(797176);
    _delay(322163);
    Tester.setSupplyCap(22104, 134);
    _delay(395237);
    _delay(150273);
    Tester.disableLiquidationGracePeriod(60);
    _delay(103183);
    _delay(168456);
    Tester.borrow(1327428230, 1, 28);
    _delay(263947);
    _delay(494836);
    Tester.repay(
      113460169279075452955927818204721906413602155416877199543651084515419479895901,
      199,
      99
    );
    _delay(1318719);
    _delay(453829);
    Tester.setReserveBorrowing(false, 76);
    _delay(486059);
    Tester.approve(
      64349701272837019632051932641313431036955485130917153021714579928156825285075,
      206,
      1
    );
    _delay(2982799);
    _delay(321976);
    Tester.approveDelegation(
      343742201451480911781285470307753062059237751591242006381088082742779877065,
      57,
      2
    );
    _delay(365349);
    Tester.repayWithATokens(
      115792089237316195423570985008687907853269984665640564039457584007844410163201,
      78
    );
    _delay(3182445);
    _delay(453882);
    Tester.disableLiquidationGracePeriod(7);
    _delay(554800);
    _delay(364254);
    Tester.donateUnderlying(
      33337808402080397431805607158584434285128862021942434413263860547193192284972,
      62
    );
    _delay(444062);
    _delay(526194);
    Tester.setBorrowableInIsolation(false, 59);
    _delay(23659);
    Tester.repayWithATokens(
      115792089237316195423570985008687907853269984665640564039457584007913129639931,
      22
    );
    _delay(254064);
    Tester.repay(
      14496732263044785785643510598825711964785226055010338430033690695699625410654,
      13,
      116
    );
    _delay(314126);
    _delay(81125);
    Tester.donateUnderlying(
      53540767030399028531450202967299416451876520590810187251495755588218324309338,
      8
    );
    _delay(118436);
    Tester.setBorrowableInIsolation(false, 37);
    _delay(424359);
    _delay(76166);
    Tester.disableLiquidationGracePeriod(60);
    _delay(1891064);
    _delay(439556);
    Tester.mintToTreasury(190);
    _delay(363241);
    Tester.setBorrowableInIsolation(false, 45);
    _delay(578493);
    Tester.borrow(
      56495079163379291484208169586838199933931760527964707990976030993653418545813,
      231,
      9
    );
    _delay(352898);
    Tester.increaseAllowance(1479890949, 102, 23);
    _delay(209859);
    Tester.repayWithATokens(90725520, 87);
    _delay(615164);
    _delay(412018);
    Tester.disableLiquidationGracePeriod(58);
    _delay(322182);
    Tester.setBorrowableInIsolation(true, 159);
    _delay(444470);
    _delay(217367);
    Tester.increaseAllowance(
      99504725668169871490339201623232949640414720075879459043430204935223715829141,
      84,
      208
    );
    _delay(464605);
    _delay(322306);
    Tester.setSiloedBorrowing(false, 108);
    _delay(185610);
    _delay(243804);
    Tester.approve(
      115792089237316195423570985008687907853269984665640564039457584007912129639935,
      77,
      19
    );
    _delay(112516);
    Tester.setReserveActive(true, 129);
    _delay(294084);
    Tester.approve(
      24132821072604019452845433356869456752194585476275041561253141166468891111311,
      252,
      9
    );
    _delay(591193);
    _delay(472700);
    Tester.approveDelegation(
      115792089237316195423570985008687907853269984665640564039457584007913129639931,
      108,
      58
    );
    _delay(322124);
    _delay(197791);
    Tester.setReserveBorrowing(true, 251);
    _delay(436728);
    Tester.liquidationCall(
      45314777003086831491907766032761308330683725952490920024602233352791613874361,
      false,
      12,
      80,
      149,
      12
    );
    _delay(323860);
    _delay(81127);
    Tester.mintToTreasury(79);
    _delay(2166714);
    _delay(276464);
    Tester.borrow(464038687, 142, 43);
    _delay(322275);
    Tester.approveDelegation(
      115792089237316195423570985008687907853269984665640564039456584007913129639935,
      49,
      239
    );
    _delay(107457);
    Tester.mintToTreasury(125);
    _delay(290008);
    _delay(284227);
    Tester.repay(13, 249, 92);
    echidna_BORROWING_INVARIANT_B();
  }

  function test_replay_v33_echidna_BORROWING_INVARIANT_C() public {
    _setUpActor(0x0000000000000000000000000000000000010000);
    Tester.supply(13, 0, 2);
    Tester.borrow(9, 0, 2);
    _delay(312476);
    Tester.donateUnderlying(
      38597363079105398474523661669562635951089994888546854679819194669304376546646,
      152
    );
    _delay(497065);
    _setUpActor(0x0000000000000000000000000000000000020000);
    _delay(150663);
    Tester.mintToTreasury(22);
    _delay(753461);
    _setUpActor(0x0000000000000000000000000000000000010000);
    _delay(501);
    Tester.setLiquidationProtocolFee(544, 59);
    _delay(210862);
    _delay(322163);
    Tester.setSupplyCap(22104, 134);
    _delay(395237);
    _delay(201910);
    Tester.increaseAllowance(
      115792089237316195423570984634549197687329661445021480007966928956539929624577,
      52,
      50
    );
    _delay(150273);
    Tester.disableLiquidationGracePeriod(60);
    _setUpActor(0x0000000000000000000000000000000000020000);
    _delay(372377);
    Tester.mintToTreasury(132);
    _delay(490448);
    Tester.setSiloedBorrowing(false, 119);
    _delay(323335);
    _setUpActor(0x0000000000000000000000000000000000010000);
    _delay(206186);
    Tester.borrow(1327428230, 18, 216);
    _delay(1007361);
    _delay(494836);
    Tester.repay(
      113460169279075452955927818204721906413602155416877199543651084515419479895901,
      199,
      99
    );
    _delay(1318719);
    _delay(386500);
    Tester.disableLiquidationGracePeriod(142);
    _delay(1578413);
    _delay(16379);
    Tester.setPoolPause(true, 998192973888);
    _delay(571677);
    _setUpActor(0x0000000000000000000000000000000000020000);
    _delay(85184);
    Tester.approveDelegation(
      84875307276726038152192332581522015542772245101417910105142414348553559208135,
      107,
      104
    );
    _setUpActor(0x0000000000000000000000000000000000010000);
    _delay(99999);
    Tester.approveDelegation(
      1613474119862448886066051152177351161896046623019441561857805191125617202734,
      170,
      68
    );
    _delay(992305);
    _delay(220715);
    Tester.approve(
      64349701272837019632051932641313431036955485130917153021714579928156825285075,
      206,
      1
    );
    _delay(322311);
    _delay(322317);
    Tester.increaseAllowance(
      48533652378942908258893408390091813604477137072018964141136305550863099289849,
      0,
      14
    );
    _setUpActor(0x0000000000000000000000000000000000020000);
    _delay(4500);
    Tester.borrow(1327428230, 18, 131);
    _delay(151630);
    Tester.approveDelegation(
      74911391484337287233966267409706790275863770848686748264948371050367839215021,
      186,
      60
    );
    _delay(930292);
    _setUpActor(0x0000000000000000000000000000000000010000);
    _delay(322192);
    Tester.setReservePause(true, 676530760, 5);
    _delay(848624);
    _delay(254);
    Tester.setReservePause(true, 202820251559, 130);
    _delay(139878);
    _delay(534073);
    Tester.setSiloedBorrowing(false, 205);
    _delay(321976);
    Tester.approveDelegation(
      11279170954544410566632619763891525999672477049343347561993816970714309857791,
      57,
      16
    );
    _delay(365349);
    Tester.repayWithATokens(
      115792089237316195423570985008687907853269984665640564039457584007844410163201,
      78
    );
    _delay(1552097);
    _delay(380129);
    Tester.disableLiquidationGracePeriod(129);
    _delay(498362);
    _setUpActor(0x0000000000000000000000000000000000020000);
    _delay(191);
    Tester.setBorrowCap(1000000001, 194);
    _delay(9899);
    _setUpActor(0x0000000000000000000000000000000000010000);
    _delay(500);
    Tester.setDebtCeiling(499, 160);
    _delay(338900);
    _delay(574278);
    Tester.setSupplyCap(4294967294, 213);
    _delay(384976);
    _setUpActor(0x0000000000000000000000000000000000020000);
    _delay(410218);
    Tester.approveDelegation(
      1791444163243152098506318537516770225823353145304134936902401035756172599955,
      17,
      185
    );
    _setUpActor(0x0000000000000000000000000000000000010000);
    _delay(453882);
    Tester.disableLiquidationGracePeriod(53);
    _delay(554800);
    _delay(489338);
    Tester.donateUnderlying(
      33337808402080397431805607158584434285128862021942434413263860547193192284972,
      62
    );
    _delay(1449557);
    _delay(526194);
    Tester.setBorrowableInIsolation(false, 212);
    _delay(76801);
    Tester.repayWithATokens(
      115792089237316195423570985008687907853269984665640564039457584007913129639931,
      22
    );
    _delay(160);
    Tester.increaseAllowance(756, 33, 62);
    _delay(314126);
    _delay(125043);
    Tester.setBorrowableInIsolation(true, 128);
    _setUpActor(0x0000000000000000000000000000000000020000);
    _delay(3865);
    Tester.setReservePause(true, 957959805942, 33);
    _delay(420494);
    _setUpActor(0x0000000000000000000000000000000000010000);
    _delay(415094);
    Tester.disableLiquidationGracePeriod(4);
    _delay(599991);
    _setUpActor(0x0000000000000000000000000000000000020000);
    _delay(15377);
    Tester.setReserveActive(false, 13);
    _setUpActor(0x0000000000000000000000000000000000010000);
    _delay(567572);
    Tester.repayWithATokens(
      86987830605528395587543624303367251153705364798916692144644677933807453727485,
      22
    );
    _delay(401);
    Tester.donateUnderlying(10950826, 29);
    _delay(439556);
    Tester.mintToTreasury(192);
    _setUpActor(0x0000000000000000000000000000000000020000);
    _delay(24867);
    Tester.setUserUseReserveAsCollateral(true, 105);
    _setUpActor(0x0000000000000000000000000000000000010000);
    _delay(363241);
    Tester.setBorrowableInIsolation(false, 56);
    _setUpActor(0x0000000000000000000000000000000000020000);
    _delay(578493);
    Tester.borrow(
      48894047680164008559879478276387182687652521969141973255800075300778001534327,
      41,
      8
    );
    _delay(298366);
    _setUpActor(0x0000000000000000000000000000000000010000);
    _delay(566551);
    Tester.updateBridgeProtocolFee(4999);
    _delay(322198);
    Tester.increaseAllowance(4395, 191, 86);
    _delay(209859);
    Tester.repayWithATokens(1009598478, 87);
    _delay(293043);
    _delay(322119);
    Tester.setSiloedBorrowing(false, 69);
    _delay(984266);
    _delay(476283);
    Tester.setBorrowCap(1158924002, 61);
    _delay(537600);
    _delay(277232);
    Tester.repay(9, 115, 17);
    _delay(50312);
    Tester.setSiloedBorrowing(true, 60);
    _delay(238206);
    Tester.approve(
      115792089237316195423570985008687907853269984665640564039457584007913129639934,
      211,
      55
    );
    _delay(303271);
    _delay(111322);
    Tester.repayWithATokens(
      49008279356062424391164723044804177852197100800299611036025768231534049552023,
      9
    );
    _delay(250896);
    Tester.disableLiquidationGracePeriod(152);
    _delay(312376);
    Tester.setReservePause(true, 593176363, 78);
    _delay(45142);
    _delay(420078);
    Tester.setReserveBorrowing(true, 184);
    _delay(465191);
    _delay(395199);
    Tester.approve(
      87247375124337106854136739660572870865681418592845079988592088127092848022159,
      34,
      30
    );
    _delay(469355);
    _delay(144683);
    Tester.liquidationCall(
      91352034832010926057001582751876410893860910903135406657784615168643518944325,
      false,
      66,
      212,
      254,
      1
    );
    _delay(322123);
    Tester.repayWithATokens(
      115792089237316195423570985008687907853269984665640564039457584007909683116410,
      154
    );
    _delay(194499);
    _delay(64406);
    Tester.setLiquidationProtocolFee(143, 213);
    _delay(513489);
    _delay(376096);
    Tester.setReserveBorrowing(false, 252);
    _delay(516956);
    _delay(401040);
    Tester.setUserUseReserveAsCollateral(false, 145);
    _delay(1425381);
    _setUpActor(0x0000000000000000000000000000000000020000);
    _delay(322215);
    Tester.setReservePause(true, 164, 184);
    _delay(290781);
    _setUpActor(0x0000000000000000000000000000000000010000);
    _delay(436727);
    Tester.repayWithATokens(
      115792089237316195423570985008687907853269901588890828691141347134601036824577,
      32
    );
    _delay(10674);
    Tester.setReserveBorrowing(true, 152);
    _delay(386819);
    Tester.setUnbackedMintCap(1, 42);
    _delay(2256055);
    _delay(10398);
    Tester.repayWithATokens(
      115792089237316195423570985008687907853269984665640564039457584007913129639785,
      56
    );
    _delay(490449);
    _delay(4500);
    Tester.repay(2109560130, 100, 15);
    _delay(842143);
    _delay(3867);
    Tester.approve(
      115792089237316195423570985008687907853269984665640564039457584007910102077141,
      251,
      156
    );
    _delay(27813);
    Tester.setPoolPause(true, 160814742);
    _delay(266142);
    _delay(412373);
    Tester.repayWithATokens(3467609, 46);
    _delay(349612);
    _delay(183799);
    Tester.setReserveBorrowing(true, 204);
    _delay(243804);
    Tester.repay(1513845946, 115, 23);
    _delay(782350);
    _delay(520990);
    Tester.repay(
      77232386750745558581303905139564453166287326505119739309730359179889410133315,
      157,
      244
    );
    _delay(6802);
    _delay(546907);
    Tester.disableLiquidationGracePeriod(6);
    _delay(149663);
    Tester.repay(
      67359618506568000212646106642539893122243724545192200452839073930112048359477,
      17,
      170
    );
    _delay(253494);
    Tester.setSiloedBorrowing(true, 0);
    _delay(542442);
    Tester.increaseAllowance(
      115012468444674537867220117441548077362522847310802063480314356408727965612211,
      59,
      2
    );
    _delay(1108106);
    _delay(71687);
    Tester.repay(
      39132476607653690839561857087648235157409873820928650868326386624556317152240,
      252,
      154
    );
    _delay(28290);
    Tester.liquidationCall(
      5905935794222959591038105642016884250145820458264270399654189534678713257883,
      true,
      211,
      128,
      3,
      4
    );
    _delay(321974);
    Tester.setUserUseReserveAsCollateral(true, 20);
    _delay(305034);
    _delay(601432);
    Tester.mintToTreasury(83);
    _setUpActor(0x0000000000000000000000000000000000020000);
    _delay(9900);
    Tester.setLatestAnswer(676530758, 251);
    _setUpActor(0x0000000000000000000000000000000000010000);
    _delay(9900);
    Tester.liquidationCall(2467012554, true, 93, 230, 151, 4);
    _delay(66543);
    _delay(322184);
    Tester.setLatestAnswer(676530760, 211);
    _delay(237192);
    _delay(64407);
    Tester.liquidationCall(
      91352034832010926057001582751876410893860910903135406657784615168643518944325,
      false,
      66,
      212,
      254,
      1
    );
    _delay(601431);
    Tester.setReserveBorrowing(false, 16);
    _delay(314382);
    Tester.approve(
      115792089237316195423570985008687907853269984665640564039457584007913129639777,
      175,
      9
    );
    _setUpActor(0x0000000000000000000000000000000000020000);
    _delay(322231);
    Tester.mintToTreasury(157);
    _delay(1145178);
    _delay(136765);
    Tester.repayWithATokens(0, 17);
    _delay(2482132);
    _setUpActor(0x0000000000000000000000000000000000010000);
    _delay(390013);
    Tester.mintToTreasury(100);
    _delay(589541);
    Tester.repay(1513845946, 115, 23);
    _delay(501629);
    _delay(287315);
    Tester.setPoolPause(false, 47);
    _delay(11636);
    Tester.liquidationCall(
      91352034832010926057001582751876410893860910903135406657784615168643518944325,
      false,
      66,
      212,
      254,
      1
    );
  }

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
