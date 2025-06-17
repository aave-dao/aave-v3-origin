#CMN="--compilation_steps_only"

echo "******** 1. Running: AToken.conf   ****************"
certoraRun $CMN certora/atoken-with-delegation/conf/AToken.conf \
           --msg "1. AToken.conf"

echo "******** 2. Running: AToken-problematic-rules.conf   ****************"
certoraRun $CMN certora/atoken-with-delegation/conf/AToken-problematic-rules.conf \
           --rule totalSupplyEqualsSumAllBalance additiveBurn additiveTransfer \
           --msg "2. AToken-problematic-rules.conf"

echo "******** 3. Running: token-v3-general.conf   ****************"
certoraRun $CMN certora/atoken-with-delegation/conf/token-v3-general.conf \
           --msg "3. token-v3-general.conf"

echo "******** 4. Running: token-v3-erc20.conf   ****************"
certoraRun $CMN certora/atoken-with-delegation/conf/token-v3-erc20.conf \
           --msg "4. token-v3-erc20.conf"

echo "******** 5 Running: token-v3-delegate-basic.conf   ****************"
certoraRun $CMN certora/atoken-with-delegation/conf/token-v3-delegate-basic.conf \
           --msg "5. token-v3-delegate-basic.conf"

echo "******** 6a. Running: token-v3-delegate-invariants.conf   ****************"
certoraRun $CMN certora/atoken-with-delegation/conf/token-v3-delegate-invariants.conf \
           --rule mirror_votingDelegatee_correct mirror_propositionDelegatee_correct mirror_delegationMode_correct mirror_balance_correct \
           --rule_sanity "none" \
           --msg "6a. delegate-HL-invariants mirrors"

echo "******** 6b. Running: token-v3-delegate-invariants.conf   ****************"
certoraRun $CMN certora/atoken-with-delegation/conf/token-v3-delegate-invariants.conf \
           --exclude_rule mirror_votingDelegatee_correct mirror_propositionDelegatee_correct mirror_delegationMode_correct mirror_balance_correct \
           --msg "6b. delegate-HL-invariants ALL except mirrors"



echo "******** 7a. Running: token-v3-delegate-HL-rules.conf:::vp_change_in_balance_affect_power_DELEGATEE   ****************"
certoraRun $CMN certora/atoken-with-delegation/conf/token-v3-delegate-HL-rules.conf \
           --rule vp_change_in_balance_affect_power_DELEGATEE \
           --msg "7a. delegate-HL-rules vp_change_in_balance_affect_power_DELEGATEE"

echo "******** 7b. Running: token-v3-delegate-HL-rules.conf:::vp_change_of_balance_affect_power_NON_DELEGATEE   ****************"
certoraRun $CMN certora/atoken-with-delegation/conf/token-v3-delegate-HL-rules.conf \
           --rule vp_change_of_balance_affect_power_NON_DELEGATEE \
           --msg "7b. delegate-HL-rules vp_change_of_balance_affect_power_NON_DELEGATEE"

echo "******** 7c. Running: token-v3-delegate-HL-rules.conf:::pp_change_in_balance_affect_power_DELEGATEE   ****************"
certoraRun $CMN certora/atoken-with-delegation/conf/token-v3-delegate-HL-rules.conf \
           --rule pp_change_in_balance_affect_power_DELEGATEE \
           --msg "7c. delegate-HL-rules pp_change_in_balance_affect_power_DELEGATEE"

echo "******** 7d. Running: token-v3-delegate-HL-rules.conf:::pp_change_of_balance_affect_power_NON_DELEGATEE   ****************"
certoraRun $CMN certora/atoken-with-delegation/conf/token-v3-delegate-HL-rules.conf \
           --rule pp_change_of_balance_affect_power_NON_DELEGATEE \
           --msg "7d. delegate-HL-rules pp_change_of_balance_affect_power_NON_DELEGATEE"

echo "******** 8. Running: token-v3-delegate-HL-rules.conf:::other   ****************"
certoraRun $CMN certora/atoken-with-delegation/conf/token-v3-delegate-HL-rules.conf \
           --rule no_function_changes_both_balance_and_delegation_state \
           --msg "8. delegate-HL-rules other rules"

echo "******** 9. Running: rayMulDiv.conf   ****************"
certoraRun $CMN certora/atoken-with-delegation/conf/rayMulDiv.conf \
           --msg "9. rayMulDiv CVL implementation is correct"

echo "******** 10. Running: index_EQ_1.conf   ****************"
certoraRun $CMN certora/atoken-with-delegation/conf/index_EQ_1.conf \
           --msg "10. index_EQ_1"

#echo "******** Running: token-v3-community.conf   ****************"
#certoraRun $CMN certora/atoken-with-delegation/conf/token-v3-community.conf



