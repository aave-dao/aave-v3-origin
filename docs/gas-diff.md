```diff
diff --git a/reports/gas.old b/reports/gas.new
index 0dec812..9ce5779 100644
--- a/reports/gas.old
+++ b/reports/gas.new
@@ -27,37 +27,37 @@
 | claimRewardsOnBehalf                                                                                                    | 41981           | 41981   | 41981   | 41981   | 1       |
 | claimRewardsToSelf                                                                                                      | 61212           | 143791  | 147239  | 188315  | 8       |
 | collectAndUpdateRewards                                                                                                 | 60947           | 102021  | 102021  | 143096  | 2       |
-| convertToAssets                                                                                                         | 3348            | 3493    | 3496    | 3496    | 261     |
-| convertToShares                                                                                                         | 22946           | 22946   | 22946   | 22946   | 1       |
-| createStaticATokens                                                                                                     | 2375769         | 2375769 | 2375769 | 2375769 | 46      |
+| convertToAssets                                                                                                         | 3370            | 3516    | 3518    | 3518    | 261     |
+| convertToShares                                                                                                         | 22968           | 22968   | 22968   | 22968   | 1       |
+| createStaticATokens                                                                                                     | 2375835         | 2375835 | 2375835 | 2375835 | 46      |
 | decimals                                                                                                                | 3154            | 3154    | 3154    | 3154    | 1       |
-| deposit                                                                                                                 | 216564          | 235000  | 237907  | 237919  | 22      |
+| deposit                                                                                                                 | 216608          | 235044  | 237951  | 237963  | 22      |
 | getClaimableRewards                                                                                                     | 7438            | 9046    | 7653    | 12042   | 17      |
 | getStaticAToken                                                                                                         | 1414            | 1414    | 1414    | 1414    | 52      |
 | getStaticATokens                                                                                                        | 16900           | 16900   | 16900   | 16900   | 2       |
 | getTotalClaimableRewards                                                                                                | 8608            | 10621   | 10429   | 14208   | 9       |
 | getUnclaimedRewards                                                                                                     | 1590            | 1590    | 1590    | 1590    | 2       |
-| maxDeposit                                                                                                              | 33171           | 37914   | 33690   | 44759   | 5       |
-| maxMint                                                                                                                 | 9226            | 57576   | 57765   | 57765   | 257     |
-| maxRedeem                                                                                                               | 10705           | 13359   | 14138   | 14600   | 18      |
-| maxWithdraw                                                                                                             | 14471           | 15471   | 15471   | 16471   | 2       |
-| metaDeposit                                                                                                             | 285952          | 343531  | 354571  | 390070  | 3       |
-| metaWithdraw                                                                                                            | 211664          | 211664  | 211664  | 211664  | 1       |
-| mint                                                                                                                    | 76230           | 188856  | 188856  | 301483  | 2       |
+| maxDeposit                                                                                                              | 33193           | 37936   | 33712   | 44781   | 5       |
+| maxMint                                                                                                                 | 9248            | 57620   | 57809   | 57809   | 257     |
+| maxRedeem                                                                                                               | 10727           | 13402   | 14182   | 14644   | 18      |
+| maxWithdraw                                                                                                             | 14537           | 15537   | 15537   | 16537   | 2       |
+| metaDeposit                                                                                                             | 285996          | 343575  | 354615  | 390114  | 3       |
+| metaWithdraw                                                                                                            | 211708          | 211708  | 211708  | 211708  | 1       |
+| mint                                                                                                                    | 76274           | 188911  | 188911  | 301549  | 2       |
 | name                                                                                                                    | 10556           | 10556   | 10556   | 10556   | 1       |
 | nonces                                                                                                                  | 3433            | 7147    | 9933    | 9933    | 7       |
 | permit                                                                                                                  | 31503           | 58858   | 60440   | 84631   | 3       |
-| previewDeposit                                                                                                          | 3445            | 10445   | 10945   | 16445   | 4       |
-| previewMint                                                                                                             | 3687            | 3687    | 3687    | 3687    | 1       |
-| previewRedeem                                                                                                           | 3539            | 3539    | 3539    | 3539    | 3       |
-| previewWithdraw                                                                                                         | 3662            | 3662    | 3662    | 3662    | 1       |
-| rate                                                                                                                    | 3037            | 3037    | 3037    | 3037    | 1       |
-| redeem(uint256,address,address)                                                                                         | 76729           | 231188  | 257218  | 318137  | 9       |
-| redeem(uint256,address,address,bool)                                                                                    | 181326          | 181326  | 181326  | 181326  | 1       |
+| previewDeposit                                                                                                          | 3467            | 10467   | 10967   | 16467   | 4       |
+| previewMint                                                                                                             | 3709            | 3709    | 3709    | 3709    | 1       |
+| previewRedeem                                                                                                           | 3561            | 3561    | 3561    | 3561    | 3       |
+| previewWithdraw                                                                                                         | 3684            | 3684    | 3684    | 3684    | 1       |
+| rate                                                                                                                    | 3059            | 3059    | 3059    | 3059    | 1       |
+| redeem(uint256,address,address)                                                                                         | 76773           | 231269  | 257306  | 318225  | 9       |
+| redeem(uint256,address,address,bool)                                                                                    | 181370          | 181370  | 181370  | 181370  | 1       |
 | refreshRewardTokens                                                                                                     | 128879          | 128879  | 128879  | 128879  | 33      |
 | symbol                                                                                                                  | 4143            | 4143    | 4143    | 4143    | 1       |
 | transfer                                                                                                                | 101595          | 101595  | 101595  | 101595  | 1       |
-| withdraw                                                                                                                | 239849          | 239849  | 239849  | 239849  | 1       |
+| withdraw                                                                                                                | 239959          | 239959  | 239959  | 239959  | 1       |


 | src/contracts/dependencies/weth/WETH9.sol:WETH9 contract |                 |       |        |       |         |
@@ -66,9 +66,9 @@
 | 546391                                                   | 2423            |       |        |       |         |
 | Function Name                                            | min             | avg   | median | max   | # calls |
 | allowance                                                | 803             | 803   | 803    | 803   | 20      |
-| approve                                                  | 29055           | 46249 | 46467  | 46467 | 1806    |
-| balanceOf                                                | 541             | 989   | 541    | 2541  | 9310    |
-| decimals                                                 | 2313            | 2313  | 2313   | 2313  | 636     |
+| approve                                                  | 29055           | 46246 | 46467  | 46467 | 1785    |
+| balanceOf                                                | 541             | 989   | 541    | 2541  | 9205    |
+| decimals                                                 | 2313            | 2313  | 2313   | 2313  | 632     |
 | symbol                                                   | 1213            | 2250  | 3213   | 3213  | 27      |


@@ -91,7 +91,7 @@
 | 2050064                                                                                                           | 10159           |        |        |        |         |
 | Function Name                                                                                                     | min             | avg    | median | max    | # calls |
 | owner                                                                                                             | 386             | 386    | 386    | 386    | 1       |
-| swapAndDeposit                                                                                                    | 352192          | 443390 | 475524 | 502455 | 3       |
+| swapAndDeposit                                                                                                    | 352280          | 443455 | 475577 | 502508 | 3       |


 | src/contracts/extensions/paraswap-adapters/ParaSwapRepayAdapter.sol:ParaSwapRepayAdapter contract |                 |        |        |        |         |
@@ -101,7 +101,7 @@
 | Function Name                                                                                     | min             | avg    | median | max    | # calls |
 | owner                                                                                             | 408             | 408    | 408    | 408    | 1       |
 | rescueTokens                                                                                      | 36133           | 36133  | 36133  | 36133  | 1       |
-| swapAndRepay                                                                                      | 405121          | 515303 | 535881 | 584329 | 4       |
+| swapAndRepay                                                                                      | 404879          | 515029 | 535596 | 584044 | 4       |


 | src/contracts/extensions/paraswap-adapters/ParaSwapWithdrawSwapAdapter.sol:ParaSwapWithdrawSwapAdapter contract |                 |        |        |        |         |
@@ -110,7 +110,7 @@
 | 1757703                                                                                                         | 8731            |        |        |        |         |
 | Function Name                                                                                                   | min             | avg    | median | max    | # calls |
 | owner                                                                                                           | 408             | 408    | 408    | 408    | 1       |
-| withdrawAndSwap                                                                                                 | 352139          | 378370 | 371176 | 411796 | 3       |
+| withdrawAndSwap                                                                                                 | 352227          | 378435 | 371229 | 411849 | 3       |


 | src/contracts/extensions/static-a-token/StataOracle.sol:StataOracle contract |                 |       |        |       |         |
@@ -118,8 +118,8 @@
 | Deployment Cost                                                              | Deployment Size |       |        |       |         |
 | 349225                                                                       | 1737            |       |        |       |         |
 | Function Name                                                                | min             | avg   | median | max   | # calls |
-| getAssetPrice                                                                | 14792           | 14877 | 14792  | 36792 | 257     |
-| getAssetsPrices                                                              | 87496           | 87496 | 87496  | 87496 | 1       |
+| getAssetPrice                                                                | 14814           | 14899 | 14814  | 36814 | 257     |
+| getAssetsPrices                                                              | 87562           | 87562 | 87562  | 87562 | 1       |


 | src/contracts/extensions/static-a-token/StaticATokenFactory.sol:StaticATokenFactory contract |                 |         |         |         |         |
@@ -128,10 +128,10 @@
 | 0                                                                                            | 0               |         |         |         |         |
 | Function Name                                                                                | min             | avg     | median  | max     | # calls |
 | STATIC_A_TOKEN_IMPL                                                                          | 228             | 228     | 228     | 228     | 1       |
-| createStaticATokens                                                                          | 2345990         | 2345990 | 2345990 | 2345990 | 46      |
+| createStaticATokens                                                                          | 2346056         | 2346056 | 2346056 | 2346056 | 46      |
 | getStaticAToken                                                                              | 616             | 616     | 616     | 616     | 52      |
 | getStaticATokens                                                                             | 9587            | 9587    | 9587    | 9587    | 2       |
-| initialize                                                                                   | 24131           | 24131   | 24131   | 24131   | 624     |
+| initialize                                                                                   | 24131           | 24131   | 24131   | 24131   | 620     |


 | src/contracts/extensions/static-a-token/StaticATokenLM.sol:StaticATokenLM contract |                 |        |        |        |         |
@@ -153,35 +153,35 @@
 | claimRewardsOnBehalf                                                               | 12204           | 12204  | 12204  | 12204  | 1       |
 | claimRewardsToSelf                                                                 | 32183           | 127811 | 128173 | 179199 | 8       |
 | collectAndUpdateRewards                                                            | 32217           | 73291  | 73291  | 114366 | 2       |
-| convertToAssets                                                                    | 2550            | 2695   | 2698   | 2698   | 261     |
-| convertToShares                                                                    | 15648           | 15648  | 15648  | 15648  | 1       |
+| convertToAssets                                                                    | 2572            | 2718   | 2720   | 2720   | 261     |
+| convertToShares                                                                    | 15670           | 15670  | 15670  | 15670  | 1       |
 | decimals                                                                           | 2359            | 2359   | 2359   | 2359   | 1       |
-| deposit                                                                            | 196987          | 215388 | 218294 | 218294 | 22      |
+| deposit                                                                            | 197031          | 215432 | 218338 | 218338 | 22      |
 | getClaimableRewards                                                                | 6637            | 8244   | 6852   | 11241  | 17      |
 | getTotalClaimableRewards                                                           | 7810            | 9823   | 9631   | 13410  | 9       |
 | getUnclaimedRewards                                                                | 789             | 789    | 789    | 789    | 2       |
 | initialize                                                                         | 25757           | 181941 | 180780 | 187780 | 139     |
-| maxDeposit                                                                         | 25873           | 30616  | 26392  | 37461  | 5       |
-| maxMint                                                                            | 8428            | 50303  | 50467  | 50467  | 257     |
-| maxRedeem                                                                          | 9907            | 12561  | 13340  | 13802  | 18      |
-| maxWithdraw                                                                        | 13673           | 14673  | 14673  | 15673  | 2       |
-| metaDeposit                                                                        | 272703          | 338943 | 347430 | 396697 | 3       |
-| metaWithdraw                                                                       | 180770          | 180770 | 180770 | 180770 | 1       |
-| mint                                                                               | 47284           | 169867 | 169867 | 292450 | 2       |
+| maxDeposit                                                                         | 25895           | 30638  | 26414  | 37483  | 5       |
+| maxMint                                                                            | 8450            | 50347  | 50511  | 50511  | 257     |
+| maxRedeem                                                                          | 9929            | 12604  | 13384  | 13846  | 18      |
+| maxWithdraw                                                                        | 13739           | 14739  | 14739  | 15739  | 2       |
+| metaDeposit                                                                        | 272747          | 338987 | 347474 | 396741 | 3       |
+| metaWithdraw                                                                       | 180814          | 180814 | 180814 | 180814 | 1       |
+| mint                                                                               | 47328           | 169922 | 169922 | 292516 | 2       |
 | name                                                                               | 3255            | 3255   | 3255   | 3255   | 1       |
 | nonces                                                                             | 2635            | 2635   | 2635   | 2635   | 7       |
 | permit                                                                             | 834             | 28265  | 29975  | 53987  | 3       |
-| previewDeposit                                                                     | 2647            | 9647   | 10147  | 15647  | 4       |
-| previewMint                                                                        | 2889            | 2889   | 2889   | 2889   | 1       |
-| previewRedeem                                                                      | 2741            | 2741   | 2741   | 2741   | 3       |
-| previewWithdraw                                                                    | 2864            | 2864   | 2864   | 2864   | 1       |
-| rate                                                                               | 2242            | 2242   | 2242   | 2242   | 1       |
-| redeem(uint256,address,address)                                                    | 47400           | 211478 | 237511 | 293630 | 9       |
-| redeem(uint256,address,address,bool)                                               | 166282          | 166282 | 166282 | 166282 | 1       |
+| previewDeposit                                                                     | 2669            | 9669   | 10169  | 15669  | 4       |
+| previewMint                                                                        | 2911            | 2911   | 2911   | 2911   | 1       |
+| previewRedeem                                                                      | 2763            | 2763   | 2763   | 2763   | 3       |
+| previewWithdraw                                                                    | 2886            | 2886   | 2886   | 2886   | 1       |
+| rate                                                                               | 2264            | 2264   | 2264   | 2264   | 1       |
+| redeem(uint256,address,address)                                                    | 47444           | 211559 | 237599 | 293718 | 9       |
+| redeem(uint256,address,address,bool)                                               | 166326          | 166326 | 166326 | 166326 | 1       |
 | refreshRewardTokens                                                                | 100523          | 100523 | 100523 | 100523 | 33      |
 | symbol                                                                             | 3342            | 3342   | 3342   | 3342   | 1       |
 | transfer                                                                           | 72662           | 72662  | 72662  | 72662  | 1       |
-| withdraw                                                                           | 224942          | 224942 | 224942 | 224942 | 1       |
+| withdraw                                                                           | 225052          | 225052 | 225052 | 225052 | 1       |


 | src/contracts/extensions/v3-config-engine/AaveV3ConfigEngine.sol:AaveV3ConfigEngine contract |                 |         |         |         |         |
@@ -189,16 +189,16 @@
 | Deployment Cost                                                                              | Deployment Size |         |         |         |         |
 | 0                                                                                            | 0               |         |         |         |         |
 | Function Name                                                                                | min             | avg     | median  | max     | # calls |
-| DEFAULT_INTEREST_RATE_STRATEGY                                                               | 337             | 337     | 337     | 337     | 5       |
-| listAssets                                                                                   | 1844953         | 1844953 | 1844953 | 1844953 | 1       |
-| listAssetsCustom                                                                             | 1844210         | 5301679 | 5307465 | 5307465 | 620     |
-| updateAssetsEMode                                                                            | 68531           | 68531   | 68531   | 68531   | 1       |
-| updateBorrowSide                                                                             | 20079           | 76359   | 76359   | 132640  | 2       |
-| updateCaps                                                                                   | 59884           | 59884   | 59884   | 59884   | 1       |
-| updateCollateralSide                                                                         | 8777            | 30468   | 8903    | 62879   | 5       |
-| updateEModeCategories                                                                        | 11063           | 61143   | 27080   | 128256  | 5       |
-| updatePriceFeeds                                                                             | 39338           | 39338   | 39338   | 39338   | 1       |
-| updateRateStrategies                                                                         | 122092          | 122092  | 122092  | 122092  | 1       |
+| DEFAULT_INTEREST_RATE_STRATEGY                                                               | 227             | 227     | 227     | 227     | 5       |
+| listAssets                                                                                   | 1832667         | 1832667 | 1832667 | 1832667 | 1       |
+| listAssetsCustom                                                                             | 1831924         | 5264742 | 5270515 | 5270515 | 616     |
+| updateAssetsEMode                                                                            | 92916           | 92916   | 92916   | 92916   | 1       |
+| updateBorrowSide                                                                             | 20101           | 76458   | 76458   | 132816  | 2       |
+| updateCaps                                                                                   | 59883           | 59883   | 59883   | 59883   | 1       |
+| updateCollateralSide                                                                         | 8777            | 30499   | 8903    | 62957   | 5       |
+| updateEModeCategories                                                                        | 10592           | 51848   | 29691   | 104184  | 5       |
+| updatePriceFeeds                                                                             | 39360           | 39360   | 39360   | 39360   | 1       |
+| updateRateStrategies                                                                         | 122202          | 122202  | 122202  | 122202  | 1       |


 | src/contracts/helpers/AaveProtocolDataProvider.sol:AaveProtocolDataProvider contract |                 |       |        |       |         |
@@ -206,22 +206,21 @@
 | Deployment Cost                                                                      | Deployment Size |       |        |       |         |
 | 0                                                                                    | 0               |       |        |       |         |
 | Function Name                                                                        | min             | avg   | median | max   | # calls |
-| getATokenTotalSupply                                                                 | 11863           | 14153 | 11907  | 24953 | 2140    |
-| getAllReservesTokens                                                                 | 16222           | 28423 | 31722  | 39722 | 27      |
+| getATokenTotalSupply                                                                 | 11863           | 14165 | 11907  | 24975 | 2128    |
+| getAllReservesTokens                                                                 | 16155           | 28653 | 39655  | 39655 | 27      |
 | getDebtCeiling                                                                       | 3263            | 3263  | 3263   | 3263  | 4       |
-| getDebtCeilingDecimals                                                               | 237             | 237   | 237    | 237   | 1       |
+| getDebtCeilingDecimals                                                               | 215             | 215   | 215    | 215   | 1       |
 | getFlashLoanEnabled                                                                  | 3236            | 4236  | 4236   | 5236  | 512     |
-| getInterestRateStrategyAddress                                                       | 8453            | 19448 | 8453   | 39953 | 9       |
-| getIsVirtualAccActive                                                                | 3242            | 3285  | 3286   | 3286  | 8116    |
-| getLiquidationProtocolFee                                                            | 3174            | 9951  | 5674   | 16674 | 9       |
-| getPaused                                                                            | 3219            | 3325  | 3263   | 5263  | 8383    |
+| getInterestRateStrategyAddress                                                       | 8563            | 19558 | 8563   | 40063 | 9       |
+| getIsVirtualAccActive                                                                | 3242            | 3285  | 3286   | 3286  | 9373    |
+| getLiquidationProtocolFee                                                            | 3285            | 10062 | 5785   | 16785 | 9       |
+| getPaused                                                                            | 3330            | 3427  | 3374   | 5374  | 9640    |
 | getReserveCaps                                                                       | 3286            | 8168  | 3286   | 16786 | 47      |
-| getReserveConfigurationData                                                          | 3565            | 3773  | 3609   | 17109 | 9714    |
-| getReserveEModeCategory                                                              | 3199            | 3199  | 3199   | 3199  | 1       |
-| getReserveTokensAddresses                                                            | 8541            | 14283 | 14585  | 40085 | 9574    |
+| getReserveConfigurationData                                                          | 3662            | 3851  | 3706   | 17206 | 10968   |
+| getReserveTokensAddresses                                                            | 8541            | 14320 | 14585  | 40085 | 10826   |
 | getSiloedBorrowing                                                                   | 3289            | 3289  | 3289   | 3289  | 1       |
-| getTotalDebt                                                                         | 51955           | 51955 | 51955  | 51955 | 3       |
-| getUserReserveData                                                                   | 18944           | 26800 | 27034  | 43944 | 1302    |
+| getTotalDebt                                                                         | 51890           | 51890 | 51890  | 51890 | 3       |
+| getUserReserveData                                                                   | 18988           | 26798 | 27013  | 43988 | 1301    |


 | src/contracts/helpers/L2Encoder.sol:L2Encoder contract |                 |       |        |       |         |
@@ -229,15 +228,15 @@
 | Deployment Cost                                        | Deployment Size |       |        |       |         |
 | 0                                                      | 0               |       |        |       |         |
 | Function Name                                          | min             | avg   | median | max   | # calls |
-| encodeBorrowParams                                     | 7859            | 7859  | 7859   | 7859  | 3       |
-| encodeLiquidationCall                                  | 19245           | 19245 | 19245  | 19245 | 1       |
-| encodeRepayParams                                      | 7742            | 7742  | 7742   | 7742  | 1       |
-| encodeRepayWithATokensParams                           | 7770            | 7770  | 7770   | 7770  | 1       |
-| encodeRepayWithPermitParams                            | 10231           | 10231 | 10231  | 10231 | 256     |
-| encodeSetUserUseReserveAsCollateral                    | 7679            | 7679  | 7679   | 7679  | 1       |
-| encodeSupplyParams                                     | 34785           | 34785 | 34785  | 34785 | 7       |
-| encodeSupplyWithPermitParams                           | 35144           | 35144 | 35144  | 35144 | 256     |
-| encodeWithdrawParams                                   | 7625            | 7659  | 7659   | 7693  | 2       |
+| encodeBorrowParams                                     | 7881            | 7881  | 7881   | 7881  | 3       |
+| encodeLiquidationCall                                  | 19289           | 19289 | 19289  | 19289 | 1       |
+| encodeRepayParams                                      | 7764            | 7764  | 7764   | 7764  | 1       |
+| encodeRepayWithATokensParams                           | 7792            | 7792  | 7792   | 7792  | 1       |
+| encodeRepayWithPermitParams                            | 10253           | 10253 | 10253  | 10253 | 256     |
+| encodeSetUserUseReserveAsCollateral                    | 7701            | 7701  | 7701   | 7701  | 1       |
+| encodeSupplyParams                                     | 34807           | 34807 | 34807  | 34807 | 7       |
+| encodeSupplyWithPermitParams                           | 35166           | 35166 | 35166  | 35166 | 256     |
+| encodeWithdrawParams                                   | 7647            | 7681  | 7681   | 7715  | 2       |


 | src/contracts/helpers/WrappedTokenGatewayV3.sol:WrappedTokenGatewayV3 contract |                 |        |        |        |         |
@@ -245,16 +244,16 @@
 | Deployment Cost                                                                | Deployment Size |        |        |        |         |
 | 0                                                                              | 0               |        |        |        |         |
 | Function Name                                                                  | min             | avg    | median | max    | # calls |
-| borrowETH                                                                      | 253365          | 253365 | 253365 | 253365 | 1       |
+| borrowETH                                                                      | 253033          | 253033 | 253033 | 253033 | 1       |
 | depositETH                                                                     | 240170          | 240170 | 240170 | 240170 | 8       |
 | emergencyEtherTransfer                                                         | 33801           | 33801  | 33801  | 33801  | 1       |
 | emergencyTokenTransfer                                                         | 52810           | 52810  | 52810  | 52810  | 1       |
 | getWETHAddress                                                                 | 245             | 245    | 245    | 245    | 1       |
 | owner                                                                          | 308             | 308    | 308    | 308    | 1       |
 | receive                                                                        | 21206           | 21206  | 21206  | 21206  | 1       |
-| repayETH                                                                       | 175754          | 179762 | 177644 | 187475 | 5       |
-| withdrawETH                                                                    | 231257          | 235319 | 235319 | 239381 | 2       |
-| withdrawETHWithPermit                                                          | 275525          | 278408 | 278408 | 281291 | 2       |
+| repayETH                                                                       | 175668          | 179676 | 177558 | 187389 | 5       |
+| withdrawETH                                                                    | 231328          | 235398 | 235398 | 239469 | 2       |
+| withdrawETHWithPermit                                                          | 275613          | 278496 | 278496 | 281379 | 2       |


 | src/contracts/instances/ATokenInstance.sol:ATokenInstance contract |                 |        |        |        |         |
@@ -264,35 +263,35 @@
 | Function Name                                                      | min             | avg    | median | max    | # calls |
 | DOMAIN_SEPARATOR                                                   | 458             | 2275   | 2458   | 3543   | 5       |
 | POOL                                                               | 327             | 327    | 327    | 327    | 151     |
-| RESERVE_TREASURY_ADDRESS                                           | 420             | 783    | 420    | 2420   | 9917    |
-| UNDERLYING_ASSET_ADDRESS                                           | 442             | 475    | 442    | 2442   | 8251    |
+| RESERVE_TREASURY_ADDRESS                                           | 420             | 742    | 420    | 2420   | 11173   |
+| UNDERLYING_ASSET_ADDRESS                                           | 442             | 471    | 442    | 2442   | 9508    |
 | allowance                                                          | 785             | 1554   | 785    | 2785   | 26      |
 | approve                                                            | 24590           | 24590  | 24590  | 24590  | 39      |
-| balanceOf                                                          | 2744            | 5319   | 4744   | 17744  | 4799    |
-| burn                                                               | 911             | 35660  | 37180  | 81176  | 2111    |
-| decimals                                                           | 357             | 403    | 357    | 2357   | 8304    |
+| balanceOf                                                          | 2766            | 5342   | 4766   | 17766  | 4796    |
+| burn                                                               | 911             | 35659  | 37180  | 81176  | 2110    |
+| decimals                                                           | 357             | 397    | 357    | 2357   | 9561    |
 | decreaseAllowance                                                  | 7709            | 7709   | 7709   | 7709   | 1       |
-| getIncentivesController                                            | 475             | 475    | 475    | 2475   | 8116    |
+| getIncentivesController                                            | 475             | 475    | 475    | 2475   | 9373    |
 | getPreviousIndex                                                   | 654             | 654    | 654    | 654    | 39      |
 | getScaledUserBalanceAndSupply                                      | 830             | 2419   | 2830   | 4830   | 39      |
-| handleRepayment                                                    | 597             | 597    | 597    | 597    | 2599    |
+| handleRepayment                                                    | 597             | 597    | 597    | 597    | 2598    |
 | increaseAllowance                                                  | 7776            | 20601  | 24876  | 24876  | 4       |
-| initialize                                                         | 146515          | 228079 | 231709 | 321646 | 43251   |
-| mint                                                               | 940             | 59706  | 64435  | 72198  | 4166    |
+| initialize                                                         | 146515          | 231136 | 231709 | 321646 | 44496   |
+| mint                                                               | 940             | 60222  | 64435  | 72198  | 4676    |
 | mintToTreasury                                                     | 444             | 43943  | 49223  | 66323  | 6       |
-| name                                                               | 1009            | 1454   | 1326   | 3264   | 8351    |
+| name                                                               | 1009            | 1448   | 1326   | 3264   | 9608    |
 | nonces                                                             | 655             | 1988   | 2655   | 2655   | 9       |
 | permit                                                             | 1117            | 33566  | 43549  | 53499  | 16      |
 | rescueTokens                                                       | 12040           | 24418  | 14258  | 46957  | 3       |
-| scaledBalanceOf                                                    | 691             | 1986   | 2691   | 2691   | 10419   |
+| scaledBalanceOf                                                    | 691             | 1933   | 2691   | 2691   | 11720   |
 | scaledTotalSupply                                                  | 375             | 2181   | 2375   | 2375   | 414     |
 | setIncentivesController                                            | 11941           | 14316  | 14316  | 16691  | 2       |
-| symbol                                                             | 1074            | 1515   | 1391   | 3329   | 8333    |
-| totalSupply                                                        | 411             | 4892   | 6457   | 10457  | 4903    |
-| transfer                                                           | 580             | 117377 | 122690 | 140646 | 275     |
-| transferFrom                                                       | 87624           | 120965 | 130243 | 145830 | 43      |
-| transferOnLiquidation                                              | 988             | 30249  | 37526  | 44326  | 1807    |
-| transferUnderlyingTo                                               | 802             | 18573  | 16500  | 33639  | 2704    |
+| symbol                                                             | 1074            | 1513   | 1391   | 3329   | 9590    |
+| totalSupply                                                        | 411             | 4985   | 6479   | 10479  | 5146    |
+| transfer                                                           | 580             | 116801 | 122712 | 140404 | 275     |
+| transferFrom                                                       | 87646           | 120962 | 130265 | 145587 | 43      |
+| transferOnLiquidation                                              | 988             | 30267  | 37548  | 44348  | 1806    |
+| transferUnderlyingTo                                               | 802             | 19862  | 16500  | 33639  | 2959    |


 | src/contracts/instances/L2PoolInstance.sol:L2PoolInstance contract |                 |        |        |        |         |
@@ -302,154 +301,155 @@
 | Function Name                                                      | min             | avg    | median | max    | # calls |
 | ADDRESSES_PROVIDER                                                 | 352             | 352    | 352    | 352    | 126     |
 | FLASHLOAN_PREMIUM_TOTAL                                            | 389             | 1389   | 1389   | 2389   | 124     |
-| FLASHLOAN_PREMIUM_TO_PROTOCOL                                      | 482             | 482    | 482    | 482    | 124     |
-| borrow(address,uint256,uint256,uint16,address)                     | 198181          | 204033 | 203781 | 238990 | 266     |
-| borrow(bytes32)                                                    | 203802          | 203802 | 203802 | 203802 | 3       |
-| configureEModeCategory                                             | 7230            | 8196   | 7230   | 49447  | 262     |
-| dropReserve                                                        | 6336            | 6631   | 6336   | 82330  | 257     |
-| getBorrowLogic                                                     | 282             | 282    | 282    | 282    | 1       |
+| FLASHLOAN_PREMIUM_TO_PROTOCOL                                      | 415             | 415    | 415    | 415    | 124     |
+| borrow(address,uint256,uint256,uint16,address)                     | 197850          | 203970 | 203450 | 238567 | 266     |
+| borrow(bytes32)                                                    | 203449          | 203449 | 203449 | 203449 | 3       |
+| configureEModeCategory                                             | 7310            | 8476   | 7310   | 51792  | 276     |
+| dropReserve                                                        | 6270            | 6565   | 6270   | 82286  | 257     |
+| getBorrowLogic                                                     | 304             | 304    | 304    | 304    | 1       |
 | getBridgeLogic                                                     | 346             | 346    | 346    | 346    | 1       |
-| getConfiguration                                                   | 682             | 728    | 682    | 2682   | 1636    |
-| getEModeCategoryData                                               | 6141            | 6141   | 6141   | 6141   | 12      |
+| getConfiguration                                                   | 704             | 714    | 704    | 2704   | 1462    |
+| getEModeCategoryData                                               | 8379            | 8379   | 8379   | 8379   | 14      |
 | getEModeLogic                                                      | 279             | 279    | 279    | 279    | 1       |
-| getFlashLoanLogic                                                  | 348             | 348    | 348    | 348    | 1       |
-| getLiquidationGracePeriod                                          | 2659            | 2659   | 2659   | 2659   | 256     |
-| getLiquidationLogic                                                | 326             | 326    | 326    | 326    | 1       |
-| getPoolLogic                                                       | 303             | 303    | 303    | 303    | 1       |
-| getReserveData                                                     | 4195            | 11606  | 6195   | 24195  | 839     |
-| getReserveNormalizedIncome                                         | 892             | 893    | 892    | 1354   | 292     |
-| getReserveNormalizedVariableDebt                                   | 849             | 868    | 849    | 2849   | 264     |
-| getReservesList                                                    | 11117           | 11117  | 11117  | 11117  | 262     |
-| getSupplyLogic                                                     | 368             | 368    | 368    | 368    | 1       |
-| getUserAccountData                                                 | 22727           | 22727  | 22727  | 22727  | 1       |
-| getVirtualUnderlyingBalance                                        | 682             | 682    | 682    | 682    | 4       |
-| initReserve                                                        | 6553            | 41017  | 6553   | 167529 | 656     |
-| initialize                                                         | 45403           | 45403  | 45403  | 45403  | 62      |
-| liquidationCall                                                    | 377264          | 377264 | 377264 | 377264 | 1       |
-| mintToTreasury                                                     | 77299           | 78694  | 78694  | 80089  | 2       |
-| repay(address,uint256,uint256,address)                             | 164697          | 164697 | 164697 | 164697 | 2       |
-| repay(bytes32)                                                     | 135689          | 135689 | 135689 | 135689 | 1       |
-| repayWithATokens                                                   | 138810          | 138810 | 138810 | 138810 | 1       |
-| repayWithPermit                                                    | 183122          | 199089 | 206994 | 210215 | 256     |
-| rescueTokens                                                       | 48197           | 48197  | 48197  | 48197  | 256     |
+| getFlashLoanLogic                                                  | 281             | 281    | 281    | 281    | 1       |
+| getLiquidationGracePeriod                                          | 2681            | 2681   | 2681   | 2681   | 256     |
+| getLiquidationLogic                                                | 348             | 348    | 348    | 348    | 1       |
+| getPoolLogic                                                       | 325             | 325    | 325    | 325    | 1       |
+| getReserveData                                                     | 4217            | 11834  | 6217   | 24217  | 853     |
+| getReserveNormalizedIncome                                         | 827             | 828    | 827    | 1289   | 292     |
+| getReserveNormalizedVariableDebt                                   | 871             | 890    | 871    | 2871   | 264     |
+| getReservesList                                                    | 11139           | 11139  | 11139  | 11139  | 256     |
+| getSupplyLogic                                                     | 282             | 282    | 282    | 282    | 1       |
+| getUserAccountData                                                 | 22396           | 22396  | 22396  | 22396  | 1       |
+| getVirtualUnderlyingBalance                                        | 704             | 704    | 704    | 704    | 4       |
+| initReserve                                                        | 6575            | 41039  | 6575   | 167551 | 656     |
+| initialize                                                         | 45425           | 45425  | 45425  | 45425  | 62      |
+| liquidationCall                                                    | 376891          | 376891 | 376891 | 376891 | 1       |
+| mintToTreasury                                                     | 77321           | 78716  | 78716  | 80111  | 2       |
+| repay(address,uint256,uint256,address)                             | 164652          | 164652 | 164652 | 164652 | 2       |
+| repay(bytes32)                                                     | 135733          | 135733 | 135733 | 135733 | 1       |
+| repayWithATokens                                                   | 138767          | 138767 | 138767 | 138767 | 1       |
+| repayWithPermit                                                    | 183077          | 199368 | 206950 | 210170 | 256     |
+| rescueTokens                                                       | 48219           | 48219  | 48219  | 48219  | 256     |
 | resetIsolationModeTotalDebt                                        | 4276            | 5590   | 6269   | 15276  | 402     |
-| setConfiguration                                                   | 2178            | 4409   | 2178   | 24334  | 2004    |
-| setLiquidationGracePeriod                                          | 6352            | 11369  | 10840  | 17003  | 768     |
-| setReserveInterestRateStrategyAddress                              | 6394            | 7969   | 6503   | 15791  | 769     |
-| setUserEMode                                                       | 22040           | 42082  | 40260  | 87614  | 7       |
-| setUserUseReserveAsCollateral(address,bool)                        | 53653           | 69628  | 71674  | 103062 | 17      |
-| setUserUseReserveAsCollateral(bytes32)                             | 73824           | 73824  | 73824  | 73824  | 1       |
-| supply(address,uint256,address,uint16)                             | 157289          | 207630 | 208589 | 208589 | 284     |
+| setConfiguration                                                   | 2178            | 4547   | 2178   | 24334  | 1848    |
+| setLiquidationGracePeriod                                          | 6374            | 11387  | 10862  | 17025  | 768     |
+| setReserveInterestRateStrategyAddress                              | 6416            | 7991   | 6525   | 15813  | 769     |
+| setUserEMode                                                       | 19813           | 42071  | 40892  | 87328  | 7       |
+| setUserUseReserveAsCollateral(address,bool)                        | 53610           | 69578  | 71631  | 102908 | 17      |
+| setUserUseReserveAsCollateral(bytes32)                             | 73781           | 73781  | 73781  | 73781  | 1       |
+| supply(address,uint256,address,uint16)                             | 157311          | 207652 | 208611 | 208611 | 284     |
 | supply(bytes32)                                                    | 210669          | 210669 | 210669 | 210669 | 7       |
-| supplyWithPermit                                                   | 259858          | 259858 | 259858 | 259858 | 256     |
-| syncIndexesState                                                   | 7317            | 13950  | 7317   | 27217  | 144     |
-| syncRatesState                                                     | 16050           | 16050  | 16050  | 16050  | 144     |
-| updateBridgeProtocolFee                                            | 6240            | 6240   | 6240   | 6240   | 256     |
-| updateFlashloanPremiums                                            | 1749            | 8143   | 6422   | 21649  | 380     |
-| withdraw                                                           | 126597          | 129039 | 129039 | 131482 | 2       |
+| supplyWithPermit                                                   | 259880          | 259880 | 259880 | 259880 | 256     |
+| syncIndexesState                                                   | 7251            | 13884  | 7251   | 27151  | 144     |
+| syncRatesState                                                     | 16072           | 16072  | 16072  | 16072  | 144     |
+| updateBridgeProtocolFee                                            | 6262            | 6262   | 6262   | 6262   | 256     |
+| updateFlashloanPremiums                                            | 1771            | 8165   | 6444   | 21671  | 380     |
+| withdraw                                                           | 126619          | 129061 | 129061 | 131504 | 2       |


 | src/contracts/instances/PoolConfiguratorInstance.sol:PoolConfiguratorInstance contract |                 |          |         |           |         |
 |----------------------------------------------------------------------------------------|-----------------|----------|---------|-----------|---------|
 | Deployment Cost                                                                        | Deployment Size |          |         |           |         |
-| 4442338                                                                                | 20353           |          |         |           |         |
+| 4446007                                                                                | 20370           |          |         |           |         |
 | Function Name                                                                          | min             | avg      | median  | max       | # calls |
-| MAX_GRACE_PERIOD                                                                       | 305             | 305      | 305     | 305       | 1792    |
-| configureReserveAsCollateral                                                           | 12205           | 26298    | 17314   | 95608     | 4169    |
-| disableLiquidationGracePeriod                                                          | 17326           | 28493    | 39617   | 39617     | 513     |
-| dropReserve                                                                            | 14069           | 14927    | 14069   | 104794    | 261     |
-| getConfiguratorLogic                                                                   | 240             | 240      | 240     | 240       | 1       |
-| getPendingLtv                                                                          | 599             | 599      | 599     | 599       | 771     |
-| initReserves                                                                           | 17491           | 25585884 | 1659867 | 216850380 | 2670    |
-| initialize                                                                             | 72581           | 90426    | 90481   | 90481     | 651     |
-| setAssetEModeCategory                                                                  | 11337           | 12907    | 11403   | 52868     | 2156    |
-| setBorrowCap                                                                           | 11197           | 12183    | 11263   | 44219     | 2126    |
-| setBorrowableInIsolation                                                               | 10808           | 11146    | 10874   | 43820     | 1872    |
-| setDebtCeiling                                                                         | 17279           | 39386    | 39794   | 94867     | 2133    |
-| setEModeCategory                                                                       | 17852           | 27224    | 17852   | 107759    | 297     |
-| setLiquidationProtocolFee                                                              | 11246           | 11455    | 11312   | 44268     | 1867    |
-| setPoolPause(bool)                                                                     | 17312           | 17735    | 17312   | 90088     | 515     |
-| setPoolPause(bool,uint40)                                                              | 17337           | 61920    | 48309   | 107843    | 512     |
-| setReserveActive                                                                       | 14202           | 17104    | 14202   | 91368     | 267     |
-| setReserveBorrowing                                                                    | 10894           | 17630    | 11116   | 41770     | 2628    |
-| setReserveFactor                                                                       | 17302           | 40360    | 36815   | 125123    | 2118    |
-| setReserveFlashLoaning                                                                 | 10959           | 17722    | 11025   | 43991     | 2373    |
-| setReserveFreeze                                                                       | 20558           | 48100    | 52947   | 73153     | 783     |
-| setReserveInterestRateData                                                             | 17561           | 18227    | 17561   | 103603    | 258     |
-| setReserveInterestRateStrategyAddress                                                  | 17671           | 34391    | 17671   | 162415    | 300     |
-| setReservePause(address,bool)                                                          | 17348           | 17531    | 17348   | 41048     | 258     |
-| setReservePause(address,bool,uint40)                                                   | 14442           | 39080    | 47073   | 52185     | 3084    |
-| setSiloedBorrowing                                                                     | 11266           | 11497    | 11332   | 91271     | 1862    |
-| setSupplyCap                                                                           | 11199           | 12951    | 11265   | 44221     | 2139    |
-| setUnbackedMintCap                                                                     | 44189           | 44189    | 44189   | 44189     | 7       |
-| updateAToken                                                                           | 14141           | 14621    | 14141   | 137683    | 257     |
-| updateBridgeProtocolFee                                                                | 14119           | 49368    | 52080   | 52080     | 14      |
-| updateFlashloanPremiumToProtocol                                                       | 10139           | 11301    | 10139   | 36939     | 907     |
-| updateFlashloanPremiumTotal                                                            | 14136           | 27000    | 32071   | 36971     | 907     |
-| updateVariableDebtToken                                                                | 14141           | 14597    | 14141   | 131538    | 257     |
+| MAX_GRACE_PERIOD                                                                       | 261             | 261      | 261     | 261       | 1792    |
+| configureReserveAsCollateral                                                           | 12283           | 26410    | 17358   | 95708     | 4157    |
+| disableLiquidationGracePeriod                                                          | 17259           | 28403    | 39505   | 39505     | 513     |
+| dropReserve                                                                            | 14113           | 14970    | 14113   | 104795    | 261     |
+| getConfiguratorLogic                                                                   | 284             | 284      | 284     | 284       | 1       |
+| getPendingLtv                                                                          | 643             | 643      | 643     | 643       | 771     |
+| initReserves                                                                           | 17446           | 26379812 | 1659772 | 213979799 | 2666    |
+| initialize                                                                             | 72581           | 90425    | 90481   | 90481     | 647     |
+| setAssetBorrowableInEMode                                                              | 94038           | 94125    | 94126   | 94126     | 517     |
+| setAssetCollateralInEMode                                                              | 17518           | 68765    | 77122   | 77123     | 1826    |
+| setBorrowCap                                                                           | 11219           | 12208    | 11285   | 44241     | 2114    |
+| setBorrowableInIsolation                                                               | 10786           | 11126    | 10852   | 43798     | 1860    |
+| setDebtCeiling                                                                         | 17301           | 39432    | 39860   | 94933     | 2121    |
+| setEModeCategory                                                                       | 17827           | 70955    | 84268   | 84268     | 1310    |
+| setLiquidationProtocolFee                                                              | 11290           | 11499    | 11356   | 44312     | 1855    |
+| setPoolPause(bool)                                                                     | 17247           | 17670    | 17247   | 90044     | 515     |
+| setPoolPause(bool,uint40)                                                              | 17359           | 61722    | 48341   | 107751    | 512     |
+| setReserveActive                                                                       | 14224           | 17128    | 14224   | 91434     | 267     |
+| setReserveBorrowing                                                                    | 10960           | 17724    | 11182   | 41836     | 2616    |
+| setReserveFactor                                                                       | 17346           | 40438    | 36925   | 125233    | 2106    |
+| setReserveFlashLoaning                                                                 | 10959           | 17755    | 11025   | 43991     | 2361    |
+| setReserveFreeze                                                                       | 20602           | 48131    | 53013   | 73219     | 782     |
+| setReserveInterestRateData                                                             | 17605           | 18272    | 17605   | 103713    | 258     |
+| setReserveInterestRateStrategyAddress                                                  | 17626           | 34359    | 17626   | 162458    | 300     |
+| setReservePause(address,bool)                                                          | 17392           | 17575    | 17392   | 41114     | 258     |
+| setReservePause(address,bool,uint40)                                                   | 14464           | 39159    | 47072   | 52184     | 3084    |
+| setSiloedBorrowing                                                                     | 11332           | 11564    | 11398   | 91272     | 1850    |
+| setSupplyCap                                                                           | 11176           | 12931    | 11242   | 44198     | 2127    |
+| setUnbackedMintCap                                                                     | 44233           | 44233    | 44233   | 44233     | 7       |
+| updateAToken                                                                           | 14074           | 14554    | 14074   | 137640    | 257     |
+| updateBridgeProtocolFee                                                                | 14141           | 49349    | 52058   | 52058     | 14      |
+| updateFlashloanPremiumToProtocol                                                       | 10205           | 11353    | 10205   | 37005     | 903     |
+| updateFlashloanPremiumTotal                                                            | 14091           | 26958    | 32070   | 36970     | 903     |
+| updateVariableDebtToken                                                                | 14075           | 14531    | 14075   | 131490    | 257     |


 | src/contracts/instances/PoolInstance.sol:PoolInstance contract |                 |        |        |        |         |
 |----------------------------------------------------------------|-----------------|--------|--------|--------|---------|
 | Deployment Cost                                                | Deployment Size |        |        |        |         |
-| 4668760                                                        | 21651           |        |        |        |         |
+| 4697379                                                        | 21784           |        |        |        |         |
 | Function Name                                                  | min             | avg    | median | max    | # calls |
-| ADDRESSES_PROVIDER                                             | 285             | 285    | 285    | 285    | 3066    |
-| BRIDGE_PROTOCOL_FEE                                            | 416             | 2176   | 2416   | 2416   | 25      |
-| FLASHLOAN_PREMIUM_TOTAL                                        | 411             | 1414   | 2411   | 2411   | 1182    |
-| FLASHLOAN_PREMIUM_TO_PROTOCOL                                  | 415             | 416    | 415    | 2415   | 1179    |
+| ADDRESSES_PROVIDER                                             | 285             | 285    | 285    | 285    | 3058    |
+| BRIDGE_PROTOCOL_FEE                                            | 350             | 2110   | 2350   | 2350   | 25      |
+| FLASHLOAN_PREMIUM_TOTAL                                        | 411             | 1414   | 2411   | 2411   | 1174    |
+| FLASHLOAN_PREMIUM_TO_PROTOCOL                                  | 437             | 438    | 437    | 2437   | 1171    |
 | MAX_NUMBER_RESERVES                                            | 309             | 309    | 309    | 309    | 514     |
-| backUnbacked                                                   | 98453           | 114633 | 112032 | 133026 | 9       |
-| borrow                                                         | 46669           | 219345 | 222815 | 262245 | 2435    |
-| configureEModeCategory                                         | 7207            | 10703  | 7207   | 49424  | 280     |
+| backUnbacked                                                   | 98475           | 114655 | 112054 | 133048 | 9       |
+| borrow                                                         | 46603           | 220726 | 222483 | 261668 | 2690    |
+| configureEModeCategory                                         | 7332            | 24595  | 8814   | 51814  | 3371    |
 | deposit                                                        | 32854           | 190352 | 208588 | 214736 | 80      |
-| dropReserve                                                    | 6270            | 7104   | 6270   | 82308  | 262     |
-| finalizeTransfer                                               | 20766           | 45533  | 48574  | 88370  | 317     |
-| flashLoan                                                      | 29742           | 80321  | 61019  | 320939 | 267     |
-| flashLoanSimple                                                | 23431           | 343312 | 189538 | 757563 | 11      |
-| getBorrowLogic                                                 | 304             | 304    | 304    | 304    | 1       |
+| dropReserve                                                    | 6292            | 7125   | 6292   | 82265  | 262     |
+| finalizeTransfer                                               | 20766           | 45011  | 48574  | 88106  | 317     |
+| flashLoan                                                      | 29764           | 82208  | 65635  | 320653 | 267     |
+| flashLoanSimple                                                | 23453           | 343384 | 189604 | 757609 | 11      |
+| getBorrowLogic                                                 | 326             | 326    | 326    | 326    | 1       |
 | getBridgeLogic                                                 | 280             | 280    | 280    | 280    | 1       |
-| getConfiguration                                               | 726             | 968    | 726    | 2726   | 53149   |
-| getEModeCategoryData                                           | 1908            | 5110   | 6163   | 6163   | 43      |
+| getConfiguration                                               | 748             | 978    | 748    | 2748   | 54971   |
+| getEModeCategoryData                                           | 2146            | 8374   | 8401   | 8401   | 2086    |
 | getEModeLogic                                                  | 301             | 301    | 301    | 301    | 1       |
-| getFlashLoanLogic                                              | 303             | 303    | 303    | 303    | 1       |
-| getLiquidationGracePeriod                                      | 2681            | 2681   | 2681   | 2681   | 2014    |
-| getLiquidationLogic                                            | 281             | 281    | 281    | 281    | 1       |
-| getPoolLogic                                                   | 280             | 280    | 280    | 280    | 1       |
-| getReserveAddressById                                          | 665             | 665    | 665    | 665    | 1       |
-| getReserveData                                                 | 4239            | 8268   | 6239   | 24239  | 18252   |
-| getReserveDataExtended                                         | 3416            | 4082   | 3416   | 5416   | 6       |
-| getReserveNormalizedIncome                                     | 849             | 1126   | 849    | 5311   | 10501   |
-| getReserveNormalizedVariableDebt                               | 893             | 1071   | 893    | 6491   | 7171    |
-| getReservesCount                                               | 437             | 437    | 437    | 437    | 2       |
-| getReservesList                                                | 3161            | 12139  | 11161  | 101874 | 1902    |
-| getSupplyLogic                                                 | 304             | 304    | 304    | 304    | 1       |
-| getUserAccountData                                             | 18124           | 21525  | 22624  | 29389  | 1036    |
-| getUserConfiguration                                           | 706             | 748    | 706    | 2706   | 1822    |
-| getUserEMode                                                   | 659             | 659    | 659    | 659    | 1037    |
-| getVirtualUnderlyingBalance                                    | 704             | 704    | 704    | 704    | 2157    |
-| initReserve                                                    | 6597            | 179856 | 179637 | 207301 | 43619   |
-| initialize                                                     | 45447           | 45546  | 45447  | 66968  | 593     |
-| liquidationCall                                                | 53261           | 228680 | 324198 | 376813 | 3491    |
-| mintToTreasury                                                 | 77321           | 78716  | 78716  | 80111  | 2       |
-| mintUnbacked                                                   | 12222           | 118445 | 103571 | 165915 | 17      |
-| repay                                                          | 33239           | 99467  | 95964  | 164674 | 21      |
-| repayWithATokens                                               | 128274          | 154025 | 155469 | 166111 | 261     |
-| repayWithPermit                                                | 127104          | 165503 | 154197 | 209900 | 768     |
-| rescueTokens                                                   | 48154           | 48154  | 48154  | 48154  | 256     |
-| resetIsolationModeTotalDebt                                    | 4298            | 4568   | 4298   | 15298  | 1974    |
-| setConfiguration                                               | 2200            | 16547  | 24200  | 24356  | 67500   |
-| setLiquidationGracePeriod                                      | 6374            | 12458  | 14525  | 17025  | 3476    |
-| setReserveInterestRateStrategyAddress                          | 6416            | 7955   | 6525   | 15813  | 813     |
-| setUserEMode                                                   | 21974           | 41470  | 40194  | 87548  | 10      |
-| setUserUseReserveAsCollateral                                  | 53632           | 72191  | 71653  | 103041 | 25      |
-| supply                                                         | 29467           | 187262 | 208611 | 216374 | 3016    |
+| getFlashLoanLogic                                              | 325             | 325    | 325    | 325    | 1       |
+| getLiquidationGracePeriod                                      | 2703            | 2703   | 2703   | 2703   | 2005    |
+| getLiquidationLogic                                            | 303             | 303    | 303    | 303    | 1       |
+| getPoolLogic                                                   | 302             | 302    | 302    | 302    | 1       |
+| getReserveAddressById                                          | 620             | 620    | 620    | 620    | 1       |
+| getReserveData                                                 | 4261            | 9945   | 10261  | 24261  | 21550   |
+| getReserveDataExtended                                         | 3438            | 4104   | 3438   | 5438   | 6       |
+| getReserveNormalizedIncome                                     | 871             | 1142   | 871    | 5333   | 10752   |
+| getReserveNormalizedVariableDebt                               | 828             | 1005   | 828    | 6426   | 7186    |
+| getReservesCount                                               | 373             | 373    | 373    | 373    | 2       |
+| getReservesList                                                | 3116            | 12647  | 11116  | 102626 | 1874    |
+| getSupplyLogic                                                 | 326             | 326    | 326    | 326    | 1       |
+| getUserAccountData                                             | 17882           | 21571  | 22382  | 28994  | 1804    |
+| getUserConfiguration                                           | 728             | 777    | 728    | 2728   | 1821    |
+| getUserEMode                                                   | 659             | 659    | 659    | 659    | 1548    |
+| getVirtualUnderlyingBalance                                    | 726             | 726    | 726    | 726    | 2155    |
+| initReserve                                                    | 6552            | 179760 | 179592 | 207256 | 44864   |
+| initialize                                                     | 45382           | 45482  | 45382  | 66903  | 589     |
+| liquidationCall                                                | 53261           | 227732 | 315362 | 376486 | 3514    |
+| mintToTreasury                                                 | 77343           | 78738  | 78738  | 80133  | 2       |
+| mintUnbacked                                                   | 12177           | 118400 | 103526 | 165870 | 17      |
+| repay                                                          | 33261           | 99436  | 95921  | 164631 | 21      |
+| repayWithATokens                                               | 128164          | 154520 | 155359 | 166023 | 261     |
+| repayWithPermit                                                | 127039          | 165709 | 154132 | 209835 | 768     |
+| rescueTokens                                                   | 48176           | 48176  | 48176  | 48176  | 256     |
+| resetIsolationModeTotalDebt                                    | 4298            | 4569   | 4298   | 15298  | 1962    |
+| setConfiguration                                               | 2200            | 17083  | 24200  | 24356  | 66881   |
+| setLiquidationGracePeriod                                      | 6329            | 12432  | 14480  | 16980  | 3485    |
+| setReserveInterestRateStrategyAddress                          | 6438            | 7977   | 6547   | 15835  | 813     |
+| setUserEMode                                                   | 18886           | 49402  | 40914  | 94583  | 1034    |
+| setUserUseReserveAsCollateral                                  | 53676           | 72230  | 71697  | 102974 | 25      |
+| supply                                                         | 29401           | 190289 | 208545 | 216308 | 3526    |
 | supplyWithPermit                                               | 113813          | 196609 | 218266 | 257750 | 768     |
-| syncIndexesState                                               | 7251            | 13978  | 7251   | 62644  | 1763    |
-| syncRatesState                                                 | 13531           | 16046  | 16072  | 22572  | 1763    |
-| updateBridgeProtocolFee                                        | 6195            | 7025   | 6195   | 23375  | 269     |
-| updateFlashloanPremiums                                        | 1704            | 10703  | 6377   | 21604  | 1432    |
-| withdraw                                                       | 39229           | 105506 | 87802  | 177983 | 51      |
+| syncIndexesState                                               | 7273            | 14001  | 7273   | 62666  | 1751    |
+| syncRatesState                                                 | 13553           | 16068  | 16094  | 22594  | 1751    |
+| updateBridgeProtocolFee                                        | 6217            | 7047   | 6217   | 23397  | 269     |
+| updateFlashloanPremiums                                        | 1726            | 10720  | 6399   | 21626  | 1424    |
+| withdraw                                                       | 39251           | 105523 | 87824  | 177740 | 51      |


 | src/contracts/instances/VariableDebtTokenInstance.sol:VariableDebtTokenInstance contract |                 |        |        |        |         |
@@ -457,22 +457,22 @@
 | Deployment Cost                                                                          | Deployment Size |        |        |        |         |
 | 1723145                                                                                  | 8349            |        |        |        |         |
 | Function Name                                                                            | min             | avg    | median | max    | # calls |
-| UNDERLYING_ASSET_ADDRESS                                                                 | 398             | 398    | 398    | 398    | 8112    |
+| UNDERLYING_ASSET_ADDRESS                                                                 | 398             | 398    | 398    | 398    | 9369    |
 | approveDelegation                                                                        | 27012           | 27012  | 27012  | 27012  | 1       |
-| balanceOf                                                                                | 681             | 4986   | 4771   | 10365  | 7692    |
+| balanceOf                                                                                | 681             | 4925   | 4706   | 10300  | 7712    |
 | borrowAllowance                                                                          | 831             | 831    | 831    | 831    | 5       |
-| burn                                                                                     | 19204           | 26197  | 26204  | 26205  | 3108    |
-| decimals                                                                                 | 335             | 335    | 335    | 335    | 8112    |
+| burn                                                                                     | 19204           | 26197  | 26204  | 26205  | 3107    |
+| decimals                                                                                 | 335             | 335    | 335    | 335    | 9369    |
 | delegationWithSig                                                                        | 1052            | 28689  | 21662  | 55862  | 7       |
-| getIncentivesController                                                                  | 431             | 431    | 431    | 431    | 8112    |
-| initialize                                                                               | 123620          | 207871 | 209041 | 299205 | 43251   |
-| mint                                                                                     | 26385           | 62549  | 62585  | 72374  | 2687    |
-| name                                                                                     | 1009            | 1421   | 1264   | 3264   | 8202    |
+| getIncentivesController                                                                  | 431             | 431    | 431    | 431    | 9369    |
+| initialize                                                                               | 123620          | 206084 | 209041 | 299205 | 44496   |
+| mint                                                                                     | 26385           | 62552  | 62585  | 72374  | 2942    |
+| name                                                                                     | 1009            | 1419   | 1264   | 3264   | 9459    |
 | nonces                                                                                   | 577             | 577    | 577    | 577    | 1       |
-| scaledBalanceOf                                                                          | 691             | 1887   | 2691   | 2691   | 5867    |
-| scaledTotalSupply                                                                        | 419             | 2102   | 2419   | 2419   | 18707   |
-| symbol                                                                                   | 1030            | 1440   | 1347   | 3285   | 8195    |
-| totalSupply                                                                              | 4079            | 7582   | 6481   | 19079  | 15      |
+| scaledBalanceOf                                                                          | 691             | 1829   | 2691   | 2691   | 6656    |
+| scaledTotalSupply                                                                        | 419             | 2116   | 2419   | 2419   | 19469   |
+| symbol                                                                                   | 1030            | 1440   | 1347   | 3285   | 9452    |
+| totalSupply                                                                              | 4014            | 7523   | 6416   | 19014  | 15      |


 | src/contracts/misc/AaveOracle.sol:AaveOracle contract |                 |       |        |       |         |
@@ -482,10 +482,10 @@
 | Function Name                                         | min             | avg   | median | max   | # calls |
 | BASE_CURRENCY                                         | 293             | 293   | 293    | 293   | 3       |
 | BASE_CURRENCY_UNIT                                    | 262             | 262   | 262    | 262   | 1       |
-| getAssetPrice                                         | 679             | 4746  | 7873   | 7873  | 22337   |
+| getAssetPrice                                         | 0               | 4726  | 7873   | 7873  | 24937   |
 | getAssetsPrices                                       | 2300            | 3404  | 2300   | 5614  | 3       |
 | getFallbackOracle                                     | 365             | 1031  | 365    | 2365  | 3       |
-| getSourceOfAsset                                      | 553             | 635   | 553    | 2553  | 1140    |
+| getSourceOfAsset                                      | 553             | 635   | 553    | 2553  | 1139    |
 | setAssetSources                                       | 37348           | 52896 | 61947  | 62187 | 9       |
 | setFallbackOracle                                     | 59544           | 59544 | 59544  | 59544 | 4       |

@@ -499,7 +499,7 @@
 | MAX_BORROW_RATE                                                                                           | 240             | 240   | 240    | 240   | 5382    |
 | MAX_OPTIMAL_POINT                                                                                         | 262             | 262   | 262    | 262   | 6918    |
 | MIN_OPTIMAL_POINT                                                                                         | 261             | 261   | 261    | 261   | 6918    |
-| calculateInterestRates                                                                                    | 0               | 4436  | 4271   | 5999  | 16046   |
+| calculateInterestRates                                                                                    | 0               | 4456  | 4271   | 5999  | 16797   |
 | getBaseVariableBorrowRate                                                                                 | 748             | 776   | 748    | 2748  | 2908    |
 | getInterestRateData                                                                                       | 1804            | 1804  | 1804   | 1804  | 256     |
 | getInterestRateDataBps                                                                                    | 987             | 987   | 987    | 987   | 256     |
@@ -507,7 +507,7 @@
 | getOptimalUsageRatio                                                                                      | 738             | 738   | 738    | 2738  | 2136    |
 | getVariableRateSlope1                                                                                     | 778             | 778   | 778    | 778   | 2140    |
 | getVariableRateSlope2                                                                                     | 799             | 799   | 799    | 799   | 1368    |
-| setInterestRateParams(address,(uint16,uint32,uint32,uint32))                                              | 28278           | 29729 | 29075  | 36816 | 2816    |
+| setInterestRateParams(address,(uint16,uint32,uint32,uint32))                                              | 28290           | 29729 | 29075  | 36804 | 2816    |
 | setInterestRateParams(address,bytes)                                                                      | 28624           | 33084 | 29860  | 37156 | 6405    |


@@ -530,26 +530,26 @@
 | Deployment Cost                                                                                                                                   | Deployment Size |          |         |           |         |
 | 465623                                                                                                                                            | 2115            |          |         |           |         |
 | Function Name                                                                                                                                     | min             | avg      | median  | max       | # calls |
-| ADDRESSES_PROVIDER                                                                                                                                | 898             | 4368     | 5398    | 5465      | 3190    |
-| BRIDGE_PROTOCOL_FEE                                                                                                                               | 1029            | 5311     | 7529    | 7529      | 23      |
+| ADDRESSES_PROVIDER                                                                                                                                | 898             | 4371     | 5398    | 5465      | 3182    |
+| BRIDGE_PROTOCOL_FEE                                                                                                                               | 963             | 5245     | 7463    | 7463      | 23      |
 | DOMAIN_SEPARATOR                                                                                                                                  | 1071            | 4688     | 4156    | 7571      | 5       |
-| EMISSION_MANAGER                                                                                                                                  | 940             | 940      | 940     | 940       | 650     |
-| FLASHLOAN_PREMIUM_TOTAL                                                                                                                           | 1002            | 2033     | 3002    | 7524      | 1304    |
-| FLASHLOAN_PREMIUM_TO_PROTOCOL                                                                                                                     | 1028            | 1039     | 1028    | 7528      | 1301    |
-| MAX_GRACE_PERIOD                                                                                                                                  | 5418            | 5418     | 5418    | 5418      | 1792    |
+| EMISSION_MANAGER                                                                                                                                  | 940             | 940      | 940     | 940       | 646     |
+| FLASHLOAN_PREMIUM_TOTAL                                                                                                                           | 1002            | 2033     | 3002    | 7524      | 1296    |
+| FLASHLOAN_PREMIUM_TO_PROTOCOL                                                                                                                     | 1028            | 1052     | 1050    | 7550      | 1293    |
+| MAX_GRACE_PERIOD                                                                                                                                  | 5374            | 5374     | 5374    | 5374      | 1792    |
 | MAX_NUMBER_RESERVES                                                                                                                               | 922             | 922      | 922     | 922       | 512     |
 | POOL                                                                                                                                              | 940             | 940      | 940     | 940       | 151     |
-| RESERVE_TREASURY_ADDRESS                                                                                                                          | 1033            | 1397     | 1033    | 7533      | 9918    |
+| RESERVE_TREASURY_ADDRESS                                                                                                                          | 1033            | 1356     | 1033    | 7533      | 11174   |
 | REVISION                                                                                                                                          | 874             | 874      | 874     | 874       | 8       |
-| UNDERLYING_ASSET_ADDRESS                                                                                                                          | 1011            | 1050     | 1055    | 3055      | 16363   |
+| UNDERLYING_ASSET_ADDRESS                                                                                                                          | 1011            | 1047     | 1055    | 3055      | 18877   |
 | admin                                                                                                                                             | 21390           | 21390    | 21390   | 21390     | 8       |
 | allowance                                                                                                                                         | 1404            | 3173     | 3404    | 7904      | 26      |
 | approve                                                                                                                                           | 51293           | 51357    | 51341   | 51653     | 39      |
 | approveDelegation                                                                                                                                 | 53760           | 53760    | 53760   | 53760     | 1       |
-| backUnbacked                                                                                                                                      | 125314          | 140965   | 138917  | 159923    | 9       |
-| balanceOf                                                                                                                                         | 1297            | 5849     | 5387    | 22860     | 12491   |
-| borrow(address,uint256,uint256,uint16,address)                                                                                                    | 74012           | 244274   | 250193  | 289647    | 2700    |
-| borrow(bytes32)                                                                                                                                   | 230155          | 230155   | 230155  | 230155    | 3       |
+| backUnbacked                                                                                                                                      | 125336          | 140987   | 138939  | 159945    | 9       |
+| balanceOf                                                                                                                                         | 1297            | 5820     | 5382    | 22882     | 12508   |
+| borrow(address,uint256,uint256,uint16,address)                                                                                                    | 73946           | 244911   | 249861  | 289070    | 2955    |
+| borrow(bytes32)                                                                                                                                   | 229802          | 229802   | 229802  | 229802    | 3       |
 | borrowAllowance                                                                                                                                   | 1450            | 1450     | 1450    | 1450      | 5       |
 | burn                                                                                                                                              | 28132           | 40754    | 28464   | 65668     | 3       |
 | claimAllRewards                                                                                                                                   | 119578          | 119578   | 119578  | 119578    | 1       |
@@ -558,128 +558,129 @@
 | claimRewards                                                                                                                                      | 28668           | 77756    | 84171   | 114016    | 4       |
 | claimRewardsOnBehalf                                                                                                                              | 116579          | 116579   | 116579  | 116579    | 1       |
 | claimRewardsToSelf                                                                                                                                | 113333          | 113333   | 113333  | 113333    | 1       |
-| configureEModeCategory                                                                                                                            | 34496           | 34507    | 34507   | 34519     | 512     |
-| configureReserveAsCollateral                                                                                                                      | 44067           | 64524    | 57732   | 122552    | 2308    |
-| decimals                                                                                                                                          | 948             | 982      | 970     | 7470      | 16416   |
+| configureEModeCategory                                                                                                                            | 34733           | 34744    | 34744   | 34755     | 512     |
+| configureReserveAsCollateral                                                                                                                      | 44111           | 64591    | 57798   | 122652    | 2308    |
+| decimals                                                                                                                                          | 948             | 979      | 970     | 7470      | 18930   |
 | decreaseAllowance                                                                                                                                 | 34424           | 34424    | 34424   | 34424     | 1       |
 | delegationWithSig                                                                                                                                 | 29263           | 56402    | 45264   | 84300     | 7       |
 | deposit                                                                                                                                           | 91067           | 215461   | 232188  | 235808    | 64      |
-| disableLiquidationGracePeriod                                                                                                                     | 43659           | 55004    | 66162   | 66162     | 513     |
-| dropReserve                                                                                                                                       | 32591           | 35715    | 32657   | 105072    | 775     |
-| flashLoan                                                                                                                                         | 59293           | 162000   | 126617  | 374226    | 267     |
-| flashLoanSimple                                                                                                                                   | 50944           | 311491   | 177238  | 642906    | 11      |
+| disableLiquidationGracePeriod                                                                                                                     | 43592           | 54914    | 66050   | 66050     | 513     |
+| dropReserve                                                                                                                                       | 32591           | 35715    | 32613   | 105072    | 775     |
+| flashLoan                                                                                                                                         | 59315           | 165996   | 134021  | 374248    | 267     |
+| flashLoanSimple                                                                                                                                   | 50966           | 311558   | 177304  | 642952    | 11      |
 | getAllUserRewards                                                                                                                                 | 9271            | 9271     | 9271    | 9271      | 1       |
 | getAssetDecimals                                                                                                                                  | 1275            | 1275     | 1275    | 1275      | 2       |
 | getAssetIndex                                                                                                                                     | 3708            | 11517    | 14698   | 21619     | 90      |
-| getBorrowLogic                                                                                                                                    | 5395            | 5406     | 5406    | 5417      | 2       |
+| getBorrowLogic                                                                                                                                    | 5417            | 5428     | 5428    | 5439      | 2       |
 | getBridgeLogic                                                                                                                                    | 5393            | 5426     | 5426    | 5459      | 2       |
 | getClaimer                                                                                                                                        | 1244            | 3410     | 1244    | 7744      | 3       |
-| getConfiguration                                                                                                                                  | 1298            | 1892     | 1342    | 7842      | 54785   |
-| getConfiguratorLogic                                                                                                                              | 5353            | 5353     | 5353    | 5353      | 1       |
+| getConfiguration                                                                                                                                  | 1320            | 1888     | 1364    | 7864      | 56433   |
+| getConfiguratorLogic                                                                                                                              | 5397            | 5397     | 5397    | 5397      | 1       |
 | getDistributionEnd                                                                                                                                | 1411            | 1411     | 1411    | 1411      | 1       |
-| getEModeCategoryData                                                                                                                              | 2554            | 6313     | 6815    | 11054     | 55      |
+| getEModeCategoryData                                                                                                                              | 2798            | 13513    | 13559   | 13559     | 2100    |
 | getEModeLogic                                                                                                                                     | 5392            | 5403     | 5403    | 5414      | 2       |
-| getFlashLoanLogic                                                                                                                                 | 5416            | 5438     | 5438    | 5461      | 2       |
-| getIncentivesController                                                                                                                           | 1044            | 1066     | 1088    | 7588      | 16230   |
-| getLiquidationGracePeriod                                                                                                                         | 29207           | 29226    | 29229   | 29229     | 2270    |
-| getLiquidationLogic                                                                                                                               | 5394            | 5416     | 5416    | 5439      | 2       |
-| getPendingLtv                                                                                                                                     | 1215            | 1215     | 1215    | 1215      | 771     |
-| getPoolLogic                                                                                                                                      | 5393            | 5404     | 5404    | 5416      | 2       |
+| getFlashLoanLogic                                                                                                                                 | 5394            | 5416     | 5416    | 5438      | 2       |
+| getIncentivesController                                                                                                                           | 1044            | 1066     | 1088    | 7588      | 18744   |
+| getLiquidationGracePeriod                                                                                                                         | 29229           | 29248    | 29251   | 29251     | 2261    |
+| getLiquidationLogic                                                                                                                               | 5416            | 5438     | 5438    | 5461      | 2       |
+| getPendingLtv                                                                                                                                     | 1259            | 1259     | 1259    | 1259      | 771     |
+| getPoolLogic                                                                                                                                      | 5415            | 5426     | 5426    | 5438      | 2       |
 | getPreviousIndex                                                                                                                                  | 1270            | 1270     | 1270    | 1270      | 39      |
-| getReserveAddressById                                                                                                                             | 1281            | 1281     | 1281    | 1281      | 1       |
-| getReserveData                                                                                                                                    | 4889            | 9269     | 6933    | 29433     | 19091   |
-| getReserveDataExtended                                                                                                                            | 4122            | 4788     | 4122    | 6122      | 6       |
-| getReserveNormalizedIncome                                                                                                                        | 1465            | 1970     | 1465    | 10427     | 10793   |
-| getReserveNormalizedVariableDebt                                                                                                                  | 1465            | 1681     | 1509    | 11607     | 7435    |
-| getReservesCount                                                                                                                                  | 1050            | 1050     | 1050    | 1050      | 2       |
-| getReservesList                                                                                                                                   | 3792            | 16242    | 16292   | 103281    | 2164    |
+| getReserveAddressById                                                                                                                             | 1236            | 1236     | 1236    | 1236      | 1       |
+| getReserveData                                                                                                                                    | 4911            | 10848    | 10955   | 29455     | 22403   |
+| getReserveDataExtended                                                                                                                            | 4144            | 4810     | 4144    | 6144      | 6       |
+| getReserveNormalizedIncome                                                                                                                        | 1443            | 1979     | 1487    | 10449     | 11044   |
+| getReserveNormalizedVariableDebt                                                                                                                  | 1444            | 1618     | 1444    | 11542     | 7450    |
+| getReservesCount                                                                                                                                  | 986             | 986      | 986     | 986       | 2       |
+| getReservesList                                                                                                                                   | 3747            | 16682    | 16247   | 104040    | 2130    |
 | getRewardOracle                                                                                                                                   | 1268            | 1268     | 1268    | 1268      | 1       |
 | getRewardsByAsset                                                                                                                                 | 2399            | 5698     | 3672    | 10899     | 201     |
 | getRewardsData                                                                                                                                    | 1610            | 1610     | 1610    | 1610      | 3       |
 | getRewardsList                                                                                                                                    | 1736            | 1736     | 1736    | 1736      | 30      |
 | getScaledUserBalanceAndSupply                                                                                                                     | 1449            | 4192     | 3449    | 9949      | 39      |
-| getSupplyLogic                                                                                                                                    | 5417            | 5449     | 5449    | 5481      | 2       |
+| getSupplyLogic                                                                                                                                    | 5395            | 5417     | 5417    | 5439      | 2       |
 | getTransferStrategy                                                                                                                               | 1267            | 1267     | 1267    | 1267      | 1       |
-| getUserAccountData                                                                                                                                | 18764           | 22167    | 23264   | 30029     | 1037    |
+| getUserAccountData                                                                                                                                | 18522           | 22212    | 23022   | 29634     | 1805    |
 | getUserAccruedRewards                                                                                                                             | 2267            | 2267     | 2267    | 2267      | 1       |
 | getUserAssetIndex                                                                                                                                 | 1634            | 1634     | 1634    | 1634      | 1       |
-| getUserConfiguration                                                                                                                              | 1322            | 1364     | 1322    | 3322      | 1822    |
-| getUserEMode                                                                                                                                      | 1275            | 1275     | 1275    | 1275      | 1037    |
+| getUserConfiguration                                                                                                                              | 1344            | 1393     | 1344    | 3344      | 1821    |
+| getUserEMode                                                                                                                                      | 1275            | 1275     | 1275    | 1275      | 1548    |
 | getUserRewards                                                                                                                                    | 5237            | 7340     | 7469    | 10837     | 19      |
-| getVirtualUnderlyingBalance                                                                                                                       | 1298            | 1319     | 1320    | 1320      | 2161    |
+| getVirtualUnderlyingBalance                                                                                                                       | 1320            | 1341     | 1342    | 1342      | 2159    |
 | increaseAllowance                                                                                                                                 | 34491           | 47316    | 51591   | 51591     | 4       |
-| initReserve                                                                                                                                       | 33270           | 33292    | 33292   | 33314     | 1024    |
-| initReserves                                                                                                                                      | 45755           | 32070878 | 1608802 | 218102716 | 2049    |
-| liquidationCall(address,address,address,uint256,bool)                                                                                             | 80856           | 256275   | 351792  | 404755    | 3491    |
-| liquidationCall(bytes32,bytes32)                                                                                                                  | 404144          | 404144   | 404144  | 404144    | 1       |
+| initReserve                                                                                                                                       | 33269           | 33280    | 33280   | 33292     | 1024    |
+| initReserves                                                                                                                                      | 45710           | 33036201 | 1608627 | 216658072 | 2049    |
+| liquidationCall(address,address,address,uint256,bool)                                                                                             | 80856           | 255326   | 342956  | 404416    | 3514    |
+| liquidationCall(bytes32,bytes32)                                                                                                                  | 403771          | 403771   | 403771  | 403771    | 1       |
 | mint                                                                                                                                              | 28161           | 73503    | 91286   | 91766     | 7       |
-| mintToTreasury(address[])                                                                                                                         | 99333           | 100926   | 100926  | 102519    | 4       |
+| mintToTreasury(address[])                                                                                                                         | 99355           | 100948   | 100948  | 102541    | 4       |
 | mintToTreasury(uint256,uint256)                                                                                                                   | 26988           | 59951    | 59951   | 92915     | 2       |
-| mintUnbacked                                                                                                                                      | 39431           | 145665   | 130791  | 193135    | 17      |
-| name                                                                                                                                              | 1625            | 2063     | 1945    | 8383      | 16555   |
+| mintUnbacked                                                                                                                                      | 39386           | 145620   | 130746  | 193090    | 17      |
+| name                                                                                                                                              | 1625            | 2058     | 1945    | 8383      | 19069   |
 | nonces                                                                                                                                            | 1193            | 2463     | 3271    | 3271      | 10      |
 | permit                                                                                                                                            | 29304           | 46376    | 37841   | 81937     | 8       |
-| repay(address,uint256,uint256,address)                                                                                                            | 60448           | 129350   | 167720  | 187144    | 13      |
-| repay(bytes32)                                                                                                                                    | 157401          | 157401   | 157401  | 157401    | 1       |
-| repayWithATokens(address,uint256,uint256)                                                                                                         | 155111          | 180842   | 182318  | 193320    | 261     |
-| repayWithATokens(bytes32)                                                                                                                         | 160522          | 160522   | 160522  | 160522    | 1       |
-| repayWithPermit(address,uint256,uint256,address,uint256,uint8,bytes32,bytes32)                                                                    | 155668          | 185855   | 182856  | 218694    | 768     |
-| repayWithPermit(bytes32,bytes32,bytes32)                                                                                                          | 190465          | 206566   | 214543  | 217860    | 256     |
-| rescueTokens                                                                                                                                      | 39115           | 70318    | 70428   | 70471     | 515     |
+| repay(address,uint256,uint256,address)                                                                                                            | 60470           | 129327   | 167677  | 187099    | 13      |
+| repay(bytes32)                                                                                                                                    | 157445          | 157445   | 157445  | 157445    | 1       |
+| repayWithATokens(address,uint256,uint256)                                                                                                         | 155001          | 181337   | 182208  | 193232    | 261     |
+| repayWithATokens(bytes32)                                                                                                                         | 160479          | 160479   | 160479  | 160479    | 1       |
+| repayWithPermit(address,uint256,uint256,address,uint256,uint8,bytes32,bytes32)                                                                    | 155591          | 186031   | 182803  | 218606    | 768     |
+| repayWithPermit(bytes32,bytes32,bytes32)                                                                                                          | 190590          | 206885   | 214480  | 217827    | 256     |
+| rescueTokens                                                                                                                                      | 39115           | 70340    | 70450   | 70493     | 515     |
 | resetIsolationModeTotalDebt                                                                                                                       | 32590           | 32636    | 32612   | 41843     | 514     |
-| scaledBalanceOf                                                                                                                                   | 1307            | 3741     | 3307    | 7807      | 16286   |
-| scaledTotalSupply                                                                                                                                 | 988             | 5835     | 7532    | 7532      | 19121   |
-| setAssetEModeCategory                                                                                                                             | 43877           | 48422    | 43877   | 79556     | 296     |
-| setBorrowCap                                                                                                                                      | 43786           | 44743    | 43786   | 70919     | 267     |
-| setBorrowableInIsolation                                                                                                                          | 67706           | 70116    | 70508   | 70508     | 13      |
+| scaledBalanceOf                                                                                                                                   | 1307            | 3711     | 3307    | 7807      | 18376   |
+| scaledTotalSupply                                                                                                                                 | 988             | 5907     | 7532    | 7532      | 19883   |
+| setAssetBorrowableInEMode                                                                                                                         | 120872          | 120959   | 120960  | 120960    | 517     |
+| setAssetCollateralInEMode                                                                                                                         | 44125           | 95562    | 103956  | 103956    | 1825    |
+| setBorrowCap                                                                                                                                      | 43786           | 44744    | 43786   | 70941     | 267     |
+| setBorrowableInIsolation                                                                                                                          | 67684           | 70094    | 70486   | 70486     | 13      |
 | setConfiguration                                                                                                                                  | 32805           | 32816    | 32816   | 32827     | 512     |
-| setDebtCeiling                                                                                                                                    | 43743           | 48112    | 43743   | 121555    | 274     |
-| setEModeCategory                                                                                                                                  | 45031           | 53892    | 45031   | 135431    | 295     |
+| setDebtCeiling                                                                                                                                    | 43765           | 48137    | 43765   | 121621    | 274     |
+| setEModeCategory                                                                                                                                  | 44872           | 98218    | 111566  | 111662    | 1308    |
 | setIncentivesController                                                                                                                           | 38502           | 40869    | 40869   | 43236     | 2       |
-| setLiquidationGracePeriod                                                                                                                         | 32828           | 37932    | 37350   | 43761     | 1536    |
-| setLiquidationProtocolFee                                                                                                                         | 43996           | 60606    | 69878   | 70968     | 8       |
-| setPoolPause(bool)                                                                                                                                | 43633           | 44062    | 43633   | 116393    | 515     |
-| setPoolPause(bool,uint40)                                                                                                                         | 43789           | 88393    | 74789   | 134303    | 512     |
-| setReserveActive                                                                                                                                  | 40906           | 43807    | 40906   | 118044    | 267     |
-| setReserveBorrowing                                                                                                                               | 43833           | 60242    | 68446   | 68448     | 768     |
-| setReserveFactor                                                                                                                                  | 43766           | 44186    | 43766   | 151823    | 258     |
+| setLiquidationGracePeriod                                                                                                                         | 32805           | 37924    | 37338   | 43761     | 1536    |
+| setLiquidationProtocolFee                                                                                                                         | 44018           | 60642    | 69922   | 71012     | 8       |
+| setPoolPause(bool)                                                                                                                                | 43568           | 43997    | 43568   | 116349    | 515     |
+| setPoolPause(bool,uint40)                                                                                                                         | 43811           | 88193    | 74821   | 134211    | 512     |
+| setReserveActive                                                                                                                                  | 40928           | 43831    | 40928   | 118110    | 267     |
+| setReserveBorrowing                                                                                                                               | 43877           | 60301    | 68512   | 68514     | 768     |
+| setReserveFactor                                                                                                                                  | 43810           | 44230    | 43810   | 151933    | 258     |
 | setReserveFlashLoaning                                                                                                                            | 68511           | 68516    | 68513   | 70667     | 513     |
-| setReserveFreeze                                                                                                                                  | 47022           | 73129    | 74823   | 99841     | 783     |
-| setReserveInterestRateData                                                                                                                        | 44326           | 44812    | 44554   | 131069    | 257     |
-| setReserveInterestRateStrategyAddress(address,address)                                                                                            | 32846           | 34588    | 33195   | 42729     | 1538    |
-| setReserveInterestRateStrategyAddress(address,address,bytes)                                                                                      | 44558           | 61418    | 44558   | 190255    | 300     |
-| setReservePause(address,bool)                                                                                                                     | 43812           | 44147    | 44040   | 67736     | 258     |
-| setReservePause(address,bool,uint40)                                                                                                              | 41277           | 65905    | 73907   | 79019     | 3084    |
-| setSiloedBorrowing                                                                                                                                | 102106          | 111956   | 115803  | 117959    | 3       |
-| setSupplyCap                                                                                                                                      | 43788           | 45799    | 43788   | 70921     | 279     |
-| setUnbackedMintCap                                                                                                                                | 70889           | 70889    | 70889   | 70889     | 7       |
-| setUserEMode                                                                                                                                      | 48307           | 68041    | 66511   | 113935    | 17      |
-| setUserUseReserveAsCollateral(address,bool)                                                                                                       | 80336           | 96356    | 93550   | 129754    | 42      |
-| setUserUseReserveAsCollateral(bytes32)                                                                                                            | 95329           | 95329    | 95329   | 95329     | 1       |
+| setReserveFreeze                                                                                                                                  | 47066           | 73158    | 74889   | 99907     | 782     |
+| setReserveInterestRateData                                                                                                                        | 44370           | 44851    | 44598   | 131179    | 257     |
+| setReserveInterestRateStrategyAddress(address,address)                                                                                            | 32868           | 34612    | 33217   | 42751     | 1538    |
+| setReserveInterestRateStrategyAddress(address,address,bytes)                                                                                      | 44513           | 61386    | 44513   | 190298    | 300     |
+| setReservePause(address,bool)                                                                                                                     | 43856           | 44188    | 44084   | 67802     | 258     |
+| setReservePause(address,bool,uint40)                                                                                                              | 41299           | 65986    | 73906   | 79018     | 3084    |
+| setSiloedBorrowing                                                                                                                                | 102085          | 111949   | 115804  | 117960    | 3       |
+| setSupplyCap                                                                                                                                      | 43743           | 45756    | 43743   | 70898     | 279     |
+| setUnbackedMintCap                                                                                                                                | 70933           | 70933    | 70933   | 70933     | 7       |
+| setUserEMode                                                                                                                                      | 43191           | 75378    | 67231   | 120900    | 1041    |
+| setUserUseReserveAsCollateral(address,bool)                                                                                                       | 80314           | 96359    | 93573   | 129666    | 42      |
+| setUserUseReserveAsCollateral(bytes32)                                                                                                            | 95286           | 95286    | 95286   | 95286     | 1       |
 | setValue                                                                                                                                          | 31574           | 31590    | 31598   | 31598     | 3       |
-| supply(address,uint256,address,uint16)                                                                                                            | 56664           | 214087   | 231043  | 243594    | 3300    |
+| supply(address,uint256,address,uint16)                                                                                                            | 56598           | 215668   | 226285  | 243528    | 3810    |
 | supply(bytes32)                                                                                                                                   | 237010          | 237010   | 237010  | 237010    | 7       |
-| supplyWithPermit(address,uint256,address,uint16,uint256,uint8,bytes32,bytes32)                                                                    | 142365          | 216977   | 242026  | 266578    | 768     |
-| supplyWithPermit(bytes32,bytes32,bytes32)                                                                                                         | 262532          | 262616   | 262592  | 262736    | 256     |
-| symbol                                                                                                                                            | 1646            | 2128     | 1966    | 8448      | 16530   |
+| supplyWithPermit(address,uint256,address,uint16,uint256,uint8,bytes32,bytes32)                                                                    | 142365          | 216981   | 242026  | 266578    | 768     |
+| supplyWithPermit(bytes32,bytes32,bytes32)                                                                                                         | 262566          | 262636   | 262614  | 262758    | 256     |
+| symbol                                                                                                                                            | 1646            | 2123     | 1988    | 8448      | 19044   |
 | text                                                                                                                                              | 1789            | 1789     | 1789    | 1789      | 8       |
-| totalSupply                                                                                                                                       | 1024            | 8279     | 11570   | 15570     | 4914    |
-| transfer                                                                                                                                          | 27662           | 144188   | 149393  | 167373    | 273     |
-| transferFrom                                                                                                                                      | 138702          | 138822   | 138822  | 138942    | 2       |
+| totalSupply                                                                                                                                       | 1024            | 8463     | 11592   | 15592     | 5157    |
+| transfer                                                                                                                                          | 27662           | 143606   | 149415  | 167131    | 273     |
+| transferFrom                                                                                                                                      | 138724          | 138844   | 138844  | 138964    | 2       |
 | transferOnLiquidation                                                                                                                             | 28063           | 28063    | 28063   | 28063     | 1       |
 | transferUnderlyingTo                                                                                                                              | 27506           | 27506    | 27506   | 27506     | 1       |
-| updateAToken                                                                                                                                      | 41856           | 42264    | 41856   | 146869    | 257     |
-| updateBridgeProtocolFee                                                                                                                           | 32528           | 33698    | 32573   | 78409     | 526     |
-| updateFlashloanPremiumToProtocol                                                                                                                  | 40448           | 40536    | 40448   | 63268     | 258     |
-| updateFlashloanPremiumTotal                                                                                                                       | 40469           | 40558    | 40469   | 63300     | 258     |
-| updateFlashloanPremiums                                                                                                                           | 32853           | 32875    | 32875   | 32898     | 512     |
-| updateVariableDebtToken                                                                                                                           | 41710           | 42095    | 41710   | 140758    | 257     |
+| updateAToken                                                                                                                                      | 41789           | 42197    | 41789   | 146826    | 257     |
+| updateBridgeProtocolFee                                                                                                                           | 32550           | 33719    | 32595   | 78387     | 526     |
+| updateFlashloanPremiumToProtocol                                                                                                                  | 40470           | 40559    | 40470   | 63334     | 258     |
+| updateFlashloanPremiumTotal                                                                                                                       | 40424           | 40513    | 40424   | 63299     | 258     |
+| updateFlashloanPremiums                                                                                                                           | 32875           | 32897    | 32897   | 32920     | 512     |
+| updateVariableDebtToken                                                                                                                           | 41644           | 42029    | 41644   | 140710    | 257     |
 | upgradeTo                                                                                                                                         | 26855           | 28742    | 28742   | 30629     | 2       |
 | upgradeToAndCall                                                                                                                                  | 28758           | 152638   | 187413  | 187413    | 8       |
 | value                                                                                                                                             | 931             | 931      | 931     | 931       | 11      |
 | values                                                                                                                                            | 1213            | 1213     | 1213    | 1213      | 16      |
-| withdraw(address,uint256,address)                                                                                                                 | 66340           | 134756   | 141964  | 205094    | 23      |
-| withdraw(bytes32)                                                                                                                                 | 138782          | 145861   | 145861  | 152941    | 2       |
+| withdraw(address,uint256,address)                                                                                                                 | 66362           | 134766   | 141986  | 204851    | 23      |
+| withdraw(bytes32)                                                                                                                                 | 138804          | 145883   | 145883  | 152963    | 2       |


 | src/contracts/mocks/flashloan/MockFlashLoanReceiver.sol:MockFlashLoanReceiver contract |                 |       |        |       |         |
@@ -703,9 +704,9 @@
 | src/contracts/mocks/helpers/MockPool.sol:MockPoolInherited contract |                 |       |        |       |         |
 |---------------------------------------------------------------------|-----------------|-------|--------|-------|---------|
 | Deployment Cost                                                     | Deployment Size |       |        |       |         |
-| 4732690                                                             | 21870           |       |        |       |         |
+| 4761368                                                             | 22003           |       |        |       |         |
 | Function Name                                                       | min             | avg   | median | max   | # calls |
-| initialize                                                          | 28462           | 28462 | 28462  | 28462 | 2       |
+| initialize                                                          | 28397           | 28397 | 28397  | 28397 | 2       |


 | src/contracts/mocks/oracle/CLAggregators/MockAggregator.sol:MockAggregator contract |                 |      |        |      |         |
@@ -713,10 +714,10 @@
 | Deployment Cost                                                                     | Deployment Size |      |        |      |         |
 | 109507                                                                              | 321             |      |        |      |         |
 | Function Name                                                                       | min             | avg  | median | max  | # calls |
-| _latestAnswer                                                                       | 317             | 317  | 317    | 317  | 4160    |
+| _latestAnswer                                                                       | 317             | 317  | 317    | 317  | 4156    |
 | decimals                                                                            | 144             | 144  | 144    | 144  | 83      |
 | description                                                                         | 170             | 170  | 170    | 170  | 83      |
-| latestAnswer                                                                        | 281             | 1395 | 2281   | 2281 | 24197   |
+| latestAnswer                                                                        | 281             | 1396 | 2281   | 2281 | 26529   |
 | name                                                                                | 170             | 170  | 170    | 170  | 83      |


@@ -732,10 +733,10 @@
 | src/contracts/mocks/oracle/SequencerOracle.sol:SequencerOracle contract |                 |       |        |       |         |
 |-------------------------------------------------------------------------|-----------------|-------|--------|-------|---------|
 | Deployment Cost                                                         | Deployment Size |       |        |       |         |
-| 278266                                                                  | 1393            |       |        |       |         |
+| 278290                                                                  | 1393            |       |        |       |         |
 | Function Name                                                           | min             | avg   | median | max   | # calls |
 | latestRoundData                                                         | 730             | 1533  | 735    | 4735  | 10      |
-| setAnswer                                                               | 26207           | 27452 | 26207  | 46119 | 73      |
+| setAnswer                                                               | 26207           | 27469 | 26207  | 46119 | 72      |


 | src/contracts/mocks/swap/MockParaSwapAugustus.sol:MockParaSwapAugustus contract |                 |        |        |        |         |
@@ -773,13 +774,13 @@
 | Function Name                                                              | min             | avg   | median | max   | # calls |
 | DOMAIN_SEPARATOR                                                           | 2340            | 2340  | 2340   | 2340  | 1       |
 | allowance                                                                  | 836             | 836   | 836    | 836   | 9       |
-| approve                                                                    | 29140           | 46510 | 46588  | 46588 | 4618    |
-| balanceOf                                                                  | 651             | 991   | 651    | 2651  | 12549   |
-| decimals                                                                   | 312             | 1481  | 2312   | 2312  | 73384   |
-| mint                                                                       | 36480           | 58491 | 53592  | 70740 | 4133    |
+| approve                                                                    | 29140           | 46492 | 46588  | 46588 | 5089    |
+| balanceOf                                                                  | 651             | 991   | 651    | 2651  | 12547   |
+| decimals                                                                   | 312             | 1441  | 2312   | 2312  | 78660   |
+| mint                                                                       | 36480           | 59853 | 53592  | 70800 | 4604    |
 | name                                                                       | 3241            | 3241  | 3241   | 3241  | 2048    |
 | nonces                                                                     | 2604            | 2604  | 2604   | 2604  | 1       |
-| permit                                                                     | 76466           | 76512 | 76502  | 76670 | 512     |
+| permit                                                                     | 76454           | 76517 | 76502  | 76670 | 512     |
 | symbol                                                                     | 1328            | 2328  | 2328   | 3328  | 56      |
 | transfer                                                                   | 46931           | 51023 | 51707  | 51707 | 7       |
 | transferOwnership                                                          | 28800           | 28800 | 28800  | 28800 | 30      |
@@ -801,10 +802,10 @@
 | Deployment Cost                                                                    | Deployment Size |     |        |     |         |
 | 119707                                                                             | 340             |     |        |     |         |
 | Function Name                                                                      | min             | avg | median | max | # calls |
-| HALF_PERCENTAGE_FACTOR                                                             | 147             | 147 | 147    | 147 | 448     |
-| PERCENTAGE_FACTOR                                                                  | 224             | 224 | 224    | 224 | 689     |
+| HALF_PERCENTAGE_FACTOR                                                             | 147             | 147 | 147    | 147 | 422     |
+| PERCENTAGE_FACTOR                                                                  | 224             | 224 | 224    | 224 | 667     |
 | percentDiv                                                                         | 321             | 426 | 432    | 432 | 259     |
-| percentMul                                                                         | 338             | 411 | 435    | 435 | 259     |
+| percentMul                                                                         | 338             | 402 | 435    | 435 | 259     |


 | src/contracts/mocks/tests/WadRayMathWrapper.sol:WadRayMathWrapper contract |                 |     |        |     |         |
@@ -813,16 +814,16 @@
 | 233882                                                                     | 871             |     |        |     |         |
 | Function Name                                                              | min             | avg | median | max | # calls |
 | HALF_RAY                                                                   | 247             | 247 | 247    | 247 | 1       |
-| HALF_WAD                                                                   | 224             | 224 | 224    | 224 | 443     |
+| HALF_WAD                                                                   | 224             | 224 | 224    | 224 | 433     |
 | RAY                                                                        | 225             | 225 | 225    | 225 | 1       |
-| WAD                                                                        | 180             | 180 | 180    | 180 | 658     |
-| WAD_RAY_RATIO                                                              | 269             | 269 | 269    | 269 | 1762    |
+| WAD                                                                        | 180             | 180 | 180    | 180 | 649     |
+| WAD_RAY_RATIO                                                              | 269             | 269 | 269    | 269 | 1765    |
 | rayDiv                                                                     | 498             | 498 | 498    | 498 | 4       |
 | rayMul                                                                     | 501             | 501 | 501    | 501 | 3       |
 | rayToWad                                                                   | 387             | 390 | 387    | 401 | 515     |
 | wadDiv                                                                     | 431             | 524 | 542    | 542 | 260     |
-| wadMul                                                                     | 338             | 409 | 435    | 435 | 262     |
-| wadToRay                                                                   | 284             | 355 | 360    | 360 | 485     |
+| wadMul                                                                     | 338             | 406 | 435    | 435 | 262     |
+| wadToRay                                                                   | 284             | 355 | 360    | 360 | 488     |


 | src/contracts/mocks/tokens/MockATokenRepayment.sol:MockATokenRepayment contract |                 |       |        |       |         |
@@ -907,23 +908,23 @@
 | Deployment Cost                                                         | Deployment Size |       |        |       |         |
 | 864174                                                                  | 4235            |       |        |       |         |
 | Function Name                                                           | min             | avg   | median | max   | # calls |
-| DEFAULT_ADMIN_ROLE                                                      | 284             | 284   | 284    | 284   | 1318    |
+| DEFAULT_ADMIN_ROLE                                                      | 284             | 284   | 284    | 284   | 1310    |
 | FLASH_BORROWER_ROLE                                                     | 317             | 317   | 317    | 317   | 20      |
-| POOL_ADMIN_ROLE                                                         | 294             | 294   | 294    | 294   | 649     |
+| POOL_ADMIN_ROLE                                                         | 294             | 294   | 294    | 294   | 645     |
 | addAssetListingAdmin                                                    | 50962           | 50962 | 50962  | 50962 | 3       |
 | addBridge                                                               | 51028           | 51028 | 51028  | 51028 | 14      |
 | addEmergencyAdmin                                                       | 50963           | 50963 | 50963  | 50963 | 3       |
 | addFlashBorrower                                                        | 50984           | 52203 | 50984  | 55863 | 4       |
-| addPoolAdmin                                                            | 50995           | 51006 | 51007  | 51007 | 639     |
+| addPoolAdmin                                                            | 50995           | 51006 | 51007  | 51007 | 635     |
 | addRiskAdmin                                                            | 51028           | 51028 | 51028  | 51028 | 14      |
 | grantRole                                                               | 51480           | 52091 | 51480  | 56370 | 8       |
 | hasRole                                                                 | 740             | 2622  | 2740   | 2740  | 17      |
-| isAssetListingAdmin                                                     | 814             | 2465  | 2814   | 2814  | 3562    |
+| isAssetListingAdmin                                                     | 814             | 2466  | 2814   | 2814  | 3554    |
 | isBridge                                                                | 2791            | 2791  | 2791   | 2791  | 26      |
 | isEmergencyAdmin                                                        | 747             | 2746  | 2747   | 2747  | 3843    |
 | isFlashBorrower                                                         | 2833            | 2833  | 2833   | 2833  | 268     |
-| isPoolAdmin                                                             | 757             | 1741  | 757    | 2757  | 45593   |
-| isRiskAdmin                                                             | 747             | 1420  | 747    | 2747  | 29906   |
+| isPoolAdmin                                                             | 757             | 1849  | 2757   | 2757  | 46656   |
+| isRiskAdmin                                                             | 747             | 1594  | 747    | 2747  | 30985   |
 | removeAssetListingAdmin                                                 | 29054           | 29054 | 29054  | 29054 | 2       |
 | removeBridge                                                            | 29023           | 29023 | 29023  | 29023 | 1       |
 | removeEmergencyAdmin                                                    | 28999           | 28999 | 28999  | 28999 | 1       |
@@ -938,24 +939,24 @@
 | Deployment Cost                                                                               | Deployment Size |        |        |        |         |
 | 1604102                                                                                       | 8368            |        |        |        |         |
 | Function Name                                                                                 | min             | avg    | median | max    | # calls |
-| getACLAdmin                                                                                   | 480             | 551    | 480    | 2480   | 676     |
-| getACLManager                                                                                 | 534             | 1369   | 534    | 2534   | 39760   |
-| getAddress                                                                                    | 546             | 549    | 546    | 2546   | 657     |
+| getACLAdmin                                                                                   | 480             | 551    | 480    | 2480   | 672     |
+| getACLManager                                                                                 | 534             | 1497   | 534    | 2534   | 40823   |
+| getAddress                                                                                    | 546             | 549    | 546    | 2546   | 653     |
 | getMarketId                                                                                   | 1351            | 1351   | 1351   | 1351   | 6       |
-| getPool                                                                                       | 469             | 682    | 469    | 2469   | 43331   |
-| getPoolConfigurator                                                                           | 512             | 774    | 512    | 2512   | 182138  |
-| getPoolDataProvider                                                                           | 489             | 1325   | 489    | 2489   | 2203    |
-| getPriceOracle                                                                                | 577             | 2281   | 2577   | 2577   | 7894    |
-| getPriceOracleSentinel                                                                        | 490             | 2484   | 2490   | 2490   | 6231    |
-| owner                                                                                         | 365             | 365    | 365    | 365    | 653     |
+| getPool                                                                                       | 469             | 660    | 469    | 2469   | 48324   |
+| getPoolConfigurator                                                                           | 512             | 800    | 512    | 2512   | 186919  |
+| getPoolDataProvider                                                                           | 489             | 1326   | 489    | 2489   | 2191    |
+| getPriceOracle                                                                                | 577             | 2188   | 2577   | 2577   | 9964    |
+| getPriceOracleSentinel                                                                        | 490             | 2484   | 2490   | 2490   | 6509    |
+| owner                                                                                         | 365             | 365    | 365    | 365    | 649     |
 | setACLAdmin                                                                                   | 24016           | 45798  | 47621  | 47621  | 24      |
 | setACLManager                                                                                 | 24059           | 37487  | 39114  | 47664  | 4       |
 | setAddress                                                                                    | 24625           | 35611  | 31540  | 48640  | 5       |
 | setAddressAsProxy                                                                             | 24331           | 228775 | 57063  | 518962 | 5       |
 | setMarketId                                                                                   | 24424           | 28561  | 28561  | 32699  | 2       |
-| setPoolConfiguratorImpl                                                                       | 24015           | 292593 | 300665 | 545030 | 4       |
+| setPoolConfiguratorImpl                                                                       | 24015           | 292580 | 300639 | 545030 | 4       |
 | setPoolDataProvider                                                                           | 24104           | 37532  | 39159  | 47709  | 4       |
-| setPoolImpl                                                                                   | 24060           | 279069 | 287138 | 517941 | 4       |
+| setPoolImpl                                                                                   | 24060           | 279024 | 287080 | 517876 | 4       |
 | setPriceOracle                                                                                | 24083           | 37511  | 39138  | 47688  | 4       |
 | setPriceOracleSentinel                                                                        | 24126           | 40946  | 47731  | 47731  | 6       |

@@ -968,7 +969,7 @@
 | getAddressesProviderAddressById                                                                               | 522             | 522    | 522    | 522    | 4       |
 | getAddressesProviderIdByAddress                                                                               | 559             | 1225   | 559    | 2559   | 6       |
 | getAddressesProvidersList                                                                                     | 673             | 3403   | 3292   | 5018   | 5       |
-| owner                                                                                                         | 331             | 2327   | 2331   | 2331   | 650     |
+| owner                                                                                                         | 331             | 2327   | 2331   | 2331   | 646     |
 | registerAddressesProvider                                                                                     | 24444           | 104012 | 119926 | 119926 | 6       |
 | unregisterAddressesProvider                                                                                   | 26448           | 39029  | 40004  | 49662  | 4       |

@@ -996,7 +997,7 @@
 | Deployment Cost                                                        | Deployment Size |        |        |        |         |
 | 3183382                                                                | 14716           |        |        |        |         |
 | Function Name                                                          | min             | avg    | median | max    | # calls |
-| EMISSION_MANAGER                                                       | 327             | 327    | 327    | 327    | 653     |
+| EMISSION_MANAGER                                                       | 327             | 327    | 327    | 327    | 649     |
 | claimAllRewards                                                        | 92349           | 92349  | 92349  | 92349  | 1       |
 | claimAllRewardsOnBehalf                                                | 94649           | 94649  | 94649  | 94649  | 1       |
 | claimAllRewardsToSelf                                                  | 92147           | 92147  | 92147  | 92147  | 1       |
@@ -1018,8 +1019,8 @@
 | getUserAccruedRewards                                                  | 1648            | 1648   | 1648   | 1648   | 1       |
 | getUserAssetIndex                                                      | 1009            | 1009   | 1009   | 1009   | 1       |
 | getUserRewards                                                         | 4600            | 6703   | 6832   | 10200  | 19      |
-| handleAction                                                           | 732             | 2337   | 2732   | 38089  | 17852   |
-| initialize                                                             | 26067           | 45246  | 45252  | 53156  | 652     |
+| handleAction                                                           | 732             | 2354   | 2732   | 38089  | 18613   |
+| initialize                                                             | 26067           | 45246  | 45252  | 53156  | 648     |
 | setClaimer                                                             | 24282           | 24282  | 24282  | 24282  | 4       |
 | setDistributionEnd                                                     | 8888            | 8888   | 8888   | 8888   | 2       |
 | setEmissionPerSecond                                                   | 24335           | 24335  | 24335  | 24335  | 2       |
@@ -1055,15 +1056,15 @@
 | Deployment Cost                                         | Deployment Size |       |        |       |         |
 | 0                                                       | 0               |       |        |       |         |
 | Function Name                                           | min             | avg   | median | max   | # calls |
-| initialize                                              | 90684           | 90684 | 90684  | 90684 | 674     |
+| initialize                                              | 90684           | 90684 | 90684  | 90684 | 670     |


 | src/deployments/projects/aave-v3-batched/batches/AaveV3GettersBatchOne.sol:AaveV3GettersBatchOne contract |                 |     |        |     |         |
 |-----------------------------------------------------------------------------------------------------------|-----------------|-----|--------|-----|---------|
 | Deployment Cost                                                                                           | Deployment Size |     |        |     |         |
-| 5190134                                                                                                   | 33125           |     |        |     |         |
+| 5144006                                                                                                   | 33345           |     |        |     |         |
 | Function Name                                                                                             | min             | avg | median | max | # calls |
-| getGettersReportOne                                                                                       | 971             | 971 | 971    | 971 | 672     |
+| getGettersReportOne                                                                                       | 971             | 971 | 971    | 971 | 668     |


 | src/deployments/projects/aave-v3-batched/batches/AaveV3GettersBatchTwo.sol:AaveV3GettersBatchTwo contract |                 |     |        |     |         |
@@ -1071,15 +1072,15 @@
 | Deployment Cost                                                                                           | Deployment Size |     |        |     |         |
 | 1583555                                                                                                   | 11792           |     |        |     |         |
 | Function Name                                                                                             | min             | avg | median | max | # calls |
-| getGettersReportTwo                                                                                       | 535             | 535 | 535    | 535 | 647     |
+| getGettersReportTwo                                                                                       | 535             | 535 | 535    | 535 | 643     |


 | src/deployments/projects/aave-v3-batched/batches/AaveV3HelpersBatchOne.sol:AaveV3HelpersBatchOne contract |                 |      |        |      |         |
 |-----------------------------------------------------------------------------------------------------------|-----------------|------|--------|------|---------|
 | Deployment Cost                                                                                           | Deployment Size |      |        |      |         |
-| 7434786                                                                                                   | 35360           |      |        |      |         |
+| 7379990                                                                                                   | 35117           |      |        |      |         |
 | Function Name                                                                                             | min             | avg  | median | max  | # calls |
-| getConfigEngineReport                                                                                     | 1696            | 1696 | 1696   | 1696 | 622     |
+| getConfigEngineReport                                                                                     | 1696            | 1696 | 1696   | 1696 | 618     |


 | src/deployments/projects/aave-v3-batched/batches/AaveV3HelpersBatchTwo.sol:AaveV3HelpersBatchTwo contract |                 |     |        |     |         |
@@ -1087,15 +1088,15 @@
 | Deployment Cost                                                                                           | Deployment Size |     |        |     |         |
 | 7169046                                                                                                   | 31590           |     |        |     |         |
 | Function Name                                                                                             | min             | avg | median | max | # calls |
-| staticATokenReport                                                                                        | 971             | 971 | 971    | 971 | 622     |
+| staticATokenReport                                                                                        | 971             | 971 | 971    | 971 | 618     |


 | src/deployments/projects/aave-v3-batched/batches/AaveV3L2PoolBatch.sol:AaveV3L2PoolBatch contract |                 |     |        |     |         |
 |---------------------------------------------------------------------------------------------------|-----------------|-----|--------|-----|---------|
 | Deployment Cost                                                                                   | Deployment Size |     |        |     |         |
-| 9289812                                                                                           | 42653           |     |        |     |         |
+| 9322069                                                                                           | 42803           |     |        |     |         |
 | Function Name                                                                                     | min             | avg | median | max | # calls |
-| getPoolReport                                                                                     | 535             | 535 | 535    | 535 | 672     |
+| getPoolReport                                                                                     | 535             | 535 | 535    | 535 | 668     |


 | src/deployments/projects/aave-v3-batched/batches/AaveV3MiscBatch.sol:AaveV3MiscBatch contract |                 |     |        |     |         |
@@ -1103,7 +1104,7 @@
 | Deployment Cost                                                                               | Deployment Size |     |        |     |         |
 | 1062926                                                                                       | 7122            |     |        |     |         |
 | Function Name                                                                                 | min             | avg | median | max | # calls |
-| getMiscReport                                                                                 | 535             | 535 | 535    | 535 | 672     |
+| getMiscReport                                                                                 | 535             | 535 | 535    | 535 | 668     |


 | src/deployments/projects/aave-v3-batched/batches/AaveV3ParaswapBatch.sol:AaveV3ParaswapBatch contract |                 |     |        |     |         |
@@ -1119,7 +1120,7 @@
 | Deployment Cost                                                                                         | Deployment Size |      |        |      |         |
 | 7573451                                                                                                 | 38861           |      |        |      |         |
 | Function Name                                                                                           | min             | avg  | median | max  | # calls |
-| getPeripheryReport                                                                                      | 1333            | 1333 | 1333   | 1333 | 672     |
+| getPeripheryReport                                                                                      | 1333            | 1333 | 1333   | 1333 | 668     |


 | src/deployments/projects/aave-v3-batched/batches/AaveV3SetupBatch.sol:AaveV3SetupBatch contract |                 |         |         |         |         |
@@ -1127,9 +1128,9 @@
 | Deployment Cost                                                                                 | Deployment Size |         |         |         |         |
 | 5147688                                                                                         | 28075           |         |         |         |         |
 | Function Name                                                                                   | min             | avg     | median  | max     | # calls |
-| getInitialReport                                                                                | 554             | 554     | 554     | 554     | 672     |
-| setMarketReport                                                                                 | 632455          | 634818  | 632455  | 773435  | 622     |
-| setupAaveV3Market                                                                               | 2709798         | 2710437 | 2709798 | 2736039 | 649     |
+| getInitialReport                                                                                | 554             | 554     | 554     | 554     | 668     |
+| setMarketReport                                                                                 | 632455          | 634834  | 632455  | 773435  | 618     |
+| setupAaveV3Market                                                                               | 2709798         | 2710433 | 2709798 | 2735948 | 645     |


 | src/deployments/projects/aave-v3-batched/batches/AaveV3TokensBatch.sol:AaveV3TokensBatch contract |                 |     |        |     |         |
@@ -1137,53 +1138,53 @@
 | Deployment Cost                                                                                   | Deployment Size |     |        |     |         |
 | 4294582                                                                                           | 20766           |     |        |     |         |
 | Function Name                                                                                     | min             | avg | median | max | # calls |
-| getTokensReport                                                                                   | 535             | 535 | 535    | 535 | 647     |
+| getTokensReport                                                                                   | 535             | 535 | 535    | 535 | 643     |


-| tests/extensions/v3-config-engine/mocks/AaveV3MockAssetEModeUpdate.sol:AaveV3MockAssetEModeUpdate contract |                 |       |        |       |         |
-|------------------------------------------------------------------------------------------------------------|-----------------|-------|--------|-------|---------|
-| Deployment Cost                                                                                            | Deployment Size |       |        |       |         |
-| 751213                                                                                                     | 3484            |       |        |       |         |
-| Function Name                                                                                              | min             | avg   | median | max   | # calls |
-| execute                                                                                                    | 94550           | 94550 | 94550  | 94550 | 1       |
+| tests/extensions/v3-config-engine/mocks/AaveV3MockAssetEModeUpdate.sol:AaveV3MockAssetEModeUpdate contract |                 |        |        |        |         |
+|------------------------------------------------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
+| Deployment Cost                                                                                            | Deployment Size |        |        |        |         |
+| 747109                                                                                                     | 3465            |        |        |        |         |
+| Function Name                                                                                              | min             | avg    | median | max    | # calls |
+| execute                                                                                                    | 118935          | 118935 | 118935 | 118935 | 1       |


 | tests/extensions/v3-config-engine/mocks/AaveV3MockBorrowUpdate.sol:AaveV3MockBorrowUpdate contract |                 |        |        |        |         |
 |----------------------------------------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
 | Deployment Cost                                                                                    | Deployment Size |        |        |        |         |
-| 783501                                                                                             | 3634            |        |        |        |         |
+| 775935                                                                                             | 3599            |        |        |        |         |
 | Function Name                                                                                      | min             | avg    | median | max    | # calls |
-| execute                                                                                            | 159425          | 159425 | 159425 | 159425 | 1       |
+| execute                                                                                            | 159601          | 159601 | 159601 | 159601 | 1       |


 | tests/extensions/v3-config-engine/mocks/AaveV3MockBorrowUpdateNoChange.sol:AaveV3MockBorrowUpdateNoChange contract |                 |       |        |       |         |
 |--------------------------------------------------------------------------------------------------------------------|-----------------|-------|--------|-------|---------|
 | Deployment Cost                                                                                                    | Deployment Size |       |        |       |         |
-| 790396                                                                                                             | 3666            |       |        |       |         |
+| 782829                                                                                                             | 3631            |       |        |       |         |
 | Function Name                                                                                                      | min             | avg   | median | max   | # calls |
-| execute                                                                                                            | 47089           | 47089 | 47089  | 47089 | 1       |
+| execute                                                                                                            | 47111           | 47111 | 47111  | 47111 | 1       |


 | tests/extensions/v3-config-engine/mocks/AaveV3MockCapUpdate.sol:AaveV3MockCapUpdate contract |                 |       |        |       |         |
 |----------------------------------------------------------------------------------------------|-----------------|-------|--------|-------|---------|
 | Deployment Cost                                                                              | Deployment Size |       |        |       |         |
-| 770601                                                                                       | 3574            |       |        |       |         |
+| 763034                                                                                       | 3539            |       |        |       |         |
 | Function Name                                                                                | min             | avg   | median | max   | # calls |
-| execute                                                                                      | 86135           | 86135 | 86135  | 86135 | 1       |
+| execute                                                                                      | 86134           | 86134 | 86134  | 86134 | 1       |


 | tests/extensions/v3-config-engine/mocks/AaveV3MockCollateralUpdate.sol:AaveV3MockCollateralUpdate contract |                 |       |        |       |         |
 |------------------------------------------------------------------------------------------------------------|-----------------|-------|--------|-------|---------|
 | Deployment Cost                                                                                            | Deployment Size |       |        |       |         |
-| 784137                                                                                                     | 3637            |       |        |       |         |
+| 776595                                                                                                     | 3602            |       |        |       |         |
 | Function Name                                                                                              | min             | avg   | median | max   | # calls |
-| execute                                                                                                    | 89667           | 89667 | 89667  | 89667 | 1       |
+| execute                                                                                                    | 89745           | 89745 | 89745  | 89745 | 1       |


 | tests/extensions/v3-config-engine/mocks/AaveV3MockCollateralUpdateNoChange.sol:AaveV3MockCollateralUpdateNoChange contract |                 |       |        |       |         |
 |----------------------------------------------------------------------------------------------------------------------------|-----------------|-------|--------|-------|---------|
 | Deployment Cost                                                                                                            | Deployment Size |       |        |       |         |
-| 790576                                                                                                                     | 3667            |       |        |       |         |
+| 783009                                                                                                                     | 3632            |       |        |       |         |
 | Function Name                                                                                                              | min             | avg   | median | max   | # calls |
 | execute                                                                                                                    | 35916           | 35916 | 35916  | 35916 | 2       |

@@ -1191,15 +1192,15 @@
 | tests/extensions/v3-config-engine/mocks/AaveV3MockCollateralUpdateWrongBonus.sol:AaveV3MockCollateralUpdateCorrectBonus contract |                 |       |        |       |         |
 |----------------------------------------------------------------------------------------------------------------------------------|-----------------|-------|--------|-------|---------|
 | Deployment Cost                                                                                                                  | Deployment Size |       |        |       |         |
-| 784137                                                                                                                           | 3637            |       |        |       |         |
+| 776595                                                                                                                           | 3602            |       |        |       |         |
 | Function Name                                                                                                                    | min             | avg   | median | max   | # calls |
-| execute                                                                                                                          | 89667           | 89667 | 89667  | 89667 | 1       |
+| execute                                                                                                                          | 89745           | 89745 | 89745  | 89745 | 1       |


 | tests/extensions/v3-config-engine/mocks/AaveV3MockCollateralUpdateWrongBonus.sol:AaveV3MockCollateralUpdateWrongBonus contract |                 |       |        |       |         |
 |--------------------------------------------------------------------------------------------------------------------------------|-----------------|-------|--------|-------|---------|
 | Deployment Cost                                                                                                                | Deployment Size |       |        |       |         |
-| 785049                                                                                                                         | 3641            |       |        |       |         |
+| 777483                                                                                                                         | 3606            |       |        |       |         |
 | Function Name                                                                                                                  | min             | avg   | median | max   | # calls |
 | execute                                                                                                                        | 35332           | 35332 | 35332  | 35332 | 1       |

@@ -1207,59 +1208,59 @@
 | tests/extensions/v3-config-engine/mocks/AaveV3MockEModeCategoryUpdate.sol:AaveV3MockEModeCategoryUpdate contract |                 |        |        |        |         |
 |------------------------------------------------------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
 | Deployment Cost                                                                                                  | Deployment Size |        |        |        |         |
-| 756400                                                                                                           | 3425            |        |        |        |         |
+| 745395                                                                                                           | 3374            |        |        |        |         |
 | Function Name                                                                                                    | min             | avg    | median | max    | # calls |
-| execute                                                                                                          | 155461          | 155461 | 155461 | 155461 | 2       |
+| execute                                                                                                          | 131198          | 131198 | 131198 | 131198 | 2       |


 | tests/extensions/v3-config-engine/mocks/AaveV3MockEModeCategoryUpdate.sol:AaveV3MockEModeCategoryUpdateEdgeBonus contract |                 |       |        |       |         |
 |---------------------------------------------------------------------------------------------------------------------------|-----------------|-------|--------|-------|---------|
 | Deployment Cost                                                                                                           | Deployment Size |       |        |       |         |
-| 757072                                                                                                                    | 3428            |       |        |       |         |
+| 746007                                                                                                                    | 3377            |       |        |       |         |
 | Function Name                                                                                                             | min             | avg   | median | max   | # calls |
-| execute                                                                                                                   | 53964           | 53964 | 53964  | 53964 | 1       |
+| execute                                                                                                                   | 56384           | 56384 | 56384  | 56384 | 1       |


 | tests/extensions/v3-config-engine/mocks/AaveV3MockEModeCategoryUpdateNoChange.sol:AaveV3MockEModeCategoryUpdateNoChange contract |                 |       |        |       |         |
 |----------------------------------------------------------------------------------------------------------------------------------|-----------------|-------|--------|-------|---------|
 | Deployment Cost                                                                                                                  | Deployment Size |       |        |       |         |
-| 770849                                                                                                                           | 3492            |       |        |       |         |
+| 759832                                                                                                                           | 3441            |       |        |       |         |
 | Function Name                                                                                                                    | min             | avg   | median | max   | # calls |
-| execute                                                                                                                          | 38497           | 38497 | 38497  | 38497 | 2       |
+| execute                                                                                                                          | 37835           | 37835 | 37835  | 37835 | 2       |


 | tests/extensions/v3-config-engine/mocks/AaveV3MockListing.sol:AaveV3MockListing contract |                 |         |         |         |         |
 |------------------------------------------------------------------------------------------|-----------------|---------|---------|---------|---------|
 | Deployment Cost                                                                          | Deployment Size |         |         |         |         |
-| 853685                                                                                   | 4030            |         |         |         |         |
+| 849574                                                                                   | 4011            |         |         |         |         |
 | Function Name                                                                            | min             | avg     | median  | max     | # calls |
-| execute                                                                                  | 1836009         | 1836009 | 1836009 | 1836009 | 1       |
+| execute                                                                                  | 1823723         | 1823723 | 1823723 | 1823723 | 1       |
 | newListings                                                                              | 2820            | 2820    | 2820    | 2820    | 4       |


 | tests/extensions/v3-config-engine/mocks/AaveV3MockListingCustom.sol:AaveV3MockListingCustom contract |                 |         |         |         |         |
 |------------------------------------------------------------------------------------------------------|-----------------|---------|---------|---------|---------|
 | Deployment Cost                                                                                      | Deployment Size |         |         |         |         |
-| 918454                                                                                               | 4491            |         |         |         |         |
+| 914350                                                                                               | 4472            |         |         |         |         |
 | Function Name                                                                                        | min             | avg     | median  | max     | # calls |
-| execute                                                                                              | 1835953         | 1835953 | 1835953 | 1835953 | 1       |
+| execute                                                                                              | 1823667         | 1823667 | 1823667 | 1823667 | 1       |
 | newListingsCustom                                                                                    | 3295            | 3295    | 3295    | 3295    | 4       |


 | tests/extensions/v3-config-engine/mocks/AaveV3MockPriceFeedUpdate.sol:AaveV3MockPriceFeedUpdate contract |                 |       |        |       |         |
 |----------------------------------------------------------------------------------------------------------|-----------------|-------|--------|-------|---------|
 | Deployment Cost                                                                                          | Deployment Size |       |        |       |         |
-| 774000                                                                                                   | 3660            |       |        |       |         |
+| 769896                                                                                                   | 3641            |       |        |       |         |
 | Function Name                                                                                            | min             | avg   | median | max   | # calls |
-| execute                                                                                                  | 65371           | 65371 | 65371  | 65371 | 1       |
+| execute                                                                                                  | 65393           | 65393 | 65393  | 65393 | 1       |


 | tests/extensions/v3-config-engine/mocks/AaveV3MockRatesUpdate.sol:AaveV3MockRatesUpdate contract |                 |        |        |        |         |
 |--------------------------------------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
 | Deployment Cost                                                                                  | Deployment Size |        |        |        |         |
-| 772773                                                                                           | 3584            |        |        |        |         |
+| 768681                                                                                           | 3565            |        |        |        |         |
 | Function Name                                                                                    | min             | avg    | median | max    | # calls |
-| execute                                                                                          | 148663          | 148663 | 148663 | 148663 | 1       |
+| execute                                                                                          | 148773          | 148773 | 148773 | 148773 | 1       |
 | rateStrategiesUpdates                                                                            | 1184            | 1184   | 1184   | 1184   | 4       |


@@ -1273,15 +1274,15 @@
 | UNDERLYING_ASSET_ADDRESS                                              | 376             | 1200   | 376    | 2376   | 4354    |
 | allowance                                                             | 909             | 909    | 909    | 909    | 1       |
 | approve                                                               | 22107           | 22107  | 22107  | 22107  | 1       |
-| approveDelegation                                                     | 48608           | 48637  | 48632  | 48680  | 256     |
-| burn                                                                  | 52036           | 52064  | 52060  | 52108  | 512     |
+| approveDelegation                                                     | 48608           | 48638  | 48632  | 48680  | 256     |
+| burn                                                                  | 52036           | 52063  | 52060  | 52108  | 512     |
 | decimals                                                              | 335             | 335    | 335    | 335    | 3330    |
 | decreaseAllowance                                                     | 22128           | 22128  | 22128  | 22128  | 1       |
 | getIncentivesController                                               | 431             | 431    | 431    | 431    | 3330    |
 | increaseAllowance                                                     | 22128           | 22128  | 22128  | 22128  | 1       |
-| initialize                                                            | 29524           | 148072 | 179097 | 270713 | 2048    |
-| mint                                                                  | 86763           | 88040  | 86799  | 91824  | 1024    |
-| name                                                                  | 1009            | 1332   | 1264   | 1796   | 3330    |
+| initialize                                                            | 29500           | 146691 | 179067 | 270797 | 2048    |
+| mint                                                                  | 86763           | 88039  | 86799  | 91824  | 1024    |
+| name                                                                  | 1009            | 1328   | 1264   | 1796   | 3330    |
 | scaledBalanceOf                                                       | 691             | 691    | 691    | 691    | 1024    |
 | symbol                                                                | 1030            | 1351   | 1285   | 1817   | 3330    |
 | transfer                                                              | 22150           | 22150  | 22150  | 22150  | 1       |
@@ -1291,11 +1292,11 @@
 | tests/mocks/AaveV3TestListing.sol:AaveV3TestListing contract |                 |         |         |         |         |
 |--------------------------------------------------------------|-----------------|---------|---------|---------|---------|
 | Deployment Cost                                              | Deployment Size |         |         |         |         |
-| 3392063                                                      | 13846           |         |         |         |         |
+| 3391415                                                      | 13843           |         |         |         |         |
 | Function Name                                                | min             | avg     | median  | max     | # calls |
-| USDX_ADDRESS                                                 | 294             | 294     | 294     | 294     | 617     |
-| WBTC_ADDRESS                                                 | 250             | 250     | 250     | 250     | 617     |
-| execute                                                      | 5227666         | 5230040 | 5230240 | 5230240 | 619     |
+| USDX_ADDRESS                                                 | 294             | 294     | 294     | 294     | 613     |
+| WBTC_ADDRESS                                                 | 250             | 250     | 250     | 250     | 613     |
+| execute                                                      | 5190851         | 5193099 | 5193290 | 5193290 | 615     |


 | tests/mocks/AugustusRegistryMock.sol:AugustusRegistryMock contract |                 |     |        |     |         |
@@ -1332,4 +1333,4 @@



-Ran 56 test suites in 75.93s (123.90s CPU time): 694 tests passed, 0 failed, 0 skipped (694 total tests)
+Ran 57 test suites in 74.55s (146.31s CPU time): 690 tests passed, 0 failed, 0 skipped (690 total tests)
```
