// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title HFPostconditionsSpec
/// @notice Health Factor Classification Model for Aave V3
/// @dev Defines postcondition properties related to the Health Factor (HF) in the protocol
abstract contract HFPostconditionsSpec {
  /*///////////////////////////////////////////////////////////////////////////////////////////////////
  //                                      PROPERTY TYPES                                             //
  ////////////////////////////////////////////////////////////////////////////////////////////////////

    Health Factor (HF) Classification Model for Aave V3:

    General Rules:
      1. Health Factor (HF): Represents the collateral-to-debt ratio of a user.
      2. Actions Affecting HF: Actions can either increase or decrease a user’s HF.
      3. Safe State: A user is considered safe if HF ≥ 1.0, and unsafe if HF < 1.0.

  //////////////////////////////////////////////////////////////////////////////////////////////////*/

  ////////////////////////////////////////////////////////////////////////////////////////////////////
  //                                    HEALTH FACTOR INVARIANTS                                    //
  ////////////////////////////////////////////////////////////////////////////////////////////////////

  // 1. HF Transition Properties
  string constant HF_GPOST_A =
    'HF_GPOST_A: If health factor decreases, the action must not belong to nonDecreasingHfActions';

  string constant HF_GPOST_B =
    'HF_GPOST_B: If health factor increases, the action must not belong to nonIncreasingHfActions';

  // 2. Safety Invariants
  string constant HF_GPOST_C =
    'HF_GPOST_C: No function can transition a healthy account (HF >= 1.0) to unhealthy (HF < 1.0), except for price updates and borrowing interest';

  // 3. Unsafe HF Conditions
  string constant HF_GPOST_D =
    'HF_GPOST_D: If HF is unsafe after an action (HF < 1.0), the action must belong to hfUnsafeAfterAction';

  string constant HF_GPOST_E =
    'HF_GPOST_E: If HF is unsafe before an action (HF < 1.0), the action must belong to hfUnsafeBeforeAction';

  // 4. Actor Isolation Invariants
  string constant HF_GPOST_F =
    'HF_GPOST_F: Changes to an actor Health Factor (HF) must not affect the HF of any non-targeted actors.';

  /*///////////////////////////////////////////////////////////////////////////////////////////////////
  //                                FUNCTIONAL BEHAVIOR AND HF IMPACT                                //
  ////////////////////////////////////////////////////////////////////////////////////////////////////

    This section outlines how different Aave V3 functions interact with HF:

    --- Pool Contract Functions ---
      • supply / supplyWithPermit / deposit:
          Affected Actors (receiverActor HF)
          HF Impact: nonDecreasingHfActions(receiverActor), hfUnsafeBeforeAction(receiverActor), hfUnsafeAfterAction(receiverActor)
          Summary:
            - Increases receiverActor's HF.
            - HF can be any value before or after the action.

      • withdraw:
          Affected Actors (senderActor HF)
          HF Impact: nonIncreasingHfActions(senderActor)
          Summary:
            - Decreases senderActor’s HF.
            - After withdrawal, HF must remain ≥ 1.0.

      • borrow:
          Affected Actors (onBehalfOf HF) -> senderActor
          HF Impact: nonIncreasingHfActions(senderActor)
          Summary:
            - Decreases HF.
            - After borrowing, HF must remain ≥ 1.0.

      • repay / repayWithPermit / repayWithATokens:
          Affected Actors (receiverActor HF)
          HF Impact: nonDecreasingHfActions(receiverActor), hfUnsafeBeforeAction(receiverActor), hfUnsafeAfterAction(receiverActor)
          Summary:
            - Increases HF.
            - HF can be any value before or after the action.

      • setUserUseReserveAsCollateral:
          Affected Actors (senderActor HF)
          HF Impact: hfUnsafeBeforeAction(senderActor), hfUnsafeAfterAction(senderActor)
          Summary:
            - Enabling collateral increases HF.
            - Disabling collateral decreases HF. After disabling, HF must remain ≥ 1.0.

      • liquidationCall:
          Affected Actors (senderActor HF, receiverActor HF)
          HF Impact: nonDecreasingHfActions(senderActor, receiverActor), hfUnsafeBeforeAction(senderActor, receiverActor), hfUnsafeAfterAction(receiverActor)
          Summary:
            - receiverActor must have HF < 1.0 before liquidation.
            - Increases receiverActor'd HF.
            - senderActor's HF remains unaffected unless they receive aTokens as a reward, in which case it increases.

      • flashLoan:
          Affected Actors (receiverActor HF)
          HF Impact: nonIncreasingHfActions(receiverActor)
          Summary:
            - If a debt position is opened, HF decreases for receiverActor.
            - If all assets are returned, HF remains unchanged.

      • executeFlashLoanSimple:
          Affected Actors (senderActor HF, receiverActor HF)
          HF Impact: hfUnsafeBeforeAction(senderActor, receiverActor), hfUnsafeAfterAction(receiverActor)
          Summary:
            - Does not affect HF.

      • setUserEMode:
          Summary:
            - After execution, HF must remain ≥ 1.0.

      • rescueTokens:
        - Does not affect HF.

    --- PoolConfigurator Functions ---
      • configureReserveAsCollateral / setEModeCategory / setAssetCollateralInEMode: (allActors HF)
          Summary:
            - May increase or decrease HF for affected users, depending on changes to liquidationThreshold or collateral parameters.

    --- AToken Functions ---
      • transfer / transferFrom:
          Affected Actors (senderActor HF, receiverActor HF)
          HF Impact: (hfUnsafeBeforeAction(receiverActor), hfUnsafeAfterAction(receiverActor))
          Summary:
            - Increases HF of the receiverActor.
            - Decreases HF of the senderActor.
            - After transfer, senderActor's HF must remain ≥ 1.0.

  //////////////////////////////////////////////////////////////////////////////////////////////////*/
}
