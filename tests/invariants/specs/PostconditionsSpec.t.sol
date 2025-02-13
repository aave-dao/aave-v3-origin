// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title PostconditionsSpec
/// @notice Postcoditions specification for the protocol
/// @dev Contains pseudo code and description for the postcondition properties in the protocol
abstract contract PostconditionsSpec {
  /*/////////////////////////////////////////////////////////////////////////////////////////////
    //                                      PROPERTY TYPES                                       //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    /// - POSTCONDITIONS:
    ///   - Properties that should hold true after an action is executed.
    ///   - Implemented in the /hooks and /handlers folders.

    ///   - There are two types of POSTCONDITIONS:

    ///     - GLOBAL POSTCONDITIONS (GPOST): 
    ///       - Properties that should always hold true after any action is executed.
    ///       - Checked in the `_checkPostConditions` function within the HookAggregator contract.

    ///     - HANDLER-SPECIFIC POSTCONDITIONS (HSPOST): 
    ///       - Properties that should hold true after a specific action is executed in a specific context.
    ///       - Implemented within each handler function, under the HANDLER-SPECIFIC POSTCONDITIONS section.

    /////////////////////////////////////////////////////////////////////////////////////////////*/

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                          BASE                                             //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  string constant BASE_GPOST_A = 'BASE_GPOST_A: Rebasing token indexes should increase monotically';

  string constant BASE_GPOST_B =
    'BASE_GPOST_B: Only a subset of actions can update the interest rate of a reserve';

  string constant BASE_GPOST_C =
    'BASE_GPOST_C: Only a subset of actions can update virtualUnderlyingBalance rate of a reserve';

  string constant BASE_GPOST_D =
    'BASE_GPOST_D: Only a subset of actions can update the liquidity index of a reserve';

  string constant BASE_HPOST_E =
    'BASE_HPOST_E: After unpausing a reserve gracePeriod should be updated correctly';

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                         LENDING                                           //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  string constant LENDING_HPOST_A =
    'LENDING_HPOST_A: An asset can only be deposited when the related reserve is active, not frozen & not paused';

  string constant LENDING_HPOST_B =
    'LENDING_HPOST_B: An asset can only be withdrawn when the related reserve is active & not paused';

  string constant LENDING_GPOST_C =
    'LENDING_GPOST_C: If totalSupply for a reserve increases new totalSupply must be less than or equal to supply cap';

  string constant LENDING_HPOST_D =
    'LENDING_HJPOST_D: After a successful deposit the sender underlying balance should decrease by the amount deposited';

  string constant LENDING_HPOST_E =
    'LENDING_HPOST_E: After a successful deposit the onBehalf AToken balance should increase by the amount deposited';

  string constant LENDING_HPOST_F =
    'LENDING_HPOST_F: After a successful withdraw the actor AToken balance should decrease by the amount withdrawn';

  string constant LENDING_HPOST_G =
    'LENDING_HPOST_G: After a successful withdraw the `to` underlying balance should increase by the amount withdrawn';

  string constant LENDING_HPOST_H1 =
    'LENDING_HPOST_H1: Before a successful withdraw of collateral, caller should be healthy';

  string constant LENDING_HPOST_H2 =
    'LENDING_HPOST_H2: After a successful withdraw of collateral, caller should remain healthy';

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                        BORROWING                                          //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  string constant BORROWING_HSPOST_A =
    'BORROWING_HSPOST_A: User liability should always decrease after repayment';

  string constant BORROWING_HSPOST_B = 'BORROWING_HSPOST_B: Unhealthy users can not borrow';

  string constant BORROWING_HSPOST_C = 'BORROWING_HSPOST_C: A user can always repay debt in full';

  string constant BORROWING_HSPOST_D =
    'BORROWING_HSPOST_D: An asset can only be borrowed when its configured as borrowable.';

  string constant BORROWING_HSPOST_E =
    'BORROWING_HSPOST_E: An asset can only be borrowed when the related reserve is active, not frozen, not paused & borrowing is enabled';

  string constant BORROWING_HSPOST_F =
    'BORROWING_HSPOST_F: An asset can only be repaid when the related reserve is active & not paused';

  string constant BORROWING_HSPOST_G =
    'BORROWING_HSPOST_G: a user should always be able to withdraw all if there is no outstanding debt';

  string constant BORROWING_GPOST_H =
    'BORROWING_GPOST_H: If totalBorrow for a reserve increases new totalBorrow must be less than or equal to borrow cap';

  string constant BORROWING_HSPOST_I =
    'BORROWING_HSPOST_I: After a successful borrow the actor asset balance should increase by the amount borrowed';

  string constant BORROWING_HSPOST_J =
    'BORROWING_HSPOST_J: After a successful borrow the onBehalf debt balance should increase by the amount borrowed';

  string constant BORROWING_HSPOST_K =
    'BORROWING_HSPOST_K: After a successful repay the actor asset balance should decrease by the amount repaid';

  string constant BORROWING_HSPOST_L =
    'BORROWING_HSPOST_L: After a successful repay the onBehalf debt balance should decrease by the amount repaid';

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                       LIQUIDATION                                         //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  // Docs v3.3 Properties 2.1
  string constant LIQUIDATION_HSPOST_A =
    'LIQUIDATION_HSPOST_A: A liquidation can only be performed once a users health-factor drops below 1';

  string constant LIQUIDATION_HSPOST_B =
    'LIQUIDATION_HSPOST_B: No position on a reserve can be liquidated under grace period';

  // Docs v3.3 Properties 2.5 mutually inclusive conditions which increase the CLOSE_FACTOR to 100%
  string constant LIQUIDATION_HSPOST_F =
    'LIQUIDATION_HSPOST_F: If more than totalUserDebt * CLOSE_FACTOR can be liquidated in a single liquidation, either totalDebtBase < MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD or totalDebtBase < MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD or healthFactor < 0.95';

  // Docs v3.3 Properties 2.4
  string constant LIQUIDATION_HSPOST_H =
    'LIQUIDATION_HSPOST_H: Liquidation must fully liquidate debt or fully liquidate collateral or leave at least MIN_LEFTOVER_BASE on both';

  // Docs v3.3 Properties 1.8
  string constant LIQUIDATION_HSPOST_L =
    'LIQUIDATION_HSPOST_L: Liquidation only creates deficit if user collateral across reserves == 0 while debt across reserves != 0';

  // Docs v3.3 Properties 1.10
  string constant LIQUIDATION_HSPOST_M =
    'LIQUIDATION_HSPOST_M: Whenever a deficit is created as a result of a liquidation, the user`s excess debt should be burned and accounted for as deficit';

  // Docs v3.3 Properties 1.11
  string constant LIQUIDATION_HSPOST_N =
    'LIQUIDATION_HSPOST_N: Deficit added during the liquidation cannot be more than the user`s debt';

  // Docs v3.3 Properties 1.12
  string constant LIQUIDATION_HSPOST_O =
    'LIQUIDATION_HSPOST_O: Deficit can only be created and eliminated for an active reserve';

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                         E-MODE                                            //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  string constant E_MODE_HSPOST_A =
    'E_MODE_HSPOST_A: User can only borrow assets that are borrowable in his specific eMode';

  string constant E_MODE_HSPOST_B =
    'E_MODE_HSPOST_B: When being liquidated (and any Health Factor calculation) the eMode LT/LB will only apply to the user eMode collaterals.';

  string constant E_MODE_GPOST_C =
    'E_MODE_GPOST_C: An asset can only be borrowable in eMode when it is borrowable outside eMode as well.'; // Included in BORROWING_HSPOST_D

  string constant E_MODE_GPOST_D =
    'E_MODE_GPOST_D: An asset can only be collateral in eMode when it is a collateral outside as well.'; // discarded

  string constant E_MODE_GPOST_F =
    'E_MODE_GPOST_F: When a borrawable asset becomes unborrawable the position stays intact, but the exposure can no longer be increased.';

  string constant E_MODE_HSPOST_G =
    'E_MODE_HSPOST_G: The health factor of the user must be >= 1 after switch or leaving an emode';

  string constant E_MODE_HSPOST_H =
    'E_MODE_HSPOST_H: All borrowed assets must be borrowable in the new enabled eMode';

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                          ERC20                                            //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  string constant ERC20_HSPOST_A =
    'ERC20_HSPOST_A: After a successful transfer, sender should remain healthy';

  string constant ERC20_HSPOST_B =
    'ERC20_HSPOST_B: Before a successful transfer, sender should be healthy';

  string constant ERC20_HSPOST_C =
    'ERC20_HSPOST_C: After a successful transferFrom, from should remain healthy';

  string constant ERC20_HSPOST_D =
    'ERC20_HSPOST_D: Before a successful transferFrom, from should be healthy';

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                       FLASHLOAN                                           //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  string constant FLASHLOAN_HSPOST_A =
    'FLASHLOAN_HSPOST_A: A flashloan succeeds if theres enough balance (amount + fee) transferred back to the protocol';

  string constant FLASHLOAN_HSPOST_B =
    'FLASHLOAN_HSPOST_B: A flashloan fails if theres not enough balance (amount + fee) transferred back to the protocol';

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                      DEFICIT MANAGEMENT                                   //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  // Docs v3.3 Properties 1.3
  string constant DM_GPOST_A = 'DM_GPOST_A: Deficits can only be reduced by burning a claim';

  // Docs v3.3 Properties 1.4
  string constant DM_HSPOST_B =
    'DM_HSPOST_B: If virtual accounting enabled `eliminateReserveDeficit` will burn aTokens, else the underlying is disposed of';

  // Docs v3.3 Properties 1.6
  string constant DM_HSPOST_C =
    'DM_HSPOST_C: `eliminateReserveDeficit` requires for the UMBRELLA entity to never have any debt';
}
