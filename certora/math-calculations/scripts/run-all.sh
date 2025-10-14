#CMN="--compilation_steps_only"



echo "******** Running:  1 ***************"
certoraRun $CMN certora/math-calculations/confs/rayMulDiv-CVL-check.conf \
           --msg "1: rayMulDiv-CVL-check.conf"

echo "******** Running:  2 ***************"
certoraRun $CMN certora/math-calculations/confs/gift_cannot_decrease_healthFactor.conf \
           --msg "2: gift_cannot_decrease_healthFactor.conf"

#echo "******** Running:  3 ***************"
#certoraRun $CMN certora/math-calculations/confs/collateralAmount_GEQ_debtAmount.conf \
#           --msg "3: collateralAmount_GEQ_debtAmount.conf"



