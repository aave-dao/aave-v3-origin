// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {Errors} from '../../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {TestnetERC20} from '../../../src/contracts/mocks/testnet-helpers/TestnetERC20.sol';
import {ReserveConfiguration} from '../../../src/contracts/protocol/pool/PoolConfigurator.sol';
import {WadRayMath} from '../../../src/contracts/protocol/libraries/math/WadRayMath.sol';
import {FlashLoanLogic} from '../../../src/contracts/protocol/libraries/logic/FlashLoanLogic.sol';
import {BorrowLogic} from '../../../src/contracts/protocol/libraries/logic/BorrowLogic.sol';
import {PercentageMath} from '../../../src/contracts/protocol/libraries/math/PercentageMath.sol';
import {MockFlashLoanReceiver} from '../../../src/contracts/mocks/flashloan/MockFlashLoanReceiver.sol';
import {MockFlashLoanSimpleReceiver} from '../../../src/contracts/mocks/flashloan/MockSimpleFlashLoanReceiver.sol';
import {IPoolAddressesProvider} from '../../../src/contracts/interfaces/IPoolAddressesProvider.sol';
import {IPool} from '../../../src/contracts/interfaces/IPool.sol';
import {IReserveInterestRateStrategy} from '../../../src/contracts/interfaces/IReserveInterestRateStrategy.sol';
import {DataTypes} from '../../../src/contracts/protocol/libraries/types/DataTypes.sol';
import {IERC20} from '../../../src/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {MockFlashLoanATokenReceiver} from '../../mocks/MockFlashLoanATokenReceiver.sol';
import {MockFlashLoanBorrowInsideFlashLoan} from '../../mocks/MockFlashLoanBorrowInsideFlashLoan.sol';
import {TestnetProcedures, TestReserveConfig} from '../../utils/TestnetProcedures.sol';

contract PoolFlashLoansTests is TestnetProcedures {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using WadRayMath for uint256;
  using PercentageMath for uint256;

  MockFlashLoanReceiver internal mockFlashReceiver;
  MockFlashLoanSimpleReceiver internal mockFlashSimpleReceiver;

  function setUp() public {
    initTestEnvironment();

    vm.prank(carol);
    contracts.poolProxy.supply(tokenList.usdx, 50_000e6, carol, 0);
    vm.prank(carol);
    contracts.poolProxy.supply(tokenList.wbtc, 20e8, carol, 0);

    mockFlashReceiver = new MockFlashLoanReceiver(
      IPoolAddressesProvider(report.poolAddressesProvider)
    );
    mockFlashSimpleReceiver = new MockFlashLoanSimpleReceiver(
      IPoolAddressesProvider(report.poolAddressesProvider)
    );
  }

  function test_reverts_flashLoan_invalid_return() public {
    (
      address[] memory assets,
      uint256[] memory amounts,
      uint256[] memory modes,
      bytes memory emptyParams
    ) = _defaultInput();

    mockFlashReceiver.setFailExecutionTransfer(true);
    mockFlashReceiver.setSimulateEOA(true);

    vm.expectRevert(abi.encodeWithSelector(Errors.InvalidFlashloanExecutorReturn.selector));

    vm.prank(alice);
    contracts.poolProxy.flashLoan(
      address(mockFlashReceiver),
      assets,
      amounts,
      modes,
      alice,
      emptyParams,
      0
    );
  }

  function test_reverts_flashLoan_reserve_not_flash_loan_enabled() public {
    (
      address[] memory assets,
      uint256[] memory amounts,
      uint256[] memory modes,
      bytes memory emptyParams
    ) = _defaultInput();

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveFlashLoaning(tokenList.usdx, false);

    vm.expectRevert(abi.encodeWithSelector(Errors.FlashloanDisabled.selector));

    vm.prank(alice);
    contracts.poolProxy.flashLoan(
      address(mockFlashReceiver),
      assets,
      amounts,
      modes,
      alice,
      emptyParams,
      0
    );
  }

  function test_reverts_flashLoan_reserve_paused() public {
    (
      address[] memory assets,
      uint256[] memory amounts,
      uint256[] memory modes,
      bytes memory emptyParams
    ) = _defaultInput();

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReservePause(tokenList.usdx, true, 0);

    vm.expectRevert(abi.encodeWithSelector(Errors.ReservePaused.selector));

    vm.prank(alice);
    contracts.poolProxy.flashLoan(
      address(mockFlashReceiver),
      assets,
      amounts,
      modes,
      alice,
      emptyParams,
      0
    );
  }

  function test_reverts_flashLoan_reserve_inactive() public {
    (
      address[] memory assets,
      uint256[] memory amounts,
      uint256[] memory modes,
      bytes memory emptyParams
    ) = _defaultInput();

    assets[0] = tokenList.weth;

    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setReserveActive(tokenList.weth, false);

    vm.expectRevert(abi.encodeWithSelector(Errors.ReserveInactive.selector));

    vm.prank(alice);
    contracts.poolProxy.flashLoan(
      address(mockFlashReceiver),
      assets,
      amounts,
      modes,
      alice,
      emptyParams,
      0
    );
  }

  function test_reverts_flashLoan_same_asset_more_then_once(uint8 length) public {
    vm.assume(length > 1);
    bytes memory emptyParams;
    address[] memory assets = new address[](length);
    uint256[] memory amounts = new uint256[](length);
    uint256[] memory modes = new uint256[](length);
    for (uint256 i = 0; i < length; i++) {
      assets[i] = tokenList.weth;
      amounts[i] = 1;
    }

    vm.expectRevert(abi.encodeWithSelector(Errors.InconsistentFlashloanParams.selector));
    vm.prank(alice);
    contracts.poolProxy.flashLoan(
      address(mockFlashReceiver),
      assets,
      amounts,
      modes,
      alice,
      emptyParams,
      0
    );
  }

  function test_reverts_flashLoan_simple_invalid_return() public {
    bytes memory emptyParams;

    mockFlashSimpleReceiver.setFailExecutionTransfer(true);
    mockFlashSimpleReceiver.setSimulateEOA(true);

    vm.expectRevert(abi.encodeWithSelector(Errors.InvalidFlashloanExecutorReturn.selector));

    vm.prank(alice);
    contracts.poolProxy.flashLoanSimple(
      address(mockFlashSimpleReceiver),
      tokenList.usdx,
      10e6,
      emptyParams,
      0
    );
  }

  function test_reverts_flashloans_eoa() public {
    (
      address[] memory assets,
      uint256[] memory amounts,
      uint256[] memory modes,
      bytes memory emptyParams
    ) = _defaultInput();

    vm.expectRevert();

    vm.prank(alice);
    contracts.poolProxy.flashLoan(alice, assets, amounts, modes, alice, emptyParams, 0);
  }

  function test_reverts_flashloan_transferred_funds() public {
    address aUSDX = contracts.poolProxy.getReserveAToken(tokenList.usdx);

    vm.startPrank(carol);
    contracts.poolProxy.withdraw(tokenList.usdx, 50_000e6, carol);
    usdx.transfer(aUSDX, 50_000e6);
    vm.stopPrank();

    assertEq(IERC20(aUSDX).totalSupply(), 0);

    (
      address[] memory assets,
      uint256[] memory amounts,
      uint256[] memory modes,
      bytes memory emptyParams
    ) = _defaultInput();

    vm.prank(alice);
    vm.expectRevert(abi.encodeWithSelector(Errors.InvalidAmount.selector));
    contracts.poolProxy.flashLoan(
      address(mockFlashSimpleReceiver),
      assets,
      amounts,
      modes,
      address(mockFlashSimpleReceiver),
      emptyParams,
      0
    );
  }

  function test_reverts_flashloan_simple_transferred_funds() public {
    address aUSDX = contracts.poolProxy.getReserveAToken(tokenList.usdx);

    vm.startPrank(carol);
    contracts.poolProxy.withdraw(tokenList.usdx, 50_000e6, carol);
    usdx.transfer(aUSDX, 50_000e6);
    vm.stopPrank();

    assertEq(IERC20(aUSDX).totalSupply(), 0);

    bytes memory emptyParams;

    vm.prank(alice);
    vm.expectRevert(abi.encodeWithSelector(Errors.InvalidAmount.selector));
    contracts.poolProxy.flashLoanSimple(
      address(mockFlashSimpleReceiver),
      tokenList.usdx,
      10e6,
      emptyParams,
      0
    );
  }

  function test_reverts_supply_flashloan_transfer_withdraw() public {
    address aUSDX = contracts.poolProxy.getReserveAToken(tokenList.usdx);

    vm.startPrank(carol);
    contracts.poolProxy.withdraw(tokenList.usdx, 50_000e6, carol);
    usdx.transfer(aUSDX, 50_000e6);
    vm.stopPrank();

    assertEq(IERC20(aUSDX).totalSupply(), 0);

    // Deploy the custom receiver
    MockFlashLoanATokenReceiver newMockReceiver = new MockFlashLoanATokenReceiver(
      IPoolAddressesProvider(report.poolAddressesProvider),
      aUSDX
    );

    // Now, supply on behalf of the flashloan receiver
    vm.prank(carol);
    contracts.poolProxy.supply(tokenList.usdx, 12e6, address(newMockReceiver), 0);

    (
      address[] memory assets,
      uint256[] memory amounts,
      uint256[] memory modes,
      bytes memory emptyParams
    ) = _defaultInput();

    vm.expectRevert(stdError.arithmeticError);
    contracts.poolProxy.flashLoan(
      address(newMockReceiver),
      assets,
      amounts,
      modes,
      address(newMockReceiver),
      emptyParams,
      0
    );
  }

  function test_reverts_supply_flashloan_simple_transfer_withdraw() public {
    address aUSDX = contracts.poolProxy.getReserveAToken(tokenList.usdx);

    vm.startPrank(carol);
    contracts.poolProxy.withdraw(tokenList.usdx, 50_000e6, carol);
    usdx.transfer(aUSDX, 50_000e6);
    vm.stopPrank();

    assertEq(IERC20(aUSDX).totalSupply(), 0);

    // Deploy the custom receiver
    MockFlashLoanATokenReceiver newMockReceiver = new MockFlashLoanATokenReceiver(
      IPoolAddressesProvider(report.poolAddressesProvider),
      aUSDX
    );

    // Now, supply on behalf of the flashloan receiver
    vm.prank(carol);
    contracts.poolProxy.supply(tokenList.usdx, 10e6, address(newMockReceiver), 0);

    bytes memory emptyParams;

    vm.expectRevert(stdError.arithmeticError);
    contracts.poolProxy.flashLoanSimple(
      address(newMockReceiver),
      tokenList.usdx,
      10e6,
      emptyParams,
      0
    );
  }

  function test_flashloan_simple() public {
    uint256 virtualUnderlyingBalanceBefore = contracts.poolProxy.getVirtualUnderlyingBalance(
      tokenList.usdx
    );
    uint256 totalFee = contracts.poolProxy.FLASHLOAN_PREMIUM_TOTAL();
    uint256 amount = 10e6;

    vm.prank(poolAdmin);
    TestnetERC20(tokenList.usdx).transferOwnership(address(mockFlashSimpleReceiver));

    vm.prank(alice);
    contracts.poolProxy.flashLoanSimple(
      address(mockFlashSimpleReceiver),
      tokenList.usdx,
      amount,
      '0x',
      0
    );

    uint256 virtualUnderlyingBalanceAfter = contracts.poolProxy.getVirtualUnderlyingBalance(
      tokenList.usdx
    );
    assertEq(
      virtualUnderlyingBalanceBefore + (amount * totalFee) / 1e4,
      virtualUnderlyingBalanceAfter
    );
  }

  function test_flashloan_simple_rounding_premium() public {
    vm.prank(poolAdmin);
    TestnetERC20(tokenList.usdx).transferOwnership(address(mockFlashSimpleReceiver));

    vm.expectEmit(address(contracts.poolProxy));
    emit IPool.FlashLoan(
      address(mockFlashSimpleReceiver),
      alice,
      tokenList.usdx,
      1,
      DataTypes.InterestRateMode(0),
      1, // should be 1 although
      0
    );

    vm.prank(alice);
    contracts.poolProxy.flashLoanSimple(
      address(mockFlashSimpleReceiver),
      tokenList.usdx,
      1,
      '0x',
      0
    );
  }

  function test_flashloan_rounding_premium() public {
    vm.prank(poolAdmin);
    TestnetERC20(tokenList.usdx).transferOwnership(address(mockFlashReceiver));

    address[] memory assets = new address[](1);
    uint256[] memory amounts = new uint256[](1);
    uint256[] memory modes = new uint256[](1);

    assets[0] = tokenList.usdx;
    amounts[0] = 1;
    modes[0] = 0;

    vm.expectEmit(address(contracts.poolProxy));
    emit IPool.FlashLoan(
      address(mockFlashReceiver),
      alice,
      tokenList.usdx,
      1,
      DataTypes.InterestRateMode(0),
      1, // should be 1 although
      0
    );

    vm.prank(alice);
    contracts.poolProxy.flashLoan(
      address(mockFlashReceiver),
      assets,
      amounts,
      modes,
      alice,
      '0x',
      0
    );
  }

  function test_flashloan_rounding_accruedToTreasury() public {
    vm.prank(poolAdmin);
    TestnetERC20(tokenList.usdx).transferOwnership(address(mockFlashReceiver));

    // increase liquidity index

    vm.startPrank(alice);

    uint256 supplyAmount = 50_000e6;

    contracts.poolProxy.supply({
      asset: tokenList.usdx,
      amount: supplyAmount,
      onBehalfOf: alice,
      referralCode: 0
    });

    contracts.poolProxy.borrow({
      asset: tokenList.usdx,
      amount: supplyAmount / 5,
      interestRateMode: 2,
      referralCode: 0,
      onBehalfOf: alice
    });

    vm.warp(block.timestamp + 4500000 days);

    contracts.poolProxy.repay({
      asset: tokenList.usdx,
      amount: supplyAmount / 5,
      interestRateMode: 2,
      onBehalfOf: alice
    });

    vm.stopPrank();

    // check liquidity index

    DataTypes.ReserveDataLegacy memory reserveData = contracts.poolProxy.getReserveData(
      tokenList.usdx
    );
    assertNotEq(reserveData.liquidityIndex, 1e27);
    assertGt(reserveData.liquidityIndex, 10e27);
    assertLt(reserveData.liquidityIndex, 11e27);

    // accruedToTreasury += 18.rayDivFloor(10e27) = 18 * 1e27 / 10e27 = 1.8
    // accruedToTreasury += 18.rayDivFloor(10e27) = 18 * 1e27 / 10e27 = 1.63636363636

    uint256 flashLoanFeeAmount = 18;
    uint256 flashLoanFeePercentageTotal = contracts.poolProxy.FLASHLOAN_PREMIUM_TOTAL();
    uint256 flashLoanAmount = (flashLoanFeeAmount * 100_00) / flashLoanFeePercentageTotal;

    address[] memory assets = new address[](1);
    uint256[] memory amounts = new uint256[](1);
    uint256[] memory modes = new uint256[](1);

    assets[0] = tokenList.usdx;
    amounts[0] = flashLoanAmount;
    modes[0] = 0;

    vm.prank(alice);
    contracts.poolProxy.flashLoan(address(mockFlashReceiver), assets, amounts, modes, alice, '', 0);

    uint256 oldAccruedToTreasury = reserveData.accruedToTreasury;
    reserveData = contracts.poolProxy.getReserveData(tokenList.usdx);
    assertEq(reserveData.accruedToTreasury, oldAccruedToTreasury + 1);
  }

  function test_flashloan_simple_rounding_accruedToTreasury() public {
    vm.prank(poolAdmin);
    TestnetERC20(tokenList.usdx).transferOwnership(address(mockFlashSimpleReceiver));

    // increase liquidity index

    vm.startPrank(alice);

    uint256 supplyAmount = 50_000e6;

    contracts.poolProxy.supply({
      asset: tokenList.usdx,
      amount: supplyAmount,
      onBehalfOf: alice,
      referralCode: 0
    });

    contracts.poolProxy.borrow({
      asset: tokenList.usdx,
      amount: supplyAmount / 5,
      interestRateMode: 2,
      referralCode: 0,
      onBehalfOf: alice
    });

    vm.warp(block.timestamp + 4500000 days);

    contracts.poolProxy.repay({
      asset: tokenList.usdx,
      amount: supplyAmount / 5,
      interestRateMode: 2,
      onBehalfOf: alice
    });

    vm.stopPrank();

    // check liquidity index

    DataTypes.ReserveDataLegacy memory reserveData = contracts.poolProxy.getReserveData(
      tokenList.usdx
    );
    assertNotEq(reserveData.liquidityIndex, 1e27);
    assertGt(reserveData.liquidityIndex, 10e27);
    assertLt(reserveData.liquidityIndex, 11e27);

    // accruedToTreasury += 18.rayDivFloor(10e27) = 18 * 1e27 / 10e27 = 1.8
    // accruedToTreasury += 18.rayDivFloor(10e27) = 18 * 1e27 / 10e27 = 1.63636363636

    uint256 flashLoanFeeAmount = 18;
    uint256 flashLoanFeePercentageTotal = contracts.poolProxy.FLASHLOAN_PREMIUM_TOTAL();
    uint256 flashLoanAmount = (flashLoanFeeAmount * 100_00) / flashLoanFeePercentageTotal;

    vm.prank(alice);
    contracts.poolProxy.flashLoanSimple({
      receiverAddress: address(mockFlashSimpleReceiver),
      asset: tokenList.usdx,
      amount: flashLoanAmount,
      params: '',
      referralCode: 0
    });

    uint256 oldAccruedToTreasury = reserveData.accruedToTreasury;
    reserveData = contracts.poolProxy.getReserveData(tokenList.usdx);
    assertEq(reserveData.accruedToTreasury, oldAccruedToTreasury + 1);
  }

  function test_flashloan_simple_2() public {
    uint256 virtualUnderlyingBalanceBefore = contracts.poolProxy.getVirtualUnderlyingBalance(
      tokenList.usdx
    );

    vm.prank(poolAdmin);
    TestnetERC20(tokenList.wbtc).transferOwnership(address(mockFlashSimpleReceiver));

    vm.prank(alice);
    contracts.poolProxy.flashLoanSimple(
      address(mockFlashSimpleReceiver),
      tokenList.wbtc,
      3e8,
      '0x',
      0
    );

    uint256 virtualUnderlyingBalanceAfter = contracts.poolProxy.getVirtualUnderlyingBalance(
      tokenList.usdx
    );
    assertEq(virtualUnderlyingBalanceBefore, virtualUnderlyingBalanceAfter);
  }

  function test_flashloan() public {
    (
      address[] memory assets,
      uint256[] memory amounts,
      uint256[] memory modes,
      bytes memory emptyParams
    ) = _defaultInput(true, 0);

    uint256 virtualUnderlyingBalanceBefore = contracts.poolProxy.getVirtualUnderlyingBalance(
      assets[0]
    );
    uint256 totalFee = contracts.poolProxy.FLASHLOAN_PREMIUM_TOTAL();

    vm.prank(alice);
    contracts.poolProxy.flashLoan(
      address(mockFlashReceiver),
      assets,
      amounts,
      modes,
      alice,
      emptyParams,
      0
    );

    uint256 virtualUnderlyingBalanceAfter = contracts.poolProxy.getVirtualUnderlyingBalance(
      assets[0]
    );
    assertEq(
      virtualUnderlyingBalanceBefore + (amounts[0] * totalFee) / 1e4,
      virtualUnderlyingBalanceAfter
    );
  }

  function test_flashloan_multiple() public {
    (
      address[] memory assets,
      uint256[] memory amounts,
      uint256[] memory modes,
      bytes memory emptyParams
    ) = _defaultMultipleInput(true);

    uint256 virtualUnderlyingBalanceBefore0 = contracts.poolProxy.getVirtualUnderlyingBalance(
      assets[0]
    );
    uint256 virtualUnderlyingBalanceBefore1 = contracts.poolProxy.getVirtualUnderlyingBalance(
      assets[1]
    );
    uint256 totalFee = contracts.poolProxy.FLASHLOAN_PREMIUM_TOTAL();

    vm.prank(alice);
    contracts.poolProxy.flashLoan(
      address(mockFlashReceiver),
      assets,
      amounts,
      modes,
      alice,
      emptyParams,
      0
    );

    uint256 virtualUnderlyingBalanceAfter0 = contracts.poolProxy.getVirtualUnderlyingBalance(
      assets[0]
    );
    uint256 virtualUnderlyingBalanceAfter1 = contracts.poolProxy.getVirtualUnderlyingBalance(
      assets[1]
    );

    assertEq(
      virtualUnderlyingBalanceBefore0 + (amounts[0] * totalFee) / 1e4,
      virtualUnderlyingBalanceAfter0
    );
    assertEq(
      virtualUnderlyingBalanceBefore1 + (amounts[1] * totalFee) / 1e4,
      virtualUnderlyingBalanceAfter1
    );
  }

  function test_flashloan_borrow() public {
    vm.prank(alice);
    contracts.poolProxy.supply(tokenList.wbtc, 0.5e8, alice, 0);

    (
      address[] memory assets,
      uint256[] memory amounts,
      uint256[] memory modes,
      bytes memory emptyParams
    ) = _defaultInput(true, 2);

    vm.prank(alice);
    contracts.poolProxy.flashLoan(
      address(mockFlashReceiver),
      assets,
      amounts,
      modes,
      alice,
      emptyParams,
      0
    );
  }

  function test_flashloan_simple_borrow_inside_flashloan_and_check_rate_after() public {
    MockFlashLoanBorrowInsideFlashLoan receiver = new MockFlashLoanBorrowInsideFlashLoan(
      contracts.poolAddressesProvider
    );

    address asset = tokenList.usdx;
    uint256 underlyingBalance = contracts.poolProxy.getVirtualUnderlyingBalance(asset);

    vm.startPrank(carol);
    contracts.poolProxy.borrow({
      asset: asset,
      amount: underlyingBalance / 5,
      interestRateMode: 2,
      referralCode: 0,
      onBehalfOf: carol
    });
    IERC20(contracts.poolProxy.getReserveAToken(asset)).transfer(
      address(receiver),
      underlyingBalance / 2
    );
    vm.stopPrank();

    underlyingBalance = contracts.poolProxy.getVirtualUnderlyingBalance(asset);
    uint256 amount = (underlyingBalance * 9) / 10;

    deal(asset, address(receiver), amount * 2);

    DataTypes.ReserveDataLegacy memory reserveData = contracts.poolProxy.getReserveData(asset);
    assertGt(reserveData.currentLiquidityRate, 0);
    assertGt(reserveData.currentVariableBorrowRate, 0);

    contracts.poolProxy.flashLoanSimple({
      receiverAddress: address(receiver),
      asset: asset,
      amount: amount,
      params: '',
      referralCode: 0
    });

    _checkInterestRates(asset);
  }

  function test_flashloan_borrow_inside_flashloan_and_check_rate_after() public {
    MockFlashLoanBorrowInsideFlashLoan receiver = new MockFlashLoanBorrowInsideFlashLoan(
      contracts.poolAddressesProvider
    );

    address[] memory assets = new address[](2);
    uint256[] memory underlyingBalances = new uint256[](2);
    uint256[] memory amounts = new uint256[](2);
    uint256[] memory interestRateModes = new uint256[](2);

    assets[0] = tokenList.usdx;
    assets[1] = tokenList.wbtc;

    interestRateModes[0] = 0;
    interestRateModes[1] = 0;

    for (uint256 i = 0; i < assets.length; ++i) {
      underlyingBalances[i] = contracts.poolProxy.getVirtualUnderlyingBalance(assets[i]);

      vm.startPrank(carol);
      contracts.poolProxy.borrow({
        asset: assets[i],
        amount: underlyingBalances[i] / 5,
        interestRateMode: 2,
        referralCode: 0,
        onBehalfOf: carol
      });

      IERC20(contracts.poolProxy.getReserveAToken(assets[i])).transfer(
        address(receiver),
        underlyingBalances[i] / 2
      );
      vm.stopPrank();

      underlyingBalances[i] = contracts.poolProxy.getVirtualUnderlyingBalance(assets[i]);

      amounts[i] = (underlyingBalances[i] * 9) / 10;

      deal(assets[i], address(receiver), amounts[i] * 2);

      DataTypes.ReserveDataLegacy memory reserveData = contracts.poolProxy.getReserveData(
        assets[i]
      );

      assertGt(reserveData.currentLiquidityRate, 0);
      assertGt(reserveData.currentVariableBorrowRate, 0);
    }

    contracts.poolProxy.flashLoan({
      receiverAddress: address(receiver),
      assets: assets,
      amounts: amounts,
      interestRateModes: interestRateModes,
      onBehalfOf: address(receiver),
      params: '',
      referralCode: 0
    });

    for (uint256 i = 0; i < assets.length; ++i) {
      _checkInterestRates(assets[i]);
    }
  }

  function test_revert_flashloan_borrow_stable() public {
    (
      address[] memory assets,
      uint256[] memory amounts,
      uint256[] memory modes,
      bytes memory emptyParams
    ) = _defaultInput(false, 1);

    vm.prank(alice);
    vm.expectRevert(abi.encodeWithSelector(Errors.InvalidInterestRateModeSelected.selector));
    contracts.poolProxy.flashLoan(
      address(mockFlashReceiver),
      assets,
      amounts,
      modes,
      alice,
      emptyParams,
      0
    );
  }

  function _defaultInput()
    internal
    returns (address[] memory, uint256[] memory, uint256[] memory, bytes memory)
  {
    return _defaultInput(false, 0);
  }

  function _defaultInput(
    bool checkEvents,
    uint256 mode
  ) internal returns (address[] memory, uint256[] memory, uint256[] memory, bytes memory) {
    address[] memory assets = new address[](1);
    uint256[] memory amounts = new uint256[](1);
    uint256[] memory modes = new uint256[](1);
    bytes memory emptyParams;

    assets[0] = tokenList.usdx;
    amounts[0] = 12e6;
    modes[0] = mode;
    for (uint8 x; x < assets.length; x++) {
      vm.prank(poolAdmin);
      TestnetERC20(assets[x]).transferOwnership(address(mockFlashReceiver));
    }

    if (checkEvents) {
      _checkFlashLoanEvents(assets, amounts, modes);
    }
    return (assets, amounts, modes, emptyParams);
  }

  function _defaultMultipleInput(
    bool checkEvents
  ) internal returns (address[] memory, uint256[] memory, uint256[] memory, bytes memory) {
    address[] memory assets = new address[](2);
    uint256[] memory amounts = new uint256[](2);
    uint256[] memory modes = new uint256[](2);
    bytes memory emptyParams;

    assets[0] = tokenList.usdx;
    assets[1] = tokenList.wbtc;
    amounts[0] = 12.93e6;
    amounts[0] = 2e8;
    modes[0] = 0;
    modes[1] = 0;

    if (checkEvents) {
      for (uint8 x; x < assets.length; x++) {
        vm.prank(poolAdmin);
        TestnetERC20(assets[x]).transferOwnership(address(mockFlashReceiver));
      }

      _checkFlashLoanEvents(assets, amounts, modes);
    }

    return (assets, amounts, modes, emptyParams);
  }

  function _checkFlashLoanEvents(
    address[] memory assets,
    uint256[] memory amounts,
    uint256[] memory modes
  ) internal {
    uint256 totalFee = contracts.poolProxy.FLASHLOAN_PREMIUM_TOTAL();

    for (uint8 x; x < assets.length; x++) {
      if (modes[x] > 0) {
        vm.expectEmit(address(contracts.poolProxy));
        emit IPool.Borrow(
          assets[x],
          alice,
          alice,
          amounts[x],
          DataTypes.InterestRateMode(modes[x]),
          _calculateInterestRates(amounts[x], assets[x]),
          0
        );
      }
      vm.expectEmit(address(contracts.poolProxy));
      emit IPool.FlashLoan(
        address(mockFlashReceiver),
        alice,
        assets[x],
        amounts[x],
        DataTypes.InterestRateMode(modes[x]),
        modes[x] > 0 ? 0 : amounts[x].percentMulCeil(totalFee),
        0
      );
    }
  }
}
