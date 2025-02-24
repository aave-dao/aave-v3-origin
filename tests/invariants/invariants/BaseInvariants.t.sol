// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Libraries
import {UserConfiguration} from 'src/contracts/protocol/libraries/configuration/UserConfiguration.sol';
import {ReserveConfiguration} from 'src/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {DataTypes} from 'src/contracts/protocol/libraries/types/DataTypes.sol';

// Interfaces
import {IERC20} from 'src/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {IAToken} from 'src/contracts/interfaces/IAToken.sol';

// Contracts
import {HandlerAggregator} from '../HandlerAggregator.t.sol';

/// @title BaseInvariants
/// @notice Implements Invariants for the protocol
/// @dev Inherits HandlerAggregator to check actions in assertion testing mode
abstract contract BaseInvariants is HandlerAggregator {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                          BASE                                             //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  function assert_BASE_INVARIANT_A(IERC20 debtToken) internal {
    uint256 sumOfUserBalances;
    for (uint256 i; i < NUMBER_OF_ACTORS; i++) {
      sumOfUserBalances += debtToken.balanceOf(actorAddresses[i]);
    }
    assertEq(debtToken.totalSupply(), sumOfUserBalances, BASE_INVARIANT_A);
  }

  function assert_BASE_INVARIANT_B(IERC20 aToken) internal {
    uint256 sumOfUserBalances;
    for (uint256 i; i < NUMBER_OF_ACTORS; i++) {
      sumOfUserBalances += aToken.balanceOf(actorAddresses[i]);
    }
    sumOfUserBalances += aToken.balanceOf(address(contracts.treasury));
    assertApproxEqAbs(aToken.totalSupply(), sumOfUserBalances, NUMBER_OF_ACTORS, BASE_INVARIANT_B);
  }

  function assert_BASE_INVARIANT_C(address asset) internal {
    address aToken = protocolTokens[asset].aTokenAddress;
    uint256 aTokenTotalSupply = IERC20(aToken).totalSupply();
    uint256 debtTokenTotalSupply = IERC20(protocolTokens[asset].variableDebtTokenAddress)
      .totalSupply();
    uint256 liabilityFreeAmount = (aTokenTotalSupply > debtTokenTotalSupply)
      ? aTokenTotalSupply - debtTokenTotalSupply
      : 0;
    liabilityFreeAmount = liabilityFreeAmount > NUMBER_OF_ACTORS
      ? liabilityFreeAmount - NUMBER_OF_ACTORS
      : liabilityFreeAmount;
    assertGe(IERC20(asset).balanceOf(address(aToken)), liabilityFreeAmount, BASE_INVARIANT_C);
  }

  function assert_BASE_INVARIANT_D(address asset) internal {
    assertGe(
      IERC20(asset).balanceOf(protocolTokens[asset].aTokenAddress),
      pool.getVirtualUnderlyingBalance(asset),
      BASE_INVARIANT_D
    );
  }

  function assert_BASE_INVARIANT_E(address asset) internal {
    if (pool.getConfiguration(asset).getFrozen() && !ghost_reserveLtvIsZero[asset]) {
      assertNeq(contracts.poolConfiguratorProxy.getPendingLtv(asset), 0, BASE_INVARIANT_E);
    }
  }

  function assert_BASE_INVARIANT_F(address asset) internal {
    uint256 virtualBalance = pool.getVirtualUnderlyingBalance(asset);
    uint256 currentDebt = IERC20(protocolTokens[asset].variableDebtTokenAddress).totalSupply();

    assertApproxEqAbs(
      virtualBalance + currentDebt,
      _getRealTotalSupply(asset),
      10,
      BASE_INVARIANT_F
    );
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
      if (
        IERC20(protocolToken.variableDebtTokenAddress).balanceOf(actorAddresses[i]) == 0
      ) {} else {
        assertTrue(
          pool.getUserConfiguration(actorAddresses[i]).isBorrowing(protocolToken.id),
          BORROWING_INVARIANT_B2
        );
      }
    }
  }

  function assert_BORROWING_INVARIANT_C(address asset) internal {
    for (uint256 i; i < NUMBER_OF_ACTORS; i++) {
      if (IERC20(protocolTokens[asset].aTokenAddress).balanceOf(actorAddresses[i]) == 0) {
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
}
