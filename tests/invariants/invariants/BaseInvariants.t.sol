// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {EnumerableSet} from 'openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol';

// Libraries
import {UserConfiguration} from 'src/contracts/protocol/libraries/configuration/UserConfiguration.sol';
import {ReserveConfiguration} from 'src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {DataTypes} from 'src/contracts/protocol/libraries/types/DataTypes.sol';
import {EModeConfiguration} from 'src/contracts/protocol/libraries/configuration/EModeConfiguration.sol';

// Interfaces
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {IAToken} from 'src/contracts/interfaces/IAToken.sol';

// Contracts
import {HandlerAggregator} from '../HandlerAggregator.t.sol';

/// @title BaseInvariants
/// @notice Implements Invariants for the protocol
/// @dev Inherits HandlerAggregator to check actions in assertion testing mode
abstract contract BaseInvariants is HandlerAggregator {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;
  using EnumerableSet for EnumerableSet.UintSet;

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                          BASE                                             //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  uint256 internal constant MAX_BALANCE_ROUNDING_ERROR_PER_ACTOR = 2;

  function assert_BASE_INVARIANT_A(IERC20 debtToken) internal {
    uint256 sumOfUserBalances;
    for (uint256 i; i < NUMBER_OF_ACTORS; i++) {
      sumOfUserBalances += debtToken.balanceOf(actorAddresses[i]);
    }
    assertApproxEqAbs(
      debtToken.totalSupply(),
      sumOfUserBalances,
      MAX_BALANCE_ROUNDING_ERROR_PER_ACTOR * NUMBER_OF_ACTORS,
      BASE_INVARIANT_A
    );
    assertGe(sumOfUserBalances, debtToken.totalSupply(), BASE_INVARIANT_A);
  }

  function assert_BASE_INVARIANT_A_EXACT(IERC20 debtToken) internal {
    uint256 sumOfUserBalances;
    for (uint256 i; i < NUMBER_OF_ACTORS; i++) {
      sumOfUserBalances += IAToken(address(debtToken)).scaledBalanceOf(actorAddresses[i]);
    }
    assertEq(
      IAToken(address(debtToken)).scaledTotalSupply(),
      sumOfUserBalances,
      BASE_INVARIANT_A_EXACT
    );
  }

  function assert_BASE_INVARIANT_B(IERC20 aToken) internal {
    uint256 sumOfUserBalances;
    for (uint256 i; i < NUMBER_OF_ACTORS; i++) {
      sumOfUserBalances += aToken.balanceOf(actorAddresses[i]);
    }
    sumOfUserBalances += aToken.balanceOf(address(contracts.treasury));
    assertApproxEqAbs(
      aToken.totalSupply(),
      sumOfUserBalances,
      (NUMBER_OF_ACTORS + 1) * MAX_BALANCE_ROUNDING_ERROR_PER_ACTOR,
      BASE_INVARIANT_B
    );
    assertLe(sumOfUserBalances, aToken.totalSupply(), BASE_INVARIANT_B);
  }

  function assert_BASE_INVARIANT_B_EXACT(IERC20 aToken) internal {
    uint256 sumOfUserBalances;
    for (uint256 i; i < NUMBER_OF_ACTORS; i++) {
      sumOfUserBalances += IAToken(address(aToken)).scaledBalanceOf(actorAddresses[i]);
    }
    sumOfUserBalances += IAToken(address(aToken)).scaledBalanceOf(address(contracts.treasury));
    assertEq(
      IAToken(address(aToken)).scaledTotalSupply(),
      sumOfUserBalances,
      BASE_INVARIANT_B_EXACT
    );
  }

  function assert_BASE_INVARIANT_C(address asset) internal {
    uint256 liquidityAfterAllRepayments = IERC20(protocolTokens[asset].variableDebtTokenAddress)
      .totalSupply() + pool.getVirtualUnderlyingBalance(asset);
    uint256 realTotalSupply = _getRealTotalSupply(asset);

    assertGe(liquidityAfterAllRepayments, realTotalSupply, BASE_INVARIANT_C);
  }

  function assert_BASE_INVARIANT_D(address asset) internal {
    assertGe(
      IERC20(asset).balanceOf(protocolTokens[asset].aTokenAddress),
      pool.getVirtualUnderlyingBalance(asset),
      BASE_INVARIANT_D
    );
  }

  function assert_BASE_INVARIANT_E(address asset) internal {
    /* if (pool.getConfiguration(asset).getFrozen() && !ghost_reserveLtvIsZero[asset]) {
      assertNeq(contracts.poolConfiguratorProxy.getPendingLtv(asset), 0, BASE_INVARIANT_E);
    } */
  }

  function assert_BASE_INVARIANT_F(address asset) internal {
    uint256 numberOfEModes = ghost_categoryIds.length();
    for (uint256 i; i < numberOfEModes; i++) {
      uint8 categoryId = uint8(ghost_categoryIds.at(i));

      uint128 ltvzeroBitmap = pool.getEModeCategoryLtvzeroBitmap(categoryId);
      if (
        EModeConfiguration.isReserveEnabledOnBitmap({
          bitmap: ltvzeroBitmap,
          reserveIndex: protocolTokens[asset].id
        })
      ) {
        uint128 collateralBitmap = pool.getEModeCategoryCollateralBitmap(categoryId);

        assertTrue(
          EModeConfiguration.isReserveEnabledOnBitmap({
            bitmap: collateralBitmap,
            reserveIndex: protocolTokens[asset].id
          }),
          BASE_INVARIANT_F
        );
      }
    }
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                        BORROWING                                          //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  function assert_BORROWING_INVARIANT_A(IERC20 debtToken) internal {
    uint256 totalBorrowed;
    for (uint256 i; i < NUMBER_OF_ACTORS; i++) {
      totalBorrowed += debtToken.balanceOf(actorAddresses[i]);
    }
    if (totalBorrowed == 0) {
      assertEq(debtToken.totalSupply(), 0, BORROWING_INVARIANT_A);
    }
  }

  function assert_BORROWING_INVARIANT_B(address asset) internal {
    ProtocolTokens memory protocolToken = protocolTokens[asset];
    for (uint256 i; i < NUMBER_OF_ACTORS; i++) {
      if (IAToken(protocolToken.variableDebtTokenAddress).scaledBalanceOf(actorAddresses[i]) == 0) {
        assertFalse(
          pool.getUserConfiguration(actorAddresses[i]).isBorrowing(protocolToken.id),
          BORROWING_INVARIANT_B1
        );
      } else {
        assertTrue(
          pool.getUserConfiguration(actorAddresses[i]).isBorrowing(protocolToken.id),
          BORROWING_INVARIANT_B2
        );
      }
    }
  }

  function assert_BORROWING_INVARIANT_C(address asset) internal {
    for (uint256 i; i < NUMBER_OF_ACTORS; i++) {
      if (IAToken(protocolTokens[asset].aTokenAddress).scaledBalanceOf(actorAddresses[i]) == 0) {
        assertFalse(
          pool.getUserConfiguration(actorAddresses[i]).isUsingAsCollateral(
            protocolTokens[asset].id
          ),
          BORROWING_INVARIANT_C
        );
      }
    }
  }

  function assert_BORROWING_INVARIANT_D(address asset) internal {
    assertLe(
      pool.getLiquidationGracePeriod(asset),
      block.timestamp + MAX_GRACE_PERIOD,
      BORROWING_INVARIANT_D
    );
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                         ORACLE                                            //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  function assert_ORACLE_INVARIANT_A() internal {
    for (uint256 i; i < baseAssets.length; i++) {
      try contracts.aaveOracle.getAssetPrice(baseAssets[i]) {} catch {
        assertTrue(false, ORACLE_INVARIANT_A);
      }
    }
  }

  function assert_ORACLE_INVARIANT_B() internal {
    for (uint256 i; i < baseAssets.length; i++) {
      uint256 price1 = contracts.aaveOracle.getAssetPrice(baseAssets[i]);
      uint256 price2 = contracts.aaveOracle.getAssetPrice(baseAssets[i]);
      assertEq(price1, price2, ORACLE_INVARIANT_B);
    }
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                         Interest rate strategy                                            //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  function assert_IR_INVARIANT_A(address asset) internal {
    DataTypes.ReserveDataLegacy memory reserveData = contracts.poolProxy.getReserveData(asset);
    assertLe(
      reserveData.currentLiquidityRate * _getRealTotalSupply(asset),
      reserveData.currentVariableBorrowRate *
        IERC20(reserveData.variableDebtTokenAddress).totalSupply(),
      IR_INVARIANT_A
    );
  }
}
