// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {ICreditDelegationToken} from '../../src/contracts/interfaces/ICreditDelegationToken.sol';
import {Errors} from '../../src/contracts/protocol/libraries/helpers/Errors.sol';
import {UserConfiguration} from '../../src/contracts/protocol/libraries/configuration/UserConfiguration.sol';
import {MockFlashLoanReceiverWithoutMint} from '../../src/contracts/mocks/flashloan/MockFlashLoanReceiverWithoutMint.sol';
import {MockSimpleFlashLoanReceiverWithoutMint} from '../../src/contracts/mocks/flashloan/MockSimpleFlashLoanReceiverWithoutMint.sol';
import {Testhelpers, IERC20} from './Testhelpers.sol';

/**
 * Scenario suite for common operations supply/borrow/repay/withdraw/liquidationCall.
 */
/// forge-config: default.isolate = true
contract PoolOperations_gas_Tests is Testhelpers {
  address supplier = makeAddr('supplier');
  address borrower = makeAddr('borrower');
  address liquidator = makeAddr('liquidator');

  function test_supply() external {
    // borrow some, so hf checks are not skipped
    _supplyOnReserve(supplier, 1 ether, tokenList.weth);
    _borrowArbitraryAmount(supplier, 1e5, tokenList.wbtc);

    _supplyOnReserve(supplier, 100e6, tokenList.usdx);
    vm.snapshotGasLastCall('Pool.Operations', 'supply: first supply->collateralEnabled');

    _skip(100);

    _supplyOnReserve(supplier, 100e6, tokenList.usdx);
    vm.snapshotGasLastCall('Pool.Operations', 'supply: collateralEnabled');
    vm.prank(supplier);
    contracts.poolProxy.setUserUseReserveAsCollateral(tokenList.usdx, false);

    _skip(100);

    _supplyOnReserve(supplier, 100e6, tokenList.usdx);
    vm.snapshotGasLastCall('Pool.Operations', 'supply: collateralDisabled');
  }

  function test_withdraw() external {
    _supplyOnReserve(supplier, 100e6, tokenList.usdx);
    vm.startPrank(supplier);
    _skip(100);

    contracts.poolProxy.withdraw(tokenList.usdx, 50e6, supplier);
    vm.snapshotGasLastCall('Pool.Operations', 'withdraw: partial withdraw');

    _skip(100);

    contracts.poolProxy.withdraw(tokenList.usdx, type(uint256).max, supplier);
    vm.snapshotGasLastCall('Pool.Operations', 'withdraw: full withdraw');
  }

  function test_withdraw_with_active_borrows() external {
    _supplyOnReserve(borrower, 100 ether, tokenList.weth);
    uint256 amountToBorrow = 1000e6;
    vm.startPrank(borrower);
    contracts.poolProxy.borrow(tokenList.usdx, amountToBorrow, 2, 0, borrower);
    _skip(100);

    contracts.poolProxy.withdraw(tokenList.weth, 1 ether, supplier);
    vm.snapshotGasLastCall('Pool.Operations', 'withdraw: partial withdraw with active borrows');
  }

  function test_borrow() external {
    _supplyOnReserve(borrower, 100 ether, tokenList.weth);
    uint256 amountToBorrow = 1000e6;
    vm.startPrank(borrower);
    contracts.poolProxy.borrow(tokenList.usdx, amountToBorrow, 2, 0, borrower);
    vm.snapshotGasLastCall('Pool.Operations', 'borrow: first borrow->borrowingEnabled');

    _skip(100);

    contracts.poolProxy.borrow(tokenList.usdx, amountToBorrow, 2, 0, borrower);
    vm.snapshotGasLastCall('Pool.Operations', 'borrow: recurrent borrow');
  }

  function test_borrow_onBehalfOf() external {
    _supplyOnReserve(borrower, 100 ether, tokenList.weth);
    uint256 amountToBorrow = 1000e6;
    vm.startPrank(borrower);
    ICreditDelegationToken(contracts.poolProxy.getReserveVariableDebtToken(tokenList.usdx))
      .approveDelegation({delegatee: supplier, amount: amountToBorrow * 2});

    vm.startPrank(supplier);
    contracts.poolProxy.borrow(tokenList.usdx, amountToBorrow, 2, 0, borrower);
    vm.snapshotGasLastCall('Pool.Operations', 'borrow: first borrow->borrowingEnabled; onBehalfOf');

    _skip(100);

    // -1 because the first borrow might have consumed one more allowance than expected due to rounding
    contracts.poolProxy.borrow(tokenList.usdx, amountToBorrow - 1, 2, 0, borrower);
    vm.snapshotGasLastCall('Pool.Operations', 'borrow: recurrent borrow; onBehalfOf');
  }

  function test_repay() external {
    _supplyOnReserve(borrower, 100 ether, tokenList.weth);
    uint256 amountToBorrow = 1000e6;
    deal(tokenList.usdx, borrower, amountToBorrow);
    vm.startPrank(borrower);
    contracts.poolProxy.borrow(tokenList.usdx, amountToBorrow, 2, 0, borrower);
    IERC20(tokenList.usdx).approve(report.poolProxy, type(uint256).max);

    _skip(100);

    contracts.poolProxy.repay(tokenList.usdx, amountToBorrow / 2, 2, borrower);
    vm.snapshotGasLastCall('Pool.Operations', 'repay: partial repay');

    _skip(100);

    contracts.poolProxy.repay(tokenList.usdx, type(uint256).max, 2, borrower);
    vm.snapshotGasLastCall('Pool.Operations', 'repay: full repay');
  }

  function test_repay_with_ATokens() external {
    _supplyOnReserve(borrower, 1_000_000e6, tokenList.usdx);
    uint256 amountToBorrow = 1000e6;
    deal(tokenList.usdx, borrower, amountToBorrow);
    vm.startPrank(borrower);
    contracts.poolProxy.borrow(tokenList.usdx, amountToBorrow, 2, 0, borrower);
    IERC20(tokenList.usdx).approve(report.poolProxy, type(uint256).max);

    _skip(100);

    contracts.poolProxy.repayWithATokens(tokenList.usdx, amountToBorrow / 2, 2);
    vm.snapshotGasLastCall('Pool.Operations', 'repay: partial repay with ATokens');

    _skip(100);

    contracts.poolProxy.repayWithATokens(tokenList.usdx, type(uint256).max, 2);
    vm.snapshotGasLastCall('Pool.Operations', 'repay: full repay with ATokens');
  }

  function test_liquidationCall_partial() external {
    // on v3.3 the amounts need to be adjusted to not cause error 103 (min leftover) issues
    uint256 scalingFactor = 10;
    uint256 price = contracts.aaveOracle.getAssetPrice(tokenList.weth);
    _supplyOnReserve(
      borrower,
      ((((price * 1e6) / 1e8) * 90) / 100) * scalingFactor,
      tokenList.usdx
    );
    _borrowArbitraryAmount(borrower, 1 ether * scalingFactor, tokenList.weth);
    deal(tokenList.weth, liquidator, 0.5 ether);
    vm.startPrank(liquidator);
    IERC20(tokenList.weth).approve(report.poolProxy, 0.5 ether);

    _skip(100);

    contracts.poolProxy.liquidationCall(tokenList.usdx, tokenList.weth, borrower, 0.5 ether, false);
    vm.snapshotGasLastCall('Pool.Operations', 'liquidationCall: partial liquidation');
  }

  function test_liquidationCall_full() external {
    uint256 price = contracts.aaveOracle.getAssetPrice(tokenList.weth);
    _supplyOnReserve(borrower, (((price * 1e6) / 1e8) * 90) / 100, tokenList.usdx);
    _borrowArbitraryAmount(borrower, 1 ether, tokenList.weth);
    deal(tokenList.weth, liquidator, 2 ether);
    vm.startPrank(liquidator);
    IERC20(tokenList.weth).approve(report.poolProxy, type(uint256).max);

    _skip(100);

    contracts.poolProxy.liquidationCall(
      tokenList.usdx,
      tokenList.weth,
      borrower,
      type(uint256).max,
      false
    );
    vm.snapshotGasLastCall('Pool.Operations', 'liquidationCall: full liquidation');
  }

  function test_liquidationCall_receive_ATokens_partial() external {
    uint256 price = contracts.aaveOracle.getAssetPrice(tokenList.weth);
    _supplyOnReserve(borrower, (((price * 3e6) / 1e8) * 90) / 100, tokenList.usdx);
    _borrowArbitraryAmount(borrower, 3 ether, tokenList.weth);
    deal(tokenList.weth, liquidator, 0.5 ether);
    vm.startPrank(liquidator);
    IERC20(tokenList.weth).approve(report.poolProxy, 0.5 ether);

    _skip(100);

    contracts.poolProxy.liquidationCall(tokenList.usdx, tokenList.weth, borrower, 0.5 ether, true);
    vm.snapshotGasLastCall(
      'Pool.Operations',
      'liquidationCall: partial liquidation and receive ATokens'
    );
  }

  function test_liquidationCall_receive_ATokens_full() external {
    uint256 price = contracts.aaveOracle.getAssetPrice(tokenList.weth);
    _supplyOnReserve(borrower, (((price * 1e6) / 1e8) * 90) / 100, tokenList.usdx);
    _borrowArbitraryAmount(borrower, 1 ether, tokenList.weth);
    deal(tokenList.weth, liquidator, 2 ether);
    vm.startPrank(liquidator);
    IERC20(tokenList.weth).approve(report.poolProxy, type(uint256).max);

    _skip(100);

    contracts.poolProxy.liquidationCall(
      tokenList.usdx,
      tokenList.weth,
      borrower,
      type(uint256).max,
      true
    );
    vm.snapshotGasLastCall(
      'Pool.Operations',
      'liquidationCall: full liquidation and receive ATokens'
    );
  }

  function test_liquidationCall_deficit() external {
    uint256 price = contracts.aaveOracle.getAssetPrice(tokenList.weth);
    _supplyOnReserve(borrower, (price * 1e6) / 1e8, tokenList.usdx);
    _borrowArbitraryAmount(borrower, 1 ether, tokenList.weth);
    deal(tokenList.weth, liquidator, 2 ether);
    vm.startPrank(liquidator);
    IERC20(tokenList.weth).approve(report.poolProxy, type(uint256).max);

    _skip(100);

    contracts.poolProxy.liquidationCall(
      tokenList.usdx,
      tokenList.weth,
      borrower,
      type(uint256).max,
      false
    );
    vm.snapshotGasLastCall('Pool.Operations', 'liquidationCall: deficit on liquidated asset');
  }

  function test_liquidationCall_deficitInAdditionalReserve() external {
    uint256 price = contracts.aaveOracle.getAssetPrice(tokenList.weth);
    _supplyOnReserve(borrower, (price * 1e6) / 1e8, tokenList.usdx);
    _borrowArbitraryAmount(borrower, 1e5, tokenList.wbtc); // additional deficit
    _borrowArbitraryAmount(borrower, 1 ether, tokenList.weth);
    deal(tokenList.weth, liquidator, 2 ether);
    vm.startPrank(liquidator);
    IERC20(tokenList.weth).approve(report.poolProxy, type(uint256).max);

    _skip(100);

    contracts.poolProxy.liquidationCall(
      tokenList.usdx,
      tokenList.weth,
      borrower,
      type(uint256).max,
      false
    );
    vm.snapshotGasLastCall(
      'Pool.Operations',
      'liquidationCall: deficit on liquidated asset + other asset'
    );
  }

  function test_flashLoan_with_one_asset() external {
    uint256 flashLoanAmount = 10 ether;
    uint256 flashLoanFee = (flashLoanAmount * contracts.poolProxy.FLASHLOAN_PREMIUM_TOTAL()) /
      100_00;

    MockFlashLoanReceiverWithoutMint flashLoanReceiver = new MockFlashLoanReceiverWithoutMint(
      contracts.poolAddressesProvider
    );

    deal(tokenList.weth, address(flashLoanReceiver), flashLoanFee);

    address[] memory assets = new address[](1);
    assets[0] = tokenList.weth;

    uint256[] memory amounts = new uint256[](1);
    amounts[0] = flashLoanAmount;

    uint256[] memory interestRateModes = new uint256[](1);
    interestRateModes[0] = 0;

    contracts.poolProxy.flashLoan({
      receiverAddress: address(flashLoanReceiver),
      assets: assets,
      amounts: amounts,
      interestRateModes: interestRateModes,
      onBehalfOf: address(flashLoanReceiver),
      params: '0x',
      referralCode: 0
    });
    vm.snapshotGasLastCall('Pool.Operations', 'flashLoan: flash loan for one asset');
  }

  function test_flashLoan_with_two_assets() external {
    uint256 flashLoanAmountWeth = 8 ether;
    uint256 flashLoanAmountWbtc = 3 * 1e8;

    uint256 flashLoanFeeWeth = (flashLoanAmountWeth *
      contracts.poolProxy.FLASHLOAN_PREMIUM_TOTAL()) / 100_00;
    uint256 flashLoanFeeWbtc = (flashLoanAmountWbtc *
      contracts.poolProxy.FLASHLOAN_PREMIUM_TOTAL()) / 100_00;

    MockFlashLoanReceiverWithoutMint flashLoanReceiver = new MockFlashLoanReceiverWithoutMint(
      contracts.poolAddressesProvider
    );

    deal(tokenList.weth, address(flashLoanReceiver), flashLoanFeeWeth);
    deal(tokenList.wbtc, address(flashLoanReceiver), flashLoanFeeWbtc);

    address[] memory assets = new address[](2);
    assets[0] = tokenList.weth;
    assets[1] = tokenList.wbtc;

    uint256[] memory amounts = new uint256[](2);
    amounts[0] = flashLoanAmountWeth;
    amounts[1] = flashLoanAmountWbtc;

    uint256[] memory interestRateModes = new uint256[](2);
    interestRateModes[0] = 0;
    interestRateModes[1] = 0;

    contracts.poolProxy.flashLoan({
      receiverAddress: address(flashLoanReceiver),
      assets: assets,
      amounts: amounts,
      interestRateModes: interestRateModes,
      onBehalfOf: address(flashLoanReceiver),
      params: '0x',
      referralCode: 0
    });
    vm.snapshotGasLastCall('Pool.Operations', 'flashLoan: flash loan for two assets');
  }

  function test_flashLoan_with_one_asset_with_borrowing() external {
    uint256 flashLoanAmount = 10 ether;
    uint256 flashLoanFee = (flashLoanAmount * contracts.poolProxy.FLASHLOAN_PREMIUM_TOTAL()) /
      100_00;

    MockFlashLoanReceiverWithoutMint flashLoanReceiver = new MockFlashLoanReceiverWithoutMint(
      contracts.poolAddressesProvider
    );

    _supplyOnReserve(address(flashLoanReceiver), flashLoanAmount * 5, tokenList.weth);

    deal(tokenList.weth, address(flashLoanReceiver), flashLoanFee);

    address[] memory assets = new address[](1);
    assets[0] = tokenList.weth;

    uint256[] memory amounts = new uint256[](1);
    amounts[0] = flashLoanAmount;

    uint256[] memory interestRateModes = new uint256[](1);
    interestRateModes[0] = 2;

    vm.prank(address(flashLoanReceiver));
    contracts.poolProxy.flashLoan({
      receiverAddress: address(flashLoanReceiver),
      assets: assets,
      amounts: amounts,
      interestRateModes: interestRateModes,
      onBehalfOf: address(flashLoanReceiver),
      params: '0x',
      referralCode: 0
    });
    vm.snapshotGasLastCall('Pool.Operations', 'flashLoan: flash loan for one asset and borrow');
  }

  function test_flashLoan_with_two_assets_with_borrowing() external {
    uint256 flashLoanAmountWeth = 8 ether;
    uint256 flashLoanAmountWbtc = 3 * 1e8;

    uint256 flashLoanFeeWeth = (flashLoanAmountWeth *
      contracts.poolProxy.FLASHLOAN_PREMIUM_TOTAL()) / 100_00;
    uint256 flashLoanFeeWbtc = (flashLoanAmountWbtc *
      contracts.poolProxy.FLASHLOAN_PREMIUM_TOTAL()) / 100_00;

    MockFlashLoanReceiverWithoutMint flashLoanReceiver = new MockFlashLoanReceiverWithoutMint(
      contracts.poolAddressesProvider
    );

    _supplyOnReserve(address(flashLoanReceiver), flashLoanAmountWeth * 5, tokenList.weth);
    _supplyOnReserve(address(flashLoanReceiver), flashLoanAmountWbtc * 5, tokenList.wbtc);

    deal(tokenList.weth, address(flashLoanReceiver), flashLoanFeeWeth);
    deal(tokenList.wbtc, address(flashLoanReceiver), flashLoanFeeWbtc);

    address[] memory assets = new address[](2);
    assets[0] = tokenList.weth;
    assets[1] = tokenList.wbtc;

    uint256[] memory amounts = new uint256[](2);
    amounts[0] = flashLoanAmountWeth;
    amounts[1] = flashLoanAmountWbtc;

    uint256[] memory interestRateModes = new uint256[](2);
    interestRateModes[0] = 2;
    interestRateModes[1] = 2;

    vm.prank(address(flashLoanReceiver));
    contracts.poolProxy.flashLoan({
      receiverAddress: address(flashLoanReceiver),
      assets: assets,
      amounts: amounts,
      interestRateModes: interestRateModes,
      onBehalfOf: address(flashLoanReceiver),
      params: '0x',
      referralCode: 0
    });
    vm.snapshotGasLastCall('Pool.Operations', 'flashLoan: flash loan for two assets and borrow');
  }

  function test_flashLoanSimple() external {
    uint256 flashLoanAmount = 10 ether;
    uint256 flashLoanFee = (flashLoanAmount * contracts.poolProxy.FLASHLOAN_PREMIUM_TOTAL()) /
      100_00;

    MockSimpleFlashLoanReceiverWithoutMint flashLoanReceiver = new MockSimpleFlashLoanReceiverWithoutMint(
        contracts.poolAddressesProvider
      );

    deal(tokenList.weth, address(flashLoanReceiver), flashLoanFee);

    contracts.poolProxy.flashLoanSimple({
      receiverAddress: address(flashLoanReceiver),
      asset: tokenList.weth,
      amount: flashLoanAmount,
      params: '0x',
      referralCode: 0
    });
    vm.snapshotGasLastCall('Pool.Operations', 'flashLoanSimple: simple flash loan');
  }

  function test_mintToTreasury_one_asset() external {
    uint256 supplyAmount = 10e18;
    uint256 borrowAmount = supplyAmount / 10;

    _supplyOnReserve(borrower, supplyAmount, tokenList.weth);
    vm.startPrank(borrower);
    contracts.poolProxy.borrow({
      asset: tokenList.weth,
      amount: borrowAmount,
      interestRateMode: 2,
      referralCode: 0,
      onBehalfOf: borrower
    });

    vm.warp(vm.getBlockTimestamp() + 10 days);

    IERC20(tokenList.weth).approve(report.poolProxy, type(uint256).max);
    contracts.poolProxy.repay({
      asset: tokenList.weth,
      amount: borrowAmount,
      interestRateMode: 2,
      onBehalfOf: borrower
    });

    skip(100);

    address[] memory assets = new address[](1);
    assets[0] = tokenList.weth;

    contracts.poolProxy.mintToTreasury(assets);

    vm.snapshotGasLastCall('Pool.Operations', 'mintToTreasury: one asset with non zero amount');
  }

  function test_mintToTreasury_two_assets() external {
    uint256 supplyAmountWeth = 10e18;
    uint256 supplyAmountWbtc = 10e8;
    uint256 borrowAmountWeth = supplyAmountWeth / 10;
    uint256 borrowAmountWbtc = supplyAmountWbtc / 10;

    _supplyOnReserve(borrower, supplyAmountWeth, tokenList.weth);
    _supplyOnReserve(borrower, supplyAmountWbtc, tokenList.wbtc);
    vm.startPrank(borrower);
    contracts.poolProxy.borrow({
      asset: tokenList.weth,
      amount: borrowAmountWeth,
      interestRateMode: 2,
      referralCode: 0,
      onBehalfOf: borrower
    });
    contracts.poolProxy.borrow({
      asset: tokenList.wbtc,
      amount: borrowAmountWbtc,
      interestRateMode: 2,
      referralCode: 0,
      onBehalfOf: borrower
    });

    vm.warp(vm.getBlockTimestamp() + 10 days);

    IERC20(tokenList.weth).approve(report.poolProxy, type(uint256).max);
    IERC20(tokenList.wbtc).approve(report.poolProxy, type(uint256).max);
    contracts.poolProxy.repay({
      asset: tokenList.weth,
      amount: borrowAmountWeth,
      interestRateMode: 2,
      onBehalfOf: borrower
    });
    contracts.poolProxy.repay({
      asset: tokenList.wbtc,
      amount: borrowAmountWbtc,
      interestRateMode: 2,
      onBehalfOf: borrower
    });

    skip(100);

    address[] memory assets = new address[](2);
    assets[0] = tokenList.weth;
    assets[1] = tokenList.wbtc;

    contracts.poolProxy.mintToTreasury(assets);

    vm.snapshotGasLastCall('Pool.Operations', 'mintToTreasury: two assets with non zero amount');
  }

  function test_mintToTreasury_one_asset_zero_amount() external {
    address[] memory assets = new address[](1);
    assets[0] = tokenList.weth;

    contracts.poolProxy.mintToTreasury(assets);

    vm.snapshotGasLastCall('Pool.Operations', 'mintToTreasury: one asset with zero amount');
  }

  function test_mintToTreasury_two_assets_zero_amount() external {
    address[] memory assets = new address[](2);
    assets[0] = tokenList.weth;
    assets[1] = tokenList.wbtc;

    contracts.poolProxy.mintToTreasury(assets);

    vm.snapshotGasLastCall('Pool.Operations', 'mintToTreasury: two assets with zero amount');
  }
}
