#CMN="--compilation_steps_only"



echo "******** Running:  1a ***************"
certoraRun $CMN certora/solvency/confs/rayMulDiv-CVL-check.conf \
           --msg "1a: rayMulDiv-CVL-check.conf"

echo "******** Running:  1b ***************"
certoraRun $CMN certora/solvency/confs/aToken-check.conf \
           --msg "1b: aToken-check.conf"

echo "******** Running:  1c ***************"
certoraRun $CMN certora/solvency/confs/variableDebtToken-check.conf \
           --msg "1c: variableDebtToken-check.conf"


echo "******** Running:  2 ***************"
certoraRun $CMN certora/solvency/confs/solvency/supply.conf \
           --msg "2: supply.conf"

echo "******** Running:  3 ***************"
certoraRun $CMN certora/solvency/confs/solvency/withdraw.conf \
           --msg "3: withdraw.conf"

echo "******** Running:  4 ***************"
certoraRun $CMN certora/solvency/confs/solvency/borrow.conf \
           --msg "4: borrow.conf"

echo "******** Running:  5 ***************"
certoraRun $CMN certora/solvency/confs/solvency/flashloan.conf \
           --msg "5: flashloan.conf"


echo "******** Running:  6a ***************"
certoraRun $CMN certora/solvency/confs/solvency/repay-lemma.conf \
           --msg "6a: repay-lemma.conf"

echo "******** Running:  6b ***************"
certoraRun $CMN certora/solvency/confs/solvency/repay-main.conf \
           --msg "6b: repay-main.conf"


echo "******** Running:  7a ***************"
certoraRun $CMN certora/solvency/confs/solvency/repayWithATokens-lemma.conf \
           --msg "7a: repayWithATokens-lemma.conf"

echo "******** Running:  7b ***************"
certoraRun $CMN certora/solvency/confs/solvency/repayWithATokens-main.conf \
           --rule_sanity "none" \
           --msg "7b: repayWithATokens-main.conf === NO-SANITY ==="

echo "******** Running:  8 ***************"
certoraRun $CMN certora/solvency/confs/solvency/eliminateReserveDeficit.conf \
           --msg "8: eliminateReserveDeficit.conf"

echo "******** Running:  9 ***************"
certoraRun $CMN certora/solvency/confs/solvency/syncIndexesState.conf \
           --msg "9: syncIndexesState.conf"




echo "******** Running:  liqCALL-a ***************"
certoraRun $CMN certora/solvency/confs/solvency/liquidationCall/lemma-revertsIF_totDbt_of_DBTasset_is0.conf \
           --msg "liqCALL-a: liquidationCall/lemma-DBTasset-totSUP0.conf"

echo "******** Running:  liqCALL-b ***************"
certoraRun $CMN certora/solvency/confs/solvency/liquidationCall/lemma-DBTasset.conf \
           --msg "liqCALL-b: liquidationCall/lemma-DBTasset.conf"

echo "******** Running:  liqCALL-c ***************"
certoraRun $CMN certora/solvency/confs/solvency/liquidationCall/main-DBTasset.conf \
           --msg "liqCALL-c: liquidationCall/main-DBTasset.conf"



echo "******** Running:  liqCALL-d ***************"
certoraRun $CMN certora/solvency/confs/solvency/liquidationCall/main-COLasset.conf \
           --msg "liqCALL-d: liquidationCall/main-COLasset.conf"

echo "******** Running:  liqCALL-e ***************"
certoraRun $CMN certora/solvency/confs/solvency/liquidationCall/lemma-COLasset.conf \
           --rule_sanity "none" \
           --msg "liqCALL-e: liquidationCall/lemma-COLasset.conf     === NO-SANITY ==="

echo "******** Running:  liqCALL-f ***************"
certoraRun $CMN certora/solvency/confs/solvency/liquidationCall/main-COLasset-totSUP0.conf \
           --rule_sanity "none" \
           --msg "liqCALL-f: liquidationCall/main-COLasset-totSUP0.conf     === NO-SANITY ==="

echo "******** Running:  liqCALL-g ***************"
certoraRun $CMN certora/solvency/confs/solvency/liquidationCall/lemma-COLasset-totSUP0.conf \
           --msg "liqCALL-g: liquidationCall/lemma-COLasset-totSUP0.conf"



echo "******** Running:  liqCALL-h ***************"
certoraRun $CMN certora/solvency/confs/solvency/liquidationCall/burnBadDebt-assetINloop.conf \
           --msg "liqCALL-h: liquidationCall/burnBadDebt-assetINloop.conf"

echo "******** Running:  liqCALL-i ***************"
certoraRun $CMN certora/solvency/confs/solvency/liquidationCall/burnBadDebt-assetNOTINloop.conf \
           --msg "liqCALL-i: liquidationCall/burnBadDebt-assetNOTINloop.conf"


echo "******** Running:  liqCALL-j ***************"
certoraRun $CMN certora/solvency/confs/solvency/liquidationCall/main-SAMEasset.conf \
           --msg "liqCALL-j: liquidationCall/main-SAMEasset.conf"

echo "******** Running:  liqCALL-k ***************"
certoraRun $CMN certora/solvency/confs/solvency/liquidationCall/lemma-SAMEasset.conf \
           --msg "liqCALL-k: liquidationCall/lemma-SAMEasset.conf"

