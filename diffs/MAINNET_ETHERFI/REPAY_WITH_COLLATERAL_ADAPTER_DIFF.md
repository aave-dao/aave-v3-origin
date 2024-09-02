```diff
diff --git a/./downloads/MAINNET/REPAY_WITH_COLLATERAL_ADAPTER.sol b/./downloads/ETHERFI/REPAY_WITH_COLLATERAL_ADAPTER.sol

-// downloads/MAINNET/REPAY_WITH_COLLATERAL_ADAPTER/ParaSwapRepayAdapter/@aave/periphery-v3/contracts/adapters/paraswap/BaseParaSwapAdapter.sol
+// downloads/ETHERFI/REPAY_WITH_COLLATERAL_ADAPTER/ParaSwapRepayAdapter/src/periphery/contracts/adapters/paraswap/BaseParaSwapAdapter.sol

 /**
  * @title BaseParaSwapAdapter
@@ -2192,7 +2343,9 @@ abstract contract BaseParaSwapAdapter is FlashLoanSimpleReceiverBase, Ownable {
    * @dev Get the aToken associated to the asset
    * @return address of the aToken
    */
-  function _getReserveData(address asset) internal view returns (DataTypes.ReserveData memory) {
+  function _getReserveData(
+    address asset
+  ) internal view returns (DataTypes.ReserveDataLegacy memory) {
     return POOL.getReserveData(asset);
   }

@@ -2253,7 +2406,7 @@ abstract contract BaseParaSwapAdapter is FlashLoanSimpleReceiverBase, Ownable {
   }
 }

-// downloads/MAINNET/REPAY_WITH_COLLATERAL_ADAPTER/ParaSwapRepayAdapter/@aave/periphery-v3/contracts/adapters/paraswap/ParaSwapRepayAdapter.sol
+// downloads/ETHERFI/REPAY_WITH_COLLATERAL_ADAPTER/ParaSwapRepayAdapter/src/periphery/contracts/adapters/paraswap/ParaSwapRepayAdapter.sol

 /**
  * @title ParaSwapRepayAdapter
@@ -2551,7 +2704,7 @@ contract ParaSwapRepayAdapter is BaseParaSwapBuyAdapter, ReentrancyGuard {
     uint256 debtRepayAmount,
     address initiator
   ) private view returns (uint256) {
-    DataTypes.ReserveData memory debtReserveData = _getReserveData(address(debtAsset));
+    DataTypes.ReserveDataLegacy memory debtReserveData = _getReserveData(address(debtAsset));

     address debtToken = DataTypes.InterestRateMode(rateMode) == DataTypes.InterestRateMode.STABLE
       ? debtReserveData.stableDebtTokenAddress
```
