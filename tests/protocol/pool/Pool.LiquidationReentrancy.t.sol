// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {Multicall} from 'openzeppelin-contracts/contracts/utils/Multicall.sol';
import {ReentrancyGuardTransient} from 'openzeppelin-contracts/contracts/utils/ReentrancyGuardTransient.sol';

import {IAaveOracle} from '../../../src/contracts/interfaces/IAaveOracle.sol';
import {IPool} from '../../../src/contracts/interfaces/IPool.sol';
import {Pool} from '../../../src/contracts/protocol/pool/Pool.sol';
import {TestnetERC20} from '../../../src/contracts/mocks/testnet-helpers/TestnetERC20.sol';
import {MockAggregator} from '../../../src/contracts/mocks/oracle/CLAggregators/MockAggregator.sol';
import {ReserveConfiguration} from '../../../src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {DataTypes} from '../../../src/contracts/protocol/libraries/types/DataTypes.sol';
import {TestnetProcedures} from '../../utils/TestnetProcedures.sol';

/**
 * @dev A malicious underlying whose runtime is etched onto the test WBTC reserve.
 * Its inheritance keeps the existing TestnetERC20 storage layout intact.
 */
contract LiquidationCallbackToken is TestnetERC20 {
  IPool internal immutable POOL;

  bool internal callbackArmed;
  bool internal callbackSucceeded;
  address internal armedCallbackSource;
  bytes internal callbackData;
  bytes internal callbackResult;

  constructor(IPool pool) TestnetERC20('implementation only', 'IMPL', 8, address(this)) {
    POOL = pool;
  }

  function openPosition(uint256 collateralAmount, address debtAsset, uint256 debtAmount) external {
    IERC20(address(this)).approve(address(POOL), type(uint256).max);
    POOL.supply(address(this), collateralAmount, address(this), 0);
    POOL.borrow(debtAsset, debtAmount, 2, 0, address(this));
  }

  function armCallback(bytes calldata data, address source) external {
    callbackData = data;
    armedCallbackSource = source;
    callbackArmed = true;
  }

  function callPool(bytes calldata data) external returns (bytes memory) {
    (bool success, bytes memory result) = address(POOL).call(data);
    if (!success) {
      assembly {
        revert(add(result, 32), mload(result))
      }
    }
    return result;
  }

  function getCallbackResult() external view returns (bool, bytes memory) {
    return (callbackSucceeded, callbackResult);
  }

  function executeOperation(
    address[] calldata,
    uint256[] calldata,
    uint256[] calldata,
    address,
    bytes calldata
  ) external view returns (bool) {
    require(msg.sender == address(POOL));
    return true;
  }

  function _update(address from, address to, uint256 value) internal override {
    super._update(from, to, value);

    if (callbackArmed && from == armedCallbackSource) {
      callbackArmed = false;
      (callbackSucceeded, callbackResult) = address(POOL).call(callbackData);
    }
  }
}

enum GuardedAction {
  Supply,
  SupplyWithPermit,
  Deposit,
  Withdraw,
  Borrow,
  Repay,
  RepayWithPermit,
  RepayWithATokens,
  LiquidationCall,
  FlashLoan,
  FlashLoanSimple,
  SetUserUseReserveAsCollateral,
  SetUserEMode,
  SetUserUseReserveAsCollateralOnBehalfOf,
  SetUserEModeOnBehalfOf,
  MintToTreasury,
  InitReserve,
  SyncIndexesState,
  SyncRatesState,
  SetConfiguration,
  UpdateFlashloanPremium,
  ConfigureEModeCategory,
  ConfigureEModeCategoryCollateralBitmap,
  ConfigureEModeCategoryBorrowableBitmap,
  ConfigureEModeCategoryLtvzeroBitmap,
  ConfigureEModeCategoryIsolated,
  SetLiquidationGracePeriod,
  RescueTokens,
  EliminateReserveDeficit,
  FinalizeTransfer
}

contract PoolLiquidationReentrancyTests is TestnetProcedures {
  IPool internal pool;
  LiquidationCallbackToken internal attacker;

  uint8 internal constant ISOLATED_EMODE = 3;
  uint256 internal constant MALICIOUS_COLLATERAL = 0.01e8;
  uint256 internal constant INITIAL_WETH_DEBT = 0.1e18;

  function setUp() public {
    initTestEnvironment();
    pool = contracts.poolProxy;

    vm.startPrank(carol);
    pool.supply(tokenList.usdx, 100_000e6, carol, 0);
    pool.supply(tokenList.weth, 100e18, carol, 0);
    pool.supply(tokenList.wbtc, 0.99e8, carol, 0);
    vm.stopPrank();

    // Preserve WBTC's balances, allowances, metadata, and reserve address while
    // replacing its behavior with a token that calls back during a transfer.
    vm.etch(tokenList.wbtc, address(new LiquidationCallbackToken(pool)).code);
    attacker = LiquidationCallbackToken(tokenList.wbtc);

    vm.prank(poolAdmin);
    TestnetERC20(tokenList.wbtc).mint(address(attacker), MALICIOUS_COLLATERAL);

    attacker.openPosition(MALICIOUS_COLLATERAL, tokenList.weth, INITIAL_WETH_DEBT);
  }

  function test_liquidationCallbackBlocksGuardedEntryPoints() public {
    for (uint256 i; i <= uint256(type(GuardedAction).max); ++i) {
      uint256 snapshot = vm.snapshotState();

      attacker.callPool(abi.encodeCall(IPool.approvePositionManager, (address(attacker), true)));
      _makePositionLiquidatable();
      attacker.armCallback(
        _getGuardedCallData(GuardedAction(i)),
        pool.getReserveAToken(tokenList.wbtc)
      );

      vm.prank(bob);
      pool.liquidationCall(
        tokenList.wbtc,
        tokenList.weth,
        address(attacker),
        type(uint256).max,
        false
      );

      _assertCallbackBlocked();
      vm.revertToState(snapshot);
    }
  }

  function test_supplyLocksGuardedEntryPoints() public {
    _prepareWbtcSupply();
    attacker.armCallback(_getGuardedCallData(GuardedAction.Borrow), address(attacker));
    attacker.callPool(abi.encodeCall(IPool.supply, (tokenList.wbtc, 1, address(attacker), 0)));

    _assertCallbackBlocked();
  }

  function test_multicallCannotBypassGuard() public {
    _prepareWbtcSupply();
    bytes[] memory calls = new bytes[](1);
    calls[0] = _getGuardedCallData(GuardedAction.Borrow);
    attacker.armCallback(abi.encodeCall(Multicall.multicall, (calls)), address(attacker));
    attacker.callPool(abi.encodeCall(IPool.supply, (tokenList.wbtc, 1, address(attacker), 0)));

    _assertCallbackBlocked();
  }

  function test_supplyCallbackCannotBypassSupplyCap() public {
    uint256 supplyCap = 2e8;
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setSupplyCap(tokenList.wbtc, 2);

    address aWbtc = pool.getReserveAToken(tokenList.wbtc);
    uint256 totalSupplyBefore = IERC20(aWbtc).totalSupply();
    uint256 supplyAmount = ((supplyCap - totalSupplyBefore) * 3) / 4;

    assertLe(totalSupplyBefore + supplyAmount, supplyCap);
    assertGt(totalSupplyBefore + 2 * supplyAmount, supplyCap);

    vm.prank(poolAdmin);
    TestnetERC20(tokenList.wbtc).mint(address(attacker), 2 * supplyAmount);

    bytes memory supplyCall = abi.encodeCall(
      IPool.supply,
      (tokenList.wbtc, supplyAmount, address(attacker), 0)
    );
    attacker.armCallback(supplyCall, address(attacker));
    attacker.callPool(supplyCall);

    _assertCallbackBlocked();
    assertApproxEqAbs(IERC20(aWbtc).totalSupply(), totalSupplyBefore + supplyAmount, 1);
    assertLe(IERC20(aWbtc).totalSupply(), supplyCap);
    assertEq(IERC20(tokenList.wbtc).balanceOf(address(attacker)), supplyAmount);
  }

  function test_supplyWithPermitLocksGuardedEntryPoints() public {
    _prepareWbtcSupply();
    attacker.armCallback(_getGuardedCallData(GuardedAction.Borrow), address(attacker));
    attacker.callPool(
      abi.encodeCall(
        IPool.supplyWithPermit,
        (tokenList.wbtc, 1, address(attacker), 0, 0, 0, bytes32(0), bytes32(0))
      )
    );

    _assertCallbackBlocked();
  }

  function test_depositLocksGuardedEntryPoints() public {
    _prepareWbtcSupply();
    attacker.armCallback(_getGuardedCallData(GuardedAction.Borrow), address(attacker));
    attacker.callPool(abi.encodeCall(IPool.deposit, (tokenList.wbtc, 1, address(attacker), 0)));

    _assertCallbackBlocked();
  }

  function test_withdrawLocksGuardedEntryPoints() public {
    attacker.armCallback(
      _getGuardedCallData(GuardedAction.Borrow),
      pool.getReserveAToken(tokenList.wbtc)
    );
    attacker.callPool(abi.encodeCall(IPool.withdraw, (tokenList.wbtc, 1, address(attacker))));

    _assertCallbackBlocked();
  }

  function test_borrowLocksGuardedEntryPoints() public {
    attacker.armCallback(
      _getGuardedCallData(GuardedAction.Supply),
      pool.getReserveAToken(tokenList.wbtc)
    );
    attacker.callPool(abi.encodeCall(IPool.borrow, (tokenList.wbtc, 1, 2, 0, address(attacker))));

    _assertCallbackBlocked();
  }

  function test_repayLocksGuardedEntryPoints() public {
    _openWbtcDebt();
    attacker.armCallback(_getGuardedCallData(GuardedAction.Supply), address(attacker));
    attacker.callPool(abi.encodeCall(IPool.repay, (tokenList.wbtc, 1, 2, address(attacker))));

    _assertCallbackBlocked();
  }

  function test_repayWithPermitLocksGuardedEntryPoints() public {
    _openWbtcDebt();
    attacker.armCallback(_getGuardedCallData(GuardedAction.Supply), address(attacker));
    attacker.callPool(
      abi.encodeCall(
        IPool.repayWithPermit,
        (tokenList.wbtc, 1, 2, address(attacker), 0, 0, bytes32(0), bytes32(0))
      )
    );

    _assertCallbackBlocked();
  }

  /// @dev rescueTokens only asserts the guard is clear, so it can still move aTokens out of the
  /// Pool, whose transfer calls back into the now guarded finalizeTransfer.
  function test_rescueATokensFromPool() public {
    address aUsdx = pool.getReserveAToken(tokenList.usdx);
    uint256 carolBalanceBefore = IERC20(aUsdx).balanceOf(carol);

    vm.prank(carol);
    IERC20(aUsdx).transfer(address(pool), 1_000e6);
    assertEq(IERC20(aUsdx).balanceOf(address(pool)), 1_000e6);

    vm.prank(poolAdmin);
    pool.rescueTokens(aUsdx, carol, 1_000e6);

    assertEq(IERC20(aUsdx).balanceOf(address(pool)), 0);
    assertApproxEqAbs(IERC20(aUsdx).balanceOf(carol), carolBalanceBefore, 2);
  }

  /// @dev The guard sits ahead of onlyUmbrella, so even the legitimate caller is turned away
  /// while another Pool action holds the lock.
  function test_eliminateReserveDeficitBlockedWhileEntered() public {
    // the caller inside the callback is the attacker, so make it Umbrella: otherwise
    // onlyUmbrella rejects the call first and the guard is never reached
    bytes32 umbrellaKey = Pool(address(pool)).UMBRELLA();

    vm.prank(poolAdmin);
    contracts.poolAddressesProvider.setAddress(umbrellaKey, address(attacker));

    _prepareWbtcSupply();
    attacker.armCallback(
      abi.encodeCall(IPool.eliminateReserveDeficit, (tokenList.wbtc, 1)),
      address(attacker)
    );
    attacker.callPool(abi.encodeCall(IPool.supply, (tokenList.wbtc, 1, address(attacker), 0)));

    _assertCallbackBlocked();
  }

  /// @dev The position manager role is deliberately settable from inside a callback: the functions
  /// that consume it are guarded, so writing it mid-action is reachable but inert.
  function test_positionManagerRoleStaysReachableFromCallback() public {
    _prepareWbtcSupply();
    attacker.armCallback(
      abi.encodeCall(IPool.approvePositionManager, (bob, true)),
      address(attacker)
    );
    attacker.callPool(abi.encodeCall(IPool.supply, (tokenList.wbtc, 1, address(attacker), 0)));

    (bool callbackSucceeded, ) = attacker.getCallbackResult();
    assertTrue(callbackSucceeded);
    assertTrue(pool.isApprovedPositionManager(address(attacker), bob));
  }

  function _assertCallbackBlocked() internal view {
    (bool callbackSucceeded, bytes memory callbackResult) = attacker.getCallbackResult();
    assertFalse(callbackSucceeded);
    assertEq(callbackResult.length, 4);
    assertEq(
      bytes4(callbackResult),
      ReentrancyGuardTransient.ReentrancyGuardReentrantCall.selector
    );
  }

  function _prepareWbtcSupply() internal {
    vm.prank(poolAdmin);
    contracts.poolConfiguratorProxy.setSupplyCap(tokenList.wbtc, 2);
    vm.prank(poolAdmin);
    TestnetERC20(tokenList.wbtc).mint(address(attacker), 1);
  }

  function _openWbtcDebt() internal {
    attacker.callPool(abi.encodeCall(IPool.borrow, (tokenList.wbtc, 1, 2, 0, address(attacker))));
  }

  function _makePositionLiquidatable() internal {
    address[] memory assets = new address[](1);
    address[] memory sources = new address[](1);
    assets[0] = tokenList.wbtc;
    sources[0] = address(new MockAggregator(10_000e8));
    vm.prank(poolAdmin);
    IAaveOracle(report.aaveOracle).setAssetSources(assets, sources);
  }

  function _getGuardedCallData(GuardedAction action) internal view returns (bytes memory) {
    if (action == GuardedAction.Supply) {
      return abi.encodeCall(IPool.supply, (tokenList.weth, 1, address(attacker), 0));
    }
    if (action == GuardedAction.SupplyWithPermit) {
      return
        abi.encodeCall(
          IPool.supplyWithPermit,
          (tokenList.weth, 1, address(attacker), 0, 0, 0, bytes32(0), bytes32(0))
        );
    }
    if (action == GuardedAction.Deposit) {
      return abi.encodeCall(IPool.deposit, (tokenList.weth, 1, address(attacker), 0));
    }
    if (action == GuardedAction.Withdraw) {
      return abi.encodeCall(IPool.withdraw, (tokenList.weth, 1, address(attacker)));
    }
    if (action == GuardedAction.Borrow) {
      return abi.encodeCall(IPool.borrow, (tokenList.usdx, 1, 2, 0, address(attacker)));
    }
    if (action == GuardedAction.Repay) {
      return abi.encodeCall(IPool.repay, (tokenList.weth, 1, 2, address(attacker)));
    }
    if (action == GuardedAction.RepayWithPermit) {
      return
        abi.encodeCall(
          IPool.repayWithPermit,
          (tokenList.weth, 1, 2, address(attacker), 0, 0, bytes32(0), bytes32(0))
        );
    }
    if (action == GuardedAction.RepayWithATokens) {
      return abi.encodeCall(IPool.repayWithATokens, (tokenList.weth, 1, 2));
    }
    if (action == GuardedAction.LiquidationCall) {
      return
        abi.encodeCall(
          IPool.liquidationCall,
          (tokenList.wbtc, tokenList.weth, address(attacker), 1, false)
        );
    }
    if (action == GuardedAction.FlashLoan) {
      address[] memory assets = new address[](1);
      assets[0] = tokenList.usdx;
      uint256[] memory amounts = new uint256[](1);
      amounts[0] = 1;
      uint256[] memory interestRateModes = new uint256[](1);
      interestRateModes[0] = 2;
      return
        abi.encodeCall(
          IPool.flashLoan,
          (address(attacker), assets, amounts, interestRateModes, address(attacker), bytes(''), 0)
        );
    }
    if (action == GuardedAction.FlashLoanSimple) {
      return
        abi.encodeCall(IPool.flashLoanSimple, (address(attacker), tokenList.usdx, 1, bytes(''), 0));
    }
    if (action == GuardedAction.SetUserUseReserveAsCollateral) {
      return abi.encodeCall(IPool.setUserUseReserveAsCollateral, (tokenList.wbtc, false));
    }
    if (action == GuardedAction.SetUserEMode) {
      return abi.encodeCall(IPool.setUserEMode, (0));
    }
    if (action == GuardedAction.SetUserUseReserveAsCollateralOnBehalfOf) {
      return
        abi.encodeCall(
          IPool.setUserUseReserveAsCollateralOnBehalfOf,
          (tokenList.wbtc, false, address(attacker))
        );
    }
    if (action == GuardedAction.SetUserEModeOnBehalfOf) {
      return abi.encodeCall(IPool.setUserEModeOnBehalfOf, (0, address(attacker)));
    }
    if (action == GuardedAction.MintToTreasury) {
      address[] memory assets = new address[](1);
      assets[0] = tokenList.wbtc;
      return abi.encodeCall(IPool.mintToTreasury, (assets));
    }
    if (action == GuardedAction.InitReserve) {
      return abi.encodeCall(IPool.initReserve, (address(1), address(2), address(3)));
    }
    if (action == GuardedAction.SyncIndexesState) {
      return abi.encodeCall(IPool.syncIndexesState, (tokenList.wbtc));
    }
    if (action == GuardedAction.SyncRatesState) {
      return abi.encodeCall(IPool.syncRatesState, (tokenList.wbtc));
    }
    if (action == GuardedAction.SetConfiguration) {
      return
        abi.encodeCall(
          IPool.setConfiguration,
          (tokenList.wbtc, pool.getConfiguration(tokenList.wbtc))
        );
    }
    if (action == GuardedAction.UpdateFlashloanPremium) {
      return abi.encodeCall(IPool.updateFlashloanPremium, (0));
    }
    if (action == GuardedAction.ConfigureEModeCategory) {
      DataTypes.EModeCategoryBaseConfiguration memory category;
      return abi.encodeCall(IPool.configureEModeCategory, (ISOLATED_EMODE, category));
    }
    if (action == GuardedAction.ConfigureEModeCategoryCollateralBitmap) {
      return
        abi.encodeCall(IPool.configureEModeCategoryCollateralBitmap, (ISOLATED_EMODE, uint128(0)));
    }
    if (action == GuardedAction.ConfigureEModeCategoryBorrowableBitmap) {
      return
        abi.encodeCall(IPool.configureEModeCategoryBorrowableBitmap, (ISOLATED_EMODE, uint128(0)));
    }
    if (action == GuardedAction.ConfigureEModeCategoryLtvzeroBitmap) {
      return
        abi.encodeCall(IPool.configureEModeCategoryLtvzeroBitmap, (ISOLATED_EMODE, uint128(0)));
    }
    if (action == GuardedAction.ConfigureEModeCategoryIsolated) {
      return abi.encodeCall(IPool.configureEModeCategoryIsolated, (ISOLATED_EMODE, false));
    }
    if (action == GuardedAction.SetLiquidationGracePeriod) {
      return abi.encodeCall(IPool.setLiquidationGracePeriod, (tokenList.wbtc, uint40(0)));
    }
    if (action == GuardedAction.RescueTokens) {
      return abi.encodeCall(IPool.rescueTokens, (tokenList.wbtc, address(attacker), 1));
    }
    if (action == GuardedAction.EliminateReserveDeficit) {
      return abi.encodeCall(IPool.eliminateReserveDeficit, (tokenList.wbtc, 1));
    }
    if (action == GuardedAction.FinalizeTransfer) {
      return abi.encodeCall(IPool.finalizeTransfer, (tokenList.wbtc, address(attacker), bob, 1, 1));
    }
    revert('unhandled GuardedAction');
  }
}

/// @dev A liquidation makes a second external call after the collateral leg: the debt asset is
/// pulled from the liquidator at LiquidationLogic:445. The same lock has to cover that transfer.
contract PoolLiquidationDebtAssetCallbackTests is TestnetProcedures {
  IPool internal pool;
  LiquidationCallbackToken internal debtAsset;

  function setUp() public {
    initTestEnvironment();
    pool = contracts.poolProxy;

    vm.prank(carol);
    pool.supply(tokenList.usdx, 100_000e6, carol, 0);

    vm.etch(tokenList.usdx, address(new LiquidationCallbackToken(pool)).code);
    debtAsset = LiquidationCallbackToken(tokenList.usdx);

    vm.startPrank(alice);
    IERC20(tokenList.weth).approve(address(pool), UINT256_MAX);
    pool.supply(tokenList.weth, 2e18, alice, 0);
    pool.borrow(tokenList.usdx, 2_000e6, 2, 0, alice);
    vm.stopPrank();

    deal(tokenList.usdx, bob, 100_000e6);
    vm.prank(bob);
    IERC20(tokenList.usdx).approve(address(pool), UINT256_MAX);
  }

  function test_debtAssetCallbackIsBlocked() public {
    _makePositionLiquidatable();

    debtAsset.armCallback(
      abi.encodeCall(IPool.supply, (tokenList.weth, 1, address(debtAsset), 0)),
      bob
    );

    vm.prank(bob);
    pool.liquidationCall(tokenList.weth, tokenList.usdx, alice, type(uint256).max, false);

    (bool callbackSucceeded, bytes memory callbackResult) = debtAsset.getCallbackResult();
    assertFalse(callbackSucceeded);
    assertEq(callbackResult.length, 4);
    assertEq(
      bytes4(callbackResult),
      ReentrancyGuardTransient.ReentrancyGuardReentrantCall.selector
    );
  }

  function _makePositionLiquidatable() internal {
    address[] memory assets = new address[](1);
    address[] memory sources = new address[](1);
    assets[0] = tokenList.weth;
    sources[0] = address(new MockAggregator(1_100e8));
    vm.prank(poolAdmin);
    IAaveOracle(report.aaveOracle).setAssetSources(assets, sources);
  }
}
