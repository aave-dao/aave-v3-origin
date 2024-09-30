#CMN="--compilation_steps_only"

echo "******** Running: 1  ***************"
certoraRun $CMN certora/stata/conf/verifyERC4626.conf --rule previewRedeemIndependentOfBalance  previewMintAmountCheck previewDepositIndependentOfAllowanceApprove previewWithdrawAmountCheck previewWithdrawIndependentOfBalance2 previewWithdrawIndependentOfBalance1 previewRedeemIndependentOfMaxRedeem1 previewRedeemAmountCheck previewRedeemIndependentOfMaxRedeem2 amountConversionRoundedDown withdrawCheck redeemCheck redeemATokensCheck convertToAssetsCheck convertToSharesCheck toAssetsDoesNotRevert sharesConversionRoundedDown toSharesDoesNotRevert previewDepositAmountCheck maxRedeemCompliance maxWithdrawConversionCompliance previewMintIndependentOfAllowance \
--msg "1: verifyERC4626.conf"

echo "******** Running: 1.5  ***************"
certoraRun $CMN certora/stata/conf/verifyERC4626.conf --rule maxMintMustntRevert maxDepositMustntRevert maxRedeemMustntRevert maxWithdrawMustntRevert totalAssetsMustntRevert \
--msg "1.5: verifyERC4626.conf"

echo "******** Running: 2  ***************"
certoraRun $CMN certora/stata/conf/verifyERC4626MintDepositSummarization.conf --rule depositCheckIndexGRayAssert2 depositATokensCheckIndexGRayAssert2 depositWithPermitCheckIndexGRayAssert2 depositCheckIndexERayAssert2 depositATokensCheckIndexERayAssert2 depositWithPermitCheckIndexERayAssert2 mintCheckIndexGRayUpperBound mintCheckIndexGRayLowerBound mintCheckIndexEqualsRay \
--msg "2: verifyERC4626MintDepositSummarization.conf"

echo "******** Running: 3  ***************"
certoraRun $CMN certora/stata/conf/verifyERC4626DepositSummarization.conf --rule depositCheckIndexGRayAssert1 depositATokensCheckIndexGRayAssert1 depositWithPermitCheckIndexGRayAssert1 depositCheckIndexERayAssert1 depositATokensCheckIndexERayAssert1 depositWithPermitCheckIndexERayAssert1 \
--msg "3: "

echo "******** Running: 4  ***************"
certoraRun $CMN certora/stata/conf/verifyERC4626Extended.conf --rule previewWithdrawRoundingRange previewRedeemRoundingRange amountConversionPreserved sharesConversionPreserved accountsJoiningSplittingIsLimited convertSumOfAssetsPreserved previewDepositSameAsDeposit previewMintSameAsMint maxDepositConstant \
--msg "4: "

echo "******** Running: 5  ***************"
certoraRun $CMN certora/stata/conf/verifyERC4626Extended.conf --rule redeemSum \
--msg "5: "

echo "******** Running: 6  ***************"
certoraRun $CMN certora/stata/conf/verifyERC4626Extended.conf --rule redeemATokensSum \
--msg "6: "

echo "******** Running: 7   ***************"
certoraRun $CMN certora/stata/conf/verifyAToken.conf --rule aTokenBalanceIsFixed_for_collectAndUpdateRewards aTokenBalanceIsFixed_for_claimRewards aTokenBalanceIsFixed_for_claimRewardsOnBehalf \
--msg "7: "

echo "******** Running: 8  ***************"
certoraRun $CMN certora/stata/conf/verifyAToken.conf --rule aTokenBalanceIsFixed_for_claimSingleRewardOnBehalf aTokenBalanceIsFixed_for_claimRewardsToSelf \
--msg "8: "

echo "******** Running: 9  ***************"
certoraRun $CMN certora/stata/conf/verifyStataToken.conf --rule rewardsConsistencyWhenSufficientRewardsExist \
--msg "9: "

echo "******** Running: 10  ***************"
certoraRun $CMN certora/stata/conf/verifyStataToken.conf --rule rewardsConsistencyWhenInsufficientRewards \
--msg "10: "

echo "******** Running: 11  ***************"
certoraRun $CMN certora/stata/conf/verifyStataToken.conf --rule totalClaimableRewards_stable \
--msg "11: "

echo "******** Running: 12  ***************"
certoraRun $CMN certora/stata/conf/verifyStataToken.conf --rule solvency_positive_total_supply_only_if_positive_asset \
--msg "12: "

echo "******** Running: 13  ***************"
certoraRun $CMN certora/stata/conf/verifyStataToken.conf --rule solvency_total_asset_geq_total_supply \
--msg "13: "

echo "******** Running: 14  ***************"
certoraRun $CMN certora/stata/conf/verifyStataToken.conf --rule singleAssetAccruedRewards \
--msg "14: "

echo "******** Running: 15  ***************"
certoraRun $CMN certora/stata/conf/verifyStataToken.conf --rule totalAssets_stable \
--msg "15: "

echo "******** Running: 16  ***************"
certoraRun $CMN certora/stata/conf/verifyStataToken.conf --rule getClaimableRewards_stable \
--msg "16: "

echo "******** Running: 17  ***************"
certoraRun $CMN certora/stata/conf/verifyStataToken.conf --rule getClaimableRewards_stable_after_deposit \
--msg "17: "

echo "******** Running: 18  ***************"
certoraRun $CMN certora/stata/conf/verifyStataToken.conf --rule getClaimableRewards_stable_after_refreshRewardTokens \
--msg "18: "

echo "******** Running: 19  ***************"
certoraRun $CMN certora/stata/conf/verifyStataToken.conf --rule getClaimableRewardsBefore_leq_claimed_claimRewardsOnBehalf \
--msg "19: "

echo "******** Running: 20  ***************"
certoraRun $CMN certora/stata/conf/verifyStataToken.conf --rule rewardsTotalDeclinesOnlyByClaim \
--msg "20: "

echo "******** Running: 21  ***************"
certoraRun $CMN certora/stata/conf/verifyDoubleClaim.conf --rule prevent_duplicate_reward_claiming_single_reward_sufficient \
--msg "21: "

echo "******** Running: 22  ***************"
certoraRun $CMN certora/stata/conf/verifyDoubleClaim.conf --rule prevent_duplicate_reward_claiming_single_reward_insufficient \
--msg "22: "
