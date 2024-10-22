```diff
diff --git a/reports/gas.old b/reports/gas.new
index 6249f68..111aa38 100644
--- a/reports/gas.old
+++ b/reports/gas.new
@@ -3,7 +3,7 @@
 | Deployment Cost                                          | Deployment Size |        |        |        |         |
 | 827595                                                   | 3611            |        |        |        |         |
 | Function Name                                            | min             | avg    | median | max    | # calls |
-| balanceOf                                                | 579             | 1100   | 579    | 2579   | 1775    |
+| balanceOf                                                | 579             | 1102   | 579    | 2579   | 1775    |
 | initialize                                               | 157662          | 157662 | 157662 | 157662 | 30      |


@@ -30,26 +30,26 @@
 | balanceOf                                                                                                               | 1442            | 1442    | 1442    | 1442    | 1       |
 | canPause                                                                                                                | 18899           | 18899   | 18899   | 18899   | 56      |
 | claimRewardsToSelf                                                                                                      | 32178           | 32178   | 32178   | 32178   | 1       |
-| createStataTokens                                                                                                       | 2513736         | 2513736 | 2513736 | 2513736 | 23      |
+| createStataTokens                                                                                                       | 2436116         | 2436116 | 2436116 | 2436116 | 23      |
 | decimals                                                                                                                | 1404            | 1404    | 1404    | 1404    | 1       |
-| deposit                                                                                                                 | 296168          | 296168  | 296168  | 296168  | 1       |
-| depositATokens                                                                                                          | 176709          | 179776  | 176721  | 218511  | 55      |
-| emergencyTokenTransfer                                                                                                  | 35389           | 153752  | 157301  | 174420  | 54      |
+| deposit                                                                                                                 | 287548          | 287548  | 287548  | 287548  | 1       |
+| depositATokens                                                                                                          | 176775          | 179779  | 176787  | 218577  | 56      |
+| emergencyTokenTransfer                                                                                                  | 35389           | 153894  | 157389  | 174508  | 55      |
 | getReferenceAsset                                                                                                       | 3277            | 3277    | 3277    | 3277    | 1       |
 | getStataToken                                                                                                           | 1358            | 1358    | 1358    | 1358    | 23      |
 | maxRedeem                                                                                                               | 8261            | 8261    | 8261    | 8261    | 2       |
-| maxWithdraw                                                                                                             | 10927           | 10927   | 10927   | 10927   | 1       |
-| mint                                                                                                                    | 296262          | 296262  | 296262  | 296262  | 1       |
+| maxWithdraw                                                                                                             | 10949           | 10949   | 10949   | 10949   | 1       |
+| mint                                                                                                                    | 287642          | 287642  | 287642  | 287642  | 1       |
 | name                                                                                                                    | 10669           | 10669   | 10669   | 10669   | 1       |
 | nonces                                                                                                                  | 10065           | 10065   | 10065   | 10065   | 3       |
 | paused                                                                                                                  | 1255            | 5505    | 5505    | 9755    | 2       |
 | permit                                                                                                                  | 31430           | 61234   | 63913   | 88360   | 3       |
-| previewDeposit                                                                                                          | 23248           | 23248   | 23248   | 23248   | 1       |
-| redeem                                                                                                                  | 60981           | 60981   | 60981   | 60981   | 1       |
+| previewDeposit                                                                                                          | 23270           | 23270   | 23270   | 23270   | 1       |
+| redeem                                                                                                                  | 61003           | 61003   | 61003   | 61003   | 1       |
 | setPaused                                                                                                               | 40089           | 42730   | 40089   | 63486   | 62      |
 | symbol                                                                                                                  | 4181            | 4181    | 4181    | 4181    | 1       |
 | transfer                                                                                                                | 31688           | 31688   | 31688   | 31688   | 1       |
-| withdraw                                                                                                                | 63648           | 63648   | 63648   | 63648   | 1       |
+| withdraw                                                                                                                | 63692           | 63692   | 63692   | 63692   | 1       |


 | src/contracts/dependencies/weth/WETH9.sol:WETH9 contract |                 |       |        |       |         |
@@ -58,9 +58,9 @@
 | 535043                                                   | 2354            |       |        |       |         |
 | Function Name                                            | min             | avg   | median | max   | # calls |
 | allowance                                                | 800             | 1500  | 800    | 2800  | 20      |
-| approve                                                  | 28992           | 45929 | 46464  | 46464 | 1763    |
-| balanceOf                                                | 538             | 948   | 538    | 2538  | 8921    |
-| decimals                                                 | 2312            | 2312  | 2312   | 2312  | 687     |
+| approve                                                  | 28992           | 45952 | 46464  | 46464 | 2010    |
+| balanceOf                                                | 538             | 965   | 538    | 2538  | 10527   |
+| decimals                                                 | 2312            | 2312  | 2312   | 2312  | 871     |
 | symbol                                                   | 1209            | 2246  | 3209   | 3209  | 27      |


@@ -80,29 +80,29 @@
 | src/contracts/extensions/paraswap-adapters/ParaSwapLiquiditySwapAdapter.sol:ParaSwapLiquiditySwapAdapter contract |                 |        |        |        |         |
 |-------------------------------------------------------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
 | Deployment Cost                                                                                                   | Deployment Size |        |        |        |         |
-| 2013105                                                                                                           | 9946            |        |        |        |         |
+| 1907377                                                                                                           | 9465            |        |        |        |         |
 | Function Name                                                                                                     | min             | avg    | median | max    | # calls |
 | owner                                                                                                             | 384             | 384    | 384    | 384    | 2       |
-| swapAndDeposit                                                                                                    | 354784          | 445579 | 477520 | 504434 | 3       |
+| swapAndDeposit                                                                                                    | 343811          | 435867 | 468438 | 495352 | 3       |


 | src/contracts/extensions/paraswap-adapters/ParaSwapRepayAdapter.sol:ParaSwapRepayAdapter contract |                 |        |        |        |         |
 |---------------------------------------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
 | Deployment Cost                                                                                   | Deployment Size |        |        |        |         |
-| 2140443                                                                                           | 10623           |        |        |        |         |
+| 2033146                                                                                           | 10135           |        |        |        |         |
 | Function Name                                                                                     | min             | avg    | median | max    | # calls |
 | owner                                                                                             | 406             | 406    | 406    | 406    | 2       |
 | rescueTokens                                                                                      | 36115           | 36115  | 36115  | 36115  | 1       |
-| swapAndRepay                                                                                      | 404190          | 512323 | 538923 | 567258 | 4       |
+| swapAndRepay                                                                                      | 376460          | 491714 | 520806 | 548783 | 4       |


 | src/contracts/extensions/paraswap-adapters/ParaSwapWithdrawSwapAdapter.sol:ParaSwapWithdrawSwapAdapter contract |                 |        |        |        |         |
 |-----------------------------------------------------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
 | Deployment Cost                                                                                                 | Deployment Size |        |        |        |         |
-| 1726578                                                                                                         | 8547            |        |        |        |         |
+| 1587776                                                                                                         | 7905            |        |        |        |         |
 | Function Name                                                                                                   | min             | avg    | median | max    | # calls |
 | owner                                                                                                           | 406             | 406    | 406    | 406    | 2       |
-| withdrawAndSwap                                                                                                 | 354732          | 380661 | 373324 | 413928 | 3       |
+| withdrawAndSwap                                                                                                 | 343759          | 371139 | 364527 | 405131 | 3       |


 | src/contracts/extensions/static-a-token/StataTokenFactory.sol:StataTokenFactory contract |                 |         |         |         |         |
@@ -111,9 +111,9 @@
 | 0                                                                                        | 0               |         |         |         |         |
 | Function Name                                                                            | min             | avg     | median  | max     | # calls |
 | STATA_TOKEN_IMPL                                                                         | 248             | 248     | 248     | 248     | 1       |
-| createStataTokens                                                                        | 2483966         | 2483966 | 2483966 | 2483966 | 23      |
+| createStataTokens                                                                        | 2406346         | 2406346 | 2406346 | 2406346 | 23      |
 | getStataToken                                                                            | 569             | 569     | 569     | 569     | 23      |
-| initialize                                                                               | 24103           | 24103   | 24103   | 24103   | 655     |
+| initialize                                                                               | 24103           | 24103   | 24103   | 24103   | 671     |


 | src/contracts/extensions/static-a-token/StataTokenV2.sol:StataTokenV2 contract |                 |        |        |        |         |
@@ -130,24 +130,24 @@
 | canPause                                                                       | 11610           | 11610  | 11610  | 11610  | 56      |
 | claimRewardsToSelf                                                             | 3167            | 3167   | 3167   | 3167   | 1       |
 | decimals                                                                       | 618             | 618    | 618    | 618    | 1       |
-| deposit                                                                        | 267243          | 267243 | 267243 | 267243 | 1       |
-| depositATokens                                                                 | 157445          | 160480 | 157445 | 199187 | 55      |
-| emergencyTokenTransfer                                                         | 6081            | 124656 | 128054 | 149925 | 54      |
+| deposit                                                                        | 258623          | 258623 | 258623 | 258623 | 1       |
+| depositATokens                                                                 | 157511          | 160492 | 157511 | 199253 | 56      |
+| emergencyTokenTransfer                                                         | 6081            | 124802 | 128142 | 150013 | 55      |
 | getReferenceAsset                                                              | 2491            | 2491   | 2491   | 2491   | 1       |
 | initialize                                                                     | 25518           | 231417 | 232108 | 239108 | 70      |
 | maxRedeem                                                                      | 7472            | 7472   | 7472   | 7472   | 2       |
-| maxWithdraw                                                                    | 10138           | 10138  | 10138  | 10138  | 1       |
-| mint                                                                           | 267337          | 267337 | 267337 | 267337 | 1       |
+| maxWithdraw                                                                    | 10160           | 10160  | 10160  | 10160  | 1       |
+| mint                                                                           | 258717          | 258717 | 258717 | 258717 | 1       |
 | name                                                                           | 3377            | 3377   | 3377   | 3377   | 1       |
 | nonces                                                                         | 2776            | 2776   | 2776   | 2776   | 3       |
 | paused                                                                         | 469             | 1469   | 1469   | 2469   | 2       |
 | permit                                                                         | 776             | 30653  | 33460  | 57725  | 3       |
-| previewDeposit                                                                 | 15959           | 15959  | 15959  | 15959  | 1       |
-| redeem                                                                         | 31682           | 31682  | 31682  | 31682  | 1       |
+| previewDeposit                                                                 | 15981           | 15981  | 15981  | 15981  | 1       |
+| redeem                                                                         | 31704           | 31704  | 31704  | 31704  | 1       |
 | setPaused                                                                      | 11592           | 14234  | 11592  | 34996  | 62      |
 | symbol                                                                         | 3389            | 3389   | 3389   | 3389   | 1       |
 | transfer                                                                       | 2763            | 2763   | 2763   | 2763   | 1       |
-| withdraw                                                                       | 34349           | 34349  | 34349  | 34349  | 1       |
+| withdraw                                                                       | 34393           | 34393  | 34393  | 34393  | 1       |


 | src/contracts/extensions/v3-config-engine/AaveV3ConfigEngine.sol:AaveV3ConfigEngine contract |                 |         |         |         |         |
@@ -156,15 +156,15 @@
 | 0                                                                                            | 0               |         |         |         |         |
 | Function Name                                                                                | min             | avg     | median  | max     | # calls |
 | DEFAULT_INTEREST_RATE_STRATEGY                                                               | 270             | 270     | 270     | 270     | 5       |
-| listAssets                                                                                   | 1804427         | 1804427 | 1804427 | 1804427 | 1       |
-| listAssetsCustom                                                                             | 1803763         | 5189401 | 5194695 | 5194695 | 649     |
-| updateAssetsEMode                                                                            | 190633          | 190633  | 190633  | 190633  | 1       |
-| updateBorrowSide                                                                             | 20061           | 76217   | 76217   | 132373  | 2       |
+| listAssets                                                                                   | 1792070         | 1792070 | 1792070 | 1792070 | 1       |
+| listAssetsCustom                                                                             | 1791406         | 5156369 | 5161624 | 5161624 | 665     |
+| updateAssetsEMode                                                                            | 179132          | 179132  | 179132  | 179132  | 1       |
+| updateBorrowSide                                                                             | 20039           | 76074   | 76074   | 132110  | 2       |
 | updateCaps                                                                                   | 59693           | 59693   | 59693   | 59693   | 1       |
 | updateCollateralSide                                                                         | 8750            | 30432   | 8874    | 62831   | 5       |
-| updateEModeCategories                                                                        | 10596           | 50460   | 28409   | 101350  | 5       |
+| updateEModeCategories                                                                        | 10596           | 50688   | 28454   | 101899  | 5       |
 | updatePriceFeeds                                                                             | 39269           | 39269   | 39269   | 39269   | 1       |
-| updateRateStrategies                                                                         | 124920          | 124920  | 124920  | 124920  | 1       |
+| updateRateStrategies                                                                         | 118868          | 118868  | 118868  | 118868  | 1       |


 | src/contracts/helpers/AaveProtocolDataProvider.sol:AaveProtocolDataProvider contract |                 |       |        |       |         |
@@ -172,21 +172,21 @@
 | Deployment Cost                                                                      | Deployment Size |       |        |       |         |
 | 0                                                                                    | 0               |       |        |       |         |
 | Function Name                                                                        | min             | avg   | median | max   | # calls |
-| getATokenTotalSupply                                                                 | 12822           | 13973 | 12866  | 25922 | 2026    |
-| getAllReservesTokens                                                                 | 16144           | 28640 | 39644  | 39644 | 27      |
-| getDebtCeiling                                                                       | 3244            | 3244  | 3244   | 3244  | 4       |
+| getATokenTotalSupply                                                                 | 6409            | 7551  | 6453   | 19531 | 2074    |
+| getAllReservesTokens                                                                 | 16077           | 28573 | 39577  | 39577 | 27      |
+| getDebtCeiling                                                                       | 3222            | 3222  | 3222   | 3222  | 4       |
 | getDebtCeilingDecimals                                                               | 214             | 214   | 214    | 214   | 1       |
 | getFlashLoanEnabled                                                                  | 3217            | 4217  | 4217   | 5217  | 110     |
-| getInterestRateStrategyAddress                                                       | 9534            | 21418 | 9534   | 43034 | 9       |
-| getIsVirtualAccActive                                                                | 3245            | 3266  | 3267   | 3267  | 2096    |
-| getLiquidationProtocolFee                                                            | 3266            | 9488  | 5266   | 16766 | 9       |
-| getPaused                                                                            | 3333            | 3409  | 3355   | 5355  | 2162    |
-| getReserveCaps                                                                       | 3267            | 8149  | 3267   | 16767 | 47      |
-| getReserveConfigurationData                                                          | 3659            | 3830  | 3681   | 17181 | 2476    |
-| getReserveTokensAddresses                                                            | 9510            | 15172 | 15554  | 43054 | 2739    |
+| getInterestRateStrategyAddress                                                       | 7745            | 17853 | 7745   | 37245 | 9       |
+| getIsVirtualAccActive                                                                | 3245            | 3266  | 3267   | 3267  | 2237    |
+| getLiquidationProtocolFee                                                            | 3244            | 9466  | 5244   | 16744 | 9       |
+| getPaused                                                                            | 3311            | 3384  | 3333   | 5333  | 2303    |
+| getReserveCaps                                                                       | 3245            | 8127  | 3245   | 16745 | 47      |
+| getReserveConfigurationData                                                          | 3637            | 3805  | 3659   | 17159 | 2621    |
+| getReserveTokensAddresses                                                            | 4808            | 5210  | 4874   | 20374 | 2902    |
 | getSiloedBorrowing                                                                   | 3270            | 3270  | 3270   | 3270  | 1       |
-| getTotalDebt                                                                         | 54903           | 54903 | 54903  | 54903 | 3       |
-| getUserReserveData                                                                   | 19863           | 28216 | 27941  | 46863 | 287     |
+| getTotalDebt                                                                         | 32479           | 32479 | 32479  | 32479 | 3       |
+| getUserReserveData                                                                   | 18096           | 24010 | 22556  | 41096 | 65      |


 | src/contracts/helpers/L2Encoder.sol:L2Encoder contract |                 |       |        |       |         |
@@ -194,15 +194,15 @@
 | Deployment Cost                                        | Deployment Size |       |        |       |         |
 | 0                                                      | 0               |       |        |       |         |
 | Function Name                                          | min             | avg   | median | max   | # calls |
-| encodeBorrowParams                                     | 8851            | 8851  | 8851   | 8851  | 3       |
-| encodeLiquidationCall                                  | 23237           | 23237 | 23237  | 23237 | 1       |
-| encodeRepayParams                                      | 8734            | 8734  | 8734   | 8734  | 1       |
-| encodeRepayWithATokensParams                           | 8761            | 8761  | 8761   | 8761  | 1       |
-| encodeRepayWithPermitParams                            | 13218           | 13218 | 13218  | 13218 | 51      |
-| encodeSetUserUseReserveAsCollateral                    | 8676            | 8676  | 8676   | 8676  | 1       |
-| encodeSupplyParams                                     | 40279           | 40279 | 40279  | 40279 | 7       |
-| encodeSupplyWithPermitParams                           | 40633           | 40633 | 40633  | 40633 | 54      |
-| encodeWithdrawParams                                   | 8620            | 8653  | 8653   | 8687  | 2       |
+| encodeBorrowParams                                     | 7084            | 7084  | 7084   | 7084  | 3       |
+| encodeLiquidationCall                                  | 13703           | 13703 | 13703  | 13703 | 1       |
+| encodeRepayParams                                      | 6967            | 6967  | 6967   | 6967  | 1       |
+| encodeRepayWithATokensParams                           | 6994            | 6994  | 6994   | 6994  | 1       |
+| encodeRepayWithPermitParams                            | 7451            | 7451  | 7451   | 7451  | 55      |
+| encodeSetUserUseReserveAsCollateral                    | 6909            | 6909  | 6909   | 6909  | 1       |
+| encodeSupplyParams                                     | 32012           | 32012 | 32012  | 32012 | 7       |
+| encodeSupplyWithPermitParams                           | 32366           | 32366 | 32366  | 32366 | 54      |
+| encodeWithdrawParams                                   | 6853            | 6886  | 6886   | 6920  | 2       |


 | src/contracts/helpers/WrappedTokenGatewayV3.sol:WrappedTokenGatewayV3 contract |                 |        |        |        |         |
@@ -210,54 +210,54 @@
 | Deployment Cost                                                                | Deployment Size |        |        |        |         |
 | 0                                                                              | 0               |        |        |        |         |
 | Function Name                                                                  | min             | avg    | median | max    | # calls |
-| borrowETH                                                                      | 252616          | 252616 | 252616 | 252616 | 1       |
-| depositETH                                                                     | 239979          | 239979 | 239979 | 239979 | 8       |
+| borrowETH                                                                      | 252242          | 252242 | 252242 | 252242 | 1       |
+| depositETH                                                                     | 239627          | 239627 | 239627 | 239627 | 8       |
 | emergencyEtherTransfer                                                         | 33792           | 33792  | 33792  | 33792  | 1       |
 | emergencyTokenTransfer                                                         | 52863           | 52863  | 52863  | 52863  | 1       |
 | getWETHAddress                                                                 | 200             | 200    | 200    | 200    | 1       |
 | owner                                                                          | 373             | 373    | 373    | 373    | 2       |
 | receive                                                                        | 21206           | 21206  | 21206  | 21206  | 1       |
-| repayETH                                                                       | 180936          | 184941 | 182826 | 192647 | 5       |
-| withdrawETH                                                                    | 233365          | 237691 | 237691 | 242018 | 2       |
-| withdrawETHWithPermit                                                          | 278174          | 281068 | 281068 | 283962 | 2       |
+| repayETH                                                                       | 167702          | 171709 | 169592 | 179417 | 5       |
+| withdrawETH                                                                    | 224876          | 228141 | 228141 | 231407 | 2       |
+| withdrawETHWithPermit                                                          | 267563          | 270457 | 270457 | 273351 | 2       |


 | src/contracts/instances/ATokenInstance.sol:ATokenInstance contract |                 |        |        |        |         |
 |--------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
 | Deployment Cost                                                    | Deployment Size |        |        |        |         |
-| 2316688                                                            | 11090           |        |        |        |         |
+| 2316755                                                            | 11090           |        |        |        |         |
 | Function Name                                                      | min             | avg    | median | max    | # calls |
 | DOMAIN_SEPARATOR                                                   | 455             | 2439   | 2455   | 3539   | 59      |
 | POOL                                                               | 326             | 326    | 326    | 326    | 110     |
-| RESERVE_TREASURY_ADDRESS                                           | 419             | 796    | 419    | 2419   | 2583    |
-| UNDERLYING_ASSET_ADDRESS                                           | 441             | 530    | 441    | 2441   | 2190    |
+| RESERVE_TREASURY_ADDRESS                                           | 419             | 984    | 419    | 2419   | 3118    |
+| UNDERLYING_ASSET_ADDRESS                                           | 441             | 525    | 441    | 2441   | 2331    |
 | allowance                                                          | 782             | 1551   | 782    | 2782   | 26      |
-| approve                                                            | 24586           | 24586  | 24586  | 24586  | 677     |
-| balanceOf                                                          | 2749            | 4649   | 4749   | 17749  | 1855    |
-| burn                                                               | 904             | 42208  | 37139  | 63239  | 642     |
-| decimals                                                           | 356             | 375    | 356    | 2356   | 2113    |
+| approve                                                            | 24586           | 24586  | 24586  | 24586  | 678     |
+| balanceOf                                                          | 2771            | 4533   | 4771   | 17771  | 3057    |
+| burn                                                               | 904             | 38540  | 37139  | 63239  | 1267    |
+| decimals                                                           | 356             | 370    | 356    | 2356   | 2823    |
 | decreaseAllowance                                                  | 7705            | 7705   | 7705   | 7705   | 1       |
-| getIncentivesController                                            | 474             | 475    | 474    | 2474   | 2096    |
+| getIncentivesController                                            | 474             | 475    | 474    | 2474   | 2237    |
 | getPreviousIndex                                                   | 651             | 651    | 651    | 651    | 39      |
 | getScaledUserBalanceAndSupply                                      | 826             | 2730   | 2826   | 4826   | 21      |
-| handleRepayment                                                    | 594             | 594    | 594    | 594    | 615     |
+| handleRepayment                                                    | 594             | 594    | 594    | 594    | 1089    |
 | increaseAllowance                                                  | 7772            | 20597  | 24872  | 24872  | 4       |
-| initialize                                                         | 146492          | 222080 | 231686 | 321621 | 11188   |
-| mint                                                               | 932             | 62097  | 64402  | 72156  | 2844    |
+| initialize                                                         | 146492          | 222913 | 231686 | 321621 | 11377   |
+| mint                                                               | 932             | 60896  | 64402  | 72156  | 3841    |
 | mintToTreasury                                                     | 442             | 43917  | 49192  | 66292  | 6       |
-| name                                                               | 1004            | 1504   | 1319   | 3259   | 2262    |
+| name                                                               | 1004            | 1497   | 1319   | 3259   | 2403    |
 | nonces                                                             | 652             | 2556   | 2652   | 2652   | 63      |
 | permit                                                             | 1108            | 24836  | 9503   | 53488  | 180     |
 | rescueTokens                                                       | 12022           | 24398  | 14240  | 46933  | 3       |
-| scaledBalanceOf                                                    | 687             | 1945   | 2687   | 2687   | 3270    |
+| scaledBalanceOf                                                    | 687             | 1728   | 2687   | 2687   | 6322    |
 | scaledTotalSupply                                                  | 373             | 2327   | 2373   | 2373   | 87      |
 | setIncentivesController                                            | 11924           | 14301  | 14301  | 16678  | 2       |
-| symbol                                                             | 1069            | 1563   | 1619   | 3324   | 2244    |
-| totalSupply                                                        | 407             | 3765   | 2407   | 10463  | 2986    |
-| transfer                                                           | 576             | 105606 | 111152 | 140167 | 233     |
-| transferFrom                                                       | 2998            | 100539 | 118585 | 142842 | 846     |
-| transferOnLiquidation                                              | 981             | 31261  | 37477  | 44277  | 440     |
-| transferUnderlyingTo                                               | 796             | 23309  | 16488  | 33627  | 902     |
+| symbol                                                             | 1069            | 1556   | 1619   | 3324   | 2385    |
+| totalSupply                                                        | 407             | 4193   | 2407   | 10485  | 3619    |
+| transfer                                                           | 576             | 104969 | 111196 | 140211 | 234     |
+| transferFrom                                                       | 2998            | 100740 | 118629 | 165386 | 847     |
+| transferOnLiquidation                                              | 981             | 34292  | 37499  | 44299  | 885     |
+| transferUnderlyingTo                                               | 796             | 23926  | 16488  | 33627  | 1487    |


 | src/contracts/instances/L2PoolInstance.sol:L2PoolInstance contract |                 |        |        |        |         |
@@ -267,54 +267,56 @@
 | Function Name                                                      | min             | avg    | median | max    | # calls |
 | ADDRESSES_PROVIDER                                                 | 351             | 351    | 351    | 351    | 177     |
 | FLASHLOAN_PREMIUM_TOTAL                                            | 388             | 1388   | 1388   | 2388   | 126     |
-| FLASHLOAN_PREMIUM_TO_PROTOCOL                                      | 437             | 437    | 437    | 437    | 126     |
-| borrow(address,uint256,uint256,uint16,address)                     | 197559          | 206366 | 203159 | 238218 | 61      |
-| borrow(bytes32)                                                    | 203157          | 203157 | 203157 | 203157 | 3       |
-| configureEModeCategory                                             | 7099            | 11242  | 7099   | 49224  | 61      |
+| FLASHLOAN_PREMIUM_TO_PROTOCOL                                      | 459             | 459    | 459    | 459    | 126     |
+| borrow(address,uint256,uint256,uint16,address)                     | 200006          | 206720 | 202806 | 237866 | 65      |
+| borrow(bytes32)                                                    | 202826          | 202826 | 202826 | 202826 | 3       |
+| configureEModeCategory                                             | 6370            | 10639  | 6370   | 49773  | 61      |
 | configureEModeCategoryBorrowableBitmap                             | 23963           | 23963  | 23963  | 23963  | 2       |
-| configureEModeCategoryCollateralBitmap                             | 6843            | 6843   | 6843   | 6843   | 12      |
-| dropReserve                                                        | 6304            | 7660   | 6304   | 82259  | 56      |
+| configureEModeCategoryCollateralBitmap                             | 6815            | 6815   | 6815   | 6815   | 12      |
+| dropReserve                                                        | 6326            | 7682   | 6326   | 82303  | 56      |
 | getBorrowLogic                                                     | 281             | 281    | 281    | 281    | 1       |
-| getBridgeLogic                                                     | 345             | 345    | 345    | 345    | 1       |
-| getConfiguration                                                   | 723             | 733    | 723    | 2723   | 1462    |
-| getEModeCategoryBorrowableBitmap                                   | 2646            | 2646   | 2646   | 2646   | 2       |
-| getEModeCategoryCollateralBitmap                                   | 2656            | 2656   | 2656   | 2656   | 12      |
-| getEModeLogic                                                      | 345             | 345    | 345    | 345    | 1       |
+| getBridgeLogic                                                     | 367             | 367    | 367    | 367    | 1       |
+| getConfiguration                                                   | 701             | 711    | 701    | 2701   | 1462    |
+| getEModeCategoryBorrowableBitmap                                   | 2624            | 2624   | 2624   | 2624   | 2       |
+| getEModeCategoryCollateralBitmap                                   | 2650            | 2650   | 2650   | 2650   | 12      |
+| getEModeLogic                                                      | 367             | 367    | 367    | 367    | 1       |
 | getFlashLoanLogic                                                  | 347             | 347    | 347    | 347    | 1       |
-| getLiquidationGracePeriod                                          | 2634            | 2634   | 2634   | 2634   | 55      |
-| getLiquidationLogic                                                | 325             | 325    | 325    | 325    | 1       |
-| getPoolLogic                                                       | 324             | 324    | 324    | 324    | 1       |
-| getReserveData                                                     | 5204            | 10962  | 7204   | 29704  | 446     |
-| getReserveNormalizedIncome                                         | 823             | 828    | 823    | 1283   | 87      |
-| getReserveNormalizedVariableDebt                                   | 845             | 932    | 845    | 2845   | 59      |
-| getReservesList                                                    | 11126           | 11126  | 11126  | 11126  | 57      |
-| getSupplyLogic                                                     | 345             | 345    | 345    | 345    | 1       |
-| getUserAccountData                                                 | 22290           | 22290  | 22290  | 22290  | 1       |
-| getVirtualUnderlyingBalance                                        | 724             | 724    | 724    | 724    | 4       |
-| initReserve                                                        | 6628            | 95634  | 161459 | 167597 | 254     |
-| initialize                                                         | 45443           | 45443  | 45443  | 45443  | 63      |
-| liquidationCall                                                    | 375920          | 375920 | 375920 | 375920 | 1       |
-| mintToTreasury                                                     | 77264           | 78657  | 78657  | 80050  | 2       |
-| repay(address,uint256,uint256,address)                             | 164468          | 164468 | 164468 | 164468 | 2       |
-| repay(bytes32)                                                     | 135484          | 135484 | 135484 | 135484 | 1       |
-| repayWithATokens                                                   | 138509          | 138509 | 138509 | 138509 | 1       |
-| repayWithPermit                                                    | 182831          | 197542 | 189266 | 209917 | 51      |
+| getLiquidationGracePeriod                                          | 2656            | 2656   | 2656   | 2656   | 55      |
+| getLiquidationLogic                                                | 303             | 303    | 303    | 303    | 1       |
+| getPoolLogic                                                       | 346             | 346    | 346    | 346    | 1       |
+| getReserveAToken                                                   | 632             | 684    | 632    | 2632   | 153     |
+| getReserveData                                                     | 3437            | 8197   | 3437   | 21437  | 297     |
+| getReserveNormalizedIncome                                         | 845             | 850    | 845    | 1305   | 91      |
+| getReserveNormalizedVariableDebt                                   | 867             | 947    | 867    | 2867   | 64      |
+| getReserveVariableDebtToken                                        | 654             | 1987   | 2654   | 2654   | 6       |
+| getReservesList                                                    | 11148           | 11148  | 11148  | 11148  | 57      |
+| getSupplyLogic                                                     | 323             | 323    | 323    | 323    | 1       |
+| getUserAccountData                                                 | 22268           | 22268  | 22268  | 22268  | 1       |
+| getVirtualUnderlyingBalance                                        | 746             | 746    | 746    | 746    | 4       |
+| initReserve                                                        | 6606            | 95612  | 161437 | 167575 | 254     |
+| initialize                                                         | 45421           | 45421  | 45421  | 45421  | 63      |
+| liquidationCall                                                    | 419695          | 419695 | 419695 | 419695 | 1       |
+| mintToTreasury                                                     | 77242           | 78635  | 78635  | 80028  | 2       |
+| repay(address,uint256,uint256,address)                             | 164134          | 164134 | 164134 | 164134 | 2       |
+| repay(bytes32)                                                     | 135150          | 135150 | 135150 | 135150 | 1       |
+| repayWithATokens                                                   | 138198          | 138198 | 138198 | 138198 | 1       |
+| repayWithPermit                                                    | 185346          | 196670 | 188981 | 209632 | 55      |
 | rescueTokens                                                       | 48214           | 48214  | 48214  | 48214  | 55      |
-| resetIsolationModeTotalDebt                                        | 4353            | 4989   | 4353   | 15353  | 201     |
+| resetIsolationModeTotalDebt                                        | 4265            | 4901   | 4265   | 15265  | 201     |
 | setConfiguration                                                   | 2148            | 4296   | 2148   | 24303  | 1647    |
-| setLiquidationGracePeriod                                          | 6364            | 11408  | 10850  | 17012  | 165     |
+| setLiquidationGracePeriod                                          | 6364            | 11374  | 10850  | 17012  | 165     |
 | setReserveInterestRateStrategyAddress                              | 6384            | 7996   | 6493   | 15782  | 166     |
 | setUserEMode                                                       | 22122           | 42635  | 41183  | 87512  | 7       |
-| setUserUseReserveAsCollateral(address,bool)                        | 53575           | 69534  | 71588  | 102788 | 17      |
-| setUserUseReserveAsCollateral(bytes32)                             | 73756           | 73756  | 73756  | 73756  | 1       |
-| supply(address,uint256,address,uint16)                             | 157134          | 204985 | 208434 | 208434 | 79      |
-| supply(bytes32)                                                    | 210512          | 210512 | 210512 | 210512 | 7       |
-| supplyWithPermit                                                   | 259775          | 259775 | 259775 | 259775 | 54      |
-| syncIndexesState                                                   | 7299            | 13932  | 7299   | 27199  | 144     |
-| syncRatesState                                                     | 16005           | 16005  | 16005  | 16005  | 144     |
+| setUserUseReserveAsCollateral(address,bool)                        | 53530           | 69489  | 71543  | 102743 | 17      |
+| setUserUseReserveAsCollateral(bytes32)                             | 73691           | 73691  | 73691  | 73691  | 1       |
+| supply(address,uint256,address,uint16)                             | 156781          | 204798 | 208081 | 208081 | 83      |
+| supply(bytes32)                                                    | 210137          | 210137 | 210137 | 210137 | 7       |
+| supplyWithPermit                                                   | 259422          | 259422 | 259422 | 259422 | 54      |
+| syncIndexesState                                                   | 7182            | 13815  | 7182   | 27082  | 144     |
+| syncRatesState                                                     | 15726           | 15726  | 15726  | 15726  | 144     |
 | updateBridgeProtocolFee                                            | 6230            | 6230   | 6230   | 6230   | 55      |
-| updateFlashloanPremiums                                            | 1698            | 10043  | 6367   | 21598  | 181     |
-| withdraw                                                           | 126426          | 128867 | 128867 | 131308 | 2       |
+| updateFlashloanPremiums                                            | 1787            | 10132  | 6456   | 21687  | 181     |
+| withdraw                                                           | 126195          | 128635 | 128635 | 131076 | 2       |


 | src/contracts/instances/PoolConfiguratorInstance.sol:PoolConfiguratorInstance contract |                 |          |         |           |         |
@@ -322,132 +324,135 @@
 | Deployment Cost                                                                        | Deployment Size |          |         |           |         |
 | 4332868                                                                                | 19812           |          |         |           |         |
 | Function Name                                                                          | min             | avg      | median  | max       | # calls |
-| MAX_GRACE_PERIOD                                                                       | 260             | 260      | 260     | 260       | 371     |
-| configureReserveAsCollateral                                                           | 12220           | 17479    | 12264   | 99552     | 2437    |
-| disableLiquidationGracePeriod                                                          | 17214           | 28272    | 17214   | 39535     | 109     |
-| dropReserve                                                                            | 14074           | 17810    | 14074   | 104832    | 60      |
+| MAX_GRACE_PERIOD                                                                       | 260             | 260      | 260     | 260       | 379     |
+| configureReserveAsCollateral                                                           | 12198           | 17150    | 12264   | 87350     | 2489    |
+| disableLiquidationGracePeriod                                                          | 17214           | 28463    | 39513   | 39513     | 111     |
+| dropReserve                                                                            | 14074           | 17811    | 14074   | 104832    | 60      |
 | getConfiguratorLogic                                                                   | 283             | 283      | 283     | 283       | 1       |
-| getPendingLtv                                                                          | 640             | 640      | 640     | 640       | 153     |
-| initReserves                                                                           | 17401           | 15903182 | 4382378 | 211119271 | 1086    |
-| initialize                                                                             | 72573           | 90420    | 90473   | 90473     | 683     |
-| setAssetBorrowableInEMode                                                              | 46849           | 87525    | 87622   | 100849    | 395     |
-| setAssetCollateralInEMode                                                              | 17472           | 75276    | 83781   | 83781     | 644     |
-| setBorrowCap                                                                           | 11170           | 11585    | 11214   | 44169     | 2012    |
-| setBorrowableInIsolation                                                               | 10736           | 11044    | 10780   | 43726     | 1959    |
-| setDebtCeiling                                                                         | 17256           | 44193    | 41675   | 98789     | 2019    |
-| setEModeCategory                                                                       | 17779           | 75328    | 81448   | 81448     | 640     |
-| setLiquidationProtocolFee                                                              | 11241           | 11425    | 11285   | 44240     | 1954    |
-| setPoolPause(bool)                                                                     | 17202           | 19129    | 17202   | 89863     | 113     |
-| setPoolPause(bool,uint40)                                                              | 17314           | 60091    | 17314   | 107716    | 108     |
-| setReserveActive                                                                       | 14185           | 26524    | 14185   | 95296     | 66      |
-| setReserveBorrowing                                                                    | 10911           | 13520    | 10955   | 41764     | 2167    |
-| setReserveFactor                                                                       | 17301           | 42687    | 36685   | 124960    | 2004    |
-| setReserveFlashLoaning                                                                 | 10910           | 12662    | 10954   | 43918     | 2058    |
-| setReserveFreeze                                                                       | 20551           | 48154    | 52937   | 73139     | 169     |
-| setReserveInterestRateData                                                             | 17558           | 20678    | 17558   | 106484    | 57      |
-| setReserveInterestRateStrategyAddress                                                  | 17579           | 69521    | 17579   | 165156    | 99      |
+| getPendingLtv                                                                          | 640             | 640      | 640     | 640       | 159     |
+| initReserves                                                                           | 17401           | 15915557 | 4382636 | 211151370 | 1105    |
+| initialize                                                                             | 72573           | 90421    | 90473   | 90473     | 699     |
+| setAssetBorrowableInEMode                                                              | 44971           | 81723    | 81811   | 94971     | 395     |
+| setAssetCollateralInEMode                                                              | 17472           | 69948    | 77936   | 77959     | 644     |
+| setBorrowCap                                                                           | 11148           | 11576    | 11214   | 44169     | 2060    |
+| setBorrowableInIsolation                                                               | 10714           | 11037    | 10780   | 43726     | 2007    |
+| setDebtCeiling                                                                         | 17256           | 33646    | 31495   | 86587     | 2067    |
+| setEModeCategory                                                                       | 17779           | 75825    | 81997   | 81997     | 640     |
+| setLiquidationProtocolFee                                                              | 11219           | 11421    | 11285   | 44240     | 2002    |
+| setPoolPause(bool)                                                                     | 17202           | 19127    | 17202   | 89796     | 113     |
+| setPoolPause(bool,uint40)                                                              | 17314           | 61612    | 17314   | 107583    | 108     |
+| setReserveActive                                                                       | 14185           | 24676    | 14185   | 83094     | 66      |
+| setReserveBorrowing                                                                    | 10889           | 13464    | 10955   | 41764     | 2215    |
+| setReserveFactor                                                                       | 17301           | 42436    | 36422   | 124697    | 2052    |
+| setReserveFlashLoaning                                                                 | 10888           | 12623    | 10954   | 43918     | 2106    |
+| setReserveFreeze                                                                       | 20551           | 48461    | 52937   | 73139     | 173     |
+| setReserveInterestRateData                                                             | 17558           | 20465    | 17558   | 100432    | 57      |
+| setReserveInterestRateStrategyAddress                                                  | 17579           | 66821    | 17579   | 159082    | 99      |
 | setReservePause(address,bool)                                                          | 17347           | 30385    | 43192   | 43192     | 111     |
-| setReservePause(address,bool,uint40)                                                   | 14424           | 38915    | 47050   | 49360     | 658     |
-| setSiloedBorrowing                                                                     | 11281           | 11491    | 11325   | 94206     | 1949    |
-| setSupplyCap                                                                           | 11127           | 13126    | 11171   | 44126     | 2073    |
+| setReservePause(address,bool,uint40)                                                   | 14424           | 39163    | 47028   | 49338     | 668     |
+| setSiloedBorrowing                                                                     | 11259           | 11455    | 11325   | 73782     | 1997    |
+| setSupplyCap                                                                           | 11105           | 13097    | 11171   | 44126     | 2121    |
 | setUnbackedMintCap                                                                     | 44161           | 44161    | 44161   | 44161     | 7       |
-| updateAToken                                                                           | 14035           | 16293    | 14035   | 140527    | 56      |
-| updateBridgeProtocolFee                                                                | 14102           | 49291    | 51998   | 51998     | 14      |
-| updateFlashloanPremiumToProtocol                                                       | 10115           | 10509    | 10181   | 36981     | 738     |
-| updateFlashloanPremiumTotal                                                            | 14052           | 30681    | 32046   | 36946     | 738     |
-| updateVariableDebtToken                                                                | 14036           | 16184    | 14036   | 134376    | 56      |
+| updateAToken                                                                           | 14035           | 15855    | 14035   | 115979    | 56      |
+| updateBridgeProtocolFee                                                                | 14102           | 49414    | 52131   | 52131     | 14      |
+| updateFlashloanPremiumToProtocol                                                       | 10137           | 10474    | 10137   | 36937     | 754     |
+| updateFlashloanPremiumTotal                                                            | 14052           | 30682    | 32002   | 36902     | 754     |
+| updateVariableDebtToken                                                                | 14036           | 15746    | 14036   | 109829    | 56      |


 | src/contracts/instances/PoolInstance.sol:PoolInstance contract |                 |        |        |        |         |
 |----------------------------------------------------------------|-----------------|--------|--------|--------|---------|
 | Deployment Cost                                                | Deployment Size |        |        |        |         |
-| 4814942                                                        | 22300           |        |        |        |         |
+| 4685220                                                        | 21709           |        |        |        |         |
 | Function Name                                                  | min             | avg    | median | max    | # calls |
-| ADDRESSES_PROVIDER                                             | 284             | 284    | 284    | 284    | 2355    |
-| BRIDGE_PROTOCOL_FEE                                            | 349             | 2109   | 2349   | 2349   | 25      |
-| FLASHLOAN_PREMIUM_TOTAL                                        | 410             | 1413   | 2410   | 2410   | 1244    |
-| FLASHLOAN_PREMIUM_TO_PROTOCOL                                  | 459             | 460    | 459    | 2459   | 1241    |
-| MAX_NUMBER_RESERVES                                            | 286             | 286    | 286    | 286    | 111     |
-| backUnbacked                                                   | 98313           | 114497 | 111899 | 132885 | 9       |
-| borrow                                                         | 46604           | 212305 | 222258 | 261378 | 893     |
-| configureEModeCategory                                         | 7121            | 45502  | 49246  | 49246  | 628     |
-| configureEModeCategoryBorrowableBitmap                         | 4041            | 23841  | 23941  | 23941  | 393     |
-| configureEModeCategoryCollateralBitmap                         | 3976            | 6767   | 6776   | 6776   | 577     |
-| deposit                                                        | 32702           | 202881 | 208433 | 208433 | 1117    |
-| dropReserve                                                    | 6326            | 9907   | 6326   | 82325  | 61      |
-| finalizeTransfer                                               | 20725           | 50394  | 52834  | 87949  | 968     |
-| flashLoan                                                      | 29684           | 96524  | 75354  | 322330 | 65      |
-| flashLoanSimple                                                | 23396           | 345141 | 191517 | 760848 | 11      |
-| getBorrowLogic                                                 | 325             | 325    | 325    | 325    | 1       |
-| getBridgeLogic                                                 | 345             | 345    | 345    | 345    | 1       |
-| getConfiguration                                               | 745             | 876    | 745    | 2745   | 27132   |
-| getEModeCategoryBorrowableBitmap                               | 668             | 2591   | 2668   | 2668   | 418     |
-| getEModeCategoryCollateralBitmap                               | 678             | 2591   | 2678   | 2678   | 602     |
-| getEModeCategoryCollateralConfig                               | 885             | 1685   | 885    | 2885   | 110     |
-| getEModeCategoryData                                           | 8291            | 8291   | 8291   | 8291   | 3       |
-| getEModeCategoryLabel                                          | 1328            | 1642   | 1583   | 3328   | 25      |
-| getEModeLogic                                                  | 278             | 278    | 278    | 278    | 1       |
-| getFlashLoanLogic                                              | 302             | 302    | 302    | 302    | 1       |
-| getLiquidationGracePeriod                                      | 2656            | 2656   | 2656   | 2656   | 418     |
-| getLiquidationLogic                                            | 347             | 347    | 347    | 347    | 1       |
-| getPoolLogic                                                   | 279             | 279    | 279    | 279    | 1       |
+| ADDRESSES_PROVIDER                                             | 351             | 351    | 351    | 351    | 3606    |
+| BRIDGE_PROTOCOL_FEE                                            | 415             | 2175   | 2415   | 2415   | 25      |
+| FLASHLOAN_PREMIUM_TOTAL                                        | 388             | 1391   | 2388   | 2388   | 1276    |
+| FLASHLOAN_PREMIUM_TO_PROTOCOL                                  | 459             | 460    | 459    | 2459   | 1273    |
+| MAX_NUMBER_RESERVES                                            | 308             | 308    | 308    | 308    | 110     |
+| backUnbacked                                                   | 97983           | 114167 | 111569 | 132555 | 9       |
+| borrow                                                         | 46465           | 217204 | 222151 | 265705 | 1474    |
+| configureEModeCategory                                         | 6392            | 45939  | 49795  | 49795  | 628     |
+| configureEModeCategoryBorrowableBitmap                         | 4063            | 23863  | 23963  | 23963  | 393     |
+| configureEModeCategoryCollateralBitmap                         | 4015            | 6806   | 6815   | 6815   | 577     |
+| deposit                                                        | 32349           | 202489 | 208080 | 208080 | 1119    |
+| dropReserve                                                    | 6326            | 9908   | 6326   | 82325  | 61      |
+| eliminateReserveDeficit                                        | 6328            | 58474  | 55368  | 120838 | 330     |
+| finalizeTransfer                                               | 20747           | 50380  | 52856  | 95613  | 970     |
+| flashLoan                                                      | 29662           | 99175  | 81700  | 321999 | 65      |
+| flashLoanSimple                                                | 23396           | 337294 | 191187 | 740396 | 11      |
+| getBorrowLogic                                                 | 303             | 303    | 303    | 303    | 1       |
+| getBridgeLogic                                                 | 279             | 279    | 279    | 279    | 1       |
+| getConfiguration                                               | 723             | 851    | 723    | 2723   | 28123   |
+| getEModeCategoryBorrowableBitmap                               | 624             | 2557   | 2624   | 2624   | 418     |
+| getEModeCategoryCollateralBitmap                               | 650             | 2560   | 2650   | 2650   | 603     |
+| getEModeCategoryCollateralConfig                               | 952             | 1744   | 952    | 2952   | 111     |
+| getEModeCategoryData                                           | 5914            | 5914   | 5914   | 5914   | 3       |
+| getEModeCategoryLabel                                          | 1306            | 1620   | 1561   | 3306   | 25      |
+| getEModeLogic                                                  | 300             | 300    | 300    | 300    | 1       |
+| getFlashLoanLogic                                              | 280             | 280    | 280    | 280    | 1       |
+| getLiquidationGracePeriod                                      | 2656            | 2656   | 2656   | 2656   | 436     |
+| getLiquidationLogic                                            | 303             | 303    | 303    | 303    | 1       |
+| getPoolLogic                                                   | 301             | 301    | 301    | 301    | 1       |
+| getReserveAToken                                               | 676             | 730    | 676    | 2676   | 5036    |
 | getReserveAddressById                                          | 662             | 662    | 662    | 662    | 1       |
-| getReserveData                                                 | 5248            | 10894  | 7248   | 29748  | 8983    |
-| getReserveDataExtended                                         | 3476            | 4142   | 3476   | 5476   | 6       |
-| getReserveNormalizedIncome                                     | 867             | 1883   | 867    | 5327   | 6560    |
-| getReserveNormalizedVariableDebt                               | 889             | 1072   | 889    | 6475   | 1605    |
+| getReserveData                                                 | 3459            | 9202   | 3459   | 21459  | 4042    |
+| getReserveDeficit                                              | 609             | 609    | 609    | 609    | 282     |
+| getReserveNormalizedIncome                                     | 889             | 1680   | 889    | 5349   | 8792    |
+| getReserveNormalizedVariableDebt                               | 889             | 1041   | 889    | 6475   | 2526    |
+| getReserveVariableDebtToken                                    | 676             | 709    | 676    | 2676   | 4117    |
 | getReservesCount                                               | 392             | 392    | 392    | 392    | 2       |
-| getReservesList                                                | 3170            | 11700  | 11170  | 99129  | 893     |
-| getSupplyLogic                                                 | 281             | 281    | 281    | 281    | 1       |
-| getUserAccountData                                             | 12141           | 22006  | 22253  | 37375  | 556     |
-| getUserConfiguration                                           | 703             | 758    | 703    | 2703   | 399     |
-| getUserEMode                                                   | 634             | 634    | 634    | 634    | 283     |
-| getVirtualUnderlyingBalance                                    | 657             | 1068   | 657    | 2657   | 811     |
-| initReserve                                                    | 6564            | 177594 | 177419 | 207007 | 11154   |
-| initialize                                                     | 45378           | 45472  | 45378  | 66895  | 624     |
-| liquidationCall                                                | 53082           | 238189 | 323142 | 382539 | 795     |
-| mintToTreasury                                                 | 77264           | 78657  | 78657  | 80050  | 2       |
-| mintUnbacked                                                   | 12183           | 118303 | 103419 | 165752 | 17      |
-| repay                                                          | 33243           | 99380  | 95853  | 164534 | 21      |
-| repayWithATokens                                               | 128089          | 155007 | 155256 | 165893 | 57      |
-| repayWithPermit                                                | 126966          | 164667 | 154052 | 209744 | 150     |
+| getReservesList                                                | 3103            | 11768  | 11103  | 95886  | 891     |
+| getSupplyLogic                                                 | 345             | 345    | 345    | 345    | 1       |
+| getUserAccountData                                             | 12119           | 22726  | 19731  | 37353  | 1922    |
+| getUserConfiguration                                           | 703             | 883    | 703    | 2703   | 177     |
+| getUserEMode                                                   | 656             | 656    | 656    | 656    | 863     |
+| getVirtualUnderlyingBalance                                    | 657             | 1552   | 657    | 2657   | 373     |
+| initReserve                                                    | 6628            | 177661 | 177483 | 207071 | 11343   |
+| initialize                                                     | 45443           | 45535  | 45443  | 66960  | 640     |
+| liquidationCall                                                | 73774           | 285332 | 325227 | 511750 | 1279    |
+| mintToTreasury                                                 | 77220           | 78613  | 78613  | 80006  | 2       |
+| mintUnbacked                                                   | 12183           | 117981 | 103045 | 165378 | 17      |
+| repay                                                          | 33126           | 104506 | 107475 | 164156 | 21      |
+| repayWithATokens                                               | 134210          | 154481 | 154860 | 165518 | 57      |
+| repayWithPermit                                                | 129325          | 160572 | 149170 | 209303 | 165     |
 | rescueTokens                                                   | 48149           | 48149  | 48149  | 48149  | 55      |
-| resetIsolationModeTotalDebt                                    | 4265            | 4336   | 4265   | 15265  | 1860    |
-| setConfiguration                                               | 2170            | 10372  | 2325   | 24325  | 30463   |
-| setLiquidationGracePeriod                                      | 6386            | 12318  | 12534  | 17034  | 724     |
-| setReserveInterestRateStrategyAddress                          | 6406            | 7868   | 6515   | 15804  | 210     |
-| setUserEMode                                                   | 14165           | 47361  | 41117  | 94723  | 566     |
-| setUserUseReserveAsCollateral                                  | 53552           | 72100  | 71565  | 102765 | 25      |
-| supply                                                         | 29399           | 195761 | 208456 | 216210 | 1471    |
-| supplyWithPermit                                               | 113713          | 195952 | 218122 | 257604 | 157     |
-| syncIndexesState                                               | 7211            | 13934  | 7211   | 62577  | 1850    |
-| syncRatesState                                                 | 13459           | 15981  | 16005  | 22505  | 1850    |
-| updateBridgeProtocolFee                                        | 6185            | 9470   | 6185   | 23369  | 68      |
-| updateFlashloanPremiums                                        | 1720            | 11437  | 6389   | 21620  | 1293    |
-| withdraw                                                       | 39154           | 127154 | 138193 | 177428 | 153     |
+| resetIsolationModeTotalDebt                                    | 4287            | 4356   | 4287   | 15287  | 1908    |
+| setConfiguration                                               | 2192            | 10347  | 2347   | 24347  | 31150   |
+| setLiquidationGracePeriod                                      | 6364            | 12264  | 12512  | 17012  | 761     |
+| setReserveInterestRateStrategyAddress                          | 6384            | 7846   | 6493   | 15782  | 210     |
+| setUserEMode                                                   | 14143           | 47337  | 41095  | 94701  | 566     |
+| setUserUseReserveAsCollateral                                  | 53574           | 72122  | 71587  | 102787 | 25      |
+| supply                                                         | 29282           | 191846 | 208081 | 215835 | 2462    |
+| supplyWithPermit                                               | 113338          | 195577 | 217747 | 257229 | 157     |
+| syncIndexesState                                               | 7160            | 13881  | 7160   | 62526  | 1898    |
+| syncRatesState                                                 | 13247           | 15769  | 15793  | 22293  | 1898    |
+| updateBridgeProtocolFee                                        | 6252            | 9537   | 6252   | 23436  | 68      |
+| updateFlashloanPremiums                                        | 1698            | 11421  | 6367   | 21598  | 1325    |
+| withdraw                                                       | 39214           | 127709 | 137875 | 177110 | 153     |


 | src/contracts/instances/VariableDebtTokenInstance.sol:VariableDebtTokenInstance contract |                 |        |        |        |         |
 |------------------------------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
 | Deployment Cost                                                                          | Deployment Size |        |        |        |         |
-| 1695548                                                                                  | 8190            |        |        |        |         |
+| 1695615                                                                                  | 8190            |        |        |        |         |
 | Function Name                                                                            | min             | avg    | median | max    | # calls |
-| UNDERLYING_ASSET_ADDRESS                                                                 | 397             | 397    | 397    | 397    | 2092    |
+| UNDERLYING_ASSET_ADDRESS                                                                 | 397             | 397    | 397    | 397    | 2233    |
 | approveDelegation                                                                        | 27009           | 27009  | 27009  | 27009  | 1       |
-| balanceOf                                                                                | 675             | 4919   | 4753   | 10336  | 1720    |
+| balanceOf                                                                                | 675             | 4704   | 4753   | 10753  | 2664    |
 | borrowAllowance                                                                          | 828             | 828    | 828    | 828    | 5       |
-| burn                                                                                     | 19171           | 26141  | 26171  | 26172  | 714     |
-| decimals                                                                                 | 334             | 334    | 334    | 334    | 2092    |
+| burn                                                                                     | 19171           | 26135  | 26171  | 26172  | 1196    |
+| decimals                                                                                 | 334             | 334    | 334    | 334    | 3436    |
 | delegationWithSig                                                                        | 1043            | 28679  | 21652  | 55852  | 7       |
-| getIncentivesController                                                                  | 430             | 430    | 430    | 430    | 2092    |
-| initialize                                                                               | 123595          | 202347 | 209016 | 299178 | 11188   |
-| mint                                                                                     | 26353           | 62484  | 62553  | 72340  | 885     |
-| name                                                                                     | 1004            | 1444   | 1319   | 3259   | 2182    |
+| getIncentivesController                                                                  | 430             | 430    | 430    | 430    | 2233    |
+| initialize                                                                               | 123595          | 203557 | 209016 | 299178 | 11377   |
+| mint                                                                                     | 26353           | 62511  | 62553  | 72340  | 1470    |
+| name                                                                                     | 1004            | 1440   | 1259   | 3259   | 2323    |
 | nonces                                                                                   | 574             | 574    | 574    | 574    | 1       |
-| scaledBalanceOf                                                                          | 687             | 1869   | 2687   | 2687   | 1563    |
-| scaledTotalSupply                                                                        | 417             | 1962   | 2417   | 2417   | 9807    |
-| symbol                                                                                   | 1025            | 1455   | 1280   | 3280   | 2175    |
-| totalSupply                                                                              | 4052            | 7563   | 6466   | 19052  | 15      |
+| scaledBalanceOf                                                                          | 687             | 1748   | 2687   | 2687   | 2767    |
+| scaledTotalSupply                                                                        | 417             | 2084   | 2417   | 2417   | 12394   |
+| symbol                                                                                   | 1025            | 1463   | 1340   | 3280   | 2316    |
+| totalSupply                                                                              | 4052            | 8364   | 8466   | 19052  | 15      |


 | src/contracts/misc/AaveOracle.sol:AaveOracle contract |                 |       |        |       |         |
@@ -457,10 +462,10 @@
 | Function Name                                         | min             | avg   | median | max   | # calls |
 | BASE_CURRENCY                                         | 292             | 292   | 292    | 292   | 3       |
 | BASE_CURRENCY_UNIT                                    | 261             | 261   | 261    | 261   | 1       |
-| getAssetPrice                                         | 0               | 4948  | 7865   | 7865  | 6615    |
+| getAssetPrice                                         | 0               | 4223  | 1365   | 7865  | 14146   |
 | getAssetsPrices                                       | 2286            | 3392  | 2286   | 5605  | 3       |
 | getFallbackOracle                                     | 364             | 1030  | 364    | 2364  | 3       |
-| getSourceOfAsset                                      | 550             | 837   | 550    | 2550  | 327     |
+| getSourceOfAsset                                      | 550             | 703   | 550    | 2550  | 613     |
 | setAssetSources                                       | 37323           | 52868 | 61918  | 62158 | 9       |
 | setFallbackOracle                                     | 59524           | 59524 | 59524  | 59524 | 4       |

@@ -470,20 +475,20 @@
 | Deployment Cost                                                                                           | Deployment Size |       |        |       |         |
 | 920973                                                                                                    | 4323            |       |        |       |         |
 | Function Name                                                                                             | min             | avg   | median | max   | # calls |
-| ADDRESSES_PROVIDER                                                                                        | 228             | 228   | 228    | 228   | 203     |
-| MAX_BORROW_RATE                                                                                           | 239             | 239   | 239    | 239   | 1064    |
-| MAX_OPTIMAL_POINT                                                                                         | 261             | 261   | 261    | 261   | 1376    |
-| MIN_OPTIMAL_POINT                                                                                         | 260             | 260   | 260    | 260   | 1373    |
-| calculateInterestRates                                                                                    | 0               | 3982  | 4251   | 5973  | 7502    |
-| getBaseVariableBorrowRate                                                                                 | 744             | 874   | 744    | 2744  | 646     |
-| getInterestRateData                                                                                       | 1788            | 1788  | 1788   | 1788  | 51      |
-| getInterestRateDataBps                                                                                    | 983             | 983   | 983    | 983   | 51      |
-| getMaxVariableBorrowRate                                                                                  | 968             | 968   | 968    | 968   | 337     |
-| getOptimalUsageRatio                                                                                      | 734             | 738   | 734    | 2734  | 490     |
-| getVariableRateSlope1                                                                                     | 774             | 774   | 774    | 774   | 496     |
-| getVariableRateSlope2                                                                                     | 795             | 795   | 795    | 795   | 340     |
-| setInterestRateParams(address,(uint16,uint32,uint32,uint32))                                              | 28281           | 29703 | 29064  | 36794 | 561     |
-| setInterestRateParams(address,bytes)                                                                      | 28626           | 33049 | 29847  | 37145 | 1278    |
+| ADDRESSES_PROVIDER                                                                                        | 228             | 228   | 228    | 228   | 214     |
+| MAX_BORROW_RATE                                                                                           | 239             | 239   | 239    | 239   | 1111    |
+| MAX_OPTIMAL_POINT                                                                                         | 261             | 261   | 261    | 261   | 1421    |
+| MIN_OPTIMAL_POINT                                                                                         | 260             | 260   | 260    | 260   | 1418    |
+| calculateInterestRates                                                                                    | 0               | 4131  | 4251   | 5973  | 10093   |
+| getBaseVariableBorrowRate                                                                                 | 744             | 868   | 744    | 2744  | 673     |
+| getInterestRateData                                                                                       | 1788            | 1788  | 1788   | 1788  | 53      |
+| getInterestRateDataBps                                                                                    | 983             | 983   | 983    | 983   | 53      |
+| getMaxVariableBorrowRate                                                                                  | 968             | 968   | 968    | 968   | 350     |
+| getOptimalUsageRatio                                                                                      | 734             | 737   | 734    | 2734  | 505     |
+| getVariableRateSlope1                                                                                     | 774             | 774   | 774    | 774   | 514     |
+| getVariableRateSlope2                                                                                     | 795             | 795   | 795    | 795   | 351     |
+| setInterestRateParams(address,(uint16,uint32,uint32,uint32))                                              | 28269           | 29733 | 29064  | 36794 | 572     |
+| setInterestRateParams(address,bytes)                                                                      | 28590           | 33098 | 29847  | 37133 | 1312    |


 | src/contracts/misc/PriceOracleSentinel.sol:PriceOracleSentinel contract |                 |       |        |       |         |
@@ -505,26 +510,26 @@
 | Deployment Cost                                                                                                                                   | Deployment Size |          |         |           |         |
 | 454308                                                                                                                                            | 2052            |          |         |           |         |
 | Function Name                                                                                                                                     | min             | avg      | median  | max       | # calls |
-| ADDRESSES_PROVIDER                                                                                                                                | 890             | 4035     | 5390    | 5457      | 2530    |
-| BRIDGE_PROTOCOL_FEE                                                                                                                               | 955             | 5237     | 7455    | 7455      | 23      |
+| ADDRESSES_PROVIDER                                                                                                                                | 957             | 3096     | 957     | 5457      | 3781    |
+| BRIDGE_PROTOCOL_FEE                                                                                                                               | 1021            | 5303     | 7521    | 7521      | 23      |
 | DOMAIN_SEPARATOR                                                                                                                                  | 1061            | 3198     | 3061    | 7561      | 59      |
-| EMISSION_MANAGER                                                                                                                                  | 932             | 932      | 932     | 932       | 682     |
-| FLASHLOAN_PREMIUM_TOTAL                                                                                                                           | 994             | 2025     | 2994    | 7516      | 1368    |
-| FLASHLOAN_PREMIUM_TO_PROTOCOL                                                                                                                     | 1043            | 1067     | 1065    | 7565      | 1365    |
-| MAX_GRACE_PERIOD                                                                                                                                  | 5366            | 5366     | 5366    | 5366      | 371     |
-| MAX_NUMBER_RESERVES                                                                                                                               | 892             | 892      | 892     | 892       | 109     |
+| EMISSION_MANAGER                                                                                                                                  | 932             | 932      | 932     | 932       | 698     |
+| FLASHLOAN_PREMIUM_TOTAL                                                                                                                           | 994             | 2005     | 2994    | 7494      | 1400    |
+| FLASHLOAN_PREMIUM_TO_PROTOCOL                                                                                                                     | 1065            | 1069     | 1065    | 7565      | 1397    |
+| MAX_GRACE_PERIOD                                                                                                                                  | 5366            | 5366     | 5366    | 5366      | 379     |
+| MAX_NUMBER_RESERVES                                                                                                                               | 914             | 914      | 914     | 914       | 108     |
 | POOL                                                                                                                                              | 932             | 2077     | 932     | 5432      | 110     |
-| RESERVE_TREASURY_ADDRESS                                                                                                                          | 1025            | 1404     | 1025    | 7525      | 2584    |
+| RESERVE_TREASURY_ADDRESS                                                                                                                          | 1025            | 1592     | 1025    | 7525      | 3119    |
 | REVISION                                                                                                                                          | 866             | 866      | 866     | 866       | 8       |
-| UNDERLYING_ASSET_ADDRESS                                                                                                                          | 1003            | 1071     | 1047    | 3047      | 4282    |
+| UNDERLYING_ASSET_ADDRESS                                                                                                                          | 1003            | 1068     | 1047    | 3047      | 4564    |
 | admin                                                                                                                                             | 21388           | 21388    | 21388   | 21388     | 8       |
 | allowance                                                                                                                                         | 1394            | 2682     | 1394    | 7894      | 26      |
-| approve                                                                                                                                           | 51270           | 51329    | 51306   | 51642     | 677     |
+| approve                                                                                                                                           | 51270           | 51329    | 51306   | 51642     | 678     |
 | approveDelegation                                                                                                                                 | 53750           | 53750    | 53750   | 53750     | 1       |
-| backUnbacked                                                                                                                                      | 125167          | 140822   | 138777  | 159775    | 9       |
-| balanceOf                                                                                                                                         | 1284            | 5615     | 5362    | 22858     | 3575    |
-| borrow(address,uint256,uint256,uint16,address)                                                                                                    | 73940           | 236432   | 249629  | 288773    | 953     |
-| borrow(bytes32)                                                                                                                                   | 229503          | 229503   | 229503  | 229503    | 3       |
+| backUnbacked                                                                                                                                      | 124837          | 140492   | 138447  | 159445    | 9       |
+| balanceOf                                                                                                                                         | 1284            | 5367     | 5362    | 22880     | 5721    |
+| borrow(address,uint256,uint256,uint16,address)                                                                                                    | 73801           | 240657   | 249254  | 293064    | 1538    |
+| borrow(bytes32)                                                                                                                                   | 229172          | 229172   | 229172  | 229172    | 3       |
 | borrowAllowance                                                                                                                                   | 1440            | 1440     | 1440    | 1440      | 5       |
 | burn                                                                                                                                              | 28118           | 40728    | 28448   | 65620     | 3       |
 | claimAllRewards                                                                                                                                   | 119485          | 119485   | 119485  | 119485    | 1       |
@@ -533,133 +538,136 @@
 | claimRewards                                                                                                                                      | 28652           | 77697    | 84102   | 113933    | 4       |
 | claimRewardsOnBehalf                                                                                                                              | 116497          | 116497   | 116497  | 116497    | 1       |
 | claimRewardsToSelf                                                                                                                                | 113252          | 113252   | 113252  | 113252    | 1       |
-| configureEModeCategory                                                                                                                            | 34247           | 34258    | 34258   | 34269     | 110     |
-| configureReserveAsCollateral                                                                                                                      | 44058           | 64901    | 57731   | 126489    | 489     |
-| decimals                                                                                                                                          | 940             | 962      | 962     | 7462      | 4205    |
+| configureEModeCategory                                                                                                                            | 33518           | 33529    | 33529   | 33540     | 110     |
+| configureReserveAsCollateral                                                                                                                      | 44058           | 63584    | 57709   | 114287    | 493     |
+| decimals                                                                                                                                          | 940             | 957      | 940     | 7462      | 6259    |
 | decreaseAllowance                                                                                                                                 | 34413           | 34413    | 34413   | 34413     | 1       |
 | delegationWithSig                                                                                                                                 | 29247           | 56385    | 45247   | 84283     | 7       |
-| deposit                                                                                                                                           | 173106          | 223009   | 226046  | 235646    | 937     |
-| disableLiquidationGracePeriod                                                                                                                     | 43552           | 54782    | 43768   | 66073     | 109     |
-| dropReserve                                                                                                                                       | 32618           | 37201    | 32640   | 105096    | 172     |
-| flashLoan                                                                                                                                         | 59228           | 179747   | 149955  | 374161    | 65      |
-| flashLoanSimple                                                                                                                                   | 50902           | 313230   | 179210  | 646184    | 11      |
+| deposit                                                                                                                                           | 172753          | 222603   | 225693  | 235293    | 939     |
+| disableLiquidationGracePeriod                                                                                                                     | 43552           | 54981    | 66051   | 66051     | 111     |
+| dropReserve                                                                                                                                       | 32640           | 37208    | 32640   | 105096    | 172     |
+| eliminateReserveDeficit                                                                                                                           | 33037           | 84429    | 82057   | 147715    | 330     |
+| flashLoan                                                                                                                                         | 59206           | 185569   | 169698  | 374139    | 65      |
+| flashLoanSimple                                                                                                                                   | 50902           | 306036   | 178880  | 625732    | 11      |
 | getAllUserRewards                                                                                                                                 | 9209            | 9209     | 9209    | 9209      | 1       |
 | getAssetDecimals                                                                                                                                  | 1265            | 1265     | 1265    | 1265      | 2       |
-| getAssetIndex                                                                                                                                     | 3081            | 10042    | 9589    | 16507     | 2079    |
-| getBorrowLogic                                                                                                                                    | 5387            | 5409     | 5409    | 5431      | 2       |
-| getBridgeLogic                                                                                                                                    | 5451            | 5451     | 5451    | 5451      | 2       |
+| getAssetIndex                                                                                                                                     | 3081            | 10058    | 9589    | 16507     | 2069    |
+| getBorrowLogic                                                                                                                                    | 5387            | 5398     | 5398    | 5409      | 2       |
+| getBridgeLogic                                                                                                                                    | 5385            | 5429     | 5429    | 5473      | 2       |
 | getClaimer                                                                                                                                        | 1234            | 7617     | 7734    | 7734      | 112     |
-| getConfiguration                                                                                                                                  | 1332            | 1670     | 1354    | 7854      | 28594   |
+| getConfiguration                                                                                                                                  | 1310            | 1639     | 1332    | 7832      | 29585   |
 | getConfiguratorLogic                                                                                                                              | 5389            | 5389     | 5389    | 5389      | 1       |
 | getDistributionEnd                                                                                                                                | 1401            | 1401     | 1401    | 1401      | 1       |
-| getEModeCategoryBorrowableBitmap                                                                                                                  | 1277            | 7422     | 7777    | 7777      | 420     |
-| getEModeCategoryCollateralBitmap                                                                                                                  | 1287            | 7511     | 7787    | 7787      | 614     |
-| getEModeCategoryCollateralConfig                                                                                                                  | 1500            | 2340     | 1500    | 8000      | 110     |
-| getEModeCategoryData                                                                                                                              | 13430           | 13430    | 13430   | 13430     | 3       |
-| getEModeCategoryLabel                                                                                                                             | 1940            | 2257     | 2198    | 3940      | 25      |
-| getEModeLogic                                                                                                                                     | 5384            | 5417     | 5417    | 5451      | 2       |
-| getFlashLoanLogic                                                                                                                                 | 5408            | 5430     | 5430    | 5453      | 2       |
-| getIncentivesController                                                                                                                           | 1036            | 1061     | 1080    | 7580      | 4190    |
-| getLiquidationGracePeriod                                                                                                                         | 29175           | 29194    | 29197   | 29197     | 473     |
-| getLiquidationLogic                                                                                                                               | 5431            | 5442     | 5442    | 5453      | 2       |
-| getPendingLtv                                                                                                                                     | 1249            | 1249     | 1249    | 1249      | 153     |
-| getPoolLogic                                                                                                                                      | 5385            | 5407     | 5407    | 5430      | 2       |
+| getEModeCategoryBorrowableBitmap                                                                                                                  | 1233            | 7387     | 7733    | 7733      | 420     |
+| getEModeCategoryCollateralBitmap                                                                                                                  | 1259            | 7473     | 7759    | 7759      | 615     |
+| getEModeCategoryCollateralConfig                                                                                                                  | 1567            | 2400     | 1567    | 8067      | 111     |
+| getEModeCategoryData                                                                                                                              | 11053           | 11053    | 11053   | 11053     | 3       |
+| getEModeCategoryLabel                                                                                                                             | 1918            | 2235     | 2176    | 3918      | 25      |
+| getEModeLogic                                                                                                                                     | 5406            | 5439     | 5439    | 5473      | 2       |
+| getFlashLoanLogic                                                                                                                                 | 5386            | 5419     | 5419    | 5453      | 2       |
+| getIncentivesController                                                                                                                           | 1036            | 1060     | 1080    | 7580      | 4472    |
+| getLiquidationGracePeriod                                                                                                                         | 29197           | 29197    | 29197   | 29197     | 491     |
+| getLiquidationLogic                                                                                                                               | 5409            | 5409     | 5409    | 5409      | 2       |
+| getPendingLtv                                                                                                                                     | 1249            | 1249     | 1249    | 1249      | 159     |
+| getPoolLogic                                                                                                                                      | 5407            | 5429     | 5429    | 5452      | 2       |
 | getPreviousIndex                                                                                                                                  | 1260            | 1260     | 1260    | 1260      | 39      |
+| getReserveAToken                                                                                                                                  | 1241            | 1380     | 1285    | 7785      | 5189    |
 | getReserveAddressById                                                                                                                             | 1271            | 1271     | 1271    | 1271      | 1       |
-| getReserveData                                                                                                                                    | 5891            | 11728    | 7935    | 34935     | 9429    |
-| getReserveDataExtended                                                                                                                            | 4175            | 4841     | 4175    | 6175      | 6       |
-| getReserveNormalizedIncome                                                                                                                        | 0               | 3429     | 1476    | 10436     | 6703    |
-| getReserveNormalizedVariableDebt                                                                                                                  | 1454            | 1681     | 1498    | 11584     | 1664    |
+| getReserveData                                                                                                                                    | 4124            | 10068    | 4146    | 26646     | 4339    |
+| getReserveDeficit                                                                                                                                 | 1218            | 1218     | 1218    | 1218      | 282     |
+| getReserveNormalizedIncome                                                                                                                        | 0               | 2996     | 1498    | 10458     | 8939    |
+| getReserveNormalizedVariableDebt                                                                                                                  | 1476            | 1652     | 1498    | 11584     | 2590    |
+| getReserveVariableDebtToken                                                                                                                       | 1263            | 1334     | 1285    | 7785      | 4123    |
 | getReservesCount                                                                                                                                  | 998             | 998      | 998     | 998       | 2       |
-| getReservesList                                                                                                                                   | 3794            | 13871    | 11794   | 100510    | 950     |
+| getReservesList                                                                                                                                   | 3727            | 13936    | 11727   | 97241     | 948     |
 | getRewardOracle                                                                                                                                   | 1258            | 1258     | 1258    | 1258      | 1       |
 | getRewardsByAsset                                                                                                                                 | 2383            | 9751     | 10883   | 10883     | 613     |
 | getRewardsData                                                                                                                                    | 1600            | 1600     | 1600    | 1600      | 3       |
 | getRewardsList                                                                                                                                    | 1723            | 1723     | 1723    | 1723      | 30      |
 | getScaledUserBalanceAndSupply                                                                                                                     | 1438            | 5057     | 3438    | 9938      | 21      |
-| getSupplyLogic                                                                                                                                    | 5387            | 5419     | 5419    | 5451      | 2       |
+| getSupplyLogic                                                                                                                                    | 5429            | 5440     | 5440    | 5451      | 2       |
 | getTransferStrategy                                                                                                                               | 1257            | 1257     | 1257    | 1257      | 1       |
-| getUserAccountData                                                                                                                                | 12774           | 22639    | 22886   | 38008     | 557     |
+| getUserAccountData                                                                                                                                | 12752           | 23358    | 20364   | 37986     | 1923    |
 | getUserAccruedRewards                                                                                                                             | 2253            | 2253     | 2253    | 2253      | 1       |
 | getUserAssetIndex                                                                                                                                 | 1623            | 1623     | 1623    | 1623      | 1       |
-| getUserConfiguration                                                                                                                              | 1312            | 1367     | 1312    | 3312      | 399     |
-| getUserEMode                                                                                                                                      | 1243            | 1243     | 1243    | 1243      | 283     |
-| getUserRewards                                                                                                                                    | 7423            | 8657     | 8711    | 17498     | 66      |
-| getVirtualUnderlyingBalance                                                                                                                       | 1266            | 1676     | 1266    | 3266      | 815     |
+| getUserConfiguration                                                                                                                              | 1312            | 1492     | 1312    | 3312      | 177     |
+| getUserEMode                                                                                                                                      | 1265            | 1265     | 1265    | 1265      | 863     |
+| getUserRewards                                                                                                                                    | 7423            | 8651     | 8711    | 17498     | 66      |
+| getVirtualUnderlyingBalance                                                                                                                       | 1266            | 2152     | 1266    | 3266      | 377     |
 | increaseAllowance                                                                                                                                 | 34480           | 47305    | 51580   | 51580     | 4       |
-| initReserve                                                                                                                                       | 33274           | 33306    | 33306   | 33338     | 220     |
-| initReserves                                                                                                                                      | 45683           | 33142016 | 1586149 | 213411849 | 436     |
-| liquidationCall(address,address,address,uint256,bool)                                                                                             | 80670           | 265778   | 350729  | 410462    | 795     |
-| liquidationCall(bytes32,bytes32)                                                                                                                  | 402793          | 402793   | 402793  | 402793    | 1       |
+| initReserve                                                                                                                                       | 33316           | 33327    | 33327   | 33338     | 220     |
+| initReserves                                                                                                                                      | 45683           | 33465441 | 1586662 | 212323201 | 439     |
+| liquidationCall(address,address,address,uint256,bool)                                                                                             | 101362          | 309730   | 352739  | 520473    | 1279    |
+| liquidationCall(bytes32,bytes32)                                                                                                                  | 432168          | 432168   | 432168  | 432168    | 1       |
 | mint                                                                                                                                              | 28146           | 73470    | 91246   | 91726     | 7       |
-| mintToTreasury(address[])                                                                                                                         | 99291           | 100871   | 100871  | 102451    | 4       |
+| mintToTreasury(address[])                                                                                                                         | 99247           | 100838   | 100838  | 102429    | 4       |
 | mintToTreasury(uint256,uint256)                                                                                                                   | 26979           | 59928    | 59928   | 92877     | 2       |
-| mintUnbacked                                                                                                                                      | 39385           | 145515   | 130632  | 192965    | 17      |
-| name                                                                                                                                              | 1613            | 2101     | 1931    | 8371      | 4446    |
+| mintUnbacked                                                                                                                                      | 39385           | 145194   | 130258  | 192591    | 17      |
+| name                                                                                                                                              | 1613            | 2095     | 1931    | 8371      | 4728    |
 | nonces                                                                                                                                            | 1183            | 3134     | 3261    | 3261      | 64      |
 | permit                                                                                                                                            | 29288           | 46358    | 37821   | 81919     | 8       |
-| repay(address,uint256,uint256,address)                                                                                                            | 60445           | 129255   | 167596  | 186974    | 13      |
-| repay(bytes32)                                                                                                                                    | 157189          | 157189   | 157189  | 157189    | 1       |
-| repayWithATokens(address,uint256,uint256)                                                                                                         | 154919          | 181702   | 182098  | 193095    | 57      |
-| repayWithATokens(bytes32)                                                                                                                         | 160214          | 160214   | 160214  | 160214    | 1       |
-| repayWithPermit(address,uint256,uint256,address,uint256,uint8,bytes32,bytes32)                                                                    | 155535          | 184979   | 182716  | 218483    | 150     |
-| repayWithPermit(bytes32,bytes32,bytes32)                                                                                                          | 190349          | 205075   | 196796  | 217554    | 51      |
-| rescueTokens                                                                                                                                      | 39090           | 69890    | 70416   | 70481     | 113     |
-| resetIsolationModeTotalDebt                                                                                                                       | 32573           | 32781    | 32661   | 41891     | 112     |
-| scaledBalanceOf                                                                                                                                   | 1296            | 3893     | 3296    | 7796      | 4833    |
-| scaledTotalSupply                                                                                                                                 | 979             | 5054     | 7523    | 7523      | 9894    |
-| setAssetBorrowableInEMode                                                                                                                         | 97349           | 114455   | 114449  | 127676    | 394     |
-| setAssetCollateralInEMode                                                                                                                         | 44072           | 102126   | 110608  | 110608    | 642     |
+| repay(address,uint256,uint256,address)                                                                                                            | 60328           | 129005   | 167218  | 186596    | 13      |
+| repay(bytes32)                                                                                                                                    | 156855          | 156855   | 156855  | 156855    | 1       |
+| repayWithATokens(address,uint256,uint256)                                                                                                         | 161043          | 181176   | 181714  | 192720    | 57      |
+| repayWithATokens(bytes32)                                                                                                                         | 159903          | 159903   | 159903  | 159903    | 1       |
+| repayWithPermit(address,uint256,uint256,address,uint256,uint8,bytes32,bytes32)                                                                    | 157882          | 180298   | 172938  | 218102    | 165     |
+| repayWithPermit(bytes32,bytes32,bytes32)                                                                                                          | 188729          | 203492   | 196487  | 217222    | 55      |
+| rescueTokens                                                                                                                                      | 39090           | 69891    | 70416   | 70481     | 113     |
+| resetIsolationModeTotalDebt                                                                                                                       | 32573           | 32748    | 32595   | 41825     | 112     |
+| scaledBalanceOf                                                                                                                                   | 1296            | 3503     | 3296    | 7796      | 9089    |
+| scaledTotalSupply                                                                                                                                 | 979             | 5545     | 7523    | 7523      | 12481   |
+| setAssetBorrowableInEMode                                                                                                                         | 91538           | 108644   | 108638  | 121798    | 394     |
+| setAssetCollateralInEMode                                                                                                                         | 44072           | 96796    | 104763  | 104786    | 642     |
 | setBorrowCap                                                                                                                                      | 43734           | 47605    | 43734   | 70862     | 66      |
-| setBorrowableInIsolation                                                                                                                          | 67604           | 70018    | 70407   | 70407     | 13      |
-| setConfiguration                                                                                                                                  | 32766           | 32777    | 32777   | 32788     | 110     |
-| setDebtCeiling                                                                                                                                    | 43713           | 60872    | 43713   | 125470    | 73      |
-| setEModeCategory                                                                                                                                  | 44817           | 102639   | 108823  | 108835    | 638     |
+| setBorrowableInIsolation                                                                                                                          | 67604           | 70015    | 70407   | 70407     | 13      |
+| setConfiguration                                                                                                                                  | 32766           | 32788    | 32788   | 32810     | 110     |
+| setDebtCeiling                                                                                                                                    | 43713           | 58531    | 43713   | 113268    | 73      |
+| setEModeCategory                                                                                                                                  | 44817           | 103136   | 109372  | 109384    | 638     |
 | setIncentivesController                                                                                                                           | 38478           | 40847    | 40847   | 43216     | 2       |
-| setLiquidationGracePeriod                                                                                                                         | 32833           | 37963    | 37353   | 43763     | 330     |
+| setLiquidationGracePeriod                                                                                                                         | 32833           | 37944    | 37331   | 43741     | 330     |
 | setLiquidationProtocolFee                                                                                                                         | 43966           | 60573    | 69843   | 70933     | 8       |
-| setPoolPause(bool)                                                                                                                                | 43516           | 45449    | 43528   | 116161    | 113     |
-| setPoolPause(bool,uint40)                                                                                                                         | 43759           | 86554    | 43831   | 134169    | 108     |
-| setReserveActive                                                                                                                                  | 40882           | 53217    | 40882   | 121965    | 66      |
+| setPoolPause(bool)                                                                                                                                | 43516           | 45446    | 43516   | 116094    | 113     |
+| setPoolPause(bool,uint40)                                                                                                                         | 43771           | 88078    | 43831   | 134036    | 108     |
+| setReserveActive                                                                                                                                  | 40882           | 51369    | 40882   | 109763    | 66      |
 | setReserveBorrowing                                                                                                                               | 43825           | 62281    | 68433   | 68436     | 220     |
-| setReserveFactor                                                                                                                                  | 43758           | 45657    | 43758   | 151653    | 57      |
+| setReserveFactor                                                                                                                                  | 43758           | 45652    | 43758   | 151390    | 57      |
 | setReserveFlashLoaning                                                                                                                            | 68432           | 68452    | 68435   | 70587     | 111     |
-| setReserveFreeze                                                                                                                                  | 47008           | 73282    | 74806   | 99820     | 169     |
-| setReserveInterestRateData                                                                                                                        | 44316           | 46059    | 44544   | 133943    | 56      |
-| setReserveInterestRateStrategyAddress(address,address)                                                                                            | 32829           | 34615    | 33178   | 42713     | 332     |
-| setReserveInterestRateStrategyAddress(address,address,bytes)                                                                                      | 44459           | 96824    | 44459   | 192989    | 99      |
-| setReservePause(address,bool)                                                                                                                     | 43816           | 57036    | 69873   | 69873     | 111     |
-| setReservePause(address,bool,uint40)                                                                                                              | 41264           | 65735    | 73877   | 76187     | 658     |
-| setSiloedBorrowing                                                                                                                                | 105040          | 114886   | 118732  | 120887    | 3       |
-| setSupplyCap                                                                                                                                      | 43691           | 58619    | 70807   | 70843     | 126     |
+| setReserveFreeze                                                                                                                                  | 47008           | 73569    | 74806   | 99820     | 173     |
+| setReserveInterestRateData                                                                                                                        | 44328           | 45932    | 44544   | 127891    | 56      |
+| setReserveInterestRateStrategyAddress(address,address)                                                                                            | 32829           | 34606    | 33178   | 42691     | 332     |
+| setReserveInterestRateStrategyAddress(address,address,bytes)                                                                                      | 44459           | 94125    | 44459   | 186915    | 99      |
+| setReservePause(address,bool)                                                                                                                     | 43816           | 57031    | 69873   | 69873     | 111     |
+| setReservePause(address,bool,uint40)                                                                                                              | 41264           | 65987    | 73855   | 76165     | 668     |
+| setSiloedBorrowing                                                                                                                                | 82616           | 93795    | 98308   | 100463    | 3       |
+| setSupplyCap                                                                                                                                      | 43691           | 58620    | 70807   | 70843     | 126     |
 | setUnbackedMintCap                                                                                                                                | 70854           | 70854    | 70854   | 70854     | 7       |
-| setUserEMode                                                                                                                                      | 40463           | 73473    | 67427   | 121033    | 573     |
-| setUserUseReserveAsCollateral(address,bool)                                                                                                       | 80249           | 96257    | 93457   | 129473    | 42      |
-| setUserUseReserveAsCollateral(bytes32)                                                                                                            | 95254           | 95254    | 95254   | 95254     | 1       |
+| setUserEMode                                                                                                                                      | 40441           | 73483    | 67405   | 121011    | 573     |
+| setUserUseReserveAsCollateral(address,bool)                                                                                                       | 80227           | 96252    | 93456   | 129472    | 42      |
+| setUserUseReserveAsCollateral(bytes32)                                                                                                            | 95189           | 95189    | 95189   | 95189     | 1       |
 | setValue                                                                                                                                          | 31565           | 31581    | 31589   | 31589     | 3       |
-| supply(address,uint256,address,uint16)                                                                                                            | 56589           | 218981   | 226189  | 243423    | 1550    |
-| supply(bytes32)                                                                                                                                   | 236846          | 236846   | 236846  | 236846    | 7       |
-| supplyWithPermit(address,uint256,address,uint16,uint256,uint8,bytes32,bytes32)                                                                    | 142270          | 216334   | 241875  | 266413    | 157     |
-| supplyWithPermit(bytes32,bytes32,bytes32)                                                                                                         | 262466          | 262515   | 262478  | 262646    | 54      |
-| symbol                                                                                                                                            | 1634            | 2185     | 1996    | 8436      | 4421    |
+| supply(address,uint256,address,uint16)                                                                                                            | 56472           | 214437   | 225814  | 243048    | 2545    |
+| supply(bytes32)                                                                                                                                   | 236471          | 236471   | 236471  | 236471    | 7       |
+| supplyWithPermit(address,uint256,address,uint16,uint256,uint8,bytes32,bytes32)                                                                    | 141895          | 216010   | 241512  | 266038    | 157     |
+| supplyWithPermit(bytes32,bytes32,bytes32)                                                                                                         | 262101          | 262171   | 262161  | 262293    | 54      |
+| symbol                                                                                                                                            | 1634            | 2182     | 2193    | 8436      | 4703    |
 | text                                                                                                                                              | 1778            | 1778     | 1778    | 1778      | 8       |
-| totalSupply                                                                                                                                       | 1013            | 5916     | 3013    | 15569     | 2997    |
-| transfer                                                                                                                                          | 27651           | 140023   | 149272  | 166887    | 71      |
-| transferFrom                                                                                                                                      | 138593          | 138713   | 138713  | 138833    | 2       |
+| totalSupply                                                                                                                                       | 1013            | 6801     | 3013    | 15591     | 3630    |
+| transfer                                                                                                                                          | 27651           | 138144   | 149316  | 166931    | 71      |
+| transferFrom                                                                                                                                      | 138637          | 138757   | 138757  | 138877    | 2       |
 | transferOnLiquidation                                                                                                                             | 28049           | 28049    | 28049   | 28049     | 1       |
 | transferUnderlyingTo                                                                                                                              | 27493           | 27493    | 27493   | 27493     | 1       |
-| updateAToken                                                                                                                                      | 41743           | 43670    | 41743   | 149706    | 56      |
-| updateBridgeProtocolFee                                                                                                                           | 32511           | 37397    | 32556   | 78320     | 124     |
-| updateFlashloanPremiumToProtocol                                                                                                                  | 40424           | 40827    | 40424   | 63303     | 57      |
-| updateFlashloanPremiumTotal                                                                                                                       | 40378           | 40781    | 40378   | 63268     | 57      |
-| updateFlashloanPremiums                                                                                                                           | 32836           | 32847    | 32847   | 32858     | 110     |
-| updateVariableDebtToken                                                                                                                           | 41598           | 43419    | 41598   | 143589    | 56      |
+| updateAToken                                                                                                                                      | 41743           | 43232    | 41743   | 125158    | 56      |
+| updateBridgeProtocolFee                                                                                                                           | 32556           | 37441    | 32578   | 78453     | 124     |
+| updateFlashloanPremiumToProtocol                                                                                                                  | 40424           | 40826    | 40424   | 63259     | 57      |
+| updateFlashloanPremiumTotal                                                                                                                       | 40378           | 40781    | 40378   | 63224     | 57      |
+| updateFlashloanPremiums                                                                                                                           | 32836           | 32880    | 32880   | 32925     | 110     |
+| updateVariableDebtToken                                                                                                                           | 41598           | 42980    | 41598   | 119042    | 56      |
 | upgradeTo                                                                                                                                         | 26845           | 28735    | 28735   | 30625     | 2       |
 | upgradeToAndCall                                                                                                                                  | 28747           | 152620   | 187393  | 187393    | 8       |
 | value                                                                                                                                             | 923             | 923      | 923     | 923       | 11      |
 | values                                                                                                                                            | 1203            | 1203     | 1203    | 1203      | 16      |
-| withdraw(address,uint256,address)                                                                                                                 | 66258           | 134574   | 141787  | 204532    | 23      |
-| withdraw(bytes32)                                                                                                                                 | 138601          | 145682   | 145682  | 152763    | 2       |
+| withdraw(address,uint256,address)                                                                                                                 | 66318           | 134324   | 141469  | 204214    | 23      |
+| withdraw(bytes32)                                                                                                                                 | 138369          | 145450   | 145450  | 152532    | 2       |


 | src/contracts/mocks/flashloan/MockFlashLoanReceiver.sol:MockFlashLoanReceiver contract |                 |       |        |       |         |
@@ -683,9 +691,9 @@
 | src/contracts/mocks/helpers/MockPool.sol:MockPoolInherited contract |                 |       |        |       |         |
 |---------------------------------------------------------------------|-----------------|-------|--------|-------|---------|
 | Deployment Cost                                                     | Deployment Size |       |        |       |         |
-| 4878289                                                             | 22516           |       |        |       |         |
+| 4748324                                                             | 21925           |       |        |       |         |
 | Function Name                                                       | min             | avg   | median | max   | # calls |
-| initialize                                                          | 28391           | 28391 | 28391  | 28391 | 2       |
+| initialize                                                          | 28478           | 28478 | 28478  | 28478 | 2       |


 | src/contracts/mocks/oracle/CLAggregators/MockAggregator.sol:MockAggregator contract |                 |      |        |      |         |
@@ -693,10 +701,10 @@
 | Deployment Cost                                                                     | Deployment Size |      |        |      |         |
 | 108467                                                                              | 310             |      |        |      |         |
 | Function Name                                                                       | min             | avg  | median | max  | # calls |
-| _latestAnswer                                                                       | 315             | 315  | 315    | 315  | 908     |
+| _latestAnswer                                                                       | 315             | 315  | 315    | 315  | 2052    |
 | decimals                                                                            | 143             | 143  | 143    | 143  | 83      |
 | description                                                                         | 168             | 168  | 168    | 168  | 83      |
-| latestAnswer                                                                        | 279             | 1638 | 2279   | 2279 | 8342    |
+| latestAnswer                                                                        | 279             | 1341 | 2279   | 2279 | 15698   |
 | name                                                                                | 168             | 168  | 168    | 168  | 83      |


@@ -715,7 +723,7 @@
 | 273603                                                                  | 1358            |       |        |       |         |
 | Function Name                                                           | min             | avg   | median | max   | # calls |
 | latestRoundData                                                         | 724             | 1527  | 729    | 4729  | 10      |
-| setAnswer                                                               | 26203           | 27465 | 26203  | 46115 | 72      |
+| setAnswer                                                               | 26203           | 27414 | 26203  | 46115 | 75      |


 | src/contracts/mocks/swap/MockParaSwapAugustus.sol:MockParaSwapAugustus contract |                 |        |        |        |         |
@@ -749,17 +757,17 @@
 | src/contracts/mocks/testnet-helpers/TestnetERC20.sol:TestnetERC20 contract |                 |       |        |       |         |
 |----------------------------------------------------------------------------|-----------------|-------|--------|-------|---------|
 | Deployment Cost                                                            | Deployment Size |       |        |       |         |
-| 1032293                                                                    | 5652            |       |        |       |         |
+| 1032245                                                                    | 5652            |       |        |       |         |
 | Function Name                                                              | min             | avg   | median | max   | # calls |
 | DOMAIN_SEPARATOR                                                           | 2339            | 2339  | 2339   | 2339  | 55      |
 | allowance                                                                  | 833             | 1944  | 2833   | 2833  | 9       |
-| approve                                                                    | 26300           | 46290 | 46584  | 46584 | 5444    |
-| balanceOf                                                                  | 648             | 1079  | 648    | 2648  | 11009   |
-| decimals                                                                   | 311             | 1487  | 2311   | 2311  | 18442   |
-| mint                                                                       | 36475           | 60304 | 53587  | 70795 | 3951    |
-| name                                                                       | 3236            | 3236  | 3236   | 3236  | 412     |
+| approve                                                                    | 26300           | 46244 | 46584  | 46584 | 5840    |
+| balanceOf                                                                  | 648             | 1071  | 648    | 2648  | 16219   |
+| decimals                                                                   | 311             | 1468  | 2311   | 2311  | 19433   |
+| mint                                                                       | 36475           | 60296 | 53587  | 70795 | 3981    |
+| name                                                                       | 3236            | 3236  | 3236   | 3236  | 431     |
 | nonces                                                                     | 2601            | 2601  | 2601   | 2601  | 55      |
-| permit                                                                     | 76469           | 76508 | 76493  | 76661 | 102     |
+| permit                                                                     | 76457           | 76510 | 76493  | 76661 | 107     |
 | symbol                                                                     | 1323            | 2323  | 2323   | 3323  | 56      |
 | totalSupply                                                                | 348             | 748   | 348    | 2348  | 2490    |
 | transfer                                                                   | 46925           | 51017 | 51701  | 51701 | 7       |
@@ -782,10 +790,10 @@
 | Deployment Cost                                                                    | Deployment Size |     |        |     |         |
 | 117447                                                                             | 326             |     |        |     |         |
 | Function Name                                                                      | min             | avg | median | max | # calls |
-| HALF_PERCENTAGE_FACTOR                                                             | 146             | 146 | 146    | 146 | 104     |
-| PERCENTAGE_FACTOR                                                                  | 223             | 223 | 223    | 223 | 157     |
+| HALF_PERCENTAGE_FACTOR                                                             | 146             | 146 | 146    | 146 | 94      |
+| PERCENTAGE_FACTOR                                                                  | 223             | 223 | 223    | 223 | 148     |
 | percentDiv                                                                         | 316             | 424 | 428    | 428 | 58      |
-| percentMul                                                                         | 333             | 420 | 431    | 431 | 58      |
+| percentMul                                                                         | 333             | 407 | 431    | 431 | 58      |


 | src/contracts/mocks/tests/WadRayMathWrapper.sol:WadRayMathWrapper contract |                 |     |        |     |         |
@@ -796,20 +804,20 @@
 | HALF_RAY                                                                   | 246             | 246 | 246    | 246 | 1       |
 | HALF_WAD                                                                   | 223             | 223 | 223    | 223 | 92      |
 | RAY                                                                        | 224             | 224 | 224    | 224 | 1       |
-| WAD                                                                        | 179             | 179 | 179    | 179 | 136     |
-| WAD_RAY_RATIO                                                              | 268             | 268 | 268    | 268 | 379     |
+| WAD                                                                        | 179             | 179 | 179    | 179 | 139     |
+| WAD_RAY_RATIO                                                              | 268             | 268 | 268    | 268 | 375     |
 | rayDiv                                                                     | 494             | 494 | 494    | 494 | 4       |
 | rayMul                                                                     | 497             | 497 | 497    | 497 | 3       |
 | rayToWad                                                                   | 384             | 387 | 384    | 398 | 113     |
-| wadDiv                                                                     | 426             | 517 | 538    | 538 | 59      |
-| wadMul                                                                     | 333             | 402 | 431    | 431 | 61      |
-| wadToRay                                                                   | 280             | 352 | 357    | 357 | 107     |
+| wadDiv                                                                     | 426             | 519 | 538    | 538 | 59      |
+| wadMul                                                                     | 333             | 406 | 431    | 431 | 61      |
+| wadToRay                                                                   | 280             | 349 | 357    | 357 | 103     |


 | src/contracts/mocks/tokens/MockATokenRepayment.sol:MockATokenRepayment contract |                 |       |        |       |         |
 |---------------------------------------------------------------------------------|-----------------|-------|--------|-------|---------|
 | Deployment Cost                                                                 | Deployment Size |       |        |       |         |
-| 2334681                                                                         | 11175           |       |        |       |         |
+| 2334748                                                                         | 11175           |       |        |       |         |
 | Function Name                                                                   | min             | avg   | median | max   | # calls |
 | RESERVE_TREASURY_ADDRESS                                                        | 419             | 419   | 419    | 419   | 1       |
 | getIncentivesController                                                         | 474             | 474   | 474    | 474   | 1       |
@@ -821,7 +829,7 @@
 | src/contracts/mocks/tokens/MockDebtTokens.sol:MockVariableDebtToken contract |                 |       |        |       |         |
 |------------------------------------------------------------------------------|-----------------|-------|--------|-------|---------|
 | Deployment Cost                                                              | Deployment Size |       |        |       |         |
-| 1695959                                                                      | 8194            |       |        |       |         |
+| 1696026                                                                      | 8194            |       |        |       |         |
 | Function Name                                                                | min             | avg   | median | max   | # calls |
 | getIncentivesController                                                      | 430             | 430   | 430    | 430   | 1       |
 | initialize                                                                   | 56093           | 56093 | 56093  | 56093 | 1       |
@@ -832,7 +840,7 @@
 | src/contracts/mocks/tokens/MockScaledToken.sol:MockScaledToken contract |                 |       |        |       |         |
 |-------------------------------------------------------------------------|-----------------|-------|--------|-------|---------|
 | Deployment Cost                                                         | Deployment Size |       |        |       |         |
-| 1004529                                                                 | 4790            |       |        |       |         |
+| 1004596                                                                 | 4790            |       |        |       |         |
 | Function Name                                                           | min             | avg   | median | max   | # calls |
 | balanceOf                                                               | 584             | 584   | 584    | 584   | 4       |
 | setStorage                                                              | 67846           | 67846 | 67846  | 67846 | 1       |
@@ -888,23 +896,23 @@
 | Deployment Cost                                                         | Deployment Size |       |        |       |         |
 | 847989                                                                  | 4139            |       |        |       |         |
 | Function Name                                                           | min             | avg   | median | max   | # calls |
-| DEFAULT_ADMIN_ROLE                                                      | 282             | 282   | 282    | 282   | 1382    |
+| DEFAULT_ADMIN_ROLE                                                      | 282             | 282   | 282    | 282   | 1414    |
 | FLASH_BORROWER_ROLE                                                     | 315             | 315   | 315    | 315   | 20      |
-| POOL_ADMIN_ROLE                                                         | 292             | 292   | 292    | 292   | 681     |
+| POOL_ADMIN_ROLE                                                         | 292             | 292   | 292    | 292   | 697     |
 | addAssetListingAdmin                                                    | 50955           | 50955 | 50955  | 50955 | 3       |
 | addBridge                                                               | 51021           | 51021 | 51021  | 51021 | 14      |
 | addEmergencyAdmin                                                       | 50956           | 50956 | 50956  | 50956 | 3       |
 | addFlashBorrower                                                        | 50977           | 52114 | 50977  | 55528 | 4       |
-| addPoolAdmin                                                            | 50988           | 50999 | 51000  | 51000 | 668     |
+| addPoolAdmin                                                            | 50988           | 50999 | 51000  | 51000 | 684     |
 | addRiskAdmin                                                            | 51021           | 51021 | 51021  | 51021 | 14      |
 | grantRole                                                               | 51474           | 52044 | 51474  | 56036 | 8       |
 | hasRole                                                                 | 737             | 2526  | 2737   | 2737  | 19      |
-| isAssetListingAdmin                                                     | 809             | 2089  | 2809   | 2809  | 1807    |
+| isAssetListingAdmin                                                     | 809             | 2085  | 2809   | 2809  | 1842    |
 | isBridge                                                                | 2786            | 2786  | 2786   | 2786  | 26      |
 | isEmergencyAdmin                                                        | 742             | 2737  | 2742   | 2742  | 948     |
 | isFlashBorrower                                                         | 2828            | 2828  | 2828   | 2828  | 66      |
-| isPoolAdmin                                                             | 752             | 1249  | 752    | 2752  | 28889   |
-| isRiskAdmin                                                             | 742             | 1123  | 742    | 2742  | 23250   |
+| isPoolAdmin                                                             | 752             | 1242  | 752    | 2752  | 29456   |
+| isRiskAdmin                                                             | 742             | 1117  | 742    | 2742  | 23738   |
 | removeAssetListingAdmin                                                 | 29047           | 29047 | 29047  | 29047 | 2       |
 | removeBridge                                                            | 29016           | 29016 | 29016  | 29016 | 1       |
 | removeEmergencyAdmin                                                    | 28992           | 28992 | 28992  | 28992 | 1       |
@@ -919,24 +927,24 @@
 | Deployment Cost                                                                               | Deployment Size |        |        |        |         |
 | 1571699                                                                                       | 8177            |        |        |        |         |
 | Function Name                                                                                 | min             | avg    | median | max    | # calls |
-| getACLAdmin                                                                                   | 477             | 681    | 477    | 2477   | 763     |
-| getACLManager                                                                                 | 531             | 968    | 531    | 2531   | 27795   |
-| getAddress                                                                                    | 543             | 1045   | 543    | 2543   | 10118   |
+| getACLAdmin                                                                                   | 477             | 679    | 477    | 2477   | 780     |
+| getACLManager                                                                                 | 531             | 962    | 531    | 2531   | 28362   |
+| getAddress                                                                                    | 543             | 1182   | 543    | 2543   | 1035    |
 | getMarketId                                                                                   | 1346            | 1346   | 1346   | 1346   | 6       |
-| getPool                                                                                       | 466             | 776    | 466    | 2466   | 14575   |
-| getPoolConfigurator                                                                           | 509             | 725    | 509    | 2509   | 67952   |
-| getPoolDataProvider                                                                           | 486             | 1203   | 486    | 2486   | 2089    |
-| getPriceOracle                                                                                | 574             | 2254   | 2574   | 2574   | 4344    |
-| getPriceOracleSentinel                                                                        | 487             | 2467   | 2487   | 2487   | 1788    |
-| owner                                                                                         | 363             | 363    | 363    | 363    | 686     |
+| getPool                                                                                       | 466             | 777    | 466    | 2466   | 14817   |
+| getPoolConfigurator                                                                           | 509             | 723    | 509    | 2509   | 69291   |
+| getPoolDataProvider                                                                           | 486             | 1201   | 486    | 2486   | 2137    |
+| getPriceOracle                                                                                | 574             | 1904   | 2574   | 2574   | 8259    |
+| getPriceOracleSentinel                                                                        | 487             | 2475   | 2487   | 2487   | 2857    |
+| owner                                                                                         | 363             | 363    | 363    | 363    | 702     |
 | setACLAdmin                                                                                   | 24013           | 45794  | 47617  | 47617  | 24      |
 | setACLManager                                                                                 | 24056           | 37484  | 39110  | 47660  | 4       |
-| setAddress                                                                                    | 24622           | 35608  | 31536  | 48636  | 5       |
+| setAddress                                                                                    | 24622           | 48054  | 48360  | 48636  | 280     |
 | setAddressAsProxy                                                                             | 24328           | 224316 | 57038  | 507830 | 5       |
 | setMarketId                                                                                   | 24420           | 28552  | 28552  | 32685  | 2       |
-| setPoolConfiguratorImpl                                                                       | 24012           | 287005 | 295057 | 533894 | 4       |
+| setPoolConfiguratorImpl                                                                       | 24012           | 287022 | 295092 | 533894 | 4       |
 | setPoolDataProvider                                                                           | 24101           | 37529  | 39155  | 47705  | 4       |
-| setPoolImpl                                                                                   | 24057           | 273450 | 281500 | 506744 | 4       |
+| setPoolImpl                                                                                   | 24057           | 273500 | 281568 | 506809 | 4       |
 | setPriceOracle                                                                                | 24080           | 37508  | 39134  | 47684  | 4       |
 | setPriceOracleSentinel                                                                        | 24123           | 40943  | 47727  | 47727  | 6       |

@@ -949,7 +957,7 @@
 | getAddressesProviderAddressById                                                                               | 519             | 519    | 519    | 519    | 4       |
 | getAddressesProviderIdByAddress                                                                               | 556             | 1222   | 556    | 2556   | 6       |
 | getAddressesProvidersList                                                                                     | 671             | 3400   | 3288   | 5014   | 5       |
-| owner                                                                                                         | 329             | 2323   | 2329   | 2329   | 683     |
+| owner                                                                                                         | 329             | 2323   | 2329   | 2329   | 699     |
 | registerAddressesProvider                                                                                     | 24438           | 104006 | 119920 | 119920 | 6       |
 | unregisterAddressesProvider                                                                                   | 26441           | 39021  | 39997  | 49652  | 4       |

@@ -959,7 +967,7 @@
 | Deployment Cost                                                    | Deployment Size |        |        |        |         |
 | 833790                                                             | 3948            |        |        |        |         |
 | Function Name                                                      | min             | avg    | median | max    | # calls |
-| configureAssets                                                    | 284134          | 284424 | 284194 | 289908 | 518     |
+| configureAssets                                                    | 284134          | 284422 | 284194 | 289908 | 518     |
 | getEmissionAdmin                                                   | 547             | 547    | 547    | 547    | 6       |
 | getRewardsController                                               | 385             | 1385   | 1385   | 2385   | 2       |
 | owner                                                              | 384             | 384    | 384    | 384    | 2       |
@@ -977,17 +985,17 @@
 | Deployment Cost                                                        | Deployment Size |        |        |        |         |
 | 3131951                                                                | 14452           |        |        |        |         |
 | Function Name                                                          | min             | avg    | median | max    | # calls |
-| EMISSION_MANAGER                                                       | 326             | 326    | 326    | 326    | 685     |
+| EMISSION_MANAGER                                                       | 326             | 326    | 326    | 326    | 701     |
 | claimAllRewards                                                        | 92263           | 92263  | 92263  | 92263  | 1       |
 | claimAllRewardsOnBehalf                                                | 94562           | 94562  | 94562  | 94562  | 1       |
 | claimAllRewardsToSelf                                                  | 92062           | 92062  | 92062  | 92062  | 1       |
-| claimRewards                                                           | 952             | 72531  | 84890  | 97899  | 155     |
+| claimRewards                                                           | 952             | 71217  | 84899  | 97899  | 135     |
 | claimRewardsOnBehalf                                                   | 88363           | 88363  | 88363  | 88363  | 1       |
 | claimRewardsToSelf                                                     | 85866           | 85866  | 85866  | 85866  | 1       |
 | configureAssets                                                        | 246530          | 246750 | 246530 | 252244 | 518     |
 | getAllUserRewards                                                      | 8567            | 8567   | 8567   | 8567   | 1       |
 | getAssetDecimals                                                       | 656             | 656    | 656    | 656    | 2       |
-| getAssetIndex                                                          | 2466            | 7696   | 8974   | 11392  | 2079    |
+| getAssetIndex                                                          | 2466            | 7708   | 8974   | 11392  | 2069    |
 | getClaimer                                                             | 625             | 2589   | 2625   | 2625   | 112     |
 | getDistributionEnd                                                     | 789             | 789    | 789    | 789    | 1       |
 | getEmissionManager                                                     | 258             | 258    | 258    | 258    | 5       |
@@ -998,9 +1006,9 @@
 | getTransferStrategy                                                    | 648             | 648    | 648    | 648    | 1       |
 | getUserAccruedRewards                                                  | 1641            | 1641   | 1641   | 1641   | 1       |
 | getUserAssetIndex                                                      | 1005            | 1005   | 1005   | 1005   | 1       |
-| getUserRewards                                                         | 6793            | 7959   | 8081   | 12368  | 66      |
-| handleAction                                                           | 728             | 2287   | 2728   | 38069  | 8227    |
-| initialize                                                             | 26065           | 45245  | 45250  | 53154  | 683     |
+| getUserRewards                                                         | 6793            | 7953   | 8081   | 12368  | 66      |
+| handleAction                                                           | 728             | 2270   | 2728   | 38069  | 11810   |
+| initialize                                                             | 26065           | 45245  | 45250  | 53154  | 699     |
 | setClaimer                                                             | 24279           | 24279  | 24279  | 24279  | 59      |
 | setDistributionEnd                                                     | 8884            | 8884   | 8884   | 8884   | 2       |
 | setEmissionPerSecond                                                   | 24303           | 24303  | 24303  | 24303  | 2       |
@@ -1036,7 +1044,7 @@
 | Deployment Cost                                         | Deployment Size |       |        |       |         |
 | 0                                                       | 0               |       |        |       |         |
 | Function Name                                           | min             | avg   | median | max   | # calls |
-| initialize                                              | 90680           | 90680 | 90680  | 90680 | 708     |
+| initialize                                              | 90680           | 90680 | 90680  | 90680 | 724     |


 | src/contracts/treasury/RevenueSplitter.sol:RevenueSplitter contract |                 |        |        |        |         |
@@ -1049,23 +1057,23 @@
 | SPLIT_PERCENTAGE_RECIPIENT_A                                        | 170             | 170    | 170    | 170    | 491     |
 | receive                                                             | 0               | 0      | 0      | 0      | 56      |
 | splitNativeRevenue                                                  | 23633           | 90996  | 92645  | 92645  | 57      |
-| splitRevenue                                                        | 24246           | 129585 | 135765 | 135765 | 112     |
+| splitRevenue                                                        | 24246           | 128965 | 135765 | 135765 | 112     |


 | src/deployments/projects/aave-v3-batched/batches/AaveV3GettersBatchOne.sol:AaveV3GettersBatchOne contract |                 |     |        |     |         |
 |-----------------------------------------------------------------------------------------------------------|-----------------|-----|--------|-----|---------|
 | Deployment Cost                                                                                           | Deployment Size |     |        |     |         |
-| 5027098                                                                                                   | 32657           |     |        |     |         |
+| 5076368                                                                                                   | 33025           |     |        |     |         |
 | Function Name                                                                                             | min             | avg | median | max | # calls |
-| getGettersReportOne                                                                                       | 968             | 968 | 968    | 968 | 705     |
+| getGettersReportOne                                                                                       | 968             | 968 | 968    | 968 | 721     |


 | src/deployments/projects/aave-v3-batched/batches/AaveV3GettersBatchTwo.sol:AaveV3GettersBatchTwo contract |                 |     |        |     |         |
 |-----------------------------------------------------------------------------------------------------------|-----------------|-----|--------|-----|---------|
 | Deployment Cost                                                                                           | Deployment Size |     |        |     |         |
-| 1506020                                                                                                   | 11284           |     |        |     |         |
+| 1403193                                                                                                   | 10809           |     |        |     |         |
 | Function Name                                                                                             | min             | avg | median | max | # calls |
-| getGettersReportTwo                                                                                       | 533             | 533 | 533    | 533 | 679     |
+| getGettersReportTwo                                                                                       | 533             | 533 | 533    | 533 | 695     |


 | src/deployments/projects/aave-v3-batched/batches/AaveV3HelpersBatchOne.sol:AaveV3HelpersBatchOne contract |                 |      |        |      |         |
@@ -1073,21 +1081,21 @@
 | Deployment Cost                                                                                           | Deployment Size |      |        |      |         |
 | 7236222                                                                                                   | 34331           |      |        |      |         |
 | Function Name                                                                                             | min             | avg  | median | max  | # calls |
-| getConfigEngineReport                                                                                     | 1693            | 1693 | 1693   | 1693 | 653     |
+| getConfigEngineReport                                                                                     | 1693            | 1693 | 1693   | 1693 | 669     |


 | src/deployments/projects/aave-v3-batched/batches/AaveV3HelpersBatchTwo.sol:AaveV3HelpersBatchTwo contract |                 |     |        |     |         |
 |-----------------------------------------------------------------------------------------------------------|-----------------|-----|--------|-----|---------|
 | Deployment Cost                                                                                           | Deployment Size |     |        |     |         |
-| 7474689                                                                                                   | 32895           |     |        |     |         |
+| 7364790                                                                                                   | 32366           |     |        |     |         |
 | Function Name                                                                                             | min             | avg | median | max | # calls |
-| staticATokenReport                                                                                        | 968             | 968 | 968    | 968 | 653     |
+| staticATokenReport                                                                                        | 968             | 968 | 968    | 968 | 669     |


 | src/deployments/projects/aave-v3-batched/batches/AaveV3L2PoolBatch.sol:AaveV3L2PoolBatch contract |                 |     |        |     |         |
 |---------------------------------------------------------------------------------------------------|-----------------|-----|--------|-----|---------|
 | Deployment Cost                                                                                   | Deployment Size |     |        |     |         |
-| 9598548                                                                                           | 43985           |     |        |     |         |
+| 9468557                                                                                           | 43394           |     |        |     |         |
 | Function Name                                                                                     | min             | avg | median | max | # calls |
 | getPoolReport                                                                                     | 533             | 533 | 533    | 533 | 76      |

@@ -1097,13 +1105,13 @@
 | Deployment Cost                                                                               | Deployment Size |     |        |     |         |
 | 1046333                                                                                       | 6958            |     |        |     |         |
 | Function Name                                                                                 | min             | avg | median | max | # calls |
-| getMiscReport                                                                                 | 533             | 533 | 533    | 533 | 705     |
+| getMiscReport                                                                                 | 533             | 533 | 533    | 533 | 721     |


 | src/deployments/projects/aave-v3-batched/batches/AaveV3ParaswapBatch.sol:AaveV3ParaswapBatch contract |                 |     |        |     |         |
 |-------------------------------------------------------------------------------------------------------|-----------------|-----|--------|-----|---------|
 | Deployment Cost                                                                                       | Deployment Size |     |        |     |         |
-| 6402821                                                                                               | 33403           |     |        |     |         |
+| 6050676                                                                                               | 31792           |     |        |     |         |
 | Function Name                                                                                         | min             | avg | median | max | # calls |
 | getParaswapReport                                                                                     | 968             | 968 | 968    | 968 | 34      |

@@ -1113,15 +1121,15 @@
 | Deployment Cost                                                                                         | Deployment Size |      |        |      |         |
 | 7501711                                                                                                 | 40894           |      |        |      |         |
 | Function Name                                                                                           | min             | avg  | median | max  | # calls |
-| getPeripheryReport                                                                                      | 1512            | 3509 | 3512   | 5512 | 705     |
+| getPeripheryReport                                                                                      | 1512            | 3509 | 3512   | 5512 | 721     |


 | src/deployments/projects/aave-v3-batched/batches/AaveV3PoolBatch.sol:AaveV3PoolBatch contract |                 |     |        |     |         |
 |-----------------------------------------------------------------------------------------------|-----------------|-----|--------|-----|---------|
 | Deployment Cost                                                                               | Deployment Size |     |        |     |         |
-| 9328324                                                                                       | 42738           |     |        |     |         |
+| 9198474                                                                                       | 42147           |     |        |     |         |
 | Function Name                                                                                 | min             | avg | median | max | # calls |
-| getPoolReport                                                                                 | 533             | 533 | 533    | 533 | 629     |
+| getPoolReport                                                                                 | 533             | 533 | 533    | 533 | 645     |


 | src/deployments/projects/aave-v3-batched/batches/AaveV3SetupBatch.sol:AaveV3SetupBatch contract |                 |         |         |         |         |
@@ -1129,17 +1137,17 @@
 | Deployment Cost                                                                                 | Deployment Size |         |         |         |         |
 | 5190443                                                                                         | 28372           |         |         |         |         |
 | Function Name                                                                                   | min             | avg     | median  | max     | # calls |
-| getInitialReport                                                                                | 619             | 619     | 619     | 619     | 705     |
-| setMarketReport                                                                                 | 632452          | 635166  | 632452  | 773432  | 653     |
-| setupAaveV3Market                                                                               | 2168961         | 2661798 | 2661889 | 2687948 | 681     |
+| getInitialReport                                                                                | 619             | 619     | 619     | 619     | 721     |
+| setMarketReport                                                                                 | 632452          | 635101  | 632452  | 773432  | 669     |
+| setupAaveV3Market                                                                               | 2168938         | 2661797 | 2661866 | 2688148 | 697     |


 | src/deployments/projects/aave-v3-batched/batches/AaveV3TokensBatch.sol:AaveV3TokensBatch contract |                 |     |        |     |         |
 |---------------------------------------------------------------------------------------------------|-----------------|-----|--------|-----|---------|
 | Deployment Cost                                                                                   | Deployment Size |     |        |     |         |
-| 4228121                                                                                           | 20353           |     |        |     |         |
+| 4228255                                                                                           | 20353           |     |        |     |         |
 | Function Name                                                                                     | min             | avg | median | max | # calls |
-| getTokensReport                                                                                   | 533             | 533 | 533    | 533 | 679     |
+| getTokensReport                                                                                   | 533             | 533 | 533    | 533 | 695     |


 | tests/extensions/static-a-token/ERC20AaveLMUpgradable.t.sol:MockERC20AaveLMUpgradeable contract |                 |        |        |        |         |
@@ -1147,20 +1155,20 @@
 | Deployment Cost                                                                                 | Deployment Size |        |        |        |         |
 | 1871016                                                                                         | 8613            |        |        |        |         |
 | Function Name                                                                                   | min             | avg    | median | max    | # calls |
-| claimRewards                                                                                    | 58219           | 96127  | 58645  | 173391 | 55      |
-| claimRewardsOnBehalf                                                                            | 34383           | 88909  | 59174  | 177643 | 165     |
-| claimRewardsToSelf                                                                              | 57729           | 108168 | 58155  | 172901 | 55      |
-| collectAndUpdateRewards                                                                         | 48341           | 85724  | 57313  | 130455 | 56      |
-| getClaimableRewards                                                                             | 6163            | 6511   | 6580   | 26280  | 726     |
+| claimRewards                                                                                    | 58219           | 106593 | 58645  | 173391 | 55      |
+| claimRewardsOnBehalf                                                                            | 34383           | 77121  | 59165  | 177643 | 165     |
+| claimRewardsToSelf                                                                              | 57729           | 91435  | 58146  | 172901 | 55      |
+| collectAndUpdateRewards                                                                         | 48341           | 86973  | 57313  | 130455 | 56      |
+| getClaimableRewards                                                                             | 6163            | 6508   | 6580   | 26280  | 718     |
 | getReferenceAsset                                                                               | 2495            | 2495   | 2495   | 2495   | 1       |
-| getTotalClaimableRewards                                                                        | 10950           | 11550  | 11367  | 24654  | 56      |
-| getUnclaimedRewards                                                                             | 818             | 818    | 818    | 818    | 226     |
+| getTotalClaimableRewards                                                                        | 10950           | 11543  | 11367  | 24654  | 56      |
+| getUnclaimedRewards                                                                             | 818             | 818    | 818    | 818    | 218     |
 | isRegisteredRewardToken                                                                         | 575             | 1241   | 575    | 2575   | 3       |
-| mint                                                                                            | 53655           | 96993  | 97646  | 100854 | 526     |
+| mint                                                                                            | 53655           | 97053  | 97646  | 100854 | 524     |
 | mockInit                                                                                        | 79952           | 79952  | 79952  | 79952  | 16      |
 | refreshRewardTokens                                                                             | 116549          | 116557 | 116557 | 116975 | 498     |
 | rewardTokens                                                                                    | 1012            | 1012   | 1012   | 1012   | 1       |
-| transfer                                                                                        | 60144           | 76481  | 73061  | 103101 | 110     |
+| transfer                                                                                        | 60126           | 77064  | 73023  | 103110 | 110     |


 | tests/extensions/static-a-token/ERC20AaveLMUpgradable.t.sol:MockScaledTestnetERC20 contract |                 |       |        |       |         |
@@ -1169,38 +1177,38 @@
 | 1058431                                                                                     | 5780            |       |        |       |         |
 | Function Name                                                                               | min             | avg   | median | max   | # calls |
 | decimals                                                                                    | 2333            | 2333  | 2333   | 2333  | 498     |
-| getScaledUserBalanceAndSupply                                                               | 735             | 2754  | 2735   | 4735  | 207     |
-| mint                                                                                        | 51332           | 67662 | 68648  | 68648 | 526     |
-| scaledTotalSupply                                                                           | 394             | 1831  | 2394   | 2394  | 2576    |
-| transfer                                                                                    | 29803           | 45994 | 46975  | 46975 | 526     |
+| getScaledUserBalanceAndSupply                                                               | 735             | 2756  | 2735   | 4735  | 187     |
+| mint                                                                                        | 51332           | 67722 | 68648  | 68648 | 524     |
+| scaledTotalSupply                                                                           | 394             | 1835  | 2394   | 2394  | 2566    |
+| transfer                                                                                    | 29803           | 46055 | 46975  | 46975 | 524     |


 | tests/extensions/static-a-token/ERC4626StataTokenUpgradeable.t.sol:MockERC4626StataTokenUpgradeable contract |                 |        |        |        |         |
 |--------------------------------------------------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
 | Deployment Cost                                                                                              | Deployment Size |        |        |        |         |
-| 2145705                                                                                                      | 10019           |        |        |        |         |
+| 2145772                                                                                                      | 10019           |        |        |        |         |
 | Function Name                                                                                                | min             | avg    | median | max    | # calls |
-| approve                                                                                                      | 26451           | 45885  | 46405  | 46495  | 110     |
+| approve                                                                                                      | 26451           | 45698  | 46393  | 46495  | 110     |
 | balanceOf                                                                                                    | 607             | 607    | 607    | 607    | 551     |
-| convertToAssets                                                                                              | 2937            | 2937   | 2937   | 2937   | 55      |
-| convertToShares                                                                                              | 15938           | 15938  | 15938  | 15938  | 55      |
+| convertToAssets                                                                                              | 2959            | 2959   | 2959   | 2959   | 55      |
+| convertToShares                                                                                              | 15960           | 15960  | 15960  | 15960  | 55      |
 | decimals                                                                                                     | 540             | 540    | 540    | 540    | 55      |
-| depositATokens                                                                                               | 51658           | 192672 | 206714 | 206822 | 606     |
-| depositWithPermit                                                                                            | 68043           | 234965 | 243428 | 332863 | 275     |
+| depositATokens                                                                                               | 51680           | 192734 | 206780 | 206888 | 606     |
+| depositWithPermit                                                                                            | 68065           | 234851 | 243518 | 332532 | 275     |
 | latestAnswer                                                                                                 | 19765           | 19765  | 19765  | 19765  | 56      |
-| maxDeposit                                                                                                   | 28852           | 41793  | 42490  | 42490  | 58      |
-| maxMint                                                                                                      | 9466            | 9466   | 9466   | 9466   | 1       |
-| maxRedeem                                                                                                    | 2593            | 5823   | 7434   | 7444   | 165     |
-| mint                                                                                                         | 74355           | 193537 | 193542 | 312717 | 110     |
+| maxDeposit                                                                                                   | 23063           | 36025  | 36723  | 36723  | 58      |
+| maxMint                                                                                                      | 7677            | 7677   | 7677   | 7677   | 1       |
+| maxRedeem                                                                                                    | 2571            | 5816   | 7434   | 7444   | 165     |
+| mint                                                                                                         | 66100           | 185119 | 185098 | 304097 | 110     |
 | mockInit                                                                                                     | 134255          | 134255 | 134255 | 134255 | 28      |
-| previewDeposit                                                                                               | 2981            | 11647  | 15981  | 15981  | 165     |
-| previewMint                                                                                                  | 2977            | 2977   | 2977   | 2977   | 55      |
-| previewRedeem                                                                                                | 2913            | 2913   | 2913   | 2913   | 110     |
-| previewWithdraw                                                                                              | 2959            | 2959   | 2959   | 2959   | 55      |
-| redeem                                                                                                       | 174631          | 174853 | 174883 | 174979 | 55      |
-| redeemATokens                                                                                                | 40731           | 121302 | 161131 | 162073 | 165     |
-| totalAssets                                                                                                  | 2930            | 3193   | 2930   | 17930  | 57      |
-| withdraw                                                                                                     | 51143           | 114477 | 114439 | 177723 | 110     |
+| previewDeposit                                                                                               | 3003            | 11669  | 16003  | 16003  | 165     |
+| previewMint                                                                                                  | 2999            | 2999   | 2999   | 2999   | 55      |
+| previewRedeem                                                                                                | 2935            | 2935   | 2935   | 2935   | 110     |
+| previewWithdraw                                                                                              | 2981            | 2981   | 2981   | 2981   | 55      |
+| redeem                                                                                                       | 174347          | 174562 | 174647 | 174683 | 55      |
+| redeemATokens                                                                                                | 40753           | 121354 | 161233 | 162139 | 165     |
+| totalAssets                                                                                                  | 2952            | 3215   | 2952   | 17952  | 57      |
+| withdraw                                                                                                     | 51165           | 114345 | 114313 | 177449 | 110     |


 | tests/extensions/v3-config-engine/mocks/AaveV3MockAssetEModeUpdate.sol:AaveV3MockAssetEModeUpdate contract |                 |        |        |        |         |
@@ -1208,7 +1216,7 @@
 | Deployment Cost                                                                                            | Deployment Size |        |        |        |         |
 | 795244                                                                                                     | 3745            |        |        |        |         |
 | Function Name                                                                                              | min             | avg    | median | max    | # calls |
-| execute                                                                                                    | 217757          | 217757 | 217757 | 217757 | 1       |
+| execute                                                                                                    | 206256          | 206256 | 206256 | 206256 | 1       |


 | tests/extensions/v3-config-engine/mocks/AaveV3MockBorrowUpdate.sol:AaveV3MockBorrowUpdate contract |                 |        |        |        |         |
@@ -1216,7 +1224,7 @@
 | Deployment Cost                                                                                    | Deployment Size |        |        |        |         |
 | 768952                                                                                             | 3555            |        |        |        |         |
 | Function Name                                                                                      | min             | avg    | median | max    | # calls |
-| execute                                                                                            | 159137          | 159137 | 159137 | 159137 | 1       |
+| execute                                                                                            | 158874          | 158874 | 158874 | 158874 | 1       |


 | tests/extensions/v3-config-engine/mocks/AaveV3MockBorrowUpdateNoChange.sol:AaveV3MockBorrowUpdateNoChange contract |                 |       |        |       |         |
@@ -1224,7 +1232,7 @@
 | Deployment Cost                                                                                                    | Deployment Size |       |        |       |         |
 | 775440                                                                                                             | 3585            |       |        |       |         |
 | Function Name                                                                                                      | min             | avg   | median | max   | # calls |
-| execute                                                                                                            | 47048           | 47048 | 47048  | 47048 | 1       |
+| execute                                                                                                            | 47026           | 47026 | 47026  | 47026 | 1       |


 | tests/extensions/v3-config-engine/mocks/AaveV3MockCapUpdate.sol:AaveV3MockCapUpdate contract |                 |       |        |       |         |
@@ -1272,7 +1280,7 @@
 | Deployment Cost                                                                                                  | Deployment Size |        |        |        |         |
 | 737875                                                                                                           | 3329            |        |        |        |         |
 | Function Name                                                                                                    | min             | avg    | median | max    | # calls |
-| execute                                                                                                          | 128344          | 128344 | 128344 | 128344 | 2       |
+| execute                                                                                                          | 128893          | 128893 | 128893 | 128893 | 2       |


 | tests/extensions/v3-config-engine/mocks/AaveV3MockEModeCategoryUpdate.sol:AaveV3MockEModeCategoryUpdateEdgeBonus contract |                 |       |        |       |         |
@@ -1280,7 +1288,7 @@
 | Deployment Cost                                                                                                           | Deployment Size |       |        |       |         |
 | 738487                                                                                                                    | 3332            |       |        |       |         |
 | Function Name                                                                                                             | min             | avg   | median | max   | # calls |
-| execute                                                                                                                   | 55082           | 55082 | 55082  | 55082 | 1       |
+| execute                                                                                                                   | 55127           | 55127 | 55127  | 55127 | 1       |


 | tests/extensions/v3-config-engine/mocks/AaveV3MockEModeCategoryUpdateNoChange.sol:AaveV3MockEModeCategoryUpdateNoChange contract |                 |       |        |       |         |
@@ -1296,7 +1304,7 @@
 | Deployment Cost                                                                          | Deployment Size |         |         |         |         |
 | 833716                                                                                   | 3923            |         |         |         |         |
 | Function Name                                                                            | min             | avg     | median  | max     | # calls |
-| execute                                                                                  | 1795274         | 1795274 | 1795274 | 1795274 | 1       |
+| execute                                                                                  | 1782917         | 1782917 | 1782917 | 1782917 | 1       |
 | newListings                                                                              | 2697            | 2697    | 2697    | 2697    | 4       |


@@ -1305,7 +1313,7 @@
 | Deployment Cost                                                                                      | Deployment Size |         |         |         |         |
 | 897931                                                                                               | 4363            |         |         |         |         |
 | Function Name                                                                                        | min             | avg     | median  | max     | # calls |
-| execute                                                                                              | 1795295         | 1795295 | 1795295 | 1795295 | 1       |
+| execute                                                                                              | 1782938         | 1782938 | 1782938 | 1782938 | 1       |
 | newListingsCustom                                                                                    | 3170            | 3170    | 3170    | 3170    | 4       |


@@ -1322,31 +1330,31 @@
 | Deployment Cost                                                                                  | Deployment Size |        |        |        |         |
 | 760739                                                                                           | 3517            |        |        |        |         |
 | Function Name                                                                                    | min             | avg    | median | max    | # calls |
-| execute                                                                                          | 151474          | 151474 | 151474 | 151474 | 1       |
+| execute                                                                                          | 145422          | 145422 | 145422 | 145422 | 1       |
 | rateStrategiesUpdates                                                                            | 1175            | 1175   | 1175   | 1175   | 4       |


 | tests/harness/VariableDebtToken.sol:VariableDebtTokenHarness contract |                 |        |        |        |         |
 |-----------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
 | Deployment Cost                                                       | Deployment Size |        |        |        |         |
-| 1699482                                                               | 8210            |        |        |        |         |
+| 1699549                                                               | 8210            |        |        |        |         |
 | Function Name                                                         | min             | avg    | median | max    | # calls |
 | DEBT_TOKEN_REVISION                                                   | 305             | 305    | 305    | 305    | 717     |
 | POOL                                                                  | 282             | 282    | 282    | 282    | 717     |
 | UNDERLYING_ASSET_ADDRESS                                              | 375             | 1201   | 375    | 2375   | 937     |
 | allowance                                                             | 902             | 902    | 902    | 902    | 1       |
 | approve                                                               | 22100           | 22100  | 22100  | 22100  | 1       |
-| approveDelegation                                                     | 48605           | 48632  | 48629  | 48677  | 55      |
-| burn                                                                  | 52003           | 52032  | 52027  | 52075  | 110     |
+| approveDelegation                                                     | 48605           | 48634  | 48629  | 48677  | 55      |
+| burn                                                                  | 52003           | 52030  | 52027  | 52075  | 110     |
 | decimals                                                              | 334             | 334    | 334    | 334    | 717     |
 | decreaseAllowance                                                     | 22121           | 22121  | 22121  | 22121  | 1       |
 | getIncentivesController                                               | 430             | 430    | 430    | 430    | 717     |
 | increaseAllowance                                                     | 22121           | 22121  | 22121  | 22121  | 1       |
-| initialize                                                            | 29537           | 150404 | 179132 | 247980 | 440     |
-| mint                                                                  | 86731           | 88007  | 86767  | 91790  | 220     |
+| initialize                                                            | 29623           | 151326 | 179120 | 247968 | 440     |
+| mint                                                                  | 86731           | 88005  | 86767  | 91790  | 220     |
 | name                                                                  | 1004            | 1325   | 1259   | 1789   | 717     |
 | scaledBalanceOf                                                       | 687             | 687    | 687    | 687    | 220     |
-| symbol                                                                | 1025            | 1360   | 1280   | 1810   | 717     |
+| symbol                                                                | 1025            | 1362   | 1280   | 1810   | 717     |
 | transfer                                                              | 22143           | 22143  | 22143  | 22143  | 1       |
 | transferFrom                                                          | 22369           | 22369  | 22369  | 22369  | 1       |

@@ -1356,9 +1364,9 @@
 | Deployment Cost                                              | Deployment Size |         |         |         |         |
 | 3356095                                                      | 13616           |         |         |         |         |
 | Function Name                                                | min             | avg     | median  | max     | # calls |
-| USDX_ADDRESS                                                 | 293             | 293     | 293     | 293     | 645     |
-| WBTC_ADDRESS                                                 | 249             | 249     | 249     | 249     | 645     |
-| execute                                                      | 5115928         | 5116789 | 5116858 | 5116858 | 648     |
+| USDX_ADDRESS                                                 | 293             | 293     | 293     | 293     | 661     |
+| WBTC_ADDRESS                                                 | 249             | 249     | 249     | 249     | 661     |
+| execute                                                      | 5081210         | 5083600 | 5083787 | 5083787 | 664     |


 | tests/mocks/AugustusRegistryMock.sol:AugustusRegistryMock contract |                 |     |        |     |         |
@@ -1395,4 +1403,4 @@



-Ran 60 test suites in 125.59s (1013.00s CPU time): 741 tests passed, 0 failed, 0 skipped (741 total tests)
+Ran 62 test suites in 118.40s (747.13s CPU time): 757 tests passed, 0 failed, 0 skipped (757 total tests)
```
