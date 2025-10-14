#CMN="--compilation_steps_only"

echo "******** 1. Running: token-v3-general.conf   ****************"
certoraRun $CMN certora/atoken-with-delegation/conf/token-v3-general.conf \
           --msg "1. token-v3-general.conf"

echo "******** 2. Running: token-v3-erc20.conf   ****************"
certoraRun $CMN certora/atoken-with-delegation/conf/token-v3-erc20.conf \
           --msg "2. token-v3-erc20.conf"

echo "******** 3 Running: token-v3-delegate-basic.conf   ****************"
certoraRun $CMN certora/atoken-with-delegation/conf/token-v3-delegate-basic.conf \
           --msg "3. token-v3-delegate-basic.conf"

echo "******** 4a. Running: token-v3-delegate-invariants.conf   ****************"
certoraRun $CMN certora/atoken-with-delegation/conf/token-v3-delegate-invariants.conf \
           --rule mirror_votingDelegatee_correct mirror_propositionDelegatee_correct \
           mirror_delegationMode_correct mirror_balance_correct \
           --rule_sanity "none" \
           --msg "4a. token-v3-delegate-invariants mirrors rule_sanity NONE"

echo "******** 4b. Running: token-v3-delegate-invariants.conf   ****************"
certoraRun $CMN certora/atoken-with-delegation/conf/token-v3-delegate-invariants.conf \
           --exclude_rule mirror_votingDelegatee_correct mirror_propositionDelegatee_correct mirror_delegationMode_correct mirror_balance_correct \
           --msg "4b. token-v3-delegate-invariants ALL except mirrors"



echo "******** 5a. Running: token-v3-delegate-HL-rules.conf:::vp_change_in_balance_affect_power_DELEGATEE   ****************"
certoraRun $CMN certora/atoken-with-delegation/conf/token-v3-delegate-HL-rules.conf \
           --rule vp_change_in_balance_affect_power_DELEGATEE \
           --msg "5a. token-v3-delegate-HL-rules vp_change_in_balance_affect_power_DELEGATEE"

echo "******** 5b. Running: token-v3-delegate-HL-rules.conf:::vp_change_of_balance_affect_power_NON_DELEGATEE   ****************"
certoraRun $CMN certora/atoken-with-delegation/conf/token-v3-delegate-HL-rules.conf \
           --rule vp_change_of_balance_affect_power_NON_DELEGATEE \
           --msg "5b. token-v3-delegate-HL-rules.conf vp_change_of_balance_affect_power_NON_DELEGATEE"

echo "******** 5c. Running: token-v3-delegate-HL-rules.conf:::pp_change_in_balance_affect_power_DELEGATEE   ****************"
certoraRun $CMN certora/atoken-with-delegation/conf/token-v3-delegate-HL-rules.conf \
           --rule pp_change_in_balance_affect_power_DELEGATEE \
           --msg "5c. token-v3-delegate-HL-rules pp_change_in_balance_affect_power_DELEGATEE"

echo "******** 5d. Running: token-v3-delegate-HL-rules.conf:::pp_change_of_balance_affect_power_NON_DELEGATEE   ****************"
certoraRun $CMN certora/atoken-with-delegation/conf/token-v3-delegate-HL-rules.conf \
           --rule pp_change_of_balance_affect_power_NON_DELEGATEE \
           --msg "5d. delegate-HL-rules pp_change_of_balance_affect_power_NON_DELEGATEE"

echo "******** 6. Running: token-v3-delegate-HL-rules.conf:::other   ****************"
certoraRun $CMN certora/atoken-with-delegation/conf/token-v3-delegate-HL-rules.conf \
           --rule no_function_changes_both_balance_and_delegation_state \
           --msg "6. delegate-HL-rules other rules"

echo "******** 7. Running: rayMulDiv.conf   ****************"
certoraRun $CMN certora/atoken-with-delegation/conf/rayMulDiv.conf \
           --msg "7. rayMulDiv CVL implementation is correct"

echo "******** 8. Running: index_EQ_1.conf   ****************"
certoraRun $CMN certora/atoken-with-delegation/conf/index_EQ_1.conf \
           --msg "8. index_EQ_1"




