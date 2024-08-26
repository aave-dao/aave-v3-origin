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
import {DataTypes} from '../../../src/contracts/protocol/libraries/types/DataTypes.sol';
import {IERC20} from '../../../src/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {MockFlashLoanATokenReceiver} from '../../mocks/MockFlashLoanATokenReceiver.sol';
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

    vm.expectRevert(bytes(Errors.INVALID_FLASHLOAN_EXECUTOR_RETURN));

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

    vm.expectRevert(bytes(Errors.FLASHLOAN_DISABLED));

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

    vm.expectRevert(bytes(Errors.RESERVE_PAUSED));

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

    vm.expectRevert(bytes(Errors.RESERVE_INACTIVE));

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

    vm.expectRevert(bytes(Errors.INCONSISTENT_FLASHLOAN_PARAMS));
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

    vm.expectRevert(bytes(Errors.INVALID_FLASHLOAN_EXECUTOR_RETURN));

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
    (address aUSDX, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(tokenList.usdx);

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
    vm.expectRevert(bytes(Errors.INVALID_AMOUNT));
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
    (address aUSDX, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(tokenList.usdx);

    vm.startPrank(carol);
    contracts.poolProxy.withdraw(tokenList.usdx, 50_000e6, carol);
    usdx.transfer(aUSDX, 50_000e6);
    vm.stopPrank();

    assertEq(IERC20(aUSDX).totalSupply(), 0);

    bytes memory emptyParams;

    vm.prank(alice);
    vm.expectRevert(bytes(Errors.INVALID_AMOUNT));
    contracts.poolProxy.flashLoanSimple(
      address(mockFlashSimpleReceiver),
      tokenList.usdx,
      10e6,
      emptyParams,
      0
    );
  }

  function test_reverts_supply_flashloan_transfer_withdraw() public {
    (address aUSDX, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(tokenList.usdx);

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
    (address aUSDX, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(tokenList.usdx);

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
    bytes memory emptyParams;

    vm.prank(poolAdmin);
    TestnetERC20(tokenList.usdx).transferOwnership(address(mockFlashSimpleReceiver));

    vm.prank(alice);
    contracts.poolProxy.flashLoanSimple(
      address(mockFlashSimpleReceiver),
      tokenList.usdx,
      10e6,
      emptyParams,
      0
    );
  }

  function test_flashloan_simple_2() public {
    bytes memory emptyParams;

    vm.prank(poolAdmin);
    TestnetERC20(tokenList.wbtc).transferOwnership(address(mockFlashSimpleReceiver));

    vm.prank(alice);
    contracts.poolProxy.flashLoanSimple(
      address(mockFlashSimpleReceiver),
      tokenList.wbtc,
      3e8,
      emptyParams,
      0
    );
  }

  function test_flashloan() public {
    (
      address[] memory assets,
      uint256[] memory amounts,
      uint256[] memory modes,
      bytes memory emptyParams
    ) = _defaultInput(true, 0);

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

  function test_flashloan_multiple() public {
    (
      address[] memory assets,
      uint256[] memory amounts,
      uint256[] memory modes,
      bytes memory emptyParams
    ) = _defaultMultipleInput(true);

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

  function test_revert_flashloan_borrow_stable() public {
    (
      address[] memory assets,
      uint256[] memory amounts,
      uint256[] memory modes,
      bytes memory emptyParams
    ) = _defaultInput(false, 1);

    vm.prank(alice);
    vm.expectRevert(bytes(Errors.INVALID_INTEREST_RATE_MODE_SELECTED));
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
        emit BorrowLogic.Borrow(
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
      emit FlashLoanLogic.FlashLoan(
        address(mockFlashReceiver),
        alice,
        assets[x],
        amounts[x],
        DataTypes.InterestRateMode(modes[x]),
        modes[x] > 0 ? 0 : amounts[x].percentMul(totalFee),
        0
      );
    }
  }
}
