#CMN="--compilation_steps_only"
#CMN="--typecheck_only"



echo "******** Running:  1 ***************"
certoraRun $CMN certora/basic/conf/AToken.conf \
           --msg "1: AToken.conf"

echo
echo "******** Running:  2 ***************"
certoraRun $CMN certora/basic/conf/ReserveConfiguration.conf \
           --msg "2: ReserveConfiguration.conf"

echo
echo "******** Running:  3 ***************"
certoraRun $CMN certora/basic/conf/UserConfiguration.conf \
           --msg "3: UserConfiguration.conf"

echo
echo "******** Running:  4 ***************"
certoraRun $CMN certora/basic/conf/VariableDebtToken.conf \
           --msg "4: VariableDebtToken.conf"

echo
echo "******** Running:  5 NEW no summarization ***************"
certoraRun $CMN certora/basic/conf/NEW-pool-no-summarizations.conf \
           --msg "5: NEW-pool-no-summarizations"

echo
echo "******** Running:  6 Stable fields are un-touched ***************"
certoraRun $CMN certora/basic/conf/stableRemoved.conf \
           --msg "6: Stable fields are un-touched"

echo
echo "******** Running:  7 EModeConfiguration ***************"
certoraRun $CMN certora/basic/conf/EModeConfiguration.conf \
           --msg "7: EModeConfiguration"


echo
echo "******** Running:  simple:1 ***************"
certoraRun $CMN certora/basic/conf/NEW-pool-simple-properties.conf \
           --rule cannotDepositInInactiveReserve \
           --msg "simple:1: NEW :: cannotDepositInInactiveReserve"

echo
echo "******** Running:  simple:2 ***************"
certoraRun $CMN certora/basic/conf/NEW-pool-simple-properties.conf \
           --rule cannotDepositInFrozenReserve \
           --msg "simple:2: NEW :: cannotDepositInFrozenReserve"

echo
echo "******** Running:  simple:3 ***************"
certoraRun $CMN certora/basic/conf/NEW-pool-simple-properties.conf \
           --rule cannotDepositZeroAmount \
           --msg "simple:3: NEW :: cannotDepositZeroAmount"

echo
echo "******** Running:  simple:4 ***************"
certoraRun $CMN certora/basic/conf/NEW-pool-simple-properties.conf \
           --rule cannotWithdrawZeroAmount \
           --msg "simple:4: NEW :: cannotWithdrawZeroAmount"

echo
echo "******** Running:  simple:5 ***************"
certoraRun $CMN certora/basic/conf/NEW-pool-simple-properties.conf \
           --rule cannotWithdrawFromInactiveReserve \
           --msg "simple:5: NEW :: cannotWithdrawFromInactiveReserve"

echo
echo "******** Running:  simple:6 ***************"
certoraRun $CMN certora/basic/conf/NEW-pool-simple-properties.conf \
           --rule cannotBorrowZeroAmount \
           --rule_sanity none \
           --msg "simple:6: NEW :: cannotBorrowZeroAmount"

echo
echo "******** Running:  simple:7 ***************"
certoraRun $CMN certora/basic/conf/NEW-pool-simple-properties.conf \
           --rule cannotBorrowOnInactiveReserve \
           --rule_sanity none \
           --msg "simple:7: NEW :: cannotBorrowOnInactiveReserve"

echo
echo "******** Running:  simple:8 ***************"
certoraRun $CMN certora/basic/conf/NEW-pool-simple-properties.conf \
           --rule cannotBorrowOnReserveDisabledForBorrowing \
           --rule_sanity none \
           --msg "simple:8: NEW :: cannotBorrowOnReserveDisabledForBorrowing"

echo
echo "******** Running:  simple:9 ***************"
certoraRun $CMN certora/basic/conf/NEW-pool-simple-properties.conf \
           --rule cannotBorrowOnFrozenReserve \
           --rule_sanity none \
           --msg "simple:9: NEW :: cannotBorrowOnFrozenReserve"


