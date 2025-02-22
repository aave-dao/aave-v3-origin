// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title InvariantsSpec
/// @notice Invariants specification for the protocol
/// @dev Contains pseudo code and description for the invariant properties in the protocol
abstract contract InvariantsSpec {
  /*/////////////////////////////////////////////////////////////////////////////////////////////
    //                                      PROPERTY TYPES                                       //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    /// - INVARIANTS (INV): 
    ///   - Properties that should always hold true in the system. 
    ///   - Implemented in the /invariants folder.

    /////////////////////////////////////////////////////////////////////////////////////////////*/

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                          BASE                                             //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  string constant BASE_INVARIANT_A =
    'BASE_INVARIANT_A: debtToken totalSupply should be equal to the sum of all user balances (user debt)';

  string constant BASE_INVARIANT_B =
    'BASE_INVARIANT_B: aToken totalSupply should be equal to the sum of all user balances)';

  string constant BASE_INVARIANT_C =
    'BASE_INVARIANT_C: The total amount of underlying in the protocol should be greater or equal than the aToken totalSuuply - debtToken totalSupply';

  string constant BASE_INVARIANT_D =
    'BASE_INVARIANT_D: The total amount of underlying in the protocol should greater or equal to the reserve virtualUnderlyingBalance';

  string constant BASE_INVARIANT_E =
    'BASE_INVARIANT_E: If reserve is frozen pending ltv cannot be 0';

  string constant BASE_INVARIANT_F =
    'BASE_INVARIANT_F: virtualBalance + currentDebt = (scaledATokenTotalSupply + accrueToTreasury) * liquidityIndexRightNow';

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                        BORROWING                                          //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  string constant BORROWING_INVARIANT_A =
    'BORROWING_INVARIANT_A: sum of all user debt == 0 <=> totalBorrowed == 0';

  string constant BORROWING_INVARIANT_B =
    'BORROWING_INVARIANT_B: if a user does not have debt, configuration.isBorrowing -> false'; // Discarded

  string constant BORROWING_INVARIANT_B2 =
    'BORROWING_INVARIANT_B: if a user has any debt, configuration.isBorrowing -> true';

  string constant BORROWING_INVARIANT_C =
    'BORROWING_INVARIANT_C: if a user does not have collateral supplied, configuration.isCollateral -> false';

  string constant BORROWING_INVARIANT_C2 =
    'BORROWING_INVARIANT_C: if a user does has any collateral, configuration.isCollateral -> true'; // Discarded

  string constant BORROWING_INVARIANT_D =
    'BORROWING_INVARIANT_D: The grace period must not exceed the defined maximum limit of 4 hours';

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                          ORACLE                                           //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  string constant ORACLE_INVARIANT_A = 'ORACLE_INVARIANT_A: getAssetPrice must never revert';

  string constant ORACLE_INVARIANT_B =
    'ORACLE_INVARIANT_B: The price feed should never return different prices when called multiple times in a single tx';

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                      DEFICIT MANAGEMENT                                   //
  ///////////////////////////////////////////////////////////////////////////////////////////////
}
